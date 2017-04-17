//
//  MoreAnalysisViewController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/14/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "ViewAttachmentsViewController.h"
#import "WordFrequencyHeapDataStructure.h"
#import "GraphViewController.h"

#import "NSTextField+Messages.h"
#import "MessageManager.h"
#import "TemporaryDatabaseManager.h"

#import "Constants.h"
#import "Person.h"
#import "Statistics.h"
#import "Message.h"

#import "RSVerticallyCenteredTextFieldCell.h"

/** Shows more analysis screen that includes graph */

@interface MoreAnalysisViewController : NSViewController <NSTextFieldDelegate, NSTableViewDataSource, NSTableViewDelegate, NSDatePickerCellDelegate, NSPopoverDelegate, NSTextField_MessagesDelegate>


# pragma mark - Constructor 

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person*)person messages:(NSMutableArray*)messages databaseManager:(TemporaryDatabaseManager*)databaseManager;

@end
