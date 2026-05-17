#import <Cocoa/Cocoa.h>
#import "../bricks/LeoRM/Sources/LeoRM.h"

@interface LeoColAppDelegate : NSObject
{
    NSWindow *_window;
    NSTableView *_tableView;
    NSMutableArray *_rows;
    NSTextField *_statusField;
}
- (void)reloadData:(id)sender;
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

- (void)setStatusString:(NSString *)status
{
    if (_statusField != nil) {
        [_statusField setStringValue:(status != nil ? status : @"")];
    }
}

- (void)addFallbackRows
{
    [_rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Finder", @"name",
        [NSNumber numberWithInt:-1], @"pid",
        @"com.apple.finder", @"bundle",
        @"Apple system component", @"kind",
        @"path-app-contained", @"confidence",
        nil]];

    [_rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Dock", @"name",
        [NSNumber numberWithInt:-1], @"pid",
        @"com.apple.dock", @"bundle",
        @"Apple system component", @"kind",
        @"path-app-contained", @"confidence",
        nil]];

    [_rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Terminal", @"name",
        [NSNumber numberWithInt:-1], @"pid",
        @"com.apple.Terminal", @"bundle",
        @"Apple application", @"kind",
        @"bundle-identifier", @"confidence",
        nil]];
}

- (void)loadRowsFromDatabase
{
    NSString *dbPath;
    NSError *error;
    LRMDatabase *database;
    LRMStatement *statement;
    LRMResultSet *resultSet;

    [_rows removeAllObjects];

    dbPath = [self databasePath];

    if (![[NSFileManager defaultManager] fileExistsAtPath:dbPath]) {
        NSLog(@"LeoCol database not found at %@; using fallback rows.", dbPath);
        [self addFallbackRows];
        [self setStatusString:[NSString stringWithFormat:@"Database not found: %@ — showing fallback rows", dbPath]];
        return;
    }

    error = nil;
    database = [LRMDatabase databaseWithPath:dbPath error:&error];

    if (database == nil || ![database open:&error]) {
        NSLog(@"LeoCol could not open database %@: %@", dbPath, error);
        [self addFallbackRows];
        [self setStatusString:[NSString stringWithFormat:@"Could not open database: %@", dbPath]];
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
        [self setStatusString:@"Query prepare failed — showing fallback rows"];
        return;
    }

    resultSet = [statement executeQuery:&error];

    if (resultSet == nil) {
        NSLog(@"LeoCol query failed: %@", error);
        [database close];
        [self addFallbackRows];
        [self setStatusString:@"Query failed — showing fallback rows"];
        return;
    }

    error = nil;

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
            pid != nil ? [pid stringValue] : [NSNumber numberWithInt:-1], @"pid",
            bundleIdentifier != nil ? bundleIdentifier : @"-", @"bundle",
            classification != nil ? classification : @"unknown", @"kind",
            confidence != nil ? confidence : @"unknown", @"confidence",
            nil]];
    }

    if (error != nil) {
        NSLog(@"LeoCol result iteration failed: %@", error);
        [self setStatusString:@"Result iteration failed"];
    } else {
        [self setStatusString:[NSString stringWithFormat:@"Loaded %lu rows from %@",
            (unsigned long)[_rows count],
            dbPath]];
    }

    [resultSet close];
    [database close];

    if ([_rows count] == 0) {
        [self addFallbackRows];
        [self setStatusString:@"Database returned no rows — showing fallback rows"];
    }
}

- (void)reloadData:(id)sender
{
    (void)sender;

    [self loadRowsFromDatabase];

    if (_tableView != nil) {
        [_tableView reloadData];
    }
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSView *contentView;
    NSRect contentBounds;
    NSButton *reloadButton;
    NSScrollView *scrollView;
    NSTableColumn *nameColumn;
    NSTableColumn *pidColumn;
    NSTableColumn *bundleColumn;
    NSTableColumn *kindColumn;
    NSTableColumn *confidenceColumn;

    (void)notification;

    _rows = [[NSMutableArray alloc] init];

    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(120, 120, 940, 460)
                                         styleMask:(NSTitledWindowMask |
                                                    NSClosableWindowMask |
                                                    NSMiniaturizableWindowMask |
                                                    NSResizableWindowMask)
                                           backing:NSBackingStoreBuffered
                                             defer:NO];

    [_window setTitle:@"LeoCol"];

    contentView = [_window contentView];
    contentBounds = [contentView bounds];

    reloadButton = [[[NSButton alloc] initWithFrame:NSMakeRect(12,
                                                               contentBounds.size.height - 34,
                                                               90,
                                                               24)] autorelease];
    [reloadButton setTitle:@"Reload"];
    [reloadButton setButtonType:NSMomentaryPushInButton];
    [reloadButton setBezelStyle:NSRoundedBezelStyle];
    [reloadButton setTarget:self];
    [reloadButton setAction:@selector(reloadData:)];
    [reloadButton setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
    [contentView addSubview:reloadButton];

    _statusField = [[[NSTextField alloc] initWithFrame:NSMakeRect(112,
                                                                  contentBounds.size.height - 32,
                                                                  contentBounds.size.width - 124,
                                                                  20)] autorelease];
    [_statusField setEditable:NO];
    [_statusField setSelectable:NO];
    [_statusField setBordered:NO];
    [_statusField setDrawsBackground:NO];
    [_statusField setFont:[NSFont systemFontOfSize:11.0]];
    [_statusField setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
    [contentView addSubview:_statusField];

    scrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(0,
                                                                 0,
                                                                 contentBounds.size.width,
                                                                 contentBounds.size.height - 44)] autorelease];
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
    [nameColumn setSortDescriptorPrototype:
        [[[NSSortDescriptor alloc] initWithKey:@"name"
                                     ascending:YES
                                      selector:@selector(caseInsensitiveCompare:)] autorelease]];
    [_tableView addTableColumn:nameColumn];

    pidColumn = [[[NSTableColumn alloc] initWithIdentifier:@"pid"] autorelease];
    [[pidColumn headerCell] setStringValue:@"PID"];
    [pidColumn setWidth:70.0];
    [pidColumn setSortDescriptorPrototype:
        [[[NSSortDescriptor alloc] initWithKey:@"pid"
                                     ascending:YES] autorelease]];
    [_tableView addTableColumn:pidColumn];

    bundleColumn = [[[NSTableColumn alloc] initWithIdentifier:@"bundle"] autorelease];
    [[bundleColumn headerCell] setStringValue:@"Bundle Identifier"];
    [bundleColumn setWidth:260.0];
    [bundleColumn setSortDescriptorPrototype:
        [[[NSSortDescriptor alloc] initWithKey:@"bundle"
                                     ascending:YES
                                      selector:@selector(caseInsensitiveCompare:)] autorelease]];
    [_tableView addTableColumn:bundleColumn];

    kindColumn = [[[NSTableColumn alloc] initWithIdentifier:@"kind"] autorelease];
    [[kindColumn headerCell] setStringValue:@"Classification"];
    [kindColumn setWidth:220.0];
    [kindColumn setSortDescriptorPrototype:
        [[[NSSortDescriptor alloc] initWithKey:@"kind"
                                     ascending:YES
                                      selector:@selector(caseInsensitiveCompare:)] autorelease]];
    [_tableView addTableColumn:kindColumn];

    confidenceColumn = [[[NSTableColumn alloc] initWithIdentifier:@"confidence"] autorelease];
    [[confidenceColumn headerCell] setStringValue:@"Confidence"];
    [confidenceColumn setWidth:180.0];
    [confidenceColumn setSortDescriptorPrototype:
        [[[NSSortDescriptor alloc] initWithKey:@"confidence"
                                     ascending:YES
                                      selector:@selector(caseInsensitiveCompare:)] autorelease]];
    [_tableView addTableColumn:confidenceColumn];

    [scrollView setDocumentView:_tableView];
    [contentView addSubview:scrollView];

    [self reloadData:nil];

    [_window makeKeyAndOrderFront:nil];
}

- (void)tableView:(NSTableView *)tableView
sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    NSArray *sortDescriptors;

    (void)oldDescriptors;

    sortDescriptors = [tableView sortDescriptors];

    if ([sortDescriptors count] == 0) {
        return;
    }

    [_rows sortUsingDescriptors:sortDescriptors];
    [tableView reloadData];
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
