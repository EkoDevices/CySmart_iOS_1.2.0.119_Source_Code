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

#import "CapsenseRootVC.h"
#import "CyCBManager.h"
#import "CapsenseButtonVC.h"
#import "CapsenseProximityVC.h"
#import "CapsenseSliderViewController.h"

#define PROXIMITY_SEGUE         @"proximityVCId"
#define CAPSENSE_BUTTON_SEGUE   @"CapsenseButtonID"
#define CAPSENSE_SLIDER_SEGUE   @"sliderVCId"

/*!
 *  @class CapsenseRootVC
 *
 *  @discussion Class to handle the selection of capsense services
 *
 */

@interface CapsenseRootVC ()
{
    CBCharacteristic *sliderCharacteristic, *proximitycharacteristic, *buttonCharacteristic;
}

@end

@implementation CapsenseRootVC
@synthesize  capsenseCharList;

-(void)viewDidLoad{
    [super viewDidLoad];
    
    // Add buttons for selecting the capsense services present in the profile
    [self performSelector:@selector(updateUI) withObject:nil afterDelay:0.1];
    
    // Add observer to handle the UI change with the orientation change in Ipad
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.navBarTitleLabel setText:CAPSENSE_SELECTION];
}
-(void) viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
}

/*!
 *  @method updateUI
 *
 *  @discussion Method to Add the buttons for selecting service.
 *
 */
-(void)updateUI
{
    NSInteger buttonCount =0 ;
    for(CBCharacteristic *capChar in capsenseCharList)
    {
        // Present the buttons by checking which characteristic is present in the profile
        
        if([capChar.UUID isEqual:CAPSENSE_BUTTON_CHARACTERISTIC_UUID] || [capChar.UUID isEqual:CUSTOM_CAPSENSE_BUTTONS_CHARACTERISTIC_UUID])
        {
            buttonCharacteristic = capChar;
            _capButton.hidden = NO;
            _capButtonYpos.constant = [self yPos:buttonCount];
            buttonCount++;
        }
        else if([capChar.UUID isEqual:CAPSENSE_SLIDER_CHARACTERISTIC_UUID] || [capChar.UUID isEqual:CUSTOM_CAPSENSE_SLIDER_CHARACTERISTIC_UUID])
        {
            sliderCharacteristic = capChar;
            _sliderButton.hidden = NO ;
            _sliderYpos.constant = [self yPos:buttonCount];
            buttonCount++;
        }
        else if([capChar.UUID isEqual:CAPSENSE_PROXIMITY_CHARACTERISTIC_UUID] || [capChar.UUID isEqual:CUSTOM_CAPSENSE_PROXIMITY_CHARACTERISTIC_UUID])
        {
            proximitycharacteristic = capChar;
            _proximityButton.hidden = NO;
            _proximityYpos.constant = [self yPos:buttonCount];
            buttonCount++;
        }
    }
}


/*!
 *  @method yPos:
 *
 *  @discussion Method that returns the Y position for the button with the button count
 *
 */

-(CGFloat)yPos:(NSInteger)buttonCount
{
    if(buttonCount == 0)
    {
        return -NAV_BAR_HEIGHT;
    }
    if(buttonCount == 1)
    {
        return _proximityButton.frame.size.height-NAV_BAR_HEIGHT;
    }
    return -_proximityButton.frame.size.height - NAV_BAR_HEIGHT;
}

/* Button actions */

- (IBAction)onProximityTouched:(id)sender
{
    CapsenseProximityVC *proximityVC = [self.storyboard instantiateViewControllerWithIdentifier:PROXIMITY_SEGUE];
    proximityVC.proximityCharacteristicUUID = proximitycharacteristic.UUID;
    [self.navigationController pushViewController:proximityVC animated:YES];
}

- (IBAction)onCapButtonTouched:(id)sender
{
    CapsenseButtonVC *buttonVc = [self.storyboard instantiateViewControllerWithIdentifier:CAPSENSE_BUTTON_SEGUE];
    buttonVc.capsenseButtonCharacteristicUUID = buttonCharacteristic.UUID;
    [self.navigationController pushViewController:buttonVc animated:YES];
}

- (IBAction)onSliderTouched:(id)sender
{
    CapsenseSliderViewController *sliderVC = [self.storyboard instantiateViewControllerWithIdentifier:CAPSENSE_SLIDER_SEGUE];
    sliderVC.sliderCharacteristicUUID = sliderCharacteristic.UUID;
    [self.navigationController pushViewController:sliderVC animated:YES];
}


/*!
 *  @method deviceOrientationDidChange:
 *
 *  @discussion invoked when the device orientation did change
 *
 */
-(void)deviceOrientationDidChange:(NSNotification *) notification
{
    if (IS_IPAD)
    {
        [self updateUI];
    }
}

@end
