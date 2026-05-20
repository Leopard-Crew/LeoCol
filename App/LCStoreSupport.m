#import "LCStoreSupport.h"
#import "LCString.h"
#import "../bricks/LeoRM/Sources/LeoRM.h"

@implementation LCStoreSupport

+ (NSString *)projectPath
{
    NSString *projectPath;

    projectPath = [[[NSBundle mainBundle] bundlePath]
        stringByDeletingLastPathComponent];

    /*
     * Debug builds live at:
     *   App/build/Debug/LeoCol.app
     *
     * The project root is therefore three levels up from the .app parent:
     *   App/build/Debug -> App/build -> App -> LeoCol
     */
    projectPath = [projectPath stringByDeletingLastPathComponent];
    projectPath = [projectPath stringByDeletingLastPathComponent];
    projectPath = [projectPath stringByDeletingLastPathComponent];

    return projectPath;
}

+ (NSString *)databasePath
{
    return [[self projectPath] stringByAppendingPathComponent:@"Probe/results/leocol-v1.db"];
}

+ (LRMDatabase *)openDatabaseWithStatusString:(NSString **)statusString
{
    NSString *dbPath;
    NSError *error;
    LRMDatabase *database;

    if (statusString != NULL) {
        *statusString = nil;
    }

    dbPath = [self databasePath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        if (statusString != NULL) {
            *statusString = [NSString stringWithFormat:LCString(@"Status.DatabaseNotFound"), dbPath];
        }

        return nil;
    }

    error = nil;
    database = [LRMDatabase databaseWithPath:dbPath error:&error];

    if (database == nil || ![database open:&error]) {
        if (statusString != NULL) {
            *statusString = [NSString stringWithFormat:LCString(@"Status.DatabaseOpenFailed"), dbPath];
        }

        return nil;
    }

    return database;
}

@end
