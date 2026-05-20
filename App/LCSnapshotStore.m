#import "LCSnapshotStore.h"
#import "LCString.h"
#import "LCStoreSupport.h"
#import "../bricks/LeoRM/Sources/LeoRM.h"

@implementation LCSnapshotStore

+ (NSArray *)loadSnapshotSummaryRowsWithStatusString:(NSString **)statusString
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
        return rows;
    }

    repository = [[[LRMRepository alloc] initWithDatabase:database
                                                     error:&error] autorelease];

    if (repository == nil) {
        [database close];

        if (statusString != NULL) {
            *statusString = LCString(@"Status.QueryPrepareFailed");
        }

        return rows;
    }

    resultSet = [repository resultSetForSQL:
        @"SELECT "
        @"  s.id AS snapshot_id, "
        @"  s.observed_at AS observed_at, "
        @"  s.source AS source, "
        @"  COUNT(o.id) AS process_count "
        @"FROM snapshot_run s "
        @"LEFT JOIN process_observation o ON o.snapshot_id = s.id "
        @"GROUP BY s.id, s.observed_at, s.source "
        @"ORDER BY s.observed_at DESC, s.id DESC;"
        arguments:nil
        error:&error];

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
