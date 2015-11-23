//
//  ViewAttachmentsViewController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/22/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import <AVFoundation/AVFoundation.h>
#import <QTKit/QTKit.h>


#import "Attachment.h"



@interface ViewAttachmentsViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil attachments:(NSMutableArray*)attachments;

@end
