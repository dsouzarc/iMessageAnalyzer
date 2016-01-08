//
//  BarPlotViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/8/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "BarPlotViewController.h"

@interface BarPlotViewController ()

@property (strong) IBOutlet CPTGraphHostingView *graphHostingView;
@property (strong, nonatomic) CPTGraph *graph;

@property (strong, nonatomic) TemporaryDatabaseManager *messageManager;
@property (strong, nonatomic) Person *person;

@property BarPlotType barPlotType;

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
    
    self.graph = [[CPTXYGraph alloc] initWithFrame:self.graphHostingView.frame];
    [self.graph applyTheme:[CPTTheme themeNamed:kCPTDarkGradientTheme]];
    [self.graphHostingView setHostedGraph:self.graph];
    
    CPTBarPlot *barPlot = [[CPTBarPlot alloc] initWithFrame:self.graph.bounds];
    barPlot.identifier = @"barPlot";
    barPlot.delegate = self;
    barPlot.dataSource = self;
    
    [self.graph addPlot:barPlot];
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
    [textStyle setFontSize:10.0f];
    [textStyle setColor:[CPTColor colorWithCGColor:[[NSColor whiteColor] CGColor]]];
    
    CPTLegend *theLegend = [CPTLegend legendWithGraph:[self graph]];
    [theLegend setNumberOfColumns:2];
    [theLegend setTextStyle:textStyle];
    [self.graph setLegend:theLegend];
    [self.graph setLegendAnchor:CPTRectAnchorBottom];
    [self.graph setLegendDisplacement:CGPointMake(0.0, 0.0)];
}



@end
