//
//  repository_main.m
//  LeoRM
//
//  Repository helper smoke test.
//

#import <Foundation/Foundation.h>
#import "../Sources/LeoRM.h"

@interface TestNote : NSObject
{
@private
    NSString *_title;
}

- (id)initWithTitle:(NSString *)title;
- (NSString *)title;

@end

@implementation TestNote

- (id)initWithTitle:(NSString *)title
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _title = [title copy];

    return self;
}

- (void)dealloc
{
    [_title release];

    [super dealloc];
}

- (NSString *)title
{
    return _title;
}

@end

@interface TestNoteRepository : LRMRepository

- (BOOL)createSchema:(NSError **)error;
- (BOOL)insertNote:(TestNote *)note error:(NSError **)error;
- (NSArray *)allNotes:(NSError **)error;

@end

@implementation TestNoteRepository

- (BOOL)createSchema:(NSError **)error
{
    return [self executeSQL:@"CREATE TABLE notes (id INTEGER PRIMARY KEY, title TEXT NOT NULL)"
                 arguments:nil
                     error:error];
}

- (BOOL)insertNote:(TestNote *)note error:(NSError **)error
{
    return [self executeSQL:@"INSERT INTO notes (title) VALUES (?)"
                 arguments:[NSArray arrayWithObject:[note title]]
                     error:error];
}

- (NSArray *)allNotes:(NSError **)error
{
    NSMutableArray *notes = [NSMutableArray array];
    LRMResultSet *resultSet = nil;

    resultSet = [self resultSetForSQL:@"SELECT title FROM notes ORDER BY id"
                            arguments:nil
                                error:error];

    if (resultSet == nil) {
        return nil;
    }

    while ([resultSet next:error]) {
        LRMRow *row = [resultSet currentRow];
        TestNote *note = [[[TestNote alloc] initWithTitle:[row stringForColumn:@"title"]] autorelease];

        [notes addObject:note];
    }

    [resultSet close];

    return notes;
}

@end

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

    TestNoteRepository *repository = [[[TestNoteRepository alloc] initWithDatabase:database
                                                                             error:&error] autorelease];

    if (repository == nil) {
        int result = failWithError(@"Could not create repository", error);
        [pool drain];
        return result;
    }

    if (![repository createSchema:&error]) {
        int result = failWithError(@"Could not create repository schema", error);
        [pool drain];
        return result;
    }

    TestNote *note = [[[TestNote alloc] initWithTitle:@"Repository note"] autorelease];

    if (![repository insertNote:note error:&error]) {
        int result = failWithError(@"Could not insert repository note", error);
        [pool drain];
        return result;
    }

    NSArray *notes = [repository allNotes:&error];

    if (notes == nil) {
        int result = failWithError(@"Could not fetch repository notes", error);
        [pool drain];
        return result;
    }

    if ([notes count] != 1) {
        fprintf(stderr, "Expected one repository note, got %lu.\n", (unsigned long)[notes count]);
        [pool drain];
        return 1;
    }

    TestNote *fetchedNote = [notes objectAtIndex:0];

    if (![[fetchedNote title] isEqualToString:@"Repository note"]) {
        fprintf(stderr, "Unexpected repository note title.\n");
        [pool drain];
        return 1;
    }

    printf("LeoRM repository smoke test OK\n");

    [database close];

    [pool drain];
    return 0;
}
