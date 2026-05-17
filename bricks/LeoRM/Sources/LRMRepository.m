//
//  LRMRepository.m
//  LeoRM
//
//  Minimal DAO-style repository helper for LeoRM V1.
//

#import "LRMRepository.h"
#import "LRMDatabase.h"
#import "LRMStatement.h"
#import "LRMResultSet.h"
#import "LRMError.h"

@implementation LRMRepository

- (id)initWithDatabase:(LRMDatabase *)database error:(NSError **)error
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    if (database == nil || ![database isOpen]) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Repository requires an open database.");
        }

        [self release];
        return nil;
    }

    _database = [database retain];

    return self;
}

- (void)dealloc
{
    [_database release];

    [super dealloc];
}

- (LRMDatabase *)database
{
    return _database;
}

- (BOOL)bindArguments:(NSArray *)arguments
          toStatement:(LRMStatement *)statement
                error:(NSError **)error
{
    NSUInteger index = 0;

    if (statement == nil) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Cannot bind arguments to a nil statement.");
        }

        return NO;
    }

    for (index = 0; index < [arguments count]; index++) {
        id value = [arguments objectAtIndex:index];

        if (![statement bindObject:value
                            atIndex:(NSInteger)index + 1
                              error:error]) {
            return NO;
        }
    }

    return YES;
}

- (BOOL)executeSQL:(NSString *)sql
         arguments:(NSArray *)arguments
             error:(NSError **)error
{
    BOOL ok = NO;
    LRMStatement *statement = nil;

    statement = [_database prepareStatement:sql error:error];

    if (statement == nil) {
        return NO;
    }

    if (![self bindArguments:arguments toStatement:statement error:error]) {
        [statement finalizeStatement];
        return NO;
    }

    ok = [statement executeUpdate:error];

    [statement finalizeStatement];

    return ok;
}

- (LRMResultSet *)resultSetForSQL:(NSString *)sql
                        arguments:(NSArray *)arguments
                            error:(NSError **)error
{
    LRMStatement *statement = nil;
    LRMResultSet *resultSet = nil;

    statement = [_database prepareStatement:sql error:error];

    if (statement == nil) {
        return nil;
    }

    if (![self bindArguments:arguments toStatement:statement error:error]) {
        [statement finalizeStatement];
        return nil;
    }

    resultSet = [statement executeQuery:error];

    if (resultSet == nil) {
        [statement finalizeStatement];
        return nil;
    }

    return resultSet;
}

@end
