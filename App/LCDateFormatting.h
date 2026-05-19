#import <Foundation/Foundation.h>

/*!
 @function LCDisplayCompactTimestampString
 @abstract Formats a canonical LeoCol timestamp for compact table display.
 @discussion
    The input timestamp is expected to use LeoCol's canonical database format.
    The returned value follows the user's current system locale.
 @param timestamp A canonical timestamp string.
 @result A compact localized date/time string, or an empty string when no value is available.
 */
NSString *LCDisplayCompactTimestampString(NSString *timestamp);

/*!
 @function LCDisplayTimestampString
 @abstract Formats a canonical LeoCol timestamp for inspector display.
 @discussion
    This formatter is used for the Process Details inspector where a slightly
    more descriptive localized date/time representation is appropriate.
 @param timestamp A canonical timestamp string.
 @result A localized date/time string, or "-" when no value is available.
 */
NSString *LCDisplayTimestampString(NSString *timestamp);
