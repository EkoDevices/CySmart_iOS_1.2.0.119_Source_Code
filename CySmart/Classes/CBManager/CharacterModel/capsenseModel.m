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
#import "capsenseModel.h"
#import "Constants.h"

/*!
 *  @class capsenseModel
 *
 *  @discussion Class to handle the capsense service related operations
 *
 */
@interface capsenseModel() <cbCharacteristicManagerDelegate>
{
    void(^cbCharacteristicDiscoveryHandler)(BOOL success, CBService *service, NSError *error);
    void(^cbCharacteristicHandler)(BOOL success, NSError *error);

    CBUUID *characteristicUUID;
    CBCharacteristic *capsenseCharacteristic;
}

@end

@implementation capsenseModel

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [[CyCBManager sharedManager] setCbCharacteristicDelegate:self];
    }
    return self;
}

/*!
 *  @method startDiscoverCharacteristicWithUUID: completionHandler
 *
 *  @discussion Discovers characteristics of the CapSense service
 */
-(void)startDiscoverCharacteristicWithUUID:(CBUUID *)UUID completionHandler:(void (^) (BOOL success,CBService *service, NSError *error))handler
{
    cbCharacteristicDiscoveryHandler = handler;
    characteristicUUID = UUID;
    [[[CyCBManager sharedManager] myPeripheral] discoverCharacteristics:nil forService:[[CyCBManager sharedManager] myService]];
}

/*!
 *  @method updateCharacteristicWithHandler:
 *
 *  @discussion Start notification/indication for the CapSense characteristic
 */
-(void)updateCharacteristicWithHandler:(void (^) (BOOL success, NSError *error))handler
{
    cbCharacteristicHandler = handler;
    [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:capsenseCharacteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:capsenseCharacteristic.UUID] descriptor:nil operation:START_NOTIFY];
    [[[CyCBManager sharedManager] myPeripheral] setNotifyValue:YES forCharacteristic:capsenseCharacteristic];
}

/*!
 *  @method stopUpdate
 *
 *  @discussion stop notifications or indications for the value of a specified characteristic.
 */
-(void)stopUpdate
{
    cbCharacteristicHandler = nil;
    if (capsenseCharacteristic != nil)
    {
        if (capsenseCharacteristic.isNotifying)
        {
            [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:capsenseCharacteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:capsenseCharacteristic.UUID] descriptor:nil operation:STOP_NOTIFY];
            [[[CyCBManager sharedManager] myPeripheral] setNotifyValue:NO forCharacteristic:capsenseCharacteristic];
        }
    }
}


#pragma mark - CBCharacteristic Manager delegate methods

/*!
 *  @method peripheral: didDiscoverCharacteristicsForService: error:
 *
 *  @discussion Method invoked when characteristics are discovered for a service
 *
 */
-(void) peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:CAPSENSE_SERVICE_UUID] || [service.UUID isEqual:CUSTOM_CAPSENSE_SERVICE_UUID])
    {
        if (characteristicUUID == nil && cbCharacteristicDiscoveryHandler != nil)
        {
            cbCharacteristicDiscoveryHandler(YES, service, nil);
        }
        
        for (CBCharacteristic *characteristic in service.characteristics)
        {
            if (characteristicUUID != nil)
            {
                // Checking for the required characteristic
                if ([characteristic.UUID isEqual:characteristicUUID])
                {
                    capsenseCharacteristic = characteristic;
                    cbCharacteristicDiscoveryHandler(YES, nil, nil);
                }
            }
        }
        cbCharacteristicDiscoveryHandler(NO, nil, nil);
    }
    else
    {
        cbCharacteristicDiscoveryHandler(NO, nil, nil);
    }
}

/*!
 *  @method didUpdateValueForCharacteristic
 *
 *  @discussion Parse the CapSense value from the characteristic.
 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    
    NSData *data = characteristic.value;
    uint8_t *dataPointer = (uint8_t *)[data bytes];
    
    /**
     * Parse the CapSense proximity value from the characteristic
     */
    if ([characteristic.UUID isEqual:CAPSENSE_PROXIMITY_CHARACTERISTIC_UUID] || [characteristic.UUID isEqual:CUSTOM_CAPSENSE_PROXIMITY_CHARACTERISTIC_UUID])
    {
        uint8_t value = dataPointer[0];
        _proximityValue = value;
        cbCharacteristicHandler(YES, nil);
    }
    /**
     * Parse the CapSense slider value from the characteristic
     */
    else if ([characteristic.UUID isEqual:CAPSENSE_SLIDER_CHARACTERISTIC_UUID] || [characteristic.UUID isEqual:CUSTOM_CAPSENSE_SLIDER_CHARACTERISTIC_UUID])
    {
        uint8_t value = dataPointer[0];
        _capsenseSliderValue = value;
        cbCharacteristicHandler(YES, nil);
    }
    /**
     * Parse the CapSense buttons value from the characteristic
     */
    else if ([characteristic.UUID isEqual:CAPSENSE_BUTTON_CHARACTERISTIC_UUID] || [characteristic.UUID isEqual:CUSTOM_CAPSENSE_BUTTONS_CHARACTERISTIC_UUID])
    {
        uint8_t numberOfButtons = dataPointer[0];
        _capsenseButtonCount = numberOfButtons;
        
        // Getting the 16 bit button status flag        
        _capsenseButtonStatus1 = dataPointer[1];
        _capsenseButtonStatus2 = dataPointer[2];
        cbCharacteristicHandler(YES, nil);
    }
    else
    {
        cbCharacteristicHandler(NO, error);
    }
    
    [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:characteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:characteristic.UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@%@ %@",NOTIFY_RESPONSE,DATA_SEPERATOR,[Utilities convertDataToLoggerFormat:data]]];
}

@end
