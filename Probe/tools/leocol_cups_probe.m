#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <unistd.h>
#import <limits.h>

static NSString *
LCProjectRoot(void)
{
    char buffer[PATH_MAX];

    if (getcwd(buffer, sizeof(buffer)) == NULL) {
        return [[NSFileManager defaultManager] currentDirectoryPath];
    }

    return [NSString stringWithUTF8String:buffer];
}

static NSString *
LCCanonicalNow(void)
{
    NSDateFormatter *formatter;
    NSString *result;

    formatter = [[NSDateFormatter alloc] init];
    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];

    result = [[formatter stringFromDate:[NSDate date]] retain];
    [formatter release];

    return [result autorelease];
}

static void
LCBindText(sqlite3_stmt *statement, int index, NSString *value)
{
    if (value == nil) {
        sqlite3_bind_null(statement, index);
        return;
    }

    sqlite3_bind_text(statement,
                      index,
                      [value UTF8String],
                      -1,
                      SQLITE_TRANSIENT);
}

static int
LCExecSQL(sqlite3 *db, NSString *sql)
{
    char *errorMessage;
    int rc;

    errorMessage = NULL;
    rc = sqlite3_exec(db, [sql UTF8String], NULL, NULL, &errorMessage);

    if (rc != SQLITE_OK) {
        fprintf(stderr, "sqlite error: %s\n", errorMessage != NULL ? errorMessage : "unknown error");
        sqlite3_free(errorMessage);
    }

    return rc;
}

static NSString *
LCRunTask(NSString *launchPath, NSArray *arguments)
{
    NSTask *task;
    NSPipe *pipe;
    NSData *data;
    NSString *output;

    task = [[NSTask alloc] init];
    pipe = [NSPipe pipe];

    [task setLaunchPath:launchPath];
    [task setArguments:arguments];
    [task setStandardOutput:pipe];
    [task setStandardError:[NSPipe pipe]];

    @try {
        [task launch];
        data = [[pipe fileHandleForReading] readDataToEndOfFile];
        [task waitUntilExit];
    }
    @catch (NSException *exception) {
        [task release];
        return nil;
    }

    output = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

    [task release];

    return output;
}

static NSString *
LCSecondTokenFromLine(NSString *line)
{
    NSArray *parts;
    NSEnumerator *enumerator;
    NSString *part;
    NSMutableArray *tokens;

    tokens = [NSMutableArray array];
    parts = [line componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    enumerator = [parts objectEnumerator];

    while ((part = [enumerator nextObject]) != nil) {
        if ([part length] > 0) {
            [tokens addObject:part];
        }
    }

    if ([tokens count] < 2) {
        return nil;
    }

    return [tokens objectAtIndex:1];
}

static NSString *
LCQueueNameFromDeviceLine(NSString *line)
{
    NSRange colonRange;
    NSString *leftSide;
    NSArray *parts;
    NSEnumerator *enumerator;
    NSString *part;
    NSString *lastToken;

    colonRange = [line rangeOfString:@":"];

    if (colonRange.location == NSNotFound) {
        return nil;
    }

    leftSide = [line substringToIndex:colonRange.location];
    parts = [leftSide componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    enumerator = [parts objectEnumerator];
    lastToken = nil;

    while ((part = [enumerator nextObject]) != nil) {
        if ([part length] > 0) {
            lastToken = part;
        }
    }

    return lastToken;
}

static NSString *
LCDeviceURIFromDeviceLine(NSString *line)
{
    NSRange colonRange;

    colonRange = [line rangeOfString:@":"];

    if (colonRange.location == NSNotFound) {
        return nil;
    }

    return [[line substringFromIndex:colonRange.location + 1]
        stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

static NSDictionary *
LCPrinterStatusLines(void)
{
    NSMutableDictionary *map;
    NSString *output;
    NSArray *lines;
    NSEnumerator *enumerator;
    NSString *line;

    map = [NSMutableDictionary dictionary];
    output = LCRunTask(@"/usr/bin/lpstat", [NSArray arrayWithObject:@"-p"]);

    if (output == nil) {
        return map;
    }

    lines = [output componentsSeparatedByString:@"\n"];
    enumerator = [lines objectEnumerator];

    while ((line = [enumerator nextObject]) != nil) {
        NSString *queueName;

        if ([line length] == 0) {
            continue;
        }

        queueName = LCSecondTokenFromLine(line);

        if (queueName != nil) {
            [map setObject:line forKey:queueName];
        }
    }

    return map;
}

static NSDictionary *
LCPrinterDeviceURIs(void)
{
    NSMutableDictionary *map;
    NSString *output;
    NSArray *lines;
    NSEnumerator *enumerator;
    NSString *line;

    map = [NSMutableDictionary dictionary];
    output = LCRunTask(@"/usr/bin/lpstat", [NSArray arrayWithObject:@"-v"]);

    if (output == nil) {
        return map;
    }

    lines = [output componentsSeparatedByString:@"\n"];
    enumerator = [lines objectEnumerator];

    while ((line = [enumerator nextObject]) != nil) {
        NSString *queueName;
        NSString *deviceURI;

        if ([line length] == 0) {
            continue;
        }

        queueName = LCQueueNameFromDeviceLine(line);
        deviceURI = LCDeviceURIFromDeviceLine(line);

        if (queueName != nil && deviceURI != nil) {
            [map setObject:deviceURI forKey:queueName];
        }
    }

    return map;
}

static NSString *
LCPPDPathForQueue(NSString *queueName)
{
    NSArray *candidatePaths;
    NSEnumerator *enumerator;
    NSString *path;

    candidatePaths = [NSArray arrayWithObjects:
        [NSString stringWithFormat:@"/etc/cups/ppd/%@.ppd", queueName],
        [NSString stringWithFormat:@"/private/etc/cups/ppd/%@.ppd", queueName],
        nil];

    enumerator = [candidatePaths objectEnumerator];

    while ((path = [enumerator nextObject]) != nil) {
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            return path;
        }
    }

    return nil;
}

static NSString *
LCCupsResolutionState(NSString *deviceURI, NSString *ppdPath)
{
    if (deviceURI == nil || [deviceURI length] == 0) {
        return @"observed-only";
    }

    if (ppdPath == nil) {
        return @"unresolved";
    }

    return @"resolved";
}

static int
LCInsertCupsEvidence(sqlite3 *db,
                     NSString *subjectKind,
                     NSString *subjectName,
                     NSString *subjectPath,
                     NSString *subjectIdentifier,
                     NSString *evidencePath,
                     NSString *evidenceValue,
                     NSString *resolutionState,
                     NSString *createdAt)
{
    sqlite3_stmt *statement;
    const char *sql;
    int rc;

    sql =
        "INSERT INTO provenance_evidence "
        "(evidence_type, evidence_source, subject_kind, subject_name, subject_path, "
        " subject_identifier, evidence_path, evidence_value, resolution_state, confidence, created_at) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";

    rc = sqlite3_prepare_v2(db, sql, -1, &statement, NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr, "sqlite prepare failed: %s\n", sqlite3_errmsg(db));
        return rc;
    }

    LCBindText(statement, 1, @"cups");
    LCBindText(statement, 2, @"CUPS");
    LCBindText(statement, 3, subjectKind);
    LCBindText(statement, 4, subjectName);
    LCBindText(statement, 5, subjectPath);
    LCBindText(statement, 6, subjectIdentifier);
    LCBindText(statement, 7, evidencePath);
    LCBindText(statement, 8, evidenceValue);
    LCBindText(statement, 9, resolutionState);
    LCBindText(statement, 10, @"cups");
    LCBindText(statement, 11, createdAt);

    rc = sqlite3_step(statement);

    if (rc != SQLITE_DONE) {
        fprintf(stderr, "sqlite insert failed: %s\n", sqlite3_errmsg(db));
    }

    sqlite3_finalize(statement);

    return rc == SQLITE_DONE ? SQLITE_OK : rc;
}

static NSUInteger
LCInsertPrinterQueueEvidence(sqlite3 *db, NSString *createdAt)
{
    NSDictionary *statusLines;
    NSDictionary *deviceURIs;
    NSMutableSet *queueNames;
    NSEnumerator *enumerator;
    NSString *queueName;
    NSUInteger inserted;

    statusLines = LCPrinterStatusLines();
    deviceURIs = LCPrinterDeviceURIs();
    queueNames = [NSMutableSet set];

    [queueNames addObjectsFromArray:[statusLines allKeys]];
    [queueNames addObjectsFromArray:[deviceURIs allKeys]];

    inserted = 0;
    enumerator = [queueNames objectEnumerator];

    while ((queueName = [enumerator nextObject]) != nil) {
        NSString *statusLine;
        NSString *deviceURI;
        NSString *ppdPath;
        NSString *resolutionState;
        NSMutableArray *parts;
        NSString *evidenceValue;

        statusLine = [statusLines objectForKey:queueName];
        deviceURI = [deviceURIs objectForKey:queueName];
        ppdPath = LCPPDPathForQueue(queueName);
        resolutionState = LCCupsResolutionState(deviceURI, ppdPath);

        parts = [NSMutableArray array];

        if (statusLine != nil) {
            [parts addObject:[NSString stringWithFormat:@"Status=%@", statusLine]];
        }

        if (deviceURI != nil) {
            [parts addObject:[NSString stringWithFormat:@"DeviceURI=%@", deviceURI]];
        }

        if (ppdPath != nil) {
            [parts addObject:[NSString stringWithFormat:@"PPD=%@", ppdPath]];
        }

        evidenceValue = [parts count] > 0 ? [parts componentsJoinedByString:@"; "] : nil;

        if (LCInsertCupsEvidence(db,
                                 @"printer-queue",
                                 queueName,
                                 deviceURI,
                                 queueName,
                                 ppdPath,
                                 evidenceValue,
                                 resolutionState,
                                 createdAt) == SQLITE_OK) {
            inserted++;
        }
    }

    return inserted;
}

static NSUInteger
LCInsertOrphanPPDEvidence(sqlite3 *db, NSString *createdAt)
{
    NSFileManager *fileManager;
    NSArray *ppdDirectories;
    NSEnumerator *directoryEnumerator;
    NSString *directory;
    NSMutableSet *activeQueues;
    NSDictionary *statusLines;
    NSDictionary *deviceURIs;
    NSUInteger inserted;

    fileManager = [NSFileManager defaultManager];
    statusLines = LCPrinterStatusLines();
    deviceURIs = LCPrinterDeviceURIs();

    activeQueues = [NSMutableSet set];
    [activeQueues addObjectsFromArray:[statusLines allKeys]];
    [activeQueues addObjectsFromArray:[deviceURIs allKeys]];

    ppdDirectories = [NSArray arrayWithObjects:
        @"/etc/cups/ppd",
        @"/private/etc/cups/ppd",
        nil];

    inserted = 0;
    directoryEnumerator = [ppdDirectories objectEnumerator];

    while ((directory = [directoryEnumerator nextObject]) != nil) {
        NSArray *names;
        NSEnumerator *nameEnumerator;
        NSString *name;

        names = [fileManager directoryContentsAtPath:directory];

        if (names == nil) {
            continue;
        }

        nameEnumerator = [names objectEnumerator];

        while ((name = [nameEnumerator nextObject]) != nil) {
            NSString *queueName;
            NSString *path;

            if (![[name pathExtension] isEqualToString:@"ppd"]) {
                continue;
            }

            queueName = [name stringByDeletingPathExtension];

            if ([activeQueues containsObject:queueName]) {
                continue;
            }

            path = [directory stringByAppendingPathComponent:name];

            if (LCInsertCupsEvidence(db,
                                     @"printer-ppd",
                                     queueName,
                                     path,
                                     queueName,
                                     path,
                                     @"PPD exists without active queue",
                                     @"artifact",
                                     createdAt) == SQLITE_OK) {
                inserted++;
            }
        }
    }

    return inserted;
}

int
main(int argc, char **argv)
{
    NSAutoreleasePool *pool;
    NSString *root;
    NSString *dbPath;
    NSString *schemaPath;
    NSString *schemaSQL;
    NSString *createdAt;
    sqlite3 *db;
    NSUInteger queueRecords;
    NSUInteger orphanPPDRecords;
    int rc;

    (void)argc;
    (void)argv;

    pool = [[NSAutoreleasePool alloc] init];

    root = LCProjectRoot();
    dbPath = [root stringByAppendingPathComponent:@"Probe/results/leocol-v1.db"];
    schemaPath = [root stringByAppendingPathComponent:@"Schema/leocol_v1.sql"];

    [[NSFileManager defaultManager] createDirectoryAtPath:[root stringByAppendingPathComponent:@"Probe/results"]
                              withIntermediateDirectories:YES
                                               attributes:nil
                                                    error:nil];

    rc = sqlite3_open([dbPath UTF8String], &db);

    if (rc != SQLITE_OK) {
        fprintf(stderr, "could not open database: %s\n", sqlite3_errmsg(db));
        sqlite3_close(db);
        [pool release];
        return 1;
    }

    schemaSQL = [NSString stringWithContentsOfFile:schemaPath
                                         encoding:NSUTF8StringEncoding
                                            error:nil];

    if (schemaSQL != nil) {
        if (LCExecSQL(db, schemaSQL) != SQLITE_OK) {
            sqlite3_close(db);
            [pool release];
            return 1;
        }
    }

    LCExecSQL(db,
        @"DELETE FROM process_provenance "
         "WHERE evidence_id IN ("
         "SELECT id FROM provenance_evidence "
         "WHERE evidence_type = 'cups');");

    LCExecSQL(db,
        @"DELETE FROM provenance_evidence "
         "WHERE evidence_type = 'cups';");

    createdAt = LCCanonicalNow();

    queueRecords = LCInsertPrinterQueueEvidence(db, createdAt);
    orphanPPDRecords = LCInsertOrphanPPDEvidence(db, createdAt);

    sqlite3_close(db);

    printf("leocol_cups_probe: inserted %lu CUPS queue records and %lu orphan PPD records into %s\n",
           (unsigned long)queueRecords,
           (unsigned long)orphanPPDRecords,
           [dbPath UTF8String]);

    [pool release];

    return 0;
}
