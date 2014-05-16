//
//  NCGradesViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 10/12/13.
//  Copyright (c) 2013 Newman Catholic. All rights reserved.
//

#import "NCGradesViewController.h"
#import "NCAppConfig.h"

@interface NCGradesViewController ()

@property (nonatomic, strong) UIBarButtonItem *backButton;;
@property (nonatomic, strong) UIBarButtonItem *forwardButton;
@property (nonatomic, strong) UIBarButtonItem *refreshButton;
@property (nonatomic, strong) UIBarButtonItem *loadingIndicator;

@end

@implementation NCGradesViewController

- (id)init {
    self = [super initWithURL:[NSURL URLWithString:POWERSCHOOL_URL]];
    if(self) {
        NSString *localizedTitle = NSLocalizedString(@"Grades", @"Grades");
        self.title = localizedTitle;
        self.tabBarItem.title = localizedTitle;
        self.tabBarItem.image = [UIImage imageNamed:@"tabGrades"];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Left side
    _backButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gradesBack"] style:UIBarButtonItemStylePlain target:self.webView action:@selector(goBack)];
    _forwardButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gradesForward"] style:UIBarButtonItemStylePlain target:self.webView action:@selector(goForward)];
    
    [self.navigationItem setLeftBarButtonItems:@[_backButton, _forwardButton]];
    
    // Right side
    _refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self.webView action:@selector(reload)];
    
    UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];
    [activityIndicator startAnimating];
    
    _loadingIndicator = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
    self.navigationItem.rightBarButtonItem = _loadingIndicator;
}

- (void)success {
    [super success];
    [self updateBarButtonItems];
    
    // Allow the page to be scaled (seriously PowerSchool?)
    [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementsByName('viewport')[0].setAttribute('content','width=device-width; initial-scale=1.0; maximum-scale=1.0; user-scalable=1;')"];
    
    // Auto-Login (Future feature?)
    /*if(![self.webView canGoBack]) {
        [self.webView stringByEvaluatingJavaScriptFromString:@"document.getElementById('fieldAccount').value='someUsername'; document.getElementsByName('pw')[0].value='somePassword'; setTimeout(function() {document.getElementById('btn-enter').click();}, 1000);"];
    }*/
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    [super webViewDidStartLoad:webView];
    [self updateBarButtonItems];
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    [super webView:webView didFailLoadWithError:error];
    [self updateBarButtonItems];
}

- (void)updateBarButtonItems {
    _backButton.enabled = [self.webView canGoBack];
    _forwardButton.enabled = [self.webView canGoForward];
    self.navigationItem.rightBarButtonItem = self.webView.isLoading ? _loadingIndicator : _refreshButton;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
