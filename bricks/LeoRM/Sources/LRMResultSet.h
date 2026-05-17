//
//  LRMResultSet.h
//  LeoRM
//
//  Public result-set interface for LeoRM.
//

#import <Foundation/Foundation.h>

/*!
 * @header LRMResultSet
 * @abstract Public result-set API for LeoRM.
 * @discussion
 * This header is part of LeoRM's public API surface. It follows the
 * Cupertino-2009 API culture documented in docs/quality and is intended to be
 * processed by Apple's HeaderDoc tools on Mac OS X 10.5.8 Leopard.
 */

@class LRMRow;
@class LRMStatement;

/*!
 * @class LRMResultSet
 * @abstract Forward-only result set for one prepared statement.
 * @discussion
 * LRMResultSet owns query iteration for an LRMStatement. It retains the
 * statement while open, steps through rows, exposes the current row, and
 * finalizes the statement when closed.
 *
 * Result sets are forward-only. They do not cache all rows. Callers should
 * consume rows before advancing to the next row or closing the result set.
 *
 * Instances use manual retain/release. Call close explicitly when finished.
 * dealloc performs defensive cleanup.
 */
@interface LRMResultSet : NSObject
{
@private
    LRMStatement *_statement;
    LRMRow *_currentRow;
    BOOL _closed;
}

/*!
 * @method initWithStatement:
 * @abstract Initializes a result set with a prepared statement.
 * @param statement Prepared statement to iterate. Must not be nil.
 * @result Returns an owned LRMResultSet.
 * @discussion
 * The result set retains the statement. Closing the result set finalizes the
 * underlying SQLite statement through LRMStatement.
 */
- (id)initWithStatement:(LRMStatement *)statement;

/*!
 * @method next:
 * @abstract Advances to the next row.
 * @param error Optional NSError output. Filled when sqlite3_step fails.
 * @result Returns YES when a row is available, NO when there are no more rows
 * or when an error occurs.
 * @discussion
 * On SQLITE_ROW, currentRow returns the row for the current statement state.
 * On SQLITE_DONE, the result set closes itself and returns NO. On SQLite
 * failure, the result set closes itself, fills error, and returns NO.
 */
- (BOOL)next:(NSError **)error;

/*!
 * @method currentRow
 * @abstract Returns the current row.
 * @result Returns the current LRMRow, or nil before next: succeeds, after the
 * result set is closed, or after iteration finishes.
 * @discussion
 * The caller does not own the returned row. The row is valid only until the
 * result set advances, closes, or is deallocated.
 */
- (LRMRow *)currentRow;

/*!
 * @method close
 * @abstract Closes the result set and finalizes the underlying statement.
 * @discussion
 * This method is idempotent. After close, currentRow returns nil and next:
 * returns NO.
 */
- (void)close;

/*!
 * @method isClosed
 * @abstract Reports whether the result set has been closed.
 * @result Returns YES after close or after iteration reaches SQLITE_DONE.
 */
- (BOOL)isClosed;

@end
