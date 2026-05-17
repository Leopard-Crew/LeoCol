//
//  LRMDatabase.m
//  LeoRM
//
//  Database connection for LeoRM V1.
//

#import "LRMDatabase.h"
#import "LRMError.h"
#import "LRMStatement.h"
#import "Private/LRMStatementPrivate.h"
#import "LRMTransaction.h"
#import "LRMResultSet.h"
#import "LRMRow.h"

#import <sqlite3.h>

static NSString *LRMSchemaVersionMetadataKey(NSString *schemaName)
{
    return [NSString stringWithFormat:@"schema.%@.version", schemaName];
}

@implementation LRMDatabase

+ (id)databaseWithPath:(NSString *)path error:(NSError **)error
{
    return [[[self alloc] initWithPath:path error:error] autorelease];
}

- (id)initWithPath:(NSString *)path error:(NSError **)error
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    if (path == nil || [path length] == 0) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Database path must not be empty.");
        }

        [self release];
        return nil;
    }

    _path = [path copy];
    _database = NULL;

    return self;
}

- (void)dealloc
{
    [self close];

    [_path release];

    [super dealloc];
}

- (NSString *)path
{
    return _path;
}

- (BOOL)open:(NSError **)error
{
    int result = SQLITE_OK;

    if (_database != NULL) {
        return YES;
    }

    result = sqlite3_open([_path fileSystemRepresentation], &_database);

    if (result != SQLITE_OK) {
        if (error != NULL) {
            *error = LRMSQLiteErrorMake(_database, result, nil, _path);
        }

        if (_database != NULL) {
            sqlite3_close(_database);
            _database = NULL;
        }

        return NO;
    }

    return YES;
}

- (void)close
{
    if (_database != NULL) {
        if (sqlite3_close(_database) == SQLITE_OK) {
            _database = NULL;
        }
    }
}

- (BOOL)isOpen
{
    return (_database != NULL);
}

- (LRMStatement *)prepareStatement:(NSString *)sql error:(NSError **)error
{
    if (_database == NULL) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Database must be open before preparing a statement.");
        }

        return nil;
    }

    return [[[LRMStatement alloc] initWithDatabase:_database
                                              sql:sql
                                     databasePath:_path
                                            error:error] autorelease];
}

- (LRMTransaction *)beginTransaction:(NSError **)error
{
    if (_database == NULL) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Database must be open before beginning a transaction.");
        }

        return nil;
    }

    return [[[LRMTransaction alloc] initWithDatabase:self
                                              error:error] autorelease];
}

- (BOOL)ensureMetadataTable:(NSError **)error
{
    BOOL ok = NO;
    LRMStatement *statement = nil;

    statement = [self prepareStatement:@"CREATE TABLE IF NOT EXISTS lrm_metadata (key TEXT PRIMARY KEY NOT NULL, value TEXT)"
                                 error:error];

    if (statement == nil) {
        return NO;
    }

    ok = [statement executeUpdate:error];

    [statement finalizeStatement];

    return ok;
}

- (NSString *)metadataValueForKey:(NSString *)key error:(NSError **)error
{
    LRMStatement *statement = nil;
    LRMResultSet *resultSet = nil;
    LRMRow *row = nil;
    NSString *value = nil;

    if (key == nil || [key length] == 0) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Metadata key must not be empty.");
        }

        return nil;
    }

    if (![self ensureMetadataTable:error]) {
        return nil;
    }

    statement = [self prepareStatement:@"SELECT value FROM lrm_metadata WHERE key = ?"
                                 error:error];

    if (statement == nil) {
        return nil;
    }

    if (![statement bindObject:key atIndex:1 error:error]) {
        [statement finalizeStatement];
        return nil;
    }

    resultSet = [statement executeQuery:error];

    if (resultSet == nil) {
        [statement finalizeStatement];
        return nil;
    }

    if ([resultSet next:error]) {
        row = [resultSet currentRow];
        value = [[row stringForColumn:@"value"] retain];
    }

    [resultSet close];

    return [value autorelease];
}

- (BOOL)setMetadataValue:(NSString *)value forKey:(NSString *)key error:(NSError **)error
{
    BOOL ok = NO;
    LRMStatement *statement = nil;

    if (key == nil || [key length] == 0) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Metadata key must not be empty.");
        }

        return NO;
    }

    if (![self ensureMetadataTable:error]) {
        return NO;
    }

    if (value == nil) {
        statement = [self prepareStatement:@"DELETE FROM lrm_metadata WHERE key = ?"
                                     error:error];

        if (statement == nil) {
            return NO;
        }

        ok = [statement bindObject:key atIndex:1 error:error];

        if (ok) {
            ok = [statement executeUpdate:error];
        }

        [statement finalizeStatement];

        return ok;
    }

    statement = [self prepareStatement:@"INSERT OR REPLACE INTO lrm_metadata (key, value) VALUES (?, ?)"
                                 error:error];

    if (statement == nil) {
        return NO;
    }

    ok = [statement bindObject:key atIndex:1 error:error];

    if (ok) {
        ok = [statement bindObject:value atIndex:2 error:error];
    }

    if (ok) {
        ok = [statement executeUpdate:error];
    }

    [statement finalizeStatement];

    return ok;
}

- (BOOL)getSchemaVersion:(NSInteger *)version
           forSchemaName:(NSString *)schemaName
                   error:(NSError **)error
{
    NSString *value = nil;
    NSString *key = nil;

    if (version == NULL) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Schema version output pointer must not be NULL.");
        }

        return NO;
    }

    if (schemaName == nil || [schemaName length] == 0) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Schema name must not be empty.");
        }

        return NO;
    }

    *version = 0;

    key = LRMSchemaVersionMetadataKey(schemaName);
    value = [self metadataValueForKey:key error:error];

    if (value == nil) {
        return YES;
    }

    *version = (NSInteger)[value integerValue];

    return YES;
}

- (BOOL)setSchemaVersion:(NSInteger)version
           forSchemaName:(NSString *)schemaName
                   error:(NSError **)error
{
    NSString *key = nil;
    NSString *value = nil;

    if (schemaName == nil || [schemaName length] == 0) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Schema name must not be empty.");
        }

        return NO;
    }

    if (version < 0) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Schema version must not be negative.");
        }

        return NO;
    }

    key = LRMSchemaVersionMetadataKey(schemaName);
    value = [NSString stringWithFormat:@"%ld", (long)version];

    return [self setMetadataValue:value forKey:key error:error];
}

@end
