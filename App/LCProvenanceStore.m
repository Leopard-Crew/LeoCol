#import "LCProvenanceStore.h"
#import "LCString.h"
#import "../bricks/LeoRM/Sources/LeoRM.h"

@implementation LCProvenanceStore

+ (NSString *)databasePath
{
    NSString *projectPath;

    projectPath = [[[NSBundle mainBundle] bundlePath]
        stringByDeletingLastPathComponent];

    projectPath = [projectPath stringByDeletingLastPathComponent];
    projectPath = [projectPath stringByDeletingLastPathComponent];
    projectPath = [projectPath stringByDeletingLastPathComponent];

    return [projectPath stringByAppendingPathComponent:@"Probe/results/leocol-v1.db"];
}

+ (NSArray *)loadEvidenceSummaryRowsWithStatusString:(NSString **)statusString
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
            *statusString = [NSString stringWithFormat:@"Database not found: %@", dbPath];
        }

        return rows;
    }

    error = nil;
    database = [LRMDatabase databaseWithPath:dbPath error:&error];

    if (database == nil || ![database open:&error]) {
        if (statusString != NULL) {
            *statusString = [NSString stringWithFormat:@"Could not open database: %@", dbPath];
        }

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
