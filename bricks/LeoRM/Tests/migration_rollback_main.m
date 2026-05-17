//
//  migration_rollback_main.m
//  LeoRM
//
//  Migration rollback smoke test.
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

static BOOL errorLooksLikeLeoRM(NSError *error)
{
    return (error != nil && [[error domain] isEqualToString:LRMErrorDomain]);
}

static BOOL tableExists(LRMDatabase *database, NSString *tableName, BOOL *exists, NSError **error)
{
    LRMStatement *statement = nil;
    LRMResultSet *resultSet = nil;
    LRMRow *row = nil;
    NSString *sql = nil;

    if (exists == NULL) {
        return NO;
    }

    *exists = NO;

    sql = @"SELECT COUNT(*) AS table_count FROM sqlite_master WHERE type = 'table' AND name = ?";

    statement = [database prepareStatement:sql error:error];

    if (statement == nil) {
        return NO;
    }

    if (![statement bindObject:tableName atIndex:1 error:error]) {
        [statement finalizeStatement];
        return NO;
    }

    resultSet = [statement executeQuery:error];

    if (resultSet == nil) {
        [statement finalizeStatement];
        return NO;
    }

    if (![resultSet next:error]) {
        [resultSet close];
        return NO;
    }

    row = [resultSet currentRow];
    *exists = ([[row numberForColumn:@"table_count"] integerValue] > 0);

    [resultSet close];

    return YES;
}

static BOOL readProbeCount(LRMDatabase *database, NSInteger *count, NSError **error)
{
    LRMStatement *statement = nil;
    LRMResultSet *resultSet = nil;
    LRMRow *row = nil;

    if (count == NULL) {
        return NO;
    }

    *count = -1;

    statement = [database prepareStatement:@"SELECT COUNT(*) AS probe_count FROM rollback_probe"
                                     error:error];

    if (statement == nil) {
        return NO;
    }

    resultSet = [statement executeQuery:error];

    if (resultSet == nil) {
        [statement finalizeStatement];
        return NO;
    }

    if (![resultSet next:error]) {
        [resultSet close];
        return NO;
    }

    row = [resultSet currentRow];
    *count = [[row numberForColumn:@"probe_count"] integerValue];

    [resultSet close];

    return YES;
}

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSError *error = nil;
    NSInteger version = -1;
    BOOL exists = YES;
    NSInteger count = -1;

    LRMDatabase *database = [LRMDatabase databaseWithPath:@":memory:"
                                                    error:&error];

    if (database == nil || ![database open:&error]) {
        int result = failWithError(@"Could not open database", error);
        [pool drain];
        return result;
    }

    LRMMigration *failingMigration = [LRMMigration migrationFromVersion:0
                                                              toVersion:1
                                                          SQLStatements:[NSArray arrayWithObjects:
                                                              @"CREATE TABLE rollback_probe (id INTEGER PRIMARY KEY, title TEXT NOT NULL)",
                                                              @"INSERT INTO rollback_probe (id, title) VALUES (1, 'temporary row')",
                                                              @"INSERT INTO table_that_does_not_exist (id) VALUES (1)",
                                                              nil]];

    LRMSchema *failingSchema = [LRMSchema schemaWithName:@"rollback_test"
                                           targetVersion:1
                                              migrations:[NSArray arrayWithObject:failingMigration]
                                                   error:&error];

    if (failingSchema == nil) {
        int result = failWithError(@"Could not create failing schema", error);
        [pool drain];
        return result;
    }

    LRMMigrationRunner *runner = [[[LRMMigrationRunner alloc] init] autorelease];

    error = nil;

    if ([runner migrateDatabase:database schema:failingSchema error:&error]) {
        fprintf(stderr, "Expected failing migration to return NO.\n");
        [pool drain];
        return 1;
    }

    if (!errorLooksLikeLeoRM(error)) {
        fprintf(stderr, "Expected LeoRM NSError for failing migration.\n");
        [pool drain];
        return 1;
    }

    /*
     * The migration failed, so the schema version must still be 0.
     */
    error = nil;
    version = -1;

    if (![database getSchemaVersion:&version
                      forSchemaName:@"rollback_test"
                              error:&error]) {
        int result = failWithError(@"Could not read schema version after failed migration", error);
        [pool drain];
        return result;
    }

    if (version != 0) {
        fprintf(stderr, "Expected schema version 0 after failed migration, got %ld.\n", (long)version);
        [pool drain];
        return 1;
    }

    /*
     * The CREATE TABLE statement was inside the failed transaction, so the
     * table must not exist after rollback.
     */
    error = nil;
    exists = YES;

    if (!tableExists(database, @"rollback_probe", &exists, &error)) {
        int result = failWithError(@"Could not inspect rollback_probe table", error);
        [pool drain];
        return result;
    }

    if (exists) {
        fprintf(stderr, "rollback_probe table should not exist after failed migration rollback.\n");
        [pool drain];
        return 1;
    }

    /*
     * Now prove that the database is still usable by running a clean migration.
     */
    LRMMigration *cleanMigration = [LRMMigration migrationFromVersion:0
                                                            toVersion:1
                                                        SQLStatements:[NSArray arrayWithObject:
                                                            @"CREATE TABLE rollback_probe (id INTEGER PRIMARY KEY, title TEXT NOT NULL)"]];

    LRMSchema *cleanSchema = [LRMSchema schemaWithName:@"rollback_test"
                                         targetVersion:1
                                            migrations:[NSArray arrayWithObject:cleanMigration]
                                                 error:&error];

    if (cleanSchema == nil) {
        int result = failWithError(@"Could not create clean schema", error);
        [pool drain];
        return result;
    }

    error = nil;

    if (![runner migrateDatabase:database schema:cleanSchema error:&error]) {
        int result = failWithError(@"Could not apply clean migration after rollback", error);
        [pool drain];
        return result;
    }

    error = nil;
    version = -1;

    if (![database getSchemaVersion:&version
                      forSchemaName:@"rollback_test"
                              error:&error]) {
        int result = failWithError(@"Could not read schema version after clean migration", error);
        [pool drain];
        return result;
    }

    if (version != 1) {
        fprintf(stderr, "Expected schema version 1 after clean migration, got %ld.\n", (long)version);
        [pool drain];
        return 1;
    }

    error = nil;

    if (!readProbeCount(database, &count, &error)) {
        int result = failWithError(@"Could not read rollback_probe row count", error);
        [pool drain];
        return result;
    }

    if (count != 0) {
        fprintf(stderr, "Expected rollback_probe row count 0 after clean migration, got %ld.\n", (long)count);
        [pool drain];
        return 1;
    }

    printf("LeoRM migration rollback smoke test OK\n");

    [database close];

    [pool drain];
    return 0;
}
