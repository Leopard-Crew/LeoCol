//
//  LRMSchema.h
//  LeoRM
//
//  Public schema description interface for LeoRM.
//

#import <Foundation/Foundation.h>

/*!
 * @header LRMSchema
 * @abstract Public schema description API for LeoRM.
 * @discussion
 * This header is part of LeoRM's public API surface. It follows the
 * Cupertino-2009 API culture documented in docs/quality and is intended to be
 * processed by Apple's HeaderDoc tools on Mac OS X 10.5.8 Leopard.
 */

/*!
 * @class LRMSchema
 * @abstract Named schema description for migration execution.
 * @discussion
 * LRMSchema groups a schema name, a target version, and an ordered set of
 * LRMMigration objects. It does not create tables by itself. It is input for
 * LRMMigrationRunner.
 *
 * A schema name identifies the version stored in LeoRM metadata. Domain stores
 * should choose stable schema names.
 *
 * Instances are immutable after initialization and use manual retain/release.
 */
@interface LRMSchema : NSObject
{
@private
    NSString *_name;
    NSInteger _targetVersion;
    NSArray *_migrations;
}

/*!
 * @method schemaWithName:targetVersion:migrations:error:
 * @abstract Creates an autoreleased schema description.
 * @param name Schema name. Must not be nil or empty.
 * @param targetVersion Target schema version. Must not be negative.
 * @param migrations Array containing only LRMMigration objects.
 * @param error Optional NSError output. Filled on invalid input.
 * @result Returns an autoreleased LRMSchema, or nil on failure.
 */
+ (id)schemaWithName:(NSString *)name
       targetVersion:(NSInteger)targetVersion
          migrations:(NSArray *)migrations
               error:(NSError **)error;

/*!
 * @method initWithName:targetVersion:migrations:error:
 * @abstract Initializes a schema description.
 * @param name Schema name. Must not be nil or empty.
 * @param targetVersion Target schema version. Must not be negative.
 * @param migrations Array containing only LRMMigration objects. The array is
 * copied.
 * @param error Optional NSError output. Filled on invalid input.
 * @result Returns an owned LRMSchema, or nil on failure.
 */
- (id)initWithName:(NSString *)name
     targetVersion:(NSInteger)targetVersion
        migrations:(NSArray *)migrations
             error:(NSError **)error;

/*!
 * @method name
 * @abstract Returns the schema name.
 * @result Returns the copied schema name. The caller does not own the returned
 * object.
 */
- (NSString *)name;

/*!
 * @method targetVersion
 * @abstract Returns the target schema version.
 * @result Target version for the schema.
 */
- (NSInteger)targetVersion;

/*!
 * @method migrations
 * @abstract Returns the migration list.
 * @result Returns the copied migration array. The caller does not own the
 * returned object.
 */
- (NSArray *)migrations;

@end
