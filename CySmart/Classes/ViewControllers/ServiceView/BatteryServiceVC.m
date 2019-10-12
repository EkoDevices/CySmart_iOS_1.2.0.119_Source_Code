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

#import "BatteryServiceVC.h"
#import "BatteryServiceModel.h"
#import "BatteryServiceView.h"

#define NOTIFY_BUTTON_START     @"Start Notify"
#define NOTIFY_BUTTON_STOP      @"Stop Notify"

/*!
 *  @class BatteryServiceVC
 *
 *  @discussion Class to handle user interactions and UI updates
 *
 */

@interface BatteryServiceVC ()<BatteryCharacteristicDelegate>
{
    BatteryServiceModel *batteryModel; // Model to handle the interaction with the device
    BatteryServiceView *bCustomView;  // Custom battery view
}

@property (weak, nonatomic) IBOutlet UIView *batteryTempView;

@end

@implementation BatteryServiceVC

-(void)viewDidLoad
{
    [self initBatteryModel];

    [super viewDidLoad];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:BATTERY_INFORMATION];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        [batteryModel stopUpdate];
    }
}

/*!
 *  @method initBatteryModel
 *
 *  @discussion Method to Initialize model
 *
 */

-(void)initBatteryModel
{
    [self initBatteryUI];
    
    batteryModel = [[BatteryServiceModel alloc] init];
    batteryModel.delegate = self;
    
    [batteryModel startDiscoverCharacteristicsWithCompletionHandler:^(BOOL success, NSError *error) {
        
        if (success)
        {
            [batteryModel readBatteryLevel];
        }
    }];
}

/*!
 *  @method startUpdate
 *
 *  @discussion Method to Start receiving the characteristic value
 *
 */

-(void)startUpdate
{
    [batteryModel startUpdateCharacteristic];
}


/*!
 *  @method stopUpdate
 *
 *  @discussion Method to stop receiving the characteristic value
 *
 */

-(void)stopUpdate
{
    [batteryModel stopUpdate];
}

/*!
 *  @method initBatteryUI
 *
 *  @discussion Method to initialize Battery screen UI
 *
 */
-(void)initBatteryUI
{
    // Custom view initialization
    bCustomView = [[BatteryServiceView alloc] initWithFrame:CGRectMake(0, 80, self.view.frame.size.width, self.view.frame.size.height-100)];
    [bCustomView.ReadButton addTarget:self action:@selector(onReadTouched:) forControlEvents:UIControlEventTouchUpInside];
    [bCustomView.notifyButton addTarget:self action:@selector(onNotifyTouched:) forControlEvents:UIControlEventTouchUpInside];
    [bCustomView.notifyButton setTitle:NOTIFY_BUTTON_START forState:UIControlStateNormal];
    [bCustomView.notifyButton setTitle:NOTIFY_BUTTON_STOP forState:UIControlStateSelected];
    [bCustomView animateBatteryPercentageValueTo:0 withDuration:0.0];
    [self.view addSubview:bCustomView];
}

#pragma mark - Button actions

/*!
 *  @method onReadTouched
 *
 *  @discussion Button method for read button
 *
 */

-(void)onReadTouched:(id)sender
{
    [batteryModel readBatteryLevel];
}

/*!
 *  @method onNotifyTouched
 *
 *  @discussion Button method for notify button
 *
 */

-(void)onNotifyTouched:(id)sender
{
    UIButton *pButton = (UIButton *)sender;
    if(pButton.isSelected)
    {
        [self stopUpdate];
    }
    else
    {
        [self startUpdate];
    }
    pButton.selected = !pButton.selected;
}


/*!
 *  @method updateBatteryUI
 *
 *  @discussion Method to Update UI with the value received from model
 *
 */

-(void)updateBatteryUI
{
    @synchronized(batteryModel){
        
        for(NSString *key in [batteryModel.batteryServiceDict allKeys])
        {
            NSString *batteryLevelVal = [batteryModel.batteryServiceDict valueForKey:key];// Getting current battery level
            [bCustomView animateBatteryPercentageValueTo:(int)[batteryLevelVal integerValue] withDuration:0.5]; // Update level in UI
            break;
        }
    }
}

@end
