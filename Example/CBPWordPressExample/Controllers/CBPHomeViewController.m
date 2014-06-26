//
//  CBPHomeViewController.m
//  CBPWordPressExample
//
//  Created by Karl Monaghan on 21/06/2014.
//  Copyright (c) 2014 Crayons and Brown Paper. All rights reserved.
//

#import <SVPullToRefresh/SVPullToRefresh.h>
#import "UIImageView+AFNetworking.h"

#import "CBPHomeViewController.h"

#import "CBPAboutViewController.h"
#import "CBPSubmitTipViewController.h"

@interface CBPHomeViewController () <UISearchBarDelegate>
@property (nonatomic) UISearchBar *searchBar;
@property (nonatomic) UILabel *searchDetailLabel;
@property (nonatomic) UIView *searchDetailView;
@property (nonatomic) NSLayoutConstraint *searchDetailViewHeightConstraint;
@property (nonatomic) UIImageView *titleImageView;
@end

@implementation CBPHomeViewController
- (void)loadView
{
    [super loadView];

    [self.view addSubview:self.searchDetailView];
    
    NSDictionary *views = @{@"topLayoutGuide": self.topLayoutGuide,
                            @"searchDetailView": self.searchDetailView};
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[topLayoutGuide][searchDetailView]"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[searchDetailView]|"
                                                                      options:0
                                                                      metrics:nil
                                                                        views:views]];
    self.searchDetailViewHeightConstraint = [NSLayoutConstraint constraintWithItem:self.searchDetailView
                                                                         attribute:NSLayoutAttributeHeight
                                                                         relatedBy:NSLayoutRelationEqual
                                                                            toItem:nil
                                                                         attribute:NSLayoutAttributeNotAnAttribute
                                                                        multiplier:1.0f
                                                                          constant:0];
    [self.view addConstraint:self.searchDetailViewHeightConstraint];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoLight];
    
    button.frame = CGRectMake(button.frame.origin.x, button.frame.origin.y, button.frame.size.width + 13, button.frame.size.height);
    
    [button addTarget:self action:@selector(aboutAction) forControlEvents:UIControlEventTouchUpInside];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCamera
                                                                                           target:self
                                                                                           action:@selector(tipAction)];
    self.titleImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed: @"broadsheet_black"]];
    
    self.navigationItem.titleView = self.titleImageView;
    
    [self updateHeaderImage];
    
    self.tableView.tableHeaderView = self.searchBar;
    
    self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchBar.frame));
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updatePosts)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [self.searchBar resignFirstResponder];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIApplicationWillEnterForegroundNotification
                                                  object:nil];
}

#pragma mark -
- (void)backgroundUpdateWithCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler
{
    if ([self.searchBar.text length]) {
        return;
    }
    
    [self.dataSource updateWithBlock:^(BOOL result, NSError *error) {
        if (error) {
            completionHandler(UIBackgroundFetchResultFailed);
            return;
        }
        
        if (result) {
            completionHandler(UIBackgroundFetchResultNewData);
            
            [self.tableView reloadData];
        } else {
            completionHandler(UIBackgroundFetchResultNoData);
        };
    }];
}

#pragma mark -
- (void)aboutAction
{
    CBPAboutViewController *vc = [[CBPAboutViewController alloc] initWithStyle:UITableViewStyleGrouped];
    
    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self.navigationController presentViewController:navController
                                            animated:YES
                                          completion:nil];
}

- (void)cancelSearchAction
{
    [self.searchBar resignFirstResponder];
    
    self.searchBar.text = @"";
    
    self.searchBar.showsCancelButton = NO;
    
    self.searchDetailViewHeightConstraint.constant = 0;
    
    [self.view layoutIfNeeded];
    
    [self load:NO];
}

- (void)tipAction
{
    CBPSubmitTipViewController *vc = [[CBPSubmitTipViewController alloc] initWithStyle:UITableViewStyleGrouped];

    UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
    
    [self.navigationController presentViewController:navController
                                            animated:YES
                                          completion:nil];
}

#pragma mark -
- (NSDictionary *)generateParams
{
    NSMutableDictionary *params = [super generateParams].mutableCopy;
    
    if ([self.searchBar.text length]) {
        params[CBPSearchQuery] = self.searchBar.text;
    }
    
    return params;
}

- (void)load:(BOOL)more
{
    if (!more) {
        [UIView animateWithDuration:0.3f animations:^(void) {
            self.tableView.contentOffset = CGPointMake(0, CGRectGetHeight(self.searchBar.frame));
        }];
    }
    
    [super load:more];
}

#pragma mark -
- (void)updateHeaderImage
{
    __weak typeof(self) weakSelf = self;
    
    [self.titleImageView setImageWithURLRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://broadsheet.ie/logo/iphone_logo.png"]]
                               placeholderImage:[UIImage imageNamed: @"broadsheet_black"]
                                        success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                            NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
                                            NSString *filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"header.png"];

                                            dispatch_async(dispatch_queue_create("com.crayonsandbrownpaper.myqueue", 0), ^{
                                                [UIImagePNGRepresentation(image) writeToFile:filePath atomically:YES];
                                            });
                                            
                                            __strong typeof(self) strongSelf = weakSelf;
                                            strongSelf.titleImageView.image = image;
                                            strongSelf.navigationItem.titleView = strongSelf.titleImageView;
                                        }
                                        failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                            NSLog(@"Error: %@", error);
                                        }];
}

- (void)updatePosts
{
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CBPBackgroundUpdate]) {
        return;
    }
    
    [self.tableView triggerPullToRefresh];
}

- (void)showSearchBanner
{
    self.searchDetailLabel.text = [NSString stringWithFormat:NSLocalizedString(@"Search for: %@", nil), self.searchBar.text];
    
    [self.searchDetailLabel sizeToFit];
    
    self.searchDetailViewHeightConstraint.constant = CGRectGetHeight(self.searchDetailLabel.frame) + 20.0f;
    
    [UIView animateWithDuration:0.3f animations:^(void) {
        [self.view layoutIfNeeded];
    }];
}

#pragma mark - UIScrollViewDelegate
- (BOOL)scrollViewShouldScrollToTop:(UIScrollView *)scrollView
{
    [scrollView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchBar.frame)) animated:YES];
    
    return NO;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if ((scrollView.contentOffset.y > 0) && (scrollView.contentOffset.y < CGRectGetHeight(self.searchBar.frame)))
    {
        [scrollView setContentOffset:CGPointMake(0, CGRectGetHeight(self.searchBar.frame)) animated:YES];
    }
}

#pragma mark - UISearchBarDelegate
- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    if ([searchBar.text length])
    {
        searchBar.showsCancelButton = YES;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    
    if ([searchBar.text length])
    {
        [self showSearchBanner];
        
        [self load:NO];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self cancelSearchAction];
}

#pragma mark -
- (UISearchBar *)searchBar
{
    if (!_searchBar) {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.frame), 44.0f)];
        _searchBar.delegate = self;
        _searchBar.placeholder = NSLocalizedString(@"Search Broadsheet.ie", nil);
    }
    
    return _searchBar;
}

- (UILabel *)searchDetailLabel
{
    if (!_searchDetailLabel) {
        _searchDetailLabel = [UILabel new];
        _searchDetailLabel.backgroundColor = [UIColor clearColor];
        _searchDetailLabel.translatesAutoresizingMaskIntoConstraints = NO;
        _searchDetailLabel.font = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
        _searchDetailLabel.numberOfLines = 0;
    }
    
    return _searchDetailLabel;
}

- (UIView *)searchDetailView
{
    if (!_searchDetailView) {
        _searchDetailView = [UIView new];
        _searchDetailView.translatesAutoresizingMaskIntoConstraints = NO;
        _searchDetailView.backgroundColor = [UIColor colorWithRed:0.7882f green:0.7882f blue:0.8078f alpha:1.0f];
        _searchDetailView.clipsToBounds = YES;
        
        [_searchDetailView addSubview:self.searchDetailLabel];
        
        UIButton *cancelSearch = [UIButton buttonWithType:UIButtonTypeSystem];
        [cancelSearch addTarget:self action:@selector(cancelSearchAction) forControlEvents:UIControlEventTouchUpInside];
        [cancelSearch setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        cancelSearch.translatesAutoresizingMaskIntoConstraints = NO;
        [cancelSearch sizeToFit];
        
        [_searchDetailView addSubview:cancelSearch];
        
        UIView *seperator = [UIView new];
        seperator.translatesAutoresizingMaskIntoConstraints = NO;
        seperator.backgroundColor = [UIColor colorWithRed:0.7215f green:0.7215f blue:0.7254f alpha:1.0f];
        
        [_searchDetailView addSubview:seperator];
        
        NSDictionary *views = @{@"searchDetailLabel": self.searchDetailLabel,
                                @"cancelSearch": cancelSearch,
                                @"seperator": seperator};
        
        [_searchDetailView addConstraint:[NSLayoutConstraint constraintWithItem:self.searchDetailLabel
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:_searchDetailView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1.0f
                                                                       constant:0]];
        [_searchDetailView addConstraint:[NSLayoutConstraint constraintWithItem:cancelSearch
                                                                      attribute:NSLayoutAttributeCenterY
                                                                      relatedBy:NSLayoutRelationEqual
                                                                         toItem:_searchDetailView
                                                                      attribute:NSLayoutAttributeCenterY
                                                                     multiplier:1.0f
                                                                       constant:0]];
        [_searchDetailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:[seperator(<=0.5)]|"
                                                                                  options:0
                                                                                  metrics:nil
                                                                                    views:views]];
        [_searchDetailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[searchDetailLabel]-[cancelSearch]-|"
                                                                                  options:0
                                                                                  metrics:nil
                                                                                    views:views]];
        [_searchDetailView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|-[seperator]-|"
                                                                                  options:0
                                                                                  metrics:nil
                                                                                    views:views]];
        self.searchDetailLabel.preferredMaxLayoutWidth = CGRectGetWidth(cancelSearch.frame) + (8 * 3);
    }
    
    return _searchDetailView;
}
@end