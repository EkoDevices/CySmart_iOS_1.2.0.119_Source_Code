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

#import "GlucoseViewController.h"
#import "GlucoseModel.h"
#import "Constants.h"
#import "GlucoseContextVC.h"
#import "DropDownView.h"

#define CONTEXT_VC_ID                   @"contextVCID"
#define NO_RECORD                       @"No Record"

#define READ_LAST_RECORD_COMMAND        @"0106"
#define READ_ALL_REORDS_COMMAND         @"0101"
#define DELETE_ALL_STORED_RECORDS       @"0201"


/*!
 *  @class GlucoseViewController
 *
 *  @discussion Class to handle the user interactions and UI updates for glucose service
 *
 */

@interface GlucoseViewController () <DropDownDelegate, UITextFieldDelegate>
{
    GlucoseModel *mGlucoseModel;
    BOOL isCharacteritsticsFound;
    NSDictionary *selectedRecordDict;
    DropDownView *recordDropDown;
}


@property (weak, nonatomic) IBOutlet NSLayoutConstraint *glucoseImageViewHeightConstraint;

/* Data fields */
@property (weak, nonatomic) IBOutlet UILabel *recordingTimeLabel;
@property (weak, nonatomic) IBOutlet UILabel *typeLabel;
@property (weak, nonatomic) IBOutlet UILabel *sampleLocationLabel;
@property (weak, nonatomic) IBOutlet UILabel *concentrationValueLabel;
@property (weak, nonatomic) IBOutlet UILabel *selectRecordLabel;

/* Buttons */

@property (weak, nonatomic) IBOutlet UIButton *readLastRecordButton;
@property (weak, nonatomic) IBOutlet UIButton *readAllRecordButton;
@property (weak, nonatomic) IBOutlet UIButton *deleteAllRecordButton;
@property (weak, nonatomic) IBOutlet UIButton *additionalInfoButton;
@property (weak, nonatomic) IBOutlet UIButton *dropDownButton;

@property (weak, nonatomic) IBOutlet UITextField *selectedRecordNameTextfield;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *recordNameTextFieldWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *topViewHeightConstraint;


@end

@implementation GlucoseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
   
    // Do any additional setup after loading the view.
    [self initializeView];
    
    // Initialize glucose model
    [self initGlucoseModel];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:GLUCOSE];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        // stop receiving characteristic value when the user exits the screen
        [mGlucoseModel stopUpdate];
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
 *  @method initializeView
 *
 *  @discussion Method to optimize the UI for Ipad screens.
 *
 */

-(void) initializeView
{
    _additionalInfoButton.hidden = YES;
    _selectedRecordNameTextfield.delegate = self;
   
    if(UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        _glucoseImageViewHeightConstraint.constant += DEFAULT_SIZE_NORMALISATION_CONSTANT_FOR_IPAD; // Change Image size
        _recordNameTextFieldWidthConstraint.constant =  _recordNameTextFieldWidthConstraint.constant * 1.75;
        [self.view layoutIfNeeded];
    }
    
    if (!IS_IPHONE_4_OR_LESS) {
        _topViewHeightConstraint.constant = _topViewHeightConstraint.constant + 15.0;
        [self.view layoutIfNeeded];
    }
    
    CALayer *bottomLayer = [CALayer layer];
    bottomLayer.frame = CGRectMake(0.0, _selectedRecordNameTextfield.frame.size.height-1.0, _selectedRecordNameTextfield.frame.size.width, 1.0);
    bottomLayer.backgroundColor = BLUE_COLOR.CGColor;
    [_selectedRecordNameTextfield.layer addSublayer:bottomLayer];
    
    _selectedRecordNameTextfield.text = NO_RECORD;
}


/*!
 *  @method initGlucoseModel
 *
 *  @discussion Method to Discover the specified characteristic of a service.
 *
 */

-(void) initGlucoseModel
{
    if (!mGlucoseModel) {
        mGlucoseModel = [[GlucoseModel alloc] init];
    }
    [mGlucoseModel startDiscoverChar:^(BOOL success, NSError *error) {
        
        if (success)
        {
            // Get the characteristic values if found successfully
            isCharacteritsticsFound = YES;
            [mGlucoseModel setCharacteristicUpdates];
        }
        else
            isCharacteritsticsFound = NO;
    }];
}

/*!
 *  @method dropDownButtonClicked:
 *
 *  @discussion Method to handle the dropdown button action.
 *
 */
-(IBAction)dropDownButtonClicked:(UIButton *)sender{
    
    if (mGlucoseModel.recordNameArray.count > 0) {
        [self showDropDownWithButton:sender];
    }
 }

/*!
 *  @method showDropDownWithButton:
 *
 *  @discussion Method to handle the dropdown presentation
 *
 */

-(void) showDropDownWithButton:(UIButton *)dropDownButton{
    
    if (!dropDownButton.selected) {
       
        if (recordDropDown) {
            
            [recordDropDown removeFromSuperview];
            recordDropDown = nil;
        }
        
        recordDropDown = [[DropDownView alloc] initWithDelegate:self titles:mGlucoseModel.recordNameArray onButton:dropDownButton withFrame:_selectedRecordNameTextfield.frame];
        
        [recordDropDown showView];
        
    }else
    {
        [recordDropDown hideView];
    }
    
}


/*
 *  @method readLastButtonClicked:
 *
 *  @discussion Method to handle the read last record request
 *
 */

-(IBAction) readLastButtonClicked:(UIButton *)sender{
    
    if (isCharacteritsticsFound) {
        _readAllRecordButton.enabled = NO;
        _deleteAllRecordButton.enabled = NO;
        
        [mGlucoseModel updateCharacteristicWithHandler:^(BOOL success, NSError *error) {
            
            if (success)
            {
                if (mGlucoseModel.glucoseRecords.count > 0) {
                    NSDictionary *dataDict = [mGlucoseModel getGlucoseData:[mGlucoseModel.glucoseRecords lastObject]];
                    selectedRecordDict = dataDict;
                    [self updateGlucoseTextFieldsWithDataDict:dataDict];
                }
            }
            _readAllRecordButton.enabled = YES;
            _deleteAllRecordButton.enabled = YES;
            
            if (mGlucoseModel.recordNameArray.count > 0) {
                _selectedRecordNameTextfield.text = [mGlucoseModel.recordNameArray lastObject];
            }
        }];
        
        [mGlucoseModel writeRACPCharacteristicWithValueString:READ_LAST_RECORD_COMMAND];
    }
}

/*
 *  @method readAllButtonClicked:
 *
 *  @discussion Method to handle the read all records request
 *
 */
-(IBAction)readAllButtonClicked:(UIButton *)sender{
    
    if (isCharacteritsticsFound) {
        
        _readLastRecordButton.enabled = NO;
        _deleteAllRecordButton.enabled = NO;
        
        [mGlucoseModel updateCharacteristicWithHandler:^(BOOL success, NSError *error) {
            
            _readLastRecordButton.enabled = YES;
            _deleteAllRecordButton.enabled = YES;
            
            if (mGlucoseModel.glucoseRecords.count > 0) {
                NSDictionary *dataDict = [mGlucoseModel getGlucoseData:[mGlucoseModel.glucoseRecords lastObject]];
                selectedRecordDict = dataDict;
                [self updateGlucoseTextFieldsWithDataDict:dataDict];
            }
            
            if (mGlucoseModel.recordNameArray.count > 0) {
                _selectedRecordNameTextfield.text = [mGlucoseModel.recordNameArray lastObject];
            }

        }];
        [mGlucoseModel writeRACPCharacteristicWithValueString:READ_ALL_REORDS_COMMAND];
    }
}

/*
 *  @method deleteAllButtonClicked:
 *
 *  @discussion Method to handle delete all record request
 *
 */
-(IBAction)deleteAllButtonClicked:(UIButton *)sender{
    
    _readLastRecordButton.enabled = NO;
    _readAllRecordButton.enabled = NO;
    [mGlucoseModel removePreviousRecords];
    
    [mGlucoseModel updateCharacteristicWithHandler:^(BOOL success, NSError *error) {
        
        _readLastRecordButton.enabled = YES;
        _readAllRecordButton.enabled = YES;
        
        [self updateGlucoseTextFieldsWithDataDict:nil];

    }];
    [mGlucoseModel writeRACPCharacteristicWithValueString:DELETE_ALL_STORED_RECORDS];
}


/*
 *  @method clearButtonClicked:
 *
 *  @discussion Method to handle clear button click
 *
 */
-(IBAction)clearButtonClicked:(UIButton *)sender{
    
    [self updateGlucoseTextFieldsWithDataDict:nil];
}

/*
 *  @method additionalInfoButtonClicked:
 *
 *  @discussion Method to handle additional info button click
 *
 */
-(IBAction)additionalInfoButtonClicked:(id)sender{
    
    GlucoseContextVC *contextVC = [self.storyboard instantiateViewControllerWithIdentifier:CONTEXT_VC_ID];
    
    for (NSData *data in mGlucoseModel.contextInfoArray) {
        if ([[selectedRecordDict objectForKey:SEQUENCE_NUMBER] integerValue] == [[[mGlucoseModel getGlucoseContextInfoFromData:data] objectForKey:SEQUENCE_NUMBER] integerValue]) {
            contextVC.glucoseContextDict = [mGlucoseModel getGlucoseContextInfoFromData:data];
        }
    }

    [self.navigationController pushViewController:contextVC animated:YES];
}

/*
 *  @method updateGlucoseTextFieldsWithDataDict:
 *
 *  @discussion Method to update the textfields with data
 *
 */
-(void) updateGlucoseTextFieldsWithDataDict:(NSDictionary *)glucoseDataDict
{
    if (glucoseDataDict == nil) {
        
        // Clearing the labels
        _recordingTimeLabel.text = @"";
        _typeLabel.text = @"";
        _concentrationValueLabel.text = @"";
        _sampleLocationLabel.text = @"";
        _selectedRecordNameTextfield.text = NO_RECORD;
        
        // Clear the previous records
        [mGlucoseModel removePreviousRecords];
        _additionalInfoButton.hidden = YES;
    }
    else{
        
        // Update values in datafields
        
        _recordingTimeLabel.text = [glucoseDataDict objectForKey:BASE_TIME];
        _typeLabel.text = [glucoseDataDict objectForKey:TYPE];
        
        if ([[glucoseDataDict objectForKey:CONCENTRATION_VALUE] floatValue]) {
            _concentrationValueLabel.text = [NSString stringWithFormat:@"%@ %@",[glucoseDataDict objectForKey:CONCENTRATION_VALUE],[glucoseDataDict objectForKey:CONCENTRATION_UNIT]];
        }
        else
            _concentrationValueLabel.text = [NSString stringWithFormat:@"%@",[glucoseDataDict objectForKey:CONCENTRATION_VALUE]];
        
        _sampleLocationLabel.text = [glucoseDataDict objectForKey:SAMPLE_LOCATION];
        
        if ([[glucoseDataDict objectForKey:CONTEXT_INFO_PRESENT] boolValue]) {
            _additionalInfoButton.hidden = NO;
        }
        else{
            _additionalInfoButton.hidden = YES;
        }
    }
}

/*!
 *  @method deviceOrientationDidChange:
 *
 *  @discussion invoked when the device orientation did change
 *
 */
-(void)deviceOrientationDidChange:(NSNotification *)notification
{
    if ([UIDevice currentDevice].orientation != UIDeviceOrientationFaceUp)
    {
        if (_dropDownButton.selected)
        {
            if (recordDropDown)
            {
                [recordDropDown removeSubviews];
                recordDropDown = nil;
            }
            
            recordDropDown = [[DropDownView alloc] initWithDelegate:self titles:mGlucoseModel.recordNameArray onButton:_dropDownButton withFrame:_selectedRecordNameTextfield.frame];
            
            [recordDropDown showView];
        }
    }
}


#pragma mark - Drop Down delegate

/*
 *  @method dropDown: valueSelected: index:
 *
 *  @discussion Method invoked when a value is selected in dropdown
 *
 */
-(void)dropDown:(DropDownView*)dropDown valueSelected:(NSString*)value index:(int) index{
    
    _selectedRecordNameTextfield.text = value;
    NSDictionary *dataDict = [mGlucoseModel getGlucoseData:[mGlucoseModel.glucoseRecords objectAtIndex:index]];
    
    selectedRecordDict = dataDict;
    [self updateGlucoseTextFieldsWithDataDict:dataDict];
}


#pragma mark - UITextfield delegate


-(BOOL)textFieldShouldBeginEditing:(UITextField *)textField{
    
    if (mGlucoseModel.recordNameArray.count > 0) {
        [self showDropDownWithButton:_dropDownButton];
    }
    return NO;
}



@end
