//
//  query_main.m
//  LeoRM
//
//  Query/result row smoke test.
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

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSError *error = nil;
    LRMDatabase *database = [LRMDatabase databaseWithPath:@":memory:"
                                                    error:&error];

    if (database == nil || ![database open:&error]) {
        int result = failWithError(@"Could not open database", error);
        [pool drain];
        return result;
    }

    LRMStatement *createStatement = [database prepareStatement:@"CREATE TABLE notes (id INTEGER PRIMARY KEY, title TEXT NOT NULL, rating INTEGER, body TEXT, payload BLOB)"
                                                         error:&error];

    if (createStatement == nil || ![createStatement executeUpdate:&error]) {
        int result = failWithError(@"Could not create table", error);
        [pool drain];
        return result;
    }

    NSData *payload = [@"blob-data" dataUsingEncoding:NSUTF8StringEncoding];

    LRMStatement *insertStatement = [database prepareStatement:@"INSERT INTO notes (title, rating, body, payload) VALUES (?, ?, ?, ?)"
                                                         error:&error];

    if (insertStatement == nil) {
        int result = failWithError(@"Could not prepare insert", error);
        [pool drain];
        return result;
    }

    if (![insertStatement bindObject:@"First note" atIndex:1 error:&error] ||
        ![insertStatement bindObject:[NSNumber numberWithInt:7] atIndex:2 error:&error] ||
        ![insertStatement bindObject:[NSNull null] atIndex:3 error:&error] ||
        ![insertStatement bindObject:payload atIndex:4 error:&error] ||
        ![insertStatement executeUpdate:&error]) {
        int result = failWithError(@"Could not insert row", error);
        [pool drain];
        return result;
    }

    LRMStatement *queryStatement = [database prepareStatement:@"SELECT id, title, rating, body, payload FROM notes WHERE title = ?"
                                                        error:&error];

    if (queryStatement == nil) {
        int result = failWithError(@"Could not prepare query", error);
        [pool drain];
        return result;
    }

    if (![queryStatement bindObject:@"First note" atIndex:1 error:&error]) {
        int result = failWithError(@"Could not bind query", error);
        [pool drain];
        return result;
    }

    LRMResultSet *resultSet = [queryStatement executeQuery:&error];

    if (resultSet == nil) {
        int result = failWithError(@"Could not execute query", error);
        [pool drain];
        return result;
    }

    if (![resultSet next:&error]) {
        int result = failWithError(@"Expected one result row", error);
        [pool drain];
        return result;
    }

    LRMRow *row = [resultSet currentRow];

    if (![[row stringForColumn:@"title"] isEqualToString:@"First note"]) {
        fprintf(stderr, "Unexpected title value.\n");
        [pool drain];
        return 1;
    }

    if ([[row numberForColumn:@"rating"] intValue] != 7) {
        fprintf(stderr, "Unexpected rating value.\n");
        [pool drain];
        return 1;
    }

    if (![row isNullForColumn:@"body"]) {
        fprintf(stderr, "Expected body to be NULL.\n");
        [pool drain];
        return 1;
    }

    if (![[row dataForColumn:@"payload"] isEqualToData:payload]) {
        fprintf(stderr, "Unexpected payload value.\n");
        [pool drain];
        return 1;
    }

    if ([resultSet next:&error]) {
        fprintf(stderr, "Expected only one result row.\n");
        [pool drain];
        return 1;
    }

    printf("LeoRM query smoke test OK\n");

    [database close];

    [pool drain];
    return 0;
}
