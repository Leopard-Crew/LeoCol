//
//  error_main.m
//  LeoRM
//
//  Error bridge smoke test.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>

#import "../Sources/LeoRM.h"

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    sqlite3 *database = NULL;
    int result = sqlite3_open(":memory:", &database);

    if (result != SQLITE_OK) {
        fprintf(stderr, "Could not open in-memory SQLite database.\n");
        [pool drain];
        return 1;
    }

    NSString *sql = @"SELECT * FROM table_that_does_not_exist";
    char *sqliteError = NULL;

    result = sqlite3_exec(database, [sql UTF8String], NULL, NULL, &sqliteError);

    if (result == SQLITE_OK) {
        fprintf(stderr, "Expected SQLite failure did not happen.\n");
        sqlite3_close(database);
        [pool drain];
        return 1;
    }

    NSError *error = LRMSQLiteErrorMake(database, result, sql, @":memory:");

    if (![[error domain] isEqualToString:LRMErrorDomain]) {
        fprintf(stderr, "Unexpected error domain.\n");
        sqlite3_free(sqliteError);
        sqlite3_close(database);
        [pool drain];
        return 1;
    }

    if ([error code] != LRMErrorSQLite) {
        fprintf(stderr, "Unexpected LeoRM error code.\n");
        sqlite3_free(sqliteError);
        sqlite3_close(database);
        [pool drain];
        return 1;
    }

    if ([[error userInfo] objectForKey:LRMErrorSQLiteCodeKey] == nil) {
        fprintf(stderr, "Missing SQLite code in userInfo.\n");
        sqlite3_free(sqliteError);
        sqlite3_close(database);
        [pool drain];
        return 1;
    }

    if ([[error userInfo] objectForKey:LRMErrorSQLKey] == nil) {
        fprintf(stderr, "Missing SQL in userInfo.\n");
        sqlite3_free(sqliteError);
        sqlite3_close(database);
        [pool drain];
        return 1;
    }

    printf("LeoRM error bridge OK: %s\n",
           [[[error localizedDescription] description] UTF8String]);

    sqlite3_free(sqliteError);
    sqlite3_close(database);

    [pool drain];
    return 0;
}
