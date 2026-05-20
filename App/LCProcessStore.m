#import "LCProcessStore.h"
#import "LCString.h"
#import "LCStoreSupport.h"
#import "../bricks/LeoRM/Sources/LeoRM.h"

@implementation LCProcessStore

+ (NSString *)executablePresenceForPath:(NSString *)path
{
    BOOL isDirectory;

    if (path == nil || [path length] == 0 || [path isEqualToString:@"-"]) {
        return @"unknown";
    }

    isDirectory = NO;

    if ([[NSFileManager defaultManager] fileExistsAtPath:path
                                             isDirectory:&isDirectory]) {
        return isDirectory ? @"directory" : @"present";
    }

    return @"missing";
}

+ (void)addFallbackRowsToArray:(NSMutableArray *)rows
{
    [rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Finder", @"name",
        [NSNumber numberWithInt:-1], @"pid",
        @"-", @"firstSeen",
        @"-", @"lastSeen",
        [NSNumber numberWithInt:0], @"exitObserved",
        @"current", @"instanceStatus",
        @"-", @"executablePath",
        @"-", @"observed",
        @"unknown", @"executable",
        @"com.apple.finder", @"bundle",
        @"Finder", @"bundleName",
        @"Apple system component", @"kind",
        @"path-app-contained", @"confidence",
        nil]];

    [rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Dock", @"name",
        [NSNumber numberWithInt:-1], @"pid",
        @"-", @"firstSeen",
        @"-", @"lastSeen",
        [NSNumber numberWithInt:0], @"exitObserved",
        @"current", @"instanceStatus",
        @"-", @"executablePath",
        @"-", @"observed",
        @"unknown", @"executable",
        @"com.apple.dock", @"bundle",
        @"Dock", @"bundleName",
        @"Apple system component", @"kind",
        @"path-app-contained", @"confidence",
        nil]];

    [rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Terminal", @"name",
        [NSNumber numberWithInt:-1], @"pid",
        @"-", @"firstSeen",
        @"-", @"lastSeen",
        [NSNumber numberWithInt:0], @"exitObserved",
        @"current", @"instanceStatus",
        @"-", @"executablePath",
        @"-", @"observed",
        @"unknown", @"executable",
        @"com.apple.Terminal", @"bundle",
        @"Terminal", @"bundleName",
        @"Apple application", @"kind",
        @"bundle-identifier", @"confidence",
        nil]];
}

+ (NSArray *)loadProcessRowsWithStatusString:(NSString **)statusString
{
    NSMutableArray *rows;
    NSError *error;
    LRMDatabase *database;
    LRMRepository *repository;
    LRMResultSet *resultSet;

    rows = [NSMutableArray array];

    if (statusString != NULL) {
        *statusString = nil;
    }

    error = nil;
    database = [LCStoreSupport openDatabaseWithStatusString:statusString];

    if (database == nil) {
        NSLog(@"LeoCol could not open database through LCStoreSupport.");
        [self addFallbackRowsToArray:rows];

        return rows;
    }

    repository = [[[LRMRepository alloc] initWithDatabase:database
                                                     error:&error] autorelease];

    if (repository == nil) {
        NSLog(@"LeoCol repository creation failed: %@", error);
        [database close];
        [self addFallbackRowsToArray:rows];

        if (statusString != NULL) {
            *statusString = LCString(@"Status.QueryPrepareFailed");
        }

        return rows;
    }

    resultSet = [repository resultSetForSQL:
        @"SELECT "
        @"  l.process_name AS process_name, "
        @"  l.pid AS pid, "
        @"  l.first_seen_at AS first_seen_at, "
        @"  l.last_seen_at AS last_seen_at, "
        @"  l.exit_observed AS exit_observed, "
        @"  l.executable_path AS executable_path, "
        @"  i.bundle_identifier AS bundle_identifier, "
        @"  i.bundle_name AS bundle_name, "
        @"  i.classification AS classification, "
        @"  i.confidence AS confidence "
        @"FROM process_lifecycle l "
        @"LEFT JOIN process_identity i ON i.lifecycle_id = l.id "
        @"ORDER BY l.exit_observed ASC, l.process_name ASC "
        @"LIMIT 200;"
        arguments:nil
        error:&error];

    if (resultSet == nil) {
        NSLog(@"LeoCol query failed: %@", error);
        [database close];
        [self addFallbackRowsToArray:rows];

        if (statusString != NULL) {
            *statusString = LCString(@"Status.QueryFailed");
        }

        return rows;
    }

    error = nil;

    while ([resultSet next:&error]) {
        LRMRow *row;
        NSString *processName;
        NSNumber *pid;
        NSString *firstSeen;
        NSString *lastSeen;
        NSNumber *exitObserved;
        NSString *instanceStatus;
        NSString *executablePath;
        NSString *observedState;
        NSString *executableState;
        NSString *bundleIdentifier;
        NSString *bundleName;
        NSString *classification;
        NSString *confidence;
        NSString *displayName;

        row = [resultSet currentRow];

        processName = [row stringForColumn:@"process_name"];
        pid = [row numberForColumn:@"pid"];
        firstSeen = [row stringForColumn:@"first_seen_at"];
        lastSeen = [row stringForColumn:@"last_seen_at"];
        exitObserved = [row numberForColumn:@"exit_observed"];
        instanceStatus = (exitObserved != nil && [exitObserved intValue] != 0) ? @"historical" : @"current";
        executablePath = [row stringForColumn:@"executable_path"];
        bundleIdentifier = [row stringForColumn:@"bundle_identifier"];
        bundleName = [row stringForColumn:@"bundle_name"];
        classification = [row stringForColumn:@"classification"];
        confidence = [row stringForColumn:@"confidence"];

        observedState = lastSeen != nil ? lastSeen : @"-";
        executableState = [self executablePresenceForPath:executablePath];

        displayName = processName;

        if (displayName == nil || [displayName length] == 0) {
            displayName = bundleName;
        }

        if (displayName == nil || [displayName length] == 0) {
            displayName = @"-";
        }

        [rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            displayName, @"name",
            pid != nil ? pid : [NSNumber numberWithInt:-1], @"pid",
            firstSeen != nil ? firstSeen : @"-", @"firstSeen",
            lastSeen != nil ? lastSeen : @"-", @"lastSeen",
            exitObserved != nil ? exitObserved : [NSNumber numberWithInt:0], @"exitObserved",
            instanceStatus, @"instanceStatus",
            executablePath != nil ? executablePath : @"-", @"executablePath",
            observedState, @"observed",
            executableState, @"executable",
            bundleIdentifier != nil ? bundleIdentifier : @"-", @"bundle",
            bundleName != nil ? bundleName : @"-", @"bundleName",
            classification != nil ? classification : @"unknown", @"kind",
            confidence != nil ? confidence : @"unknown", @"confidence",
            nil]];
    }

    if (error != nil) {
        NSLog(@"LeoCol result iteration failed: %@", error);

        if (statusString != NULL) {
            *statusString = LCString(@"Status.ResultIterationFailed");
        }
    }

    [resultSet close];
    [database close];

    if ([rows count] == 0) {
        [self addFallbackRowsToArray:rows];

        if (statusString != NULL) {
            *statusString = LCString(@"Status.EmptyDatabase");
        }
    }

    return rows;
}

@end
