#import <Foundation/Foundation.h>

@class LRMDatabase;

/*!
 @class LCStoreSupport
 @abstract Shared store support helpers for LeoCol's LeoRM-backed stores.
 @discussion
    LCStoreSupport centralizes project path, database path, and database open
    logic for the Cocoa application stores. It keeps LeoRM usage consistent
    without hiding SQL or domain-specific row mapping.
 */
@interface LCStoreSupport : NSObject

/*!
 @method projectPath
 @abstract Returns the LeoCol project path for the current app bundle.
 @result The project root path used by development builds.
 */
+ (NSString *)projectPath;

/*!
 @method databasePath
 @abstract Returns the LeoCol SQLite database path.
 @result The project-relative Probe/results/leocol-v1.db path.
 */
+ (NSString *)databasePath;

/*!
 @method openDatabaseWithStatusString:
 @abstract Opens the LeoCol database through LeoRM.
 @param statusString Optional output parameter receiving a localized user-facing status string on failure.
 @result An open autoreleased LRMDatabase, or nil on failure.
 */
+ (LRMDatabase *)openDatabaseWithStatusString:(NSString **)statusString;

@end
