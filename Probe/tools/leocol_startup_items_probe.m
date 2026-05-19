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
LCArrayValueString(id value)
{
    if ([value isKindOfClass:[NSArray class]]) {
        return [value componentsJoinedByString:@","];
    }

    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }

    return nil;
}

static NSString *
LCStartupItemEvidenceValue(NSDictionary *parameters,
                           NSString *executablePath,
                           BOOL executablePresent)
{
    NSMutableArray *parts;
    NSString *description;
    NSString *provides;
    NSString *requires;
    NSString *uses;
    NSString *orderPreference;

    parts = [NSMutableArray array];

    description = [parameters objectForKey:@"Description"];
    provides = LCArrayValueString([parameters objectForKey:@"Provides"]);
    requires = LCArrayValueString([parameters objectForKey:@"Requires"]);
    uses = LCArrayValueString([parameters objectForKey:@"Uses"]);
    orderPreference = [parameters objectForKey:@"OrderPreference"];

    if (description != nil) {
        [parts addObject:[NSString stringWithFormat:@"Description=%@", description]];
    }

    if (provides != nil) {
        [parts addObject:[NSString stringWithFormat:@"Provides=%@", provides]];
    }

    if (requires != nil) {
        [parts addObject:[NSString stringWithFormat:@"Requires=%@", requires]];
    }

    if (uses != nil) {
        [parts addObject:[NSString stringWithFormat:@"Uses=%@", uses]];
    }

    if (orderPreference != nil) {
        [parts addObject:[NSString stringWithFormat:@"OrderPreference=%@", orderPreference]];
    }

    if (executablePath != nil) {
        [parts addObject:[NSString stringWithFormat:@"Executable=%@", executablePath]];
        [parts addObject:[NSString stringWithFormat:@"ExecutablePresent=%@",
            executablePresent ? @"YES" : @"NO"]];
    }

    if ([parts count] == 0) {
        return nil;
    }

    return [parts componentsJoinedByString:@"; "];
}

static NSString *
LCResolutionStateForStartupItem(NSString *itemPath, NSString *executablePath)
{
    BOOL isDirectory;

    isDirectory = NO;

    if (![[NSFileManager defaultManager] fileExistsAtPath:itemPath
                                              isDirectory:&isDirectory]) {
        return @"stale-reference";
    }

    if (!isDirectory) {
        return @"unresolved";
    }

    if (executablePath == nil) {
        return @"observed-only";
    }

    if ([[NSFileManager defaultManager] isExecutableFileAtPath:executablePath]) {
        return @"resolved";
    }

    if ([[NSFileManager defaultManager] fileExistsAtPath:executablePath]) {
        return @"resolved";
    }

    return @"stale-reference";
}

static int
LCInsertStartupItemEvidence(sqlite3 *db,
                            NSString *directory,
                            NSString *itemName,
                            NSString *itemPath,
                            NSString *parametersPath,
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

    LCBindText(statement, 1, @"startup-item");
    LCBindText(statement, 2, directory);
    LCBindText(statement, 3, @"startup-item");
    LCBindText(statement, 4, itemName);
    LCBindText(statement, 5, itemPath);
    LCBindText(statement, 6, itemName);
    LCBindText(statement, 7, parametersPath);
    LCBindText(statement, 8, evidenceValue);
    LCBindText(statement, 9, resolutionState);
    LCBindText(statement, 10, @"startupitems");
    LCBindText(statement, 11, createdAt);

    rc = sqlite3_step(statement);

    if (rc != SQLITE_DONE) {
        fprintf(stderr, "sqlite insert failed: %s\n", sqlite3_errmsg(db));
    }

    sqlite3_finalize(statement);

    return rc == SQLITE_DONE ? SQLITE_OK : rc;
}

static NSUInteger
LCScanStartupItemsDirectory(sqlite3 *db, NSString *directory, NSString *createdAt)
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
        NSString *itemPath;
        NSString *parametersPath;
        NSString *executablePath;
        NSDictionary *parameters;
        BOOL isDirectory;
        BOOL executablePresent;
        NSString *resolutionState;
        NSString *evidenceValue;

        if ([name hasPrefix:@"."]) {
            continue;
        }

        itemPath = [directory stringByAppendingPathComponent:name];

        isDirectory = NO;

        if (![fileManager fileExistsAtPath:itemPath isDirectory:&isDirectory] || !isDirectory) {
            continue;
        }

        parametersPath = [itemPath stringByAppendingPathComponent:@"StartupParameters.plist"];
        parameters = [NSDictionary dictionaryWithContentsOfFile:parametersPath];

        if (parameters == nil) {
            parametersPath = nil;
            parameters = [NSDictionary dictionary];
        }

        executablePath = [itemPath stringByAppendingPathComponent:name];
        executablePresent = [fileManager fileExistsAtPath:executablePath];

        resolutionState = LCResolutionStateForStartupItem(itemPath, executablePath);
        evidenceValue = LCStartupItemEvidenceValue(parameters,
                                                   executablePath,
                                                   executablePresent);

        if (LCInsertStartupItemEvidence(db,
                                        directory,
                                        name,
                                        itemPath,
                                        parametersPath,
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
         "WHERE evidence_type = 'startup-item');");

    LCExecSQL(db,
        @"DELETE FROM provenance_evidence "
         "WHERE evidence_type = 'startup-item';");

    createdAt = LCCanonicalNow();

    directories = [NSArray arrayWithObjects:
        @"/Library/StartupItems",
        @"/System/Library/StartupItems",
        nil];

    totalInserted = 0;
    enumerator = [directories objectEnumerator];

    while ((directory = [enumerator nextObject]) != nil) {
        totalInserted += LCScanStartupItemsDirectory(db, directory, createdAt);
    }

    sqlite3_close(db);

    printf("leocol_startup_items_probe: inserted %lu startup item provenance records into %s\n",
           (unsigned long)totalInserted,
           [dbPath UTF8String]);

    [pool release];

    return 0;
}
