#import <Cocoa/Cocoa.h>

@interface LeoColAppDelegate : NSObject
{
    NSWindow *_window;
    NSTableView *_tableView;
    NSArray *_rows;
}
@end

@implementation LeoColAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSScrollView *scrollView;
    NSTableColumn *nameColumn;
    NSTableColumn *kindColumn;
    NSTableColumn *confidenceColumn;

    (void)notification;

    _rows = [[NSArray alloc] initWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Finder", @"name",
            @"Apple system component", @"kind",
            @"path-app-contained", @"confidence",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Dock", @"name",
            @"Apple system component", @"kind",
            @"path-app-contained", @"confidence",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Terminal", @"name",
            @"Apple application", @"kind",
            @"bundle-identifier", @"confidence",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"Xcode", @"name",
            @"developer tool", @"kind",
            @"path-app-contained", @"confidence",
            nil],
        nil];

    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(120, 120, 760, 360)
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
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setBorderType:NSBezelBorder];

    _tableView = [[[NSTableView alloc] initWithFrame:[scrollView bounds]] autorelease];
    [_tableView setDelegate:(id)self];
    [_tableView setDataSource:(id)self];
    [_tableView setUsesAlternatingRowBackgroundColors:YES];

    nameColumn = [[[NSTableColumn alloc] initWithIdentifier:@"name"] autorelease];
    [[nameColumn headerCell] setStringValue:@"Process"];
    [nameColumn setWidth:220.0];
    [_tableView addTableColumn:nameColumn];

    kindColumn = [[[NSTableColumn alloc] initWithIdentifier:@"kind"] autorelease];
    [[kindColumn headerCell] setStringValue:@"Classification"];
    [kindColumn setWidth:260.0];
    [_tableView addTableColumn:kindColumn];

    confidenceColumn = [[[NSTableColumn alloc] initWithIdentifier:@"confidence"] autorelease];
    [[confidenceColumn headerCell] setStringValue:@"Confidence"];
    [confidenceColumn setWidth:220.0];
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
