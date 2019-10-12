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

#import <Foundation/Foundation.h>
#import "CyCBManager.h"


@interface GlucoseModel : NSObject



/*!
 *  @property glucoseRecords
 *
 *  @discussion The glucose data records received from the kit
 *
 */

@property (nonatomic, retain) NSMutableArray *glucoseRecords;


/*!
 *  @property recordNameArray
 *
 *  @discussion Array of the name of records 
 *
 */

@property (strong, nonatomic) NSMutableArray *recordNameArray;

/*!
 *  @property contextInfoArray
 *
 *  @discussion Array of glucose measurement context data
 *
 */

@property (strong, nonatomic) NSMutableArray *contextInfoArray;

/*!
 *  @method startDiscoverChar:
 *
 *  @discussion Discovers the specified characteristics of a service.
 */

-(void)startDiscoverChar:(void (^) (BOOL success, NSError *error))handler;

/*!
 *  @method updateCharacteristicWithHandler:
 *
 *  @discussion Sets notifications or indications for the value of a specified characteristic.
 */

-(void)updateCharacteristicWithHandler:(void (^) (BOOL success, NSError *error))handler;

/*!
 *  @method stopUpdate
 *
 *  @discussion Stop notifications or indications for the value of a specified characteristic.
 */

-(void)stopUpdate;

/*!
 *  @method writeRACPCharacteristicWithValueString:
 *
 *  @discussion Write specified value to the RACP characteristic.
 */

-(void) writeRACPCharacteristicWithValueString:(NSString *)Value;

/*!
 *  @method getGlucoseData:
 *
 *  @discussion Parse the glucose measurement characteristic value.
 */

-(NSMutableDictionary *) getGlucoseData:(NSData *)characteristicValue;

/*!
 *  @method getGlucoseContextInfoFromData:
 *
 *  @discussion Method to parse the value from the glucose measurement context characteristic
 *
 */

-(NSMutableDictionary *) getGlucoseContextInfoFromData:(NSData *) characteristicValue;

/*!
 *  @method setCharacteristicUpdates:
 *
 *  @discussion Sets notifications or indications for glucose characteristics.
 */
-(void) setCharacteristicUpdates;

/*!
 *  @method removePreviousRecords
 *
 *  @discussion clear all the records received.
 */

-(void) removePreviousRecords;

@end
