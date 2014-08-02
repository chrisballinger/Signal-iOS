#import "Environment.h"
#import "FutureUtil.h"
#import "LocalizableText.h"
#import "Operation.h"
#import "PreferencesUtil.h"
#import "PhoneNumber.h"
#import "RecentCallManager.h"
#import "RegisterViewController.h"
#import "SettingsViewController.h"
#import "Pastelog.h"
#import "SGNKeychainUtil.h"

#import "UIViewController+MMDrawerController.h"

#define SECTION_HEADER_VIEW_HEIGHT 27
#define PRIVACY_SECTION_INDEX 0
#define CALL_QUALITY_SECTION_INDEX 1

static NSString *const CHECKBOX_CHECKMARK_IMAGE_NAME = @"checkbox_checkmark";
static NSString *const CHECKBOX_EMPTY_IMAGE_NAME = @"checkbox_empty";

@interface SettingsViewController () {
    NSArray *_sectionHeaderViews;
    NSArray *_privacyTableViewCells;
    NSArray *_callQualityTableViewCells;
    
    NSString *gistURL;
}

@end

@implementation SettingsViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    _sectionHeaderViews = @[_privacyAndSecurityHeaderView];

    _titleLabel.text = SETTINGS_NAV_BAR_TITLE;
}

- (void)viewWillAppear:(BOOL)animated {
    [self configureLocalNumber];
    [self configureAllCells];
    [self configureCheckboxPreferences];
    [self.navigationController setNavigationBarHidden:YES animated:NO];
    [super viewWillAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self saveExpandedSectionPreferences];

    if ([self.navigationController.viewControllers count] > 1) {
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }

    [super viewWillDisappear:animated];
}

- (void)menuButtonTapped {
    [self.mm_drawerController openDrawerSide:MMDrawerSideLeft animated:YES completion:nil];
}

#pragma mark - Local number

- (void)configureLocalNumber {
    PhoneNumber *localNumber = [SGNKeychainUtil localNumber];
    if (localNumber) {
        _phoneNumberLabel.attributedText = [self localNumberAttributedStringForNumber:localNumber];
    } else {
        _phoneNumberLabel.text = @"";
    }
}

- (NSAttributedString *)localNumberAttributedStringForNumber:(PhoneNumber *)number {
    NSString *numberPrefixString = SETTINGS_NUMBER_PREFIX;
    NSString *localNumberString = [number toE164];

    NSString *displayString = [NSString stringWithFormat:@"%@ %@", numberPrefixString, localNumberString];
    NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:displayString];

    UIFont *prefixFont = [UIUtil helveticaNeueLTStdLightFontWithSize:_phoneNumberLabel.font.pointSize];
    UIFont *numberFont = [UIUtil helveticaNeueLTStdBoldFontWithSize:_phoneNumberLabel.font.pointSize];

    [attributedString addAttribute:NSFontAttributeName
                             value:prefixFont
                             range:NSMakeRange(0, [numberPrefixString length])];

    [attributedString addAttribute:NSFontAttributeName
                             value:numberFont
                             range:NSMakeRange([numberPrefixString length] + 1, [localNumberString length])];
    return attributedString;
}

#pragma mark - Preferences

- (void)configureCheckboxPreferences {
    NSArray *buttons = @[_hideContactImagesButton,
                         _disableAutocorrectButton,
                         _disableHistoryButton];

    for (UIButton *button in buttons) {
        [button setImage:[UIImage imageNamed:CHECKBOX_EMPTY_IMAGE_NAME]
                forState:UIControlStateNormal];
        
        [button setImage:[UIImage imageNamed:CHECKBOX_CHECKMARK_IMAGE_NAME]
                forState:UIControlStateSelected];
    }
    PropertyListPreferences *prefs = [Environment preferences];
    _hideContactImagesButton.selected = ![prefs getContactImagesEnabled];
    _disableAutocorrectButton.selected = ![prefs getAutocorrectEnabled];
    _disableHistoryButton.selected = ![prefs getHistoryLogEnabled];
}

- (void)configureAllCells {
    _privacyTableViewCells = [self privacyAndSecurityCells];
    [_privacyAndSecurityHeaderView setColumnStateExpanded:YES andIsAnimated:NO];
}

- (void)saveExpandedSectionPreferences {
    NSMutableArray *expandedSectionPrefs = [NSMutableArray array];
    NSNumber *numberBoolYes = [NSNumber numberWithBool:YES];
    NSNumber *numberBoolNo = [NSNumber numberWithBool:NO];

    [expandedSectionPrefs addObject:(_privacyTableViewCells ? numberBoolYes : numberBoolNo)];
}

#pragma mark - Table View Helpers

- (NSArray *)privacyAndSecurityCells {
    return @[_hideContactImagesCell,
             _disableAutocorrectCell,
             _disableHistoryCell,
             _clearHistoryLogCell,
             _sendDebugLog];
}

- (NSArray *)indexPathsForCells:(NSArray *)cells forRow:(NSInteger)row {
    NSMutableArray *indexPaths = [NSMutableArray array];
    for (NSUInteger i = 0; i < [cells count]; i++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(NSInteger)i inSection:row];
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}

- (NSArray *)cellsForRow:(NSInteger)row {
    if (row == PRIVACY_SECTION_INDEX) {
        return [self privacyAndSecurityCells];
    } else {
        return @[];
    }
}

#pragma mark - Actions

- (void)registerTapped {
    RegisterViewController *registerViewController = [RegisterViewController registerViewController];
    [self presentViewController:registerViewController animated:YES completion:nil];
}

- (void)privacyAndSecurityTapped {
    [self toggleCells:&_privacyTableViewCells forRow:PRIVACY_SECTION_INDEX];
    BOOL columnExpanded = _privacyTableViewCells != nil;
    [_privacyAndSecurityHeaderView setColumnStateExpanded:columnExpanded andIsAnimated:YES];
}

- (void)toggleCells:(NSArray *__strong*)cells forRow:(NSInteger)row {
    [_settingsTableView beginUpdates];
    if (*cells) {
        [_settingsTableView deleteRowsAtIndexPaths:[self indexPathsForCells:*cells forRow:row]
                                  withRowAnimation:UITableViewRowAnimationFade];
        *cells = nil;
    } else {
        *cells = [self cellsForRow:row];
        [_settingsTableView insertRowsAtIndexPaths:[self indexPathsForCells:*cells forRow:row]
                                  withRowAnimation:UITableViewRowAnimationFade];
    }
    [_settingsTableView endUpdates];
}

- (IBAction)hideContactImagesButtonTapped {
    _hideContactImagesButton.selected = !_hideContactImagesButton.selected;
    [[Environment preferences] setContactImagesEnabled:!_hideContactImagesButton.selected];
}

- (IBAction)disableAutocorrectButtonTapped {
    _disableAutocorrectButton.selected = !_disableAutocorrectButton.selected;
    [[Environment preferences] setAutocorrectEnabled:!_disableAutocorrectButton.selected];
}

- (IBAction)disableHistoryButtonTapped {
    _disableHistoryButton.selected = !_disableHistoryButton.selected;
    [[Environment preferences] setHistoryLogEnabled:!_disableHistoryButton.selected];
}

- (void)clearHistory {
    [[[Environment getCurrent] recentCallManager] clearRecentCalls];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:SETTINGS_LOG_CLEAR_TITLE
                                                        message:SETTINGS_LOG_CLEAR_MESSAGE
                                                       delegate:nil
                                              cancelButtonTitle:nil
                                              otherButtonTitles:SETTINGS_LOG_CLEAR_CONFIRM, nil];
    [alertView show];
}

#pragma mark - UITableViewDelegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return (NSInteger)[_sectionHeaderViews count];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return _sectionHeaderViews[(NSUInteger)section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return SECTION_HEADER_VIEW_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    UIView *headerView = _sectionHeaderViews[(NSUInteger)section];
    if (headerView == _privacyAndSecurityHeaderView) {
        return (NSInteger)[_privacyTableViewCells count];
    } else {
        return 0;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UIView *headerView = _sectionHeaderViews[(NSUInteger)indexPath.section];
    UITableViewCell *cell = nil;
    if (headerView == _privacyAndSecurityHeaderView) {
        cell = _privacyTableViewCells[(NSUInteger)indexPath.row];
    }
    [self findAndLocalizeLabelsForView:cell];

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell == _clearHistoryLogCell) {
        [self clearHistory];
    }
    
    if (cell == _sendDebugLog) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:SETTINGS_SENDLOG_WAITING
                                            message:nil delegate:self cancelButtonTitle:nil otherButtonTitles: nil];
        
        [alert show];
        
        [Pastelog submitLogsWithCompletion:^(NSError *error, NSString *urlString) {
            [alert dismissWithClickedButtonIndex:0 animated:YES];
            if (!error) {
                gistURL = urlString;
                UIAlertView *alertView = [[UIAlertView alloc]initWithTitle:SETTINGS_SENDLOG_ALERT_TITLE message:SETTINGS_SENDLOG_ALERT_BODY delegate:self cancelButtonTitle:SETTINGS_SENDLOG_ALERT_PASTE otherButtonTitles:SETTINGS_SENDLOG_ALERT_EMAIL, nil];
                [alertView show];
                
            } else{
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:SETTINGS_SENDLOG_FAILED_TITLE message:SETTINGS_SENDLOG_FAILED_BODY delegate:nil cancelButtonTitle:SETTINGS_SENDLOG_FAILED_DISMISS otherButtonTitles:nil, nil];
                [alertView show];
            }
        }];
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    if (buttonIndex == 0) {
        [self submitEmail:gistURL];
    } else{
        [self pasteBoardCopy:gistURL];
    }
}

- (void)submitEmail:(NSString*)url{
    NSString *emailAddress;
    
#ifdef ADHOC
    emailAddress = @"signal-beta@fredericjacobs.com";
#else
    emailAddress = @"support@whispersystems.org";
#endif
    
    NSString *urlString = [NSString stringWithString: [[NSString stringWithFormat:@"mailto:%@?subject=iOS%%20Debug%%20Log&body=", emailAddress] stringByAppendingString:[[NSString stringWithFormat:@"Log URL: %@ \n Tell us about the issue: ", url]stringByAddingPercentEscapesUsingEncoding:NSASCIIStringEncoding]]];
    
    [[UIApplication sharedApplication] openURL: [NSURL URLWithString: urlString]];
}

- (void)pasteBoardCopy:(NSString*)url{
    UIPasteboard *pb = [UIPasteboard generalPasteboard];
    [pb setString:url];
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"https://github.com/WhisperSystems/Signal-iOS/issues"]];
}

- (void)findAndLocalizeLabelsForView:(UIView *)view {
    for (UIView *subview in view.subviews) {
        if ([subview respondsToSelector:@selector(localizationKey)]) {
            LocalizableCustomFontLabel *label = (LocalizableCustomFontLabel *)subview;
            if (label.localizationKey) {
                label.text = NSLocalizedString(label.localizationKey, @"");
            }
        }
        [self findAndLocalizeLabelsForView:subview];
    }
}

@end
