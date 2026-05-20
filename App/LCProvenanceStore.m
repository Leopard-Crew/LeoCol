#import "LCProvenanceStore.h"
#import "LCString.h"
#import "LCStoreSupport.h"
#import "../bricks/LeoRM/Sources/LeoRM.h"

@implementation LCProvenanceStore

+ (NSArray *)loadEvidenceSummaryRowsWithStatusString:(NSString **)statusString
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
        @"  evidence_type AS evidence_type, "
        @"  resolution_state AS resolution_state, "
        @"  COUNT(*) AS evidence_count "
        @"FROM provenance_evidence "
        @"GROUP BY evidence_type, resolution_state "
        @"ORDER BY evidence_type ASC, resolution_state ASC;"
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
        NSString *evidenceType;
        NSString *resolutionState;
        NSNumber *count;

        row = [resultSet currentRow];

        evidenceType = [row stringForColumn:@"evidence_type"];
        resolutionState = [row stringForColumn:@"resolution_state"];
        count = [row numberForColumn:@"evidence_count"];

        [rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            evidenceType != nil ? evidenceType : @"-", @"evidenceType",
            resolutionState != nil ? resolutionState : @"-", @"resolutionState",
            count != nil ? count : [NSNumber numberWithInt:0], @"count",
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
