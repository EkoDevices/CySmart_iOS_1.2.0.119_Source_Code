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


@interface FindMeModel : NSObject

/*!
 *  @property isTransmissionPowerPresent
 *
 *  @discussion BOOL value idicates the presence of TransmissionPower
 *
 */
@property(nonatomic) BOOL isTransmissionPowerPresent;

/*!
 *  @property isLinkLossServicePresent
 *
 *  @discussion BOOL value idicates the presence of LinkLoss
 *
 */
@property(nonatomic) BOOL isLinkLossServicePresent;

/*!
 *  @property isImmediateAlertServicePresent
 *
 *  @discussion BOOL value idicates the presence of ImmediateAlert
 *
 */
@property(nonatomic) BOOL isImmediateAlertServicePresent;

/*!
 *  @property transmissionPowerValue
 *
 *  @discussion float value hold the power value
 *
 */

@property(nonatomic) float transmissionPowerValue;

/*!
 *  @property immediateAlertCharacteristic
 *
 *  @discussion characteristic for immediate alert
 *
 */
@property (nonatomic) CBCharacteristic *immediateAlertCharacteristic;

/*!
 *  @method startDiscoverCharacteristicsForService: withCompletionHandler:
 *
 *  @discussion Discovers the characteristics of a specified service..
 */

-(void)startDiscoverCharacteristicsForService:(CBService *)serviceUUID withCompletionHandler:(void (^) (CBService *foundService, BOOL success, NSError *error))handler;

/*!
 *  @method updateProximityCharacteristicWithHandler:WithHandler
 *
 *  @discussion Read value from transmission power characteristic.
 */

-(void)updateProximityCharacteristicWithHandler:(void (^) (BOOL success, NSError *error))handler;

/*!
 *  @method updateLinkLossCharacteristicValue: WithHandler
 *
 *  @discussion Write value to link loss characteristic.
 */

-(void)updateLinkLossCharacteristicValue:(enum alertOptions)option WithHandler:(void (^) (BOOL success, NSError *error))handler;

/*!
 *  @method updateImmedieteALertCharacteristicValue: WithHandler
 *
 *  @discussion Write value to a immediete alert characteristic.
 */

-(void)updateImmedieteALertCharacteristicValue:(enum alertOptions)option WithHandler:(void (^) (BOOL success, NSError *error))handler;

/*!
 *  @method stopUpdate
 *
 *  @discussion Stop notifications or indications for the value of a specified characteristic.
 */

-(void)stopUpdate;

@end
