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

#import "DeviceInformationVC.h"
#import "DeviceInformationTableViewCell.h"
#import "DevieInformationModel.h"
#import "Constants.h"

#define deviceInfoCharacteristicsArray [NSArray arrayWithObjects:MANUFACTURER_NAME,MODEL_NUMBER,SERIAL_NUMBER,HARDWARE_REVISION,FIRMWARE_REVISION,SOFTWARE_REVISION,SYSTEM_ID,REGULATORY_CERTIFICATION_DATA_LIST,PNP_ID,nil]

/*!
 *  @class DeviceInformationVC
 *
 *  @discussion  Class to handle the user interactions and UI updates for device information service  
 *
 */

@interface DeviceInformationVC ()<UITableViewDataSource,UITableViewDelegate>
{
    DevieInformationModel *deviceInfoModel;
}
@property (weak, nonatomic) IBOutlet UITableView *deviceInfoTableView;

@end

@implementation DeviceInformationVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    _deviceInfoTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    // Initialize device information model
    [self initModel];
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:DEVICE_INFO];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*!
 *  @method initModel
 *
 *  @discussion Method to Discover the specified characteristic of a service.
 *
 */

-(void) initModel
{
    deviceInfoModel = [[DevieInformationModel alloc] init];
    [deviceInfoModel startDiscoverChar:^(BOOL success, NSError *error) {
        
        if (success)
        {
            @synchronized(deviceInfoModel){
                // Get the characteristic value if the required characteristic is found
                [self updateUI];
            }
        }
    }];
}

/*!
 *  @method updateUI
 *
 *  @discussion Method to update UI with the characteristic value.
 *
 */

-(void) updateUI
{
    [deviceInfoModel discoverCharacteristicValues:^(BOOL success, NSError *error)
     {
         if (success)
         {
             // Reload table view with the data received
             [_deviceInfoTableView reloadData];
         }
     }];
}


#pragma mark - TableView data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return deviceInfoCharacteristicsArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DeviceInformationTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"deviceInfoCell"];
    
    if (cell == nil)
    {
        cell = [[DeviceInformationTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"deviceInfoCell"];
    }
    NSString *deviceCharaName = [deviceInfoCharacteristicsArray objectAtIndex:[indexPath row]];
    cell.deviceCharacteristicNameLabel.text = deviceCharaName;
    
    if ([deviceInfoModel.deviceInfoCharValueDictionary objectForKey:deviceCharaName] != nil)
    {
        cell.deviceCharacteristicValueLabel.text = [deviceInfoModel.deviceInfoCharValueDictionary objectForKey:deviceCharaName];
    }
        
    return cell;
}


@end
