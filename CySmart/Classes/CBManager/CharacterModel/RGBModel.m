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
#import "RGBModel.h"
#import "CyCBManager.h"
#import "LoggerHandler.h"

/*!
 *  @class RGBModel
 *
 *  @discussion Class to handle the RGB service related operations
 *
 */
@interface RGBModel()<cbCharacteristicManagerDelegate>
{
    void (^didUpdateValueForCharacteristicHandler)(BOOL success, NSError *error);
    void (^didWriteValueForCharacteristicHandler)(BOOL success, NSError *error);
    CBCharacteristic *RGBCharacteristic;
    BOOL isWriteSuccess;
}

@end

@implementation RGBModel

@synthesize  red;
@synthesize  green;
@synthesize  blue;
@synthesize  intensity;

- (instancetype)init
{
    self = [super init];
    if (self) {
        [self discoverCharacteristics];
    }
    return self;
}

/*!
 *  @method discoverCharacteristics
 *
 *  @discussion Discover characteristics of the RGB service
 */
-(void)discoverCharacteristics
{
    isWriteSuccess = YES ;
    [[CyCBManager sharedManager] setCbCharacteristicDelegate:self];
    for(CBService *service in [[CyCBManager sharedManager] myPeripheral].services)
    {
        if([service.UUID isEqual:RGB_SERVICE_UUID] || [service.UUID isEqual:CUSTOM_RGB_SERVICE_UUID] )
        {
            [[[CyCBManager sharedManager] myPeripheral] discoverCharacteristics:nil forService:service];
        }
    }
}

/*!
 *  @method setDidUpdateValueForCharacteristicHandler:
 *
 *  @discussion Set handler to be invoked when RGB characteristic value is updated
 */
-(void)setDidUpdateValueForCharacteristicHandler:(void (^) (BOOL success, NSError *error))handler
{
    didUpdateValueForCharacteristicHandler = handler;
}

/*!
 *  @method stopUpdate
 *
 *  @discussion Disable notifications/indications for RGB characteristic
 */
-(void)stopUpdate
{
    didUpdateValueForCharacteristicHandler = nil;
    if ([[[CyCBManager sharedManager] myService].UUID isEqual:RGB_SERVICE_UUID] || [[[CyCBManager sharedManager] myService].UUID isEqual:CUSTOM_RGB_SERVICE_UUID])
    {
        for (CBCharacteristic *aChar in [[CyCBManager sharedManager] myService].characteristics)
        {
            if ([aChar.UUID isEqual:RGB_CHARACTERISTIC_UUID] || [aChar.UUID isEqual:CUSTOM_RGB_CHARACTERISTIC_UUID] )
            {
                [[[CyCBManager sharedManager] myPeripheral] setNotifyValue:NO  forCharacteristic:aChar];
            }
        }
    }
}

/*!
 *  @method writeColorWithRed:green:blue:intensity:handler
 *
 *  @discussion Write RGB + intensity to the RGB characteristic
 */
-(void)writeColorWithRed:(NSInteger)red green:(NSInteger)green blue:(NSInteger)blue intensity:(NSInteger)intensity handler:(void (^) (BOOL success, NSError *error))handler
{
    didWriteValueForCharacteristicHandler = handler ;
    if(isWriteSuccess && RGBCharacteristic)
    {
        self.red = red ;
        self.green = green;
        self.blue = blue;
        self.intensity = intensity;
        
        uint8_t value[] = {red, green, blue, intensity}; //enter the value which you want to write.
        NSData *valueData = [NSData dataWithBytes:(void*)&value length:sizeof(value)];
        [[[CyCBManager sharedManager] myPeripheral] writeValue:valueData forCharacteristic:RGBCharacteristic type:CBCharacteristicWriteWithResponse];
        [self logColorData:valueData];
        isWriteSuccess = NO;
    }
}

#pragma mark - CBManagerDelagate methods

/*!
 *  @method peripheral: didDiscoverCharacteristicsForService: error:
 *
 *  @discussion Method invoked when characteristics are discovered for a service
 *
 */
-(void)peripheral:(CBPeripheral *)peripheral didDiscoverCharacteristicsForService:(CBService *)service error:(NSError *)error
{
    if ([service.UUID isEqual:RGB_SERVICE_UUID] || [service.UUID isEqual:CUSTOM_RGB_SERVICE_UUID])
    {
        for (CBCharacteristic *aChar in service.characteristics){
            if ([aChar.UUID isEqual:RGB_CHARACTERISTIC_UUID] || [aChar.UUID isEqual:CUSTOM_RGB_CHARACTERISTIC_UUID])
            {
                RGBCharacteristic = aChar;
                [[[CyCBManager sharedManager] myPeripheral] readValueForCharacteristic:aChar];
            }
        }
    }
}

/*!
 *  @method peripheral: didUpdateValueForCharacteristic: error:
 *
 *  @discussion Method invoked when the characteristic value changes
 *
 */
-(void)peripheral:(CBPeripheral *)peripheral didUpdateValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error == nil)
    {
        if (([characteristic.UUID isEqual:RGB_CHARACTERISTIC_UUID] || [characteristic.UUID isEqual:CUSTOM_RGB_CHARACTERISTIC_UUID]) && characteristic.value)
        {
            NSData *valueData = [characteristic value];
            const uint8_t *valueBytes = [valueData bytes];
            
            self.red = valueBytes[0];
            self.green = valueBytes[1];
            self.blue = valueBytes[2];
            self.intensity = valueBytes[3];
            
            didUpdateValueForCharacteristicHandler(YES,nil);
        }
        else
        {
            didUpdateValueForCharacteristicHandler(NO,error);
        }
    }
    else
    {
        didUpdateValueForCharacteristicHandler(NO,error);
    }
}


/*!
 *  @method peripheral: didWriteVlueForCharacteristic: error:
 *
 *  @discussion Write acknowledgement for RGB colors and intensity to specified characteristic.
 */
-(void)peripheral:(CBPeripheral *)peripheral didWriteValueForCharacteristic:(CBCharacteristic *)characteristic error:(NSError *)error
{
    if(error)
    {
        isWriteSuccess = NO ;
        didWriteValueForCharacteristicHandler(NO,error);
    }
    else
    {
        isWriteSuccess = YES ;
        didWriteValueForCharacteristicHandler(YES,error);
    }
    
    [self logWriteStatusWithError:error];
}

/*!
 *  @method logColorData:
 *
 *  @discussion Method to log the color written to the device
 *
 */
-(void) logColorData:(NSData *)data
{
    [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:RGB_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:RGB_CHARACTERISTIC_UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@%@ %@",WRITE_REQUEST,DATA_SEPERATOR,[Utilities convertDataToLoggerFormat:data]]];
}

-(void) logWriteStatusWithError:(NSError *)error
{
    if (error == nil)
    {
        [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:RGB_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:RGB_CHARACTERISTIC_UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@- %@",WRITE_REQUEST_STATUS,WRITE_SUCCESS]];
    }
    else
    {
       [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:RGB_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:RGB_CHARACTERISTIC_UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@- %@%@",WRITE_REQUEST_STATUS,WRITE_ERROR,[error.userInfo objectForKey:NSLocalizedDescriptionKey]]];
    }
}

@end
