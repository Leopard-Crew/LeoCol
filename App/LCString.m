#import "LCString.h"

NSString *
LCString(NSString *key)
{
    return [[NSBundle mainBundle] localizedStringForKey:key
                                                  value:key
                                                  table:@"Localizable"];
}
