//
//  failure_paths_main.m
//  LeoRM
//
//  Failure-path smoke test.
//

#import <Foundation/Foundation.h>
#import "../Sources/LeoRM.h"

static int fail(NSString *message)
{
    fprintf(stderr, "%s\n", [message UTF8String]);
    return 1;
}

static BOOL errorLooksLikeLeoRM(NSError *error)
{
    return (error != nil && [[error domain] isEqualToString:LRMErrorDomain]);
}

static BOOL expectLeoRMFailure(BOOL condition, NSError *error, NSString *message)
{
    if (condition) {
        fprintf(stderr, "Expected failure did not happen: %s\n", [message UTF8String]);
        return NO;
    }

    if (!errorLooksLikeLeoRM(error)) {
        fprintf(stderr, "Expected LeoRM NSError for failure: %s\n", [message UTF8String]);
        return NO;
    }

    return YES;
}

static BOOL expectNilLeoRMFailure(id object, NSError *error, NSString *message)
{
    if (object != nil) {
        fprintf(stderr, "Expected nil result did not happen: %s\n", [message UTF8String]);
        return NO;
    }

    if (!errorLooksLikeLeoRM(error)) {
        fprintf(stderr, "Expected LeoRM NSError for nil failure: %s\n", [message UTF8String]);
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

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSError *error = nil;

    /*
     * Invalid database path.
     */
    error = nil;
    LRMDatabase *badPathDatabase = [LRMDatabase databaseWithPath:@""
                                                          error:&error];

    if (!expectNilLeoRMFailure(badPathDatabase, error, @"empty database path")) {
        [pool drain];
        return 1;
    }

    /*
     * Closed database: prepareStatement must fail.
     */
    error = nil;
    LRMDatabase *closedDatabase = [LRMDatabase databaseWithPath:@":memory:"
                                                         error:&error];

    if (closedDatabase == nil) {
        return fail(@"Could not create closed database object.");
    }

    error = nil;
    LRMStatement *closedPrepareStatement = [closedDatabase prepareStatement:@"CREATE TABLE x (id INTEGER)"
                                                                      error:&error];

    if (!expectNilLeoRMFailure(closedPrepareStatement, error, @"prepare on closed database")) {
        [pool drain];
        return 1;
    }

    /*
     * Closed database: repository creation must fail.
     */
    error = nil;
    LRMRepository *closedRepository = [[[LRMRepository alloc] initWithDatabase:closedDatabase
                                                                        error:&error] autorelease];

    if (!expectNilLeoRMFailure(closedRepository, error, @"repository with closed database")) {
        [pool drain];
        return 1;
    }

    /*
     * Open database for the remaining failure-path tests.
     */
    error = nil;
    LRMDatabase *database = [LRMDatabase databaseWithPath:@":memory:"
                                                    error:&error];

    if (database == nil || ![database open:&error]) {
        fprintf(stderr, "Could not open test database: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    /*
     * Empty SQL must fail.
     */
    error = nil;
    LRMStatement *emptySQLStatement = [database prepareStatement:@""
                                                          error:&error];

    if (!expectNilLeoRMFailure(emptySQLStatement, error, @"empty SQL")) {
        [pool drain];
        return 1;
    }

    /*
     * Prepare valid table for binding tests.
     */
    error = nil;
    if (!executeSQL(database, @"CREATE TABLE values_table (id INTEGER PRIMARY KEY, title TEXT)", &error)) {
        fprintf(stderr, "Could not create values_table: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    /*
     * Bind index 0 must fail because SQLite bind indexes start at 1.
     */
    error = nil;
    LRMStatement *bindIndexStatement = [database prepareStatement:@"INSERT INTO values_table (title) VALUES (?)"
                                                           error:&error];

    if (bindIndexStatement == nil) {
        fprintf(stderr, "Could not prepare bind index statement: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    error = nil;
    if (!expectLeoRMFailure([bindIndexStatement bindObject:@"wrong index"
                                                   atIndex:0
                                                     error:&error],
                            error,
                            @"bind index 0")) {
        [pool drain];
        return 1;
    }

    [bindIndexStatement finalizeStatement];

    /*
     * Unsupported bind object must fail.
     */
    error = nil;
    LRMStatement *unsupportedBindStatement = [database prepareStatement:@"INSERT INTO values_table (title) VALUES (?)"
                                                                  error:&error];

    if (unsupportedBindStatement == nil) {
        fprintf(stderr, "Could not prepare unsupported bind statement: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    error = nil;
    if (!expectLeoRMFailure([unsupportedBindStatement bindObject:[NSArray arrayWithObject:@"not supported"]
                                                        atIndex:1
                                                          error:&error],
                            error,
                            @"unsupported bind object")) {
        [pool drain];
        return 1;
    }

    [unsupportedBindStatement finalizeStatement];

    /*
     * Executing a finalized statement must fail.
     */
    error = nil;
    LRMStatement *finalizedStatement = [database prepareStatement:@"CREATE TABLE finalized_test (id INTEGER)"
                                                           error:&error];

    if (finalizedStatement == nil) {
        fprintf(stderr, "Could not prepare finalized statement test: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    [finalizedStatement finalizeStatement];

    error = nil;
    if (!expectLeoRMFailure([finalizedStatement executeUpdate:&error],
                            error,
                            @"execute finalized statement")) {
        [pool drain];
        return 1;
    }

    /*
     * Inactive transaction double-use must fail.
     */
    error = nil;
    LRMTransaction *transaction = [database beginTransaction:&error];

    if (transaction == nil) {
        fprintf(stderr, "Could not begin transaction: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    if (![transaction rollback:&error]) {
        fprintf(stderr, "Could not rollback active transaction: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    error = nil;
    if (!expectLeoRMFailure([transaction commit:&error],
                            error,
                            @"commit inactive transaction")) {
        [pool drain];
        return 1;
    }

    /*
     * Missing migration step must fail.
     */
    error = nil;
    LRMMigration *migration12 = [LRMMigration migrationFromVersion:1
                                                         toVersion:2
                                                     SQLStatements:[NSArray arrayWithObject:@"CREATE TABLE missing_step (id INTEGER)"]];

    LRMSchema *missingStepSchema = [LRMSchema schemaWithName:@"missing_step"
                                               targetVersion:2
                                                  migrations:[NSArray arrayWithObject:migration12]
                                                       error:&error];

    if (missingStepSchema == nil) {
        fprintf(stderr, "Could not create missing-step schema: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    LRMMigrationRunner *runner = [[[LRMMigrationRunner alloc] init] autorelease];

    error = nil;
    if (!expectLeoRMFailure([runner migrateDatabase:database
                                             schema:missingStepSchema
                                              error:&error],
                            error,
                            @"missing migration step")) {
        [pool drain];
        return 1;
    }

    /*
     * Current schema version newer than target must fail.
     */
    error = nil;
    if (![database setSchemaVersion:3
                      forSchemaName:@"newer_schema"
                              error:&error]) {
        fprintf(stderr, "Could not set newer schema version: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    LRMSchema *olderTargetSchema = [LRMSchema schemaWithName:@"newer_schema"
                                               targetVersion:2
                                                  migrations:[NSArray array]
                                                       error:&error];

    if (olderTargetSchema == nil) {
        fprintf(stderr, "Could not create older-target schema: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    error = nil;
    if (!expectLeoRMFailure([runner migrateDatabase:database
                                             schema:olderTargetSchema
                                              error:&error],
                            error,
                            @"schema version newer than target")) {
        [pool drain];
        return 1;
    }

    printf("LeoRM failure-path smoke test OK\n");

    [database close];

    [pool drain];
    return 0;
}
