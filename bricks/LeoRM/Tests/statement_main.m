//
//  statement_main.m
//  LeoRM
//
//  Prepared statement smoke test.
//

#import <Foundation/Foundation.h>
#import "../Sources/LeoRM.h"

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSError *error = nil;
    LRMDatabase *database = [LRMDatabase databaseWithPath:@":memory:"
                                                    error:&error];

    if (database == nil || ![database open:&error]) {
        fprintf(stderr, "Could not open database: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    LRMStatement *createStatement = [database prepareStatement:@"CREATE TABLE notes (id INTEGER PRIMARY KEY, title TEXT NOT NULL, body TEXT)"
                                                         error:&error];

    if (createStatement == nil || ![createStatement executeUpdate:&error]) {
        fprintf(stderr, "Could not create table: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    LRMStatement *insertStatement = [database prepareStatement:@"INSERT INTO notes (title, body) VALUES (?, ?)"
                                                         error:&error];

    if (insertStatement == nil) {
        fprintf(stderr, "Could not prepare insert: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    if (![insertStatement bindObject:@"First note" atIndex:1 error:&error]) {
        fprintf(stderr, "Could not bind title: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    if (![insertStatement bindObject:@"Created through LRMStatement." atIndex:2 error:&error]) {
        fprintf(stderr, "Could not bind body: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    if (![insertStatement executeUpdate:&error]) {
        fprintf(stderr, "Could not insert note: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    LRMStatement *badStatement = [database prepareStatement:@"INSERT INTO notes (missing_column) VALUES (?)"
                                                      error:&error];

    if (badStatement != nil) {
        fprintf(stderr, "Expected invalid SQL prepare to fail.\n");
        [pool drain];
        return 1;
    }

    printf("LeoRM statement smoke test OK\n");

    [database close];

    [pool drain];
    return 0;
}
