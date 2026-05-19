#import <Foundation/Foundation.h>

/*!
 @class LCProvenanceStore
 @abstract Loads provenance evidence summaries for the Cocoa viewer.
 @discussion
    LCProvenanceStore reads grouped evidence counts from provenance_evidence.
    It does not run probes and does not modify the system.
 */
@interface LCProvenanceStore : NSObject

/*!
 @method loadEvidenceSummaryRowsWithStatusString:
 @abstract Loads grouped provenance evidence summary rows.
 @discussion
    Returned rows are grouped by evidence type and resolution state.
 @param statusString Optional output parameter receiving a user-facing status string.
 @result An array of evidence summary row dictionaries.
 */
+ (NSArray *)loadEvidenceSummaryRowsWithStatusString:(NSString **)statusString;

@end
