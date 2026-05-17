//
//  LRMTransaction.m
//  LeoRM
//
//  Explicit SQLite transaction wrapper for LeoRM V1.
//

#import "LRMTransaction.h"
#import "LRMDatabase.h"
#import "LRMStatement.h"
#import "LRMError.h"

@implementation LRMTransaction

- (BOOL)executeTransactionSQL:(NSString *)sql error:(NSError **)error
{
    BOOL ok = NO;
    LRMStatement *statement = nil;

    statement = [_database prepareStatement:sql error:error];

    if (statement == nil) {
        return NO;
    }

    ok = [statement executeUpdate:error];

    [statement finalizeStatement];

    return ok;
}

- (id)initWithDatabase:(LRMDatabase *)database error:(NSError **)error
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    if (database == nil || ![database isOpen]) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Database must be open before beginning a transaction.");
        }

        [self release];
        return nil;
    }

    _database = [database retain];
    _active = NO;

    if (![self executeTransactionSQL:@"BEGIN TRANSACTION" error:error]) {
        [_database release];
        _database = nil;

        [self release];
        return nil;
    }

    _active = YES;

    return self;
}

- (void)dealloc
{
    if (_active) {
        [self rollback:NULL];
    }

    [_database release];

    [super dealloc];
}

- (BOOL)commit:(NSError **)error
{
    if (!_active) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Cannot commit an inactive transaction.");
        }

        return NO;
    }

    if (![self executeTransactionSQL:@"COMMIT" error:error]) {
        return NO;
    }

    _active = NO;

    return YES;
}

- (BOOL)rollback:(NSError **)error
{
    if (!_active) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Cannot rollback an inactive transaction.");
        }

        return NO;
    }

    if (![self executeTransactionSQL:@"ROLLBACK" error:error]) {
        return NO;
    }

    _active = NO;

    return YES;
}

- (BOOL)isActive
{
    return _active;
}

@end
