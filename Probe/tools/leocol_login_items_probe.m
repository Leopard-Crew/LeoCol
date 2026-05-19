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
LCResolutionStateForPath(NSString *path)
{
    BOOL isDirectory;

    if (path == nil || [path length] == 0) {
        return @"observed-only";
    }

    if (![path isAbsolutePath]) {
        return @"unresolved";
    }

    isDirectory = NO;

    if ([[NSFileManager defaultManager] fileExistsAtPath:path
                                             isDirectory:&isDirectory]) {
        return @"resolved";
    }

    return @"stale-reference";
}

static int
LCInsertLoginItemEvidence(sqlite3 *db,
                          NSString *name,
                          NSString *path,
                          NSString *resolutionState,
                          NSString *createdAt)
{
    sqlite3_stmt *statement;
    const char *sql;
    NSString *evidenceValue;
    int rc;

    sql =
        "INSERT INTO provenance_evidence "
        "(evidence_type, evidence_source, subject_kind, subject_name, subject_path, "
        " subject_identifier, evidence_path, evidence_value, resolution_state, confidence, created_at) "
        "VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?);";

    evidenceValue = nil;

    if (path != nil && [path length] > 0) {
        evidenceValue = [NSString stringWithFormat:@"LoginItemPath=%@", path];
    }

    rc = sqlite3_prepare_v2(db, sql, -1, &statement, NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr, "sqlite prepare failed: %s\n", sqlite3_errmsg(db));
        return rc;
    }

    LCBindText(statement, 1, @"login-item");
    LCBindText(statement, 2, @"System Events login items");
    LCBindText(statement, 3, @"login-item");
    LCBindText(statement, 4, name);
    LCBindText(statement, 5, path);
    LCBindText(statement, 6, name);
    LCBindText(statement, 7, nil);
    LCBindText(statement, 8, evidenceValue);
    LCBindText(statement, 9, resolutionState);
    LCBindText(statement, 10, @"system-events");
    LCBindText(statement, 11, createdAt);

    rc = sqlite3_step(statement);

    if (rc != SQLITE_DONE) {
        fprintf(stderr, "sqlite insert failed: %s\n", sqlite3_errmsg(db));
    }

    sqlite3_finalize(statement);

    return rc == SQLITE_DONE ? SQLITE_OK : rc;
}

static NSString *
LCLoginItemsAppleScript(void)
{
    return
        @"tell application \"System Events\"\n"
         "    set outputText to \"\"\n"
         "    repeat with loginItem in login items\n"
         "        set itemName to name of loginItem\n"
         "        set itemPath to \"\"\n"
         "        try\n"
         "            set rawPath to path of loginItem\n"
         "            if rawPath is not missing value then\n"
         "                try\n"
         "                    set itemPath to POSIX path of rawPath\n"
         "                on error\n"
         "                    set itemPath to rawPath as text\n"
         "                end try\n"
         "            end if\n"
         "        end try\n"
         "        set outputText to outputText & itemName & tab & itemPath & linefeed\n"
         "    end repeat\n"
         "    return outputText\n"
         "end tell\n";
}

static NSArray *
LCLoginItemRows(void)
{
    NSAppleScript *script;
    NSAppleEventDescriptor *result;
    NSDictionary *errorInfo;
    NSString *text;
    NSArray *lines;
    NSMutableArray *rows;
    NSEnumerator *enumerator;
    NSString *line;

    script = [[NSAppleScript alloc] initWithSource:LCLoginItemsAppleScript()];
    errorInfo = nil;
    result = [script executeAndReturnError:&errorInfo];
    [script release];

    if (result == nil) {
        NSLog(@"Login item AppleScript failed: %@", errorInfo);
        return [NSArray array];
    }

    text = [result stringValue];

    if (text == nil || [text length] == 0) {
        return [NSArray array];
    }

    rows = [NSMutableArray array];
    lines = [text componentsSeparatedByString:@"\n"];
    enumerator = [lines objectEnumerator];

    while ((line = [enumerator nextObject]) != nil) {
        NSArray *fields;
        NSString *name;
        NSString *path;

        if ([line length] == 0) {
            continue;
        }

        fields = [line componentsSeparatedByString:@"\t"];

        if ([fields count] < 1) {
            continue;
        }

        name = [fields objectAtIndex:0];
        path = @"";

        if ([fields count] > 1) {
            path = [fields objectAtIndex:1];
        }

        [rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            name, @"name",
            path, @"path",
            nil]];
    }

    return rows;
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
    NSArray *rows;
    NSEnumerator *enumerator;
    NSDictionary *row;
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
         "WHERE evidence_type = 'login-item');");

    LCExecSQL(db,
        @"DELETE FROM provenance_evidence "
         "WHERE evidence_type = 'login-item';");

    createdAt = LCCanonicalNow();
    rows = LCLoginItemRows();
    enumerator = [rows objectEnumerator];
    inserted = 0;

    while ((row = [enumerator nextObject]) != nil) {
        NSString *name;
        NSString *path;
        NSString *resolutionState;

        name = [row objectForKey:@"name"];
        path = [row objectForKey:@"path"];

        if (path != nil && [path length] == 0) {
            path = nil;
        }

        resolutionState = LCResolutionStateForPath(path);

        if (LCInsertLoginItemEvidence(db,
                                      name,
                                      path,
                                      resolutionState,
                                      createdAt) == SQLITE_OK) {
            inserted++;
        }
    }

    sqlite3_close(db);

    printf("leocol_login_items_probe: inserted %lu login item provenance records into %s\n",
           (unsigned long)inserted,
           [dbPath UTF8String]);

    [pool release];

    return 0;
}
