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
    
    self.mainData = [self.messageManager getMySentWordsInConversationOverHoursInDay:0 endTime:INT_MAX];
    self.secondData = [self.messageManager getReceivedMessagesInConversationOverHoursInDay:0 endTime:INT_MAX];
    [self setPlotRange];
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphHostingView.frame];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    [self.graphHostingView setHostedGraph:self.graph];
    
    CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
    barLineStyle.lineColor = [CPTColor lightGrayColor];
    barLineStyle.lineWidth = 0.5;
    
    CPTBarPlot *mainPlot = [[CPTBarPlot alloc] initWithFrame:self.graph.bounds];
    mainPlot.identifier = mainPlotId;
    mainPlot.delegate = self;
    mainPlot.dataSource = self;
    mainPlot.barWidth = @(0.25f);
    mainPlot.lineStyle = barLineStyle;
    
    CPTBarPlot *secondPlot = [[CPTBarPlot alloc] initWithFrame:self.graph.bounds];
    secondPlot.identifier = secondPlotId;
    secondPlot.delegate = self;
    secondPlot.dataSource = self;
    secondPlot.barWidth = mainPlot.barWidth;
    secondPlot.barOffset = mainPlot.barWidth;
    secondPlot.lineStyle = barLineStyle;
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*) self.graph.defaultPlotSpace;
    [self.graph addPlot:mainPlot toPlotSpace:plotSpace];
    [self.graph addPlot:secondPlot toPlotSpace:plotSpace];
    
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    [textStyle setFontSize:10.0f];
    [textStyle setColor:[CPTColor colorWithCGColor:[[NSColor whiteColor] CGColor]]];
    
    CPTXYAxisSet *axis = (CPTXYAxisSet*) self.graph.axisSet;
    axis.xAxis.labelingPolicy = CPTAxisLabelingPolicyFixedInterval;
    axis.xAxis.majorIntervalLength = @(1.0);
    
    axis.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
    
    
    NSArray *plots = [NSArray arrayWithObjects:mainPlot, secondPlot, nil];
    [plotSpace scaleToFitPlots:plots];
    
    CPTLegend *theLegend = [CPTLegend legendWithPlots:plots];
    [theLegend setNumberOfColumns:2];
    [theLegend setTextStyle:textStyle];
    [self.graph setLegend:theLegend];
    [self.graph setLegendAnchor:CPTRectAnchorBottom];
    [self.graph setLegendDisplacement:CGPointMake(0.0, 0.0)];
    
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
