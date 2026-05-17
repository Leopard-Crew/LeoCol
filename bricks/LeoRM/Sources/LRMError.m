//
//  LRMError.m
//  LeoRM
//
//  Error definitions for LeoRM.
//

#import "LRMError.h"

#import <sqlite3.h>

NSString * const LRMErrorDomain = @"org.quietcode.LeoRM";

NSString * const LRMErrorSQLiteCodeKey = @"LRMErrorSQLiteCode";
NSString * const LRMErrorSQLiteMessageKey = @"LRMErrorSQLiteMessage";
NSString * const LRMErrorSQLKey = @"LRMErrorSQL";
NSString * const LRMErrorDatabasePathKey = @"LRMErrorDatabasePath";

static NSString *LRMMessageOrDefault(NSString *message)
{
    if (message != nil && [message length] > 0) {
        return message;
    }

    return @"LeoRM error.";
}

NSError *LRMErrorMake(NSInteger code, NSString *message)
{
    return LRMErrorMakeWithUserInfo(code, message, nil);
}

NSError *LRMErrorMakeWithUserInfo(NSInteger code, NSString *message, NSDictionary *extraUserInfo)
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

    [userInfo setObject:LRMMessageOrDefault(message)
                 forKey:NSLocalizedDescriptionKey];

    if (extraUserInfo != nil) {
        [userInfo addEntriesFromDictionary:extraUserInfo];
    }

    return [NSError errorWithDomain:LRMErrorDomain
                               code:code
                           userInfo:userInfo];
}

NSError *LRMSQLiteErrorMake(struct sqlite3 *database,
                            int sqliteCode,
                            NSString *sql,
                            NSString *databasePath)
{
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];

    NSString *sqliteMessage = nil;

    if (database != NULL) {
        const char *rawMessage = sqlite3_errmsg(database);

        if (rawMessage != NULL) {
            sqliteMessage = [NSString stringWithUTF8String:rawMessage];
        }
    }

    if (sqliteMessage == nil) {
        sqliteMessage = @"SQLite error.";
    }

    [userInfo setObject:sqliteMessage
                 forKey:NSLocalizedDescriptionKey];

    [userInfo setObject:[NSNumber numberWithInt:sqliteCode]
                 forKey:LRMErrorSQLiteCodeKey];

    [userInfo setObject:sqliteMessage
                 forKey:LRMErrorSQLiteMessageKey];

    if (sql != nil) {
        [userInfo setObject:sql
                     forKey:LRMErrorSQLKey];
    }

    if (databasePath != nil) {
        [userInfo setObject:databasePath
                     forKey:LRMErrorDatabasePathKey];
    }

    return [NSError errorWithDomain:LRMErrorDomain
                               code:LRMErrorSQLite
                           userInfo:userInfo];
}
