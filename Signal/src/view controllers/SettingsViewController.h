#import <UIKit/UIKit.h>

#import "FutureSource.h"
#import "LocalizableCustomFontLabel.h"
#import "SettingsTableHeaderView.h"

/**
 *
 * SettingsViewController displays a list of settings in sections which can animate between being expanded or collapsed.
 * The expanded/collapsed preference of the sections is remembered by the preference util.
 * Table cell text labels are localized by setting them to a custom label class that has a localization key which are both set in the xib -
 * and localized when the cell appears.
 * Preferences are saved to preference util when tapped.
 *
 */

@interface SettingsViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UIAlertViewDelegate>

@property (nonatomic, strong) IBOutlet UITableView *settingsTableView;
@property (nonatomic, strong) IBOutlet UILabel *phoneNumberLabel;
@property (nonatomic, strong) IBOutlet UILabel *currentDateFormatLabel;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;

@property (nonatomic, strong) IBOutlet SettingsTableHeaderView *privacyAndSecurityHeaderView;
@property (nonatomic, strong) IBOutlet UITableViewCell *hideContactImagesCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *disableAutocorrectCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *disableHistoryCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *clearHistoryLogCell;

@property (nonatomic, strong) IBOutlet UIButton *hideContactImagesButton;
@property (nonatomic, strong) IBOutlet UIButton *disableAutocorrectButton;
@property (nonatomic, strong) IBOutlet UIButton *disableHistoryButton;

@property (nonatomic, strong) IBOutlet SettingsTableHeaderView *locationOverridesHeaderView;
@property (nonatomic, strong) IBOutlet UITableViewCell *dateFormatCell;

@property (nonatomic, strong) IBOutlet SettingsTableHeaderView *callQualityHeaderView;
@property (nonatomic, strong) IBOutlet UITableViewCell *feedbackCell;
@property (nonatomic, strong) IBOutlet UITableViewCell *directoryUpdateCell;

@property (nonatomic, strong) IBOutlet UIButton *sendFeedbackButton;
@property (nonatomic, strong) IBOutlet UITableViewCell *sendDebugLog;

@property (nonatomic, assign) FutureSource *apnId;

- (IBAction)registerTapped;

- (IBAction)privacyAndSecurityTapped;

- (IBAction)hideContactImagesButtonTapped;
- (IBAction)disableAutocorrectButtonTapped;
- (IBAction)disableHistoryButtonTapped;

- (IBAction)sendFeedbackButtonTapped;

- (IBAction)menuButtonTapped;

@end
