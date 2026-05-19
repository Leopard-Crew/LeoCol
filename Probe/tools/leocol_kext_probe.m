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
LCBundleIdentifierFromKextstatLine(NSString *line)
{
    NSRange openRange;
    NSRange closeRange;
    NSString *inside;
    NSArray *parts;

    openRange = [line rangeOfString:@"(" options:NSBackwardsSearch];
    closeRange = [line rangeOfString:@")" options:NSBackwardsSearch];

    if (openRange.location == NSNotFound || closeRange.location == NSNotFound) {
        return nil;
    }

    if (closeRange.location <= openRange.location) {
        return nil;
    }

    inside = [line substringWithRange:NSMakeRange(openRange.location + 1,
                                                  closeRange.location - openRange.location - 1)];

    parts = [inside componentsSeparatedByString:@" "];

    if ([parts count] < 1) {
        return nil;
    }

    return [parts objectAtIndex:0];
}

static NSString *
LCVersionFromKextstatLine(NSString *line)
{
    NSRange openRange;
    NSRange closeRange;
    NSString *inside;
    NSArray *parts;

    openRange = [line rangeOfString:@"(" options:NSBackwardsSearch];
    closeRange = [line rangeOfString:@")" options:NSBackwardsSearch];

    if (openRange.location == NSNotFound || closeRange.location == NSNotFound) {
        return nil;
    }

    if (closeRange.location <= openRange.location) {
        return nil;
    }

    inside = [line substringWithRange:NSMakeRange(openRange.location + 1,
                                                  closeRange.location - openRange.location - 1)];

    parts = [inside componentsSeparatedByString:@" "];

    if ([parts count] < 2) {
        return nil;
    }

    return [parts objectAtIndex:1];
}

static void
LCCollectKextBundlePathsInDirectory(NSMutableDictionary *map, NSString *directory)
{
    NSFileManager *fileManager;
    NSDirectoryEnumerator *enumerator;
    NSString *relativePath;

    fileManager = [NSFileManager defaultManager];
    enumerator = [fileManager enumeratorAtPath:directory];

    while ((relativePath = [enumerator nextObject]) != nil) {
        NSString *fullPath;
        NSString *extension;
        NSString *infoPath;
        NSDictionary *info;
        NSString *bundleIdentifier;

        extension = [relativePath pathExtension];

        if (![extension isEqualToString:@"kext"]) {
            continue;
        }

        fullPath = [directory stringByAppendingPathComponent:relativePath];
        infoPath = [fullPath stringByAppendingPathComponent:@"Contents/Info.plist"];
        info = [NSDictionary dictionaryWithContentsOfFile:infoPath];

        if (info == nil) {
            continue;
        }

        bundleIdentifier = [info objectForKey:@"CFBundleIdentifier"];

        if (bundleIdentifier != nil && [bundleIdentifier length] > 0) {
            [map setObject:fullPath forKey:bundleIdentifier];
        }

        [enumerator skipDescendents];
    }
}

static NSDictionary *
LCKextBundlePathMap(void)
{
    NSMutableDictionary *map;

    map = [NSMutableDictionary dictionary];

    LCCollectKextBundlePathsInDirectory(map, @"/System/Library/Extensions");
    LCCollectKextBundlePathsInDirectory(map, @"/Library/Extensions");

    return map;
}

static int
LCInsertKextEvidence(sqlite3 *db,
                     NSString *bundleIdentifier,
                     NSString *bundlePath,
                     NSString *version,
                     NSString *kextstatLine,
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

    if (version != nil) {
        evidenceValue = [NSString stringWithFormat:@"Version=%@; Kextstat=%@", version, kextstatLine];
    } else {
        evidenceValue = [NSString stringWithFormat:@"Kextstat=%@", kextstatLine];
    }

    rc = sqlite3_prepare_v2(db, sql, -1, &statement, NULL);

    if (rc != SQLITE_OK) {
        fprintf(stderr, "sqlite prepare failed: %s\n", sqlite3_errmsg(db));
        return rc;
    }

    LCBindText(statement, 1, @"kext");
    LCBindText(statement, 2, @"kextstat");
    LCBindText(statement, 3, @"kext");
    LCBindText(statement, 4, bundleIdentifier);
    LCBindText(statement, 5, bundlePath);
    LCBindText(statement, 6, bundleIdentifier);
    LCBindText(statement, 7, bundlePath);
    LCBindText(statement, 8, evidenceValue);
    LCBindText(statement, 9, resolutionState);
    LCBindText(statement, 10, @"kextstat");
    LCBindText(statement, 11, createdAt);

    rc = sqlite3_step(statement);

    if (rc != SQLITE_DONE) {
        fprintf(stderr, "sqlite insert failed: %s\n", sqlite3_errmsg(db));
    }

    sqlite3_finalize(statement);

    return rc == SQLITE_DONE ? SQLITE_OK : rc;
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
    NSString *kextstatOutput;
    NSDictionary *pathMap;
    NSArray *lines;
    NSEnumerator *enumerator;
    NSString *line;
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
         "WHERE evidence_type = 'kext');");

    LCExecSQL(db,
        @"DELETE FROM provenance_evidence "
         "WHERE evidence_type = 'kext';");

    createdAt = LCCanonicalNow();
    pathMap = LCKextBundlePathMap();
    kextstatOutput = LCRunTask(@"/usr/sbin/kextstat", [NSArray array]);

    if (kextstatOutput == nil) {
        fprintf(stderr, "could not run kextstat\n");
        sqlite3_close(db);
        [pool release];
        return 1;
    }

    lines = [kextstatOutput componentsSeparatedByString:@"\n"];
    enumerator = [lines objectEnumerator];
    inserted = 0;

    while ((line = [enumerator nextObject]) != nil) {
        NSString *bundleIdentifier;
        NSString *version;
        NSString *bundlePath;
        NSString *resolutionState;

        bundleIdentifier = LCBundleIdentifierFromKextstatLine(line);

        if (bundleIdentifier == nil || [bundleIdentifier length] == 0) {
            continue;
        }

        version = LCVersionFromKextstatLine(line);
        bundlePath = [pathMap objectForKey:bundleIdentifier];
        resolutionState = bundlePath != nil ? @"resolved" : @"observed-only";

        if (LCInsertKextEvidence(db,
                                 bundleIdentifier,
                                 bundlePath,
                                 version,
                                 line,
                                 resolutionState,
                                 createdAt) == SQLITE_OK) {
            inserted++;
        }
    }

    sqlite3_close(db);

    printf("leocol_kext_probe: inserted %lu kext provenance records into %s\n",
           (unsigned long)inserted,
           [dbPath UTF8String]);

    [pool release];

    return 0;
}
