//
//  metadata_main.m
//  LeoRM
//
//  Metadata and schema version smoke test.
//

#import <Foundation/Foundation.h>
#import "../Sources/LeoRM.h"

static int failWithError(NSString *message, NSError *error)
{
    if (error != nil) {
        fprintf(stderr, "%s: %s\n",
                [message UTF8String],
                [[[error localizedDescription] description] UTF8String]);
    } else {
        fprintf(stderr, "%s\n", [message UTF8String]);
    }

    return 1;
}

int main(int argc, const char *argv[])
{
    (void)argc;
    (void)argv;

    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

    NSError *error = nil;
    NSInteger version = -1;

    LRMDatabase *database = [LRMDatabase databaseWithPath:@":memory:"
                                                    error:&error];

    if (database == nil || ![database open:&error]) {
        int result = failWithError(@"Could not open database", error);
        [pool drain];
        return result;
    }

    if (![database ensureMetadataTable:&error]) {
        int result = failWithError(@"Could not ensure metadata table", error);
        [pool drain];
        return result;
    }

    if (![database setMetadataValue:@"LeoRM"
                             forKey:@"store.name"
                              error:&error]) {
        int result = failWithError(@"Could not set metadata value", error);
        [pool drain];
        return result;
    }

    NSString *storeName = [database metadataValueForKey:@"store.name"
                                                  error:&error];

    if (![storeName isEqualToString:@"LeoRM"]) {
        fprintf(stderr, "Unexpected metadata value.\n");
        [pool drain];
        return 1;
    }

    if (![database setMetadataValue:nil
                             forKey:@"store.name"
                              error:&error]) {
        int result = failWithError(@"Could not delete metadata value", error);
        [pool drain];
        return result;
    }

    storeName = [database metadataValueForKey:@"store.name"
                                        error:&error];

    if (storeName != nil) {
        fprintf(stderr, "Expected deleted metadata value to be nil.\n");
        [pool drain];
        return 1;
    }

    if (![database getSchemaVersion:&version
                      forSchemaName:@"test"
                              error:&error]) {
        int result = failWithError(@"Could not read default schema version", error);
        [pool drain];
        return result;
    }

    if (version != 0) {
        fprintf(stderr, "Expected default schema version 0, got %ld.\n", (long)version);
        [pool drain];
        return 1;
    }

    if (![database setSchemaVersion:3
                      forSchemaName:@"test"
                              error:&error]) {
        int result = failWithError(@"Could not set schema version", error);
        [pool drain];
        return result;
    }

    version = -1;

    if (![database getSchemaVersion:&version
                      forSchemaName:@"test"
                              error:&error]) {
        int result = failWithError(@"Could not read schema version", error);
        [pool drain];
        return result;
    }

    if (version != 3) {
        fprintf(stderr, "Expected schema version 3, got %ld.\n", (long)version);
        [pool drain];
        return 1;
    }

    printf("LeoRM metadata smoke test OK\n");

    [database close];

    [pool drain];
    return 0;
}
