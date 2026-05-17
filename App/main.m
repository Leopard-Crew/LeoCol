#import <Cocoa/Cocoa.h>
#import "../bricks/LeoRM/Sources/LeoRM.h"

@interface LeoColAppDelegate : NSObject
{
    NSWindow *_window;
    NSTableView *_tableView;
    NSMutableArray *_rows;
}
@end

@implementation LeoColAppDelegate

- (NSString *)databasePath
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

    return [projectPath stringByAppendingPathComponent:@"Probe/results/leocol-v1.db"];
}

- (void)addFallbackRows
{
    [_rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Finder", @"name",
        @"-", @"pid",
        @"Apple system component", @"kind",
        @"path-app-contained", @"confidence",
        @"com.apple.finder", @"bundle",
        nil]];

    [_rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Dock", @"name",
        @"-", @"pid",
        @"Apple system component", @"kind",
        @"path-app-contained", @"confidence",
        @"com.apple.dock", @"bundle",
        nil]];

    [_rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Terminal", @"name",
        @"-", @"pid",
        @"Apple application", @"kind",
        @"bundle-identifier", @"confidence",
        @"com.apple.Terminal", @"bundle",
        nil]];
}

- (void)loadRowsFromDatabase
{
    NSString *dbPath;
    NSError *error;
    LRMDatabase *database;
    LRMStatement *statement;
    LRMResultSet *resultSet;

    dbPath = [self databasePath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        NSLog(@"LeoCol database not found at %@; using fallback rows.", dbPath);
        [self addFallbackRows];
        return;
    }

    error = nil;
    database = [LRMDatabase databaseWithPath:dbPath error:&error];

    if (database == nil || ![database open:&error]) {
        NSLog(@"LeoCol could not open database %@: %@", dbPath, error);
        [self addFallbackRows];
        return;
    }

    statement = [database prepareStatement:
        @"SELECT "
        @"  l.process_name AS process_name, "
        @"  l.pid AS pid, "
        @"  i.bundle_identifier AS bundle_identifier, "
        @"  i.bundle_name AS bundle_name, "
        @"  i.classification AS classification, "
        @"  i.confidence AS confidence "
        @"FROM process_lifecycle l "
        @"LEFT JOIN process_identity i ON i.lifecycle_id = l.id "
        @"ORDER BY l.exit_observed ASC, l.process_name ASC "
        @"LIMIT 200;"
        error:&error];

    if (statement == nil) {
        NSLog(@"LeoCol prepare failed: %@", error);
        [database close];
        [self addFallbackRows];
        return;
    }

    resultSet = [statement executeQuery:&error];

    if (resultSet == nil) {
        NSLog(@"LeoCol query failed: %@", error);
        [database close];
        [self addFallbackRows];
        return;
    }

    while ([resultSet next:&error]) {
        LRMRow *row;
        NSString *processName;
        NSNumber *pid;
        NSString *bundleIdentifier;
        NSString *bundleName;
        NSString *classification;
        NSString *confidence;
        NSString *displayName;

        row = [resultSet currentRow];

        processName = [row stringForColumn:@"process_name"];
        pid = [row numberForColumn:@"pid"];
        bundleIdentifier = [row stringForColumn:@"bundle_identifier"];
        bundleName = [row stringForColumn:@"bundle_name"];
        classification = [row stringForColumn:@"classification"];
        confidence = [row stringForColumn:@"confidence"];

        displayName = processName;

        if (displayName == nil || [displayName length] == 0) {
            displayName = bundleName;
        }

        if (displayName == nil || [displayName length] == 0) {
            displayName = @"-";
        }

        [_rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            displayName, @"name",
            pid != nil ? [pid stringValue] : @"-", @"pid",
            classification != nil ? classification : @"unknown", @"kind",
            confidence != nil ? confidence : @"unknown", @"confidence",
            bundleIdentifier != nil ? bundleIdentifier : @"-", @"bundle",
            nil]];
    }

    if (error != nil) {
        NSLog(@"LeoCol result iteration failed: %@", error);
    }

    [resultSet close];
    [database close];

    if ([_rows count] == 0) {
        [self addFallbackRows];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSScrollView *scrollView;
    NSTableColumn *nameColumn;
    NSTableColumn *pidColumn;
    NSTableColumn *bundleColumn;
    NSTableColumn *kindColumn;
    NSTableColumn *confidenceColumn;

    (void)notification;

    _rows = [[NSMutableArray alloc] init];
    [self loadRowsFromDatabase];

    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(120, 120, 920, 420)
                                         styleMask:(NSTitledWindowMask |
                                                    NSClosableWindowMask |
                                                    NSMiniaturizableWindowMask |
                                                    NSResizableWindowMask)
                                           backing:NSBackingStoreBuffered
                                             defer:NO];

    [_window setTitle:@"LeoCol"];

    scrollView = [[[NSScrollView alloc] initWithFrame:[[_window contentView] bounds]] autorelease];
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:YES];
    [scrollView setBorderType:NSBezelBorder];

    _tableView = [[[NSTableView alloc] initWithFrame:[scrollView bounds]] autorelease];
    [_tableView setDelegate:(id)self];
    [_tableView setDataSource:(id)self];
    [_tableView setUsesAlternatingRowBackgroundColors:YES];

    nameColumn = [[[NSTableColumn alloc] initWithIdentifier:@"name"] autorelease];
    [[nameColumn headerCell] setStringValue:@"Process"];
    [nameColumn setWidth:180.0];
    [_tableView addTableColumn:nameColumn];

    pidColumn = [[[NSTableColumn alloc] initWithIdentifier:@"pid"] autorelease];
    [[pidColumn headerCell] setStringValue:@"PID"];
    [pidColumn setWidth:70.0];
    [_tableView addTableColumn:pidColumn];

    bundleColumn = [[[NSTableColumn alloc] initWithIdentifier:@"bundle"] autorelease];
    [[bundleColumn headerCell] setStringValue:@"Bundle Identifier"];
    [bundleColumn setWidth:240.0];
    [_tableView addTableColumn:bundleColumn];

    kindColumn = [[[NSTableColumn alloc] initWithIdentifier:@"kind"] autorelease];
    [[kindColumn headerCell] setStringValue:@"Classification"];
    [kindColumn setWidth:220.0];
    [_tableView addTableColumn:kindColumn];

    confidenceColumn = [[[NSTableColumn alloc] initWithIdentifier:@"confidence"] autorelease];
    [[confidenceColumn headerCell] setStringValue:@"Confidence"];
    [confidenceColumn setWidth:180.0];
    [_tableView addTableColumn:confidenceColumn];

    [scrollView setDocumentView:_tableView];
    [[_window contentView] addSubview:scrollView];

    [_window makeKeyAndOrderFront:nil];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    (void)tableView;
    return [_rows count];
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)rowIndex
{
    NSDictionary *row;

    (void)tableView;

    row = [_rows objectAtIndex:rowIndex];

    return [row objectForKey:[tableColumn identifier]];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    (void)sender;
    return YES;
}

- (void)dealloc
{
    [_rows release];
    [_window release];

    [super dealloc];
}

@end

int main(int argc, char *argv[])
{
    NSAutoreleasePool *pool;
    NSApplication *application;
    LeoColAppDelegate *delegate;

    (void)argc;
    (void)argv;

    pool = [[NSAutoreleasePool alloc] init];

    application = [NSApplication sharedApplication];
    delegate = [[LeoColAppDelegate alloc] init];

    [application setDelegate:delegate];
    [application run];

    [delegate release];
    [pool release];

    return 0;
}
