//
//  LRMSchema.m
//  LeoRM
//
//  Schema description for LeoRM V1 migrations.
//

#import "LRMSchema.h"
#import "LRMMigration.h"
#import "LRMError.h"

@implementation LRMSchema

+ (id)schemaWithName:(NSString *)name
       targetVersion:(NSInteger)targetVersion
          migrations:(NSArray *)migrations
               error:(NSError **)error
{
    return [[[self alloc] initWithName:name
                         targetVersion:targetVersion
                            migrations:migrations
                                 error:error] autorelease];
}

- (id)initWithName:(NSString *)name
     targetVersion:(NSInteger)targetVersion
        migrations:(NSArray *)migrations
             error:(NSError **)error
{
    NSUInteger index = 0;

    self = [super init];
    if (self == nil) {
        return nil;
    }

    if (name == nil || [name length] == 0) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Schema name must not be empty.");
        }

        [self release];
        return nil;
    }

    if (targetVersion < 0) {
        if (error != NULL) {
            *error = LRMErrorMake(LRMErrorInvalidArgument, @"Schema target version must not be negative.");
        }

        [self release];
        return nil;
    }

    for (index = 0; index < [migrations count]; index++) {
        id item = [migrations objectAtIndex:index];

        if (![item isKindOfClass:[LRMMigration class]]) {
            if (error != NULL) {
                *error = LRMErrorMake(LRMErrorInvalidArgument, @"Schema migrations must contain only LRMMigration objects.");
            }

            [self release];
            return nil;
        }
    }

    _name = [name copy];
    _targetVersion = targetVersion;
    _migrations = [migrations copy];

    return self;
}

- (void)dealloc
{
    [_name release];
    [_migrations release];

    [super dealloc];
}

- (NSString *)name
{
    return _name;
}

- (NSInteger)targetVersion
{
    return _targetVersion;
}

- (NSArray *)migrations
{
    return _migrations;
}

@end
