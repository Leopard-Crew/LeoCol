//
//  LRMStatementPrivate.h
//  LeoRM
//
//  Private statement accessors for LeoRM internals.
//

#import "../LRMStatement.h"

struct sqlite3;
struct sqlite3_stmt;

/*
 * Private LeoRM internals.
 *
 * This header is intentionally not part of the public umbrella header and is
 * not part of the public HeaderDoc API.
 */

@interface LRMStatement (LeoRMPrivate)

- (id)initWithDatabase:(struct sqlite3 *)database
                   sql:(NSString *)sql
          databasePath:(NSString *)databasePath
                 error:(NSError **)error;

- (NSString *)databasePath;
- (struct sqlite3 *)sqliteDatabase;
- (struct sqlite3_stmt *)sqliteStatement;

@end
