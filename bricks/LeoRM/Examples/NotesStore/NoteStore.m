//
//  NoteStore.m
//  LeoRM NotesStore Example
//
//  Tiny domain store built on top of LeoRM.
//

#import "NoteStore.h"
#import "Note.h"

@implementation NoteStore

- (BOOL)migrate:(NSError **)error
{
    LRMMigration *migration01 = nil;
    LRMMigration *migration12 = nil;
    LRMSchema *schema = nil;
    LRMMigrationRunner *runner = nil;

    migration01 = [LRMMigration migrationFromVersion:0
                                           toVersion:1
                                       SQLStatements:[NSArray arrayWithObject:
                                           @"CREATE TABLE notes (id INTEGER PRIMARY KEY, title TEXT NOT NULL, body TEXT, created_at TEXT NOT NULL)"]];

    migration12 = [LRMMigration migrationFromVersion:1
                                           toVersion:2
                                       SQLStatements:[NSArray arrayWithObject:
                                           @"CREATE INDEX IF NOT EXISTS notes_created_at_index ON notes (created_at)"]];

    schema = [LRMSchema schemaWithName:@"notes"
                         targetVersion:2
                            migrations:[NSArray arrayWithObjects:migration01, migration12, nil]
                                 error:error];

    if (schema == nil) {
        return NO;
    }

    runner = [[[LRMMigrationRunner alloc] init] autorelease];

    return [runner migrateDatabase:[self database]
                            schema:schema
                             error:error];
}

- (BOOL)addNoteWithTitle:(NSString *)title
                    body:(NSString *)body
               createdAt:(NSString *)createdAt
                   error:(NSError **)error
{
    NSArray *arguments = nil;

    arguments = [NSArray arrayWithObjects:title, body, createdAt, nil];

    return [self executeSQL:@"INSERT INTO notes (title, body, created_at) VALUES (?, ?, ?)"
                 arguments:arguments
                     error:error];
}

- (NSArray *)allNotes:(NSError **)error
{
    NSMutableArray *notes = nil;
    LRMResultSet *resultSet = nil;

    notes = [NSMutableArray array];

    resultSet = [self resultSetForSQL:@"SELECT id, title, body, created_at FROM notes ORDER BY id"
                            arguments:nil
                                error:error];

    if (resultSet == nil) {
        return nil;
    }

    while ([resultSet next:error]) {
        LRMRow *row = nil;
        Note *note = nil;

        row = [resultSet currentRow];

        note = [[[Note alloc] initWithIdentifier:[[row numberForColumn:@"id"] integerValue]
                                           title:[row stringForColumn:@"title"]
                                            body:[row stringForColumn:@"body"]
                                       createdAt:[row stringForColumn:@"created_at"]] autorelease];

        [notes addObject:note];
    }

    [resultSet close];

    return notes;
}

@end
