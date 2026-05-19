#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <sys/stat.h>
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

static NSString *
LCLaunchEvidenceTypeForDirectory(NSString *directory)
{
    if ([directory rangeOfString:@"LaunchDaemons"].location != NSNotFound) {
        return @"launch-daemon";
    }

    return @"launch-agent";
}

static NSString *
LCProgramPathFromPlist(NSDictionary *plist)
{
    id program;
    id arguments;

    program = [plist objectForKey:@"Program"];

    if ([program isKindOfClass:[NSString class]] && [program length] > 0) {
        return program;
    }

    arguments = [plist objectForKey:@"ProgramArguments"];

    if ([arguments isKindOfClass:[NSArray class]] && [arguments count] > 0) {
        id first;

        first = [arguments objectAtIndex:0];

        if ([first isKindOfClass:[NSString class]] && [first length] > 0) {
            return first;
        }
    }

    return nil;
}

static NSString *
LCProgramArgumentsStringFromPlist(NSDictionary *plist)
{
    id arguments;

    arguments = [plist objectForKey:@"ProgramArguments"];

    if ([arguments isKindOfClass:[NSArray class]]) {
        return [arguments componentsJoinedByString:@" "];
    }

    return nil;
}

static NSString *
LCResolutionStateForProgramPath(NSString *programPath)
{
    BOOL isDirectory;

    if (programPath == nil || [programPath length] == 0) {
        return @"observed-only";
    }

    if (![programPath isAbsolutePath]) {
        return @"unresolved";
    }

    isDirectory = NO;

    if ([[NSFileManager defaultManager] fileExistsAtPath:programPath
                                             isDirectory:&isDirectory]) {
        return @"resolved";
    }

    return @"stale-reference";
}

static NSString *
LCEvidenceValueForPlist(NSDictionary *plist, NSString *programPath)
{
    NSMutableArray *parts;
    id disabled;
    NSString *arguments;

    parts = [NSMutableArray array];

    disabled = [plist objectForKey:@"Disabled"];

    if ([disabled respondsToSelector:@selector(boolValue)]) {
        [parts addObject:[NSString stringWithFormat:@"Disabled=%@",
            [disabled boolValue] ? @"YES" : @"NO"]];
    }

    if (programPath != nil) {
        [parts addObject:[NSString stringWithFormat:@"Program=%@", programPath]];
    }

    arguments = LCProgramArgumentsStringFromPlist(plist);

    if (arguments != nil) {
        [parts addObject:[NSString stringWithFormat:@"ProgramArguments=%@", arguments]];
    }

    if ([parts count] == 0) {
        return nil;
    }

    return [parts componentsJoinedByString:@"; "];
}

static int
LCInsertEvidence(sqlite3 *db,
                 NSString *evidenceType,
                 NSString *evidenceSource,
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

    LCBindText(statement, 1, evidenceType);
    LCBindText(statement, 2, evidenceSource);
    LCBindText(statement, 3, @"launch-job");
    LCBindText(statement, 4, subjectName);
    LCBindText(statement, 5, subjectPath);
    LCBindText(statement, 6, subjectIdentifier);
    LCBindText(statement, 7, evidencePath);
    LCBindText(statement, 8, evidenceValue);
    LCBindText(statement, 9, resolutionState);
    LCBindText(statement, 10, @"plist");
    LCBindText(statement, 11, createdAt);

    rc = sqlite3_step(statement);

    if (rc != SQLITE_DONE) {
        fprintf(stderr, "sqlite insert failed: %s\n", sqlite3_errmsg(db));
    }

    sqlite3_finalize(statement);

    return rc == SQLITE_DONE ? SQLITE_OK : rc;
}

static NSUInteger
LCScanLaunchDirectory(sqlite3 *db, NSString *directory, NSString *createdAt)
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
        NSString *path;
        NSDictionary *plist;
        NSString *label;
        NSString *programPath;
        NSString *evidenceType;
        NSString *resolutionState;
        NSString *evidenceValue;

        if (![[name pathExtension] isEqualToString:@"plist"]) {
            continue;
        }

        path = [directory stringByAppendingPathComponent:name];
        plist = [NSDictionary dictionaryWithContentsOfFile:path];

        if (plist == nil) {
            continue;
        }

        label = [plist objectForKey:@"Label"];

        if (label == nil || ![label isKindOfClass:[NSString class]] || [label length] == 0) {
            label = [name stringByDeletingPathExtension];
        }

        programPath = LCProgramPathFromPlist(plist);
        evidenceType = LCLaunchEvidenceTypeForDirectory(directory);
        resolutionState = LCResolutionStateForProgramPath(programPath);
        evidenceValue = LCEvidenceValueForPlist(plist, programPath);

        if (LCInsertEvidence(db,
                             evidenceType,
                             directory,
                             label,
                             programPath,
                             label,
                             path,
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
    NSArray *directories;
    NSEnumerator *enumerator;
    NSString *directory;
    sqlite3 *db;
    NSUInteger totalInserted;
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
         "WHERE evidence_type IN ('launch-agent', 'launch-daemon'));");

    LCExecSQL(db,
        @"DELETE FROM provenance_evidence "
         "WHERE evidence_type IN ('launch-agent', 'launch-daemon');");

    createdAt = LCCanonicalNow();

    directories = [NSArray arrayWithObjects:
        @"/System/Library/LaunchAgents",
        @"/System/Library/LaunchDaemons",
        @"/Library/LaunchAgents",
        @"/Library/LaunchDaemons",
        [@"~/Library/LaunchAgents" stringByExpandingTildeInPath],
        nil];

    totalInserted = 0;
    enumerator = [directories objectEnumerator];

    while ((directory = [enumerator nextObject]) != nil) {
        totalInserted += LCScanLaunchDirectory(db, directory, createdAt);
    }

    sqlite3_close(db);

    printf("leocol_launch_sources_probe: inserted %lu launch provenance records into %s\n",
           (unsigned long)totalInserted,
           [dbPath UTF8String]);

    [pool release];

    return 0;
}
