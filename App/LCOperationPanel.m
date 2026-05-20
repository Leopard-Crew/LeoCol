#import "LCOperationPanel.h"
#import "LCString.h"

@implementation LCOperationPanel

- (id)init
{
    self = [super init];

    if (self != nil) {
        _panel = nil;
        _statusField = nil;
        _logTextView = nil;
        _progressIndicator = nil;
        _doneButton = nil;
    }

    return self;
}

- (void)ensurePanel
{
    NSView *contentView;
    NSScrollView *scrollView;

    if (_panel != nil) {
        return;
    }

    _panel = [[NSPanel alloc] initWithContentRect:NSMakeRect(240, 240, 520, 300)
                                        styleMask:(NSTitledWindowMask |
                                                   NSClosableWindowMask |
                                                   NSUtilityWindowMask)
                                          backing:NSBackingStoreBuffered
                                            defer:NO];

    [_panel setReleasedWhenClosed:NO];

    contentView = [_panel contentView];

    _statusField = [[NSTextField alloc] initWithFrame:NSMakeRect(20, 252, 480, 20)];
    [_statusField setEditable:NO];
    [_statusField setSelectable:NO];
    [_statusField setBordered:NO];
    [_statusField setDrawsBackground:NO];
    [_statusField setFont:[NSFont systemFontOfSize:12.0]];
    [_statusField setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
    [contentView addSubview:_statusField];

    _progressIndicator = [[NSProgressIndicator alloc] initWithFrame:NSMakeRect(20, 222, 480, 16)];
    [_progressIndicator setStyle:NSProgressIndicatorBarStyle];
    [_progressIndicator setIndeterminate:YES];
    [_progressIndicator setUsesThreadedAnimation:YES];
    [_progressIndicator setAutoresizingMask:(NSViewWidthSizable | NSViewMinYMargin)];
    [contentView addSubview:_progressIndicator];

    scrollView = [[[NSScrollView alloc] initWithFrame:NSMakeRect(20, 54, 480, 156)] autorelease];
    [scrollView setAutoresizingMask:(NSViewWidthSizable | NSViewHeightSizable)];
    [scrollView setHasVerticalScroller:YES];
    [scrollView setHasHorizontalScroller:NO];
    [scrollView setBorderType:NSBezelBorder];

    _logTextView = [[NSTextView alloc] initWithFrame:[scrollView bounds]];
    [_logTextView setEditable:NO];
    [_logTextView setSelectable:YES];
    [_logTextView setFont:[NSFont userFixedPitchFontOfSize:11.0]];
    [_logTextView setString:@""];

    [scrollView setDocumentView:_logTextView];
    [contentView addSubview:scrollView];

    _doneButton = [[NSButton alloc] initWithFrame:NSMakeRect(400, 18, 100, 26)];
    [_doneButton setTitle:LCString(@"Button.OK")];
    [_doneButton setButtonType:NSMomentaryPushInButton];
    [_doneButton setBezelStyle:NSRoundedBezelStyle];
    [_doneButton setTarget:_panel];
    [_doneButton setAction:@selector(orderOut:)];
    [_doneButton setAutoresizingMask:(NSViewMinXMargin | NSViewMaxYMargin)];
    [contentView addSubview:_doneButton];
}

- (void)showWithTitle:(NSString *)title status:(NSString *)status
{
    [self ensurePanel];

    [_panel setTitle:(title != nil ? title : @"LeoCol")];
    [_statusField setStringValue:(status != nil ? status : @"")];
    [_logTextView setString:@""];

    [_doneButton setEnabled:NO];

    [_panel makeKeyAndOrderFront:nil];
}

- (void)beginOperation
{
    [self ensurePanel];

    [_doneButton setEnabled:NO];
    [_progressIndicator startAnimation:nil];
}

- (void)setStatusText:(NSString *)status
{
    [self ensurePanel];

    [_statusField setStringValue:(status != nil ? status : @"")];
    [_panel displayIfNeeded];
}

- (void)appendLogLine:(NSString *)line
{
    NSMutableString *log;

    [self ensurePanel];

    log = [NSMutableString stringWithString:[_logTextView string]];

    if ([log length] > 0) {
        [log appendString:@"\n"];
    }

    [log appendString:(line != nil ? line : @"")];

    [_logTextView setString:log];
    [_logTextView scrollRangeToVisible:NSMakeRange([log length], 0)];

    [_panel displayIfNeeded];
}

- (void)completeOperationWithStatus:(NSString *)status
{
    [self ensurePanel];

    [_progressIndicator stopAnimation:nil];
    [_statusField setStringValue:(status != nil ? status : @"")];
    [_doneButton setEnabled:YES];

    [_panel displayIfNeeded];
}

- (void)dealloc
{
    [_doneButton release];
    [_progressIndicator release];
    [_logTextView release];
    [_statusField release];
    [_panel release];

    [super dealloc];
}

@end
