//
//  NCEventDetailsViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 5/6/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCEventDetailsViewController.h"
#import "NCEventDetailsCell.h"
#import "NCEventOpponentsCell.h"
#import <MapKit/MapKit.h>

@interface NCEventDetailsViewController ()

@end

@implementation NCEventDetailsViewController

- (instancetype)initWithCalendarEvent:(NCCalendarEvent *)event {
    self = [super initWithStyle:UITableViewStyleGrouped];
    if(self) {
        _event = event;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(shareEvent)];
    self.navigationItem.rightBarButtonItem = shareButton;
    
    self.title = NSLocalizedString(@"Event Details", @"Event Details");
    self.tableView.backgroundColor = [UIColor colorWithRed:239.0f/255.0f green:239.0f/255.0f blue:244.0f/255.0f alpha:1];
    self.tableView.separatorColor = [UIColor colorWithRed:200.0f/255.0f green:199.0f/255.0f blue:204.0f/255.0f alpha:1];
}

- (void)shareEvent {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"http://www.northiowaconference.org/g5-bin/client.cgi?cwellOnly=1&G5statusflag=view_note&schoolname=&school_id=5&G5button=13&G5genie=97&view_id=%@", _event.identifier]];
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:@[url] applicationActivities:nil];
    [self presentViewController:activityController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource

- (BOOL)displayingLocation {
    return [_event.location length] > 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    NSUInteger rows = 1;
    if([self displayingLocation]) rows++;
    if([_event.opponents count] > 0) rows++;
    return rows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 0) {
        NCEventDetailsCell *cell = (NCEventDetailsCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
        return [cell heightForCalendarEvent:_event];
    } else if(indexPath.row == 1 && [self displayingLocation]) {
        return 44;
    } else {
        NCEventOpponentsCell *cell = (NCEventOpponentsCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
        return [cell heightForCalendarEvent:_event];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 0) {
        NSString *cellIdentifier = @"Cell";
        NCEventDetailsCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if(cell == nil) {
            cell = [[NCEventDetailsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.event = _event;
            [cell setNeedsDisplay];
        }
        
        return cell;
    } else if(indexPath.row == 1 && [self displayingLocation]) {
        NSString *cellIdentifier = @"locationCell";
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if(cell == nil) {
            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellIdentifier];
            cell.backgroundColor = [UIColor whiteColor];
            cell.textLabel.text = NSLocalizedString(@"Location", @"Location");
            cell.detailTextLabel.text = _event.location;
            
            if(![_event.location isEqualToString:@"TBA"])
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
        
        return cell;
    } else {
        NSString *cellIdentifier = @"opponentsCell";
        NCEventOpponentsCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
        
        if(cell == nil) {
            cell = [[NCEventOpponentsCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
            cell.event = _event;
            [cell setNeedsDisplay];
        }
        
        return cell;
    }
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.row == 1 && [self displayingLocation]) {
        NSString *location = [_event.location stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        if([location isEqualToString:@"TBA"]) return;

        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[NSString stringWithFormat:@"http://maps.apple.com/maps?q=%@", location]]];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
