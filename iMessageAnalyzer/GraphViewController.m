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

@property (strong) IBOutlet NSButton *lineGraphAllTimeButton;
@property (strong) IBOutlet NSButton *lineGraphCourseOfDayButton;
@property (strong) IBOutlet NSButton *lineGraphMessagesButton;
@property (strong) IBOutlet NSButton *lineGraphWordsButton;
@property (strong) IBOutlet NSButton *lineGraphDayViewButton;
@property (strong) IBOutlet NSButton *lineGraphCompareToOthersButton;


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
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [[self.dropPlotViewController view] setFrame:self.view.frame];
    [self.view addSubview:self.dropPlotViewController.view];
    //[self.view addSubview:self.dropPlotViewController.view positioned:NSWindowAbove relativeTo:self.view];
}

- (IBAction)buttonClick:(id)sender {
    if(sender == self.lineGraphAllTimeButton) {
        [self.lineGraphDayViewButton setEnabled:NO];
    }
    else if(sender == self.lineGraphCourseOfDayButton) {
        [self.lineGraphDayViewButton setEnabled:NO];
    }
    else if(sender == self.lineGraphMessagesButton) {
        [self.lineGraphDayViewButton setEnabled:YES];
    }
    else if(sender == self.lineGraphWordsButton) {
        [self.lineGraphDayViewButton setEnabled:YES];
    }
    else if(sender == self.lineGraphDayViewButton) {
        
    }
    else if(sender == self.lineGraphCompareToOthersButton) {
        
    }
}



@end
