//
//  GraphViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 12/9/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "GraphViewController.h"

@interface GraphViewController ()

@property (strong, nonatomic) Person *person;
@property (strong, nonatomic) TemporaryDatabaseManager *database;
@property (strong, nonatomic) NSDate *firstMessage;

@property (strong, nonatomic) NSView *graphView;

@property (strong, nonatomic) DropPlotMessageAnalyzerViewController *dropPlotViewController;
@property (strong, nonatomic) PieChartViewController *pieChartViewController;

@property (strong) IBOutlet NSButton *lineGraphAllTimeButton;
@property (strong) IBOutlet NSButton *lineGraphCourseOfDayButton;
@property (strong) IBOutlet NSButton *lineGraphMessagesButton;
@property (strong) IBOutlet NSButton *lineGraphWordsButton;
@property (strong) IBOutlet NSButton *lineGraphCompareToOthersButton;

@property (strong) IBOutlet NSButton *pieChartSentAndReceivedMessages;
@property (strong) IBOutlet NSButton *pieChartSentAndReceivedWords;
@property (strong) IBOutlet NSButton *pieChartSentAndReceivedTotalMessages;

@end

@implementation GraphViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person *)person temporaryDatabase:(TemporaryDatabaseManager *)temporaryDatabase firstMessageDate:(NSDate *)firstMessage graphView:(NSView *)graphView
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.person = person;
        self.database = temporaryDatabase;
        self.firstMessage = firstMessage;
        self.graphView = graphView;
        
        self.dropPlotViewController = [[DropPlotMessageAnalyzerViewController alloc] initWithNibName:@"DropPlotMessageAnalyzerViewController" bundle:nibBundleOrNil person:self.person temporaryDatabase:self.database firstMessageDate:self.firstMessage];
        
        self.pieChartViewController = [[PieChartViewController alloc] initWithNibName:@"PieChartViewController" bundle:[NSBundle mainBundle] person:self.person temporaryDatabase:self.database];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self.dropPlotViewController view] setFrame:self.view.frame];
    [[self.pieChartViewController view] setFrame:self.view.frame];
    
    [self.view addSubview:self.dropPlotViewController.view];
    [self.view addSubview:self.pieChartViewController.view];
    
    [self.pieChartViewController.view setHidden:YES];
    //[self.view addSubview:self.dropPlotViewController.view positioned:NSWindowAbove relativeTo:self.view];
}

- (void) showPieChart
{
    [self.pieChartViewController.view setHidden:NO];
    [self.dropPlotViewController.view setHidden:YES];
}

- (void) showDropPlot
{
    [self.pieChartViewController.view setHidden:YES];
    [self.dropPlotViewController.view setHidden:NO];
}

- (void) disableAllCheckMarks
{
    [self.lineGraphCompareToOthersButton setEnabled:NO];
}

- (IBAction)buttonClick:(id)sender {
    
    [self disableAllCheckMarks];
    
    if(sender == self.lineGraphAllTimeButton) {
        [self showDropPlot];
        [self.lineGraphCompareToOthersButton setEnabled:YES];
    }
    
    else if(sender == self.lineGraphCourseOfDayButton) {
        [self showDropPlot];
        [self.lineGraphCompareToOthersButton setEnabled:YES];
    }
    
    else if(sender == self.lineGraphMessagesButton) {
        [self showDropPlot];
        [self.dropPlotViewController showThisConversationSentAndReceivedMessages];
    }
    
    else if(sender == self.lineGraphWordsButton) {
        [self showDropPlot];
        [self.dropPlotViewController showThisConversationSentAndReceivedWords];
    }

    else if(sender == self.lineGraphCompareToOthersButton) {
        [self showDropPlot];
        [self.lineGraphCompareToOthersButton setEnabled:YES];
        
        if(self.lineGraphCompareToOthersButton.state == NSOnState) {
            if(self.lineGraphAllTimeButton.state == NSOnState) {
                [self.dropPlotViewController showAllOtherMessagesOverYear];
            }
        }
        else {
            [self.dropPlotViewController hideSecondGraph];
        }
    }
    
    else if(sender == self.pieChartSentAndReceivedMessages) {
        [self showPieChart];
        [self.pieChartViewController showSentAndReceivedMessages];
    }
    
    else if(sender == self.pieChartSentAndReceivedWords) {
        [self showPieChart];
        [self.pieChartViewController showSentAndReceivedWords];
    }
    
    else if(sender == self.pieChartSentAndReceivedTotalMessages) {
        [self showPieChart];
        [self.pieChartViewController showTotalMessages];
    }
    
}



@end
