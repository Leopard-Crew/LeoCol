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

static NSUInteger
LCNonEmptyLineCount(NSString *text)
{
    NSArray *lines;
    NSEnumerator *enumerator;
    NSString *line;
    NSUInteger count;

    if (text == nil) {
        return 0;
    }

    lines = [text componentsSeparatedByString:@"\n"];
    enumerator = [lines objectEnumerator];
    count = 0;

    while ((line = [enumerator nextObject]) != nil) {
        if ([[line stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] length] > 0) {
            count++;
        }
    }

    return count;
}

static NSString *
LCStringFromInfo(NSDictionary *info, NSArray *keys)
{
    NSEnumerator *enumerator;
    NSString *key;

    enumerator = [keys objectEnumerator];

    while ((key = [enumerator nextObject]) != nil) {
        id value;

        value = [info objectForKey:key];

        if ([value isKindOfClass:[NSString class]] && [value length] > 0) {
            return value;
        }

        if ([value respondsToSelector:@selector(stringValue)]) {
            return [value stringValue];
        }
    }

    return nil;
}

static NSDictionary *
LCReceiptInfo(NSString *receiptPath)
{
    NSString *infoPath;
    NSDictionary *info;

    infoPath = [receiptPath stringByAppendingPathComponent:@"Contents/Info.plist"];
    info = [NSDictionary dictionaryWithContentsOfFile:infoPath];

    if (info == nil) {
        return [NSDictionary dictionary];
    }

    return info;
}

static NSString *
LCReceiptIdentifier(NSString *receiptPath, NSDictionary *info)
{
    NSString *identifier;

    identifier = LCStringFromInfo(info, [NSArray arrayWithObjects:
        @"IFPkgFlagIdentifier",
        @"CFBundleIdentifier",
        @"Identifier",
        nil]);

    if (identifier != nil) {
        return identifier;
    }

    return [[receiptPath lastPathComponent] stringByDeletingPathExtension];
}

static NSString *
LCReceiptVersion(NSDictionary *info)
{
    return LCStringFromInfo(info, [NSArray arrayWithObjects:
        @"IFPkgFlagVersion",
        @"CFBundleShortVersionString",
        @"CFBundleVersion",
        nil]);
}

static int
LCInsertReceiptEvidence(sqlite3 *db,
                        NSString *receiptName,
                        NSString *receiptPath,
                        NSString *identifier,
                        NSString *bomPath,
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

    LCBindText(statement, 1, @"receipt-bom");
    LCBindText(statement, 2, @"/Library/Receipts");
    LCBindText(statement, 3, @"receipt");
    LCBindText(statement, 4, receiptName);
    LCBindText(statement, 5, receiptPath);
    LCBindText(statement, 6, identifier);
    LCBindText(statement, 7, bomPath);
    LCBindText(statement, 8, evidenceValue);
    LCBindText(statement, 9, resolutionState);
    LCBindText(statement, 10, @"lsbom");
    LCBindText(statement, 11, createdAt);

    rc = sqlite3_step(statement);

    if (rc != SQLITE_DONE) {
        fprintf(stderr, "sqlite insert failed: %s\n", sqlite3_errmsg(db));
    }

    sqlite3_finalize(statement);

    return rc == SQLITE_DONE ? SQLITE_OK : rc;
}

static NSUInteger
LCScanReceiptsDirectory(sqlite3 *db, NSString *directory, NSString *createdAt)
{
    NSFileManager *fileManager;
    NSArray *names;
    NSEnumerator *enumerator;
    NSString *name;
    NSUInteger inserted;

    fileManager = [NSFileManager defaultManager];
    names = [fileManager directoryContentsAtPath:directory];
    inserted = 0;

    if (names == nil) {
        return 0;
    }

    enumerator = [names objectEnumerator];

    while ((name = [enumerator nextObject]) != nil) {
        NSString *receiptPath;
        NSString *bomPath;
        NSString *receiptName;
        NSDictionary *info;
        NSString *identifier;
        NSString *version;
        NSString *lsbomOutput;
        NSUInteger pathCount;
        NSString *resolutionState;
        NSMutableArray *parts;
        NSString *evidenceValue;
        BOOL isDirectory;

        if (![[name pathExtension] isEqualToString:@"pkg"]) {
            continue;
        }

        receiptPath = [directory stringByAppendingPathComponent:name];

        isDirectory = NO;

        if (![fileManager fileExistsAtPath:receiptPath isDirectory:&isDirectory] || !isDirectory) {
            continue;
        }

        receiptName = [name stringByDeletingPathExtension];
        bomPath = [receiptPath stringByAppendingPathComponent:@"Contents/Archive.bom"];
        info = LCReceiptInfo(receiptPath);
        identifier = LCReceiptIdentifier(receiptPath, info);
        version = LCReceiptVersion(info);

        parts = [NSMutableArray array];
        [parts addObject:[NSString stringWithFormat:@"Receipt=%@", receiptPath]];

        if (identifier != nil) {
            [parts addObject:[NSString stringWithFormat:@"Identifier=%@", identifier]];
        }

        if (version != nil) {
            [parts addObject:[NSString stringWithFormat:@"Version=%@", version]];
        }

        if (![fileManager fileExistsAtPath:bomPath]) {
            resolutionState = @"observed-only";
            bomPath = nil;
            [parts addObject:@"ArchiveBOM=NO"];
        } else {
            lsbomOutput = LCRunTask(@"/usr/bin/lsbom", [NSArray arrayWithObject:bomPath]);

            if (lsbomOutput == nil) {
                resolutionState = @"unresolved";
                [parts addObject:@"ArchiveBOM=unreadable"];
            } else {
                pathCount = LCNonEmptyLineCount(lsbomOutput);
                resolutionState = @"resolved";
                [parts addObject:@"ArchiveBOM=YES"];
                [parts addObject:[NSString stringWithFormat:@"BOMPathCount=%lu", (unsigned long)pathCount]];
            }
        }

        evidenceValue = [parts componentsJoinedByString:@"; "];

        if (LCInsertReceiptEvidence(db,
                                    receiptName,
                                    receiptPath,
                                    identifier,
                                    bomPath,
                                    evidenceValue,
                                    resolutionState,
                                    createdAt) == SQLITE_OK) {
            inserted++;
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
    NSUInteger inserted;
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
         "WHERE evidence_type = 'receipt-bom');");

    LCExecSQL(db,
        @"DELETE FROM provenance_evidence "
         "WHERE evidence_type = 'receipt-bom';");

    createdAt = LCCanonicalNow();
    inserted = LCScanReceiptsDirectory(db, @"/Library/Receipts", createdAt);

    sqlite3_close(db);

    printf("leocol_receipt_bom_probe: inserted %lu receipt BOM provenance records into %s\n",
           (unsigned long)inserted,
           [dbPath UTF8String]);

    [pool release];

    return 0;
}
