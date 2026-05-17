//
//  smoke_main.m
//  LeoRM
//
//  Minimal compile/runtime smoke test.
//

#import <Foundation/Foundation.h>
#import "../Sources/LeoRM.h"

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSError *error = nil;
    LRMDatabase *database = [LRMDatabase databaseWithPath:@"test.sqlite"
                                                    error:&error];

    if (database == nil) {
        fprintf(stderr, "LeoRM smoke test failed: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    if ([database isOpen]) {
        fprintf(stderr, "LeoRM smoke test failed: database should not be open before open:.\n");
        [pool drain];
        return 1;
    }

    if (![database open:&error]) {
        fprintf(stderr, "LeoRM smoke test failed while opening database: %s\n",
                [[[error localizedDescription] description] UTF8String]);
        [pool drain];
        return 1;
    }

    if (![database isOpen]) {
        fprintf(stderr, "LeoRM smoke test failed: database should be open after open:.\n");
        [pool drain];
        return 1;
    }

    [database close];

    if ([database isOpen]) {
        fprintf(stderr, "LeoRM smoke test failed: database should be closed after close.\n");
        [pool drain];
        return 1;
    }

    printf("LeoRM smoke test OK: %s\n", [[database path] UTF8String]);

    [pool drain];
    return 0;
}
