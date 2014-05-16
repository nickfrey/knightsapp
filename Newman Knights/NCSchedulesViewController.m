//
//  NCSchedulesViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 3/14/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCSchedulesViewController.h"
#import "NCDocumentViewController.h"
#import "NCDataSource.h"
#import "NCScheduleCell.h"

@interface NCSchedulesViewController () <UITableViewDataSource, UITableViewDelegate, UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, strong) UITableView *tableView; // iPhone
@property (nonatomic, strong) UICollectionView *collectionView; // iPad
@property (nonatomic, strong) UICollectionViewFlowLayout *collectionViewLayout;
@property (nonatomic, strong) NSArray *schedules;

@end

@implementation NCSchedulesViewController

static NSString * const NCSchedulesCellIdentifier = @"ScheduleCell";

- (id)init {
    self = [super init];
    if(self) {
        NSString *localizedTitle = NSLocalizedString(@"Schedules", @"Schedules");
        self.title = localizedTitle;
        self.tabBarItem.title = localizedTitle;
        self.tabBarItem.image = [UIImage imageNamed:@"tabSchedule"];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    UIBarButtonItem *reloadButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(retry)];
    self.navigationItem.rightBarButtonItem = reloadButton;
    
    UIView *mainView;
    
    if([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        _collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        _collectionViewLayout.itemSize = CGSizeMake(250, 250);
        _collectionViewLayout.minimumInteritemSpacing = 50;
        _collectionViewLayout.minimumLineSpacing = 50;
        _collectionViewLayout.sectionInset = UIEdgeInsetsMake(70, 70, 70, 70);
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_collectionViewLayout];
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.hidden = YES;
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.backgroundColor = self.view.backgroundColor;
        _collectionView.translatesAutoresizingMaskIntoConstraints = NO;
        [_collectionView registerClass:[NCScheduleCell class] forCellWithReuseIdentifier:NCSchedulesCellIdentifier];
        mainView = _collectionView;
    } else {
        _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _tableView.dataSource = self;
        _tableView.delegate = self;
        _tableView.hidden = YES;
        _tableView.translatesAutoresizingMaskIntoConstraints = NO;
        mainView = _tableView;
    }
    
    [self.view addSubview:mainView];
    [self.view sendSubviewToBack:mainView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(mainView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[mainView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[mainView]|" options:0 metrics:0 views:views]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:YES];
    for(NSIndexPath *indexPath in _collectionView.indexPathsForSelectedItems)
        [_collectionView deselectItemAtIndexPath:indexPath animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadSchedules];
}

- (void)retry {
    [super retry];
    [_tableView setHidden:YES];
    [_collectionView setHidden:YES];
    [self performSelector:@selector(loadSchedules) withObject:nil afterDelay:1];
}

- (void)success {
    [super success];
    [_tableView reloadData];
    [_tableView setHidden:NO];
    [_collectionView reloadData];
    [_collectionView setHidden:NO];
}

- (void)loadSchedules {
    [[NCDataSource sharedDataSource] fetchSchedules:^(NSArray *schedules, NSError *error) {
        if(schedules) {
            _schedules = schedules;
            [self success];
        } else {
            [self failWithError:error];
        }
    }];
}

- (void)selectScheduleAtIndex:(NSUInteger)index {
    NSDictionary *info = _schedules[index];
    UIViewController *viewController;
    
    if([info[@"document"] boolValue]) {
        viewController = [[NCDocumentViewController alloc] initWithDocumentID:info[@"url"]];
    } else {
        viewController = [[NCWebViewController alloc] initWithURL:[NSURL URLWithString:info[@"url"]]];
    }
    
    viewController.title = info[@"title"];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_schedules count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSDictionary *info = _schedules[indexPath.row];
    cell.textLabel.text = info[@"title"];

    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [self selectScheduleAtIndex:indexPath.row];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return [_schedules count];
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    NCScheduleCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:NCSchedulesCellIdentifier forIndexPath:indexPath];
    cell.scheduleTitle = _schedules[indexPath.row][@"title"];
    return cell;
}

#pragma mark - UICollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    [self selectScheduleAtIndex:indexPath.row];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
