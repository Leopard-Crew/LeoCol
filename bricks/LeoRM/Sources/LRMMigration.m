//
//  LRMMigration.m
//  LeoRM
//
//  Explicit schema migration step for LeoRM V1.
//

#import "LRMMigration.h"
#import "LRMDatabase.h"
#import "LRMStatement.h"
#import "LRMError.h"

@implementation LRMMigration

+ (id)migrationFromVersion:(NSInteger)fromVersion
                 toVersion:(NSInteger)toVersion
             SQLStatements:(NSArray *)SQLStatements
{
    return [[[self alloc] initFromVersion:fromVersion
                                toVersion:toVersion
                            SQLStatements:SQLStatements] autorelease];
}

- (id)initFromVersion:(NSInteger)fromVersion
            toVersion:(NSInteger)toVersion
        SQLStatements:(NSArray *)SQLStatements
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _fromVersion = fromVersion;
    _toVersion = toVersion;
    _SQLStatements = [SQLStatements copy];

    return self;
}

- (void)dealloc
{
    [_SQLStatements release];

    [super dealloc];
}

- (NSInteger)fromVersion
{
    return _fromVersion;
}

- (NSInteger)toVersion
{
    return _toVersion;
}

- (NSArray *)SQLStatements
{
    return _SQLStatements;
}

- (BOOL)applyToDatabase:(LRMDatabase *)database error:(NSError **)error
{
    NSUInteger index = 0;

    if (database == nil || ![database isOpen]) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Database must be open before applying a migration.");
        }

        return NO;
    }

    if (_toVersion <= _fromVersion) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Migration target version must be greater than source version.");
        }

        return NO;
    }

    for (index = 0; index < [_SQLStatements count]; index++) {
        id item = [_SQLStatements objectAtIndex:index];
        LRMStatement *statement = nil;

        if (![item isKindOfClass:[NSString class]] || [item length] == 0) {
            if (error != NULL) {
                *error = LRMErrorMake(LRMErrorInvalidArgument, @"Migration SQL statement must be a non-empty NSString.");
            }

            return NO;
        }

        statement = [database prepareStatement:item error:error];

        if (statement == nil) {
            return NO;
        }

        if (![statement executeUpdate:error]) {
            [statement finalizeStatement];
            return NO;
        }

        [statement finalizeStatement];
    }

    return YES;
}

@end
