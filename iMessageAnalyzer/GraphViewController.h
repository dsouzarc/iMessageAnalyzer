//
//  GraphViewController.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 12/9/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import <CorePlot/CorePlot.h>

#import "DropPlotMessageAnalyzerViewController.h"
#import "PieChartViewController.h"
#import "BarPlotViewController.h"

#import "TemporaryDatabaseManager.h"
#import "Message.h"
#import "Person.h"
#import "Statistics.h"

@interface GraphViewController : NSViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person*)person temporaryDatabase:(TemporaryDatabaseManager*)temporaryDatabase firstMessageDate:(NSDate*)firstMessage graphView:(NSView*)graphView;

@end
