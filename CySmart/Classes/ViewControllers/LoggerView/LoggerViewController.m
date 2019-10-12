/*
 * Copyright Cypress Semiconductor Corporation, 2014-2018 All rights reserved.
 *
 * This software, associated documentation and materials ("Software") is
 * owned by Cypress Semiconductor Corporation ("Cypress") and is
 * protected by and subject to worldwide patent protection (UnitedStates and foreign), United States copyright laws and international
 * treaty provisions. Therefore, unless otherwise specified in a separate license agreement between you and Cypress, this Software
 * must be treated like any other copyrighted material. Reproduction,
 * modification, translation, compilation, or representation of this
 * Software in any other form (e.g., paper, magnetic, optical, silicon)
 * is prohibited without Cypress's express written permission.
 *
 * Disclaimer: THIS SOFTWARE IS PROVIDED AS-IS, WITH NO WARRANTY OF ANY
 * KIND, EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
 * NONINFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE. Cypress reserves the right to make changes
 * to the Software without notice. Cypress does not assume any liability
 * arising out of the application or use of Software or any product or
 * circuit described in the Software. Cypress does not authorize its
 * products for use as critical components in any products where a
 * malfunction or failure may reasonably be expected to result in
 * significant injury or death ("High Risk Product"). By including
 * Cypress's product in a High Risk Product, the manufacturer of such
 * system or application assumes all risk of such use and in doing so
 * indemnifies Cypress against all liability.
 *
 * Use of this Software may be limited by and subject to the applicable
 * Cypress software license agreement.
 *
 *
 */

#import "LoggerViewController.h"
#import "LoggerHandler.h"
#import "Constants.h"
#import "UIView+Toast.h"
#import "CoreDataHandler.h"
#import "Utilities.h"


/*!
 *  @class LoggerViewController
 *
 *  @discussion Class to handle the operations related to logger
 *
 */
@interface LoggerViewController () <UIActionSheetDelegate>
{
    NSArray *dateHistory;
    UIActionSheet *historyListActionSheet;
    IBOutlet UIButton *historyButton;
    BOOL isActionSheetShown;
    CoreDataHandler *logDataHandler;
}

@property (weak, nonatomic) IBOutlet UILabel *fileNameLabel;


@end

@implementation LoggerViewController

-(void)viewDidLoad {
    [super viewDidLoad];
    
    if (!logDataHandler) {
        logDataHandler = [[CoreDataHandler alloc] init];
    }
    
    [[super navBarTitleLabel] setText:DATA_LOGGER];
    [self initLoggerTextView:[[LoggerHandler logManager] getTodayLogData]];
    [[LoggerHandler logManager] deleteOldLogData];
    
    [self initHistoryList];
    
    if (self.loggerTextView.text.length > 0) {
        NSRange initialRange = NSMakeRange(0, 1);
        [self.loggerTextView scrollRangeToVisible:initialRange];
    }
    [self showToastWithLatestLoggedTime];
}


-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}


/*!
 *  @method initHistoryList
 *
 *  @discussion Method to initialize array with last seven days data
 *
 */
-(void)initHistoryList {
    dateHistory = [[[logDataHandler getLogDates] reverseObjectEnumerator] allObjects];
    if ([[LoggerHandler logManager] getTodayLogData].count > 0) {
        _currentLogFileName = [NSString stringWithFormat:@"%@.txt", [dateHistory objectAtIndex:0]];
    } else {
        _currentLogFileName = [NSString stringWithFormat:@"%@.txt", [Utilities getTodayDateString]];
    }
    _fileNameLabel.text = _currentLogFileName;
}

/*!
 *  @method initLoggerTextView:
 *
 *  @discussion Method to display the data logged in a day
 *
 */
-(void)initLoggerTextView:(NSArray *)logArray
{
    self.loggerTextView.text =[[[[[[[NSString stringWithFormat:@"%@",logArray] stringByReplacingOccurrencesOfString:@"(" withString:@""]stringByReplacingOccurrencesOfString:@")" withString:@""]stringByReplacingOccurrencesOfString:@"\"" withString:@""]stringByReplacingOccurrencesOfString:@"," withString:@""]stringByReplacingOccurrencesOfString:DATE_SEPARATOR withString:@" , "] stringByReplacingOccurrencesOfString:DATA_SEPERATOR withString:@","];
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}
#pragma mark - History Listing

/*!
 *  @method onHistoryTouched:
 *
 *  @discussion Method to handle history button touch
 *
 */

- (IBAction)onHistoryTouched:(id)sender
{
    [self prepareHistoryList:sender];
}


/*!
 *  @method prepareHistoryList:
 *
 *  @discussion Method to initialize the selection options while clicking on the history button
 *
 */

-(void)prepareHistoryList:(id)sender
{
    if (!historyListActionSheet)
    {
        historyListActionSheet = [[UIActionSheet alloc] initWithTitle:[sender title]
                                                  delegate:self
                                         cancelButtonTitle:CANCEL
                                    destructiveButtonTitle:nil
                                         otherButtonTitles: nil];
        
    }
    
    if ([dateHistory count])
    {
        if ([[LoggerHandler logManager] getTodayLogData].count == 0)
        {
            [historyListActionSheet addButtonWithTitle:[NSString stringWithFormat:@"%@.txt",[Utilities getTodayDateString]]];
        }

        for(NSString *date in dateHistory)
        {
            [historyListActionSheet addButtonWithTitle:[NSString stringWithFormat:@"%@.txt",date]];
        }
    }
    else
        [historyListActionSheet addButtonWithTitle:[NSString stringWithFormat:@"%@.txt",[Utilities getTodayDateString]]];
   
    [historyListActionSheet showFromRect:[(UIButton*)sender frame] inView:self.view animated:YES];
    
    isActionSheetShown = YES;
}


/*!
 *  @method actionSheet: clickedButtonAtIndex:
 *
 *  @discussion Method to handle the date selection in history.The view will be automatically dismissed after this call returns.
 *
 */

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if(buttonIndex != 0 )
    {
        if ([dateHistory count])
        {
            if ([[LoggerHandler logManager] getTodayLogData].count == 0)
            {
                if (buttonIndex == 1)
                {
                    _currentLogFileName = [NSString stringWithFormat:@"%@.txt",[Utilities getTodayDateString]];
                    _fileNameLabel.text = _currentLogFileName;
                    [self initLoggerTextView:[[LoggerHandler logManager] getTodayLogData]];
                }
                else
                {
                    [self initLoggerTextView:[logDataHandler getLogEventsForDate:[dateHistory objectAtIndex:(buttonIndex-2)]]];
                    _currentLogFileName = [NSString stringWithFormat:@"%@.txt", [dateHistory objectAtIndex:(buttonIndex-2)]];
                    _fileNameLabel.text = _currentLogFileName;
                }
            }
            else
            {
                [self initLoggerTextView:[logDataHandler getLogEventsForDate:[dateHistory objectAtIndex:(buttonIndex-1)]]];
                _currentLogFileName = [NSString stringWithFormat:@"%@.txt", [dateHistory objectAtIndex:(buttonIndex-1)]];
                _fileNameLabel.text = _currentLogFileName;
            }
        }
        else
        {
            _currentLogFileName = [NSString stringWithFormat:@"%@.txt",[Utilities getTodayDateString]];
            _fileNameLabel.text = _currentLogFileName;
        }
    }
    else
        isActionSheetShown = NO;
    
    historyListActionSheet = nil;
}

/*!
 *  @method showToastWithLatestLoggedTime
 *
 *  @discussion Method to show the user the last logged time
 *
 */

-(void) showToastWithLatestLoggedTime
{
    NSArray *stringArray = [[[[LoggerHandler logManager] getTodayLogData] lastObject] componentsSeparatedByString:DATE_SEPARATOR];
    if([stringArray count])
    {
        NSString *lastItem = [[stringArray firstObject] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        lastItem  = [[[lastItem stringByReplacingOccurrencesOfString:@"[" withString:@""] stringByReplacingOccurrencesOfString:@"]" withString:@""] stringByReplacingOccurrencesOfString:@"|" withString:@" "];
        
        [self.view makeToast:[NSString stringWithFormat:@"%@ %@",LOCALIZEDSTRING(@"loggerToastMessage"),lastItem]];
    }
    else
    {
        [self.view makeToast:[NSString stringWithFormat:@"%@ %@ %@",LOCALIZEDSTRING(@"loggerToastMessage"),[Utilities getTodayDateString],[Utilities getTodayTimeString]]];
    }
}

/*!
 *  @method scrollToDownButtonClicked:
 *
 *  @discussion Method to handle the button click
 *
 */

- (IBAction)scrollToDownButtonClicked:(UIButton *)sender {
    [self scrollTextViewToBottom:self.loggerTextView];
}

/*!
 *  @method scrollTextViewToBottom :
 *
 *  @discussion Method to scroll the text view to the bottom
 *
 */

-(void)scrollTextViewToBottom:(UITextView *)textView {
    if(textView.text.length > 0 ) {
        NSRange bottom = NSMakeRange(textView.text.length -1, 1);
        [textView scrollRangeToVisible:bottom];
    }
}

#pragma mark - Device orientation

/*!
 *  @method deviceOrientationDidChange:
 *
 *  @discussion invoked when the device orientation did change
 *
 */
-(void)deviceOrientationDidChange:(NSNotification *)notification
{
    if (IS_IPAD)
    {
        if (isActionSheetShown && ([[UIDevice currentDevice] orientation] != UIDeviceOrientationFaceUp)) {
            [historyListActionSheet dismissWithClickedButtonIndex:0 animated:NO];
            [historyListActionSheet showFromRect:historyButton.frame inView:self.view animated:NO];
        }
    }
}



@end
