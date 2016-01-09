//
//  DropPlotMessageAnalyzerViewController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/25/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <CorePlot/CorePlot.h>

#import "Constants.h"
#import "TemporaryDatabaseManager.h"
#import "Message.h"
#import "Person.h"
#import "Statistics.h"


/** Controls the line graph for viewing messages/words over time */

@interface DropPlotMessageAnalyzerViewController : NSViewController <CPTPlotDataSource, CPTPlotSpaceDelegate, CPTScatterPlotDelegate, CPTLegendDelegate>

#pragma mark Constructor
- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person*)person temporaryDatabase:(TemporaryDatabaseManager*)temporaryDatabase firstMessageDate:(NSDate*)firstMessage;


#pragma mark Modify graph data

- (void) showThisConversationSentAndReceivedWords;
- (void) showThisConversationSentAndReceivedMessages;
- (void) showThisConversationMessagesOverYear;

- (void) showAllOtherMessagesOverYear;
- (void) hideSecondGraph;

@end