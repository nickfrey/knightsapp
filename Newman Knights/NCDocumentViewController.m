//
//  NCDocumentViewController.m
//  Newman Knights
//
//  Created by Nick Frey on 3/14/14.
//  Copyright (c) 2014 Newman Catholic. All rights reserved.
//

#import "NCDocumentViewController.h"
#import "AFNetworking.h"
#import "NCAppConfig.h"

@interface NCDocumentViewController ()

@property (nonatomic, strong) NSString *initialDocumentID;
@property (nonatomic, strong) NSURL *documentURL;

@end

@implementation NCDocumentViewController

- (instancetype)initWithDocumentID:(NSString *)documentID {
    self = [super init];
    if(self) {
        _initialDocumentID = documentID;
    }
    return self;
}

- (void)loadPage {
    NSString *url = [NSString stringWithFormat:@"https://www.googleapis.com/drive/v2/files/%@?key=%@&fields=exportLinks", _initialDocumentID, GOOGLE_DRIVE_KEY];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    [manager GET:url parameters:nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        if([responseObject isKindOfClass:[NSDictionary class]] && responseObject[@"exportLinks"]) {
            NSString *pdfURL = responseObject[@"exportLinks"][@"application/pdf"];
            //NSString *htmlURL = responseObject[@"exportLinks"][@"text/html"];
            
            _documentURL = [NSURL URLWithString:pdfURL];
            [self.webView loadRequest:[NSURLRequest requestWithURL:_documentURL]];
        } else {
            NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain
                                                        code:NSURLErrorBadServerResponse
                                                    userInfo:@{NSLocalizedDescriptionKey: @"This document could not be located."}];
            [self failWithError:error];
        }
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self failWithError:error];
    }];
}

- (NSURL *)shareableURL {
    return [NSURL URLWithString:[@"https://docs.google.com/document/d/" stringByAppendingString:_initialDocumentID]];
}

@end
