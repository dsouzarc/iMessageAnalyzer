//
//  SimpleAnalyticsPopUpViewController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/12/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SimpleAnalyticsPopUpViewController : NSViewController

@property (strong) IBOutlet NSTextField *numberOfSentMessages;
@property (strong) IBOutlet NSTextField *numberOfReceivedMessages;
@property (strong) IBOutlet NSTextField *totalNumberOfMessages;


@end
