//
//  LRMDatabase.h
//  LeoRM
//
//  Public database connection interface for LeoRM.
//

#import <Foundation/Foundation.h>

/*!
 * @header LRMDatabase
 * @abstract Public database connection API for LeoRM.
 * @discussion
 * This header is part of LeoRM's public API surface. It follows the
 * Cupertino-2009 API culture documented in docs/quality and is intended to be
 * processed by Apple's HeaderDoc tools on Mac OS X 10.5.8 Leopard.
 */

struct sqlite3;

@class LRMStatement;
@class LRMTransaction;

/*!
 * @class LRMDatabase
 * @abstract Explicit SQLite database connection wrapper.
 * @discussion
 * LRMDatabase owns one SQLite database connection. It stores the database path,
 * opens and closes the sqlite3 handle explicitly, prepares statements, begins
 * transactions, and provides small metadata helpers used by migrations.
 *
 * LRMDatabase does not define domain schemas, hide SQL, act as a global
 * singleton, or replace Core Data. The database file and SQL schema remain
 * owned by the application or domain store above LeoRM.
 *
 * Instances use manual retain/release. Factory methods return autoreleased
 * objects. Callers should close databases explicitly; dealloc performs
 * defensive cleanup.
 */
@interface LRMDatabase : NSObject
{
@private
    NSString *_path;
    struct sqlite3 *_database;
}

/*!
 * @method databaseWithPath:error:
 * @abstract Creates an autoreleased database object for a path.
 * @param path SQLite database path. Must not be nil or empty. The special
 * SQLite path ":memory:" is valid.
 * @param error Optional NSError output. Filled when the path is invalid.
 * @result Returns an autoreleased LRMDatabase, or nil on failure.
 * @discussion
 * This method does not open the SQLite connection. Call open: explicitly.
 */
+ (id)databaseWithPath:(NSString *)path error:(NSError **)error;

/*!
 * @method initWithPath:error:
 * @abstract Initializes a database object for a path.
 * @param path SQLite database path. Must not be nil or empty. The special
 * SQLite path ":memory:" is valid.
 * @param error Optional NSError output. Filled when the path is invalid.
 * @result Returns an initialized owned LRMDatabase, or nil on failure.
 * @discussion
 * This initializer copies the path but does not open the SQLite connection.
 * Call open: explicitly.
 */
- (id)initWithPath:(NSString *)path error:(NSError **)error;

/*!
 * @method path
 * @abstract Returns the SQLite database path.
 * @result Returns the path copied during initialization.
 * @discussion
 * The caller does not own the returned object.
 */
- (NSString *)path;

/*!
 * @method open:
 * @abstract Opens the SQLite database connection.
 * @param error Optional NSError output. Filled when sqlite3_open fails.
 * @result Returns YES on success, NO on failure.
 * @discussion
 * Calling open: on an already open database returns YES. SQLite failures are
 * reported through LRMSQLiteErrorMake. The database remains closed on failure.
 */
- (BOOL)open:(NSError **)error;

/*!
 * @method close
 * @abstract Closes the SQLite database connection if open.
 * @discussion
 * This method is idempotent for already closed databases. If SQLite refuses to
 * close because statements are still active, the internal handle is kept so
 * that later cleanup can still happen. Callers should close result sets and
 * finalize statements before closing the database.
 */
- (void)close;

/*!
 * @method isOpen
 * @abstract Reports whether the SQLite handle is currently open.
 * @result Returns YES when the database has an active sqlite3 handle.
 */
- (BOOL)isOpen;

/*!
 * @method prepareStatement:error:
 * @abstract Prepares SQL as an LRMStatement.
 * @param sql SQL string to prepare. Must not be nil or empty.
 * @param error Optional NSError output. Filled on invalid state or SQLite
 * prepare failure.
 * @result Returns an autoreleased LRMStatement, or nil on failure.
 * @discussion
 * The database must be open. SQL remains visible to the caller and is not
 * generated or hidden by LeoRM.
 */
- (LRMStatement *)prepareStatement:(NSString *)sql error:(NSError **)error;

/*!
 * @method beginTransaction:
 * @abstract Begins an explicit SQLite transaction.
 * @param error Optional NSError output. Filled when the database is closed or
 * the transaction cannot be started.
 * @result Returns an autoreleased active LRMTransaction, or nil on failure.
 * @discussion
 * Nested transactions are not part of LeoRM V1. Call commit: or rollback: on
 * the returned transaction to end it.
 */
- (LRMTransaction *)beginTransaction:(NSError **)error;

/*!
 * @method ensureMetadataTable:
 * @abstract Ensures that LeoRM's small metadata table exists.
 * @param error Optional NSError output.
 * @result Returns YES on success, NO on failure.
 * @discussion
 * The metadata table is named lrm_metadata and stores string key/value pairs.
 * It is LeoRM-owned housekeeping data, not a private store format.
 */
- (BOOL)ensureMetadataTable:(NSError **)error;

/*!
 * @method metadataValueForKey:error:
 * @abstract Reads a metadata value.
 * @param key Metadata key. Must not be nil or empty.
 * @param error Optional NSError output.
 * @result Returns an autoreleased NSString value, or nil when the key is not
 * present or when an error occurs.
 * @discussion
 * A missing key is not treated as an error. Because nil can mean either
 * "missing" or "failure", callers that need to distinguish those cases should
 * inspect the supplied NSError pointer.
 */
- (NSString *)metadataValueForKey:(NSString *)key error:(NSError **)error;

/*!
 * @method setMetadataValue:forKey:error:
 * @abstract Writes or deletes a metadata value.
 * @param value Metadata value. Passing nil deletes the key.
 * @param key Metadata key. Must not be nil or empty.
 * @param error Optional NSError output.
 * @result Returns YES on success, NO on failure.
 * @discussion
 * Values are stored as TEXT. Domain data should not be stored in LeoRM
 * metadata.
 */
- (BOOL)setMetadataValue:(NSString *)value forKey:(NSString *)key error:(NSError **)error;

/*!
 * @method getSchemaVersion:forSchemaName:error:
 * @abstract Reads the stored schema version for a named schema.
 * @param version Output pointer receiving the schema version. Must not be NULL.
 * @param schemaName Schema name. Must not be nil or empty.
 * @param error Optional NSError output.
 * @result Returns YES on success, NO on failure.
 * @discussion
 * Missing schema versions read as 0. This is used by LRMMigrationRunner to
 * start migration from an empty database.
 */
- (BOOL)getSchemaVersion:(NSInteger *)version
           forSchemaName:(NSString *)schemaName
                   error:(NSError **)error;

/*!
 * @method setSchemaVersion:forSchemaName:error:
 * @abstract Stores the schema version for a named schema.
 * @param version Schema version. Must not be negative.
 * @param schemaName Schema name. Must not be nil or empty.
 * @param error Optional NSError output.
 * @result Returns YES on success, NO on failure.
 * @discussion
 * Migration code should update the schema version only after the corresponding
 * migration step has succeeded.
 */
- (BOOL)setSchemaVersion:(NSInteger)version
           forSchemaName:(NSString *)schemaName
                   error:(NSError **)error;

@end
