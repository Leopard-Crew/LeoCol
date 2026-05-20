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
    LRMStatement *statement;
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

    statement = [database prepareStatement:
        @"SELECT "
        @"  evidence_type AS evidence_type, "
        @"  resolution_state AS resolution_state, "
        @"  COUNT(*) AS evidence_count "
        @"FROM provenance_evidence "
        @"GROUP BY evidence_type, resolution_state "
        @"ORDER BY evidence_type ASC, resolution_state ASC;"
        error:&error];

    if (statement == nil) {
        [database close];

        if (statusString != NULL) {
            *statusString = @"Could not prepare provenance summary query";
        }

        return rows;
    }

    resultSet = [statement executeQuery:&error];

    if (resultSet == nil) {
        [database close];

        if (statusString != NULL) {
            *statusString = @"Could not execute provenance summary query";
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
        *statusString = @"Could not read provenance summary rows";
    }

    return rows;
}

@end
