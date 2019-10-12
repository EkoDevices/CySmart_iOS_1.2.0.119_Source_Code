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

#import "HealthThermometerVC.h"
#import "ThermometerModel.h"
#import "MyLineChart.h"
#import "Utilities.h"


/*!
 *  @class HealthThermometerVC
 *
 *  @discussion Class to handle the user interactions and UI updates for thermometer service
 *
 */
@interface HealthThermometerVC ()<lineChartDelegate>
{
    ThermometerModel *mThermometerModel;
    
    KLCPopup* kPopup;
    MyLineChart *myChart;
    NSMutableArray *healthDataArray;
    NSMutableArray *timeDataArray;
    NSDate *startTime;
    NSTimeInterval previousTimeInterval;
    float xAxisTimeInterval;
}

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *thermometerImageViewHeightConstraint;

/* Data fields */
@property (weak, nonatomic) IBOutlet UILabel *temperatureValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *sensorLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *temperatureUnitLabel;

@end

@implementation HealthThermometerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    healthDataArray = [NSMutableArray array];
    timeDataArray = [NSMutableArray array];
    
    [self initializeView];
    
    // initialize thermometer model
    [self initThermometerModel];
    
    startTime = [NSDate date];
    previousTimeInterval = 0;
    xAxisTimeInterval = 1.0;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:THERMOMETER];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIDeviceOrientationDidChangeNotification object:self];

    if (![self.navigationController.viewControllers containsObject:self])
    {
        [mThermometerModel stopUpdate];   // stop receiving characteristic value when the user exits the screen
        [kPopup dismiss:YES];
    }
}

/*!
 *  @method initializeView
 *
 *  @discussion Method to optimize the UI for Ipad screens.
 *
 */
-(void) initializeView
{
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        _thermometerImageViewHeightConstraint.constant += DEFAULT_SIZE_NORMALISATION_CONSTANT_FOR_IPAD; // Change image size
        [self.view layoutIfNeeded];
    }
}

/*!
 *  @method initThermometerModel
 *
 *  @discussion Method to Discover the specified characteristics of a service.
 *
 */
-(void) initThermometerModel
{
    if (!mThermometerModel)
    {
        mThermometerModel = [[ThermometerModel alloc] init];
    }
    [mThermometerModel startDiscoverChar:^(BOOL success, NSError *error) {
        
        if (success)
        {
            // Get the characteristic values if found successfully
            [self startUpdateCharacteristic];
        }
    }];
}


/*!
 *  @method startUpdateCharacteristic
 *
 *  @discussion Method to assign completion handler to get call back once the block has completed execution.
 *
 */


-(void) startUpdateCharacteristic
{
    [mThermometerModel updateCharacteristicWithHandler:^(BOOL success, NSError *error) {
        
        if (success)
        {
            @synchronized(mThermometerModel){
                // Handle the characteristic values if successfully received
                [self updateTemperature];
            }
        }
    }];
}

/*!
 *  @method updateTemperature
 *
 *  @discussion Method to Update UI when the characteristic’s value changes.
 *
 */
-(void) updateTemperature
{
    // Update datafields
    if ([[NSString stringWithFormat:@"%@", mThermometerModel.tempStringValue] isEqualToString:@"(null)"]) {
        _temperatureValueLabel.text = @"";
    }else{
        _temperatureValueLabel.text =[NSString stringWithFormat:@"%@", mThermometerModel.tempStringValue];
        _temperatureUnitLabel.text = [NSString stringWithFormat:@"%@", mThermometerModel.mesurementType];
    }
    
    if (nil == mThermometerModel.tempType) {
        _sensorLocationLabel.text = @"---";
    } else {
        _sensorLocationLabel.text = [NSString stringWithFormat:@"%@",mThermometerModel.tempType];
    }
    
    // Handling the values for graph update

    if([mThermometerModel.tempStringValue floatValue])
    {
        NSTimeInterval timeInterval = fabs([startTime timeIntervalSinceNow]);
        [timeDataArray addObject:@(timeInterval)];
        
        if (previousTimeInterval == 0)
        {
            previousTimeInterval = timeInterval;
        }
        
        if (timeInterval > previousTimeInterval)
        {
            xAxisTimeInterval = timeInterval - previousTimeInterval;
        }
        
        if ([_temperatureUnitLabel.text isEqualToString:@"°F"])
        {
            float celciusValue = ([mThermometerModel.tempStringValue floatValue] - 32) * 5 / 9;
            [healthDataArray addObject:@(celciusValue)];
        }
        else
        {
            [healthDataArray addObject:@([mThermometerModel.tempStringValue floatValue])];
        }
        
        if(myChart && kPopup.isShowing)
        {
            [myChart setXaxisScaleWithValue:nearbyintf(xAxisTimeInterval)];
            [self checkGraphPointsCount];
            [myChart updateLineGraph:timeDataArray Y:healthDataArray ];
        }
        previousTimeInterval = timeInterval;
    }
}


/*!
 *  @method showGraphPopUp:
 *
 *  @discussion Method to show Graph .
 *
 */

-(IBAction)showGraphPopUp:(id)sender
{
    if (myChart) {
        myChart = nil;
    }
    myChart =[[MyLineChart alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height/2.0)];
    myChart.graphTitleLabel.text = TEMPERATURE_GRAPH_HEADER;
    [myChart addXLabel:TIME yLabel:TEMPERATURE_YLABEL];
    [myChart setXaxisScaleWithValue:nearbyintf(xAxisTimeInterval)];
    myChart.delegate = self;
    
    if([timeDataArray count])
    {
        [self checkGraphPointsCount];
        [myChart updateLineGraph:timeDataArray Y:healthDataArray ];
        KLCPopupLayout layout = KLCPopupLayoutMake(KLCPopupHorizontalLayoutCenter,
                                                   KLCPopupVerticalLayoutBottom);
        
        kPopup = [KLCPopup popupWithContentView:myChart
                                       showType:KLCPopupShowTypeBounceIn
                                    dismissType:KLCPopupDismissTypeBounceOut
                                       maskType:KLCPopupMaskTypeDimmed
                       dismissOnBackgroundTouch:YES
                          dismissOnContentTouch:NO];
        
        [kPopup showWithLayout:layout];
    }
    else
        [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"graphDataNotAvailableAlert")];
}


/*!
 *  @method checkGraphPointsCount
 *
 *  @discussion Method to check the graph plot points
 *
 */
-(void) checkGraphPointsCount{
    
    if (timeDataArray.count > MAX_GRAPH_POINTS) {
        timeDataArray = [[timeDataArray subarrayWithRange:NSMakeRange(timeDataArray.count - MAX_GRAPH_POINTS,MAX_GRAPH_POINTS)] mutableCopy];
        myChart.chartView.setXmin = YES;
    }else{
        myChart.chartView.setXmin = NO;
    }
    
    if (healthDataArray.count > MAX_GRAPH_POINTS) {
        healthDataArray = [[healthDataArray subarrayWithRange:NSMakeRange(healthDataArray.count - MAX_GRAPH_POINTS,MAX_GRAPH_POINTS)] mutableCopy];
    }
}


/*!
 *  @method shareScreen:
 *
 *  @discussion Method to share the screen
 *
 */

-(void)shareScreen:(id)sender
{
    UIImage *screenShot = [Utilities captureScreenShot];
    [kPopup dismiss:YES];
    
    CGRect rect = [(UIButton *)sender frame];
    CGRect newRect = CGRectMake(rect.origin.x, rect.origin.y + (self.view.frame.size.height/2), rect.size.width, rect.size.height);
    [self showActivityPopover:[self saveImage:screenShot] Rect:newRect excludedActivities:nil];
}

/*!
 *  @method deviceOrientationDidChange:
 *
 *  @discussion invoked when the device orientation did change
 *
 */
-(void)deviceOrientationDidChange:(NSNotification *)notification
{
    if (IS_IPAD && kPopup.isShowing && [UIDevice currentDevice].orientation != UIDeviceOrientationFaceUp)
    {
        [kPopup dismiss:NO];
        [self showGraphPopUp:nil];
    }
}


@end
