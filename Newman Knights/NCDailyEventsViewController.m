//
//  NCDailyEventsViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 5/6/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCDailyEventsViewController.h"
#import "NCEventDetailsViewController.h"
#import "NCEventStore.h"
#import "NCDailyEventCell.h"

@interface NCDailyEventsViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *events;

@end

@implementation NCDailyEventsViewController

- (instancetype)initWithDate:(NSDate *)date {
    self = [super init];
    if(self) {
        _date = date;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(retry)];
    self.navigationItem.rightBarButtonItem = reloadButton;
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.hidden = YES;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_tableView];
    [self.view sendSubviewToBack:_tableView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_tableView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_tableView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_tableView]|" options:0 metrics:0 views:views]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"Day", @"Day");
    [self fetchEvents];
}

- (void)fetchEvents {
    [[NCEventStore sharedInstance] fetchEventsForDate:_date completion:^(NSArray *events, NSError *error) {
        if(events) {
            _events = events;
            [self success];
        } else {
            [self failWithError:error];
        }
    }];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:YES];
}

- (void)retry {
    [super retry];
    [_tableView setHidden:YES];
    [self performSelector:@selector(fetchEvents) withObject:nil afterDelay:1];
}

- (void)success {
    [super success];
    [_tableView reloadData];
    [_tableView setHidden:NO];
    [_tableView setSeparatorStyle:([_events count] == 0) ? UITableViewCellSeparatorStyleNone : UITableViewCellSeparatorStyleSingleLine];
    [_tableView setContentInset:([_events count] == 0) ? UIEdgeInsetsMake(150, 0, 150, 0) : UIEdgeInsetsZero];
}

#pragma mark - UITableViewDataSource

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 55;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger numberOfEvents = [_events count];
    return numberOfEvents > 0 ? numberOfEvents : 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([_events count] == 0) {
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
        
        NCCalendarEvent *event = _events[indexPath.row];
        cell.event = event;
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if([_events count] <= indexPath.row) return;
    NCCalendarEvent *event = _events[indexPath.row];
    NCEventDetailsViewController *viewController = [[NCEventDetailsViewController alloc] initWithCalendarEvent:event];
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
