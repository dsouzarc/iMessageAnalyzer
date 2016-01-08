//
//  BarPlotViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/8/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "BarPlotViewController.h"

static NSString *mainPlotId = @"mainPlot";
static NSString *secondPlotId = @"secondPlot";

typedef enum {
    sentAndReceivedMessages,
    sentAndReceivedWords,
    totalMessages
} BarPlotType;

typedef enum {
    mainPlot,
    secondPlot
} BarPlotIdentifier;

@interface BarPlotViewController ()

@property (strong) IBOutlet CPTGraphHostingView *graphHostingView;
@property (strong, nonatomic) CPTGraph *graph;

@property (strong, nonatomic) TemporaryDatabaseManager *messageManager;
@property (strong, nonatomic) Person *person;

@property BarPlotType barPlotType;

@property (strong, nonatomic) NSMutableArray *mainData;
@property (strong, nonatomic) NSMutableArray *secondData;

@end

@implementation BarPlotViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person *)person temporaryDatabase:(TemporaryDatabaseManager *)temporaryDatabase
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.messageManager = temporaryDatabase;
        self.person = person;
        self.barPlotType = sentAndReceivedWords;
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.mainData = [self.messageManager getMySentMessagesInConversationOverHoursInDay:0 endTime:INT_MAX];
    self.secondData = [self.messageManager getReceivedMessagesInConversationOverHoursInDay:0 endTime:INT_MAX];
    
    NSLog(@"%@\t%@", self.mainData, self.secondData);
    
    [self setPlotRange];
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphHostingView.frame];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    [self.graphHostingView setHostedGraph:self.graph];
    
    self.graph.paddingLeft = 0.0;
    self.graph.paddingTop = 0.0;
    self.graph.paddingRight = 0.0;
    self.graph.paddingBottom = 0.0;
    
    self.graph.plotAreaFrame.paddingLeft = 55.0;
    self.graph.plotAreaFrame.paddingTop = 40.0;
    self.graph.plotAreaFrame.paddingRight = 40.0;
    self.graph.plotAreaFrame.paddingBottom = 35.0;
    
    self.graph.plotAreaFrame.plotArea.fill = self.graph.plotAreaFrame.fill;
    self.graph.plotAreaFrame.fill = nil;
    
    self.graph.plotAreaFrame.borderLineStyle = nil;
    self.graph.plotAreaFrame.cornerRadius = 0.0;
    self.graph.plotAreaFrame.masksToBorder = NO;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.graph.defaultPlotSpace;
    
    [plotSpace setXRange:[CPTPlotRange plotRangeWithLocation:@(0)
                                                      length:@(24)]];
    [plotSpace setYRange:[CPTPlotRange plotRangeWithLocation:@(0)
                                                      length:@(15)]];
    [plotSpace setAllowsUserInteraction:YES];
    
    
    CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
    barLineStyle.lineColor = [CPTColor whiteColor];
    barLineStyle.lineWidth = 0.5;
    
    CPTBarPlot *mainPlot = [[CPTBarPlot alloc] initWithFrame:self.graph.bounds];
    mainPlot.identifier = mainPlotId;
    mainPlot.delegate = self;
    mainPlot.dataSource = self;
    mainPlot.fill = [CPTFill fillWithColor:[CPTColor redColor]];
    [barLineStyle setLineFill:[CPTFill fillWithColor:[CPTColor redColor]]];
    mainPlot.lineStyle = barLineStyle;
    
    CPTBarPlot *secondPlot = [[CPTBarPlot alloc] initWithFrame:self.graph.bounds];
    secondPlot.identifier = secondPlotId;
    secondPlot.delegate = self;
    secondPlot.dataSource = self;
    secondPlot.barOffset = mainPlot.barWidth;
    barLineStyle.lineColor = [CPTColor greenColor];
    [barLineStyle setLineFill:[CPTFill fillWithColor:[CPTColor greenColor]]];
    secondPlot.lineStyle = barLineStyle;

    [self.graph addPlot:mainPlot toPlotSpace:plotSpace];
    [self.graph addPlot:secondPlot toPlotSpace:plotSpace];
    
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    [textStyle setFontSize:10.0f];
    [textStyle setColor:[CPTColor colorWithCGColor:[[NSColor whiteColor] CGColor]]];
    
    CPTXYAxisSet *axis = (CPTXYAxisSet*) self.graph.axisSet;
    axis.xAxis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
    axis.xAxis.majorIntervalLength = @(1);
    
    axis.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
}

- (void) showSentAndReceivedMessages
{
    if(self.barPlotType == sentAndReceivedMessages) {
        return;
    }
    
    self.barPlotType = sentAndReceivedMessages;
    self.mainData = [self.messageManager getMySentMessagesInConversationOverHoursInDay:0 endTime:INT_MAX];
    self.secondData = [self.messageManager getReceivedMessagesInConversationOverHoursInDay:0 endTime:INT_MAX];
    [self setPlotRange];
    [self.graph reloadData];
}

- (CPTLayer*) dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)idx
{
    int value = 0;
    CPTColor *color;
    if([self getPlotType:plot] == mainPlot) {
        value = [self.mainData[idx] intValue];
        color = [CPTColor redColor];
    }
    else {
        value = [self.secondData[idx] intValue];
        color = [CPTColor greenColor];
    }
    
    CPTTextLayer *label = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%d", value]];
    CPTMutableTextStyle *textStyle = [label.textStyle mutableCopy];
    
    
    
    textStyle.color = color;
    label.textStyle = textStyle;
    return label;
}

- (void) showSentAndReceivedWords
{
    if(self.barPlotType == sentAndReceivedWords) {
        return;
    }
    self.barPlotType = sentAndReceivedWords;
    
    self.mainData = [self.messageManager getMySentWordsInConversationOverHoursInDay:0 endTime:INT_MAX];
    self.secondData = [self.messageManager getReceivedWordsInConversationOverHoursInDay:0 endTime:INT_MAX];
    [self setPlotRange];
    [self.graph reloadData];
}

- (void) showTotalMessages
{
    if(self.barPlotType == totalMessages) {
        return;
    }
    
    self.barPlotType = totalMessages;
    
    self.mainData = [self.messageManager getThisConversationMessagesOverHoursInDay:0 endTime:INT_MAX];
    self.secondData = [self.messageManager getOtherMessagesOverHoursInDay:0 endTime:INT_MAX];
    [self setPlotRange];
    [self.graph reloadData];
}



- (NSUInteger) numberOfRecordsForPlot:(CPTPlot *)plot
{
    return 24;
}

- (BarPlotIdentifier) getPlotType:(CPTPlot*)plot
{
    NSString *plotType = (NSString*) plot.plotSpace.identifier;
    if([plot.identifier isEqual:mainPlotId]) {
        return mainPlot;
    }
    else if([plot.identifier isEqual:secondPlotId]) {
        return secondPlot;
    }
    
    if([plotType isEqualToString:mainPlotId]) {
        return mainPlot;
    }
    else if([plotType isEqualToString:secondPlotId]) {
        return secondPlot;
    }
    return mainPlot;
}

- (id) numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
    if([self getPlotType:plot] == mainPlot) {
        return self.mainData[idx];
    }
    else {
        return self.secondData[idx];
    }
}

- (void) setPlotRange
{
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*) self.graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(0) length:@(24)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(0) length:@([self getMaxFromData])];
}

- (double) getMaxFromData
{
    int mainMax = [self getMaxFromArray:self.mainData];
    int secondMax = [self getMaxFromArray:self.secondData];
    return MAX(mainMax, secondMax) * (11.0 / 10);
}

- (int) getMaxFromArray:(NSMutableArray*)array
{
    int max = 0;
    for(NSNumber *number in array) {
        if([number intValue] > max) {
            max = [number intValue];
        }
    }
    
    return max;
}

- (NSString*) legendTitleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)idx
{
    switch (self.barPlotType) {
        case sentAndReceivedWords:
            return idx == 0 ? [NSString stringWithFormat:@"My total words to %@", self.person.personName] : [NSString stringWithFormat:@"%@'s words to me", self.person.personName];
        case sentAndReceivedMessages:
            return idx == 0 ? [NSString stringWithFormat:@"My messages to %@", self.person.personName] : [NSString stringWithFormat:@"%@'s messages to me", self.person.personName];
        case totalMessages:
            return idx == 0 ? @"This conversation's messages" : @"All other messages";
        default:
            break;
    }
    return @"Error";
}



@end
