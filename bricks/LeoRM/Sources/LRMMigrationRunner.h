//
//  LRMMigrationRunner.h
//  LeoRM
//
//  Public migration-runner interface for LeoRM.
//

#import <Foundation/Foundation.h>

/*!
 * @header LRMMigrationRunner
 * @abstract Public migration-runner API for LeoRM.
 * @discussion
 * This header is part of LeoRM's public API surface. It follows the
 * Cupertino-2009 API culture documented in docs/quality and is intended to be
 * processed by Apple's HeaderDoc tools on Mac OS X 10.5.8 Leopard.
 */

@class LRMDatabase;
@class LRMSchema;

/*!
 * @class LRMMigrationRunner
 * @abstract Applies ordered schema migrations to an open database.
 * @discussion
 * LRMMigrationRunner reads the current schema version from LRMDatabase
 * metadata, applies missing migrations in order, and updates the stored schema
 * version only after each migration step succeeds.
 *
 * Each migration step is executed inside its own LRMTransaction. If a migration
 * fails, the runner rolls back that step and stops. The runner does not invent
 * migrations, infer schema diffs, skip missing steps, or reorder migrations.
 */
@interface LRMMigrationRunner : NSObject

/*!
 * @method migrateDatabase:schema:error:
 * @abstract Migrates an open database to a schema's target version.
 * @param database Open LRMDatabase. Must not be nil and must be open.
 * @param schema Schema description. Must not be nil.
 * @param error Optional NSError output. Filled on invalid input, missing
 * migration step, invalid version state, transaction failure, migration
 * failure, or metadata update failure.
 * @result Returns YES when the database is at the target version, NO on
 * failure.
 * @discussion
 * If the current version already equals the target version, this method returns
 * YES without applying migrations. If the current version is newer than the
 * target version, the method returns NO.
 */
- (BOOL)migrateDatabase:(LRMDatabase *)database
                 schema:(LRMSchema *)schema
                  error:(NSError **)error;

@end
