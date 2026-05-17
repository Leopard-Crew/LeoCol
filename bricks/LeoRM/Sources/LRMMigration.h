//
//  LRMMigration.h
//  LeoRM
//
//  Public migration-step interface for LeoRM.
//

#import <Foundation/Foundation.h>

/*!
 * @header LRMMigration
 * @abstract Public migration-step API for LeoRM.
 * @discussion
 * This header is part of LeoRM's public API surface. It follows the
 * Cupertino-2009 API culture documented in docs/quality and is intended to be
 * processed by Apple's HeaderDoc tools on Mac OS X 10.5.8 Leopard.
 */

@class LRMDatabase;

/*!
 * @class LRMMigration
 * @abstract One explicit schema migration step.
 * @discussion
 * LRMMigration represents a versioned schema step from one integer version to
 * a greater integer version. It owns an ordered array of SQL statements that
 * are executed by applyToDatabase:error:.
 *
 * Migration SQL is supplied by the schema owner, usually a domain store or
 * application. LeoRM runs migrations; it does not invent them or infer schema
 * differences.
 *
 * Instances are immutable after initialization and use manual retain/release.
 */
@interface LRMMigration : NSObject
{
@private
    NSInteger _fromVersion;
    NSInteger _toVersion;
    NSArray *_SQLStatements;
}

/*!
 * @method migrationFromVersion:toVersion:SQLStatements:
 * @abstract Creates an autoreleased migration step.
 * @param fromVersion Source schema version.
 * @param toVersion Target schema version. Must be greater than fromVersion
 * when the migration is applied.
 * @param SQLStatements Ordered array of non-empty NSString SQL statements.
 * @result Returns an autoreleased LRMMigration.
 */
+ (id)migrationFromVersion:(NSInteger)fromVersion
                 toVersion:(NSInteger)toVersion
             SQLStatements:(NSArray *)SQLStatements;

/*!
 * @method initFromVersion:toVersion:SQLStatements:
 * @abstract Initializes a migration step.
 * @param fromVersion Source schema version.
 * @param toVersion Target schema version.
 * @param SQLStatements Ordered array of SQL statements. The array is copied.
 * @result Returns an owned LRMMigration.
 * @discussion
 * Validation of SQL statement contents happens when the migration is applied.
 */
- (id)initFromVersion:(NSInteger)fromVersion
            toVersion:(NSInteger)toVersion
        SQLStatements:(NSArray *)SQLStatements;

/*!
 * @method fromVersion
 * @abstract Returns the source schema version.
 * @result Source version for this migration step.
 */
- (NSInteger)fromVersion;

/*!
 * @method toVersion
 * @abstract Returns the target schema version.
 * @result Target version for this migration step.
 */
- (NSInteger)toVersion;

/*!
 * @method SQLStatements
 * @abstract Returns the ordered SQL statements for this migration.
 * @result Returns the copied SQL statement array. The caller does not own the
 * returned object.
 */
- (NSArray *)SQLStatements;

/*!
 * @method applyToDatabase:error:
 * @abstract Applies this migration's SQL statements to an open database.
 * @param database Open LRMDatabase. Must not be nil and must be open.
 * @param error Optional NSError output. Filled on invalid migration data,
 * invalid database state, prepare failure, or execution failure.
 * @result Returns YES when all SQL statements execute successfully, NO on the
 * first failure.
 * @discussion
 * This method does not start or commit a transaction. LRMMigrationRunner owns
 * transaction boundaries for normal migration execution.
 */
- (BOOL)applyToDatabase:(LRMDatabase *)database error:(NSError **)error;

@end
