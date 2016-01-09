//
//  PieChartViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/8/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "PieChartViewController.h"

#pragma mark Graph type identifiers

typedef enum {
    sentAndReceivedMessages,
    sentAndReceivedWords,
    totalMessages
} PieType;


@interface PieChartViewController ()

#pragma mark Private variables

@property (strong) IBOutlet CPTGraphHostingView *graphHostingView;
@property (strong, nonatomic) CPTGraph *graph;

@property (strong, nonatomic) TemporaryDatabaseManager *messageManager;
@property (strong, nonatomic) Person *person;

@property PieType pieType;

@end

@implementation PieChartViewController


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
        self.pieType = sentAndReceivedWords;
    }
    
    return self;
}


/****************************************************************
 *
 *             Graph setup
 *
 *****************************************************************/

# pragma mark Graph setup

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphHostingView.frame];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    [self.graphHostingView setHostedGraph:self.graph];
    
    CPTPieChart *pieChart = [[CPTPieChart alloc] initWithFrame:self.graph.bounds];
    [pieChart setPieRadius:100.0];
    [pieChart setIdentifier:@"pieChart"];
    [pieChart setSliceDirection:CPTPieDirectionCounterClockwise];
    [pieChart setDataSource:self];
    [pieChart setDelegate:self];
    
    [self.graph addPlot:pieChart];
    [self.graph setAxisSet:nil];
    [self.graph setBorderLineStyle:nil];
    
    [self setGraphLegendAndTitle];
}

- (void) setGraphLegendAndTitle
{
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    [textStyle setFontSize:10.0f];
    [textStyle setColor:[CPTColor colorWithCGColor:[[NSColor whiteColor] CGColor]]];
    
    CPTLegend *theLegend = [CPTLegend legendWithGraph:[self graph]];
    [theLegend setNumberOfColumns:2];
    [theLegend setTextStyle:textStyle];
    [self.graph setLegend:theLegend];
    [self.graph setLegendAnchor:CPTRectAnchorBottom];
    [self.graph setLegendDisplacement:CGPointMake(0.0, 0.0)];
    
    textStyle = [CPTMutableTextStyle textStyle];
    textStyle.color = [CPTColor yellowColor];
    [self.graph setTitleTextStyle:textStyle];
    [self.graph setTitle:[NSString stringWithFormat:@"Total sent and received words with %@", self.person.personName]];
}


/****************************************************************
 *
 *              CPTPieChart Data Source
 *
*****************************************************************/

# pragma mark CPTPieChart Data Source

- (NSString*) legendTitleForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)idx
{
    switch (self.pieType) {
        case sentAndReceivedWords:
            return idx == 0 ? [NSString stringWithFormat:@"My total words to %@", self.person.personName] : [NSString stringWithFormat:@"%@'s words to me", self.person.personName];
            
        case sentAndReceivedMessages:
            return idx == 0 ? [NSString stringWithFormat:@"My messages to %@", self.person.personName] : [NSString stringWithFormat:@"%@'s messages to me", self.person.personName];
            
        case totalMessages:
            return idx == 0 ? @"This conversation's messages" : @"All other messages";
            
        default:
            return @"Error";
    }
}

- (CPTLayer*) dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)idx
{
    CPTMutableTextStyle *labelText = [[CPTMutableTextStyle alloc] init];
    labelText.color = idx == 0 ? [CPTColor redColor] : [CPTColor greenColor];
    
    int firstSum = [[self numberForPlot:plot field:0 recordIndex:idx] intValue];
    int secondSum = [[self numberForPlot:plot field:0 recordIndex:idx == 0 ? 1 : 0] intValue];
    int total = firstSum + secondSum;

    
    NSString *text = @""; //[self legendTitleForPieChart:(CPTPieChart*) plot recordIndex:idx];

    NSString *labelValue = [NSString stringWithFormat:@"%@%.2f%% (%d/%d)", text, (firstSum * 100.0 / total), firstSum, total];
    return [[CPTTextLayer alloc] initWithText:labelValue style:labelText];
}

- (id) numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)idx
{
    switch (self.pieType) {
        case sentAndReceivedWords:
            return idx == 0 ? @([self.messageManager getMySentMessagesWordCountInConversation:0 endTime:INT_MAX]) : @([self.messageManager getMyReceivedMessagesWordCountInConversation:0 endTime:INT_MAX]);
            
        case sentAndReceivedMessages:
            return idx == 0 ? @([self.messageManager getMySentMessagesCountInConversationStartTime:0 endTime:INT_MAX]) : @([self.messageManager getReceivedMessagesCountInConversationStartTime:0 endTime:INT_MAX]);
            
        case totalMessages:
            return idx == 0 ? @([self.messageManager getConversationMessageCountStartTime:0 endTime:INT_MAX]) : @([self.messageManager getOtherMessagesCountStartTime:0 endTime:INT_MAX]);
        default:
            return @(0);
    }
}

- (NSUInteger) numberOfRecordsForPlot:(CPTPlot *)plot
{
    return 2;
}


/****************************************************************
 *
 *              Data Modification
 *
*****************************************************************/

# pragma mark Data modification

- (void) showSentAndReceivedMessages
{
    if(self.pieType == sentAndReceivedMessages) {
        return;
    }
    
    [self.graph setTitle:[NSString stringWithFormat:@"Total sent and received messages with %@", self.person.personName]];
    self.pieType = sentAndReceivedMessages;
    [self.graph reloadData];
}

- (void) showSentAndReceivedWords
{
    if(self.pieType == sentAndReceivedWords) {
        return;
    }
    
    [self.graph setTitle:[NSString stringWithFormat:@"Total sent and received words with %@", self.person.personName]];
    self.pieType = sentAndReceivedWords;
    [self.graph reloadData];
}

- (void) showTotalMessages
{
    if(self.pieType == totalMessages) {
        return;
    }
    
    [self.graph setTitle:[NSString stringWithFormat:@"Messages with %@ vs all other messages", self.person.personName]];
    self.pieType = totalMessages;
    [self.graph reloadData];
}

@end