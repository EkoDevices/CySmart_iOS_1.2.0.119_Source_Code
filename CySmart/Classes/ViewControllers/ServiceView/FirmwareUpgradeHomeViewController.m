/*
 * Copyright Cypress Semiconductor Corporation, 2015-2018 All rights reserved.
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

#import <QuartzCore/QuartzCore.h>
#import "FirmwareUpgradeHomeViewController.h"
#import "FirmwareFileSelectionViewController.h"
#import "OTAFileParser.h"
#import "BootLoaderServiceModel.h"
#import "Utilities.h"
#import "CyCBManager.h"

#define BACK_BUTTON_ALERT_TAG  200

#define UPGRADE_RESUME_ALERT_TAG 201
#define UPGRADE_STOP_ALERT_TAG  202

#define APP_UPGRADE_BTN_TAG 203
#define APP_STACK_UPGRADE_COMBINED_BTN_TAG  204
#define APP_STACK_UPGRADE_SEPARATE_BTN_TAG  205

#define WRITE_WITH_RESP_MAX_DATA_SIZE   133
#define WRITE_NO_RESP_MAX_DATA_SIZE   300

#define FIRMWARE_SELECTION_SEGUE    @"firmwareSelectionPageSegue"

/*!
 *  @class FirmwareUpgradeHomeViewController
 *
 *  @discussion Class to handle user interaction, UI update and firmware upgrade
 *
 */

@interface FirmwareUpgradeHomeViewController () <FirmwareFileSelectionDelegate, UIAlertViewDelegate>
{
    IBOutlet UIButton *applicationUpgradeBtn;
    IBOutlet UIButton *applicationAndStackUpgradeCombinedBtn;
    IBOutlet UIButton *applicationAndStackUpgradeSeparateBtn;
    IBOutlet UIButton *startStopUpgradeBtn;
    
    IBOutlet UILabel *currentOperationLabel;
    IBOutlet UILabel *firmwareFile1NameLabel;
    IBOutlet UILabel *firmwareFile2NameLabel;
    IBOutlet UILabel *firmwareFile1UpgradePercentageLabel;
    IBOutlet UILabel *firmwareFile2UpgradePercentageLabel;
    
    IBOutlet UIView *firmwareFile1NameContainerView;
    IBOutlet UIView *firmwareFile2NameContainerView;
    
    //Constraint Outlets for modifying UI for screen fit
    IBOutlet NSLayoutConstraint *titleLabelTopSpaceConstraint;
    IBOutlet NSLayoutConstraint *firstBtnTopSpaceConstraint;
    IBOutlet NSLayoutConstraint *secondBtnTopSpaceonstraint;
    IBOutlet NSLayoutConstraint *thirdBtnTopSpaceConstraint;
    IBOutlet NSLayoutConstraint *statusLabelTopSpaceConstraint;
    IBOutlet NSLayoutConstraint *progressLabel1TopSpaceConstraint;
    IBOutlet NSLayoutConstraint *progressLabel2TopSpaceConstraint;
    
    IBOutlet NSLayoutConstraint *firmwareUpgradeProgressLabel1TrailingSpaceConstraint;
    IBOutlet NSLayoutConstraint *firmwareUpgradeProgressLabel2TrailingSpaceConstraint;
    
    BootLoaderServiceModel *bootloaderModel;
    BOOL isBootloaderCharacteristicFound, isWritingFile1;
    
    NSArray *firmwareFileList, *fileRowDataArray;
    NSMutableArray *currentRowDataArray;
    uint32_t currentRowDataAddress;
    uint32_t currentRowDataCRC32;
    
    NSDictionary *fileHeaderDict;
    NSDictionary *appInfoDict;
    OTAMode firmwareUpgradeMode;
    int currentRowNumber, currentIndex;
    NSString *currentArrayID;
    int fileWritingProgress;
    int maxDataSize;
    ActiveApp activeApp; // Active Application for Dual Application Bootloader projects
    NSData *securityKey; // Security Key for CYACD files
}

@end

@implementation FirmwareUpgradeHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self initView];
    [self initServiceModel];
    
    activeApp = NoChange; // Do nothing by default
    maxDataSize = WRITE_NO_RESP_MAX_DATA_SIZE;
    
    isWritingFile1 = YES;
    
    // Check for multiple files
    if ([[CyCBManager sharedManager] bootloaderFileArray] != nil) {
        [self.view layoutIfNeeded];
        [self firmwareFilesSelected:[[CyCBManager sharedManager] bootloaderFileArray] upgradeMode:app_stack_separate securityKey:[[CyCBManager sharedManager] bootloaderSecurityKey] activeApp:[[CyCBManager sharedManager] bootloaderActiveApp]];
        
        firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = 0.0;
        firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = firmwareFile2NameContainerView.frame.size.width;
        
        [firmwareFile1UpgradePercentageLabel setHidden:NO];
        [firmwareFile1UpgradePercentageLabel setText:@"100 %"];
        
        [firmwareFile2UpgradePercentageLabel setHidden:NO];
        [firmwareFile2UpgradePercentageLabel setText:@"0 %"];
        
        UIAlertView *updateAlert = [[UIAlertView alloc] initWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAUpgradeResumeConfirmMessage") delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        updateAlert.tag = UPGRADE_RESUME_ALERT_TAG;
        [updateAlert show];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:FIRMWARE_UPGRADE];
    
    // Adding custom back button
    UIBarButtonItem * backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:BACK_BUTTON_IMAGE] landscapeImagePhone:[UIImage imageNamed:BACK_BUTTON_IMAGE] style:UIBarButtonItemStyleDone target:self action:@selector(backButtonPressed)];
    self.navigationItem.leftBarButtonItem = backButton;
    self.navigationItem.leftBarButtonItem.imageInsets = UIEdgeInsetsMake(0, -5, 0, 0);
}

-(void) backButtonPressed
{
    if (!startStopUpgradeBtn.hidden)
    {
        UIAlertView *upgradeInterruptAlert = [[UIAlertView alloc] initWithTitle:APP_NAME message:LOCALIZEDSTRING(@"upgradeProgressAlert") delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        upgradeInterruptAlert.tag = BACK_BUTTON_ALERT_TAG;
        [upgradeInterruptAlert show];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void) viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    if (![self.navigationController.viewControllers containsObject:self])
    {
        [bootloaderModel stopUpdate];
    }
    
    // removing the custom back button
    if (self.navigationItem.leftBarButtonItem != nil)
    {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

/*!
 *  @method initView
 *
 *  @discussion Setup/reset the view
 *
 */
- (void) initView
{
    applicationAndStackUpgradeCombinedBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    applicationAndStackUpgradeSeparateBtn.titleLabel.textAlignment = NSTextAlignmentCenter;
    
    //Setting button view properties programmatically.
    applicationUpgradeBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    applicationUpgradeBtn.layer.shadowOpacity = .5;
    applicationUpgradeBtn.layer.shadowRadius = 3;
    applicationUpgradeBtn.layer.shadowOffset = CGSizeZero;
    [applicationUpgradeBtn setBackgroundColor:[UIColor whiteColor]];
    [applicationUpgradeBtn setSelected:NO];
    
    applicationAndStackUpgradeCombinedBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    applicationAndStackUpgradeCombinedBtn.layer.shadowOpacity = 0.5;
    applicationAndStackUpgradeCombinedBtn.layer.shadowRadius = 3;
    applicationAndStackUpgradeCombinedBtn.layer.shadowOffset = CGSizeZero;
    [applicationAndStackUpgradeCombinedBtn setBackgroundColor:[UIColor whiteColor]];
    [applicationAndStackUpgradeCombinedBtn setSelected:NO];
    
    applicationAndStackUpgradeSeparateBtn.layer.shadowColor = [UIColor blackColor].CGColor;
    applicationAndStackUpgradeSeparateBtn.layer.shadowOpacity = 0.5;
    applicationAndStackUpgradeSeparateBtn.layer.shadowRadius = 3;
    applicationAndStackUpgradeSeparateBtn.layer.shadowOffset = CGSizeZero;
    [applicationAndStackUpgradeSeparateBtn setBackgroundColor:[UIColor whiteColor]];
    [applicationAndStackUpgradeSeparateBtn setSelected:NO];
    
    [startStopUpgradeBtn setHidden:YES];
    [startStopUpgradeBtn setSelected:NO];
    [firmwareFile1NameContainerView setHidden:YES];
    [firmwareFile2NameContainerView setHidden:YES];
    [currentOperationLabel setHidden:YES];
    [firmwareFile1UpgradePercentageLabel setHidden:YES];
    [firmwareFile2UpgradePercentageLabel setHidden:YES];
    firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = firmwareFile1NameContainerView.frame.size.width;
    firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = firmwareFile2NameContainerView.frame.size.width;
    
    if (self.view.frame.size.height <= 480) {
        titleLabelTopSpaceConstraint.constant = 15;
        firstBtnTopSpaceConstraint.constant = 15;
        secondBtnTopSpaceonstraint.constant = 15;
        thirdBtnTopSpaceConstraint.constant = 15;
        statusLabelTopSpaceConstraint.constant = 15;
        progressLabel2TopSpaceConstraint.constant = 10;
        [self.view layoutIfNeeded];
    }
}

#pragma mark - Button Events

/*!
 *  @method applicationUpgradeBtnTouched:
 *
 *  @discussion Method - Common Action method for the 3 upgrade mode button
 *
 */
- (IBAction)applicationUpgradeBtnTouched:(UIButton *)sender
{
    if (!startStopUpgradeBtn.selected)
    {
        [self performSegueWithIdentifier:FIRMWARE_SELECTION_SEGUE sender:sender];
    }
}

/*!
 *  @method startStopBtnTouched:
 *
 *  @discussion Method - Action method of upgrade start/stop button
 *
 */
- (IBAction)startStopBtnTouched:(UIButton *)sender
{
    if (sender.selected)
    {
        UIAlertView *stopUpdateAlert = [[UIAlertView alloc] initWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAUpgradeCancelConfirmMessage") delegate:self cancelButtonTitle:@"No" otherButtonTitles:@"Yes", nil];
        stopUpdateAlert.tag = UPGRADE_STOP_ALERT_TAG;
        [stopUpdateAlert show];
    }
    else
    {
        [sender setSelected:YES];
        if (firmwareFileList)
        {
            [currentOperationLabel setText:LOCALIZEDSTRING(@"OTAUpgradeInProgressMessage")];
            [firmwareFile1UpgradePercentageLabel setHidden:NO];
            if (firmwareUpgradeMode == app_stack_separate)
            {
                [firmwareFile2UpgradePercentageLabel setHidden:NO];
                [firmwareFile2UpgradePercentageLabel setText:@"0 %"];
            }
            
            if (isWritingFile1)
            {
                [firmwareFile1UpgradePercentageLabel setText:@"0 %"];
                [self startParsingFirmwareFile:[firmwareFileList objectAtIndex:0]];
            }
            else
            {
                [firmwareFile2UpgradePercentageLabel setText:@"0 %"];
                [self startParsingFirmwareFile:[firmwareFileList objectAtIndex:1]];
            }
        }
    }
}

#pragma mark - Send files for parsing

/*!
 *  @method startParsingFirmwareFile:
 *
 *  @discussion Method for handling the file parsing call and callback
 *
 */
- (void) startParsingFirmwareFile:(NSDictionary *)firmwareFile {
    OTAFileParser *fileParser = [OTAFileParser new];
    NSString *fileName = [firmwareFile valueForKey:FILE_NAME];
    NSString *filePath = [firmwareFile valueForKey:FILE_PATH];
    if ([[fileName pathExtension] caseInsensitiveCompare:@"cyacd2"] == NSOrderedSame) {
        [fileParser parseFirmwareFileWithName_v1:fileName path:filePath onFinish:^(NSMutableDictionary *header, NSDictionary *appInfo, NSArray *rowData, NSError *error) {
            if(error) {
                [Utilities alertWithTitle:APP_NAME message:error.localizedDescription];
                [self initView];
            } else if (header && rowData) {
                fileHeaderDict = header;
                appInfoDict = appInfo;
                fileRowDataArray = rowData;
                [self initializeFileTransfer_v1];
            }
        }];
    } else {
        [fileParser parseFirmwareFileWithName:fileName path:filePath onFinish:^(NSMutableDictionary *header, NSArray *rowData, NSArray *rowIdArray, NSError *error) {
            if(error) {
                [Utilities alertWithTitle:APP_NAME message:error.localizedDescription];
                [self initView];
            } else if (header && rowData && rowIdArray) {
                fileHeaderDict = header;
                fileRowDataArray = rowData;
                [self initializeFileTransfer];
            }
        }];
    }
}

#pragma mark - FirmwareFileSelection delegate methods

- (void)firmwareFilesSelected:(NSArray *)fileList upgradeMode:(OTAMode)upgradeMode securityKey:(NSData *)securityKey activeApp:(ActiveApp)activeApp {
    self->activeApp = activeApp;
    self->securityKey = securityKey;
    if (fileList) {
        firmwareFileList = [[NSArray alloc] initWithArray:fileList];
        firmwareUpgradeMode = upgradeMode;
        
        [self initView];
        [startStopUpgradeBtn setHidden:NO];
        [currentOperationLabel setHidden:NO];
        [firmwareFile1NameContainerView setHidden:NO];
        firmwareFile1NameLabel.text = [[[fileList objectAtIndex:0] valueForKey:FILE_NAME] stringByDeletingPathExtension];
        
        if (upgradeMode == app_stack_separate) {
            [firmwareFile2NameContainerView setHidden:NO];
            [applicationAndStackUpgradeSeparateBtn setSelected:YES];
            [applicationAndStackUpgradeSeparateBtn setBackgroundColor:[UIColor colorWithRed:12.0f/255.0f green:55.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
            firmwareFile2NameLabel.text = [[[fileList objectAtIndex:1] valueForKey:FILE_NAME] stringByDeletingPathExtension];
            currentOperationLabel.text = LOCALIZEDSTRING(@"OTAFileSelectedMessage");
        } else {
            currentOperationLabel.text = LOCALIZEDSTRING(@"OTAFileSelectedMessage");
            if(upgradeMode == app_upgrade)
            {
                [applicationUpgradeBtn setSelected:YES];
                [applicationUpgradeBtn setBackgroundColor:[UIColor colorWithRed:12.0f/255.0f green:55.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
            }else{
                [applicationAndStackUpgradeCombinedBtn setSelected:YES];
                [applicationAndStackUpgradeCombinedBtn setBackgroundColor:[UIColor colorWithRed:12.0f/255.0f green:55.0f/255.0f blue:123.0f/255.0f alpha:1.0f]];
            }
        }
        
        if ([[CyCBManager sharedManager] bootloaderFileArray] == nil) {
            [self startStopBtnTouched:startStopUpgradeBtn];
        }
    }
}

#pragma mark - Segue Methods
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    UIButton * senderBtn = (UIButton *)sender;
    
    FirmwareFileSelectionViewController * destView = [segue destinationViewController];
    destView.delegate = self;
    if (senderBtn.tag == APP_UPGRADE_BTN_TAG) {
        destView.upgradeMode = app_upgrade;
    }else if (senderBtn.tag == APP_STACK_UPGRADE_COMBINED_BTN_TAG){
        destView.upgradeMode = app_stack_combined;
    }else if (senderBtn.tag == APP_STACK_UPGRADE_SEPARATE_BTN_TAG){
        destView.upgradeMode = app_stack_separate;
    }
}

#pragma mark - OTA Upgrade

/*!
 *  @method initServiceModel
 *
 *  @discussion Method to initialize the bootloader model
 *
 */

-(void) initServiceModel
{
    if (!bootloaderModel)
    {
        bootloaderModel = [[BootLoaderServiceModel alloc] init];
    }
    
    [bootloaderModel discoverCharacteristicsWithCompletionHandler:^(BOOL success, NSError *error)
     {
         if (success)
         {
             isBootloaderCharacteristicFound = YES;
             if (bootloaderModel.isWriteWithoutResponseSupported)
             {
                 maxDataSize = WRITE_NO_RESP_MAX_DATA_SIZE;
             }
             else
             {
                 maxDataSize = WRITE_WITH_RESP_MAX_DATA_SIZE;
             }
         }
     }];
}

/*!
 *  @method initializeFileTransfer
 *
 *  @discussion Begins file transter
 *
 */
-(void) initializeFileTransfer {
    if (isBootloaderCharacteristicFound) {
        currentIndex = 0;
        [self registerForBootloaderCharacteristicNotifications];
        
        bootloaderModel.fileVersion = [[fileHeaderDict objectForKey:FILE_VERSION] integerValue];
        bootloaderModel.isDualAppBootloaderAppValid = NO;
        bootloaderModel.isDualAppBootloaderAppActive = NO;
        
        // Set checksum type
        if (CHECKSUM_TYPE_CRC == [[fileHeaderDict objectForKey:CHECKSUM_TYPE] integerValue]) {
            [bootloaderModel setCheckSumType:CRC_16];
        } else{
            [bootloaderModel setCheckSumType:CHECK_SUM];
        }
        
        // Write ENTER_BOOTLOADER command
        NSMutableDictionary *dataDict = [NSMutableDictionary new];
        unsigned short dataLength = 0;
        if (securityKey) {
            [dataDict setObject:securityKey forKey:SECURITY_KEY];
            dataLength = (unsigned short)securityKey.length;
        }
        NSData *data = [bootloaderModel createPacketWithCommandCode:ENTER_BOOTLOADER dataLength:dataLength data:dataDict];
        [bootloaderModel writeCharacteristicValueWithData:data command:ENTER_BOOTLOADER];
    }
}

/*!
 *  @method initializeFileTransfer_v1
 *
 *  @discussion Method to begin file transter (CYACD2)
 *
 */
-(void) initializeFileTransfer_v1 {
    if (isBootloaderCharacteristicFound) {
        currentIndex = 0;
        [self registerForBootloaderCharacteristicNotifications_v1];
        
        bootloaderModel.fileVersion = [[fileHeaderDict objectForKey:FILE_VERSION] integerValue];
        
        // Set checksum type
        if ([[fileHeaderDict objectForKey:CHECKSUM_TYPE] integerValue]) {
            [bootloaderModel setCheckSumType:CRC_16];
        } else {
            [bootloaderModel setCheckSumType:CHECK_SUM];
        }
        
        [self sendEnterBootloaderCmd];
    }
}

/*!
 *  @method handleCharacteristicUpdates
 *
 *  @discussion Method to handle the characteristic value updates
 *
 */
-(void) registerForBootloaderCharacteristicNotifications
{
    [bootloaderModel enableNotificationForBootloaderCharacteristicAndSetNotificationHandler:^(NSError *error, id command, unsigned char otaError)
     {
         if (nil == error)
         {
             [self handleResponseForCommand:command error:otaError];
         }
     }];
}

/*!
 *  @method handleCharacteristicUpdates_v1
 *
 *  @discussion Method to handle characteristic value updates
 *
 */
-(void) registerForBootloaderCharacteristicNotifications_v1
{
    [bootloaderModel enableNotificationForBootloaderCharacteristicAndSetNotificationHandler:^(NSError *error, id command, unsigned char otaError)
     {
         if (nil == error)
         {
             [self handleResponseForCommand_v1:command error:otaError];
         }
     }];
}

- (void)sendEnterBootloaderCmd {
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:[fileHeaderDict objectForKey:PRODUCT_ID] forKey:PRODUCT_ID];
    NSData *data = [bootloaderModel createPacketWithCommandCode_v1:ENTER_BOOTLOADER dataLength:4 data:dataDict];
    [bootloaderModel writeCharacteristicValueWithData:data command:ENTER_BOOTLOADER];
}

- (void)sendGetAppStatusCmd {
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:@(activeApp) forKey:ACTIVE_APP];
    NSData *commandData = [bootloaderModel createPacketWithCommandCode:GET_APP_STATUS dataLength:1 data:dataDict];
    [bootloaderModel writeCharacteristicValueWithData:commandData command:GET_APP_STATUS];
}

- (void)sendGetFlashSizeCmd {
    NSDictionary *rowDataDict = [fileRowDataArray objectAtIndex:currentIndex];
    NSString *arrayID = [rowDataDict objectForKey:ARRAY_ID];
    currentArrayID = arrayID;
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:arrayID forKey:FLASH_ARRAY_ID];
    NSData *data = [bootloaderModel createPacketWithCommandCode:GET_FLASH_SIZE dataLength:1 data:dataDict];
    [bootloaderModel writeCharacteristicValueWithData:data command:GET_FLASH_SIZE];
}

- (void)sendVerifyRowCmd {
    NSDictionary *rowDataDict = [fileRowDataArray objectAtIndex:currentIndex];
    NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[rowDataDict objectForKey:ARRAY_ID], FLASH_ARRAY_ID, @(currentRowNumber), FLASH_ROW_NUMBER, nil];
    NSData *data = [bootloaderModel createPacketWithCommandCode:VERIFY_ROW dataLength:3 data:dataDict];
    [bootloaderModel writeCharacteristicValueWithData:data command:VERIFY_ROW];
}

- (void)sendVerifyChecksumCmd {
    NSData *data = [bootloaderModel createPacketWithCommandCode:VERIFY_CHECKSUM dataLength:0 data:nil];
    [bootloaderModel writeCharacteristicValueWithData:data command:VERIFY_CHECKSUM];
}

- (void)sendSetActiveAppCmd {
    NSDictionary *dataDict = [NSDictionary dictionaryWithObject:@(activeApp) forKey:ACTIVE_APP];
    NSData *data = [bootloaderModel createPacketWithCommandCode:SET_ACTIVE_APP dataLength:1 data:dataDict];
    [bootloaderModel writeCharacteristicValueWithData:data command:SET_ACTIVE_APP];
}

- (void)sendExitBootloaderCmd {
    NSData *data = [bootloaderModel createPacketWithCommandCode:EXIT_BOOTLOADER dataLength:0 data:nil];
    [bootloaderModel writeCharacteristicValueWithData:data command:EXIT_BOOTLOADER];
}

/*!
 *  @method handleResponseForCommand:error:
 *
 *  @discussion Method to handle the file tranfer with the response from the device
 *
 */
-(void) handleResponseForCommand:(id)command error:(unsigned char)error {
    if (SUCCESS == error) {
        if ([command isEqual:@(ENTER_BOOTLOADER)]) {
            // Compare siliconID and siliconRev
            if ([[[fileHeaderDict objectForKey:SILICON_ID] lowercaseString] isEqualToString:bootloaderModel.siliconIDString] && [[fileHeaderDict objectForKey:SILICON_REV] isEqualToString:bootloaderModel.siliconRevString]) {
                if (NoChange != activeApp) {
                    [self sendGetAppStatusCmd];
                } else {
                    [self sendGetFlashSizeCmd];
                }
            } else {
                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTASiliconIDMismatchMessage")];
                // Reset view in case of error
                [self initView];
            }
        } else if ([command isEqual:@(GET_APP_STATUS)]) {
            if (currentIndex == 0) {
                // The 1st time the GetAppStatus is called
                if (bootloaderModel.isDualAppBootloaderAppActive) {
                    [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAProgrammingOfActiveAppIsNotAllowedError")];
                    [self initView];
                } else {
                    [self sendGetFlashSizeCmd];
                }
            } else if (currentIndex == fileRowDataArray.count){
                // The 2nd time the GetAppStatus is called
                if (bootloaderModel.isDualAppBootloaderAppValid) { // It looks strange but it is so. The same logic is used by CySmart PC Tool.
                    [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAInvalidActiveAppProgrammedError")];
                    [self initView];
                } else {
                    [self sendSetActiveAppCmd];
                }
            }
        } else if ([command isEqual:@(GET_FLASH_SIZE)]) {
            [self startProgrammingDataRowAtIndex:currentIndex];
        } else if ([command isEqual:@(SEND_DATA)]) {
            if (bootloaderModel.isSendRowDataSuccess) {
                [self programDataRowAtIndex:currentIndex];
            } else {
                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTASendDataCommandFailed")];
            }
        } else if ([command isEqual:@(PROGRAM_ROW)]) {
            // Check row check sum
            if (bootloaderModel.isProgramRowDataSuccess) {
                [self sendVerifyRowCmd];
            } else {
                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAWritingFailedMessage")];
                [self initView];
            }
        } else if ([command isEqual:@(VERIFY_ROW)]) {
            // Compare checksum received from the device and the one from the file row
            NSDictionary *rowDataDict = [fileRowDataArray objectAtIndex:currentIndex];
            
            uint8_t rowChecksum = [Utilities getIntegerFromHexString:[rowDataDict objectForKey:CHECKSUM_OTA]];
            uint8_t arrayID = [Utilities getIntegerFromHexString:[rowDataDict objectForKey:ARRAY_ID]];
            uint16_t rowNumber = [Utilities getIntegerFromHexString:[rowDataDict objectForKey:ROW_NUMBER]];
            uint16_t dataLength = [Utilities getIntegerFromHexString:[rowDataDict objectForKey:DATA_LENGTH]];
            
            uint8_t sum = rowChecksum + arrayID + rowNumber + (rowNumber >> 8) + dataLength + (dataLength >> 8);
            if (sum == bootloaderModel.checksum) {
                currentIndex++;
                
                // Update UI with file writing progress
                float percentage = ((float) currentIndex/fileRowDataArray.count) * 100;
                
                fileWritingProgress = (firmwareFile1NameContainerView.frame.size.width * currentIndex)/fileRowDataArray.count;
                if (isWritingFile1) {
                    firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = firmwareFile1NameContainerView.frame.size.width - fileWritingProgress;
                    firmwareFile1UpgradePercentageLabel.text = [NSString stringWithFormat:@"%d %%",(int)percentage];
                } else {
                    firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = firmwareFile2NameContainerView.frame.size.width - fileWritingProgress;
                    firmwareFile2UpgradePercentageLabel.text = [NSString stringWithFormat:@"%d %%",(int)percentage];
                }
                
                [UIView animateWithDuration:0.5 animations:^{
                    [self.view layoutIfNeeded];
                }];
                
                // Writing next line from file
                if (currentIndex < fileRowDataArray.count) {
                    [self startProgrammingDataRowAtIndex:currentIndex];
                } else {
                    if (NoChange != activeApp) {
                        [self sendGetAppStatusCmd];
                    } else {
                        [self sendVerifyChecksumCmd];
                    }
                }
            } else {
                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAChecksumMismatchMessage")];
                [self initView];
                currentIndex = 0;
            }
        } else if ([command isEqual:@(VERIFY_CHECKSUM)]) {
            if (bootloaderModel.isAppValid) {
                [currentOperationLabel setText:LOCALIZEDSTRING(@"OTAUpgradeCompletedMessage")];
                
                if (app_stack_separate == firmwareUpgradeMode && isWritingFile1) {
                    [[CyCBManager sharedManager] setBootloaderFileArray:firmwareFileList];
                    [[CyCBManager sharedManager] setBootloaderSecurityKey:securityKey];
                    [[CyCBManager sharedManager] setBootloaderActiveApp:activeApp];
                    [[UIApplication sharedApplication] cancelAllLocalNotifications];
                    UILocalNotification *n1 = [[UILocalNotification alloc] init];
                    n1.fireDate = [NSDate dateWithTimeIntervalSinceNow: 5];
                    n1.alertBody = LOCALIZEDSTRING(@"OTAAppUgradePendingMessage");
                    [[UIApplication sharedApplication] scheduleLocalNotification: n1];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:LOCALIZEDSTRING(@"OTAUpgradeStatus")];
                } else {
                    [[UIApplication sharedApplication] cancelAllLocalNotifications];
                    UILocalNotification *n1 = [[UILocalNotification alloc] init];
                    n1.fireDate = [NSDate dateWithTimeIntervalSinceNow: 5];
                    n1.alertBody = LOCALIZEDSTRING(@"OTAUpgradeCompletedMessage");
                    [[UIApplication sharedApplication] scheduleLocalNotification: n1];
                }
                
                [self sendExitBootloaderCmd];
            } else {
                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAInvalidApplicationMessage")];
                [self initView];
                currentIndex = 0;
            }
        } else if ([command isEqual:@(SET_ACTIVE_APP)]) {
            [[UIApplication sharedApplication] cancelAllLocalNotifications];
            UILocalNotification *n1 = [[UILocalNotification alloc] init];
            n1.fireDate = [NSDate dateWithTimeIntervalSinceNow: 5];
            n1.alertBody = LOCALIZEDSTRING(@"OTAUpgradeCompletedMessage");
            [[UIApplication sharedApplication] scheduleLocalNotification: n1];
            
            [self sendExitBootloaderCmd];
        }
    } else {
        [Utilities alertWithTitle:APP_NAME message:[bootloaderModel errorMessageForErrorCode:error]];
        [self initView];
    }
}

/*!
 *  @method handleResponseForCommand_v1:error:
 *
 *  @discussion Method to handle the file tranfer with the response from the device
 *
 */
-(void) handleResponseForCommand_v1:(id)command error:(unsigned char)error {
    if (SUCCESS == error) {
        if ([command isEqual:@(ENTER_BOOTLOADER)]) {
            // Compare Silicon ID and Silicon Rev string
            if ([[[fileHeaderDict objectForKey:SILICON_ID] lowercaseString] isEqualToString:bootloaderModel.siliconIDString] && [[fileHeaderDict objectForKey:SILICON_REV] isEqualToString:bootloaderModel.siliconRevString]) {
                /* Send SET_APP_METADATA command */
                uint8_t appID = [[fileHeaderDict objectForKey:APP_ID] unsignedCharValue];
                
                uint32_t appStart = 0xFFFFFFFF;
                uint32_t appSize = 0;
                
                if (appInfoDict) {
                    appStart = [appInfoDict[APPINFO_APP_START] unsignedIntValue];
                    appSize = [appInfoDict[APPINFO_APP_SIZE] unsignedIntValue];
                } else {
                    for (NSDictionary *rowDict in fileRowDataArray) {
                        if (RowTypeData == [[rowDict objectForKey:ROW_TYPE] unsignedCharValue]) {
                            uint32_t addr = [[rowDict objectForKey:ADDRESS] unsignedIntValue];
                            if (addr < appStart) {
                                appStart = addr;
                            }
                            appSize += [[rowDict objectForKey:DATA_LENGTH] unsignedIntValue];
                        }
                    }
                }
                
                NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedChar:appID], APP_ID, [NSNumber numberWithUnsignedInt:appStart], APP_META_APP_START, [NSNumber numberWithUnsignedInt:appSize], APP_META_APP_SIZE, nil];
                NSData *data = [bootloaderModel createPacketWithCommandCode_v1:SET_APP_METADATA dataLength:9 data:dataDict];
                [bootloaderModel writeCharacteristicValueWithData:data command:SET_APP_METADATA];
            } else {
                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTASiliconIDMismatchMessage")];
                //Reset view in case of error
                [self initView];
            }
        } else if ([command isEqual:@(SET_APP_METADATA)]) {
            NSDictionary *rowDataDict = [fileRowDataArray objectAtIndex:currentIndex];
            if (RowTypeEiv == [[rowDataDict objectForKey:ROW_TYPE] unsignedCharValue]) {
                /* Send SET_EIV command */
                NSArray *dataArr = [rowDataDict objectForKey:DATA_ARRAY];
                NSDictionary * dataDict = [NSDictionary dictionaryWithObject:dataArr forKey:ROW_DATA];
                NSData *data = [bootloaderModel createPacketWithCommandCode_v1:SET_EIV dataLength:[dataArr count] data:dataDict];
                [bootloaderModel writeCharacteristicValueWithData:data command:SET_EIV];
            } else {
                //Process data row
                [self startProgrammingDataRowAtIndex_v1:currentIndex];
            }
        } else if ([command isEqual:@(SEND_DATA)]) {
            /* Send SEND_DATA/PROGRAM_DATA commands */
            if (bootloaderModel.isSendRowDataSuccess) {
                [self programDataRowAtIndex_v1:currentIndex];
            } else {
                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTASendDataCommandFailed")];
            }
        } else if ([command isEqual:@(PROGRAM_DATA)] || [command isEqual:@(SET_EIV)]) {
            // Update progress and proceed to next row
            if (bootloaderModel.isProgramRowDataSuccess) {
                currentIndex++;
                
                float percentage = ((float) currentIndex/fileRowDataArray.count) * 100;
                fileWritingProgress = (firmwareFile1NameContainerView.frame.size.width * currentIndex)/fileRowDataArray.count;
                if (isWritingFile1) {
                    firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = firmwareFile1NameContainerView.frame.size.width - fileWritingProgress;
                    firmwareFile1UpgradePercentageLabel.text = [NSString stringWithFormat:@"%d %%",(int)percentage];
                } else {
                    firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = firmwareFile2NameContainerView.frame.size.width - fileWritingProgress;
                    firmwareFile2UpgradePercentageLabel.text = [NSString stringWithFormat:@"%d %%",(int)percentage];
                }
                
                [UIView animateWithDuration:0.5 animations:^{
                    [self.view layoutIfNeeded];
                }];
                
                if (currentIndex < fileRowDataArray.count) {
                    NSDictionary * rowDataDict = [fileRowDataArray objectAtIndex:currentIndex];
                    if (RowTypeEiv == [[rowDataDict objectForKey:ROW_TYPE] unsignedCharValue]) {
                        /* Send SET_EIV command */
                        NSArray * dataArr = [rowDataDict objectForKey:DATA_ARRAY];
                        NSDictionary * dataDict = [NSDictionary dictionaryWithObject:dataArr forKey:ROW_DATA];
                        NSData * data = [bootloaderModel createPacketWithCommandCode_v1:SET_EIV dataLength:[dataArr count] data:dataDict];
                        [bootloaderModel writeCharacteristicValueWithData:data command:SET_EIV];
                    } else {
                        //Process data row (program next row)
                        [self startProgrammingDataRowAtIndex_v1:currentIndex];
                    }
                } else {
                    /* Send VERIFY_APP command */
                    uint8_t appID = [[fileHeaderDict objectForKey:APP_ID] unsignedCharValue];
                    NSDictionary * dataDict = [NSDictionary dictionaryWithObject:[NSNumber numberWithUnsignedInt:appID] forKey:APP_ID];
                    NSData * data = [bootloaderModel createPacketWithCommandCode_v1:VERIFY_APP dataLength:1 data:dataDict];
                    [bootloaderModel writeCharacteristicValueWithData:data command:VERIFY_APP];
                }
            } else {
                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAWritingFailedMessage")];
                [self initView];
            }
        } else if ([command isEqual:@(VERIFY_APP)]) {
            if (bootloaderModel.isAppValid) {
                [currentOperationLabel setText:LOCALIZEDSTRING(@"OTAUpgradeCompletedMessage")];
                
                // Storing selected files
                if (app_stack_separate == firmwareUpgradeMode && isWritingFile1) {
                    // NOTE: Security Key and Active Application are not applicable for CYACD2, hence not setting them here
                    [[CyCBManager sharedManager] setBootloaderFileArray:firmwareFileList];
                    [[UIApplication sharedApplication] cancelAllLocalNotifications];
                    UILocalNotification * n1 = [[UILocalNotification alloc] init];
                    n1.fireDate = [NSDate dateWithTimeIntervalSinceNow: 5];
                    n1.alertBody = LOCALIZEDSTRING(@"OTAAppUgradePendingMessage");
                    [[UIApplication sharedApplication] scheduleLocalNotification: n1];
                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:LOCALIZEDSTRING(@"OTAUpgradeStatus")];
                } else {
                    [[UIApplication sharedApplication] cancelAllLocalNotifications];
                    UILocalNotification * n1 = [[UILocalNotification alloc] init];
                    n1.fireDate = [NSDate dateWithTimeIntervalSinceNow: 5];
                    n1.alertBody = LOCALIZEDSTRING(@"OTAUpgradeCompletedMessage");
                    [[UIApplication sharedApplication] scheduleLocalNotification: n1];
                }
                
                /* Send EXIT_BOOTLOADER command */
                NSData *exitBootloaderCommandData = [bootloaderModel createPacketWithCommandCode_v1:EXIT_BOOTLOADER dataLength:0 data:nil];
                [bootloaderModel writeCharacteristicValueWithData:exitBootloaderCommandData command:EXIT_BOOTLOADER];
            } else {
                [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAInvalidApplicationMessage")];
                [self initView];
                currentIndex = 0;
            }
        }
    } else {
        [Utilities alertWithTitle:APP_NAME message:[bootloaderModel errorMessageForErrorCode:error]];
        [self initView];
    }
}

/*!
 *  @method startProgrammingDataRowAtIndex:
 *
 *  @discussion Method to write the firmware file data to the device
 *
 */
-(void) startProgrammingDataRowAtIndex:(int) index
{
    NSDictionary *rowDataDict = [fileRowDataArray objectAtIndex:index];
    
    // Check for change in arrayID
    if (![[rowDataDict objectForKey:ARRAY_ID] isEqual:currentArrayID])
    {
        // GET_FLASH_SIZE command is passed to get the new start and end row numbers
        NSDictionary * rowDataDictionary = [fileRowDataArray objectAtIndex:index];
        NSDictionary * dict = [NSDictionary dictionaryWithObject:[rowDataDictionary objectForKey:ARRAY_ID] forKey:FLASH_ARRAY_ID];
        NSData * data = [bootloaderModel createPacketWithCommandCode:GET_FLASH_SIZE dataLength:1 data:dict];
        [bootloaderModel writeCharacteristicValueWithData:data command:GET_FLASH_SIZE];
        
        currentArrayID = [rowDataDictionary objectForKey:ARRAY_ID];
        return;
    }
    
    // Check whether the row number falls in the range obtained from the device
    currentRowNumber = [Utilities getIntegerFromHexString:[rowDataDict objectForKey:ROW_NUMBER]];
    
    if (currentRowNumber >= bootloaderModel.startRowNumber && currentRowNumber <= bootloaderModel.endRowNumber)
    {
        /* Write data using PROGRAM_ROW command */
        currentRowDataArray = [[rowDataDict objectForKey:DATA_ARRAY] mutableCopy];
        [self programDataRowAtIndex:index];
    }
    else
    {
        [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTARowNoOutOfBoundMessage")];
        [self initView];
        currentIndex = 0;
    }
}

/*!
 *  @method startProgrammingDataRowAtIndex_v1:
 *
 *  @discussion Method to write the firmware file data to the device
 *
 */
-(void) startProgrammingDataRowAtIndex_v1:(int) index
{
    NSDictionary *rowDataDict = [fileRowDataArray objectAtIndex:index];
    
    //Write data using SEND_DATA/PROGRAM_ROW commands
    currentRowDataArray = [[rowDataDict objectForKey:DATA_ARRAY] mutableCopy];
    currentRowDataAddress = [[rowDataDict objectForKey:ADDRESS] unsignedIntValue];
    currentRowDataCRC32 = [[rowDataDict objectForKey:CRC_32] unsignedIntValue];
    
    [self programDataRowAtIndex_v1:index];
}

/*!
 *  @method programDataRowAtIndex:
 *
 *  @discussion Method to write the data in a row
 *
 */
-(void) programDataRowAtIndex:(int)index
{
    NSDictionary *rowDataDict = [fileRowDataArray objectAtIndex:index];
    
    if (currentRowDataArray.count > maxDataSize)
    {
        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[currentRowDataArray subarrayWithRange:NSMakeRange(0, maxDataSize)], ROW_DATA, nil];
        NSData *data = [bootloaderModel createPacketWithCommandCode:SEND_DATA dataLength:maxDataSize data:dataDict];
        [bootloaderModel writeCharacteristicValueWithData:data command:SEND_DATA];
        [currentRowDataArray removeObjectsInRange:NSMakeRange(0, maxDataSize)];
    }
    else
    {
        //Last packet data
        NSDictionary *dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[rowDataDict objectForKey:ARRAY_ID],FLASH_ARRAY_ID,
                                  @(currentRowNumber),FLASH_ROW_NUMBER,
                                  currentRowDataArray,ROW_DATA, nil];
        NSData *data = [bootloaderModel createPacketWithCommandCode:PROGRAM_ROW dataLength:currentRowDataArray.count+3 data:dataDict];
        [bootloaderModel writeCharacteristicValueWithData:data command:PROGRAM_ROW];
    }
}

/*!
 *  @method programDataRowAtIndex_v1:
 *
 *  @discussion Method to write the data in a row
 *
 */
-(void) programDataRowAtIndex_v1:(int)index
{
    if (currentRowDataArray.count > maxDataSize)
    {
        NSDictionary * dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[currentRowDataArray subarrayWithRange:NSMakeRange(0, maxDataSize)], ROW_DATA, nil];
        NSData * data = [bootloaderModel createPacketWithCommandCode_v1:SEND_DATA dataLength:maxDataSize data:dataDict];
        [bootloaderModel writeCharacteristicValueWithData:data command:SEND_DATA];
        [currentRowDataArray removeObjectsInRange:NSMakeRange(0, maxDataSize)];
    }
    else
    {
        //Last packet data
        NSDictionary * dataDict = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:currentRowDataAddress], ADDRESS, [NSNumber numberWithUnsignedInt:currentRowDataCRC32], CRC_32, currentRowDataArray, ROW_DATA, nil];
        NSData * data = [bootloaderModel createPacketWithCommandCode_v1:PROGRAM_DATA dataLength:(currentRowDataArray.count + 8) data:dataDict];
        [bootloaderModel writeCharacteristicValueWithData:data command:PROGRAM_DATA];
    }
}

#pragma mark - alertView delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView.tag == BACK_BUTTON_ALERT_TAG)
    {
        if (buttonIndex)
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
    if (alertView.tag == UPGRADE_RESUME_ALERT_TAG) {
        if (buttonIndex == 1)
        {
            isWritingFile1 = NO;
            [self startStopBtnTouched:startStopUpgradeBtn];
            [[CyCBManager sharedManager] setBootloaderFileArray:nil];
            [[CyCBManager sharedManager] setBootloaderSecurityKey:nil];
            [[CyCBManager sharedManager] setBootloaderActiveApp:NoChange];
        }
        else
        {
            [[CyCBManager sharedManager] setBootloaderFileArray:nil];
            [[CyCBManager sharedManager] setBootloaderSecurityKey:nil];
            [[CyCBManager sharedManager] setBootloaderActiveApp:NoChange];
            [self initView];
        }
    }else if (alertView.tag == UPGRADE_STOP_ALERT_TAG)
    {
        
        if (buttonIndex == 1) {
            
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    int differenceInWidth = self.view.frame.size.height - self.view.frame.size.width;
    if (startStopUpgradeBtn.selected) {
        if (isWritingFile1) {
            firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = (firmwareFile1NameContainerView.frame.size.width+differenceInWidth) - fileWritingProgress;
        }else{
            firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = (firmwareFile2NameContainerView.frame.size.width+differenceInWidth) - fileWritingProgress;
        }
    }else{
        firmwareUpgradeProgressLabel1TrailingSpaceConstraint.constant = firmwareFile1NameContainerView.frame.size.width+differenceInWidth;
        firmwareUpgradeProgressLabel2TrailingSpaceConstraint.constant = firmwareFile2NameContainerView.frame.size.width+differenceInWidth;
    }
}

@end
