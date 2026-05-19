#import <Foundation/Foundation.h>

/*!
 @function LCPresentationStringForValue
 @abstract Maps canonical LeoCol values to localized presentation strings.
 @discussion
    The database keeps canonical technical values such as "resolved",
    "observed-only", "present", or "receipt-bom". This helper translates those
    values into user-facing strings for the Cocoa viewer without changing the
    stored data.
 @param value The canonical value to present.
 @param key The row key that describes the value category.
 @param detail Pass YES for detail/inspector presentation, NO for table cells.
 @result A localized presentation string.
 */
NSString *LCPresentationStringForValue(id value, NSString *key, BOOL detail);
