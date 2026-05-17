//
//  file_database_main.m
//  LeoRM
//
//  File-backed database smoke test.
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

static BOOL insertNote(LRMRepository *repository, NSString *title, NSError **error)
{
    return [repository executeSQL:@"INSERT INTO file_notes (title) VALUES (?)"
                        arguments:[NSArray arrayWithObject:title]
                            error:error];
}

static BOOL readFirstNoteTitle(LRMRepository *repository, NSString **title, NSError **error)
{
    LRMResultSet *resultSet = nil;
    LRMRow *row = nil;

    if (title == NULL) {
        return NO;
    }

    *title = nil;

    resultSet = [repository resultSetForSQL:@"SELECT title FROM file_notes ORDER BY id LIMIT 1"
                                  arguments:nil
                                      error:error];

    if (resultSet == nil) {
        return NO;
    }

    if (![resultSet next:error]) {
        [resultSet close];
        return NO;
    }

    row = [resultSet currentRow];
    *title = [[row stringForColumn:@"title"] retain];

    [resultSet close];

    [*title autorelease];

    return YES;
}

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSError *error = nil;
    NSString *temporaryDirectory = NSTemporaryDirectory();
    NSString *databasePath = [temporaryDirectory stringByAppendingPathComponent:@"leorm-file-database-smoke.sqlite"];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSInteger version = -1;
    NSString *title = nil;

    [fileManager removeFileAtPath:databasePath handler:nil];

    /*
     * First open: create schema and insert data.
     */
    LRMDatabase *database = [LRMDatabase databaseWithPath:databasePath
                                                    error:&error];

    if (database == nil || ![database open:&error]) {
        int result = failWithError(@"Could not open file-backed database", error);
        [pool drain];
        return result;
    }

    LRMMigration *migration01 = [LRMMigration migrationFromVersion:0
                                                         toVersion:1
                                                     SQLStatements:[NSArray arrayWithObject:
                                                         @"CREATE TABLE file_notes (id INTEGER PRIMARY KEY, title TEXT NOT NULL)"]];

    LRMSchema *schema = [LRMSchema schemaWithName:@"file_notes"
                                    targetVersion:1
                                       migrations:[NSArray arrayWithObject:migration01]
                                            error:&error];

    if (schema == nil) {
        int result = failWithError(@"Could not create file_notes schema", error);
        [pool drain];
        return result;
    }

    LRMMigrationRunner *runner = [[[LRMMigrationRunner alloc] init] autorelease];

    if (![runner migrateDatabase:database schema:schema error:&error]) {
        int result = failWithError(@"Could not migrate file-backed database", error);
        [pool drain];
        return result;
    }

    LRMRepository *repository = [[[LRMRepository alloc] initWithDatabase:database
                                                                  error:&error] autorelease];

    if (repository == nil) {
        int result = failWithError(@"Could not create file repository", error);
        [pool drain];
        return result;
    }

    if (!insertNote(repository, @"Persistent LeoRM note", &error)) {
        int result = failWithError(@"Could not insert persistent note", error);
        [pool drain];
        return result;
    }

    [database close];

    /*
     * Second open: verify persisted schema version and data.
     */
    database = [LRMDatabase databaseWithPath:databasePath
                                       error:&error];

    if (database == nil || ![database open:&error]) {
        int result = failWithError(@"Could not reopen file-backed database", error);
        [pool drain];
        return result;
    }

    if (![database getSchemaVersion:&version
                      forSchemaName:@"file_notes"
                              error:&error]) {
        int result = failWithError(@"Could not read persisted schema version", error);
        [pool drain];
        return result;
    }

    if (version != 1) {
        fprintf(stderr, "Expected persisted schema version 1, got %ld.\n", (long)version);
        [pool drain];
        return 1;
    }

    repository = [[[LRMRepository alloc] initWithDatabase:database
                                                   error:&error] autorelease];

    if (repository == nil) {
        int result = failWithError(@"Could not recreate file repository", error);
        [pool drain];
        return result;
    }

    if (!readFirstNoteTitle(repository, &title, &error)) {
        int result = failWithError(@"Could not read persisted note", error);
        [pool drain];
        return result;
    }

    if (![title isEqualToString:@"Persistent LeoRM note"]) {
        fprintf(stderr, "Unexpected persisted note title.\n");
        [pool drain];
        return 1;
    }

    [database close];

    if (![fileManager removeFileAtPath:databasePath handler:nil]) {
        fprintf(stderr, "Could not remove temporary file-backed database.\n");
        [pool drain];
        return 1;
    }

    printf("LeoRM file-database smoke test OK\n");

    [pool drain];
    return 0;
}
