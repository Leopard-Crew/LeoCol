//
//  transaction_main.m
//  LeoRM
//
//  Transaction smoke test.
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

static BOOL insertNote(LRMDatabase *database, NSString *title, NSError **error)
{
    BOOL ok = NO;
    LRMStatement *statement = [database prepareStatement:@"INSERT INTO notes (title) VALUES (?)"
                                                   error:error];

    if (statement == nil) {
        return NO;
    }

    ok = [statement bindObject:title atIndex:1 error:error];

    if (ok) {
        ok = [statement executeUpdate:error];
    }

    [statement finalizeStatement];

    return ok;
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
    NSInteger count = 0;

    LRMDatabase *database = [LRMDatabase databaseWithPath:@":memory:"
                                                    error:&error];

    if (database == nil || ![database open:&error]) {
        int result = failWithError(@"Could not open database", error);
        [pool drain];
        return result;
    }

    if (!executeSQL(database, @"CREATE TABLE notes (id INTEGER PRIMARY KEY, title TEXT NOT NULL)", &error)) {
        int result = failWithError(@"Could not create table", error);
        [pool drain];
        return result;
    }

    LRMTransaction *commitTransaction = [database beginTransaction:&error];

    if (commitTransaction == nil || ![commitTransaction isActive]) {
        int result = failWithError(@"Could not begin commit transaction", error);
        [pool drain];
        return result;
    }

    if (!insertNote(database, @"Committed note", &error)) {
        int result = failWithError(@"Could not insert committed note", error);
        [pool drain];
        return result;
    }

    if (![commitTransaction commit:&error]) {
        int result = failWithError(@"Could not commit transaction", error);
        [pool drain];
        return result;
    }

    if ([commitTransaction isActive]) {
        fprintf(stderr, "Commit transaction should be inactive after commit.\n");
        [pool drain];
        return 1;
    }

    if (![commitTransaction rollback:&error]) {
        if ([error code] != LRMErrorInvalidArgument) {
            int result = failWithError(@"Unexpected double-use transaction error", error);
            [pool drain];
            return result;
        }
    } else {
        fprintf(stderr, "Rollback after commit should not succeed.\n");
        [pool drain];
        return 1;
    }

    if (!readNoteCount(database, &count, &error)) {
        int result = failWithError(@"Could not read note count after commit", error);
        [pool drain];
        return result;
    }

    if (count != 1) {
        fprintf(stderr, "Expected one committed note, got %ld.\n", (long)count);
        [pool drain];
        return 1;
    }

    LRMTransaction *rollbackTransaction = [database beginTransaction:&error];

    if (rollbackTransaction == nil || ![rollbackTransaction isActive]) {
        int result = failWithError(@"Could not begin rollback transaction", error);
        [pool drain];
        return result;
    }

    if (!insertNote(database, @"Rolled back note", &error)) {
        int result = failWithError(@"Could not insert rollback note", error);
        [pool drain];
        return result;
    }

    if (![rollbackTransaction rollback:&error]) {
        int result = failWithError(@"Could not rollback transaction", error);
        [pool drain];
        return result;
    }

    if ([rollbackTransaction isActive]) {
        fprintf(stderr, "Rollback transaction should be inactive after rollback.\n");
        [pool drain];
        return 1;
    }

    if (!readNoteCount(database, &count, &error)) {
        int result = failWithError(@"Could not read note count after rollback", error);
        [pool drain];
        return result;
    }

    if (count != 1) {
        fprintf(stderr, "Expected rollback to keep note count at one, got %ld.\n", (long)count);
        [pool drain];
        return 1;
    }

    printf("LeoRM transaction smoke test OK\n");

    [database close];

    [pool drain];
    return 0;
}
