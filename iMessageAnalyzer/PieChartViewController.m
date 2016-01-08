//
//  PieChartViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/8/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "PieChartViewController.h"

@interface PieChartViewController ()

@property (strong) IBOutlet CPTGraphHostingView *graphHostingView;
@property (strong, nonatomic) CPTGraph *graph;

@property (strong, nonatomic) TemporaryDatabaseManager *messageManager;
@property (strong, nonatomic) Person *person;

@property PieType pieType;

@end

@implementation PieChartViewController

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

    CPTLegend *theLegend = [CPTLegend legendWithGraph:[self graph]];
    [theLegend setNumberOfColumns:2];
    [[self graph] setLegend:theLegend];
    [[self graph] setLegendAnchor:CPTRectAnchorBottom];
    [[self graph] setLegendDisplacement:CGPointMake(0.0, 30.0)];
}

- (NSString*) legendTitleForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)idx
{
    switch (self.pieType) {
        case sentAndReceivedWords:
            return idx == 0 ? @"My Sent Words" : [NSString stringWithFormat:@"%@'s Sent Words", self.person.personName];
        case sentAndReceivedMessages:
            return idx == 0 ? @"My Sent Messages" : [NSString stringWithFormat:@"%@'s Sent Messages", self.person.personName];
        case totalMessages:
            return idx == 0 ? @"This Conversation's Messages" : @"All Other Messages";
        default:
            break;
    }
    return @"Error";
}

- (NSUInteger) numberOfRecordsForPlot:(CPTPlot *)plot
{
    return 2;
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

- (void) showSentAndReceivedMessages
{
    self.pieType = sentAndReceivedMessages;
    [self.graph reloadData];
}

- (void) showSentAndReceivedWords
{
    self.pieType = sentAndReceivedWords;
    [self.graph reloadData];
}

- (void) showTotalMessages
{
    self.pieType = totalMessages;
    [self.graph reloadData];
}

@end