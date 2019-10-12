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

#import "MenuViewController.h"
#import "MenuTableViewCell.h"
#import "Reachability.h"
#import "Constants.h"

#define TABLE_IMAGEVIEW_LEADING_CONSTRAINT_CONSTANT     55.0
#define MENU_TABLE_CELL_IDENTIFIER                      @"menuTableCell"

#define menuItems           [NSArray arrayWithObjects:@"BLE Devices",@"Data Logger",@"Cypress",@"About",nil]
#define menuItemImages      [NSArray arrayWithObjects:@"cypress_BLE_products",@"settings",@"cypress",@"about",nil]

#define subMenuItems        [NSArray arrayWithObjects:@"Home",@"BLE Products",@"CySmart Mobile",@"Contact Us",nil]
#define subMenuItemImages   [NSArray arrayWithObjects:@"home",@"products",@"mobile",@"contact",nil]


/*!
 *  @class MenuViewController
 *
 *  @discussion Class to handle the menu related operations 
 *
 */
@interface MenuViewController ()
{
    NSMutableArray *menuItemsMutableArray;
    NSMutableArray *menuItemImagesMutableArray;
    
    BOOL isSubMenuVisible;
}

@end


@implementation MenuViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Do any additional setup after loading the view.
    
    if (!menuItemsMutableArray){
        menuItemsMutableArray = [NSMutableArray array];
    }
    
    if (!menuItemImagesMutableArray) {
        menuItemImagesMutableArray = [NSMutableArray array];
    }
   
    menuItemsMutableArray = [menuItems mutableCopy];
    menuItemImagesMutableArray = [menuItemImages mutableCopy];
    [self tableView:_menuTableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:2 inSection:0]];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - tableView delegates

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return menuItemsMutableArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    
    static NSString *menuTableCellIdentifier = MENU_TABLE_CELL_IDENTIFIER;
    MenuTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:menuTableCellIdentifier];
    
    if (cell == nil)
    {
        cell = [[MenuTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:menuTableCellIdentifier];
    }
    
    NSString *ItemName = [menuItemsMutableArray objectAtIndex:[indexPath row]];
    cell.menuItemLabel.text = ItemName ;
    cell.menuItemImageview.image = [UIImage imageNamed:[menuItemImagesMutableArray objectAtIndex:[indexPath row]]];
    
    if (isSubMenuVisible)
    {
        if ([indexPath row] > 2 && [indexPath row] < 7 && cell.menuItemImageViewLeadingConstraint.constant != TABLE_IMAGEVIEW_LEADING_CONSTRAINT_CONSTANT)
        {
            cell.menuItemImageViewLeadingConstraint.constant += 40;
        }
    }
    return cell;
}

/*!
 *  @method tableView: didSelectRowAtIndexPath:
 *
 *  @discussion Method to handle the selection in menu
 *
 */

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSInteger selectedIndex= [indexPath row];
    
    switch (selectedIndex)
    {
        case 0:
            // Show the bluetooth devices
            if (_delegate && [_delegate respondsToSelector:@selector(showBLEDEvices)])
            {
                [_delegate showBLEDEvices];
            }
            break;
        case 1:
            // Show Logger
            
            if (_delegate && [_delegate respondsToSelector:@selector(showLoggerView)])
            {
                [_delegate showLoggerView];
            }
            break;
        case 2:
            {
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(selectedIndex+1, 4)];
                NSArray *indexPathArray = [NSArray arrayWithObjects:[NSIndexPath indexPathForRow:selectedIndex+1 inSection:0],[NSIndexPath indexPathForRow:selectedIndex+2 inSection:0],[NSIndexPath indexPathForRow:selectedIndex+3 inSection:0],[NSIndexPath indexPathForRow:selectedIndex+4 inSection:0], nil];
                
                if (isSubMenuVisible)
                {
                    isSubMenuVisible = NO;
                    [menuItemsMutableArray removeObjectsAtIndexes:indexSet];
                    [menuItemImagesMutableArray removeObjectsAtIndexes:indexSet];
                    [_menuTableView deleteRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationTop];
                }
                else
                {
                    isSubMenuVisible = YES;
                    [menuItemsMutableArray insertObjects:subMenuItems atIndexes:indexSet];
                    [menuItemImagesMutableArray insertObjects:subMenuItemImages atIndexes:indexSet];
                    [_menuTableView insertRowsAtIndexPaths:indexPathArray withRowAnimation:UITableViewRowAnimationBottom];
                }
            }
            break;
        case 3:
            
            if (isSubMenuVisible)
            {
                // Show CySmart home
                if (_delegate && [_delegate respondsToSelector:@selector(showCypressHomePage)])
                {
                    [_delegate showCypressHomePage];
                }
            }
            else
            {
                // Show about
                if (_delegate && [_delegate respondsToSelector:@selector(showAboutView)])
                {
                    [_delegate showAboutView];
                }
            }
            break;
        case 4:
            
            // show the Cypress Products WebPage
            if (_delegate && [_delegate respondsToSelector:@selector(showCypressBLEProductsWebPage)])
            {
                [_delegate showCypressBLEProductsWebPage];
            }
            break;
        case 5:
            
            // Show mobile
            if (_delegate && [_delegate respondsToSelector:@selector(showCypressMobilePage)])
            {
                [_delegate showCypressMobilePage];
            }
            break;
            
        case 6:
            
            // show the Cypress contact WebPage
            
            if (_delegate && [_delegate respondsToSelector:@selector(showCypressContactWebPage)])
            {
                [_delegate showCypressContactWebPage];
            }
            break;
        case 7:
            // Show about
            
            if (_delegate && [_delegate respondsToSelector:@selector(showAboutView)])
            {
                [_delegate showAboutView];
            }
            break;
            
        default:
            break;
    
    }
    [_menuTableView deselectRowAtIndexPath:indexPath animated:NO];
}

@end
