//
//  SimpleAnalyticsPopUpViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/12/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "SimpleAnalyticsPopUpViewController.h"

@interface SimpleAnalyticsPopUpViewController ()

@end

@implementation SimpleAnalyticsPopUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}
- (IBAction)wantsMoreAnalysis:(id)sender {
    [self.delegate wantsMoreAnalysis];
}

@end
