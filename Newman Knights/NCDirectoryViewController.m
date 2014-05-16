//
//  NCDirectoryViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 5/12/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCDirectoryViewController.h"
#import <MessageUI/MessageUI.h>

@interface NCDirectoryViewController () <UITableViewDataSource, UITableViewDelegate, MFMailComposeViewControllerDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSArray *contacts;

@end

@implementation NCDirectoryViewController

- (instancetype)initWithDirectory:(NCContactDirectory)directory {
    self = [super init];
    if(self) {
        _directory = directory;
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    switch(_directory) {
        case NCContactDirectoryAdministration:
            self.title = NSLocalizedString(@"Administration", @"Administration");
            break;
        case NCContactDirectoryOffice:
            self.title = NSLocalizedString(@"Office", @"Office");
            break;
        case NCContactDirectoryFaculty:
            self.title = NSLocalizedString(@"Teachers", @"Teachers");
            break;
    }
    
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
    [self performSelector:@selector(loadContacts) withObject:nil afterDelay:0.2];
}

- (void)retry {
    [super retry];
    [_tableView setHidden:YES];
    [self performSelector:@selector(loadContacts) withObject:nil afterDelay:1];
}

- (void)success {
    [super success];
    [_tableView reloadData];
    [_tableView setHidden:NO];
}

- (void)loadContacts {
    [[NCDataSource sharedDataSource] fetchContactDirectory:_directory completion:^(NSArray *contacts, NSError *error) {
        if(contacts) {
            _contacts = contacts;
            [self success];
        } else {
            [self failWithError:error];
        }
    }];
}

#pragma mark - UITableViewDataSource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_contacts count];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSDictionary *info = _contacts[indexPath.row];
    cell.textLabel.text = info[@"name"];
    cell.detailTextLabel.text = info[@"title"];
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [_tableView deselectRowAtIndexPath:indexPath animated:YES];

    NSDictionary *info = _contacts[indexPath.row];
    NSString *email = [NSString stringWithFormat:@"\"%@\" <%@>", info[@"name"], info[@"email"]];
    
    if([MFMailComposeViewController canSendMail]) {
        MFMailComposeViewController *viewController = [[MFMailComposeViewController alloc] init];
        viewController.mailComposeDelegate = self;
        [viewController setToRecipients:@[email]];
        [viewController.navigationBar setBarStyle:UIBarStyleBlackOpaque];
        [viewController.navigationBar setTintColor:[UIColor whiteColor]];
        
        [self presentViewController:viewController animated:YES completion:^{
            [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
        }];
    } else {
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"mailto://%@", email]]];
    }
}

#pragma mark - MFMailComposeViewControllerDelegate

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
