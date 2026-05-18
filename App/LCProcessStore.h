#import <Foundation/Foundation.h>

@interface LCProcessStore : NSObject

+ (NSArray *)loadProcessRowsWithStatusString:(NSString **)statusString;

@end
