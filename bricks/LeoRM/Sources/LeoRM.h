//
//  LeoRM.h
//  LeoRM
//
//  Public umbrella header for LeoRM.
//

#import <Foundation/Foundation.h>

/*!
 * @header LeoRM
 * @abstract Umbrella header for the LeoRM storage brick.
 * @discussion
 * LeoRM is a small Mac OS X 10.5.8 Leopard / PowerPC verified
 * Repository/DAO layer for explicit SQLite-backed Cocoa objects.
 *
 * LeoRM keeps SQL visible, schemas open, and domain models outside the core.
 * It provides NSError mapping, database connection lifecycle, prepared
 * statements, result sets, row access, explicit transactions, metadata helpers,
 * ordered migrations, and a minimal repository helper.
 *
 * LeoRM depends on Foundation.framework and libsqlite3. It does not require
 * AppKit, Core Data, Swift, ARC, blocks, CocoaPods, Carthage, or Swift Package
 * Manager.
 *
 * Public API follows manual retain/release Cocoa conventions.
 */

#import "LRMError.h"
#import "LRMDatabase.h"
#import "LRMStatement.h"
#import "LRMResultSet.h"
#import "LRMRow.h"
#import "LRMTransaction.h"
#import "LRMMigration.h"
#import "LRMSchema.h"
#import "LRMMigrationRunner.h"
#import "LRMRepository.h"
