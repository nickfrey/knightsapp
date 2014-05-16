//
//  NCSocialViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 3/14/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCSocialViewController.h"
#import "NCDataSource.h"
#import "NCSocialPostCell.h"

@interface NCSocialViewController () <UITableViewDataSource, UITableViewDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong) NSArray *posts;
@property (nonatomic, strong) NCSocialPostCell *sizingCell;

@end

@implementation NCSocialViewController

static NSString * const NCSocialPostCellIdentifier = @"NCSocialPostCellIdentifier";

- (id)init {
    self = [super init];
    if(self) {
        NSString *localizedTitle = NSLocalizedString(@"Social", @"Social");
        self.title = localizedTitle;
        self.tabBarItem.title = localizedTitle;
        self.tabBarItem.image = [UIImage imageNamed:@"tabSocial"];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    _sizingCell = [[NCSocialPostCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    _sizingCell.hidden = YES;
    _sizingCell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_tableView addSubview:_sizingCell];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.hidden = YES;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [_tableView registerClass:[NCSocialPostCell class] forCellReuseIdentifier:NCSocialPostCellIdentifier];
    [self.view addSubview:_tableView];
    [self.view sendSubviewToBack:_tableView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_tableView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_tableView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_tableView]|" options:0 metrics:0 views:views]];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _refreshControl = [[UIRefreshControl alloc] init];
    [_refreshControl addTarget:self action:@selector(refresh) forControlEvents:UIControlEventValueChanged];
    [_tableView addSubview:_refreshControl];
    [_tableView sendSubviewToBack:_refreshControl];
    
    [self loadPosts];
}

- (void)refresh {
    [_refreshControl beginRefreshing];
    [self performSelector:@selector(loadPosts) withObject:nil afterDelay:1];
}

- (void)retry {
    [super retry];
    [_tableView setHidden:YES];
    [self performSelector:@selector(loadPosts) withObject:nil afterDelay:1];
}

- (void)success {
    [super success];
    [_tableView reloadData];
    [_tableView setHidden:NO];
}

- (void)failWithError:(NSError *)error {
    [super failWithError:error];
    [_tableView setHidden:YES];
}

- (void)loadPosts {
    [[NCDataSource sharedDataSource] fetchSocialPosts:^(NSArray *posts, NSError *error) {
        [_refreshControl endRefreshing];
        
        if(posts) {
            _posts = posts;
            [self success];
        } else {
            [self failWithError:error];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_posts count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    [self configureCell:_sizingCell forRowAtIndexPath:indexPath];
    
    CGRect theFrame = _sizingCell.frame;
    theFrame.size.width = self.tableView.bounds.size.width;
    _sizingCell.frame = theFrame;
    
    [_sizingCell setNeedsLayout];
    [_sizingCell layoutIfNeeded];
    
    return [_sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height+1;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NCSocialPostCell *cell = [tableView dequeueReusableCellWithIdentifier:NCSocialPostCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NCSocialPostCell *postCell = (NCSocialPostCell *)cell;
    postCell.post = _posts[indexPath.row];
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NCSocialPost *post = _posts[indexPath.row];
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];
    [post openInExternalApplication];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
