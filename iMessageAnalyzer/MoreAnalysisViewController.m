//
//  MoreAnalysisViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/14/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "MoreAnalysisViewController.h"

@interface MoreAnalysisViewController ()

@property (strong, nonatomic) Person *person;
@property (strong, nonatomic) NSMutableArray *messages;

@end

@implementation MoreAnalysisViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person *)person messages:(NSMutableArray *)messages
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.person = person;
        self.messages = messages;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
