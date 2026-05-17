//
//  LRMRepository.h
//  LeoRM
//
//  Public repository helper interface for LeoRM.
//

#import <Foundation/Foundation.h>

/*!
 * @header LRMRepository
 * @abstract Public repository helper API for LeoRM.
 * @discussion
 * This header is part of LeoRM's public API surface. It follows the
 * Cupertino-2009 API culture documented in docs/quality and is intended to be
 * processed by Apple's HeaderDoc tools on Mac OS X 10.5.8 Leopard.
 */

@class LRMDatabase;
@class LRMResultSet;
@class LRMStatement;

/*!
 * @class LRMRepository
 * @abstract Minimal DAO-style helper for SQL-backed repositories.
 * @discussion
 * LRMRepository is a small convenience base class for domain repositories. It
 * holds an open LRMDatabase, prepares SQL, binds NSArray arguments, executes
 * updates, and creates result sets.
 *
 * LRMRepository is not ActiveRecord. It does not require domain objects to
 * inherit from LeoRM classes, does not generate schemas, does not hide SQL, and
 * does not map rows automatically into objects. Domain repositories should
 * subclass or wrap it and perform explicit row-to-object mapping above LeoRM.
 *
 * Instances use manual retain/release. The database is retained by the
 * repository but remains owned by the caller.
 */
@interface LRMRepository : NSObject
{
@private
    LRMDatabase *_database;
}

/*!
 * @method initWithDatabase:error:
 * @abstract Initializes a repository with an open database.
 * @param database Open LRMDatabase. Must not be nil and must be open.
 * @param error Optional NSError output. Filled when the database is invalid.
 * @result Returns an owned LRMRepository, or nil on failure.
 * @discussion
 * The repository retains the database. It does not open or close the database.
 */
- (id)initWithDatabase:(LRMDatabase *)database error:(NSError **)error;

/*!
 * @method database
 * @abstract Returns the repository database.
 * @result Returns the retained database. The caller does not own the returned
 * object.
 */
- (LRMDatabase *)database;

/*!
 * @method executeSQL:arguments:error:
 * @abstract Executes non-row-returning SQL with positional arguments.
 * @param sql SQL string to execute. Must not be nil or empty.
 * @param arguments Optional NSArray of values to bind. Values are bound in
 * order starting at SQLite parameter index 1. Passing nil is valid and means no
 * arguments.
 * @param error Optional NSError output.
 * @result Returns YES on success, NO on prepare, bind, or execution failure.
 * @discussion
 * This method keeps SQL visible. It is intended for repository methods such as
 * insert, update, delete, and schema creation helpers.
 */
- (BOOL)executeSQL:(NSString *)sql
         arguments:(NSArray *)arguments
             error:(NSError **)error;

/*!
 * @method resultSetForSQL:arguments:error:
 * @abstract Prepares row-returning SQL and returns a result set.
 * @param sql SQL query string. Must not be nil or empty.
 * @param arguments Optional NSArray of values to bind. Passing nil is valid.
 * @param error Optional NSError output.
 * @result Returns an autoreleased LRMResultSet, or nil on prepare, bind, or
 * query setup failure.
 * @discussion
 * The caller should close the returned result set when finished. Closing the
 * result set finalizes the underlying statement.
 */
- (LRMResultSet *)resultSetForSQL:(NSString *)sql
                        arguments:(NSArray *)arguments
                            error:(NSError **)error;

/*!
 * @method bindArguments:toStatement:error:
 * @abstract Binds an NSArray of positional arguments to a statement.
 * @param arguments Optional NSArray of values. Passing nil is valid and binds
 * no values.
 * @param statement Statement to bind. Must not be nil.
 * @param error Optional NSError output.
 * @result Returns YES when all arguments bind successfully, NO on invalid state
 * or binding failure.
 * @discussion
 * This helper binds values using LRMStatement bindObject:atIndex:error:. The
 * first array object is bound at SQLite index 1.
 */
- (BOOL)bindArguments:(NSArray *)arguments
          toStatement:(LRMStatement *)statement
                error:(NSError **)error;

@end
