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

#import <UIKit/UIKit.h>

@interface BaseViewController : UIViewController

/*!
 *  @property rightMenuButton
 *
 *  @discussion Button that handle right menu display
 *
 */

/*!
 *  @property shareButton
 *
 *  @discussion button that handle share
 *
 */

/*!
*  @property searchButton
*
*  @discussion button that handle search
*
*/

@property (strong,nonatomic) UIButton *rightMenuButton, *shareButton, *searchButton;

/*!
 *  @property navBarTitleLabel
 *
 *  @discussion displays title in each view
 *
 */

@property (strong,nonatomic) UILabel *navBarTitleLabel;

/*!
 *  @property searchBar
 *
 *  @discussion Textfield to enter the the text to search
 *
 */

@property (strong,nonatomic) UISearchBar *searchBar;

/*!
 *  @method saveImage:
 *
 *  @discussion Method to save image to the document path
 *
 */
-(NSURL*)saveImage:(UIImage *)image;

/*!
 *  @Method showActivityPopover:Rect
 *
 *  @discussion  Method to show share window
 *
 */
-(void)showActivityPopover:(NSURL *)pathUrl Rect:(CGRect)rect excludedActivities:(NSArray *)excludedActivityTypes;

/*!
 *  @Method addSearchButtonToNavBar
 *
 *  @discussion  Method to add search button to navigation bar
 *
 */

-(void) addSearchButtonToNavBar;

/*!
 *  @Method removeSearchButtonFromNavBar
 *
 *  @discussion  Method to remove search button from navigation bar
 *
 */

-(void) removeSearchButtonFromNavBar;

@end
