#import <Foundation/Foundation.h>

/*!
 @header LCString
 @abstract Localization helper for LeoCol.
 @discussion
    LCString resolves Localizable.strings keys for the Cocoa application layer.
 */

/*!
 @function LCString
 @abstract Returns a localized string for a LeoCol localization key.
 @discussion
    LCString is the small application-level localization helper used by the
    Cocoa viewer. It resolves keys through Localizable.strings and deliberately
    keeps localization access out of the view/controller code.
 @param key The localization key to resolve.
 @result The localized string, or the key itself when no localized value exists.
 */
NSString *LCString(NSString *key);
