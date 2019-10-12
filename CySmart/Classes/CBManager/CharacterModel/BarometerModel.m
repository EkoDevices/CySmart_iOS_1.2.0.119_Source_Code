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


#import "BarometerModel.h"
#import "Constants.h"

/*!
 *  @class BarometerModel
 *
 *  @discussion Class to handle the barometer service related operations
 *
 */

@interface BarometerModel () <cbCharacteristicManagerDelegate>
{
    
    CBCharacteristic *sensorTypeCharacteristic, *sensorScanIntervalCharacteristic, *dataAccumulationCharacterstic, *barometerReadingCharacteristic, *indicationThresholdCharacteristic;
}

@end


@implementation BarometerModel


/*!
 *  @method stopUpdate
 *
 *  @discussion Method to stop update
 *
 */

-(void) stopUpdate
{
    
    if (barometerReadingCharacteristic != nil)
    {
        [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:BAROMETER_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:barometerReadingCharacteristic.UUID] descriptor:nil operation:STOP_NOTIFY];
        
        [[[CyCBManager sharedManager] myPeripheral] setNotifyValue:NO forCharacteristic:barometerReadingCharacteristic];
    }
}

/*!
 *  @method getCharacteristicsForBarometerService:
 *
 *  @discussion Method to get characteristics for barometer service
 *
 */

-(void) getCharacteristicsForBarometerService:(CBService *)service
{
    for (CBCharacteristic *characteristic in service.characteristics)
    {
        if ([characteristic.UUID isEqual:BAROMETER_DIGITAL_SENSOR_CHARACTERISTIC_UUID])
        {
            sensorTypeCharacteristic = characteristic;
        }
        else if ([characteristic.UUID isEqual:BAROMETER_SENSOR_SCAN_INTERVAL_CHARACTERISTIC_UUID])
        {
            sensorScanIntervalCharacteristic = characteristic;
        }
        else if ([characteristic.UUID isEqual:BAROMETER_DATA_ACCUMULATION_CHARACTERISTIC_UUID])
        {
            dataAccumulationCharacterstic = characteristic;
        }
        else if ([characteristic.UUID isEqual:BAROMETER_READING_CHARACTERISTIC_UUID])
        {
            barometerReadingCharacteristic = characteristic;
        }
        else if ([characteristic.UUID isEqual:BAROMETER_THRESHOLD_FOR_INDICATION_CHARACTERISTIC_UUID])
        {
            indicationThresholdCharacteristic = characteristic;
        }
        
    }

}

/*!
 *  @method updateValueForPressure
 *
 *  @discussion Method to set notification for barometer reading
 *
 */
-(void) updateValueForPressure
{
    if (barometerReadingCharacteristic != nil)
    {
        [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:barometerReadingCharacteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:barometerReadingCharacteristic.UUID] descriptor:nil operation:START_NOTIFY];
        
        
        [[[CyCBManager sharedManager] myPeripheral] setNotifyValue:YES forCharacteristic:barometerReadingCharacteristic];
    }
    
}

/*!
 *  @method readValueForCharacteristics
 *
 *  @discussion Method to read values for sensortype, scan interval and data accumulation characteristic
 *
 */

-(void) readValueForCharacteristics
{
    
    if (sensorTypeCharacteristic != nil)
    {
        [[[CyCBManager sharedManager] myPeripheral] readValueForCharacteristic:sensorTypeCharacteristic];
        
        [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:ANALOG_TEMPERATURE_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:sensorTypeCharacteristic.UUID] descriptor:nil operation:READ_REQUEST];
    }
    
    if (sensorScanIntervalCharacteristic != nil)
    {
        [[[CyCBManager sharedManager] myPeripheral] readValueForCharacteristic:sensorScanIntervalCharacteristic];
        
        [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:ANALOG_TEMPERATURE_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:sensorScanIntervalCharacteristic.UUID] descriptor:nil operation:READ_REQUEST];
    }
    
    if (dataAccumulationCharacterstic != nil)
    {
        [[[CyCBManager sharedManager] myPeripheral] readValueForCharacteristic:dataAccumulationCharacterstic];
        
        [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:ANALOG_TEMPERATURE_SERVICE_UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:dataAccumulationCharacterstic.UUID] descriptor:nil operation:READ_REQUEST];
    }
    
}

/*!
 *  @method getValuesForBarometerCharacteristics:
 *
 *  @discussion Method to get values for barometer characteristics
 *
 */

-(void) getValuesForBarometerCharacteristics:(CBCharacteristic *)characteristic
{
    NSData *dataValue = characteristic.value;
    const uint8_t *reportData = (uint8_t *)[dataValue bytes];
    
    if ([characteristic.UUID isEqual:BAROMETER_DIGITAL_SENSOR_CHARACTERISTIC_UUID])
    {
        _sensorTypeString = [NSString stringWithFormat:@"%d",reportData[0]];
        
         [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:characteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:characteristic.UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@%@ %@",READ_RESPONSE,DATA_SEPERATOR,[Utilities convertDataToLoggerFormat:dataValue]]];
    }
    else if ([characteristic.UUID isEqual:BAROMETER_SENSOR_SCAN_INTERVAL_CHARACTERISTIC_UUID])
    {
        _sensorScanIntervalString = [NSString stringWithFormat:@"%d",reportData[0]];
        
         [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:characteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:characteristic.UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@%@ %@",READ_RESPONSE,DATA_SEPERATOR,[Utilities convertDataToLoggerFormat:dataValue]]];
    }
    else if ([characteristic.UUID isEqual:BAROMETER_DATA_ACCUMULATION_CHARACTERISTIC_UUID])
    {
        _filterTypeConfigurationString = [NSString stringWithFormat:@"%d",reportData[0]];
        
         [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:characteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:characteristic.UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@%@ %@",READ_RESPONSE,DATA_SEPERATOR,[Utilities convertDataToLoggerFormat:dataValue]]];
    }
    else if ([characteristic.UUID isEqual:BAROMETER_READING_CHARACTERISTIC_UUID])
    {
        float pressureValue = CFSwapInt16LittleToHost(*(uint16_t *) &reportData[0]);
        _pressureValueString = [NSString stringWithFormat:@"%f",pressureValue];
        
        [Utilities logDataWithService:[ResourceHandler getServiceNameForUUID:characteristic.service.UUID] characteristic:[ResourceHandler getCharacteristicNameForUUID:characteristic.UUID] descriptor:nil operation:[NSString stringWithFormat:@"%@%@ %@",NOTIFY_RESPONSE,DATA_SEPERATOR,[Utilities convertDataToLoggerFormat:dataValue]]];
    }

}



@end
