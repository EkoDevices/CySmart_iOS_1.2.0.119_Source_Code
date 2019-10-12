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

#import <UIKit/UIKit.h>
#import "BaseViewController.h"
#import "Constants.h"

@class FirmwareFileSelectionViewController;

#define FILE_NAME       @"FileName"
#define FILE_PATH       @"FilePath"

typedef enum{
    app_upgrade,
    app_stack_combined,
    app_stack_separate
}OTAMode;

@protocol FirmwareFileSelectionDelegate <NSObject>

@required

/*!
 *  @method firmwareFilesSelected: upgradeMode: securityKey: activeApp:
 *
 *  @discussion Receives files passed in from the FirmwareFileSelectionViewController.
 *
 */
- (void) firmwareFilesSelected:(NSArray *)fileList upgradeMode:(OTAMode)upgradeMode securityKey:(NSData *)securityKeyData activeApp:(ActiveApp)activeApp;

@end


@interface FirmwareFileSelectionViewController : BaseViewController

/*!
 *  @property selectedUpgradeMode
 *
 *  @discussion Enum that shows the firmware upgrade mode selected by the user
 *
 */
@property OTAMode upgradeMode;

@property (strong, nonatomic) id <FirmwareFileSelectionDelegate> delegate;

@end
