//
//  LRMMigrationRunner.m
//  LeoRM
//
//  Ordered schema migration runner for LeoRM V1.
//

#import "LRMMigrationRunner.h"
#import "LRMDatabase.h"
#import "LRMMigration.h"
#import "LRMSchema.h"
#import "LRMTransaction.h"
#import "LRMError.h"

@implementation LRMMigrationRunner

- (LRMMigration *)migrationFromVersion:(NSInteger)version
                              inSchema:(LRMSchema *)schema
{
    NSUInteger index = 0;
    NSArray *migrations = [schema migrations];

    for (index = 0; index < [migrations count]; index++) {
        LRMMigration *migration = [migrations objectAtIndex:index];

        if ([migration fromVersion] == version) {
            return migration;
        }
    }

    return nil;
}

- (BOOL)migrateDatabase:(LRMDatabase *)database
                 schema:(LRMSchema *)schema
                  error:(NSError **)error
{
    NSInteger currentVersion = 0;
    NSInteger targetVersion = 0;

    if (database == nil || ![database isOpen]) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Database must be open before running migrations.");
        }

        return NO;
    }

    if (schema == nil) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Schema must not be nil.");
        }

        return NO;
    }

    targetVersion = [schema targetVersion];

    if (![database getSchemaVersion:&currentVersion
                      forSchemaName:[schema name]
                              error:error]) {
        return NO;
    }

    if (currentVersion > targetVersion) {
        if (error != NULL) {
            NSString *message = [NSString stringWithFormat:@"Database schema version %ld is newer than target version %ld.",
                                                           (long)currentVersion,
                                                           (long)targetVersion];
            *error = LRMErrorMake(LRMErrorInvalidArgument, message);
        }

        return NO;
    }

    while (currentVersion < targetVersion) {
        LRMMigration *migration = nil;
        LRMTransaction *transaction = nil;

        migration = [self migrationFromVersion:currentVersion
                                      inSchema:schema];

        if (migration == nil) {
            if (error != NULL) {
                NSString *message = [NSString stringWithFormat:@"Missing migration from schema version %ld.",
                                                               (long)currentVersion];
                *error = LRMErrorMake(LRMErrorInvalidArgument, message);
            }

            return NO;
        }

        if ([migration toVersion] <= currentVersion || [migration toVersion] > targetVersion) {
            if (error != NULL) {
                NSString *message = [NSString stringWithFormat:@"Invalid migration step %ld -> %ld for target version %ld.",
                                                               (long)[migration fromVersion],
                                                               (long)[migration toVersion],
                                                               (long)targetVersion];
                *error = LRMErrorMake(LRMErrorInvalidArgument, message);
            }

            return NO;
        }

        transaction = [database beginTransaction:error];

        if (transaction == nil) {
            return NO;
        }

        if (![migration applyToDatabase:database error:error]) {
            [transaction rollback:NULL];
            return NO;
        }

        if (![database setSchemaVersion:[migration toVersion]
                          forSchemaName:[schema name]
                                  error:error]) {
            [transaction rollback:NULL];
            return NO;
        }

        if (![transaction commit:error]) {
            return NO;
        }

        currentVersion = [migration toVersion];
    }

    return YES;
}

@end
