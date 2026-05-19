#import <Foundation/Foundation.h>

@interface LCProvenanceStore : NSObject

+ (NSArray *)loadEvidenceSummaryRowsWithStatusString:(NSString **)statusString;

@end
