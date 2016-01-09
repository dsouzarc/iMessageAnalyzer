//
//  BarPlotViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/8/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "BarPlotViewController.h"


#pragma mark Plot and graph type identifiers 

static NSString *mainPlotId = @"mainPlot";
static NSString *secondPlotId = @"secondPlot";

typedef enum {
    sentAndReceivedMessages,
    sentAndReceivedWords,
    totalMessages,
    totalMessagesAsPercentage
} BarPlotType;

typedef enum {
    mainPlot,
    secondPlot
} BarPlotIdentifier;


@interface BarPlotViewController ()


/****************************************************************
 *
 *              Private class variables
 *
*****************************************************************/

#pragma mark CPTGraph Variables

@property (strong) IBOutlet CPTGraphHostingView *graphHostingView;
@property (strong, nonatomic) CPTGraph *graph;

@property (strong, nonatomic) CPTBarPlot *mainPlot;
@property (strong, nonatomic) CPTBarPlot *secondPlot;
@property (strong, nonatomic) CPTAnnotation *yValueAnnotation;
@property (strong, nonatomic) NSNumber *barWidth;


#pragma mark Data variables

@property (strong, nonatomic) NSMutableArray *mainData;
@property (strong, nonatomic) NSMutableArray *secondData;
@property BarPlotType barPlotType;


#pragma mark Person variables

@property (strong, nonatomic) TemporaryDatabaseManager *messageManager;
@property (strong, nonatomic) Person *person;

@end

@implementation BarPlotViewController


/****************************************************************
 *
 *              Constructor
 *
*****************************************************************/

# pragma mark Constructor

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person *)person temporaryDatabase:(TemporaryDatabaseManager *)temporaryDatabase
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.messageManager = temporaryDatabase;
        self.person = person;
        self.barPlotType = sentAndReceivedMessages;
        
        mainPlotId = [NSString stringWithFormat:@"Messages to %@", self.person.personName];
        secondPlotId = [NSString stringWithFormat:@"Messages from %@", self.person.personName];
    }
    
    return self;
}

- (void) viewDidLoad {
    
    [super viewDidLoad];
    
    //Start off showing sent vs received messages
    self.mainData = [self.messageManager getMySentMessagesInConversationOverHoursInDay:0 endTime:INT_MAX];
    self.secondData = [self.messageManager getReceivedMessagesInConversationOverHoursInDay:0 endTime:INT_MAX];
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphHostingView.frame];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    [self.graphHostingView setHostedGraph:self.graph];
    
    [self setGraphPaddingAndPlotArea];
    [self createGraphPlots];
    [self setGraphAxisProperties];
    
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *) self.graph.defaultPlotSpace;
    [plotSpace setXRange:[CPTPlotRange plotRangeWithLocation:@(0)
                                                      length:@(24)]];
    [plotSpace setYRange:[CPTPlotRange plotRangeWithLocation:@(0)
                                                      length:@([self getMaxFromData])]];
    [plotSpace setAllowsUserInteraction:NO];
    
    [self.graph addPlot:self.mainPlot toPlotSpace:plotSpace];
    [self.graph addPlot:self.secondPlot toPlotSpace:plotSpace];
    
    [self setLegendAndTitle];
}


/****************************************************************
 *
 *              Set Graph Properties
 *
*****************************************************************/

# pragma mark Set Graph Properties

- (void) setLegendAndTitle
{
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    [textStyle setFontSize:10.0f];
    [textStyle setColor:[CPTColor whiteColor]];
    
    CPTLegend *theLegend = [CPTLegend legendWithGraph:self.graph];
    theLegend.numberOfColumns = 1;
    theLegend.textStyle = textStyle;
    theLegend.cornerRadius = 5.0;
    theLegend.delegate = self;
    
    self.graph.legend = theLegend;
    self.graph.legendAnchor = CPTRectAnchorTopRight;
    self.graph.legendDisplacement = CGPointMake(0.0, 0.0);
    
    textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor yellowColor];
    [self.graph setTitleTextStyle:textStyle];
    [self.graph setTitle:[NSString stringWithFormat:@"Sent and received words with %@ over 24 hours", self.person.personName]];
}

- (void) setGraphAxisProperties
{
    NSDictionary *result = [self getTickLocationsAndLabelsForHours];
    
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    [textStyle setFontSize:10.0f];
    [textStyle setColor:[CPTColor colorWithCGColor:[[NSColor whiteColor] CGColor]]];
    
    CPTXYAxisSet *axis = (CPTXYAxisSet*) self.graph.axisSet;
    [axis.xAxis setMajorIntervalLength:[NSNumber numberWithDouble:24.0]];
    [axis.xAxis setMinorTickLineStyle:nil];
    [axis.xAxis setLabelTextStyle:textStyle];
    [axis.xAxis setLabelRotation:M_PI/6];
    
    axis.xAxis.labelingPolicy = CPTAxisLabelingPolicyNone;
    axis.xAxis.majorTickLocations = result[@"tickLocations"];
    axis.xAxis.axisLabels = result[@"tickLabels"];
    
    axis.yAxis.labelingPolicy = CPTAxisLabelingPolicyAutomatic;
}

- (void) setGraphPaddingAndPlotArea
{
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
}

- (void) createGraphPlots
{
    CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
    barLineStyle.lineColor = [CPTColor whiteColor];
    barLineStyle.lineFill = [CPTFill fillWithColor:[CPTColor whiteColor]];
    barLineStyle.lineWidth = 0.5;
    
    self.mainPlot = [[CPTBarPlot alloc] initWithFrame:self.graph.bounds];
    self.mainPlot.identifier = mainPlotId;
    self.mainPlot.delegate = self;
    self.mainPlot.dataSource = self;
    self.mainPlot.fill = [CPTFill fillWithColor:[CPTColor redColor]];
    self.mainPlot.lineStyle = barLineStyle;
    self.barWidth = self.mainPlot.barWidth;
    
    self.secondPlot = [[CPTBarPlot alloc] initWithFrame:self.graph.bounds];
    self.secondPlot.identifier = secondPlotId;
    self.secondPlot.delegate = self;
    self.secondPlot.dataSource = self;
    self.secondPlot.barOffset = self.mainPlot.barWidth;
    
    barLineStyle.lineColor = [CPTColor whiteColor];
    barLineStyle.lineFill =[CPTFill fillWithColor:[CPTColor whiteColor]];
    self.secondPlot.fill = [CPTFill fillWithColor:[CPTColor blueColor]];
    self.secondPlot.lineStyle = barLineStyle;
}


/****************************************************************
 *
 *              Modify graph data
 *
*****************************************************************/

# pragma mark Modify graph data

- (void) showSentAndReceivedMessages
{
    if(self.barPlotType == sentAndReceivedMessages) {
        return;
    }
    
    self.barPlotType = sentAndReceivedMessages;
    self.mainData = [self.messageManager getMySentMessagesInConversationOverHoursInDay:0 endTime:INT_MAX];
    self.secondData = [self.messageManager getReceivedMessagesInConversationOverHoursInDay:0 endTime:INT_MAX];
    
    NSString *graphTitle = [NSString stringWithFormat:@"Sent and received messages with %@ over 24 hours", self.person.personName];
    NSString *mainPlotTitle = [NSString stringWithFormat:@"Messages to %@", self.person.personName];
    NSString *secondPlotTitle = [NSString stringWithFormat:@"Messages from %@", self.person.personName];
    
    [self setGraphTitle:graphTitle mainPlotTitle:mainPlotTitle secondPlotTitle:secondPlotTitle];
    [self setPlotRange];
}

- (void) showSentAndReceivedWords
{
    if(self.barPlotType == sentAndReceivedWords) {
        return;
    }
    self.barPlotType = sentAndReceivedWords;
    
    self.mainData = [self.messageManager getMySentWordsInConversationOverHoursInDay:0 endTime:INT_MAX];
    self.secondData = [self.messageManager getReceivedWordsInConversationOverHoursInDay:0 endTime:INT_MAX];
    
    NSString *graphTitle = [NSString stringWithFormat:@"Sent and received words with %@ over 24 hours", self.person.personName];
    NSString *mainPlotTitle = [NSString stringWithFormat:@"Words to %@", self.person.personName];
    NSString *secondPlotTitle = [NSString stringWithFormat:@"Words from %@", self.person.personName];
    
    [self setGraphTitle:graphTitle mainPlotTitle:mainPlotTitle secondPlotTitle:secondPlotTitle];
    [self setPlotRange];
}

- (void) showTotalMessages
{
    if(self.barPlotType == totalMessages) {
        return;
    }
    
    self.barPlotType = totalMessages;
    
    self.mainData = [self.messageManager getThisConversationMessagesOverHoursInDay:0 endTime:INT_MAX];
    self.secondData = [self.messageManager getOtherMessagesOverHoursInDay:0 endTime:INT_MAX];
    
    NSString *graphTitle = [NSString stringWithFormat:@"Messages with %@ vs all other messages over 24 hours", self.person.personName];
    NSString *mainPlotTitle = [NSString stringWithFormat:@"Conversation with %@", self.person.personName];
    NSString *secondPlotTitle = @"All other messages";
    
    [self setGraphTitle:graphTitle mainPlotTitle:mainPlotTitle secondPlotTitle:secondPlotTitle];
    [self setPlotRange];
}

- (void) showTotalMessagesAsPercentage
{
    if(self.barPlotType == totalMessagesAsPercentage) {
        return;
    }
    
    self.barPlotType = totalMessagesAsPercentage;
    
    self.mainData = [self.messageManager getThisConversationMessagesOverHoursInDay:0 endTime:INT_MAX];
    self.secondData = [self.messageManager getOtherMessagesOverHoursInDay:0 endTime:INT_MAX];
    
    const int totalConversation = [self.messageManager getConversationMessageCountStartTime:0 endTime:INT_MAX];
    const int totalAllOtherMessages = [self.messageManager getOtherMessagesCountStartTime:0 endTime:INT_MAX];
    
    [self calculatePercents:self.mainData total:totalConversation];
    [self calculatePercents:self.secondData total:totalAllOtherMessages];
    
    NSString *graphTitle = [NSString stringWithFormat:@"%% of messages with %@ vs %% of all other messages over 24 hours", self.person.personName];
    NSString *mainPlotTitle = [NSString stringWithFormat:@"%% of total messages with %@", self.person.personName];
    NSString *secondPlotTitle = @"% of all other messages";
    
    [self setGraphTitle:graphTitle mainPlotTitle:mainPlotTitle secondPlotTitle:secondPlotTitle];
    [self setPlotRange];
}


/****************************************************************
 *
 *              CPTBarPlot Delegate
 *
*****************************************************************/

# pragma mark CPTBarPlot Delegate

- (void) barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)idx
{
    [self removeAnnotations];
    
    int value = 0;
    int plotIndex = 0;
    
    if([self getPlotType:plot] == mainPlot) {
        value = [self.mainData[idx] intValue];
        plotIndex = 0;
    }
    else {
        value = [self.secondData[idx] intValue];
        plotIndex = 1;
    }
    
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    textStyle.fontSize = 15.0f;
    textStyle.fontName = @"Helvetica-Bold";
    textStyle.color = [CPTColor whiteColor];

    NSArray *anchorPoint = [NSArray arrayWithObjects:@(idx + (plotIndex * [self.barWidth doubleValue])), @(value), nil];
    
    NSString *text = nil;
    if(self.barPlotType == totalMessagesAsPercentage) {
        text = [NSString stringWithFormat:@"%d%%", value];
    }
    else {
        text = [NSString stringWithFormat:@"%d", value];
    }
    
    CPTTextLayer *textLayer = [[CPTTextLayer alloc] initWithText:text style:textStyle];
    self.yValueAnnotation = [[CPTPlotSpaceAnnotation alloc] initWithPlotSpace:(CPTXYPlotSpace *)self.graph.defaultPlotSpace  anchorPlotPoint:anchorPoint];
    self.yValueAnnotation.contentLayer = textLayer;
    self.yValueAnnotation.displacement = CGPointMake(0.0f, 15.0f);
    [self.graph.plotAreaFrame.plotArea addAnnotation:self.yValueAnnotation];
}


/****************************************************************
 *
 *              CPTBarPlot Data Source
 *
*****************************************************************/

# pragma mark CPTBarPlot Data Source

- (NSUInteger) numberOfRecordsForPlot:(CPTPlot *)plot
{
    return 24;
}

- (id) numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
    if(fieldEnum == CPTScatterPlotFieldX) {
        return @(idx);
    }
    
    if([self getPlotType:plot] == mainPlot) {
        return self.mainData[idx];
    }
    else {
        return self.secondData[idx];
    }
}


/****************************************************************
 *
 *              Auxillary methods
 *
*****************************************************************/

# pragma mark Auxillary methods

- (void) setGraphTitle:(NSString*)graphTitle mainPlotTitle:(NSString*)mainPlotTitle secondPlotTitle:(NSString*)secondPlotTitle
{
    [self.graph setTitle:graphTitle];
    [self.mainPlot setTitle:mainPlotTitle];
    [self.secondPlot setTitle:secondPlotTitle];
    
    CPTXYAxisSet *axis = (CPTXYAxisSet*) self.graph.axisSet;
    if(self.barPlotType == totalMessagesAsPercentage) {
        [axis.yAxis setTitle:@"% of total messages"];
    }
    else {
        [axis.yAxis setTitle:nil];
    }
    [self removeAnnotations];
}

- (void) removeAnnotations
{
    if(self.yValueAnnotation) {
        [self.graph.plotAreaFrame.plotArea removeAnnotation:self.yValueAnnotation];
        self.yValueAnnotation = nil;
    }
}

- (void) calculatePercents:(NSMutableArray*)messages total:(int)total
{
    for(int i = 0; i < messages.count; i++) {
        int messageCount = [messages[i] intValue];
        double percentage = (messageCount * 100.0) / total;
        messages[i] = @(percentage);
    }
}

- (void) setPlotRange
{
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace*) self.graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:@(0) length:@(24)];
    plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:@(0) length:@([self getMaxFromData])];
    [self.graph reloadData];
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

- (NSDictionary*) getTickLocationsAndLabelsForHours
{
    CPTXYAxis *xAxis = [((CPTXYAxisSet *)self.graph.axisSet) xAxis];
    
    NSMutableArray *tickLocations = [[NSMutableArray alloc] init];
    NSMutableArray *tickLabels = [[NSMutableArray alloc] init];
    
    double tickLocation = 0;
    double labelLocation = 0;
    
    for(int i = 0; i < 24; i++) {
        
        NSString *text = @"";
        
        if(i == 0) {
            text = @"12AM";
        }
        else if(i < 12) {
            text = [NSString stringWithFormat:@"%dAM", i];
        }
        else if(i == 12) {
            text = @"12PM";
        }
        else if(i < 24) {
            text = [NSString stringWithFormat:@"%dPM", (i - 12)];
        }
        
        [tickLocations addObject:@(tickLocation)];
        tickLocation += 1;
        CPTAxisLabel *label = [[CPTAxisLabel alloc] initWithText:text textStyle:xAxis.labelTextStyle];
        label.tickLocation = @(labelLocation);
        labelLocation += 1;
        label.offset = 4.0f;
        label.rotation = M_PI / 6;
        
        [tickLabels addObject:label];
    }
    
    return [NSDictionary dictionaryWithObjectsAndKeys:tickLocations, @"tickLocations", tickLabels, @"tickLabels", nil];
}

@end