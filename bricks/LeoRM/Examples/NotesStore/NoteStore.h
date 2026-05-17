//
//  NoteStore.h
//  LeoRM NotesStore Example
//
//  Tiny domain store built on top of LeoRM.
//

#import <Foundation/Foundation.h>
#import "../../Sources/LeoRM.h"

@class Note;

@interface NoteStore : LRMRepository

- (BOOL)migrate:(NSError **)error;
- (BOOL)addNoteWithTitle:(NSString *)title
                    body:(NSString *)body
               createdAt:(NSString *)createdAt
                   error:(NSError **)error;

- (NSArray *)allNotes:(NSError **)error;

@end
