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

#import "ScannedPeripheralTableViewCell.h"
#import "CBPeripheralExt.h"
#import "Constants.h"


/*!
 *  @class ScannedPeripheralTableViewCell
 *
 *  @discussion Model class for handling operations related to peripheral table cell
 *
 */

@implementation ScannedPeripheralTableViewCell
{
    /*  Data fields  */
    __weak IBOutlet UILabel *RSSIValueLabel;
    __weak IBOutlet UILabel *peripheralAdressLabel;
    __weak IBOutlet UILabel *peripheralName;
}
- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

/*!
 *  @method nameForPeripheral:
 *
 *  @discussion Method to get the peripheral name
 *
 */
-(NSString *)nameForPeripheral:(CBPeripheralExt *)ble
{
    NSString *bleName ;
    
    if ([ble.mAdvertisementData valueForKey:CBAdvertisementDataLocalNameKey] != nil)
    {
        bleName = [ble.mAdvertisementData valueForKey:CBAdvertisementDataLocalNameKey];
    }
    
    // If the peripheral name is not found in advertisement data, then check whether it is there in peripheral object. If it's not found then assign it as unknown peripheral
    
    if(bleName.length < 1 )
    {
        if (ble.mPeripheral.name.length > 0) {
            bleName = ble.mPeripheral.name;
        }
        else
            bleName = LOCALIZEDSTRING(@"unknownPeripheral");
    }
    
    return bleName;
}


/*!
 *  @method UUIDStringfromPeripheral:
 *
 *  @discussion Method to get the UUID from the peripheral
 *
 */
-(NSString *)UUIDStringfromPeripheral:(CBPeripheralExt *)ble
{
    
    NSString *bleUUID = ble.mPeripheral.identifier.UUIDString;
    if(bleUUID.length < 1 )
        bleUUID = @"Nil";
    else
        bleUUID = [NSString stringWithFormat:@"UUID: %@",bleUUID];
    
    return bleUUID;
}

/*!
 *  @method ServiceCountfromPeripheral:
 *
 *  @discussion Method to get the number of services present in a device
 *
 */
-(NSString *)ServiceCountfromPeripheral:(CBPeripheralExt *)ble
{
    NSString *bleService =@"";
    NSInteger serViceCount = [[ble.mAdvertisementData valueForKey:CBAdvertisementDataServiceUUIDsKey] count];
    if(serViceCount < 1 )
        bleService = LOCALIZEDSTRING(@"noServices");
    else
        bleService = [NSString stringWithFormat:@" %ld Service Advertised ",(long)serViceCount];
    
    return bleService;
}

#define RSSI_UNDEFINED_VALUE 127


/*!
 *  @method RSSIValue:
 *
 *  @discussion Method to get the RSSI value
 *
 */
-(NSString *)RSSIValue:(CBPeripheralExt *)ble
{
    NSString *deviceRSSI=[ble.mRSSI stringValue];
    
    if(deviceRSSI.length < 1 )
    {
        if([ble.mPeripheral respondsToSelector:@selector(RSSI)])
            deviceRSSI = ble.mPeripheral.RSSI.stringValue;
    }
    
    if([deviceRSSI intValue]>=RSSI_UNDEFINED_VALUE)
        deviceRSSI = LOCALIZEDSTRING(@"undefined");
    else
        deviceRSSI=[NSString stringWithFormat:@"%@ dBm",deviceRSSI];
    
    return deviceRSSI;
}


/*!
 *  @method setDiscoveredPeripheralDataFromPeripheral:
 *
 *  @discussion Method to display the device details
 *
 */
-(void)setDiscoveredPeripheralDataFromPeripheral:(CBPeripheralExt*) discoveredPeripheral
{
    peripheralName.text         = [self nameForPeripheral:discoveredPeripheral];
    peripheralAdressLabel.text  = [self ServiceCountfromPeripheral:discoveredPeripheral];
    RSSIValueLabel.text         = [self RSSIValue:discoveredPeripheral];
}

/*!
 *  @method updateRSSIWithValue:
 *
 *  @discussion Method to update the RSSI value of a device
 *
 */
-(void)updateRSSIWithValue:(NSString*) newRSSI
{
    RSSIValueLabel.text=newRSSI;
}
@end
