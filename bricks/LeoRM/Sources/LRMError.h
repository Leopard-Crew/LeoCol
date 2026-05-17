//
//  LRMError.h
//  LeoRM
//
//  Public error definitions for LeoRM.
//

#import <Foundation/Foundation.h>

struct sqlite3;

/*!
 * @header LRMError
 * @abstract NSError support for LeoRM.
 * @discussion
 * LeoRM reports public failures through NSError. This header defines the
 * LeoRM error domain, common error codes, userInfo keys, and helper functions
 * used to build Cocoa-shaped errors from SQLite failures.
 *
 * SQLite errors should preserve enough context to be useful without stepping
 * into LeoRM internals: SQLite result code, SQLite message, SQL string where
 * available, and database path where available.
 */

/*!
 * @const LRMErrorDomain
 * @abstract NSError domain used by LeoRM.
 */
extern NSString * const LRMErrorDomain;

/*!
 * @const LRMErrorSQLiteCodeKey
 * @abstract userInfo key for the raw SQLite result code as an NSNumber.
 */
extern NSString * const LRMErrorSQLiteCodeKey;

/*!
 * @const LRMErrorSQLiteMessageKey
 * @abstract userInfo key for the raw SQLite error message as an NSString.
 */
extern NSString * const LRMErrorSQLiteMessageKey;

/*!
 * @const LRMErrorSQLKey
 * @abstract userInfo key for the SQL string related to the failure.
 * @discussion
 * This key is present only when the failing operation had a meaningful SQL
 * string available.
 */
extern NSString * const LRMErrorSQLKey;

/*!
 * @const LRMErrorDatabasePathKey
 * @abstract userInfo key for the database path related to the failure.
 * @discussion
 * This key is present only when the failing operation had a database path
 * available.
 */
extern NSString * const LRMErrorDatabasePathKey;

/*!
 * @enum LeoRM error codes
 * @abstract Public LeoRM error codes.
 * @constant LRMErrorUnknown Generic fallback error.
 * @constant LRMErrorInvalidArgument Invalid caller input or invalid API state.
 * @constant LRMErrorSQLite SQLite operation failure. The raw SQLite code is
 * stored under LRMErrorSQLiteCodeKey.
 */
enum {
    LRMErrorUnknown = 1,
    LRMErrorInvalidArgument = 2,
    LRMErrorSQLite = 100
};

/*!
 * @function LRMErrorMake
 * @abstract Creates a basic LeoRM NSError.
 * @param code LeoRM error code.
 * @param message Human-readable error message. If nil or empty, a default
 * message is used.
 * @result Returns an autoreleased NSError using LRMErrorDomain.
 * @discussion
 * Use this helper for LeoRM-level errors that are not direct SQLite failures,
 * for example invalid arguments or invalid object lifecycle state.
 */
NSError *LRMErrorMake(NSInteger code, NSString *message);

/*!
 * @function LRMErrorMakeWithUserInfo
 * @abstract Creates a LeoRM NSError with additional userInfo entries.
 * @param code LeoRM error code.
 * @param message Human-readable error message. If nil or empty, a default
 * message is used.
 * @param extraUserInfo Optional dictionary merged into the returned error's
 * userInfo.
 * @result Returns an autoreleased NSError using LRMErrorDomain.
 * @discussion
 * Values in extraUserInfo are added after the localized description is set.
 * Passing nil for extraUserInfo is valid.
 */
NSError *LRMErrorMakeWithUserInfo(NSInteger code, NSString *message, NSDictionary *extraUserInfo);

/*!
 * @function LRMSQLiteErrorMake
 * @abstract Creates a LeoRM NSError from a SQLite failure.
 * @param database SQLite database handle. May be NULL, but when provided it is
 * used to retrieve sqlite3_errmsg().
 * @param sqliteCode Raw SQLite result code.
 * @param sql Optional SQL string related to the failure.
 * @param databasePath Optional database path related to the failure.
 * @result Returns an autoreleased NSError using LRMErrorDomain and code
 * LRMErrorSQLite.
 * @discussion
 * The returned error includes LRMErrorSQLiteCodeKey and
 * LRMErrorSQLiteMessageKey. It includes LRMErrorSQLKey and
 * LRMErrorDatabasePathKey only when those values are available.
 */
NSError *LRMSQLiteErrorMake(struct sqlite3 *database,
                            int sqliteCode,
                            NSString *sql,
                            NSString *databasePath);
