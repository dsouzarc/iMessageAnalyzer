//
//  ViewAttachmentsViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/22/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "ViewAttachmentsViewController.h"

@interface ViewAttachmentsViewController ()

@property (strong, nonatomic) NSMutableArray *attachments;

@end

@implementation ViewAttachmentsViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil attachments:(NSMutableArray *)attachments
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    self.attachments = attachments;
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

@end
