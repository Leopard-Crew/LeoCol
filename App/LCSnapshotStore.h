#import <Foundation/Foundation.h>

/*!
 @class LCSnapshotStore
 @abstract Loads process snapshot summaries for the Cocoa viewer.
 @discussion
    LCSnapshotStore reads snapshot_run and process_observation from the LeoCol
    database. It provides read-only summary rows for the planned Snapshot
    Overview panel.
 */
@interface LCSnapshotStore : NSObject

/*!
 @method loadSnapshotSummaryRowsWithStatusString:
 @abstract Loads snapshot summary rows from the LeoCol database.
 @discussion
    Returned rows contain snapshot ID, observed timestamp, source, and process
    count. This makes LeoCol's snapshot-based model visible to the user.
 @param statusString Optional output parameter receiving a user-facing status string.
 @result An array of snapshot summary row dictionaries.
 */
+ (NSArray *)loadSnapshotSummaryRowsWithStatusString:(NSString **)statusString;

@end
