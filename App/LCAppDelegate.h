#import <Cocoa/Cocoa.h>

/*!
 @class LeoColAppDelegate
 @abstract Application delegate for the LeoCol Cocoa viewer.
 @discussion
    LeoColAppDelegate owns the current programmatic Cocoa user interface:
    the process table, filter field, reload button, read-only process detail
    inspector, status line, and provenance evidence summary window.
 */
@interface LeoColAppDelegate : NSObject
{
    NSWindow *_window;
    NSTableView *_tableView;
    NSMutableArray *_rows;
    NSMutableArray *_visibleRows;
    NSTextField *_filterField;
    NSTextField *_statusField;
    NSTextView *_detailTextView;
    NSPanel *_evidencePanel;
    NSTableView *_evidenceTableView;
    NSMutableArray *_evidenceRows;
    NSString *_sortKey;
    BOOL _sortAscending;
}

/*!
 @method reloadData:
 @abstract Reloads process rows from the LeoCol store and refreshes the viewer.
 @param sender The control or menu item that initiated the reload.
 */
- (void)reloadData:(id)sender;

/*!
 @method filterChanged:
 @abstract Applies the current filter text to the loaded process rows.
 @param sender The control that initiated the filter update.
 */
- (void)filterChanged:(id)sender;

/*!
 @method showEvidenceSummary:
 @abstract Opens the read-only provenance evidence summary.
 @param sender The control or menu item that requested the summary.
 */
- (void)showEvidenceSummary:(id)sender;

/*!
 @method showAboutPanel:
 @abstract Opens the localized LeoCol About panel.
 @param sender The control or menu item that requested the About panel.
 */
- (void)showAboutPanel:(id)sender;

/*!
 @method exportReport:
 @abstract Exports a read-only plain text report of the current LeoCol viewer state.
 @param sender The control or menu item that requested the export.
 */
- (void)exportReport:(id)sender;

@end
