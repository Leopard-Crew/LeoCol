//
//  leaks_main.m
//  LeoRM
//
//  Long-lived target for Leopard leaks(1) inspection.
//

#import <Foundation/Foundation.h>
#import <unistd.h>
#import "../Sources/LeoRM.h"

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

static BOOL insertItem(LRMRepository *repository,
                       NSString *title,
                       NSData *payload,
                       NSError **error)
{
    return [repository executeSQL:@"INSERT INTO leak_items (title, payload) VALUES (?, ?)"
                        arguments:[NSArray arrayWithObjects:title, payload, nil]
                            error:error];
}

static BOOL readItems(LRMRepository *repository, NSError **error)
{
    LRMResultSet *resultSet = nil;
    NSUInteger count = 0;

    resultSet = [repository resultSetForSQL:@"SELECT id, title, payload FROM leak_items ORDER BY id"
                                  arguments:nil
                                      error:error];

    if (resultSet == nil) {
        return NO;
    }

    while ([resultSet next:error]) {
        LRMRow *row = [resultSet currentRow];

        if ([[row numberForColumn:@"id"] integerValue] <= 0) {
            [resultSet close];
            return NO;
        }

        if ([row stringForColumn:@"title"] == nil) {
            [resultSet close];
            return NO;
        }

        if ([row dataForColumn:@"payload"] == nil) {
            [resultSet close];
            return NO;
        }

        count++;
    }

    [resultSet close];

    return (count == 3);
}

static int runLeakScenario(void)
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSError *error = nil;
    NSString *databasePath = nil;
    NSFileManager *fileManager = nil;
    LRMDatabase *database = nil;
    LRMRepository *repository = nil;
    LRMMigration *migration = nil;
    LRMSchema *schema = nil;
    LRMMigrationRunner *runner = nil;
    LRMTransaction *transaction = nil;
    NSData *payload = nil;
    NSInteger version = -1;
    int result = 0;

    databasePath = [NSTemporaryDirectory() stringByAppendingPathComponent:
        [NSString stringWithFormat:@"leorm-leaks-%ld.sqlite", (long)getpid()]];

    fileManager = [NSFileManager defaultManager];
    [fileManager removeFileAtPath:databasePath handler:nil];

    database = [LRMDatabase databaseWithPath:databasePath error:&error];

    if (database == nil || ![database open:&error]) {
        fprintf(stderr, "leaks target: could not open database: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        result = 1;
        goto cleanup;
    }

    migration = [LRMMigration migrationFromVersion:0
                                         toVersion:1
                                     SQLStatements:[NSArray arrayWithObject:
                                         @"CREATE TABLE leak_items (id INTEGER PRIMARY KEY, title TEXT NOT NULL, payload BLOB NOT NULL)"]];

    schema = [LRMSchema schemaWithName:@"leaks"
                         targetVersion:1
                            migrations:[NSArray arrayWithObject:migration]
                                 error:&error];

    if (schema == nil) {
        fprintf(stderr, "leaks target: could not create schema: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        result = 1;
        goto cleanup;
    }

    runner = [[[LRMMigrationRunner alloc] init] autorelease];

    if (![runner migrateDatabase:database schema:schema error:&error]) {
        fprintf(stderr, "leaks target: could not migrate database: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        result = 1;
        goto cleanup;
    }

    if (![database getSchemaVersion:&version forSchemaName:@"leaks" error:&error] || version != 1) {
        fprintf(stderr, "leaks target: unexpected schema version.\n");
        result = 1;
        goto cleanup;
    }

    repository = [[[LRMRepository alloc] initWithDatabase:database error:&error] autorelease];

    if (repository == nil) {
        fprintf(stderr, "leaks target: could not create repository: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        result = 1;
        goto cleanup;
    }

    payload = [@"LeoRM leak-check payload" dataUsingEncoding:NSUTF8StringEncoding];

    if (!insertItem(repository, @"First", payload, &error) ||
        !insertItem(repository, @"Second", payload, &error) ||
        !insertItem(repository, @"Third", payload, &error)) {
        fprintf(stderr, "leaks target: could not insert data: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        result = 1;
        goto cleanup;
    }

    if (!readItems(repository, &error)) {
        fprintf(stderr, "leaks target: could not read data: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        result = 1;
        goto cleanup;
    }

    transaction = [database beginTransaction:&error];

    if (transaction == nil) {
        fprintf(stderr, "leaks target: could not begin transaction: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        result = 1;
        goto cleanup;
    }

    if (!executeSQL(database, @"INSERT INTO leak_items (title, payload) VALUES ('Rolled back', X'010203')", &error)) {
        fprintf(stderr, "leaks target: could not execute rollback insert: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        result = 1;
        goto cleanup;
    }

    if (![transaction rollback:&error]) {
        fprintf(stderr, "leaks target: could not rollback transaction: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        result = 1;
        goto cleanup;
    }

cleanup:
    if (database != nil) {
        [database close];
    }

    if (databasePath != nil) {
        [fileManager removeFileAtPath:databasePath handler:nil];
    }

    [pool drain];

    return result;
}

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    int result = runLeakScenario();

    if (result != 0) {
        return result;
    }

    printf("LeoRM leaks target ready; pid=%ld\n", (long)getpid());
    fflush(stdout);

    /*
     * Keep the process alive long enough for Tools/run_leaks_check.sh to
     * inspect it with leaks(1). This is intentionally not a smoke test.
     */
    sleep(30);

    return 0;
}
