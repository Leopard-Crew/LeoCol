#import "LCSnapshotStore.h"
#import "LCString.h"
#import "../bricks/LeoRM/Sources/LeoRM.h"

@implementation LCSnapshotStore

+ (NSString *)databasePath
{
    NSString *projectPath;

    projectPath = [[[NSBundle mainBundle] bundlePath]
        stringByDeletingLastPathComponent];

    /*
     * Debug builds live at:
     *   App/build/Debug/LeoCol.app
     *
     * The project root is therefore three levels up from the .app parent:
     *   App/build/Debug -> App/build -> App -> LeoCol
     */
    projectPath = [projectPath stringByDeletingLastPathComponent];
    projectPath = [projectPath stringByDeletingLastPathComponent];
    projectPath = [projectPath stringByDeletingLastPathComponent];

    return [projectPath stringByAppendingPathComponent:@"Probe/results/leocol-v1.db"];
}

+ (NSArray *)loadSnapshotSummaryRowsWithStatusString:(NSString **)statusString
{
    NSMutableArray *rows;
    NSString *dbPath;
    NSError *error;
    LRMDatabase *database;
    LRMStatement *statement;
    LRMResultSet *resultSet;

    rows = [NSMutableArray array];

    if (statusString != NULL) {
        *statusString = nil;
    }

    dbPath = [self databasePath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        if (statusString != NULL) {
            *statusString = [NSString stringWithFormat:LCString(@"Status.DatabaseNotFound"), dbPath];
        }

        return rows;
    }

    error = nil;
    database = [LRMDatabase databaseWithPath:dbPath error:&error];

    if (database == nil || ![database open:&error]) {
        if (statusString != NULL) {
            *statusString = [NSString stringWithFormat:LCString(@"Status.DatabaseOpenFailed"), dbPath];
        }

        return rows;
    }

    statement = [database prepareStatement:
        @"SELECT "
        @"  s.id AS snapshot_id, "
        @"  s.observed_at AS observed_at, "
        @"  s.source AS source, "
        @"  COUNT(o.id) AS process_count "
        @"FROM snapshot_run s "
        @"LEFT JOIN process_observation o ON o.snapshot_id = s.id "
        @"GROUP BY s.id, s.observed_at, s.source "
        @"ORDER BY s.observed_at DESC, s.id DESC;"
        error:&error];

    if (statement == nil) {
        [database close];

        if (statusString != NULL) {
            *statusString = LCString(@"Status.QueryPrepareFailed");
        }

        return rows;
    }

    resultSet = [statement executeQuery:&error];

    if (resultSet == nil) {
        [database close];

        if (statusString != NULL) {
            *statusString = LCString(@"Status.QueryFailed");
        }

        return rows;
    }

    error = nil;

    while ([resultSet next:&error]) {
        LRMRow *row;
        NSNumber *snapshotID;
        NSString *observedAt;
        NSString *source;
        NSNumber *processCount;

        row = [resultSet currentRow];

        snapshotID = [row numberForColumn:@"snapshot_id"];
        observedAt = [row stringForColumn:@"observed_at"];
        source = [row stringForColumn:@"source"];
        processCount = [row numberForColumn:@"process_count"];

        [rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            snapshotID != nil ? snapshotID : [NSNumber numberWithInt:0], @"snapshotID",
            observedAt != nil ? observedAt : @"-", @"observedAt",
            source != nil ? source : @"-", @"source",
            processCount != nil ? processCount : [NSNumber numberWithInt:0], @"processCount",
            nil]];
    }

    [resultSet close];
    [database close];

    if (error != nil && statusString != NULL) {
        *statusString = LCString(@"Status.ResultIterationFailed");
    }

    return rows;
}

@end
