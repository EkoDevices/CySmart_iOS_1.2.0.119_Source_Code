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


#import "CapsenseProximityVC.h"
#import "Constants.h"
#import "AVFoundation/AVFoundation.h"

#define AUDIO_TYPE          @"mp3"
#define AUDIO_NAME          @"beep"

#define PROXIMITY_VALUE_MAX 255
#define PROXIMITY_VALUE_THRESHOLD 127

/*!
 *  @class CapsenseProximityVC
 *
 *  @discussion Class to handle the UI updates with capsense proximity
 *
 */

@interface CapsenseProximityVC ()
{
    capsenseModel *proximityModel; // Model to handle the service and characteristics
    BOOL isAudioPlayedOnce; // Varieble to check whether the beep sound played once
    float lastProximityValue;
}

/* view outlets */
@property (weak, nonatomic) IBOutlet UIView *overLayView;
@property (weak, nonatomic) IBOutlet UIView *proximityColorRectangleView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *overlayViewBottomDistanceConstraint;
@property (weak, nonatomic) IBOutlet UIView *proximityColorRectangleTopView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *proximityColourRectWidthConstraint;

@property (strong, nonatomic) AVAudioPlayer *audioPlayer;
@end

@implementation CapsenseProximityVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    _proximityColorRectangleTopView.backgroundColor = BLUE_COLOR;
    [self initializeView];
    // Initialize model
    [self initCapsenseProximityModel];
    
    // Initialize audio player
    [self initializeAudioPlayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:CAPSENSE];
}


-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        // Stop receiving characteristic value when the user exits screen
        [proximityModel stopUpdate];
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
 *  @method initializeView
 *
 *  @discussion Method to change the UI for Iphone
 *
 */

-(void) initializeView
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
    {
        _proximityColourRectWidthConstraint.constant = self.view.frame.size.width/2;
        [self.view layoutIfNeeded];
    }
}

/*!
 *  @method initializeAudioPlayer
 *
 *  @discussion Method to initialize the audio player with the required file.
 *
 */

-(void) initializeAudioPlayer
{
    NSString *filePath = [[NSBundle mainBundle] pathForResource:AUDIO_NAME ofType:AUDIO_TYPE];
    NSURL *audioFileURL = [NSURL fileURLWithPath:filePath];
    
    if (!_audioPlayer)
    {
        NSError *error;
        _audioPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:audioFileURL error:&error];
        
        if(error != nil)
        {
            [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"AudioErrorAlert")];
        }
    }
}

/*!
 *  @method initCapsenseProximityModel
 *
 *  @discussion Method to discover the specified characteristics of a service.
 *
 */

-(void) initCapsenseProximityModel
{
    if (!proximityModel)
    {
        proximityModel = [[capsenseModel alloc] init];
    }
    
    [proximityModel startDiscoverCharacteristicWithUUID:_proximityCharacteristicUUID completionHandler:^(BOOL success, CBService *service, NSError *error)
     {
        if (success)
        {
            // start receiving characteristic value if found successfully
            [self startUpdateProximityChar];
        }
    }];
}

/*!
 *  @method startUpdateProximityChar
 *
 *  @discussion Method to update the characteristic value
 *
 */

-(void) startUpdateProximityChar
{
    [proximityModel updateCharacteristicWithHandler:^(BOOL success, NSError *error) {
        
        if (success)
        {
            @synchronized(proximityModel){
            
                // Start updating the UI with the proximity value from the device
                [self updateProximityUIWithValue:proximityModel.proximityValue];
            }
        }
    }];
}

/*!
 *  @method updateProximityUIWithValue:
 *
 *  @discussion change the UI with the received proximity value
 *
 */

-(void) updateProximityUIWithValue:(float)proximityValue
{
    lastProximityValue = proximityValue;
    // Calculate view size with the proximity value
    
    float constraintValue =( _proximityColorRectangleView.frame.size.height/PROXIMITY_VALUE_MAX) * proximityValue;
    _overlayViewBottomDistanceConstraint.constant = constraintValue;
    
    /* playing audio when the value goes beyond threshold */
    
    if (proximityValue >= PROXIMITY_VALUE_THRESHOLD)
    {
        // Play audio only once when it goes above threshold value

        if (!isAudioPlayedOnce)
        {
            if (_audioPlayer != nil)
            {
                [_audioPlayer play];
            }
            isAudioPlayedOnce = YES;
        }
    }
    else
    {
        isAudioPlayedOnce = NO;
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
        CGFloat newHeightOfColorRect = self.view.frame.size.width - (50.0f + 30.0f + 30.0f + 80.0f);
        _overlayViewBottomDistanceConstraint.constant = ( newHeightOfColorRect/255.0) * lastProximityValue;
        [self.view layoutIfNeeded];
    }
}

@end
