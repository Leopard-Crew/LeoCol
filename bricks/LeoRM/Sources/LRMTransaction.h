//
//  LRMTransaction.h
//  LeoRM
//
//  Public transaction interface for LeoRM.
//

#import <Foundation/Foundation.h>

/*!
 * @header LRMTransaction
 * @abstract Public transaction API for LeoRM.
 * @discussion
 * This header is part of LeoRM's public API surface. It follows the
 * Cupertino-2009 API culture documented in docs/quality and is intended to be
 * processed by Apple's HeaderDoc tools on Mac OS X 10.5.8 Leopard.
 */

@class LRMDatabase;

/*!
 * @class LRMTransaction
 * @abstract Explicit SQLite transaction wrapper.
 * @discussion
 * LRMTransaction represents one active SQLite transaction started through
 * LRMDatabase. It provides explicit commit and rollback boundaries and tracks
 * whether the transaction is still active.
 *
 * LeoRM V1 does not implement nested transactions or savepoints. A transaction
 * object should be committed or rolled back exactly once. dealloc performs a
 * defensive rollback if the transaction is still active, but callers should not
 * rely on dealloc for normal control flow.
 *
 * Instances use manual retain/release. Factory ownership follows normal Cocoa
 * rules through LRMDatabase beginTransaction:.
 */
@interface LRMTransaction : NSObject
{
@private
    LRMDatabase *_database;
    BOOL _active;
}

/*!
 * @method initWithDatabase:error:
 * @abstract Begins a transaction on an open database.
 * @param database Open LRMDatabase. Must not be nil and must be open.
 * @param error Optional NSError output. Filled when the database is invalid or
 * BEGIN TRANSACTION fails.
 * @result Returns an owned active LRMTransaction, or nil on failure.
 * @discussion
 * This initializer executes BEGIN TRANSACTION. The transaction is active only
 * after that SQL succeeds.
 */
- (id)initWithDatabase:(LRMDatabase *)database error:(NSError **)error;

/*!
 * @method commit:
 * @abstract Commits the active transaction.
 * @param error Optional NSError output. Filled when the transaction is inactive
 * or COMMIT fails.
 * @result Returns YES on success, NO on failure.
 * @discussion
 * After a successful commit the transaction becomes inactive. Calling commit:
 * or rollback: again is an API error and returns NO.
 */
- (BOOL)commit:(NSError **)error;

/*!
 * @method rollback:
 * @abstract Rolls back the active transaction.
 * @param error Optional NSError output. Filled when the transaction is inactive
 * or ROLLBACK fails.
 * @result Returns YES on success, NO on failure.
 * @discussion
 * After a successful rollback the transaction becomes inactive. Calling commit:
 * or rollback: again is an API error and returns NO.
 */
- (BOOL)rollback:(NSError **)error;

/*!
 * @method isActive
 * @abstract Reports whether the transaction is still active.
 * @result Returns YES between successful begin and successful commit or
 * rollback.
 */
- (BOOL)isActive;

@end
