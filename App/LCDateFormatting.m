#import "LCDateFormatting.h"

static NSDate *
LCDateFromCanonicalTimestamp(NSString *timestamp)
{
    NSDateFormatter *parser;
    NSDate *date;

    if (timestamp == nil || [timestamp length] == 0 || [timestamp isEqualToString:@"-"]) {
        return nil;
    }

    parser = [[NSDateFormatter alloc] init];
    [parser setFormatterBehavior:NSDateFormatterBehavior10_4];
    [parser setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
    [parser setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];

    date = [[parser dateFromString:timestamp] retain];
    [parser release];

    return [date autorelease];
}

NSString *
LCDisplayCompactTimestampString(NSString *timestamp)
{
    NSDateFormatter *displayFormatter;
    NSDate *date;
    NSString *result;

    date = LCDateFromCanonicalTimestamp(timestamp);

    if (date == nil) {
        if (timestamp == nil || [timestamp isEqualToString:@"-"]) {
            return @"";
        }

        return timestamp;
    }

    displayFormatter = [[NSDateFormatter alloc] init];
    [displayFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [displayFormatter setDateStyle:NSDateFormatterShortStyle];
    [displayFormatter setTimeStyle:NSDateFormatterShortStyle];

    result = [[displayFormatter stringFromDate:date] retain];
    [displayFormatter release];

    return [result autorelease];
}

NSString *
LCDisplayTimestampString(NSString *timestamp)
{
    NSDateFormatter *displayFormatter;
    NSDate *date;
    NSString *result;

    date = LCDateFromCanonicalTimestamp(timestamp);

    if (date == nil) {
        if (timestamp == nil || [timestamp isEqualToString:@"-"]) {
            return @"-";
        }

        return timestamp;
    }

    displayFormatter = [[NSDateFormatter alloc] init];
    [displayFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [displayFormatter setDateStyle:NSDateFormatterMediumStyle];
    [displayFormatter setTimeStyle:NSDateFormatterMediumStyle];

    result = [[displayFormatter stringFromDate:date] retain];
    [displayFormatter release];

    return [result autorelease];
}
