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

#import "CapsenseSliderViewController.h"


/*!
 *  @class CapsenseSliderViewController
 *
 *  @discussion Class to handle the UI updates with capsense slider service
 *
 */

@interface CapsenseSliderViewController ()
{
    float arrowWidthMultiplier,sliderViewRefHeight, currentSliderValue;
    capsenseModel *sliderModel;  // Model to handle the service and characteristics
}

/* constraint outlets to handle arrow movement */
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *firstArrowLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *secondArrowLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *thirdArrowLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fourthArrrowLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *fifthArrowLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *sliderViewHeightConstraint;

@property (weak, nonatomic) IBOutlet UIImageView *firstArrowImageView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *firstArrowWidthConstraint;
@property (weak, nonatomic) IBOutlet UIView *sliderView;

@property (strong, nonatomic) IBOutletCollection(UIImageView) NSArray * greyArrowImageViews;

-(void) deviceOrientationDidChange:(NSNotification *)notification;
	
@end


@implementation CapsenseSliderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    sliderViewRefHeight = _sliderView.frame.size.height;  // Slider height is stored to change height for Ipad
   
    // Initializing the position of arrows in slider
    [self initiallizeView];
    [self.view layoutIfNeeded];
    
    // Initialize model
    [self initSliderModel];
    
    for (UIImageView * arrowImage in _greyArrowImageViews) {
        [arrowImage setHidden:NO];
    }
    [_sliderView setBackgroundColor:[UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:1.0]];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [[self navBarTitleLabel] setText:CAPSENSE];

    // Add observer to handle the UI change with device orientation
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        [sliderModel stopUpdate];   // stop receiving characteristic value when the user exits the screen
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
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
 *  @method initSliderModel
 *
 *  @discussion Method to discover the specified characteristics of a service.
 *
 */

-(void) initSliderModel
{
    if (!sliderModel)
    {
        sliderModel = [[capsenseModel alloc] init];;
    }
    
    [sliderModel startDiscoverCharacteristicWithUUID:_sliderCharacteristicUUID completionHandler:^(BOOL success, CBService *service, NSError *error)
    {
        if (success)
        {
            // Start receiving characteristic value when characteristic found successfully
            [self updateSliderUI];
        }
    }];
}


/*!
 *  @method updateSliderUI
 *
 *  @discussion Method to Start receiving characteristic value
 *
 */
-(void) updateSliderUI
{
    [sliderModel updateCharacteristicWithHandler:^(BOOL success, NSError *error) {
        
        if (success)
        {
            @synchronized(sliderModel){
               
                float sliderValue = sliderModel.capsenseSliderValue;  // Get the slider value
                [self changeSliderToPosition:sliderValue];   // Move the arrows with the value recieved
                currentSliderValue = sliderValue;
            }
        }
    }];
}

/*!
 *  @method initializeView
 *
 *  @discussion Method to handle the screen when the user first enters.
 *
 */

-(void) initiallizeView
{
    // Calculate the factor by which the arrow should be moved
    
    arrowWidthMultiplier = [self calculateArrowWidthMultiplier];
    
    // Initially hiding all the imageViews
    
    _firstArrowLeadingConstraint.constant =   -_firstArrowImageView.frame.size.width + 10;
    _secondArrowLeadingConstraint.constant = - _firstArrowImageView.frame.size.width;
    _thirdArrowLeadingConstraint.constant = - _firstArrowImageView.frame.size.width;
    _fourthArrrowLeadingConstraint.constant = - _firstArrowImageView.frame.size.width;
    _fifthArrowLeadingConstraint.constant = -_firstArrowImageView.frame.size.width;
    for (UIImageView * arrowImage in _greyArrowImageViews) {
        [arrowImage setHidden:YES];
    }
}


/*!
 *  @method changeSliderToPosition:
 *
 *  @discussion Method to move the arrows with the value received
 *
 */
-(void)changeSliderToPosition:(float)value
{

    // The range of characteristic value is checked to move the respective arrow
    if (value <= 20) {
        
        _firstArrowLeadingConstraint.constant = -_firstArrowImageView.frame.size.width + 10 + value * arrowWidthMultiplier ;
        _secondArrowLeadingConstraint.constant = - _firstArrowImageView.frame.size.width;
        _thirdArrowLeadingConstraint.constant = - _firstArrowImageView.frame.size.width;
        _fourthArrrowLeadingConstraint.constant = - _firstArrowImageView.frame.size.width;
        _fifthArrowLeadingConstraint.constant = - _firstArrowImageView.frame.size.width;
        
    }
    else if (value > 20 && value <= 40){
        
        _firstArrowLeadingConstraint.constant = -10;
        
        _secondArrowLeadingConstraint.constant = _firstArrowLeadingConstraint.constant + (value -20) *arrowWidthMultiplier;
        _thirdArrowLeadingConstraint.constant = _fourthArrrowLeadingConstraint.constant = _fifthArrowLeadingConstraint.constant = _firstArrowLeadingConstraint.constant + (value -20) *arrowWidthMultiplier;
    }
    else if (value > 40 && value <= 60){
        
        _firstArrowLeadingConstraint.constant = -10;
        _secondArrowLeadingConstraint.constant = _firstArrowLeadingConstraint.constant + 20*arrowWidthMultiplier;
        _thirdArrowLeadingConstraint.constant = _secondArrowLeadingConstraint.constant +(value - 40) * arrowWidthMultiplier;
        _fourthArrrowLeadingConstraint.constant = _fifthArrowLeadingConstraint.constant = _secondArrowLeadingConstraint.constant +(value - 40) * arrowWidthMultiplier;
        
    }
    else if (value > 60 && value <= 80){
        
        _firstArrowLeadingConstraint.constant = -10;
        _secondArrowLeadingConstraint.constant = _firstArrowLeadingConstraint.constant + 20 * arrowWidthMultiplier;
        _thirdArrowLeadingConstraint.constant =  _secondArrowLeadingConstraint.constant +20 * arrowWidthMultiplier;
        _fourthArrrowLeadingConstraint.constant = _thirdArrowLeadingConstraint.constant + (value -60) *arrowWidthMultiplier;
        _fifthArrowLeadingConstraint.constant =  _thirdArrowLeadingConstraint.constant + (value -60) *arrowWidthMultiplier;
    }
    else if (value > 80 && value <= 100){
        
        _firstArrowLeadingConstraint.constant = -10;
        _secondArrowLeadingConstraint.constant = _firstArrowLeadingConstraint.constant + 20 * arrowWidthMultiplier;
        _thirdArrowLeadingConstraint.constant = _secondArrowLeadingConstraint.constant +20 * arrowWidthMultiplier;
        _fourthArrrowLeadingConstraint.constant = _thirdArrowLeadingConstraint.constant + 20 * arrowWidthMultiplier;
        _fifthArrowLeadingConstraint.constant = _fourthArrrowLeadingConstraint.constant + (value -80) * arrowWidthMultiplier;
    }
    
    // Animate the view
    
    [UIView animateWithDuration:0.05 animations:^{
        [self.view layoutIfNeeded];
    }];
    
    // Reset the view when the user remove finger
    if (value == 255) {
        for (UIImageView * arrowImage in _greyArrowImageViews) {
            [arrowImage setHidden:NO];
        }
        [_sliderView setBackgroundColor:[UIColor colorWithRed:130.0/255.0 green:130.0/255.0 blue:130.0/255.0 alpha:1.0]];
    }else{
        if (![[_greyArrowImageViews objectAtIndex:0]isHidden]) {
            [_sliderView setBackgroundColor:[UIColor colorWithRed:12.0/255.0 green:55.0/255.0 blue:123.0/255.0 alpha:1.0]];
            for (UIImageView * arrowImage in _greyArrowImageViews) {
                [arrowImage setHidden:YES];
            }
        }
    }
}


/*!
 *  @method deviceOrientationDidChange:
 *
 *  @discussion invoked when the device orientation did change
 *
 */
-(void) deviceOrientationDidChange:(NSNotification *)notification
{
    if (IS_IPAD)
    {
        arrowWidthMultiplier = [self calculateArrowWidthMultiplier];
        [self changeSliderToPosition:currentSliderValue];
    }
}


/*!
 *  @method calculateArrowWidthMultiplier
 *
 *  @discussion Method to calculate the factor by which the arrow should be moved
 *
 */

-(float) calculateArrowWidthMultiplier
{
    float multiplier;
    
    // Multiplier is different for Ipad since the image size is different
    if ( UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad )
    {
        _sliderViewHeightConstraint.constant = sliderViewRefHeight * 2;
        _firstArrowWidthConstraint.constant = self.view.frame.size.width/5;
        [self.view layoutIfNeeded];
        multiplier = (_firstArrowImageView.frame.size.width)/20;
    }
    else
    {
        if (IS_IPHONE_6P)
        {
            multiplier = (self.view.frame.size.width + 15)/100;
        }
        else
            multiplier = (self.view.frame.size.width - 5)/100;
    }
    return multiplier;

}

@end
