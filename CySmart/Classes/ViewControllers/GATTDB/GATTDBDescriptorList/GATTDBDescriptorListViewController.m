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
#import "GATTDBDescriptorListViewController.h"
#import "GATTDBDescriptorDetailsViewController.h"
#import "DescriptorListTableViewCell.h"
#import "CyCBManager.h"
#import "Utilities.h"

#define DESCRIPTOR_DETAILS_SEGUE    @"descriptorDetailsSegue"
#define DESCRIPTOR_CELL_IDENTIFIER   @"descriptorCellID"

/*!
 *  @class GATTDBDescriptorListViewController
 *
 *  @discussion Class to handle the descriptor list
 *
 */
@interface GATTDBDescriptorListViewController () <UITableViewDataSource,UITableViewDelegate>
{
    NSArray *descriptorArray;
    CBUUID * selectedUUID;
    CBDescriptor * selectedDescriptor;
}

@end

@implementation GATTDBDescriptorListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    descriptorArray = [[CyCBManager sharedManager] characteristicDescriptors];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [[super navBarTitleLabel] setText:GATT_DB];
}
/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark - TableView Datasource Methods

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return descriptorArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = DESCRIPTOR_CELL_IDENTIFIER;
    
    DescriptorListTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (cell == nil)
    {
        cell = [[DescriptorListTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    /*  Update datafields */
    CBDescriptor *descriptor = [descriptorArray objectAtIndex:[indexPath row]];
    cell.descriptorUUIDLabel.text = [Utilities get128BitUUIDForUUID:descriptor.UUID];
    cell.descriptionLabel.text = [Utilities getDiscriptorNameForUUID:descriptor.UUID];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 92.0;
}

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIImageView *bgImageView = [[UIImageView alloc] initWithFrame:cell.bounds];
    bgImageView.image = [UIImage imageNamed:CELL_BG_IMAGE];
    cell.backgroundView = bgImageView;
}

#pragma mark - TableView Delegate Methods
/*!
 *  @method tableView: didSelectRowAtIndexPath:
 *
 *  @discussion Method to handle the selection of a descriptor
 *
 */

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    selectedDescriptor = [descriptorArray objectAtIndex:indexPath.row];
    [self performSegueWithIdentifier:DESCRIPTOR_DETAILS_SEGUE sender:nil];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Segue Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:DESCRIPTOR_DETAILS_SEGUE]) {
        GATTDBDescriptorDetailsViewController * detailsVC = segue.destinationViewController;
        detailsVC.descriptor = selectedDescriptor;
        detailsVC.serviceName = self.serviceName;
        detailsVC.characteristicName = self.characteristicName;
    }
}


@end
