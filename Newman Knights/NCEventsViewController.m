//
//  NCEventsViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 3/12/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCEventsViewController.h"
#import "MNCalendarView.h"
#import "NCCalendarViewDayCell.h"
#import "NCEventDetailsViewController.h"
#import "NCDailyEventsViewController.h"
#import "NCDailyEventCell.h"
#import "NCEventStore.h"

@interface NCEventsViewController () <MNCalendarViewDelegate, NCEventStoreDelegate, UISearchBarDelegate, UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) MNCalendarView *calendarView;
@property (nonatomic, strong) NSIndexPath *selectedIndexPath;
@property (nonatomic, strong) UIPopoverController *detailsPopover;
@property (nonatomic) BOOL hasScrolledToToday;
@property (nonatomic) UIInterfaceOrientation lastOrientation;

@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UITableView *resultsTableView; // iPhone
@property (nonatomic, strong) NSLayoutConstraint *resultsTableViewConstraint;
@property (nonatomic, strong) UITableViewController *resultsController; // iPad
@property (nonatomic, strong) UIPopoverController *resultsPopover; // iPad
@property (nonatomic, strong) NSMutableArray *searchResults;
@property (nonatomic, strong) NSTimer *typingTimer;

@end

@implementation NCEventsViewController

- (id)init {
    self = [super init];
    if(self) {
        NSString *localizedTitle = NSLocalizedString(@"Events", @"Events");
        self.title = localizedTitle;
        self.tabBarItem.title = localizedTitle;
        self.tabBarItem.image = [UIImage imageNamed:@"tabEvents"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    [[NCEventStore sharedInstance] setDelegate:self];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    
    /* Navigation Bar */
    [self.navigationController.navigationBar setTranslucent:NO];
    [self.navigationController.navigationBar setBarTintColor:[UIColor colorWithWhite:0.97 alpha:1]];
    [self setSearchHidden:YES animated:NO];
    
    /* Calendar */
    _calendarView = [[MNCalendarView alloc] init];
    _calendarView.alpha = 0;
    _calendarView.delegate = self;
    _calendarView.calendar = [[[NCEventStore sharedInstance] calendar] copy];
    _calendarView.selectedDate = [NSDate date];
    _calendarView.dayCellClass = [NCCalendarViewDayCell class];
    _calendarView.separatorColor = [UIColor colorWithWhite:0 alpha:0.1];
    _calendarView.collectionView.scrollsToTop = NO;
    _calendarView.translatesAutoresizingMaskIntoConstraints = NO;
    [_calendarView registerUICollectionViewClasses];
    [self.view addSubview:_calendarView];
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.year = 2011;
    _calendarView.fromDate = [_calendarView.calendar dateFromComponents:dateComponents];
    dateComponents.year = 2;
    _calendarView.toDate = [_calendarView.calendar dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
    [_calendarView reloadData];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_calendarView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_calendarView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_calendarView]|" options:0 metrics:0 views:views]];
    
    /* Results Table View */
    _searchResults = [[NSMutableArray alloc] init];
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        _resultsController = [[UITableViewController alloc] initWithStyle:UITableViewStylePlain];
        _resultsController.tableView.dataSource = self;
        _resultsController.tableView.delegate = self;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:_resultsController];
        _resultsPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        _resultsController.navigationItem.titleView = _searchBar;
        
        _searchBar = [[UISearchBar alloc] init];
        _searchBar.showsCancelButton = YES;
        _searchBar.delegate = self;
        _searchBar.tintColor = [UIColor darkGrayColor];
        _searchBar.placeholder = NSLocalizedString(@"Search", @"Search");
        _searchBar.searchBarStyle = UISearchBarStyleMinimal;
        [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor colorWithRed:223.0f/255.0f green:71.0f/255.0f blue:71.0f/255.0f alpha:1]];
        
        UIView *barWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 305, 44)];
        [barWrapper addSubview:_searchBar];
        [_searchBar sizeToFit];
        
        _resultsController.navigationItem.titleView = barWrapper;
    } else {
        _resultsTableView = [[UITableView alloc] init];
        _resultsTableView.dataSource = self;
        _resultsTableView.delegate = self;
        _resultsTableView.hidden = YES;
        _resultsTableView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.view addSubview:_resultsTableView];
        
        views = NSDictionaryOfVariableBindings(_resultsTableView);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_resultsTableView]|" options:0 metrics:0 views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_resultsTableView]" options:0 metrics:0 views:views]];
        
        _resultsTableViewConstraint = [NSLayoutConstraint constraintWithItem:_resultsTableView attribute:NSLayoutAttributeBottom relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeBottom multiplier:1 constant:0];
        [self.view addConstraint:_resultsTableViewConstraint];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillShow:)
                                                     name:UIKeyboardWillShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(keyboardWillDisappear:)
                                                     name:UIKeyboardWillHideNotification object:nil];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_resultsTableView deselectRowAtIndexPath:_resultsTableView.indexPathForSelectedRow animated:YES];
    
    if(_lastOrientation != [UIApplication sharedApplication].statusBarOrientation) {
        [self willRotateToInterfaceOrientation:[UIApplication sharedApplication].statusBarOrientation duration:0];
    }
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if(!_hasScrolledToToday) {
        _hasScrolledToToday = YES;
        [self selectTodayAnimated:NO];
        [_calendarView setAlpha:1];
    }
    
    if(_lastOrientation != [UIApplication sharedApplication].statusBarOrientation) {
        [self didRotateFromInterfaceOrientation:_lastOrientation];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    _calendarView.alpha = 0;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {    
    NSDateComponents *components = [_calendarView.calendar components:NSCalendarUnitMonth fromDate:_calendarView.fromDate toDate:_calendarView.selectedDate options:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:components.month];
    [_calendarView reloadData];
    
    [UIView animateWithDuration:0.3 animations:^{
        _calendarView.alpha = 1;
        [_calendarView.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:NO];
    }];
    
    _lastOrientation = [UIApplication sharedApplication].statusBarOrientation;
}

#pragma mark - Bar Button Items

- (void)selectToday {
    [self selectTodayAnimated:YES];
}

- (void)invokeSearch {
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [_resultsController.tableView reloadData];
        [_resultsPopover presentPopoverFromBarButtonItem:self.navigationItem.rightBarButtonItem permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
        [_searchBar becomeFirstResponder];
    } else {
        [_resultsTableView reloadData];
        [self setSearchHidden:NO animated:YES];
    }
}

- (void)selectTodayAnimated:(BOOL)animated {
    [_calendarView setSelectedDate:[NSDate date]];
    
    NSDateComponents *components = [_calendarView.calendar components:NSCalendarUnitMonth fromDate:_calendarView.fromDate toDate:[NSDate date] options:0];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:0 inSection:components.month];
    [_calendarView.collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionTop animated:animated];
    [_calendarView reloadData];
}

- (void)setSearchHidden:(BOOL)hidden animated:(BOOL)animated {
    if(hidden) {
        UIBarButtonItem *todayItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Today", @"Today") style:UIBarButtonItemStylePlain target:self action:@selector(selectToday)];
        UIBarButtonItem *searchItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(invokeSearch)];
        
        if(animated) {
            [UIView animateWithDuration:0.2 animations:^{
                self.navigationItem.titleView.alpha = 0;
                _resultsTableView.alpha = 0;
            } completion:^(BOOL finished) {
                self.navigationItem.titleView = nil;
                _searchBar = nil;
                [self.navigationItem setLeftBarButtonItem:todayItem animated:YES];
                [self.navigationItem setRightBarButtonItem:searchItem animated:YES];
                _resultsTableView.hidden = YES;
            }];
        } else {
            self.navigationItem.titleView = nil;
            [self.navigationItem setLeftBarButtonItem:todayItem animated:NO];
            [self.navigationItem setRightBarButtonItem:searchItem animated:NO];
            _resultsTableView.hidden = YES;
        }
    } else {
        _searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(-8, 0, self.view.bounds.size.width, 44)];
        _searchBar.showsCancelButton = YES;
        _searchBar.backgroundImage = [UIImage new];
        _searchBar.delegate = self;
        _searchBar.tintColor = [UIColor darkGrayColor];
        _searchBar.placeholder = NSLocalizedString(@"Search", @"Search");
        [[UIBarButtonItem appearanceWhenContainedIn:[UISearchBar class], nil] setTintColor:[UIColor whiteColor]];
        
        UIView *barWrapper = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 44)];
        [barWrapper addSubview:_searchBar];
        
        [self.navigationItem setLeftBarButtonItem:nil animated:animated];
        [self.navigationItem setRightBarButtonItem:nil animated:animated];
        self.navigationItem.titleView = barWrapper;
        
        if(animated) {
            barWrapper.alpha = 0;
            _resultsTableView.alpha = 0;
            _resultsTableView.hidden = NO;
            
            [UIView animateWithDuration:0.2 animations:^{
                barWrapper.alpha = 1;
                _resultsTableView.alpha = 1;
            } completion:^(BOOL finished) {
                [_searchBar becomeFirstResponder];
            }];
        } else {
            [_searchBar becomeFirstResponder];
            _resultsTableView.alpha = 1;
            _resultsTableView.hidden = NO;
        }
    }
}

#pragma mark - NCEventStoreDelegate

- (void)eventStore:(NCEventStore *)eventStore didFetchEventsForMonthOfDate:(NSDate *)date {
    NSDateComponents *components = [_calendarView.calendar components:NSCalendarUnitMonth fromDate:_calendarView.fromDate toDate:date options:0];
    NSMutableArray *cells = [NSMutableArray array];
    
    NSUInteger daysInWeek = 7;
    NSUInteger daysInMonth = [_calendarView.calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:date].length;
    
    for(NSUInteger day = 0; day < daysInMonth; day++) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:day+daysInWeek inSection:components.month];
        NCCalendarViewDayCell *cell = (NCCalendarViewDayCell *)[_calendarView.collectionView cellForItemAtIndexPath:indexPath];
        if(cell) [cells addObject:cell];
    }
    
    for(NCCalendarViewDayCell *cell in cells)
        cell.eventful = [eventStore eventsOccurOnDate:cell.date];
}

#pragma mark - MNCalendarViewDelegate

- (void)calendarView:(MNCalendarView *)calendarView didSelectDate:(NSDate *)date atIndexPath:(NSIndexPath *)indexPath {
    NCDailyEventsViewController *dailyEvents = [[NCDailyEventsViewController alloc] initWithDate:date];
    _selectedIndexPath = indexPath;
    [self performSelector:@selector(displayEventsWithController:) withObject:dailyEvents afterDelay:0.1];
}

- (void)displayEventsWithController:(NCDailyEventsViewController *)dailyEvents {
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        UICollectionViewLayoutAttributes *attributes = [_calendarView.collectionView layoutAttributesForItemAtIndexPath:_selectedIndexPath];
        CGRect cellRect = attributes.frame;
        
        UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:dailyEvents];
        
        _detailsPopover = [[UIPopoverController alloc] initWithContentViewController:navController];
        [_detailsPopover presentPopoverFromRect:cellRect inView:_calendarView.collectionView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    } else {
        [self.navigationController pushViewController:dailyEvents animated:YES];
    }
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger numberOfEvents = [_searchResults count];
    return numberOfEvents > 0 ? numberOfEvents : ((_searchBar.text.length > 0) ? 1 : 0);
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([_searchResults count] == 0) {
        NSString *cellIdentifier = @"NoneCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell.textLabel.textColor = [UIColor colorWithWhite:0 alpha:0.4];
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = NSLocalizedString(@"No events.", @"No events.");
        }
        
        return cell;
    } else {
        NSString *cellIdentifier = @"Cell";
        NCDailyEventCell *cell = (NCDailyEventCell *)[tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if(cell == nil) {
            cell = [[NCDailyEventCell alloc] initWithReuseIdentifier:cellIdentifier];
        }
        
        NCCalendarEvent *event = _searchResults[indexPath.row];
        cell.event = event;
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([_searchResults count] <= indexPath.row) return;
    NCCalendarEvent *event = _searchResults[indexPath.row];
    NCEventDetailsViewController *viewController = [[NCEventDetailsViewController alloc] initWithCalendarEvent:event];
    UINavigationController *navController = self.navigationController;
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        navController = _resultsController.navigationController;
    
    [navController pushViewController:viewController animated:YES];
}

#pragma mark - UISearchBarDelegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    [_searchResults removeAllObjects];
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        [_resultsPopover dismissPopoverAnimated:YES];
    else
        [self setSearchHidden:YES animated:YES];
}

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if(_typingTimer)
        [_typingTimer invalidate];
    
    _typingTimer = [NSTimer scheduledTimerWithTimeInterval:0.3 target:self selector:@selector(searchEvents) userInfo:nil repeats:NO];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
}

- (void)searchEvents {
    if([_searchBar.text length] < 3) return;
    
    [[NCEventStore sharedInstance] cancelAllQueries];
    [[NCEventStore sharedInstance] fetchEventsWithQuery:_searchBar.text completion:^(NSArray *events, NSError *error) {
        if(error) {
            if(error.domain == NSURLErrorDomain && error.code == NSURLErrorCancelled) {
                // Cancelled fetch, user is still typing.
            } else {
                NSLog(@"Search error: %@", error);
            }
        } else {
            [_searchResults setArray:events];
            
            if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
                [_resultsController.tableView reloadData];
            else
                [_resultsTableView reloadData];
        }
    }];
}

#pragma mark - Keyboard (Phone Only)

- (NSTimeInterval)keyboardAnimationDurationForNotification:(NSNotification *)notification {
    NSDictionary *info = [notification userInfo];
    NSValue *value = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSTimeInterval duration = 0;
    [value getValue:&duration];
    return duration;
}

- (void)keyboardWillShow:(NSNotification *)aNotification {
    [UIView animateWithDuration:[self keyboardAnimationDurationForNotification:aNotification] animations:^{
        CGRect frame = [[[aNotification userInfo] objectForKey:UIKeyboardFrameEndUserInfoKey] CGRectValue];
        CGRect newFrame = [self.view convertRect:frame fromView:[[UIApplication sharedApplication] delegate].window];
        _resultsTableViewConstraint.constant = newFrame.origin.y - CGRectGetHeight(self.view.frame);
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)keyboardWillDisappear:(NSNotification *)aNotification {
    [UIView animateWithDuration:[self keyboardAnimationDurationForNotification:aNotification] animations:^{
        _resultsTableViewConstraint.constant = 0;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIKeyboardWillHideNotification object:nil];
}

@end
