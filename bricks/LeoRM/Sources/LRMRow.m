//
//  LRMRow.m
//  LeoRM
//
//  SQLite result row access for LeoRM V1.
//

#import "LRMRow.h"

#import <sqlite3.h>
#import <string.h>

@implementation LRMRow

- (id)initWithStatement:(void *)statement
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _statement = statement;

    return self;
}

- (NSInteger)columnCount
{
    if (_statement == NULL) {
        return 0;
    }

    return (NSInteger)sqlite3_column_count((sqlite3_stmt *)_statement);
}

- (NSString *)columnNameAtIndex:(NSInteger)index
{
    const char *name = NULL;

    if (_statement == NULL || index < 0 || index >= [self columnCount]) {
        return nil;
    }

    name = sqlite3_column_name((sqlite3_stmt *)_statement, (int)index);

    if (name == NULL) {
        return nil;
    }

    return [NSString stringWithUTF8String:name];
}

- (NSInteger)indexForColumn:(NSString *)name
{
    NSInteger index = 0;
    NSInteger count = [self columnCount];

    if (name == nil) {
        return -1;
    }

    for (index = 0; index < count; index++) {
        NSString *candidate = [self columnNameAtIndex:index];

        if (candidate != nil && [candidate isEqualToString:name]) {
            return index;
        }
    }

    return -1;
}

- (id)objectAtIndex:(NSInteger)index
{
    int type = SQLITE_NULL;
    const unsigned char *text = NULL;
    const void *bytes = NULL;
    int length = 0;

    if (_statement == NULL || index < 0 || index >= [self columnCount]) {
        return nil;
    }

    type = sqlite3_column_type((sqlite3_stmt *)_statement, (int)index);

    switch (type) {
        case SQLITE_TEXT:
            text = sqlite3_column_text((sqlite3_stmt *)_statement, (int)index);
            if (text == NULL) {
                return nil;
            }
            return [NSString stringWithUTF8String:(const char *)text];

        case SQLITE_INTEGER:
            return [NSNumber numberWithLongLong:(long long)sqlite3_column_int64((sqlite3_stmt *)_statement, (int)index)];

        case SQLITE_FLOAT:
            return [NSNumber numberWithDouble:sqlite3_column_double((sqlite3_stmt *)_statement, (int)index)];

        case SQLITE_BLOB:
            bytes = sqlite3_column_blob((sqlite3_stmt *)_statement, (int)index);
            length = sqlite3_column_bytes((sqlite3_stmt *)_statement, (int)index);

            if (bytes == NULL || length <= 0) {
                return [NSData data];
            }

            return [NSData dataWithBytes:bytes length:(NSUInteger)length];

        case SQLITE_NULL:
        default:
            return nil;
    }
}

- (id)objectForColumn:(NSString *)name
{
    NSInteger index = [self indexForColumn:name];

    if (index < 0) {
        return nil;
    }

    return [self objectAtIndex:index];
}

- (NSString *)stringAtIndex:(NSInteger)index
{
    id value = [self objectAtIndex:index];

    if ([value isKindOfClass:[NSString class]]) {
        return value;
    }

    if ([value respondsToSelector:@selector(stringValue)]) {
        return [value stringValue];
    }

    return nil;
}

- (NSString *)stringForColumn:(NSString *)name
{
    NSInteger index = [self indexForColumn:name];

    if (index < 0) {
        return nil;
    }

    return [self stringAtIndex:index];
}

- (NSNumber *)numberAtIndex:(NSInteger)index
{
    id value = [self objectAtIndex:index];

    if ([value isKindOfClass:[NSNumber class]]) {
        return value;
    }

    return nil;
}

- (NSNumber *)numberForColumn:(NSString *)name
{
    NSInteger index = [self indexForColumn:name];

    if (index < 0) {
        return nil;
    }

    return [self numberAtIndex:index];
}

- (NSData *)dataAtIndex:(NSInteger)index
{
    id value = [self objectAtIndex:index];

    if ([value isKindOfClass:[NSData class]]) {
        return value;
    }

    return nil;
}

- (NSData *)dataForColumn:(NSString *)name
{
    NSInteger index = [self indexForColumn:name];

    if (index < 0) {
        return nil;
    }

    return [self dataAtIndex:index];
}

- (BOOL)isNullAtIndex:(NSInteger)index
{
    if (_statement == NULL || index < 0 || index >= [self columnCount]) {
        return YES;
    }

    return (sqlite3_column_type((sqlite3_stmt *)_statement, (int)index) == SQLITE_NULL);
}

- (BOOL)isNullForColumn:(NSString *)name
{
    NSInteger index = [self indexForColumn:name];

    if (index < 0) {
        return YES;
    }

    return [self isNullAtIndex:index];
}

@end
