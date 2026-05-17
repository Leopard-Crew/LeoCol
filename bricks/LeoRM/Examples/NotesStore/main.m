//
//  main.m
//  LeoRM NotesStore Example
//
//  Neutral domain-store proof for LeoRM.
//

#import <Foundation/Foundation.h>
#import "../../Sources/LeoRM.h"
#import "Note.h"
#import "NoteStore.h"

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
    LRMDatabase *database = nil;
    NoteStore *store = nil;
    NSArray *notes = nil;
    Note *note = nil;

    database = [LRMDatabase databaseWithPath:@":memory:"
                                       error:&error];

    if (database == nil || ![database open:&error]) {
        int result = failWithError(@"Could not open NotesStore database", error);
        [pool drain];
        return result;
    }

    store = [[[NoteStore alloc] initWithDatabase:database
                                          error:&error] autorelease];

    if (store == nil) {
        int result = failWithError(@"Could not create NotesStore", error);
        [pool drain];
        return result;
    }

    if (![store migrate:&error]) {
        int result = failWithError(@"Could not migrate NotesStore", error);
        [pool drain];
        return result;
    }

    if (![store addNoteWithTitle:@"First LeoRM note"
                            body:@"This note was stored through a neutral domain store."
                       createdAt:@"2026-05-15T00:00:00Z"
                           error:&error]) {
        int result = failWithError(@"Could not add note", error);
        [pool drain];
        return result;
    }

    notes = [store allNotes:&error];

    if (notes == nil) {
        int result = failWithError(@"Could not fetch notes", error);
        [pool drain];
        return result;
    }

    if ([notes count] != 1) {
        fprintf(stderr, "Expected one note, got %lu.\n", (unsigned long)[notes count]);
        [pool drain];
        return 1;
    }

    note = [notes objectAtIndex:0];

    if (![[note title] isEqualToString:@"First LeoRM note"]) {
        fprintf(stderr, "Unexpected note title.\n");
        [pool drain];
        return 1;
    }

    if (![[note createdAt] isEqualToString:@"2026-05-15T00:00:00Z"]) {
        fprintf(stderr, "Unexpected note creation date.\n");
        [pool drain];
        return 1;
    }

    printf("LeoRM NotesStore example OK\n");

    [database close];

    [pool drain];
    return 0;
}
