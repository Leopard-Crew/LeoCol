//
//  edge_cases_main.m
//  LeoRM
//
//  Foundation / SQLite edge-case smoke test.
//

#import <Foundation/Foundation.h>
#import "../Sources/LeoRM.h"

static int failWithError(NSString *message, NSError *error)
{
    if (error != nil) {
        fprintf(stderr, "%s: %s\n",
                [message UTF8String],
                [[[error localizedDescription] description] UTF8String]);
    } else {
        fprintf(stderr, "%s\n", [message UTF8String]);
    }

    return 1;
}

static BOOL executeSQL(LRMDatabase *database, NSString *sql, NSError **error)
{
    BOOL ok = NO;
    LRMStatement *statement = [database prepareStatement:sql error:error];

    if (statement == nil) {
        return NO;
    }

    ok = [statement executeUpdate:error];

    [statement finalizeStatement];

    return ok;
}

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSError *error = nil;

    NSString *utf8Text = @"Grüße aus LeoRM – 日本語 – ᚱ";
    NSData *payload = [@"binary-ish payload: \x01\x02\x03" dataUsingEncoding:NSUTF8StringEncoding];

    LRMDatabase *database = [LRMDatabase databaseWithPath:@":memory:"
                                                    error:&error];

    if (database == nil || ![database open:&error]) {
        int result = failWithError(@"Could not open database", error);
        [pool drain];
        return result;
    }

    if (!executeSQL(database,
                    @"CREATE TABLE edge_values (id INTEGER PRIMARY KEY, text_value TEXT, int_value INTEGER, float_value REAL, null_value TEXT, nsnull_value TEXT, blob_value BLOB)",
                    &error)) {
        int result = failWithError(@"Could not create edge_values table", error);
        [pool drain];
        return result;
    }

    LRMStatement *insert = [database prepareStatement:@"INSERT INTO edge_values (id, text_value, int_value, float_value, null_value, nsnull_value, blob_value) VALUES (?, ?, ?, ?, ?, ?, ?)"
                                               error:&error];

    if (insert == nil) {
        int result = failWithError(@"Could not prepare edge insert", error);
        [pool drain];
        return result;
    }

    if (![insert bindObject:[NSNumber numberWithInteger:1] atIndex:1 error:&error] ||
        ![insert bindObject:utf8Text atIndex:2 error:&error] ||
        ![insert bindObject:[NSNumber numberWithLongLong:922337203685477LL] atIndex:3 error:&error] ||
        ![insert bindObject:[NSNumber numberWithDouble:3.1415926535] atIndex:4 error:&error] ||
        ![insert bindObject:nil atIndex:5 error:&error] ||
        ![insert bindObject:[NSNull null] atIndex:6 error:&error] ||
        ![insert bindObject:payload atIndex:7 error:&error] ||
        ![insert executeUpdate:&error]) {
        int result = failWithError(@"Could not insert edge row", error);
        [insert finalizeStatement];
        [pool drain];
        return result;
    }

    [insert finalizeStatement];

    LRMStatement *query = [database prepareStatement:@"SELECT id, text_value, int_value, float_value, null_value, nsnull_value, blob_value FROM edge_values WHERE id = ?"
                                              error:&error];

    if (query == nil) {
        int result = failWithError(@"Could not prepare edge query", error);
        [pool drain];
        return result;
    }

    if (![query bindObject:[NSNumber numberWithInteger:1] atIndex:1 error:&error]) {
        int result = failWithError(@"Could not bind edge query id", error);
        [query finalizeStatement];
        [pool drain];
        return result;
    }

    LRMResultSet *resultSet = [query executeQuery:&error];

    if (resultSet == nil) {
        int result = failWithError(@"Could not execute edge query", error);
        [query finalizeStatement];
        [pool drain];
        return result;
    }

    if (![resultSet next:&error]) {
        int result = failWithError(@"Expected edge row", error);
        [resultSet close];
        [pool drain];
        return result;
    }

    LRMRow *row = [resultSet currentRow];

    if ([[row numberForColumn:@"id"] integerValue] != 1) {
        fprintf(stderr, "Unexpected id value.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if (![[row stringForColumn:@"text_value"] isEqualToString:utf8Text]) {
        fprintf(stderr, "Unexpected UTF-8 text value.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if ([[row numberForColumn:@"int_value"] longLongValue] != 922337203685477LL) {
        fprintf(stderr, "Unexpected integer value.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    {
        double value = [[row numberForColumn:@"float_value"] doubleValue];

        if (value < 3.1415926534 || value > 3.1415926536) {
            fprintf(stderr, "Unexpected floating point value.\n");
            [resultSet close];
            [pool drain];
            return 1;
        }
    }

    if (![row isNullForColumn:@"null_value"]) {
        fprintf(stderr, "Expected nil-bound value to read as SQL NULL.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if (![row isNullForColumn:@"nsnull_value"]) {
        fprintf(stderr, "Expected NSNull-bound value to read as SQL NULL.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if ([row objectForColumn:@"null_value"] != nil) {
        fprintf(stderr, "Expected objectForColumn:null_value to return nil.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if (![[row dataForColumn:@"blob_value"] isEqualToData:payload]) {
        fprintf(stderr, "Unexpected blob value.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if ([row objectForColumn:@"missing_column"] != nil) {
        fprintf(stderr, "Expected missing column lookup to return nil.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if (![row isNullForColumn:@"missing_column"]) {
        fprintf(stderr, "Expected missing column to report as null.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if ([row objectAtIndex:-1] != nil) {
        fprintf(stderr, "Expected negative column index lookup to return nil.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if ([row objectAtIndex:999] != nil) {
        fprintf(stderr, "Expected out-of-range column index lookup to return nil.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if (![row isNullAtIndex:-1]) {
        fprintf(stderr, "Expected negative column index to report as null.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if (![row isNullAtIndex:999]) {
        fprintf(stderr, "Expected out-of-range column index to report as null.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    if ([resultSet next:&error]) {
        fprintf(stderr, "Expected only one edge row.\n");
        [resultSet close];
        [pool drain];
        return 1;
    }

    [resultSet close];

    printf("LeoRM edge-case smoke test OK\n");

    [database close];

    [pool drain];
    return 0;
}
