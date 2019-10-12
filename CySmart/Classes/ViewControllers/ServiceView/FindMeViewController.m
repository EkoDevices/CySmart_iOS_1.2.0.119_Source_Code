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

#import "FindMeViewController.h"
#import "FindMeModel.h"
#import "UIView+Toast.h"

#define LINKLOSS_ALERT_ACTIONSHEET  101
#define IMMEDIATE_ALERT_ACTIONSHEET 102

/*!
 *  @class Class FindMeViewController
 *
 *  @discussion Class to handle the user interactions and UI updates for linkloss, immediete alert and transmission power services
 *
 */

@interface FindMeViewController ()<UIActionSheetDelegate>
{
    FindMeModel *mFindMeModel;
    UIActionSheet *linkLossAlertOptionActionSheet;
    UIActionSheet *immediateAlertOptionActionSheet;
    float whiteCircleRefHeight;
}

/*  Selection Buttons */
@property (weak, nonatomic) IBOutlet UIButton *linkLossAlertSelectionButton;
@property (weak, nonatomic) IBOutlet UIButton *ImmediateAlertSelectionButton;

/*  Data field  */
@property (weak, nonatomic) IBOutlet UILabel *transmissionPowerLevelValue;

/*  View outlets  */
@property (weak, nonatomic) IBOutlet UIView *linkLossView;
@property (weak, nonatomic) IBOutlet UIView *immediateALertView;
@property (weak, nonatomic) IBOutlet UIView *transmissionPowerLevelView;

/*  Constraint outlets */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *findMeBlueCircleHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *findMeWhiteCircleHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *immediateAlertViewHeightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *linkLossViewHeightConstraint;



@end

@implementation FindMeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self initView];
    
    // Initialize find me model
    [self initFindMeModel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:PROXIMITY];

    for (CBService *service in _servicesArray)
    {
        if ([service.UUID isEqual:IMMEDIATE_ALERT_SERVICE_UUID])
        {
            [[super navBarTitleLabel] setText:FIND_ME];
        }
    }
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        // stop receiving characteristic value when the user exits the screen
        [mFindMeModel stopUpdate];
    }
   
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


/*!
 *  @method initView
 *
 *  @discussion Method to initialize the view properties.
 *
 */

-(void) initView
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        _findMeBlueCircleHeightConstraint.constant += DEFAULT_SIZE_NORMALISATION_CONSTANT_FOR_IPAD;
        _findMeWhiteCircleHeightConstraint.constant+= DEFAULT_SIZE_NORMALISATION_CONSTANT_FOR_IPAD;
        [self.view layoutIfNeeded];
    }
    whiteCircleRefHeight = _findMeWhiteCircleHeightConstraint.constant;
    
    // Set border color for the labels
    
    _linkLossAlertSelectionButton.layer.borderColor = [UIColor blueColor].CGColor;
    _linkLossAlertSelectionButton.layer.borderWidth = 1.0;
    
    _ImmediateAlertSelectionButton.layer.borderColor =  [UIColor blueColor].CGColor;
    _ImmediateAlertSelectionButton.layer.borderWidth = 1.0;

    // Hiding the views initially
    _transmissionPowerLevelView.hidden = YES;
    _immediateAlertViewHeightConstraint.constant = 0;
    _linkLossViewHeightConstraint.constant = 0;
}


/*!
 *  @method initFindMeModel
 *
 *  @discussion Method to Discover the specified characteristic of a service.
 *
 */

-(void) initFindMeModel
{
    if (!mFindMeModel)
    {
        mFindMeModel = [[FindMeModel alloc] init];
    }
    
    // Find the required characteristic for each service
    if (_servicesArray.count > 0)
    {
        for (CBService *service  in _servicesArray)
        {
            [mFindMeModel startDiscoverCharacteristicsForService:service withCompletionHandler:^(CBService *foundService,BOOL success, NSError *error) {
                
                if (success)
                {
                    // Get the characteristic value if successfully found out
                    [self updateFindMeUIForServiceWithUUID:foundService.UUID];
                }
            }];
        }
    }
}


/*!
 *  @method updateFindMeUIForServiceWithUUID:
 *
 *  @discussion Method to show the respecive views with the services present
 *
 */
-(void) updateFindMeUIForServiceWithUUID:(CBUUID *)serviceUUID
{
    // Check whether the service is present
    if ([serviceUUID isEqual:TRANSMISSION_POWER_SERVICE] && mFindMeModel.isTransmissionPowerPresent)
    {
        _transmissionPowerLevelView.hidden = NO;
        [self readValueForTransmissionPower];
    }
    
    if ([serviceUUID isEqual:LINK_LOSS_SERVICE_UUID] && mFindMeModel.isLinkLossServicePresent)
    {
        _linkLossViewHeightConstraint.constant = 100.0f;
        [_linkLossAlertSelectionButton setTitle:SELECT forState:UIControlStateNormal];
    }
    
    if ([serviceUUID isEqual:IMMEDIATE_ALERT_SERVICE_UUID] && mFindMeModel.isImmediateAlertServicePresent)
    {
        _immediateAlertViewHeightConstraint.constant = 100.0f;
        [_ImmediateAlertSelectionButton setTitle:SELECT forState:UIControlStateNormal];
    }

    [self.view layoutIfNeeded];
}

/*  Button actions */
- (IBAction)selectButtonClickedForLinkLossAlert:(UIButton *)sender
{
    // Show selection options
    if (!linkLossAlertOptionActionSheet)
    {
        linkLossAlertOptionActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:CANCEL destructiveButtonTitle:nil otherButtonTitles:NO_ALERT,MILD_ALERT,HIGH_ALERT, nil];
        linkLossAlertOptionActionSheet.tag = LINKLOSS_ALERT_ACTIONSHEET;
    }
    [linkLossAlertOptionActionSheet showFromRect:sender.frame inView:sender.superview animated:YES];

}

- (IBAction)selectButtonClickedForImmedieteAlert:(UIButton *)sender
{
    // Show selection options

    if (!immediateAlertOptionActionSheet)
    {
        immediateAlertOptionActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:CANCEL destructiveButtonTitle:nil otherButtonTitles:NO_ALERT,MILD_ALERT,HIGH_ALERT, nil];
        immediateAlertOptionActionSheet.tag = IMMEDIATE_ALERT_ACTIONSHEET;
    }
    [immediateAlertOptionActionSheet showFromRect:sender.frame inView:sender.superview animated:YES];
}


/*!
 *  @method writeValueForLinkLossWith:
 *
 *  @discussion Method to write the link loss characteristic value to the device
 *
 */
-(void) writeValueForLinkLossWith:(enum alertOptions)option WithAlert:(NSString *)alert
{
    [mFindMeModel updateLinkLossCharacteristicValue:option WithHandler:^(BOOL success, NSError *error) {
        
        NSString *message = @"";
        if (success)
        {
            message = [NSString stringWithFormat:LOCALIZEDSTRING(@"dataWriteSuccessMessage"),alert];
        }
        else
        {
            message = LOCALIZEDSTRING(@"dataWriteErrorMessage");
        }
        
        // Show whether the write was success or not
        [self.view makeToast:message];
    }];
}


/*!
 *  @method writeValueForImmediateAlertWith:
 *
 *  @discussion Method to write the ImmediateAlert characteristic value to the device
 *
 */

-(void) writeValueForImmediateAlertWith:(enum alertOptions)option withAlert:(NSString *)alert
{
    [mFindMeModel updateImmedieteALertCharacteristicValue:option WithHandler:^(BOOL success, NSError *error) {
        
        if (success)
        {
            NSString *message = @"";
            if (success)
            {
                message = [NSString stringWithFormat:LOCALIZEDSTRING(@"dataWriteSuccessMessage"),alert];
            }
            else
            {
                message = LOCALIZEDSTRING(@"dataWriteErrorMessage");
            }
            
            // Show whether the write was success or not
            [self.view makeToast:message];
        }
    }];
}


/*!
 *  @method readValueForTransmissionPower
 *
 *  @discussion Method to read the power value and handle animation
 *
 */
-(void) readValueForTransmissionPower
{
    [mFindMeModel updateProximityCharacteristicWithHandler:^(BOOL success, NSError *error) {
        
            if (success)
            {
                @synchronized(mFindMeModel){
                    
                    _transmissionPowerLevelValue.text = [NSString stringWithFormat:@"%0.f",mFindMeModel.transmissionPowerValue];
                    
                    // Calculating the constraint value
                    
                    float tempValue = mFindMeModel.transmissionPowerValue + 80;
                    
                    if (tempValue <0) {
                        tempValue = tempValue * -1;
                    }
                    // White circle animation
                    
                    float constraintValue = tempValue * (whiteCircleRefHeight/100);
                    _findMeWhiteCircleHeightConstraint.constant = constraintValue;
                    
                    [UIView animateWithDuration:0.5 animations:^{
                        [self.view layoutIfNeeded];
                    }];
                }
            }
    }];
}


#pragma mark - UIActionSheetDelegate Methods

-(void) actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Identify the actionsheet related to which service
    if (actionSheet.tag == LINKLOSS_ALERT_ACTIONSHEET)
    {
        // Checking the selected alert and writing the corresponding value to the device

        switch (buttonIndex)
        {
            case kAlertNone:
                [_linkLossAlertSelectionButton setTitle:NO_ALERT forState:UIControlStateNormal];
                [self writeValueForLinkLossWith:kAlertNone WithAlert:NO_ALERT];
                break;
                
            case kMidAlert:
                [_linkLossAlertSelectionButton setTitle:MILD_ALERT forState:UIControlStateNormal];
                [self writeValueForLinkLossWith:kMidAlert WithAlert:MILD_ALERT];
                break;
                
            case kHighAlert:
                [_linkLossAlertSelectionButton setTitle:HIGH_ALERT forState:UIControlStateNormal];
                [self writeValueForLinkLossWith:kHighAlert WithAlert:HIGH_ALERT];
                break;
                
            default:
                break;
        }
        [_linkLossAlertSelectionButton layoutIfNeeded];

    }
    else if (actionSheet.tag == IMMEDIATE_ALERT_ACTIONSHEET)
    {
       // Checking the selected alert and writing the corresponding value to the device
        switch (buttonIndex)
        {
            case kAlertNone:
                [_ImmediateAlertSelectionButton setTitle:NO_ALERT forState:UIControlStateNormal];
                [self writeValueForImmediateAlertWith:kAlertNone withAlert:NO_ALERT];
                break;
                
            case kMidAlert:
                [_ImmediateAlertSelectionButton setTitle:MILD_ALERT forState:UIControlStateNormal];
                [self writeValueForImmediateAlertWith:kMidAlert withAlert:MILD_ALERT];
                break;
                
            case kHighAlert:
                [_ImmediateAlertSelectionButton setTitle:HIGH_ALERT forState:UIControlStateNormal];
                [self writeValueForImmediateAlertWith:kHighAlert withAlert:HIGH_ALERT];
                break;
                
            default:
                break;
        }
    }

}


@end
