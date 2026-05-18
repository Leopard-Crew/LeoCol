#import <Cocoa/Cocoa.h>
#import "../bricks/LeoRM/Sources/LeoRM.h"

typedef struct LeoColSortContext {
    NSString *key;
    BOOL ascending;
} LeoColSortContext;

static NSComparisonResult
LeoColCompareRows(id leftObject, id rightObject, void *contextPointer)
{
    LeoColSortContext *context;
    NSDictionary *leftRow;
    NSDictionary *rightRow;
    id leftValue;
    id rightValue;
    NSComparisonResult result;

    context = (LeoColSortContext *)contextPointer;
    leftRow = (NSDictionary *)leftObject;
    rightRow = (NSDictionary *)rightObject;

    leftValue = [leftRow objectForKey:context->key];
    rightValue = [rightRow objectForKey:context->key];

    if ([context->key isEqualToString:@"pid"]) {
        int leftPID;
        int rightPID;

        leftPID = leftValue != nil ? [leftValue intValue] : -1;
        rightPID = rightValue != nil ? [rightValue intValue] : -1;

        if (leftPID < rightPID) {
            result = NSOrderedAscending;
        } else if (leftPID > rightPID) {
            result = NSOrderedDescending;
        } else {
            result = NSOrderedSame;
        }
    } else {
        NSString *leftString;
        NSString *rightString;

        leftString = leftValue != nil ? [leftValue description] : @"";
        rightString = rightValue != nil ? [rightValue description] : @"";

        result = [leftString caseInsensitiveCompare:rightString];
    }

    if (!context->ascending) {
        if (result == NSOrderedAscending) {
            return NSOrderedDescending;
        }

        if (result == NSOrderedDescending) {
            return NSOrderedAscending;
        }
    }

    return result;
}

@interface LeoColAppDelegate : NSObject
{
    NSWindow *_window;
    NSTableView *_tableView;
    NSMutableArray *_rows;
    NSMutableArray *_visibleRows;
    NSTextField *_filterField;
    NSTextField *_statusField;
    NSTextView *_detailTextView;
    NSString *_sortKey;
    BOOL _sortAscending;
}
- (void)reloadData:(id)sender;
- (void)filterChanged:(id)sender;
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
        @"-", @"firstSeen",
        @"-", @"lastSeen",
        [NSNumber numberWithInt:0], @"exitObserved",
        @"-", @"executablePath",
        @"fallback", @"observed",
        @"unknown", @"executable",
        @"com.apple.finder", @"bundle",
        @"Finder", @"bundleName",
        @"Apple system component", @"kind",
        @"path-app-contained", @"confidence",
        nil]];

    [_rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Dock", @"name",
        [NSNumber numberWithInt:-1], @"pid",
        @"-", @"firstSeen",
        @"-", @"lastSeen",
        [NSNumber numberWithInt:0], @"exitObserved",
        @"-", @"executablePath",
        @"fallback", @"observed",
        @"unknown", @"executable",
        @"com.apple.dock", @"bundle",
        @"Dock", @"bundleName",
        @"Apple system component", @"kind",
        @"path-app-contained", @"confidence",
        nil]];

    [_rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
        @"Terminal", @"name",
        [NSNumber numberWithInt:-1], @"pid",
        @"-", @"firstSeen",
        @"-", @"lastSeen",
        [NSNumber numberWithInt:0], @"exitObserved",
        @"-", @"executablePath",
        @"fallback", @"observed",
        @"unknown", @"executable",
        @"com.apple.Terminal", @"bundle",
        @"Terminal", @"bundleName",
        @"Apple application", @"kind",
        @"bundle-identifier", @"confidence",
        nil]];
}

- (NSString *)executablePresenceForPath:(NSString *)path
{
    BOOL isDirectory;

    if (path == nil || [path length] == 0 || [path isEqualToString:@"-"]) {
        return @"unknown";
    }

    isDirectory = NO;

    if ([[NSFileManager defaultManager] fileExistsAtPath:path
                                             isDirectory:&isDirectory]) {
        return isDirectory ? @"directory" : @"present";
    }

    return @"missing";
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
        @"  l.first_seen_at AS first_seen_at, "
        @"  l.last_seen_at AS last_seen_at, "
        @"  l.exit_observed AS exit_observed, "
        @"  l.executable_path AS executable_path, "
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
        NSString *firstSeen;
        NSString *lastSeen;
        NSNumber *exitObserved;
        NSString *executablePath;
        NSString *observedState;
        NSString *executableState;
        NSString *bundleIdentifier;
        NSString *bundleName;
        NSString *classification;
        NSString *confidence;
        NSString *displayName;

        row = [resultSet currentRow];

        processName = [row stringForColumn:@"process_name"];
        pid = [row numberForColumn:@"pid"];
        firstSeen = [row stringForColumn:@"first_seen_at"];
        lastSeen = [row stringForColumn:@"last_seen_at"];
        exitObserved = [row numberForColumn:@"exit_observed"];
        executablePath = [row stringForColumn:@"executable_path"];
        bundleIdentifier = [row stringForColumn:@"bundle_identifier"];
        bundleName = [row stringForColumn:@"bundle_name"];
        classification = [row stringForColumn:@"classification"];
        confidence = [row stringForColumn:@"confidence"];

        observedState = (exitObserved != nil && [exitObserved intValue] != 0)
            ? @"Earlier snapshot"
            : @"Latest snapshot";

        executableState = [self executablePresenceForPath:executablePath];

        displayName = processName;

        if (displayName == nil || [displayName length] == 0) {
            displayName = bundleName;
        }

        if (displayName == nil || [displayName length] == 0) {
            displayName = @"-";
        }

        [_rows addObject:[NSDictionary dictionaryWithObjectsAndKeys:
            displayName, @"name",
            pid != nil ? pid : [NSNumber numberWithInt:-1], @"pid",
            firstSeen != nil ? firstSeen : @"-", @"firstSeen",
            lastSeen != nil ? lastSeen : @"-", @"lastSeen",
            exitObserved != nil ? exitObserved : [NSNumber numberWithInt:0], @"exitObserved",
            executablePath != nil ? executablePath : @"-", @"executablePath",
            observedState, @"observed",
            executableState, @"executable",
            bundleIdentifier != nil ? bundleIdentifier : @"-", @"bundle",
            bundleName != nil ? bundleName : @"-", @"bundleName",
            classification != nil ? classification : @"unknown", @"kind",
            confidence != nil ? confidence : @"unknown", @"confidence",
            nil]];
    }

    if (error != nil) {
        NSLog(@"LeoCol result iteration failed: %@", error);
        [self setStatusString:@"Result iteration failed"];
    }

    [resultSet close];
    [database close];

    if ([_rows count] == 0) {
        [self addFallbackRows];
        [self setStatusString:@"Database returned no rows — showing fallback rows"];
    }
}

- (BOOL)row:(NSDictionary *)row matchesFilter:(NSString *)filter
{
    NSArray *keys;
    NSEnumerator *enumerator;
    NSString *key;

    if (filter == nil || [filter length] == 0) {
        return YES;
    }

    keys = [NSArray arrayWithObjects:@"name", @"pid", @"observed", @"executable", @"bundle", @"kind", @"confidence", nil];
    enumerator = [keys objectEnumerator];

    while ((key = [enumerator nextObject]) != nil) {
        id value;
        NSString *text;

        value = [row objectForKey:key];

        if (value == nil) {
            continue;
        }

        if ([key isEqualToString:@"pid"] && [value intValue] < 0) {
            text = @"";
        } else {
            text = [value description];
        }

        if ([text rangeOfString:filter options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }

    return NO;
}

- (void)sortRowsByKey:(NSString *)key ascending:(BOOL)ascending
{
    LeoColSortContext context;

    if (key == nil) {
        return;
    }

    context.key = key;
    context.ascending = ascending;

    [_visibleRows sortUsingFunction:LeoColCompareRows context:&context];
}

- (void)applyFilterAndSort
{
    NSString *filter;
    NSEnumerator *enumerator;
    NSDictionary *row;

    [_visibleRows removeAllObjects];

    filter = [_filterField stringValue];

    enumerator = [_rows objectEnumerator];

    while ((row = [enumerator nextObject]) != nil) {
        if ([self row:row matchesFilter:filter]) {
            [_visibleRows addObject:row];
        }
    }

    if (_sortKey != nil) {
        [self sortRowsByKey:_sortKey ascending:_sortAscending];
    }

    [self setStatusString:[NSString stringWithFormat:@"Showing %lu of %lu rows",
        (unsigned long)[_visibleRows count],
        (unsigned long)[_rows count]]];
}

- (void)reloadData:(id)sender
{
    (void)sender;

    [self loadRowsFromDatabase];
    [self applyFilterAndSort];

    if (_tableView != nil) {
        [_tableView reloadData];
    }

    [self updateDetailView];
}

- (void)filterChanged:(id)sender
{
    (void)sender;

    [self applyFilterAndSort];

    if (_tableView != nil) {
        [_tableView reloadData];
    }

    [self updateDetailView];
}

- (void)controlTextDidChange:(NSNotification *)notification
{
    (void)notification;

    [self filterChanged:nil];
}

- (NSString *)displayStringForRow:(NSDictionary *)row key:(NSString *)key
{
    id value;

    value = [row objectForKey:key];

    if (value == nil) {
        return @"-";
    }

    if ([key isEqualToString:@"pid"] && [value intValue] < 0) {
        return @"-";
    }

    return [value description];
}

- (NSString *)displayTimestampString:(NSString *)timestamp
{
    NSDateFormatter *parser;
    NSDateFormatter *displayFormatter;
    NSDate *date;
    NSString *result;

    if (timestamp == nil || [timestamp length] == 0 || [timestamp isEqualToString:@"-"]) {
        return @"-";
    }

    parser = [[NSDateFormatter alloc] init];
    [parser setFormatterBehavior:NSDateFormatterBehavior10_4];
    [parser setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
    [parser setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];

    date = [parser dateFromString:timestamp];
    [parser release];

    if (date == nil) {
        return timestamp;
    }

    displayFormatter = [[NSDateFormatter alloc] init];
    [displayFormatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [displayFormatter setDateStyle:NSDateFormatterMediumStyle];
    [displayFormatter setTimeStyle:NSDateFormatterMediumStyle];

    result = [[displayFormatter stringFromDate:date] retain];
    [displayFormatter release];

    return [result autorelease];
}

- (NSString *)detailContinuationIndentWithWidth:(NSUInteger)width
{
    NSMutableString *indent;
    NSUInteger i;

    indent = [NSMutableString string];

    for (i = 0; i < width; i++) {
        [indent appendString:@" "];
    }

    return indent;
}

- (NSString *)wrappedDetailValue:(NSString *)value continuationWidth:(NSUInteger)continuationWidth
{
    NSMutableString *wrapped;
    NSString *remaining;
    NSUInteger maxValueLength;

    if (value == nil || [value length] == 0) {
        return @"-";
    }

    maxValueLength = 92;
    remaining = value;
    wrapped = [NSMutableString string];

    while ([remaining length] > maxValueLength) {
        NSRange slashRange;
        NSRange searchRange;
        NSUInteger splitIndex;

        searchRange = NSMakeRange(1, maxValueLength - 1);
        slashRange = [remaining rangeOfString:@"/"
                                      options:NSBackwardsSearch
                                        range:searchRange];

        if (slashRange.location != NSNotFound && slashRange.location > 8) {
            splitIndex = slashRange.location + 1;
        } else {
            splitIndex = maxValueLength;
        }

        [wrapped appendString:[remaining substringToIndex:splitIndex]];
        [wrapped appendString:@"\n"];
        [wrapped appendString:[self detailContinuationIndentWithWidth:continuationWidth]];

        remaining = [remaining substringFromIndex:splitIndex];
    }

    [wrapped appendString:remaining];

    return wrapped;
}

- (void)appendDetailLineWithLabel:(NSString *)label
                            value:(NSString *)value
                         toString:(NSMutableString *)detail
{
    NSString *labelText;
    NSString *displayValue;
    NSUInteger labelWidth;
    NSUInteger i;

    labelWidth = 18;
    labelText = [NSString stringWithFormat:@"%@:", label];

    [detail appendString:labelText];

    if ([labelText length] < labelWidth) {
        for (i = [labelText length]; i < labelWidth; i++) {
            [detail appendString:@" "];
        }
    } else {
        [detail appendString:@" "];
        labelWidth = [labelText length] + 1;
    }

    displayValue = [self wrappedDetailValue:value continuationWidth:labelWidth];

    [detail appendString:displayValue];
    [detail appendString:@"\n"];
}

- (void)updateDetailView
{
    NSInteger selectedRow;
    NSDictionary *row;
    NSMutableString *detail;

    if (_detailTextView == nil || _tableView == nil) {
        return;
    }

    selectedRow = [_tableView selectedRow];

    if (selectedRow < 0 || selectedRow >= (NSInteger)[_visibleRows count]) {
        [_detailTextView setString:@"No process selected."];
        return;
    }

    row = [_visibleRows objectAtIndex:selectedRow];

    detail = [NSMutableString string];

    [self appendDetailLineWithLabel:@"Process"
                              value:[self displayStringForRow:row key:@"name"]
                           toString:detail];
    [self appendDetailLineWithLabel:@"PID"
                              value:[self displayStringForRow:row key:@"pid"]
                           toString:detail];
    [self appendDetailLineWithLabel:@"Bundle"
                              value:[self displayStringForRow:row key:@"bundle"]
                           toString:detail];
    [self appendDetailLineWithLabel:@"Bundle Name"
                              value:[self displayStringForRow:row key:@"bundleName"]
                           toString:detail];
    [self appendDetailLineWithLabel:@"Classification"
                              value:[self displayStringForRow:row key:@"kind"]
                           toString:detail];
    [self appendDetailLineWithLabel:@"Confidence"
                              value:[self displayStringForRow:row key:@"confidence"]
                           toString:detail];
    [self appendDetailLineWithLabel:@"Observed"
                              value:[self displayStringForRow:row key:@"observed"]
                           toString:detail];
    [self appendDetailLineWithLabel:@"Executable"
                              value:[self displayStringForRow:row key:@"executable"]
                           toString:detail];
    [self appendDetailLineWithLabel:@"First Seen"
                              value:[self displayTimestampString:[self displayStringForRow:row key:@"firstSeen"]]
                           toString:detail];
    [self appendDetailLineWithLabel:@"Last Seen"
                              value:[self displayTimestampString:[self displayStringForRow:row key:@"lastSeen"]]
                           toString:detail];
    [self appendDetailLineWithLabel:@"Executable Path"
                              value:[self displayStringForRow:row key:@"executablePath"]
                           toString:detail];

    [_detailTextView setString:detail];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSView *contentView;
    NSRect contentBounds;
    NSButton *reloadButton;
    NSTextField *filterLabel;
    NSScrollView *scrollView;
    NSTextField *detailLabel;
    NSScrollView *detailScrollView;
    NSTableColumn *nameColumn;
    NSTableColumn *observedColumn;
    NSTableColumn *executableColumn;
    NSTableColumn *kindColumn;

    (void)notification;

    _rows = [[NSMutableArray alloc] init];
    _visibleRows = [[NSMutableArray alloc] init];

    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(120, 120, 980, 720)
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

    filterLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(114,
                                                                 contentBounds.size.height - 31,
                                                                 42,
                                                                 18)] autorelease];
    [filterLabel setEditable:NO];
    [filterLabel setSelectable:NO];
    [filterLabel setBordered:NO];
    [filterLabel setDrawsBackground:NO];
    [filterLabel setFont:[NSFont systemFontOfSize:11.0]];
    [filterLabel setStringValue:@"Filter:"];
    [filterLabel setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
    [contentView addSubview:filterLabel];

    _filterField = [[[NSTextField alloc] initWithFrame:NSMakeRect(158,
                                                                  contentBounds.size.height - 34,
                                                                  220,
                                                                  22)] autorelease];
    [_filterField setTarget:self];
    [_filterField setAction:@selector(filterChanged:)];
    [_filterField setDelegate:(id)self];
    [_filterField setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
    [contentView addSubview:_filterField];

    _statusField = [[[NSTextField alloc] initWithFrame:NSMakeRect(390,
                                                                  contentBounds.size.height - 32,
                                                                  contentBounds.size.width - 402,
                                                                  20)] autorelease];
    [_statusField setEditable:NO];
    [_statusField setSelectable:NO];
    [_statusField setBordered:NO];
    [_statusField setDrawsBackground:NO];
    [_statusField setFont:[NSFont systemFontOfSize:11.0]];
    [_statusField setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
    [contentView addSubview:_statusField];

    scrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(0,
                                                                 270,
                                                                 contentBounds.size.width,
                                                                 contentBounds.size.height - 314)] autorelease];
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
    [nameColumn setWidth:260.0];
    [_tableView addTableColumn:nameColumn];

    observedColumn = [[[NSTableColumn alloc] initWithIdentifier:@"observed"] autorelease];
    [[observedColumn headerCell] setStringValue:@"Observed"];
    [observedColumn setWidth:130.0];
    [_tableView addTableColumn:observedColumn];

    executableColumn = [[[NSTableColumn alloc] initWithIdentifier:@"executable"] autorelease];
    [[executableColumn headerCell] setStringValue:@"Executable"];
    [executableColumn setWidth:100.0];
    [_tableView addTableColumn:executableColumn];

    kindColumn = [[[NSTableColumn alloc] initWithIdentifier:@"kind"] autorelease];
    [[kindColumn headerCell] setStringValue:@"Classification"];
    [kindColumn setWidth:300.0];
    [_tableView addTableColumn:kindColumn];

    [scrollView setDocumentView:_tableView];
    [contentView addSubview:scrollView];

    detailLabel = [[[NSTextField alloc] initWithFrame:NSMakeRect(12,
                                                                  244,
                                                                  180,
                                                                  18)] autorelease];
    [detailLabel setEditable:NO];
    [detailLabel setSelectable:NO];
    [detailLabel setBordered:NO];
    [detailLabel setDrawsBackground:NO];
    [detailLabel setFont:[NSFont boldSystemFontOfSize:11.0]];
    [detailLabel setStringValue:@"Process Details"];
    [detailLabel setAutoresizingMask:(NSViewMaxXMargin | NSViewMaxYMargin)];
    [contentView addSubview:detailLabel];

    detailScrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(0,
                                                                       0,
                                                                       contentBounds.size.width,
                                                                       240)] autorelease];
    [detailScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
    [detailScrollView setHasVerticalScroller:YES];
    [detailScrollView setHasHorizontalScroller:NO];
    [detailScrollView setBorderType:NSBezelBorder];

    _detailTextView = [[[NSTextView alloc] initWithFrame:[detailScrollView bounds]] autorelease];
    [_detailTextView setEditable:NO];
    [_detailTextView setSelectable:YES];
    [_detailTextView setFont:[NSFont userFixedPitchFontOfSize:12.0]];
    [_detailTextView setString:@"No process selected."];

    [detailScrollView setDocumentView:_detailTextView];
    [contentView addSubview:detailScrollView];

    [self reloadData:nil];

    [_window makeKeyAndOrderFront:nil];
}

- (void)tableView:(NSTableView *)tableView
didClickTableColumn:(NSTableColumn *)tableColumn
{
    NSString *clickedKey;

    clickedKey = [tableColumn identifier];

    if (_sortKey != nil && [_sortKey isEqualToString:clickedKey]) {
        _sortAscending = !_sortAscending;
    } else {
        [_sortKey release];
        _sortKey = [clickedKey copy];
        _sortAscending = YES;
    }

    [self sortRowsByKey:_sortKey ascending:_sortAscending];

    [tableView setHighlightedTableColumn:tableColumn];
    [tableView reloadData];
}

- (BOOL)tableView:(NSTableView *)tableView
shouldEditTableColumn:(NSTableColumn *)tableColumn
              row:(NSInteger)rowIndex
{
    (void)tableView;
    (void)tableColumn;
    (void)rowIndex;

    return NO;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    (void)notification;

    [self updateDetailView];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    (void)tableView;
    return [_visibleRows count];
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)rowIndex
{
    NSDictionary *row;
    NSString *identifier;
    id value;

    (void)tableView;

    row = [_visibleRows objectAtIndex:rowIndex];
    identifier = [tableColumn identifier];
    value = [row objectForKey:identifier];

    if ([identifier isEqualToString:@"pid"] && value != nil && [value intValue] < 0) {
        return @"-";
    }

    return value;
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    (void)sender;
    return YES;
}

- (void)dealloc
{
    [_sortKey release];
    [_visibleRows release];
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
