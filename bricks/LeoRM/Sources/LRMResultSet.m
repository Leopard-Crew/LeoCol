//
//  LRMResultSet.m
//  LeoRM
//
//  SQLite result set wrapper for LeoRM V1.
//

#import "LRMResultSet.h"
#import "LRMRow.h"
#import "LRMStatement.h"
#import "Private/LRMStatementPrivate.h"
#import "LRMError.h"

#import <sqlite3.h>

@implementation LRMResultSet

- (id)initWithStatement:(LRMStatement *)statement
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _statement = [statement retain];
    _currentRow = nil;
    _closed = NO;

    return self;
}

- (void)dealloc
{
    [self close];

    [super dealloc];
}

- (BOOL)next:(NSError **)error
{
    int result = SQLITE_OK;

    if (_closed) {
        return NO;
    }

    [_currentRow release];
    _currentRow = nil;

    result = sqlite3_step([_statement sqliteStatement]);

    if (result == SQLITE_ROW) {
        _currentRow = [[LRMRow alloc] initWithStatement:(void *)[_statement sqliteStatement]];
        return YES;
    }

    if (result == SQLITE_DONE) {
        [self close];
        return NO;
    }

    if (error != NULL) {
        *error = LRMSQLiteErrorMake([_statement sqliteDatabase],
                                    result,
                                    [_statement sql],
                                    [_statement databasePath]);
    }

    [self close];

    return NO;
}

- (LRMRow *)currentRow
{
    return _currentRow;
}

- (void)close
{
    if (!_closed) {
        [_currentRow release];
        _currentRow = nil;

        [_statement finalizeStatement];
        [_statement release];
        _statement = nil;

        _closed = YES;
    }
}

- (BOOL)isClosed
{
    return _closed;
}

@end
