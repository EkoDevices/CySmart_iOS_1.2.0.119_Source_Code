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
#import "LineChart.h"
#import "KLCPopup.h"


@protocol lineChartDelegate <NSObject>

-(void)shareScreen:(id)sender;

@end

@interface MyLineChart : UIView

/*!
 *  @property chartTitle
 *
 *  @discussion chart title name
 *
 */
@property (nonatomic,retain)NSString *chartTitle;

/*!
 *  @property chartView
 *
 *  @discussion view that contain chart
 *
 */
@property(nonatomic,strong) LCLineChartView *chartView;

@property(strong,nonatomic)id<lineChartDelegate> delegate;

/*!
 *  @property pauseButton
 *
 *  @discussion Button to handle the pause/resume sate of chart
 *
 */
@property (strong,nonatomic) UIButton *pauseButton;

/*!
 *  @property shareButton
 *
 *  @discussion Button to handle share while the graph is present
 *
 */
@property (strong,nonatomic) UIButton *shareButton;

/*!
 *  @property graphTitleLabel
 *
 *  @discussion Label to add the graph title
 *
 */
@property (strong, nonatomic) UILabel *graphTitleLabel;

/*!
 *  @method addXLabel: yLabel:
 *
 *  @discussion Method to add axis label name
 *
 */
-(void) addXLabel:(NSString *)xLabelText yLabel:(NSString *)yLabelText;

/*!
 *  @method updateLineGraph: Y:
 *
 *  @discussion Method to update the values in the graph
 *
 */

-(void) updateLineGraph:(NSMutableArray *)xValues Y:(NSMutableArray *)yValues;

/*!
 *  @method setXaxisScaleWithValue
 *
 *  @discussion Method to set X axis scale
 *
 */
-(void) setXaxisScaleWithValue:(float)scale;


@end
