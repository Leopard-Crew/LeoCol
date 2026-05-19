#import <Cocoa/Cocoa.h>

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
- (void)showEvidenceSummary:(id)sender;
@end

