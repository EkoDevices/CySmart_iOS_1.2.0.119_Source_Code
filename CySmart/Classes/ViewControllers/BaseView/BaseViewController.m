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

#import "BaseViewController.h"
#import "MenuViewController.h"
#import "ResourceHandler.h"
#import "Reachability.h"
#import "Constants.h"
#import "AboutView.h"
#import "Utilities.h"
#import "LoggerViewController.h"
#import "ProgressHandler.h"

#define VIEW_COMMON_TAG 11111

#define MENU_VIEW_ID       @"MenuViewID"
#define MENU_ICON_IMAGE    @"rightMenuIcon"
#define SHARE_IMAGE        @"share"
#define SEARCH_ICON_IMAGE  @"SearchIcon"
#define VIEW_KEY           @"view"
#define LOGGER_VIEW_ID     @"LoggerViewID"
#define OFFLINE_VIEW_ID    @"OffLineContactUsView"
#define POPOVER_CONTROLLER @"UIPopoverPresentationController"

#define IMAGE_NAME         @"image.jpg"



static NSInteger const kNavButtonWidth = 40;

/*!
 *  @class BaseViewController
 *
 *  @discussion Class that act as a base for all the other view controllers. It initializes the UI and handles all the menu related operations
 *
 */

@interface BaseViewController () <MenuViewControllerDelegate, UISearchBarDelegate>
{
    MenuViewController *rightMenuViewController;
    CGFloat initialMenuViewLeadingConstraintValue, currentViewWidth;
    BOOL isRightMenuPresent, isTitleViewSearchBar;
    AboutView *appDetailsView;
    UIView *offlineContactUsView;
}

@end

@implementation BaseViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    [self addNavigationBarView];
    [self addrightMenuView];
    currentViewWidth = self.view.frame.size.width;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma mark - Setup rightMenu

/*!s
 *  @Method addrightMenuView
 *
 *  @discussion  Add right Menu to the BaseView.
 *
 */

-(void) addrightMenuView
{
    if (!rightMenuViewController)
    {
        rightMenuViewController = [self.storyboard instantiateViewControllerWithIdentifier:MENU_VIEW_ID];
        [self.view addSubview:rightMenuViewController.view];
        [self.view bringSubviewToFront:rightMenuViewController.view];
        
        rightMenuViewController.view.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height+NAV_BAR_HEIGHT,
                                                        self.view.frame.size.width, self.view.frame.size.height - NAV_BAR_HEIGHT);
        rightMenuViewController.delegate = self;
        rightMenuViewController.rightMenuViewWidthConstraint.constant = 0.0f;
        [rightMenuViewController.view layoutIfNeeded];
        rightMenuViewController.view.hidden = YES;
    }
}

#pragma mark - Setup navigation bar

/*!
 *  @Method addNavigationBarView
 *
 *  @discussion  Method to add Custom Navigation bar
 *
 */

-(void) addNavigationBarView
{
    [self.navigationController.navigationBar setBackgroundImage:[UIImage new]
                                                  forBarMetrics:UIBarMetricsDefault];
    self.navigationController.navigationBar.shadowImage = nil;
    self.navigationController.navigationBar.translucent = YES;
    self.navigationController.navigationBar.backgroundColor = BLUE_COLOR;
    
    
    CGRect labelFrame = CGRectMake(-5, 0, [[UIScreen mainScreen] bounds].size.width, NAV_BAR_HEIGHT);
    // Add Navbar title label
    _navBarTitleLabel = [[UILabel alloc] initWithFrame:labelFrame];
    _navBarTitleLabel.backgroundColor = [UIColor clearColor];
    _navBarTitleLabel.textAlignment = NSTextAlignmentLeft;
    _navBarTitleLabel.textColor = [UIColor whiteColor];
    _navBarTitleLabel.text = @"";
    
    // Add NavBar buttons
    _rightMenuButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kNavButtonWidth, NAV_BAR_HEIGHT)];
    [_rightMenuButton setImage:[UIImage imageNamed:MENU_ICON_IMAGE] forState:UIControlStateNormal];
    [_rightMenuButton addTarget:self action:@selector(rightMenuButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    
    _shareButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kNavButtonWidth, NAV_BAR_HEIGHT)];
    [_shareButton setImage:[UIImage imageNamed:SHARE_IMAGE] forState:UIControlStateNormal];
    [_shareButton addTarget:self action:@selector(shareButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.titleView = _navBarTitleLabel;
    isTitleViewSearchBar = NO;
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithCustomView:_rightMenuButton],[[UIBarButtonItem alloc] initWithCustomView:_shareButton], nil];
    
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@" " style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.tintColor=[UIColor whiteColor];
}

/*!
 *  @Method addSearchButtonToNavBar
 *
 *  @discussion  Method to add search button to navigation bar
 *
 */

-(void) addSearchButtonToNavBar
{
    _searchButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kNavButtonWidth, NAV_BAR_HEIGHT)];
    [_searchButton setImage:[UIImage imageNamed:SEARCH_ICON_IMAGE] forState:UIControlStateNormal];
    [_searchButton addTarget:self action:@selector(replaceNavBarTitleWithSearchBar) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithCustomView:_rightMenuButton],[[UIBarButtonItem alloc] initWithCustomView:_shareButton],[[UIBarButtonItem alloc] initWithCustomView:_searchButton], nil];
    
    CGRect titleFrame = CGRectMake(-5, 0, [[UIScreen mainScreen] bounds].size.width, NAV_BAR_HEIGHT);
    self.navBarTitleLabel.frame = titleFrame;
    self.navigationItem.titleView = _navBarTitleLabel;
    isTitleViewSearchBar = NO;
}

/*!
 *  @Method removeSearchButtonFromNavBar
 *
 *  @discussion  Method to remove search button from navigation bar
 *
 */

-(void) removeSearchButtonFromNavBar
{
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithCustomView:_rightMenuButton],[[UIBarButtonItem alloc] initWithCustomView:_shareButton], nil];
}

/*!
 *  @Method replaceNavBarTitleWithSearchBar
 *
 *  @discussion  Method to replace the titl with search bar
 *
 */

-(void) replaceNavBarTitleWithSearchBar
{
    _searchButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kNavButtonWidth, NAV_BAR_HEIGHT)];
    [_searchButton setImage:[UIImage imageNamed:SEARCH_ICON_IMAGE] forState:UIControlStateNormal];
    [_searchButton addTarget:self action:@selector(addSearchButtonToNavBar) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithCustomView:_rightMenuButton],[[UIBarButtonItem alloc] initWithCustomView:_shareButton],[[UIBarButtonItem alloc] initWithCustomView:_searchButton], nil];
    
    _searchBar = [UISearchBar new];
    _searchBar.delegate = self;
    _searchBar.tintColor = BLUE_COLOR;
    _searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    _searchBar.autocorrectionType = UITextAutocorrectionTypeNo;
    _searchBar.returnKeyType = UIReturnKeyDone;

    self.navigationItem.titleView = _searchBar;
    [_searchBar becomeFirstResponder];
    isTitleViewSearchBar = YES;
}

/*!
 *  @Method addCustomBackButtonToNavBar
 *
 *  @discussion  Method to add custom back button to navigation bar
 *
 */

-(void) addCustomBackButtonToNavBar
{
    UIBarButtonItem * backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:BACK_BUTTON_IMAGE] landscapeImagePhone:[UIImage imageNamed:BACK_BUTTON_IMAGE] style:UIBarButtonItemStyleDone target:self action:@selector(showBLEDEvices)];
    self.navigationItem.leftBarButtonItem = backButton;
    self.navigationItem.leftBarButtonItem.imageInsets = UIEdgeInsetsMake(0, -5, 0, 0);
}

/*!
 *  @Method removeCustomBackButtonFromNavBar
 *
 *  @discussion  Method to remove custom back button from navigation bar
 *
 */

-(void) removeCustomBackButtonFromNavBar
{
    if (self.navigationItem.leftBarButtonItem != nil)
    {
        self.navigationItem.leftBarButtonItem  = nil;
    }
}

#pragma mark - Navigation Bar button events

/*!
 *  @method rightMenuButtonClicked:
 *
 *  @discussion Method to show and hide the menu
 *
 */

-(IBAction)rightMenuButtonClicked:(id)sender
{
    // menu button action
    
    if (!isRightMenuPresent)
    {
        [self presentRightMenuView];
    }
    else
    {
        [self removeRightMenuView];
        
    }
}

/*!
 *  @method shareButtonClicked:
 *
 *  @discussion Method to handle share button click
 *
 */

-(IBAction)shareButtonClicked:(id)sender
{
    // check whether the present viewcontroller is logger or not.
    
    if (![self.navBarTitleLabel.text isEqualToString:LOGGER])
    {
        [self captureScreen:sender];
        
    }
    else
    {
        // Send the .txt file for logger view controller
        
        LoggerViewController *loggerVC = [self.navigationController.viewControllers lastObject];
        NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
        NSString *filePath = [docsPath stringByAppendingPathComponent:loggerVC.currentLogFileName];
        NSURL *textFileUrl = [NSURL fileURLWithPath:filePath];
        
        NSError *error;
        [loggerVC.loggerTextView.text writeToURL:textFileUrl atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        NSArray *shareExcludedActivitiesArray = @[UIActivityTypeCopyToPasteboard,UIActivityTypeAssignToContact,UIActivityTypeMessage,UIActivityTypePostToFacebook,UIActivityTypePostToTwitter];
        [self showActivityPopover:textFileUrl Rect:[(UIButton *)sender frame] excludedActivities:shareExcludedActivitiesArray];
    }
}

#pragma mark - NavBar button utility methods
/*!
 *  @Method captureScreen
 *
 *  @discussion  Method to capture screen to share
 *
 */
-(void)captureScreen:(id)sender
{
    if ([[UIScreen mainScreen] respondsToSelector:@selector(scale)])
        UIGraphicsBeginImageContextWithOptions([UIApplication sharedApplication].keyWindow.bounds.size, NO, [UIScreen mainScreen].scale);
    else
        UIGraphicsBeginImageContext([UIApplication sharedApplication].keyWindow.bounds.size);
    
    [[UIApplication sharedApplication].keyWindow.rootViewController.view drawViewHierarchyInRect:[UIApplication sharedApplication].keyWindow.bounds afterScreenUpdates:YES];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self showActivityPopover:[self saveImage:image] Rect:[(UIButton*)sender frame] excludedActivities:nil];
}

/*!
 *  @method saveImage:
 *
 *  @discussion Method to save image to the document path
 *
 */

-(NSURL*)saveImage:(UIImage *)image
{
    UIImage *shareImg=image;
    NSData *compressedImage = UIImageJPEGRepresentation(shareImg, 0.8 );
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *imagePath = [docsPath stringByAppendingPathComponent:IMAGE_NAME];
    NSURL *imageUrl     = [NSURL fileURLWithPath:imagePath];
    [compressedImage writeToURL:imageUrl atomically:YES];
    return imageUrl;
}

/*!
 *  @Method showActivityPopover:Rect
 *
 *  @discussion  Method to show share window
 *
 */
-(void)showActivityPopover:(NSURL *)pathUrl Rect:(CGRect)rect excludedActivities:(NSArray *)excludedActivityTypes
{
    NSArray *imageToShare=[NSArray arrayWithObjects:SHARE_IMAGE,pathUrl , nil];
    UIActivityViewController *shareAction=[[UIActivityViewController alloc]initWithActivityItems:imageToShare applicationActivities:nil];
    if (NSClassFromString(POPOVER_CONTROLLER))
    {
        shareAction.popoverPresentationController.sourceView = self.parentViewController.view;
        shareAction.popoverPresentationController.sourceRect = rect;
    }
    
    if (excludedActivityTypes != nil)
    {
        shareAction.excludedActivityTypes = excludedActivityTypes;
    }
    else
        shareAction.excludedActivityTypes=@[UIActivityTypeCopyToPasteboard,UIActivityTypeAssignToContact,UIActivityTypeMessage];
    
    [self presentViewController:shareAction animated:TRUE completion:nil];
    
}

#pragma mark - MenuViewController Delegate

/*!
 *  @method presentRightMenuView
 *
 *  @discussion Method to animatedly present the right menu
 *
 */

-(void) presentRightMenuView
{
    [self addSearchButtonToNavBar];
    [self removeSearchButtonFromNavBar];
    rightMenuViewController.view.hidden = NO;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        if (self.view.frame.size.width > self.view.frame.size.height) {
            rightMenuViewController.rightMenuViewWidthConstraint.constant = rightMenuViewController.view.frame.size.width - (rightMenuViewController.view.frame.size.width * 0.5);
        }else{
            rightMenuViewController.rightMenuViewWidthConstraint.constant = rightMenuViewController.view.frame.size.width - (rightMenuViewController.view.frame.size.width * 0.4);
        }
    }else{
        rightMenuViewController.rightMenuViewWidthConstraint.constant = rightMenuViewController.view.frame.size.width - 50;
    }
    [UIView animateWithDuration:.5 animations:^{
        [rightMenuViewController.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        isRightMenuPresent = YES;
        if (rightMenuViewController.rightMenuView.frame.size.width == 0) {
            [rightMenuViewController.view removeFromSuperview];
            rightMenuViewController.rightMenuViewWidthConstraint.constant = 0.0f;
            [self.view layoutSubviews];
            [self.view addSubview:rightMenuViewController.view];
            rightMenuViewController.rightMenuViewWidthConstraint.constant = rightMenuViewController.view.frame.size.width - 50;
            [UIView animateWithDuration:0.5 animations:^{
                [rightMenuViewController.view layoutIfNeeded];
            }];
        }
    }];
}


/*!
 *  @method removeRightMenuView
 *
 *  @discussion Method to animatedly hide the right menu
 *
 */
-(void) removeRightMenuView
{
    rightMenuViewController.rightMenuViewWidthConstraint.constant =0.0f;
    [UIView animateWithDuration:0.5 animations:^{
        [rightMenuViewController.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        isRightMenuPresent = NO;
        rightMenuViewController.view.hidden = YES;
        if ([_navBarTitleLabel.text isEqualToString:BLE_DEVICE]) {
            [self addSearchButtonToNavBar];
        }
    }];
}

/*!
 *  @method showCypressBLEProductsWebPage
 *
 *  @discussion Method to show the web page of Cypress BLE Products
 *
 */
-(void) showCypressBLEProductsWebPage
{
    // Remove other views
    [self removeRightMenuView];
    [self removeLastShowedView];
    
    // Check internet connectivity
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus connectionStatus = [networkReachability currentReachabilityStatus];
    
    if (connectionStatus != NotReachable)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:BLE_PRODUCTS_URL]];
    }
    else
    {
        [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"internetUnavailbleAlert")];
    }
}


/*!
 *  @method showCypressContactWebPage
 *
 *  @discussion Method to show the webpage of Cypress contact webpage
 *
 */
-(void) showCypressContactWebPage
{

    // Remove other views
    [self removeRightMenuView];
    [self removeLastShowedView];
    
    // Check internet connectivity
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus connectionStatus = [networkReachability currentReachabilityStatus];
    
    if (connectionStatus != NotReachable)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:CONTACT_URL]];
    }
    
    else
    {
        _navBarTitleLabel.text = CONTACT_US;
        
        // Add custom back button
        [self addCustomBackButtonToNavBar];
        
        offlineContactUsView = nil;
        if (!offlineContactUsView) {
            UIViewController * contactUsVC = [self.storyboard instantiateViewControllerWithIdentifier:OFFLINE_VIEW_ID];
            offlineContactUsView = contactUsVC.view;
            offlineContactUsView.frame = CGRectMake(0, [UIApplication sharedApplication].statusBarFrame.size.height+NAV_BAR_HEIGHT, self.view.frame.size.width, self.view.frame.size.height);
        }
        [self.view insertSubview:offlineContactUsView belowSubview:rightMenuViewController.view];
        offlineContactUsView.tag = VIEW_COMMON_TAG;
    }
}

/*!
 *  @method showCySmartHomePage
 *
 *  @discussion Method to show cypress home page
 *
 */
-(void) showCypressHomePage
{
    // Remove other views
    [self removeRightMenuView];
    [self removeLastShowedView];
    
    // Check internet connectivity
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus connectionStatus = [networkReachability currentReachabilityStatus];
    
    if (connectionStatus != NotReachable)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:CYPRESS_HOME_URL]];
    }
    else
    {
        [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"internetUnavailbleAlert")];
    }
}

/*!
 *  @method showCypressMobilePage
 *
 *  @discussion Method to show cypress mobile page
 *
 */

-(void) showCypressMobilePage
{
    // Remove other views
    [self removeRightMenuView];
    [self removeLastShowedView];
    
    // Check internet connectivity
    Reachability *networkReachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus connectionStatus = [networkReachability currentReachabilityStatus];
    
    if (connectionStatus != NotReachable)
    {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:CYPRESS_MOBILE_URL]];
    }
    else
    {
        [Utilities alertWithTitle:APP_NAME message:LOCALIZEDSTRING(@"internetUnavailbleAlert")];
    }
}


/*!
 *  @method showAboutView
 *
 *  @discussion Method to show the about view
 *
 */
-(void) showAboutView
{
    _navBarTitleLabel.text = ABOUT_US;
    
    // Remove other views
    [self removeRightMenuView];
    [self removeLastShowedView];
    
    // Add custom back button
    [self addCustomBackButtonToNavBar];
    appDetailsView = nil;
    if (!appDetailsView)
    {
        appDetailsView = [[AboutView alloc] initWithFrame:self.view.frame];
        appDetailsView.tag = VIEW_COMMON_TAG;
    }
    [self.view insertSubview:appDetailsView belowSubview:rightMenuViewController.view];
}

/*!
 *  @method showLoggerView
 *
 *  @discussion Method to show loggerview
 *
 */
-(void)showLoggerView
{
    // Remove other views
    [self removeRightMenuView];
    [self removeLastShowedView];
    
    [_navBarTitleLabel setText:LOGGER];
    if (![[self.navigationController.viewControllers lastObject] isKindOfClass:[LoggerViewController class]])
    {
        LoggerViewController *logger = [self.storyboard instantiateViewControllerWithIdentifier:LOGGER_VIEW_ID];
        [self.navigationController pushViewController:logger animated:YES];
    }
}

/*!
 *  @method removeLastShowedView
 *
 *  @discussion Method to remove the last showed view
 *
 */
-(void)removeLastShowedView
{
    UIView *lastView = [self.view viewWithTag:VIEW_COMMON_TAG];
    [lastView removeFromSuperview];
    
    [self removeCustomBackButtonFromNavBar];
}


/*!
 *  @method showBLEDEvices
 *
 *  @discussion Method to move to home screen
 *
 */
-(void) showBLEDEvices
{
    // Remove other views
    [self removeLastShowedView];
    [self removeRightMenuView];
    [self addSearchButtonToNavBar];
    if ([[self.navigationController.viewControllers lastObject] isKindOfClass:[LoggerViewController class]])
    {
        [self.navigationController popViewControllerAnimated:NO];
    }
    
    _navBarTitleLabel.text = DEVICES;
    // Move to home screen
    [self.navigationController popToRootViewControllerAnimated:YES];
}


-(void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    currentViewWidth = self.view.frame.size.height;
    if (!rightMenuViewController.view.isHidden) {
        if (toInterfaceOrientation == UIInterfaceOrientationPortrait) {
            rightMenuViewController.rightMenuViewWidthConstraint.constant = rightMenuViewController.view.frame.size.height - (rightMenuViewController.view.frame.size.height * 0.4);
        }else{
            rightMenuViewController.rightMenuViewWidthConstraint.constant = rightMenuViewController.view.frame.size.height - (rightMenuViewController.view.frame.size.height * 0.5);
        }
        [UIView animateWithDuration:duration animations:^{
            [rightMenuViewController.view layoutIfNeeded];
        }];
    }
    
    //Left aligning the Title View
    if (isTitleViewSearchBar) {
        if (self.navigationItem.rightBarButtonItems.count > 2) {
            NSString * searchString = _searchBar.text;
            [self replaceNavBarTitleWithSearchBar];
            _searchBar.text = searchString;
        }
    }else{
        _navBarTitleLabel.frame = CGRectMake(-5, 0, [[UIScreen mainScreen] bounds].size.height, NAV_BAR_HEIGHT);
        self.navigationItem.titleView = _navBarTitleLabel;
    }
}

@end
