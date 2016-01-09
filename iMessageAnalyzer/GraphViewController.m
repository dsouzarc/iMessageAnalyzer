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
@property (strong, nonatomic) BarPlotViewController *barPlotViewController;

@property (strong) IBOutlet NSButton *lineGraphAllTimeButton;
@property (strong) IBOutlet NSButton *lineGraphMessagesButton;
@property (strong) IBOutlet NSButton *lineGraphWordsButton;
@property (strong) IBOutlet NSButton *lineGraphCompareToOthersButton;

@property (strong) IBOutlet NSButton *pieChartSentAndReceivedMessages;
@property (strong) IBOutlet NSButton *pieChartSentAndReceivedWords;
@property (strong) IBOutlet NSButton *pieChartSentAndReceivedTotalMessages;

@property (strong) IBOutlet NSButton *barChartSentAndReceivedMessages;
@property (strong) IBOutlet NSButton *barChartSentAndReceivedWords;
@property (strong) IBOutlet NSButton *barChartTotalMessages;
@property (strong) IBOutlet NSButton *barChartTotalMessagesAsPercent;

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
        
        self.barPlotViewController = [[BarPlotViewController alloc] initWithNibName:@"BarPlotViewController" bundle:[NSBundle mainBundle] person:self.person temporaryDatabase:self.database];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self.dropPlotViewController view] setFrame:self.view.frame];
    [[self.pieChartViewController view] setFrame:self.view.frame];
    [[self.barPlotViewController view] setFrame:self.view.frame];
    
    [self.view addSubview:self.dropPlotViewController.view];
    [self.view addSubview:self.pieChartViewController.view];
    [self.view addSubview:self.barPlotViewController.view];
    
    [self showDropPlot];
}

- (void) showPieChart
{
    [self.pieChartViewController.view setHidden:NO];
    [self.dropPlotViewController.view setHidden:YES];
    [self.barPlotViewController.view setHidden:YES];
}

- (void) showDropPlot
{
    [self.dropPlotViewController.view setHidden:NO];
    [self.pieChartViewController.view setHidden:YES];
    [self.barPlotViewController.view setHidden:YES];
}

- (void) showBarPlot
{
    [self.barPlotViewController.view setHidden:NO];
    [self.dropPlotViewController.view setHidden:YES];
    [self.pieChartViewController.view setHidden:YES];
}

- (void) disableAllCheckMarks
{
    [self.lineGraphCompareToOthersButton setEnabled:NO];
}

- (IBAction)buttonClick:(id)sender {
    
    [self disableAllCheckMarks];
    
    //Multiples of 7 have to do with bar graphs
    if([sender tag] % 7 == 0) {
        [self showBarPlot];
        [self.lineGraphCompareToOthersButton setState:NSOffState];
        
        if(sender == self.barChartSentAndReceivedMessages) {
            [self.barPlotViewController showSentAndReceivedMessages];
        }
        
        else if(sender == self.barChartSentAndReceivedWords) {
            [self.barPlotViewController showSentAndReceivedWords];
        }
        
        else if(sender == self.barChartTotalMessages) {
            [self.barPlotViewController showTotalMessages];
        }
        
        else if(sender == self.barChartTotalMessagesAsPercent) {
            [self.barPlotViewController showTotalMessagesAsPercentage];
        }
    }
    
    //Multiples of 5 have to do with pie charts
    else if([sender tag] % 5 == 0) {
        
        [self showPieChart];
        [self.lineGraphCompareToOthersButton setState:NSOffState];
        
        if(sender == self.pieChartSentAndReceivedMessages) {
            [self.pieChartViewController showSentAndReceivedMessages];
        }
        
        else if(sender == self.pieChartSentAndReceivedWords) {
            [self.pieChartViewController showSentAndReceivedWords];
        }
        
        else if(sender == self.pieChartSentAndReceivedTotalMessages) {
            [self.pieChartViewController showTotalMessages];
        }
    }
    
    //Multiples of 3 have to do with pie charts
    else if([sender tag] % 3 == 0) {
        
        [self showDropPlot];

        if(sender == self.lineGraphAllTimeButton) {
            [self.dropPlotViewController showThisConversationMessagesOverYear];
            [self.lineGraphCompareToOthersButton setEnabled:YES];
        }
        
        else if(sender == self.lineGraphMessagesButton) {
            [self.dropPlotViewController showThisConversationSentAndReceivedMessages];
            [self.lineGraphCompareToOthersButton setState:NSOffState];
        }
        
        else if(sender == self.lineGraphWordsButton) {
            [self.dropPlotViewController showThisConversationSentAndReceivedWords];
            [self.lineGraphCompareToOthersButton setState:NSOffState];
        }
        
        else if(sender == self.lineGraphCompareToOthersButton) {
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
    }
}

@end