#import "LCAppDelegate.h"
#import "LCString.h"
#import "LCPresentation.h"
#import "LCProcessStore.h"
#import "LCProvenanceStore.h"
#import "LCDateFormatting.h"

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

@implementation LeoColAppDelegate


- (void)setStatusString:(NSString *)status
{
    if (_statusField != nil) {
        [_statusField setStringValue:(status != nil ? status : @"")];
    }
}



- (void)loadRowsFromDatabase
{
    NSString *statusString;
    NSArray *loadedRows;

    statusString = nil;
    loadedRows = [LCProcessStore loadProcessRowsWithStatusString:&statusString];

    [_rows removeAllObjects];
    [_rows addObjectsFromArray:loadedRows];

    if (statusString != nil) {
        [self setStatusString:statusString];
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

    keys = [NSArray arrayWithObjects:@"name", @"pid", @"bundleName", @"observed", @"executable", @"bundle", @"kind", @"confidence", nil];
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

    [self setStatusString:[NSString stringWithFormat:LCString(@"Status.ShowingRows"),
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
    return LCPresentationStringForValue([row objectForKey:key], key, YES);
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
        [_detailTextView setString:LCString(@"Detail.NoSelection")];
        return;
    }

    row = [_visibleRows objectAtIndex:selectedRow];

    detail = [NSMutableString string];

    [self appendDetailLineWithLabel:LCString(@"Detail.Process")
                              value:[self displayStringForRow:row key:@"name"]
                           toString:detail];
    [self appendDetailLineWithLabel:LCString(@"Detail.PID")
                              value:[self displayStringForRow:row key:@"pid"]
                           toString:detail];
    [self appendDetailLineWithLabel:LCString(@"Detail.Bundle")
                              value:[self displayStringForRow:row key:@"bundle"]
                           toString:detail];
    [self appendDetailLineWithLabel:LCString(@"Detail.BundleName")
                              value:[self displayStringForRow:row key:@"bundleName"]
                           toString:detail];
    [self appendDetailLineWithLabel:LCString(@"Detail.Classification")
                              value:[self displayStringForRow:row key:@"kind"]
                           toString:detail];
    [self appendDetailLineWithLabel:LCString(@"Detail.Confidence")
                              value:[self displayStringForRow:row key:@"confidence"]
                           toString:detail];
    [self appendDetailLineWithLabel:LCString(@"Detail.Executable")
                              value:[self displayStringForRow:row key:@"executable"]
                           toString:detail];
    [self appendDetailLineWithLabel:LCString(@"Detail.FirstSeen")
                              value:LCDisplayTimestampString([self displayStringForRow:row key:@"firstSeen"])
                           toString:detail];
    [self appendDetailLineWithLabel:LCString(@"Detail.LastSeen")
                              value:LCDisplayTimestampString([self displayStringForRow:row key:@"lastSeen"])
                           toString:detail];
    [self appendDetailLineWithLabel:LCString(@"Detail.ExecutablePath")
                              value:[self displayStringForRow:row key:@"executablePath"]
                           toString:detail];

    [_detailTextView setString:detail];
}

- (NSString *)evidenceSummaryText
{
    NSString *statusString;
    NSArray *rows;
    NSMutableString *summary;
    NSEnumerator *enumerator;
    NSDictionary *row;

    statusString = nil;
    rows = [LCProvenanceStore loadEvidenceSummaryRowsWithStatusString:&statusString];

    if ([rows count] == 0) {
        if (statusString != nil && [statusString length] > 0) {
            return statusString;
        }

        return LCString(@"EvidenceSummary.Empty");
    }

    summary = [NSMutableString string];

    enumerator = [rows objectEnumerator];

    while ((row = [enumerator nextObject]) != nil) {
        NSString *evidenceType;
        NSString *resolutionState;
        NSNumber *count;

        evidenceType = LCPresentationStringForValue([row objectForKey:@"evidenceType"],
                                                    @"evidenceType",
                                                    YES);
        resolutionState = LCPresentationStringForValue([row objectForKey:@"resolutionState"],
                                                       @"resolutionState",
                                                       YES);
        count = [row objectForKey:@"count"];

        [summary appendFormat:@"%@ / %@: %@\n",
            evidenceType,
            resolutionState,
            count != nil ? count : [NSNumber numberWithInt:0]];
    }

    return summary;
}

- (void)showEvidenceSummary:(id)sender
{
    NSAlert *alert;

    (void)sender;

    alert = [[[NSAlert alloc] init] autorelease];

    [alert setMessageText:LCString(@"EvidenceSummary.Title")];
    [alert setInformativeText:[self evidenceSummaryText]];
    [alert addButtonWithTitle:LCString(@"Button.OK")];

    [alert runModal];
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSView *contentView;
    NSRect contentBounds;
    NSButton *reloadButton;
    NSButton *evidenceButton;
    NSTextField *filterLabel;
    NSScrollView *scrollView;
    NSTextField *detailLabel;
    NSScrollView *detailScrollView;
    NSTableColumn *nameColumn;
    NSTableColumn *pidColumn;
    NSTableColumn *bundleNameColumn;
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
    [reloadButton setTitle:LCString(@"Button.Reload")];
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
    [filterLabel setStringValue:LCString(@"Label.Filter")];
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

    evidenceButton = [[[NSButton alloc] initWithFrame:NSMakeRect(390,
                                                                 contentBounds.size.height - 34,
                                                                 90,
                                                                 24)] autorelease];
    [evidenceButton setTitle:LCString(@"Button.EvidenceSummary")];
    [evidenceButton setButtonType:NSMomentaryPushInButton];
    [evidenceButton setBezelStyle:NSRoundedBezelStyle];
    [evidenceButton setTarget:self];
    [evidenceButton setAction:@selector(showEvidenceSummary:)];
    [evidenceButton setAutoresizingMask:(NSViewMaxXMargin | NSViewMinYMargin)];
    [contentView addSubview:evidenceButton];

    _statusField = [[[NSTextField alloc] initWithFrame:NSMakeRect(12,
                                                                  2,
                                                                  contentBounds.size.width - 24,
                                                                  18)] autorelease];
    [_statusField setEditable:NO];
    [_statusField setSelectable:NO];
    [_statusField setBordered:NO];
    [_statusField setDrawsBackground:NO];
    [_statusField setFont:[NSFont systemFontOfSize:11.0]];
    [_statusField setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
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
    [[nameColumn headerCell] setStringValue:LCString(@"Column.Process")];
    [nameColumn setWidth:210.0];
    [_tableView addTableColumn:nameColumn];

    pidColumn = [[[NSTableColumn alloc] initWithIdentifier:@"pid"] autorelease];
    [[pidColumn headerCell] setStringValue:LCString(@"Column.PID")];
    [pidColumn setWidth:60.0];
    [_tableView addTableColumn:pidColumn];

    bundleNameColumn = [[[NSTableColumn alloc] initWithIdentifier:@"bundleName"] autorelease];
    [[bundleNameColumn headerCell] setStringValue:LCString(@"Column.BundleName")];
    [bundleNameColumn setWidth:190.0];
    [_tableView addTableColumn:bundleNameColumn];

    observedColumn = [[[NSTableColumn alloc] initWithIdentifier:@"observed"] autorelease];
    [[observedColumn headerCell] setStringValue:LCString(@"Column.Observed")];
    [observedColumn setWidth:120.0];
    [_tableView addTableColumn:observedColumn];

    executableColumn = [[[NSTableColumn alloc] initWithIdentifier:@"executable"] autorelease];
    [[executableColumn headerCell] setStringValue:LCString(@"Column.Executable")];
    [executableColumn setWidth:130.0];
    [_tableView addTableColumn:executableColumn];

    kindColumn = [[[NSTableColumn alloc] initWithIdentifier:@"kind"] autorelease];
    [[kindColumn headerCell] setStringValue:LCString(@"Column.Classification")];
    [kindColumn setWidth:230.0];
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
    [detailLabel setStringValue:LCString(@"Label.ProcessDetails")];
    [detailLabel setAutoresizingMask:(NSViewMaxXMargin | NSViewMaxYMargin)];
    [contentView addSubview:detailLabel];

    detailScrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(0,
                                                                       22,
                                                                       contentBounds.size.width,
                                                                       218)] autorelease];
    [detailScrollView setAutoresizingMask:(NSViewWidthSizable | NSViewMaxYMargin)];
    [detailScrollView setHasVerticalScroller:YES];
    [detailScrollView setHasHorizontalScroller:NO];
    [detailScrollView setBorderType:NSBezelBorder];

    _detailTextView = [[[NSTextView alloc] initWithFrame:[detailScrollView bounds]] autorelease];
    [_detailTextView setEditable:NO];
    [_detailTextView setSelectable:YES];
    [_detailTextView setFont:[NSFont userFixedPitchFontOfSize:12.0]];
    [_detailTextView setString:LCString(@"Detail.NoSelection")];

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

    if ([identifier isEqualToString:@"observed"]) {
        return LCDisplayCompactTimestampString((value != nil ? [value description] : nil));
    }

    return LCPresentationStringForValue(value, identifier, NO);
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

