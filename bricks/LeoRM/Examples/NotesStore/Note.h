//
//  Note.h
//  LeoRM NotesStore Example
//
//  Small example domain object.
//

#import <Foundation/Foundation.h>

@interface Note : NSObject
{
@private
    NSInteger _identifier;
    NSString *_title;
    NSString *_body;
    NSString *_createdAt;
}

- (id)initWithIdentifier:(NSInteger)identifier
                  title:(NSString *)title
                   body:(NSString *)body
              createdAt:(NSString *)createdAt;

- (NSInteger)identifier;
- (NSString *)title;
- (NSString *)body;
- (NSString *)createdAt;

@end
