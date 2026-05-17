//
//  LRMRow.h
//  LeoRM
//
//  Public row-access interface for LeoRM.
//

#import <Foundation/Foundation.h>

/*!
 * @header LRMRow
 * @abstract Public result-row access API for LeoRM.
 * @discussion
 * This header is part of LeoRM's public API surface. It follows the
 * Cupertino-2009 API culture documented in docs/quality and is intended to be
 * processed by Apple's HeaderDoc tools on Mac OS X 10.5.8 Leopard.
 */

/*!
 * @class LRMRow
 * @abstract Foundation-shaped access to the current SQLite result row.
 * @discussion
 * LRMRow reads values from the current sqlite3_stmt row state. It does not own
 * the SQLite statement and does not remain valid independently of the
 * LRMResultSet that created it.
 *
 * Rows are lightweight views over the current result row. The caller should
 * read needed values before advancing or closing the result set.
 *
 * LRMRow does not map values into domain objects. Domain mapping belongs in a
 * repository or domain store above LeoRM.
 */
@interface LRMRow : NSObject
{
@private
    void *_statement;
}

/*!
 * @method initWithStatement:
 * @abstract Initializes a row view for the current SQLite statement state.
 * @param statement Internal sqlite3_stmt pointer as an opaque value. Must point
 * to a statement currently positioned on SQLITE_ROW.
 * @result Returns an owned LRMRow.
 * @discussion
 * This initializer is intended for LeoRM internals. The row does not own or
 * finalize the statement.
 */
- (id)initWithStatement:(void *)statement;

/*!
 * @method columnCount
 * @abstract Returns the number of columns in the current row.
 * @result Returns the SQLite column count, or 0 if the row has no statement.
 */
- (NSInteger)columnCount;

/*!
 * @method columnNameAtIndex:
 * @abstract Returns a column name by zero-based index.
 * @param index Zero-based column index.
 * @result Returns an autoreleased NSString, or nil if the index is invalid.
 */
- (NSString *)columnNameAtIndex:(NSInteger)index;

/*!
 * @method objectAtIndex:
 * @abstract Returns a Foundation object for a column by zero-based index.
 * @param index Zero-based column index.
 * @result Returns NSString, NSNumber, NSData, or nil for SQL NULL / invalid
 * index.
 * @discussion
 * SQLITE_TEXT becomes NSString, SQLITE_INTEGER and SQLITE_FLOAT become
 * NSNumber, SQLITE_BLOB becomes NSData, and SQLITE_NULL becomes nil.
 */
- (id)objectAtIndex:(NSInteger)index;

/*!
 * @method objectForColumn:
 * @abstract Returns a Foundation object for a column by name.
 * @param name Column name. Must not be nil.
 * @result Returns NSString, NSNumber, NSData, or nil for SQL NULL, missing
 * column, or invalid state.
 */
- (id)objectForColumn:(NSString *)name;

/*!
 * @method stringAtIndex:
 * @abstract Returns a string value by zero-based index.
 * @param index Zero-based column index.
 * @result Returns NSString, converted stringValue for NSNumber-like values, or
 * nil when unavailable.
 */
- (NSString *)stringAtIndex:(NSInteger)index;

/*!
 * @method stringForColumn:
 * @abstract Returns a string value by column name.
 * @param name Column name. Must not be nil.
 * @result Returns NSString, converted stringValue for NSNumber-like values, or
 * nil when unavailable.
 */
- (NSString *)stringForColumn:(NSString *)name;

/*!
 * @method numberAtIndex:
 * @abstract Returns an NSNumber value by zero-based index.
 * @param index Zero-based column index.
 * @result Returns NSNumber, or nil when the value is not numeric or unavailable.
 */
- (NSNumber *)numberAtIndex:(NSInteger)index;

/*!
 * @method numberForColumn:
 * @abstract Returns an NSNumber value by column name.
 * @param name Column name. Must not be nil.
 * @result Returns NSNumber, or nil when the value is not numeric or unavailable.
 */
- (NSNumber *)numberForColumn:(NSString *)name;

/*!
 * @method dataAtIndex:
 * @abstract Returns NSData for a BLOB column by zero-based index.
 * @param index Zero-based column index.
 * @result Returns NSData, or nil when the value is not a BLOB or unavailable.
 */
- (NSData *)dataAtIndex:(NSInteger)index;

/*!
 * @method dataForColumn:
 * @abstract Returns NSData for a BLOB column by name.
 * @param name Column name. Must not be nil.
 * @result Returns NSData, or nil when the value is not a BLOB or unavailable.
 */
- (NSData *)dataForColumn:(NSString *)name;

/*!
 * @method isNullAtIndex:
 * @abstract Reports whether a column is SQL NULL.
 * @param index Zero-based column index.
 * @result Returns YES for SQL NULL, invalid index, or invalid state.
 */
- (BOOL)isNullAtIndex:(NSInteger)index;

/*!
 * @method isNullForColumn:
 * @abstract Reports whether a named column is SQL NULL.
 * @param name Column name. Must not be nil.
 * @result Returns YES for SQL NULL, missing column, or invalid state.
 */
- (BOOL)isNullForColumn:(NSString *)name;

@end
