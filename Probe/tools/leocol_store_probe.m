/*
 * LeoColStore probe.
 *
 * This Objective-C probe reads LeoCol's existing SQLite journal through LeoRM.
 * It does not replace the raw C probes. It proves that LeoRM can consume the
 * already proven LeoCol data path from a future Cocoa/Fundation store layer.
 */

#import <Foundation/Foundation.h>
#import "LeoRM.h"

static void
LeoColPrintNSError(NSString *prefix, NSError *error)
{
    if (error == nil) {
        fprintf(stderr, "%s: unknown error\n", [prefix UTF8String]);
        return;
    }

    fprintf(stderr,
            "%s: %s\n",
            [prefix UTF8String],
            [[error localizedDescription] UTF8String]);
}

int
main(int argc, char **argv)
{
    NSAutoreleasePool *pool;
    NSString *dbPath;
    NSError *error;
    LRMDatabase *database;
    LRMStatement *statement;
    LRMResultSet *resultSet;
    NSInteger printedRows;

    pool = [[NSAutoreleasePool alloc] init];

    dbPath = @"Probe/results/leocol-v1.db";

    if (argc > 1) {
        dbPath = [NSString stringWithUTF8String:argv[1]];
    }

    error = nil;
    database = [LRMDatabase databaseWithPath:dbPath error:&error];

    if (database == nil) {
        LeoColPrintNSError(@"leocol_store_probe: database init failed", error);
        [pool release];
        return 1;
    }

    if (![database open:&error]) {
        LeoColPrintNSError(@"leocol_store_probe: database open failed", error);
        [pool release];
        return 1;
    }

    statement = [database prepareStatement:
        @"SELECT "
        @"  l.process_name AS process_name, "
        @"  l.pid AS pid, "
        @"  l.exit_observed AS exit_observed, "
        @"  i.bundle_identifier AS bundle_identifier, "
        @"  i.bundle_name AS bundle_name, "
        @"  i.classification AS classification, "
        @"  i.confidence AS confidence "
        @"FROM process_lifecycle l "
        @"LEFT JOIN process_identity i ON i.lifecycle_id = l.id "
        @"ORDER BY l.exit_observed ASC, l.process_name ASC "
        @"LIMIT 20;"
        error:&error];

    if (statement == nil) {
        LeoColPrintNSError(@"leocol_store_probe: prepare failed", error);
        [database close];
        [pool release];
        return 1;
    }

    resultSet = [statement executeQuery:&error];

    if (resultSet == nil) {
        LeoColPrintNSError(@"leocol_store_probe: query failed", error);
        [database close];
        [pool release];
        return 1;
    }

    printedRows = 0;

    printf("process_name\tpid\texit_observed\tbundle_identifier\tbundle_name\tclassification\tconfidence\n");

    while ([resultSet next:&error]) {
        LRMRow *row;
        NSString *processName;
        NSNumber *pid;
        NSNumber *exitObserved;
        NSString *bundleIdentifier;
        NSString *bundleName;
        NSString *classification;
        NSString *confidence;

        row = [resultSet currentRow];

        processName = [row stringForColumn:@"process_name"];
        pid = [row numberForColumn:@"pid"];
        exitObserved = [row numberForColumn:@"exit_observed"];
        bundleIdentifier = [row stringForColumn:@"bundle_identifier"];
        bundleName = [row stringForColumn:@"bundle_name"];
        classification = [row stringForColumn:@"classification"];
        confidence = [row stringForColumn:@"confidence"];

        printf("%s\t%d\t%d\t%s\t%s\t%s\t%s\n",
               processName != nil ? [processName UTF8String] : "-",
               pid != nil ? [pid intValue] : -1,
               exitObserved != nil ? [exitObserved intValue] : -1,
               bundleIdentifier != nil ? [bundleIdentifier UTF8String] : "-",
               bundleName != nil ? [bundleName UTF8String] : "-",
               classification != nil ? [classification UTF8String] : "-",
               confidence != nil ? [confidence UTF8String] : "-");

        printedRows++;
    }

    if (error != nil) {
        LeoColPrintNSError(@"leocol_store_probe: iteration failed", error);
        [resultSet close];
        [database close];
        [pool release];
        return 1;
    }

    [resultSet close];
    [database close];

    printf("leocol_store_probe: printed %ld rows from %s\n",
           (long)printedRows,
           [dbPath UTF8String]);

    [pool release];
    return 0;
}
