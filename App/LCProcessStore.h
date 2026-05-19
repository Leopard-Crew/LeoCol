#import <Foundation/Foundation.h>

/*!
 @class LCProcessStore
 @abstract Loads process lifecycle rows for the Cocoa viewer.
 @discussion
    LCProcessStore owns the read-only LeoRM/SQLite access used by the viewer.
    It returns row dictionaries and keeps SQL/database details out of
    LCAppDelegate.
 */
@interface LCProcessStore : NSObject

/*!
 @method loadProcessRowsWithStatusString:
 @abstract Loads process rows from the LeoCol database.
 @discussion
    The method returns viewer-ready dictionaries. If the database is missing or
    unreadable, fallback rows may be returned and statusString describes the
    condition.
 @param statusString Optional output parameter receiving a user-facing status string.
 @result An array of process row dictionaries.
 */
+ (NSArray *)loadProcessRowsWithStatusString:(NSString **)statusString;

@end
