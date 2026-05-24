#import "LCAppDelegate.h"
#import "LCString.h"
#import "LCPresentation.h"
#import "LCProcessStore.h"
#import "LCProvenanceStore.h"
#import "LCSnapshotStore.h"
#import "LCOperationPanel.h"
#import "LCStoreSupport.h"
#import "LCDateFormatting.h"
#import <WebKit/WebKit.h>

typedef struct LeoColSortContext {
    NSString *key;
    BOOL ascending;
} LeoColSortContext;

static NSString *LeoColToolbarIdentifier = @"LeoColToolbar";
static NSString *LeoColToolbarReloadItemIdentifier = @"LeoColToolbarReloadItem";
static NSString *LeoColToolbarEvidenceItemIdentifier = @"LeoColToolbarEvidenceItem";
static NSString *LeoColToolbarSearchItemIdentifier = @"LeoColToolbarSearchItem";

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

@interface LeoColAppDelegate (Private)

- (void)updateDetailView;
- (void)installApplicationMenu;
- (void)installToolbar;
- (void)openEvidencePanel;
- (void)reloadEvidenceRows;
- (void)openSnapshotPanel;
- (void)reloadSnapshotRows;
- (NSString *)applicationProjectPath;
- (NSString *)pathForHelperNamed:(NSString *)helperName;
- (BOOL)runHelperNamed:(NSString *)helperName output:(NSString **)outputText;
- (void)appendOperationLogLine:(NSString *)line;
- (void)setOperationStatusText:(NSString *)status;
- (void)runUpdateSnapshotOperation:(id)sender;
- (void)finishUpdateSnapshotOperation:(NSDictionary *)result;
- (void)runUpdateEvidenceOperation:(id)sender;
- (void)finishUpdateEvidenceOperation:(NSDictionary *)result;
- (NSString *)exportReportText;
- (void)showExportFailureAlert;

@end

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

    keys = [NSArray arrayWithObjects:@"name", @"pid", @"instanceStatus", @"bundleName", @"observed", @"executable", @"bundle", @"kind", @"confidence", nil];
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

    filter = (_filterField != nil) ? [_filterField stringValue] : @"";

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
    [self appendDetailLineWithLabel:LCString(@"Detail.InstanceStatus")
                              value:[self displayStringForRow:row key:@"instanceStatus"]
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

- (void)reloadEvidenceRows
{
    NSString *statusString;
    NSArray *rows;

    statusString = nil;
    rows = [LCProvenanceStore loadEvidenceSummaryRowsWithStatusString:&statusString];

    [_evidenceRows removeAllObjects];

    if ([rows count] > 0) {
        [_evidenceRows addObjectsFromArray:rows];
    }

    if (_evidenceTableView != nil) {
        [_evidenceTableView reloadData];
    }
}

- (void)openEvidencePanel
{
    NSScrollView *scrollView;
    NSTableColumn *evidenceTypeColumn;
    NSTableColumn *resolutionStateColumn;
    NSTableColumn *countColumn;

    if (_evidencePanel != nil) {
        [self reloadEvidenceRows];
        [_evidencePanel makeKeyAndOrderFront:nil];
        return;
    }

    _evidencePanel = [[NSPanel alloc] initWithContentRect:NSMakeRect(180, 180, 520, 230)
                                                styleMask:(NSTitledWindowMask |
                                                           NSClosableWindowMask |
                                                           NSUtilityWindowMask)
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];

    [_evidencePanel setTitle:LCString(@"EvidenceSummary.Title")];
    [_evidencePanel setReleasedWhenClosed:NO];

    scrollView = [[[NSScrollView alloc] initWithFrame:[[_evidencePanel contentView] bounds]] autorelease];
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBorderType:NSBezelBorder];

    _evidenceTableView = [[[NSTableView alloc] initWithFrame:[scrollView bounds]] autorelease];
    [_evidenceTableView setDelegate:(id)self];
    [_evidenceTableView setDataSource:(id)self];
    [_evidenceTableView setUsesAlternatingRowBackgroundColors:YES];

    evidenceTypeColumn = [[[NSTableColumn alloc] initWithIdentifier:@"evidenceType"] autorelease];
    [[evidenceTypeColumn headerCell] setStringValue:LCString(@"Column.EvidenceType")];
    [evidenceTypeColumn setWidth:220.0];
    [_evidenceTableView addTableColumn:evidenceTypeColumn];

    resolutionStateColumn = [[[NSTableColumn alloc] initWithIdentifier:@"resolutionState"] autorelease];
    [[resolutionStateColumn headerCell] setStringValue:LCString(@"Column.ResolutionState")];
    [resolutionStateColumn setWidth:190.0];
    [_evidenceTableView addTableColumn:resolutionStateColumn];

    countColumn = [[[NSTableColumn alloc] initWithIdentifier:@"count"] autorelease];
    [[countColumn headerCell] setStringValue:LCString(@"Column.Count")];
    [countColumn setWidth:80.0];
    [_evidenceTableView addTableColumn:countColumn];

    [scrollView setDocumentView:_evidenceTableView];
    [[_evidencePanel contentView] addSubview:scrollView];

    [self reloadEvidenceRows];

    [_evidencePanel makeKeyAndOrderFront:nil];
}

- (void)showEvidenceSummary:(id)sender
{
    (void)sender;

    [self openEvidencePanel];
}

- (NSString *)pathForHelperNamed:(NSString *)helperName
{
    NSFileManager *fileManager;
    NSString *bundleHelperPath;
    NSString *projectHelperPath;

    fileManager = [NSFileManager defaultManager];

    bundleHelperPath = [[[[NSBundle mainBundle] resourcePath]
        stringByAppendingPathComponent:@"Probes"]
        stringByAppendingPathComponent:helperName];

    if ([fileManager isExecutableFileAtPath:bundleHelperPath]) {
        return bundleHelperPath;
    }

    projectHelperPath = [[[self applicationProjectPath]
        stringByAppendingPathComponent:@"Probe/build"]
        stringByAppendingPathComponent:helperName];

    if ([fileManager isExecutableFileAtPath:projectHelperPath]) {
        return projectHelperPath;
    }

    return nil;
}

- (BOOL)runHelperNamed:(NSString *)helperName output:(NSString **)outputText
{
    NSString *helperPath;
    NSTask *task;
    NSPipe *pipe;
    NSData *data;
    NSString *output;
    int status;

    if (outputText != NULL) {
        *outputText = nil;
    }

    helperPath = [self pathForHelperNamed:helperName];

    if (helperPath == nil) {
        if (outputText != NULL) {
            *outputText = [NSString stringWithFormat:LCString(@"Operation.HelperMissingFormat"), helperName];
        }

        return NO;
    }

    task = [[NSTask alloc] init];
    pipe = [NSPipe pipe];

    [task setLaunchPath:helperPath];
    [task setCurrentDirectoryPath:[self applicationProjectPath]];
    [task setStandardOutput:pipe];
    [task setStandardError:pipe];

    @try {
        [task launch];
        data = [[pipe fileHandleForReading] readDataToEndOfFile];
        [task waitUntilExit];
        status = [task terminationStatus];
    }
    @catch (NSException *exception) {
        if (outputText != NULL) {
            *outputText = [NSString stringWithFormat:@"%@: %@", helperName, [exception reason]];
        }

        [task release];

        return NO;
    }

    output = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];

    if (outputText != NULL) {
        if (output != nil && [output length] > 0) {
            *outputText = output;
        } else {
            *outputText = [NSString stringWithFormat:@"%@: exit status %d", helperName, status];
        }
    }

    [task release];

    return status == 0;
}

- (void)appendOperationLogLine:(NSString *)line
{
    [_operationPanel appendLogLine:line];
}

- (void)setOperationStatusText:(NSString *)status
{
    [_operationPanel setStatusText:status];
}

- (void)finishUpdateSnapshotOperation:(NSDictionary *)result
{
    NSString *status;

    status = [result objectForKey:@"status"];

    [self reloadData:nil];
    [self reloadSnapshotRows];

    [self setStatusString:status];
    [_operationPanel completeOperationWithStatus:status];

    _snapshotUpdateRunning = NO;
}

- (void)runUpdateSnapshotOperation:(id)sender
{
    NSAutoreleasePool *pool;
    NSArray *stages;
    NSEnumerator *enumerator;
    NSDictionary *stage;
    NSUInteger warningCount;
    BOOL stopPipeline;
    NSString *finalStatus;

    (void)sender;

    pool = [[NSAutoreleasePool alloc] init];

    stages = [NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"leocol_journal_probe", @"helper",
            LCString(@"Operation.Stage.JournalProbe"), @"title",
            [NSNumber numberWithBool:YES], @"required",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"leocol_lifecycle_probe", @"helper",
            LCString(@"Operation.Stage.LifecycleProbe"), @"title",
            [NSNumber numberWithBool:YES], @"required",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"leocol_identity_probe", @"helper",
            LCString(@"Operation.Stage.IdentityProbe"), @"title",
            [NSNumber numberWithBool:NO], @"required",
            nil],
        nil];

    warningCount = 0;
    stopPipeline = NO;

    enumerator = [stages objectEnumerator];

    while (!stopPipeline && (stage = [enumerator nextObject]) != nil) {
        NSString *helperName;
        NSString *stageTitle;
        NSString *output;
        BOOL required;
        BOOL success;

        helperName = [stage objectForKey:@"helper"];
        stageTitle = [stage objectForKey:@"title"];
        required = [[stage objectForKey:@"required"] boolValue];

        [self performSelectorOnMainThread:@selector(setOperationStatusText:)
                               withObject:stageTitle
                            waitUntilDone:YES];

        [self performSelectorOnMainThread:@selector(appendOperationLogLine:)
                               withObject:[NSString stringWithFormat:@"Running: %@", stageTitle]
                            waitUntilDone:YES];

        output = nil;
        success = [self runHelperNamed:helperName output:&output];

        if (success) {
            [self performSelectorOnMainThread:@selector(appendOperationLogLine:)
                                   withObject:[NSString stringWithFormat:@"OK: %@", stageTitle]
                                waitUntilDone:YES];
        } else {
            warningCount++;

            [self performSelectorOnMainThread:@selector(appendOperationLogLine:)
                                   withObject:[NSString stringWithFormat:LCString(@"Operation.HelperFailedFormat"), stageTitle]
                                waitUntilDone:YES];

            if (output != nil && [output length] > 0) {
                [self performSelectorOnMainThread:@selector(appendOperationLogLine:)
                                       withObject:output
                                    waitUntilDone:YES];
            }

            if (required) {
                stopPipeline = YES;
            }
        }
    }

    if (warningCount == 0) {
        finalStatus = LCString(@"Operation.UpdateSnapshot.Completed");
    } else {
        finalStatus = [NSString stringWithFormat:LCString(@"Operation.UpdateSnapshot.WarningFormat"),
            (unsigned long)warningCount];
    }

    [self performSelectorOnMainThread:@selector(finishUpdateSnapshotOperation:)
                           withObject:[NSDictionary dictionaryWithObject:finalStatus forKey:@"status"]
                        waitUntilDone:NO];

    [pool release];
}

- (void)updateSnapshot:(id)sender
{
    (void)sender;

    if (_snapshotUpdateRunning) {
        [_operationPanel showWithTitle:LCString(@"Operation.UpdateSnapshot.Title")
                                status:LCString(@"Operation.UpdateSnapshot.Starting")];
        return;
    }

    _snapshotUpdateRunning = YES;

    [_operationPanel showWithTitle:LCString(@"Operation.UpdateSnapshot.Title")
                            status:LCString(@"Operation.UpdateSnapshot.Starting")];
    [_operationPanel beginOperation];
    [_operationPanel appendLogLine:LCString(@"Operation.UpdateSnapshot.Starting")];

    [NSThread detachNewThreadSelector:@selector(runUpdateSnapshotOperation:)
                             toTarget:self
                           withObject:nil];
}

- (void)finishUpdateEvidenceOperation:(NSDictionary *)result
{
    NSString *status;

    status = [result objectForKey:@"status"];

    [self reloadEvidenceRows];

    [self setStatusString:status];
    [_operationPanel completeOperationWithStatus:status];

    _evidenceUpdateRunning = NO;
}

- (void)runUpdateEvidenceOperation:(id)sender
{
    NSAutoreleasePool *pool;
    NSArray *stages;
    NSEnumerator *enumerator;
    NSDictionary *stage;
    NSUInteger warningCount;
    NSString *finalStatus;

    (void)sender;

    pool = [[NSAutoreleasePool alloc] init];

    stages = [NSArray arrayWithObjects:
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"leocol_launch_sources_probe", @"helper",
            LCString(@"Operation.Stage.LaunchSourcesProbe"), @"title",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"leocol_login_items_probe", @"helper",
            LCString(@"Operation.Stage.LoginItemsProbe"), @"title",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"leocol_startup_items_probe", @"helper",
            LCString(@"Operation.Stage.StartupItemsProbe"), @"title",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"leocol_kext_probe", @"helper",
            LCString(@"Operation.Stage.KextProbe"), @"title",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"leocol_cups_probe", @"helper",
            LCString(@"Operation.Stage.CUPSProbe"), @"title",
            nil],
        [NSDictionary dictionaryWithObjectsAndKeys:
            @"leocol_receipt_bom_probe", @"helper",
            LCString(@"Operation.Stage.ReceiptBOMProbe"), @"title",
            nil],
        nil];

    warningCount = 0;
    enumerator = [stages objectEnumerator];

    while ((stage = [enumerator nextObject]) != nil) {
        NSString *helperName;
        NSString *stageTitle;
        NSString *output;
        BOOL success;

        helperName = [stage objectForKey:@"helper"];
        stageTitle = [stage objectForKey:@"title"];

        [self performSelectorOnMainThread:@selector(setOperationStatusText:)
                               withObject:stageTitle
                            waitUntilDone:YES];

        [self performSelectorOnMainThread:@selector(appendOperationLogLine:)
                               withObject:[NSString stringWithFormat:@"Running: %@", stageTitle]
                            waitUntilDone:YES];

        output = nil;
        success = [self runHelperNamed:helperName output:&output];

        if (success) {
            [self performSelectorOnMainThread:@selector(appendOperationLogLine:)
                                   withObject:[NSString stringWithFormat:@"OK: %@", stageTitle]
                                waitUntilDone:YES];
        } else {
            warningCount++;

            [self performSelectorOnMainThread:@selector(appendOperationLogLine:)
                                   withObject:[NSString stringWithFormat:LCString(@"Operation.HelperFailedFormat"), stageTitle]
                                waitUntilDone:YES];

            if (output != nil && [output length] > 0) {
                [self performSelectorOnMainThread:@selector(appendOperationLogLine:)
                                       withObject:output
                                    waitUntilDone:YES];
            }
        }
    }

    if (warningCount == 0) {
        finalStatus = LCString(@"Operation.UpdateEvidence.Completed");
    } else {
        finalStatus = [NSString stringWithFormat:LCString(@"Operation.UpdateEvidence.WarningFormat"),
            (unsigned long)warningCount];
    }

    [self performSelectorOnMainThread:@selector(finishUpdateEvidenceOperation:)
                           withObject:[NSDictionary dictionaryWithObject:finalStatus forKey:@"status"]
                        waitUntilDone:NO];

    [pool release];
}

- (void)updateEvidence:(id)sender
{
    (void)sender;

    if (_evidenceUpdateRunning) {
        [_operationPanel showWithTitle:LCString(@"Operation.UpdateEvidence.Title")
                                status:LCString(@"Operation.UpdateEvidence.Starting")];
        return;
    }

    _evidenceUpdateRunning = YES;

    [_operationPanel showWithTitle:LCString(@"Operation.UpdateEvidence.Title")
                            status:LCString(@"Operation.UpdateEvidence.Starting")];
    [_operationPanel beginOperation];
    [_operationPanel appendLogLine:LCString(@"Operation.UpdateEvidence.Starting")];

    [NSThread detachNewThreadSelector:@selector(runUpdateEvidenceOperation:)
                             toTarget:self
                           withObject:nil];
}

- (NSString *)exportTimestampString
{
    NSDateFormatter *formatter;
    NSString *result;

    formatter = [[[NSDateFormatter alloc] init] autorelease];

    [formatter setFormatterBehavior:NSDateFormatterBehavior10_4];
    [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];

    result = [formatter stringFromDate:[NSDate date]];

    return result != nil ? result : @"-";
}

- (NSString *)applicationProjectPath
{
    return [LCStoreSupport projectPath];
}

- (NSString *)applicationDatabasePath
{
    return [LCStoreSupport databasePath];
}

- (void)appendReportLineWithLabel:(NSString *)label
                            value:(NSString *)value
                         toString:(NSMutableString *)report
{
    [report appendFormat:@"%@: %@\n", label, value != nil ? value : @"-"];
}

- (void)appendReportSectionTitle:(NSString *)title
                        toString:(NSMutableString *)report
{
    NSUInteger i;

    [report appendString:@"\n"];
    [report appendString:title];
    [report appendString:@"\n"];

    for (i = 0; i < [title length]; i++) {
        [report appendString:@"-"];
    }

    [report appendString:@"\n"];
}

- (NSString *)exportReportText
{
    NSMutableString *report;
    NSDictionary *infoDictionary;
    NSString *shortVersion;
    NSString *buildVersion;
    NSString *searchText;
    NSString *visibleRowsText;
    NSEnumerator *enumerator;
    NSDictionary *row;
    NSArray *evidenceRows;
    NSString *statusString;

    report = [NSMutableString string];

    infoDictionary = [[NSBundle mainBundle] infoDictionary];
    shortVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    buildVersion = [infoDictionary objectForKey:@"CFBundleVersion"];

    [report appendString:LCString(@"Report.Title")];
    [report appendString:@"\n"];

    {
        NSUInteger i;

        for (i = 0; i < [LCString(@"Report.Title") length]; i++) {
            [report appendString:@"="];
        }
    }

    [report appendString:@"\n\n"];

    [self appendReportLineWithLabel:LCString(@"Report.Label.Version")
                              value:[NSString stringWithFormat:@"%@ (%@)",
                                  shortVersion != nil ? shortVersion : @"-",
                                  buildVersion != nil ? buildVersion : @"-"]
                           toString:report];

    [self appendReportLineWithLabel:LCString(@"Report.Label.Exported")
                              value:[self exportTimestampString]
                           toString:report];

    [self appendReportLineWithLabel:LCString(@"Report.Label.Database")
                              value:[self applicationDatabasePath]
                           toString:report];

    searchText = (_filterField != nil) ? [_filterField stringValue] : @"";

    [self appendReportLineWithLabel:LCString(@"Report.Label.Search")
                              value:([searchText length] > 0 ? searchText : LCString(@"Report.NoActiveSearch"))
                           toString:report];

    visibleRowsText = [NSString stringWithFormat:LCString(@"Report.VisibleRowsFormat"),
        (unsigned long)[_visibleRows count],
        (unsigned long)[_rows count]];

    [self appendReportLineWithLabel:LCString(@"Report.Label.VisibleRows")
                              value:visibleRowsText
                           toString:report];

    [self appendReportSectionTitle:LCString(@"Report.Section.Processes")
                          toString:report];

    [report appendString:LCString(@"Report.ProcessHeader")];
    [report appendString:@"\n"];

    enumerator = [_visibleRows objectEnumerator];

    while ((row = [enumerator nextObject]) != nil) {
        [report appendFormat:@"%@\t%@\t%@\t%@\t%@\t%@\t%@\n",
            [self displayStringForRow:row key:@"name"],
            [self displayStringForRow:row key:@"pid"],
            [self displayStringForRow:row key:@"instanceStatus"],
            [self displayStringForRow:row key:@"bundleName"],
            LCDisplayCompactTimestampString([self displayStringForRow:row key:@"lastSeen"]),
            [self displayStringForRow:row key:@"executable"],
            [self displayStringForRow:row key:@"kind"]];
    }

    [self appendReportSectionTitle:LCString(@"Report.Section.Provenance")
                          toString:report];

    [report appendString:LCString(@"Report.EvidenceHeader")];
    [report appendString:@"\n"];

    statusString = nil;
    evidenceRows = [LCProvenanceStore loadEvidenceSummaryRowsWithStatusString:&statusString];

    if ([evidenceRows count] == 0) {
        [report appendFormat:@"%@\n", statusString != nil ? statusString : LCString(@"EvidenceSummary.Empty")];
    } else {
        enumerator = [evidenceRows objectEnumerator];

        while ((row = [enumerator nextObject]) != nil) {
            NSString *evidenceType;
            NSString *resolutionState;
            NSNumber *count;

            evidenceType = LCPresentationStringForValue([row objectForKey:@"evidenceType"],
                                                        @"evidenceType",
                                                        NO);
            resolutionState = LCPresentationStringForValue([row objectForKey:@"resolutionState"],
                                                           @"resolutionState",
                                                           NO);
            count = [row objectForKey:@"count"];

            [report appendFormat:@"%@\t%@\t%@\n",
                evidenceType,
                resolutionState,
                count != nil ? count : [NSNumber numberWithInt:0]];
        }
    }

    [self appendReportSectionTitle:LCString(@"Report.Section.Boundary")
                          toString:report];

    [report appendString:LCString(@"Report.Boundary.Evidence")];
    [report appendString:@"\n"];
    [report appendString:LCString(@"Report.Boundary.ReadOnly")];
    [report appendString:@"\n"];

    return report;
}

- (void)showExportFailureAlert
{
    NSAlert *alert;

    alert = [[[NSAlert alloc] init] autorelease];

    [alert setMessageText:LCString(@"Export.FailedTitle")];
    [alert setInformativeText:LCString(@"Export.FailedInfo")];
    [alert addButtonWithTitle:LCString(@"Button.OK")];

    [alert runModal];
}

- (void)exportReport:(id)sender
{
    NSSavePanel *savePanel;
    int result;
    NSString *path;
    NSString *report;
    NSError *error;
    BOOL success;

    (void)sender;

    savePanel = [NSSavePanel savePanel];

    [savePanel setCanCreateDirectories:YES];
    [savePanel setRequiredFileType:@"txt"];

    result = [savePanel runModalForDirectory:NSHomeDirectory()
                                        file:LCString(@"Export.DefaultFileName")];

    if (result != NSOKButton) {
        return;
    }

    path = [savePanel filename];
    report = [self exportReportText];

    error = nil;
    success = [report writeToFile:path
                       atomically:YES
                         encoding:NSUTF8StringEncoding
                            error:&error];

    if (!success) {
        [self showExportFailureAlert];
    }
}

- (void)reloadSnapshotRows
{
    NSString *statusString;
    NSArray *rows;

    statusString = nil;
    rows = [LCSnapshotStore loadSnapshotSummaryRowsWithStatusString:&statusString];

    [_snapshotRows removeAllObjects];

    if ([rows count] > 0) {
        [_snapshotRows addObjectsFromArray:rows];
    }

    if (_snapshotTableView != nil) {
        [_snapshotTableView reloadData];
    }
}

- (void)openSnapshotPanel
{
    NSScrollView *scrollView;
    NSTableColumn *snapshotIDColumn;
    NSTableColumn *observedAtColumn;
    NSTableColumn *sourceColumn;
    NSTableColumn *processCountColumn;

    if (_snapshotPanel != nil) {
        [self reloadSnapshotRows];
        [_snapshotPanel makeKeyAndOrderFront:nil];
        return;
    }

    _snapshotPanel = [[NSPanel alloc] initWithContentRect:NSMakeRect(220, 220, 600, 260)
                                                styleMask:(NSTitledWindowMask |
                                                           NSClosableWindowMask |
                                                           NSUtilityWindowMask)
                                                  backing:NSBackingStoreBuffered
                                                    defer:NO];

    [_snapshotPanel setTitle:LCString(@"SnapshotOverview.Title")];
    [_snapshotPanel setReleasedWhenClosed:NO];

    scrollView = [[[NSScrollView alloc] initWithFrame:[[_snapshotPanel contentView] bounds]] autorelease];
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setAutohidesScrollers:YES];
    [scrollView setBorderType:NSBezelBorder];

    _snapshotTableView = [[[NSTableView alloc] initWithFrame:[scrollView bounds]] autorelease];
    [_snapshotTableView setDelegate:(id)self];
    [_snapshotTableView setDataSource:(id)self];
    [_snapshotTableView setUsesAlternatingRowBackgroundColors:YES];

    snapshotIDColumn = [[[NSTableColumn alloc] initWithIdentifier:@"snapshotID"] autorelease];
    [[snapshotIDColumn headerCell] setStringValue:LCString(@"Column.SnapshotID")];
    [snapshotIDColumn setWidth:90.0];
    [_snapshotTableView addTableColumn:snapshotIDColumn];

    observedAtColumn = [[[NSTableColumn alloc] initWithIdentifier:@"observedAt"] autorelease];
    [[observedAtColumn headerCell] setStringValue:LCString(@"Column.ObservedAt")];
    [observedAtColumn setWidth:190.0];
    [_snapshotTableView addTableColumn:observedAtColumn];

    sourceColumn = [[[NSTableColumn alloc] initWithIdentifier:@"source"] autorelease];
    [[sourceColumn headerCell] setStringValue:LCString(@"Column.Source")];
    [sourceColumn setWidth:160.0];
    [_snapshotTableView addTableColumn:sourceColumn];

    processCountColumn = [[[NSTableColumn alloc] initWithIdentifier:@"processCount"] autorelease];
    [[processCountColumn headerCell] setStringValue:LCString(@"Column.ProcessCount")];
    [processCountColumn setWidth:110.0];
    [_snapshotTableView addTableColumn:processCountColumn];

    [scrollView setDocumentView:_snapshotTableView];
    [[_snapshotPanel contentView] addSubview:scrollView];

    [self reloadSnapshotRows];

    [_snapshotPanel makeKeyAndOrderFront:nil];
}

- (void)showSnapshotOverview:(id)sender
{
    (void)sender;

    [self openSnapshotPanel];
}

- (NSString *)helpIndexPath
{
    NSFileManager *fileManager;
    NSString *resourcePath;
    NSString *projectHelpRootPath;
    NSMutableArray *localizationNames;
    NSArray *preferredLocalizations;
    NSEnumerator *localizationEnumerator;
    NSString *localizationName;
    NSString *mappedName;
    NSString *candidatePath;
    NSString *relativePath;

    fileManager = [NSFileManager defaultManager];
    resourcePath = [[NSBundle mainBundle] resourcePath];

    localizationNames = [NSMutableArray array];
    preferredLocalizations = [[NSBundle mainBundle] preferredLocalizations];

    localizationEnumerator = [preferredLocalizations objectEnumerator];

    while ((localizationName = [localizationEnumerator nextObject]) != nil) {
        if (![localizationNames containsObject:localizationName]) {
            [localizationNames addObject:localizationName];
        }

        mappedName = nil;

        if ([localizationName hasPrefix:@"de"]) {
            mappedName = @"German";
        } else if ([localizationName hasPrefix:@"en"]) {
            mappedName = @"English";
        }

        if (mappedName != nil && ![localizationNames containsObject:mappedName]) {
            [localizationNames addObject:mappedName];
        }
    }

    if (![localizationNames containsObject:@"German"]) {
        [localizationNames addObject:@"German"];
    }

    if (![localizationNames containsObject:@"English"]) {
        [localizationNames addObject:@"English"];
    }

    localizationEnumerator = [localizationNames objectEnumerator];

    while ((localizationName = [localizationEnumerator nextObject]) != nil) {
        relativePath = [NSString stringWithFormat:@"%@.lproj/LeoCol Help/index.html",
            localizationName];
        candidatePath = [resourcePath stringByAppendingPathComponent:relativePath];

        if ([fileManager fileExistsAtPath:candidatePath]) {
            return candidatePath;
        }
    }

    candidatePath = [resourcePath stringByAppendingPathComponent:@"LeoCol Help/index.html"];

    if ([fileManager fileExistsAtPath:candidatePath]) {
        return candidatePath;
    }

    projectHelpRootPath = [[LCStoreSupport projectPath]
        stringByAppendingPathComponent:@"App/Help"];

    localizationEnumerator = [localizationNames objectEnumerator];

    while ((localizationName = [localizationEnumerator nextObject]) != nil) {
        relativePath = [NSString stringWithFormat:@"%@.lproj/LeoCol Help/index.html",
            localizationName];
        candidatePath = [projectHelpRootPath stringByAppendingPathComponent:relativePath];

        if ([fileManager fileExistsAtPath:candidatePath]) {
            return candidatePath;
        }
    }

    candidatePath = [projectHelpRootPath stringByAppendingPathComponent:@"LeoCol Help/index.html"];

    if ([fileManager fileExistsAtPath:candidatePath]) {
        return candidatePath;
    }

    return nil;
}

- (void)openLeoColHelp:(id)sender
{
    NSString *path;
    NSURL *url;
    NSURLRequest *request;
    NSView *contentView;
    WebView *webView;

    (void)sender;

    path = [self helpIndexPath];

    if (path == nil) {
        NSBeep();
        [self setStatusString:LCString(@"Status.HelpNotFound")];
        return;
    }

    if (_helpWindow == nil) {
        _helpWindow = [[NSWindow alloc] initWithContentRect:NSMakeRect(180, 140, 820, 620)
                                                  styleMask:(NSTitledWindowMask |
                                                             NSClosableWindowMask |
                                                             NSMiniaturizableWindowMask |
                                                             NSResizableWindowMask)
                                                    backing:NSBackingStoreBuffered
                                                      defer:NO];

        [_helpWindow setReleasedWhenClosed:NO];
        [_helpWindow setTitle:LCString(@"Window.HelpTitle")];

        contentView = [_helpWindow contentView];

        webView = [[[WebView alloc] initWithFrame:[contentView bounds]] autorelease];
        [webView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];

        [contentView addSubview:webView];
        _helpWebView = [webView retain];
    }

    url = [NSURL fileURLWithPath:path];
    request = [NSURLRequest requestWithURL:url];

    [[_helpWebView mainFrame] loadRequest:request];

    [_helpWindow makeKeyAndOrderFront:nil];
    [self setStatusString:LCString(@"Status.HelpOpenedFromFile")];
}

- (void)showAboutPanel:(id)sender
{
    NSAlert *alert;
    NSDictionary *infoDictionary;
    NSString *shortVersion;
    NSString *buildVersion;
    NSString *versionLine;
    NSString *informativeText;

    (void)sender;

    infoDictionary = [[NSBundle mainBundle] infoDictionary];
    shortVersion = [infoDictionary objectForKey:@"CFBundleShortVersionString"];
    buildVersion = [infoDictionary objectForKey:@"CFBundleVersion"];

    if (shortVersion == nil || [shortVersion length] == 0) {
        shortVersion = @"-";
    }

    if (buildVersion == nil || [buildVersion length] == 0) {
        buildVersion = @"-";
    }

    versionLine = [NSString stringWithFormat:LCString(@"About.VersionFormat"),
        shortVersion,
        buildVersion];

    informativeText = [NSString stringWithFormat:@"%@\n\n%@",
        versionLine,
        LCString(@"About.Info")];

    alert = [[[NSAlert alloc] init] autorelease];

    [alert setMessageText:LCString(@"About.Message")];
    [alert setInformativeText:informativeText];
    [alert addButtonWithTitle:LCString(@"Button.OK")];

    [alert runModal];
}

- (void)installApplicationMenu
{
    NSMenu *mainMenu;

    NSMenuItem *applicationMenuItem;
    NSMenu *applicationMenu;
    NSMenuItem *aboutItem;
    NSMenuItem *hideItem;
    NSMenuItem *hideOthersItem;
    NSMenuItem *showAllItem;
    NSMenuItem *quitItem;

    NSMenuItem *fileMenuItem;
    NSMenu *fileMenu;
    NSMenuItem *updateSnapshotItem;
    NSMenuItem *updateEvidenceItem;
    NSMenuItem *exportItem;
    NSMenuItem *closeItem;

    NSMenuItem *editMenuItem;
    NSMenu *editMenu;
    NSMenuItem *copyItem;
    NSMenuItem *selectAllItem;

    NSMenuItem *viewMenuItem;
    NSMenu *viewMenu;
    NSMenuItem *toolbarItem;
    NSMenuItem *snapshotItem;
    NSMenuItem *evidenceItem;

    NSMenuItem *windowMenuItem;
    NSMenu *windowMenu;
    NSMenuItem *minimizeItem;
    NSMenuItem *zoomItem;
    NSMenuItem *bringAllToFrontItem;

    NSMenuItem *helpMenuItem;
    NSMenu *helpMenu;
    NSMenuItem *leoColHelpItem;

    mainMenu = [[[NSMenu alloc] initWithTitle:@""] autorelease];

    /*
     * Application menu.
     */
    applicationMenuItem = [[[NSMenuItem alloc] initWithTitle:@""
                                                      action:NULL
                                               keyEquivalent:@""] autorelease];
    [mainMenu addItem:applicationMenuItem];

    applicationMenu = [[[NSMenu alloc] initWithTitle:@"LeoCol"] autorelease];

    aboutItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"About.Title")
                                            action:@selector(showAboutPanel:)
                                     keyEquivalent:@""] autorelease];
    [aboutItem setTarget:self];
    [applicationMenu addItem:aboutItem];

    [applicationMenu addItem:[NSMenuItem separatorItem]];

    hideItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.HideLeoCol")
                                           action:@selector(hide:)
                                    keyEquivalent:@"h"] autorelease];
    [applicationMenu addItem:hideItem];

    hideOthersItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.HideOthers")
                                                 action:@selector(hideOtherApplications:)
                                          keyEquivalent:@"h"] autorelease];
    [hideOthersItem setKeyEquivalentModifierMask:(NSCommandKeyMask | NSAlternateKeyMask)];
    [applicationMenu addItem:hideOthersItem];

    showAllItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.ShowAll")
                                              action:@selector(unhideAllApplications:)
                                       keyEquivalent:@""] autorelease];
    [applicationMenu addItem:showAllItem];

    [applicationMenu addItem:[NSMenuItem separatorItem]];

    quitItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.QuitLeoCol")
                                          action:@selector(terminate:)
                                   keyEquivalent:@"q"] autorelease];
    [applicationMenu addItem:quitItem];

    [applicationMenuItem setSubmenu:applicationMenu];

    /*
     * File menu.
     */
    fileMenuItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.File")
                                               action:NULL
                                        keyEquivalent:@""] autorelease];
    [mainMenu addItem:fileMenuItem];

    fileMenu = [[[NSMenu alloc] initWithTitle:LCString(@"Menu.File")] autorelease];

    updateSnapshotItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.UpdateSnapshot")
                                                     action:@selector(updateSnapshot:)
                                              keyEquivalent:@"r"] autorelease];
    [updateSnapshotItem setTarget:self];
    [fileMenu addItem:updateSnapshotItem];

    updateEvidenceItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.UpdateEvidence")
                                                     action:@selector(updateEvidence:)
                                              keyEquivalent:@""] autorelease];
    [updateEvidenceItem setTarget:self];
    [fileMenu addItem:updateEvidenceItem];

    [fileMenu addItem:[NSMenuItem separatorItem]];

    exportItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.ExportReport")
                                             action:@selector(exportReport:)
                                      keyEquivalent:@"e"] autorelease];
    [exportItem setTarget:self];
    [fileMenu addItem:exportItem];

    [fileMenu addItem:[NSMenuItem separatorItem]];

    closeItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.Close")
                                            action:@selector(performClose:)
                                     keyEquivalent:@"w"] autorelease];
    [fileMenu addItem:closeItem];

    [fileMenuItem setSubmenu:fileMenu];

    /*
     * Edit menu.
     */
    editMenuItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.Edit")
                                               action:NULL
                                        keyEquivalent:@""] autorelease];
    [mainMenu addItem:editMenuItem];

    editMenu = [[[NSMenu alloc] initWithTitle:LCString(@"Menu.Edit")] autorelease];

    copyItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.Copy")
                                           action:@selector(copy:)
                                    keyEquivalent:@"c"] autorelease];
    [editMenu addItem:copyItem];

    selectAllItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.SelectAll")
                                                action:@selector(selectAll:)
                                         keyEquivalent:@"a"] autorelease];
    [editMenu addItem:selectAllItem];

    [editMenuItem setSubmenu:editMenu];

    /*
     * View menu.
     */
    viewMenuItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.View")
                                               action:NULL
                                        keyEquivalent:@""] autorelease];
    [mainMenu addItem:viewMenuItem];

    viewMenu = [[[NSMenu alloc] initWithTitle:LCString(@"Menu.View")] autorelease];

    toolbarItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.ShowToolbar")
                                              action:@selector(toggleToolbarShown:)
                                       keyEquivalent:@""] autorelease];
    [viewMenu addItem:toolbarItem];

    [viewMenu addItem:[NSMenuItem separatorItem]];

    snapshotItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.ShowSnapshots")
                                               action:@selector(showSnapshotOverview:)
                                        keyEquivalent:@""] autorelease];
    [snapshotItem setTarget:self];
    [viewMenu addItem:snapshotItem];

    evidenceItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.ShowEvidenceSummary")
                                               action:@selector(showEvidenceSummary:)
                                        keyEquivalent:@""] autorelease];
    [evidenceItem setTarget:self];
    [viewMenu addItem:evidenceItem];

    [viewMenuItem setSubmenu:viewMenu];

    /*
     * Window menu.
     */
    windowMenuItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.Window")
                                                 action:NULL
                                          keyEquivalent:@""] autorelease];
    [mainMenu addItem:windowMenuItem];

    windowMenu = [[[NSMenu alloc] initWithTitle:LCString(@"Menu.Window")] autorelease];

    minimizeItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.Minimize")
                                               action:@selector(performMiniaturize:)
                                        keyEquivalent:@"m"] autorelease];
    [windowMenu addItem:minimizeItem];

    zoomItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.Zoom")
                                           action:@selector(performZoom:)
                                    keyEquivalent:@""] autorelease];
    [windowMenu addItem:zoomItem];

    [windowMenu addItem:[NSMenuItem separatorItem]];

    bringAllToFrontItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.BringAllToFront")
                                                      action:@selector(arrangeInFront:)
                                               keyEquivalent:@""] autorelease];
    [windowMenu addItem:bringAllToFrontItem];

    [windowMenuItem setSubmenu:windowMenu];

    /*
     * Help menu.
     */
    helpMenuItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.Help")
                                               action:NULL
                                        keyEquivalent:@""] autorelease];
    [mainMenu addItem:helpMenuItem];

    helpMenu = [[[NSMenu alloc] initWithTitle:LCString(@"Menu.Help")] autorelease];

    leoColHelpItem = [[[NSMenuItem alloc] initWithTitle:LCString(@"Menu.LeoColHelp")
                                                 action:@selector(openLeoColHelp:)
                                          keyEquivalent:@""] autorelease];
    [leoColHelpItem setTarget:self];
    [helpMenu addItem:leoColHelpItem];

    [helpMenuItem setSubmenu:helpMenu];

    [NSApp setMainMenu:mainMenu];
    [NSApp setWindowsMenu:windowMenu];
}

- (NSButton *)toolbarButtonWithTitle:(NSString *)title
                                action:(SEL)action
                                 width:(CGFloat)width
{
    NSButton *button;

    button = [[[NSButton alloc] initWithFrame:NSMakeRect(0, 0, width, 28)] autorelease];

    [button setTitle:title];
    [button setButtonType:NSMomentaryPushInButton];
    [button setBezelStyle:NSRoundedBezelStyle];
    [button setTarget:self];
    [button setAction:action];

    return button;
}

- (void)installToolbar
{
    NSToolbar *toolbar;

    toolbar = [[[NSToolbar alloc] initWithIdentifier:LeoColToolbarIdentifier] autorelease];

    [toolbar setDelegate:(id)self];
    [toolbar setAllowsUserCustomization:NO];
    [toolbar setAutosavesConfiguration:NO];
    [toolbar setDisplayMode:NSToolbarDisplayModeIconAndLabel];

    [_window setToolbar:toolbar];
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *)toolbar
{
    (void)toolbar;

    return [NSArray arrayWithObjects:
        LeoColToolbarReloadItemIdentifier,
        LeoColToolbarEvidenceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        NSToolbarSpaceItemIdentifier,
        LeoColToolbarSearchItemIdentifier,
        nil];
}

- (NSArray *)toolbarDefaultItemIdentifiers:(NSToolbar *)toolbar
{
    (void)toolbar;

    return [NSArray arrayWithObjects:
        LeoColToolbarReloadItemIdentifier,
        LeoColToolbarEvidenceItemIdentifier,
        NSToolbarFlexibleSpaceItemIdentifier,
        LeoColToolbarSearchItemIdentifier,
        nil];
}

- (NSToolbarItem *)toolbar:(NSToolbar *)toolbar
    itemForItemIdentifier:(NSString *)itemIdentifier
willBeInsertedIntoToolbar:(BOOL)flag
{
    NSToolbarItem *item;

    (void)toolbar;
    (void)flag;

    item = [[[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier] autorelease];

    if ([itemIdentifier isEqualToString:LeoColToolbarReloadItemIdentifier]) {
        NSButton *button;

        button = [self toolbarButtonWithTitle:LCString(@"Button.Reload")
                                       action:@selector(reloadData:)
                                        width:90.0];

        [item setLabel:LCString(@"Button.Reload")];
        [item setPaletteLabel:LCString(@"Button.Reload")];
        [item setToolTip:LCString(@"Button.Reload")];
        [item setView:button];
        [item setMinSize:NSMakeSize(90.0, 28.0)];
        [item setMaxSize:NSMakeSize(90.0, 28.0)];

        return item;
    }

    if ([itemIdentifier isEqualToString:LeoColToolbarEvidenceItemIdentifier]) {
        NSButton *button;

        button = [self toolbarButtonWithTitle:LCString(@"Button.EvidenceSummary")
                                       action:@selector(showEvidenceSummary:)
                                        width:96.0];

        [item setLabel:LCString(@"Button.EvidenceSummary")];
        [item setPaletteLabel:LCString(@"Button.EvidenceSummary")];
        [item setToolTip:LCString(@"Button.EvidenceSummary")];
        [item setView:button];
        [item setMinSize:NSMakeSize(96.0, 28.0)];
        [item setMaxSize:NSMakeSize(96.0, 28.0)];

        return item;
    }

    if ([itemIdentifier isEqualToString:LeoColToolbarSearchItemIdentifier]) {
        _filterField = [[[NSSearchField alloc] initWithFrame:NSMakeRect(0, 0, 240, 22)] autorelease];

        [[_filterField cell] setPlaceholderString:LCString(@"Label.Search")];
        [_filterField setTarget:self];
        [_filterField setAction:@selector(filterChanged:)];
        [_filterField setDelegate:(id)self];

        [item setLabel:LCString(@"Label.Search")];
        [item setPaletteLabel:LCString(@"Label.Search")];
        [item setToolTip:LCString(@"Label.Search")];
        [item setView:_filterField];
        [item setMinSize:NSMakeSize(180.0, 22.0)];
        [item setMaxSize:NSMakeSize(260.0, 22.0)];

        return item;
    }

    return nil;
}

- (void)applicationDidFinishLaunching:(NSNotification *)notification
{
    NSView *contentView;
    NSRect contentBounds;
      NSScrollView *scrollView;
    NSTextField *detailLabel;
    NSScrollView *detailScrollView;
    NSTableColumn *nameColumn;
    NSTableColumn *pidColumn;
    NSTableColumn *instanceStatusColumn;
    NSTableColumn *bundleNameColumn;
    NSTableColumn *observedColumn;
    NSTableColumn *executableColumn;
    NSTableColumn *kindColumn;

    (void)notification;

    [self installApplicationMenu];

    _rows = [[NSMutableArray alloc] init];
    _visibleRows = [[NSMutableArray alloc] init];
    _evidenceRows = [[NSMutableArray alloc] init];
    _snapshotRows = [[NSMutableArray alloc] init];
    _operationPanel = [[LCOperationPanel alloc] init];
    _snapshotUpdateRunning = NO;
    _evidenceUpdateRunning = NO;

    _window = [[NSWindow alloc] initWithContentRect:NSMakeRect(120, 120, 980, 720)
                                         styleMask:(NSTitledWindowMask |
                                                    NSClosableWindowMask |
                                                    NSMiniaturizableWindowMask |
                                                    NSResizableWindowMask)
                                           backing:NSBackingStoreBuffered
                                             defer:NO];

    [_window setTitle:@"LeoCol"];
    [self installToolbar];

    contentView = [_window contentView];
    contentBounds = [contentView bounds];

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
                                                                 contentBounds.size.height - 282)] autorelease];
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setBorderType:NSBezelBorder];

    _tableView = [[[NSTableView alloc] initWithFrame:[scrollView bounds]] autorelease];
    [_tableView setDelegate:(id)self];
    [_tableView setDataSource:(id)self];
    [_tableView setUsesAlternatingRowBackgroundColors:YES];

    nameColumn = [[[NSTableColumn alloc] initWithIdentifier:@"name"] autorelease];
    [[nameColumn headerCell] setStringValue:LCString(@"Column.Process")];
    [nameColumn setWidth:180.0];
    [_tableView addTableColumn:nameColumn];

    pidColumn = [[[NSTableColumn alloc] initWithIdentifier:@"pid"] autorelease];
    [[pidColumn headerCell] setStringValue:LCString(@"Column.PID")];
    [pidColumn setWidth:55.0];
    [_tableView addTableColumn:pidColumn];

    instanceStatusColumn = [[[NSTableColumn alloc] initWithIdentifier:@"instanceStatus"] autorelease];
    [[instanceStatusColumn headerCell] setStringValue:LCString(@"Column.InstanceStatus")];
    [instanceStatusColumn setWidth:80.0];
    [_tableView addTableColumn:instanceStatusColumn];

    bundleNameColumn = [[[NSTableColumn alloc] initWithIdentifier:@"bundleName"] autorelease];
    [[bundleNameColumn headerCell] setStringValue:LCString(@"Column.BundleName")];
    [bundleNameColumn setWidth:160.0];
    [_tableView addTableColumn:bundleNameColumn];

    observedColumn = [[[NSTableColumn alloc] initWithIdentifier:@"observed"] autorelease];
    [[observedColumn headerCell] setStringValue:LCString(@"Column.Observed")];
    [observedColumn setWidth:110.0];
    [_tableView addTableColumn:observedColumn];

    executableColumn = [[[NSTableColumn alloc] initWithIdentifier:@"executable"] autorelease];
    [[executableColumn headerCell] setStringValue:LCString(@"Column.Executable")];
    [executableColumn setWidth:105.0];
    [_tableView addTableColumn:executableColumn];

    kindColumn = [[[NSTableColumn alloc] initWithIdentifier:@"kind"] autorelease];
    [[kindColumn headerCell] setStringValue:LCString(@"Column.Classification")];
    [kindColumn setWidth:200.0];
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
    if ([notification object] == _evidenceTableView ||
        [notification object] == _snapshotTableView) {
        return;
    }

    [self updateDetailView];
}

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    if (tableView == _evidenceTableView) {
        return [_evidenceRows count];
    }

    if (tableView == _snapshotTableView) {
        return [_snapshotRows count];
    }

    return [_visibleRows count];
}

- (id)tableView:(NSTableView *)tableView
objectValueForTableColumn:(NSTableColumn *)tableColumn
            row:(NSInteger)rowIndex
{
    NSDictionary *row;
    NSString *identifier;
    id value;

    identifier = [tableColumn identifier];

    if (tableView == _evidenceTableView) {
        row = [_evidenceRows objectAtIndex:rowIndex];
        value = [row objectForKey:identifier];

        if ([identifier isEqualToString:@"count"]) {
            return value != nil ? value : [NSNumber numberWithInt:0];
        }

        return LCPresentationStringForValue(value, identifier, NO);
    }

    if (tableView == _snapshotTableView) {
        row = [_snapshotRows objectAtIndex:rowIndex];
        value = [row objectForKey:identifier];

        if ([identifier isEqualToString:@"observedAt"]) {
            return LCDisplayCompactTimestampString((value != nil ? [value description] : nil));
        }

        return value != nil ? value : @"-";
    }

    row = [_visibleRows objectAtIndex:rowIndex];
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
    [_operationPanel release];
    [_snapshotRows release];
    [_snapshotPanel release];
    [_helpWebView release];
    [_helpWindow release];
    [_evidenceRows release];
    [_evidencePanel release];
    [_visibleRows release];
    [_rows release];
    [_window release];

    [super dealloc];
}

@end

