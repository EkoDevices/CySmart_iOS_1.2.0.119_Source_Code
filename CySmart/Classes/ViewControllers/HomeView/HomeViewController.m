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

#import "HomeViewController.h"
#import "ScannedPeripheralTableViewCell.h"
#import "CyCBManager.h"
#import "CBPeripheralExt.h"
#import "ProgressHandler.h"
#import "Utilities.h"
#import "UIView+Toast.h"

#define CAROUSEL_SEGUE              @"CarouselViewID"
#define PERIPHERAL_CELL_IDENTIFIER  @"peripheralCell"

/*!
 *  @class HomeViewController
 *
 *  @discussion Class to handle the available device listing and connection
 *
 */
@interface HomeViewController ()<UITableViewDataSource, UITableViewDelegate, cbDiscoveryManagerDelegate, UISearchBarDelegate>
{
    __weak IBOutlet UILabel *refreshingStatusLabel;
    UIRefreshControl *refreshPeripheralListControl;
    BOOL isBluetoothON, isSearchActive;
    NSArray *searchResults;
}

@property (weak, nonatomic) IBOutlet UITableView *scannedPeripheralsTableView;

@end

@implementation HomeViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self addRefreshControl];
    if ([[[NSUserDefaults standardUserDefaults] valueForKey:LOCALIZEDSTRING(@"OTAUpgradeStatus")] boolValue]) {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:LOCALIZEDSTRING(@"OTAUpgradeStatus")];

        UIAlertView * alert = [[UIAlertView alloc] initWithTitle:APP_NAME message:LOCALIZEDSTRING(@"OTAAppUpgradePendingWarning") delegate:self cancelButtonTitle:OK otherButtonTitles:nil, nil];
        [alert show];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self addSearchButtonToNavBar];
    [[self navBarTitleLabel] setText:BLE_DEVICE];
}

-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [[CyCBManager sharedManager] disconnectPeripheral:[[CyCBManager sharedManager] myPeripheral]];
    [[CyCBManager sharedManager] setCbDiscoveryDelegate:self];
    
    // Start scanning for devices
    [[CyCBManager sharedManager] startScanning];
}

-(void)viewDidDisappear:(BOOL)animated
{
    [[CyCBManager sharedManager] stopScanning];
    [super removeSearchButtonFromNavBar];
}

#pragma mark - UISearchBarDelegate
// called when text starts editing
- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar {
    isSearchActive = YES;
}

// called when text ends editing
- (void)searchBarTextDidEndEditing:(UISearchBar *)searchBar {
//    isSearchActive = NO;
}

// called before text changes
- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text {
    NSString *searchString = text.length == 0 ? [searchBar.text substringToIndex:searchBar.text.length-1] : [NSString stringWithFormat:@"%@%@",searchBar.text, text];
    if (searchString.length == 0) {
        isSearchActive = NO;
        [_scannedPeripheralsTableView reloadData];
    }else{
        isSearchActive = YES;
        [self searchBLEPeripheralsNamesForSubString:searchString onFinish:^(NSArray *filteredPeripheralList) {
            searchResults = [[NSArray alloc] initWithArray:filteredPeripheralList];
            [_scannedPeripheralsTableView reloadData];
        }];
    }
    return YES;
}

// called when keyboard search button pressed
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

#pragma mark - Search Filter Method

- (void) searchBLEPeripheralsNamesForSubString:(NSString *)searchString onFinish:(void(^)(NSArray *filteredPeripheralList))finish
{
    if (searchString) {
        searchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    }
    NSMutableArray *filteredPeripheralList = [NSMutableArray new];
    for (CBPeripheralExt *peripheral in [[CyCBManager sharedManager] foundPeripherals])
    {
        if (peripheral.mPeripheral.name.length > 0){
                if ([[peripheral.mPeripheral.name lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound) {
                    [filteredPeripheralList addObject:peripheral];
            }
        }
        else
        {
            if ([[LOCALIZEDSTRING(@"unknownPeripheral") lowercaseString] rangeOfString:[searchString lowercaseString]].location != NSNotFound) {
                [filteredPeripheralList addObject:peripheral];
            }
        }
    }
    finish((NSArray *)filteredPeripheralList);
}

#pragma mark - RefreshControl
/*!
 *  @method addRefreshControl
 *
 *  @discussion Method to add a control for pull to refresh functonality .
 *
 */
-(void)addRefreshControl
{
    refreshPeripheralListControl = [[UIRefreshControl alloc] init];
    [refreshPeripheralListControl addTarget:self action:@selector(refreshPeripheralList:) forControlEvents:UIControlEventValueChanged];
    [_scannedPeripheralsTableView addSubview:refreshPeripheralListControl];
}

#pragma mark - TableView Datasource

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return isBluetoothON ? LOCALIZEDSTRING(@"pullToRefresh") : LOCALIZEDSTRING(@"bluetoothTurnOnAlert") ;
}

-(CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 60.0f;
}

- (void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section
{
    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
    CGRect headerFrame = header.frame;
    header.textLabel.frame = headerFrame;
    [header.textLabel setTextColor:[UIColor colorWithRed:12.0/255.0 green:55.0/255.0 blue:123.0/255.0 alpha:1.0]];
    header.textLabel.textAlignment = NSTextAlignmentCenter;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 81.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 81.0f;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (isBluetoothON) {
        if (isSearchActive) {
            return searchResults.count;
        }
        return [[[CyCBManager sharedManager] foundPeripherals] count];
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ScannedPeripheralTableViewCell *currentCell=[tableView dequeueReusableCellWithIdentifier:PERIPHERAL_CELL_IDENTIFIER];
    if (isSearchActive) {
        [currentCell setDiscoveredPeripheralDataFromPeripheral:[searchResults objectAtIndex:indexPath.row] ];
    }else{
        [currentCell setDiscoveredPeripheralDataFromPeripheral:[[[CyCBManager sharedManager] foundPeripherals] objectAtIndex:indexPath.row] ];
    }
    
    return currentCell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIImageView *cellBGImageView=[[UIImageView alloc]initWithFrame:cell.bounds];
    UIImage *buttonImage = [[UIImage imageNamed:CELL_BG_IMAGE]
                            resizableImageWithCapInsets:UIEdgeInsetsMake(2, 10, 2, 10)];
    [cellBGImageView setImage:buttonImage];
    cell.backgroundView=cellBGImageView;
}

#pragma mark - TableView Delegates

/*!
 *  @method tableView: didSelectRowAtIndexPath:
 *
 *  @discussion Method to handle the device selection
 *
 */

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (isBluetoothON) {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self connectPeripheral:indexPath.row];
    }
}
#pragma mark -Table Update

/*!
 *  @method refreshPeripheralList:
 *
 *  @discussion Method to refresh the device list
 *
 */

-(void)refreshPeripheralList:(UIRefreshControl*) refreshControl
{
    if(refreshControl)
    {
        self.searchBar.text = @""; // Reset filter
        isSearchActive = NO;
        [refreshControl endRefreshing];
        [[CyCBManager sharedManager] refreshPeripherals];
    }
}

#pragma mark - TableView Refresh

/*!
 *  @method reloadPeripheralTable
 *
 *  @discussion Method to reload the device list
 *
 */

-(void)reloadPeripheralTable
{
    if (!isSearchActive) {
        [_scannedPeripheralsTableView reloadData];
    }
}

-(void)discoveryDidRefresh
{
    [self reloadPeripheralTable];
}

#pragma mark - BlueTooth Turned Off Delegate

/*!
 *  @method bluetoothStateUpdatedToState:
 *
 *  @discussion Method to be called when state of Bluetooth changes
 *
 */

-(void)bluetoothStateUpdatedToState:(BOOL)state
{
    isBluetoothON = state;
    [self reloadPeripheralTable];
    isBluetoothON ? [_scannedPeripheralsTableView setScrollEnabled:YES] : [_scannedPeripheralsTableView setScrollEnabled:NO];
}

#pragma mark - Connect Peripheral

/*!
 *  @method connectPeripheral:
 *
 *  @discussion Method to connect the selected peripheral
 *
 */

-(void)connectPeripheral:(NSInteger)index
{
    if ([[CyCBManager sharedManager] foundPeripherals].count != 0)
    {
        CBPeripheralExt *selectedBLE = [[[CyCBManager sharedManager] foundPeripherals] objectAtIndex:index];
        [[ProgressHandler sharedInstance] showWithTitle:LOCALIZEDSTRING(@"connecting") detail:selectedBLE.mPeripheral.name];
        
        [[CyCBManager sharedManager] connectPeripheral:selectedBLE.mPeripheral completionHandler:^(BOOL success, NSError *error)
        {
            [[ProgressHandler sharedInstance] hideProgressView];
            if(success)
            {
                [self performSegueWithIdentifier:CAROUSEL_SEGUE sender:self];
            }
            else
            {
                if(error)
                {
                    NSString *errorString = [error.userInfo valueForKey:NSLocalizedDescriptionKey];
                    if(errorString.length)
                    {
                        [self.view makeToast:errorString];
                    }
                    else
                    {
                        [self.view makeToast:LOCALIZEDSTRING(@"unknownError")];
                    }
                }
            }
        }];
    }
    else
    {
        [[CyCBManager sharedManager] refreshPeripherals];
    }
}

@end
