//
//  Note.m
//  LeoRM NotesStore Example
//
//  Small example domain object.
//

#import "Note.h"

@implementation Note

- (id)initWithIdentifier:(NSInteger)identifier
                  title:(NSString *)title
                   body:(NSString *)body
              createdAt:(NSString *)createdAt
{
    self = [super init];
    if (self == nil) {
        return nil;
    }

    _identifier = identifier;
    _title = [title copy];
    _body = [body copy];
    _createdAt = [createdAt copy];

    return self;
}

- (void)dealloc
{
    [_title release];
    [_body release];
    [_createdAt release];

    [super dealloc];
}

- (NSInteger)identifier
{
    return _identifier;
}

- (NSString *)title
{
    return _title;
}

- (NSString *)body
{
    return _body;
}

- (NSString *)createdAt
{
    return _createdAt;
}

@end
