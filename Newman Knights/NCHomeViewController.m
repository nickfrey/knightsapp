//
//  NCHomeViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 10/10/13.
//  Copyright (c) 2013 Newman Catholic. All rights reserved.
//

#import "NCHomeViewController.h"
#import "NCDataSource.h"
#import "NCCoverView.h"
#import "NCHomeBulletinCell.h"
#import <QuickLook/QuickLook.h>
#import "NCCoverViewPreviewItem.h"
#import "MHPrettyDate.h"

@interface NCHomeViewController () <UITableViewDataSource, UITableViewDelegate, UIScrollViewDelegate, QLPreviewControllerDataSource>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NCCoverView *coverView;
@property (nonatomic, strong) NCCoverViewPreviewItem *coverViewPreview;
@property (nonatomic, strong) NSLayoutConstraint *coverVerticalConstraint, *coverHeightConstraint;
@property (nonatomic, strong) NSArray *bulletins;
@property (nonatomic, strong) UITableViewCell *sizingCell;

@end

@implementation NCHomeViewController

static CGFloat NCHomeCoverViewHeight;
static NSString * const NCHomeBulletinCellIdentifier = @"NCHomeBulletinCellIdentifier";

- (id)init {
    self = [super init];
    if(self) {
        self.title = @"Newman Catholic";
        self.tabBarItem.title = NSLocalizedString(@"News", @"News");
        self.tabBarItem.image = [UIImage imageNamed:@"tabNews"];
        NCHomeCoverViewHeight = ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) ? 325 : 150;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _coverView = [[NCCoverView alloc] init];
    _coverView.hidden = YES;
    _coverView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_coverView];
    
    UIButton *tableHeaderButton = [UIButton buttonWithType:UIButtonTypeCustom];
    tableHeaderButton.frame = CGRectMake(0, 0, 0, NCHomeCoverViewHeight);
    [tableHeaderButton addTarget:self action:@selector(coverViewWasSelected) forControlEvents:UIControlEventTouchUpInside];
    
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.hidden = YES;
    _tableView.dataSource = self;
    _tableView.delegate = self;
    _tableView.backgroundColor = [UIColor clearColor];
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    _tableView.tableHeaderView = tableHeaderButton;
    [_tableView registerClass:[NCHomeBulletinCell class] forCellReuseIdentifier:NCHomeBulletinCellIdentifier];
    [self.view addSubview:_tableView];
    
    _sizingCell = [[NCHomeBulletinCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:nil];
    _sizingCell.hidden = YES;
    _sizingCell.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_tableView addSubview:_sizingCell];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(_coverView, _tableView);
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_coverView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_tableView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_tableView]|" options:0 metrics:0 views:views]];
    
    _coverVerticalConstraint = [NSLayoutConstraint constraintWithItem:_coverView attribute:NSLayoutAttributeTop relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeTop multiplier:0 constant:0];
    _coverHeightConstraint = [NSLayoutConstraint constraintWithItem:_coverView attribute:NSLayoutAttributeHeight relatedBy:NSLayoutRelationEqual toItem:nil attribute:NSLayoutAttributeHeight multiplier:0 constant:NCHomeCoverViewHeight];
    [self.view addConstraint:_coverVerticalConstraint];
    [self.view addConstraint:_coverHeightConstraint];
    
    [self loadRemoteData];
}

- (void)loadRemoteData {
    __block NSUInteger operationsToSucceed = 2;
    
    void (^operationSuceeded)(void) = ^{
        operationsToSucceed--;
        if(operationsToSucceed == 0) {
            [self success];
        }
    };
    
    [[NCDataSource sharedDataSource] fetchSocialPosts:^(NSArray *tweets, NSError *error) {
        if(error) {
            [self failWithError:error];
        } else {
            NSMutableArray *coverPosts = [NSMutableArray array];
            for(NCSocialPost *socialPost in tweets) {
                for(id attachment in socialPost.attachments) {
                    if([attachment isKindOfClass:[NSURL class]]) {
                        [coverPosts addObject:socialPost];
                        break;
                    }
                }
            }
            [_coverView setCoverPosts:coverPosts];
            operationSuceeded();
        }
    }];
    
    [[NCDataSource sharedDataSource] fetchBulletin:^(NSArray *events, NSError *error) {
        if(error) {
            [self failWithError:error];
        } else {
            _bulletins = events;
            operationSuceeded();
        }
    }];
}

- (void)retry {
    [super retry];
    [self loadRemoteData];
}

- (void)success {
    [super success];
    [_tableView reloadData];
    [_tableView setHidden:NO];
    [_coverView setHidden:NO];
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    NSUInteger bulletins = [_bulletins count];
    if(bulletins == 0) bulletins++;
    return bulletins;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if([_bulletins count] == 0) return 1;
    return [_bulletins[section][@"events"] count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([_bulletins count] == 0) return 60;
    
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

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if([_bulletins count] == 0) return nil;
    NSDate *date = _bulletins[section][@"date"];
    return [MHPrettyDate prettyDateFromDate:date withFormat:MHPrettyDateFormatNoTime withDateStyle:NSDateFormatterMediumStyle];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if([_bulletins count] == 0) {
        static NSString *cellIdentifier = @"Cell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.textLabel.text = NSLocalizedString(@"Nothing seems to be happening right now.", @"Nothing seems to be happening right now.");
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.numberOfLines = 2;
            cell.textLabel.font = [UIFont systemFontOfSize:14];
            cell.backgroundColor = [UIColor clearColor];
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        return cell;
    }
    
    NCHomeBulletinCell *cell = [tableView dequeueReusableCellWithIdentifier:NCHomeBulletinCellIdentifier forIndexPath:indexPath];
    [self configureCell:cell forRowAtIndexPath:indexPath];
    return cell;
}

- (void)configureCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    NCHomeBulletinCell *bulletinCell = (NCHomeBulletinCell *)cell;
    bulletinCell.bulletinText = _bulletins[indexPath.section][@"events"][indexPath.row];
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat scrollOffset = scrollView.contentOffset.y;

    if (scrollOffset < 0) {
        // Adjust image proportionally
        _coverHeightConstraint.constant = MAX(NCHomeCoverViewHeight, -scrollOffset+NCHomeCoverViewHeight);
        _coverVerticalConstraint.constant = 0;
    } else {
        // We're scrolling up, return to normal behavior
        _coverHeightConstraint.constant = NCHomeCoverViewHeight;
        _coverVerticalConstraint.constant = -scrollOffset;
    }
    
    [_coverView setNeedsUpdateConstraints];
}

#pragma mark - Cover View Previews

- (void)coverViewWasSelected {
    NSURL *tmpDirURL = [NSURL fileURLWithPath:NSTemporaryDirectory() isDirectory:YES];
    NSURL *imageURL = [[tmpDirURL URLByAppendingPathComponent:@"photo"] URLByAppendingPathExtension:@"jpg"];
    [UIImageJPEGRepresentation(_coverView.currentImage, 1) writeToURL:imageURL atomically:NO];
    
    _coverViewPreview = [[NCCoverViewPreviewItem alloc] init];
    _coverViewPreview.url = imageURL;
    
    QLPreviewController *previewController = [[QLPreviewController alloc] init];
    previewController.dataSource = self;
    [self presentViewController:previewController animated:YES completion:nil];
}

- (NSInteger)numberOfPreviewItemsInPreviewController:(QLPreviewController *)controller {
    return 1;
}

- (id<QLPreviewItem>)previewController:(QLPreviewController *)controller previewItemAtIndex:(NSInteger)index {
    return _coverViewPreview;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
