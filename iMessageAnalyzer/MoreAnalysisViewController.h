//
//  MoreAnalysisViewController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/14/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "MessageManager.h"

#import "WordFrequencyHeapDataStructure.h"

#import "Person.h"
#import "Statistics.h"
#import "Message.h"

@interface MoreAnalysisViewController : NSViewController <NSTableViewDataSource, NSTableViewDelegate>

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person*)person messages:(NSMutableArray*)messages;

@end
