//
//  constraint_errors_main.m
//  LeoRM
//
//  SQLite constraint-error smoke test.
//

#import <Foundation/Foundation.h>
#import "../Sources/LeoRM.h"

static BOOL errorLooksLikeSQLiteFailure(NSError *error)
{
    if (error == nil) {
        return NO;
    }

    if (![[error domain] isEqualToString:LRMErrorDomain]) {
        return NO;
    }

    if ([error code] != LRMErrorSQLite) {
        return NO;
    }

    if ([[error userInfo] objectForKey:LRMErrorSQLiteCodeKey] == nil) {
        return NO;
    }

    if ([[error userInfo] objectForKey:LRMErrorSQLiteMessageKey] == nil) {
        return NO;
    }

    return YES;
}

static BOOL expectSQLiteFailure(BOOL condition, NSError *error, NSString *message)
{
    if (condition) {
        fprintf(stderr, "Expected SQLite constraint failure did not happen: %s\n",
                [message UTF8String]);
        return NO;
    }

    if (!errorLooksLikeSQLiteFailure(error)) {
        fprintf(stderr, "Expected LeoRM SQLite NSError for constraint failure: %s\n",
                [message UTF8String]);
        return NO;
    }

    return YES;
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

static BOOL insertRecord(LRMDatabase *database,
                         NSInteger identifier,
                         id title,
                         NSString *slug,
                         NSError **error)
{
    BOOL ok = NO;
    LRMStatement *statement = nil;

    statement = [database prepareStatement:@"INSERT INTO constraint_items (id, title, slug) VALUES (?, ?, ?)"
                                     error:error];

    if (statement == nil) {
        return NO;
    }

    ok = [statement bindObject:[NSNumber numberWithInteger:identifier]
                       atIndex:1
                         error:error];

    if (ok) {
        ok = [statement bindObject:title
                           atIndex:2
                             error:error];
    }

    if (ok) {
        ok = [statement bindObject:slug
                           atIndex:3
                             error:error];
    }

    if (ok) {
        ok = [statement executeUpdate:error];
    }

    [statement finalizeStatement];

    return ok;
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
        fprintf(stderr, "Could not open database: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    if (!executeSQL(database,
                    @"CREATE TABLE constraint_items (id INTEGER PRIMARY KEY, title TEXT NOT NULL, slug TEXT UNIQUE)",
                    &error)) {
        fprintf(stderr, "Could not create constraint_items table: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    /*
     * Valid seed row.
     */
    error = nil;
    if (!insertRecord(database, 1, @"First item", @"first", &error)) {
        fprintf(stderr, "Could not insert seed row: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    /*
     * NOT NULL violation.
     */
    error = nil;
    if (!expectSQLiteFailure(insertRecord(database, 2, [NSNull null], @"null-title", &error),
                             error,
                             @"NOT NULL title violation")) {
        [pool drain];
        return 1;
    }

    /*
     * UNIQUE violation.
     */
    error = nil;
    if (!expectSQLiteFailure(insertRecord(database, 3, @"Duplicate slug", @"first", &error),
                             error,
                             @"UNIQUE slug violation")) {
        [pool drain];
        return 1;
    }

    /*
     * PRIMARY KEY conflict.
     */
    error = nil;
    if (!expectSQLiteFailure(insertRecord(database, 1, @"Duplicate primary key", @"duplicate-pk", &error),
                             error,
                             @"PRIMARY KEY conflict")) {
        [pool drain];
        return 1;
    }

    printf("LeoRM constraint-error smoke test OK\n");

    [database close];

    [pool drain];
    return 0;
}
