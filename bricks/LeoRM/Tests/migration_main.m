//
//  migration_main.m
//  LeoRM
//
//  Migration runner smoke test.
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

static BOOL readNoteCount(LRMDatabase *database, NSInteger *count, NSError **error)
{
    LRMStatement *statement = nil;
    LRMResultSet *resultSet = nil;
    LRMRow *row = nil;

    if (count == NULL) {
        return NO;
    }

    *count = 0;

    statement = [database prepareStatement:@"SELECT COUNT(*) AS note_count FROM notes"
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
    *count = [[row numberForColumn:@"note_count"] integerValue];

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
    NSInteger count = -1;

    LRMDatabase *database = [LRMDatabase databaseWithPath:@":memory:"
                                                    error:&error];

    if (database == nil || ![database open:&error]) {
        int result = failWithError(@"Could not open database", error);
        [pool drain];
        return result;
    }

    LRMMigration *migration01 = [LRMMigration migrationFromVersion:0
                                                         toVersion:1
                                                     SQLStatements:[NSArray arrayWithObject:@"CREATE TABLE notes (id INTEGER PRIMARY KEY, title TEXT NOT NULL)"]];

    LRMMigration *migration12 = [LRMMigration migrationFromVersion:1
                                                         toVersion:2
                                                     SQLStatements:[NSArray arrayWithObject:@"INSERT INTO notes (title) VALUES ('Migrated note')"]];

    LRMSchema *schema = [LRMSchema schemaWithName:@"test"
                                    targetVersion:2
                                       migrations:[NSArray arrayWithObjects:migration01, migration12, nil]
                                            error:&error];

    if (schema == nil) {
        int result = failWithError(@"Could not create schema", error);
        [pool drain];
        return result;
    }

    LRMMigrationRunner *runner = [[[LRMMigrationRunner alloc] init] autorelease];

    if (![runner migrateDatabase:database schema:schema error:&error]) {
        int result = failWithError(@"Could not migrate database", error);
        [pool drain];
        return result;
    }

    if (![database getSchemaVersion:&version
                      forSchemaName:@"test"
                              error:&error]) {
        int result = failWithError(@"Could not read schema version after migration", error);
        [pool drain];
        return result;
    }

    if (version != 2) {
        fprintf(stderr, "Expected schema version 2, got %ld.\n", (long)version);
        [pool drain];
        return 1;
    }

    if (!readNoteCount(database, &count, &error)) {
        int result = failWithError(@"Could not read migrated note count", error);
        [pool drain];
        return result;
    }

    if (count != 1) {
        fprintf(stderr, "Expected one migrated note, got %ld.\n", (long)count);
        [pool drain];
        return 1;
    }

    if (![runner migrateDatabase:database schema:schema error:&error]) {
        int result = failWithError(@"Second migration pass should be idempotent", error);
        [pool drain];
        return result;
    }

    version = -1;

    if (![database getSchemaVersion:&version
                      forSchemaName:@"test"
                              error:&error]) {
        int result = failWithError(@"Could not read schema version after second pass", error);
        [pool drain];
        return result;
    }

    if (version != 2) {
        fprintf(stderr, "Expected schema version 2 after second pass, got %ld.\n", (long)version);
        [pool drain];
        return 1;
    }

    printf("LeoRM migration smoke test OK\n");

    [database close];

    [pool drain];
    return 0;
}
