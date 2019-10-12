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

#import "RGBViewController.h"
#import "RGBModel.h"
#import "Constants.h"


/*!
 *  @class RGBViewController
 *
 *  @discussion Class to handle user interactions and UI updation for RGB service
 *
 */
@interface RGBViewController ()
{
    RGBModel *rgbModel;
}

@property (weak, nonatomic) IBOutlet UIView *pickerContainer;
@property (weak, nonatomic) IBOutlet UIImageView *gamutImage;
@property (weak, nonatomic) IBOutlet UIImageView *thumbImage;
@property (weak, nonatomic) IBOutlet UISlider *intensitySlider;
@property (weak, nonatomic) IBOutlet UIView *colorValueContainerView;
@property (weak, nonatomic) IBOutlet UIView *colorSelectionView;

/* Datafields */
@property (weak, nonatomic) IBOutlet UILabel *currentColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *redColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *greenColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *blueColorLabel;
@property (weak, nonatomic) IBOutlet UILabel *intensityLabel;

/*Layout constraints for dynamically updating UI layouts*/
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *colorSelectionViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *colorSelectionViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *valuesDisplayViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *valuesDisplayViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *colorSelectionViewTopDistanceConstraint;

- (IBAction)intensityChanged:(id)sender;

@end

@implementation RGBViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self initView];
    [self startUpdate];
    
    // Adding the tap gesture recognizer with uislider to get the tap
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sliderTapped:)] ;
    [_intensitySlider addGestureRecognizer:tapRecognizer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[self navBarTitleLabel] setText:RGB_LED];
    
    [self deviceOrientationDidChange:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        // Stop receiving characteristic value when the user exits the screen
        [rgbModel stopUpdate];
    }
}

/*!
 *  @method initView
 *
 *  @discussion Method to init the view.
 *
 */
- (void)initView
{
    _thumbImage.hidden = YES; // Hide cursor initially
    _colorSelectionViewTopDistanceConstraint.constant = _colorSelectionViewTopDistanceConstraint.constant + NAV_BAR_HEIGHT;
    
    UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
    if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
    {
        _valuesDisplayViewHeightConstraint.constant = self.view.frame.size.height - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
        _colorSelectionViewHeightConstraint.constant = self.view.frame.size.height - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
        _colorSelectionViewWidthConstraint.constant = self.view.frame.size.width * 0.6;
        _valuesDisplayViewWidthConstraint.constant = (self.view.frame.size.width * 0.4) - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
        [self.view layoutIfNeeded];
        [self.view layoutSubviews];
    }
    else
    {
        if (self.view.frame.size.height * 0.6 > 300)
        {
            _colorSelectionViewHeightConstraint.constant = self.view.frame.size.height * 0.5;
            [self.view layoutIfNeeded];
            _valuesDisplayViewHeightConstraint.constant = self.view.frame.size.height - CGRectGetMaxY(_colorSelectionView.frame) - 60;
        }
        else
        {
            _colorSelectionViewHeightConstraint.constant = 260.0f;
            _valuesDisplayViewHeightConstraint.constant = self.view.frame.size.height - 260.0f - STATUS_BAR_HEIGHT - NAV_BAR_HEIGHT;
        }
        _colorSelectionViewWidthConstraint.constant = self.view.frame.size.width;
        _valuesDisplayViewWidthConstraint.constant = self.view.frame.size.width;
        [self.view layoutIfNeeded];
    }
}

/*!
 *  @method startUpdate
 *
 *  @discussion Method to get value from specified characteristic.
 *
 */
-(void)startUpdate
{
    rgbModel = [[RGBModel alloc] init];
    
    // Establish weak self reference
    __weak typeof(self) weakSelf = self;
    
    [rgbModel setDidUpdateValueForCharacteristicHandler:^(BOOL success, NSError *error)
     {
         // Establish strong self reference
         __strong typeof(self) strongSelf = weakSelf;
         
         [strongSelf updateRGBValues];
         
         // Init intensity slider position
         NSInteger intensity = strongSelf->rgbModel.intensity;
         CGFloat percentage = intensity / (CGFloat)0xFF;
         CGFloat delta = percentage * (_intensitySlider.maximumValue - _intensitySlider.minimumValue);
         CGFloat value = _intensitySlider.minimumValue + delta;
         [strongSelf.intensitySlider setValue:value animated:YES];
     }];
}

/*!
 *  @method updateRGBValues
 *
 *  @discussion Method to update the color and intensity in data fields.
 *
 */
-(void)updateRGBValues
{
    // Upadating datafields
    _redColorLabel.text = [self hexStringForInteger:rgbModel.red];
    _greenColorLabel.text = [self hexStringForInteger:rgbModel.green];
    _blueColorLabel.text = [self hexStringForInteger:rgbModel.blue];
    _intensityLabel.text = [self hexStringForInteger:rgbModel.intensity];
    _currentColorLabel.backgroundColor = [UIColor colorWithRed:rgbModel.red/255.0 green:rgbModel.green/255.0 blue:rgbModel.blue/255.0 alpha:rgbModel.intensity/255.0];
}

/*!
 *  @method hexStringForInteger:
 *
 *  @discussion returns hex string for integer value
 *
 */
-(NSString *)hexStringForInteger:(NSInteger)value
{
    return [NSString stringWithFormat:@"0x%02lx",(long)value];
}

/*!
 *  @method intensityChanged:
 *
 *  @discussion Method to handle the inensity change
 *
 */
- (IBAction)intensityChanged:(id)sender
{
    // Write the intensity values to the device
    [rgbModel writeColorWithRed:rgbModel.red green:rgbModel.green blue:rgbModel.blue intensity:_intensitySlider.value handler:^(BOOL success, NSError *error)
     {
         [self updateRGBValues];
     }];
}

#pragma mark - Device orientation notification

/*!
 *  @method deviceOrientationDidChange:
 *
 *  @discussion invoked when the device orientation did change
 *
 */
-(void) deviceOrientationDidChange:(NSNotification *) notification
{
    if (IS_IPAD)
    {
        UIInterfaceOrientation orientation = [[UIApplication sharedApplication] statusBarOrientation];
        if (orientation == UIInterfaceOrientationLandscapeLeft || orientation == UIInterfaceOrientationLandscapeRight)
        {
            _valuesDisplayViewHeightConstraint.constant = self.view.frame.size.height - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
            _colorSelectionViewHeightConstraint.constant = self.view.frame.size.height - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
            _colorSelectionViewWidthConstraint.constant = self.view.frame.size.width * 0.6;
            _valuesDisplayViewWidthConstraint.constant = (self.view.frame.size.width * 0.4) - NAV_BAR_HEIGHT - STATUS_BAR_HEIGHT;
            [self.view layoutIfNeeded];
        }
        else
        {
            _colorSelectionViewHeightConstraint.constant = self.view.frame.size.height * 0.5;
            [self.view layoutIfNeeded];
            
            _valuesDisplayViewHeightConstraint.constant = self.view.frame.size.height - CGRectGetMaxY(_colorSelectionView.frame) - 60;
            _colorSelectionViewWidthConstraint.constant = self.view.frame.size.width;
            _valuesDisplayViewWidthConstraint.constant = self.view.frame.size.width;
            [self.view layoutIfNeeded];
        }
    }
}


#pragma mark - tap in slider

/*!
 *  @method sliderTapped:
 *
 *  @discussion Method to handle the the tap on slider
 *
 */
-(void) sliderTapped:(UIGestureRecognizer *)gestureRecognizer
{
    if (_intensitySlider.highlighted) {
        return; // tap on thumb, let slider deal with it
    }
    CGPoint point = [gestureRecognizer locationInView: _intensitySlider];
    CGFloat percentage = point.x / _intensitySlider.bounds.size.width;
    CGFloat delta = percentage * (_intensitySlider.maximumValue - _intensitySlider.minimumValue);
    CGFloat value = _intensitySlider.minimumValue + delta;
    [_intensitySlider setValue:value animated:YES];
    
    // Write the intensity values to the device
    [rgbModel writeColorWithRed:rgbModel.red green:rgbModel.green blue:rgbModel.blue intensity:_intensitySlider.value handler:^(BOOL success, NSError *error) {
        [self updateRGBValues];
    }];
}


#pragma mark - Touch Methods

/* Methods to handle the touch events */
-(void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint tappedPt = [[touches anyObject] locationInView:_pickerContainer];
    [self colorOfPoint:tappedPt]; // Get color at the point where the touch began
}

- (void) touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event
{
    CGPoint tappedPt = [[touches anyObject] locationInView:_pickerContainer];
    [self colorOfPoint:tappedPt]; // Get color at the point where the touch ended
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    CGPoint tappedPt = [[touches anyObject] locationInView:_pickerContainer];
    [self colorOfPoint:tappedPt]; // Get color at the current point
}

/*!
 *  @method colorOfPoint:
 *
 *  @discussion Method that returns the color at a particular point
 *
 */
-(UIColor *) colorOfPoint:(CGPoint)point
{
    _thumbImage.hidden = YES;
    unsigned char pixel[4] = {0};
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pixel, 1, 1, 8, 4, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    CGContextTranslateCTM(context, -point.x, -point.y);
    
    [_pickerContainer.layer renderInContext:context];
    
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    CGFloat intensity = _intensitySlider.value/255.0;
    UIColor *color = [UIColor colorWithRed:pixel[0]/255.0
                                     green:pixel[1]/255.0
                                     blue:pixel[2]/255.0
                                     alpha:intensity];
    _thumbImage.hidden = NO;
    
    // Checking the selected color reside inside the color gamut
    if(pixel[3] > 0 && (pixel[0] > 0 || pixel[1] > 0 || pixel[2] > 0 ))
    {
        // Writing the color values to the peripheral
        [rgbModel writeColorWithRed:pixel[0] green:pixel[1] blue:pixel[2] intensity:_intensitySlider.value handler:^(BOOL success, NSError *error)
         {
             if (success)
             {
                 [self updateRGBValues];
             }
         }];
        _thumbImage.center = point ;
        [_currentColorLabel setBackgroundColor:color];   //showing the current selected color in the screen
    }
    return color;
}

@end
