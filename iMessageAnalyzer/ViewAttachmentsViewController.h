//
//  ViewAttachmentsViewController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/22/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import <Quartz/Quartz.h>

#import "Attachment.h"

/** Shows attachments */

@interface ViewAttachmentsViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

#pragma mark Constructor
- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil attachments:(NSMutableArray*)attachments;

@end