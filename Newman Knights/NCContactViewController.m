//
//  NCContactViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 4/29/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCContactViewController.h"
#import "NCDirectoryViewController.h"
#import <MapKit/MapKit.h>
#import "NCAppConfig.h"

@interface NCContactViewController () <UITableViewDataSource, UITableViewDelegate, MKMapViewDelegate>

@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) MKPointAnnotation *annotation;
@property (nonatomic, strong) UITableView *tableView;

@property (nonatomic, strong) NSString *address;
@property (nonatomic, strong) NSString *phoneNumber;
@property (nonatomic) CLLocationCoordinate2D locationCoordinate;

@end

@implementation NCContactViewController

- (id)init {
    self = [super init];
    if(self) {
        NSString *localizedTitle = NSLocalizedString(@"Contact", @"Contact");
        self.title = localizedTitle;
        self.tabBarItem.title = localizedTitle;
        self.tabBarItem.image = [UIImage imageNamed:@"tabContact"];
    }
    return self;
}

- (void)loadView {
    [super loadView];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.extendedLayoutIncludesOpaqueBars = NO;
    
    _phoneNumber = SCHOOL_PHONE_NUMBER;
    _address = SCHOOL_ADDRESS;
    
    /* Map View */
    _locationCoordinate = CLLocationCoordinate2DMake(SCHOOL_COORDINATE_LONG, SCHOOL_COORDINATE_LAT);
    _mapView = [[MKMapView alloc] init];
    _mapView.mapType = MKMapTypeHybrid;
    _mapView.delegate = self;
    _mapView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_mapView];
    
    _annotation = [[MKPointAnnotation alloc] init];
    _annotation.title = SCHOOL_TITLE;
    _annotation.subtitle = SCHOOL_SUBTITLE;
    _annotation.coordinate = _locationCoordinate;
    [_mapView addAnnotation:_annotation];
    
    /* Table View */
    _tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    _tableView.delegate = self;
    _tableView.dataSource = self;
    _tableView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.view addSubview:_tableView];
    
    NSNumber *mapHeight = @([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad ? 325 : 150);
    NSDictionary *metrics = NSDictionaryOfVariableBindings(mapHeight);
    NSDictionary *views = NSDictionaryOfVariableBindings(_mapView, _tableView);
    
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_mapView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[_tableView]|" options:0 metrics:0 views:views]];
    [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[_mapView(mapHeight)][_tableView]|" options:0 metrics:metrics views:views]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [_tableView deselectRowAtIndexPath:_tableView.indexPathForSelectedRow animated:YES];
    
    MKCoordinateSpan span;
    span.latitudeDelta = 0.0005;
    span.longitudeDelta = 0.0005;
    [_mapView setRegion:MKCoordinateRegionMake(_locationCoordinate, span) ];
    [_mapView setCenterCoordinate:_locationCoordinate];
}

#pragma mark - MKMapViewDelegate

- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
    MKPinAnnotationView *annotationView = (MKPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"Pin"];
    if(annotationView == nil) {
        annotationView = [[MKPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"Pin"];
        annotationView.canShowCallout = YES;
        annotationView.animatesDrop = YES;
        annotationView.pinColor = MKPinAnnotationColorGreen;
    }
    return annotationView;
}

#pragma mark - UITableViewDataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (section == 0) ? 2 : 3;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0 && indexPath.row == 1) {
        return 65;
    } else {
        return 44;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *cellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if(cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    
    if(indexPath.section == 0) {
        if(indexPath.row == 0) {
            cell.textLabel.text = _phoneNumber;
            cell.imageView.image = [UIImage imageNamed:@"contactIconPhone"];
        } else if(indexPath.row == 1) {
            cell.textLabel.text = _address;
            cell.imageView.image = [UIImage imageNamed:@"contactIconLocation"];
        }
    } else {
        if(indexPath.row == 0) {
            cell.textLabel.text = NSLocalizedString(@"Administration", @"Administration");
            cell.imageView.image = [UIImage imageNamed:@"contactIconMail"];
        } else if(indexPath.row == 1) {
            cell.textLabel.text = NSLocalizedString(@"Office", @"Office");
            cell.imageView.image = [UIImage imageNamed:@"contactIconMail"];
        } else if(indexPath.row == 2) {
            cell.textLabel.text = NSLocalizedString(@"Teachers", @"Teachers");
            cell.imageView.image = [UIImage imageNamed:@"contactIconMail"];
        }
    }
    
    cell.textLabel.numberOfLines = (indexPath.section == 0 && indexPath.row == 1) ? 2 : 1;
    cell.accessoryType = (indexPath.section == 1) ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    
    return cell;
}

#pragma mark - UITableViewDelegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if(indexPath.section == 0) {
        [_tableView deselectRowAtIndexPath:indexPath animated:YES];
        
        if(indexPath.row == 0) {
            NSString *encodedPhone = [_phoneNumber stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSURL *phoneURL = [NSURL URLWithString:[NSString stringWithFormat:@"tel://%@", encodedPhone]];
            if([[UIApplication sharedApplication] canOpenURL:phoneURL])
                [[UIApplication sharedApplication] openURL:phoneURL];
        } else {
            MKPlacemark *placemark = [[MKPlacemark alloc] initWithCoordinate:_locationCoordinate addressDictionary:nil];
            MKMapItem *mapItem = [[MKMapItem alloc] initWithPlacemark:placemark];
            [mapItem setName:SCHOOL_TITLE];
            [mapItem openInMapsWithLaunchOptions:nil];
        }
    } else if(indexPath.section == 1) {
        NCContactDirectory directory;
        
        if(indexPath.row == 0) directory = NCContactDirectoryAdministration;
        else if(indexPath.row == 1) directory = NCContactDirectoryOffice;
        else directory = NCContactDirectoryFaculty;
        
        NCDirectoryViewController *viewController = [[NCDirectoryViewController alloc] initWithDirectory:directory];
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

#pragma mark - Memory mangement

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
