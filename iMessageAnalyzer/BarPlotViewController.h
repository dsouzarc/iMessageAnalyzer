//
//  BarPlotViewController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/8/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <CorePlot/CorePlot.h>

#import "Constants.h"
#import "TemporaryDatabaseManager.h"
#import "Message.h"
#import "Person.h"
#import "Statistics.h"

typedef enum {
    sentAndReceivedMessages,
    sentAndReceivedWords,
    totalMessages
} BarPlotType;

typedef enum {
    mainPlot,
    secondPlot
} BarPlotIdentifier;

@interface BarPlotViewController : NSViewController <CPTBarPlotDataSource, CPTBarPlotDelegate>

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person *)person temporaryDatabase:(TemporaryDatabaseManager *)temporaryDatabase;


@end
