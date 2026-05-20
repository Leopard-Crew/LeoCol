#import <Cocoa/Cocoa.h>

/*!
 @class LCOperationPanel
 @abstract Small reusable progress panel for explicit LeoCol operations.
 @discussion
    LCOperationPanel is used for user-triggered operations such as Update
    Snapshot and Update Evidence. It provides visible progress feedback so
    LeoCol does not appear frozen while helper tools run.
 */
@interface LCOperationPanel : NSObject
{
    NSPanel *_panel;
    NSTextField *_statusField;
    NSTextView *_logTextView;
    NSProgressIndicator *_progressIndicator;
    NSButton *_doneButton;
}

/*!
 @method showWithTitle:status:
 @abstract Shows the operation panel with an initial title and status.
 @param title The panel title.
 @param status Initial status text.
 */
- (void)showWithTitle:(NSString *)title status:(NSString *)status;

/*!
 @method beginOperation
 @abstract Puts the panel into running state and starts the progress indicator.
 */
- (void)beginOperation;

/*!
 @method setStatusText:
 @abstract Updates the visible operation status line.
 @param status New status text.
 */
- (void)setStatusText:(NSString *)status;

/*!
 @method appendLogLine:
 @abstract Appends one line to the read-only operation log.
 @param line Log line to append.
 */
- (void)appendLogLine:(NSString *)line;

/*!
 @method completeOperationWithStatus:
 @abstract Stops progress indication and enables the Done button.
 @param status Final status text.
 */
- (void)completeOperationWithStatus:(NSString *)status;

@end
