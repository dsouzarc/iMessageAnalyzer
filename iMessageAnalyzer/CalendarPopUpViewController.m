//
//  CalendarPopUpViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/2/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "CalendarPopUpViewController.h"

@interface CalendarPopUpViewController ()

@property (strong) IBOutlet NSDatePicker *datePicker;
@property (strong) IBOutlet NSButton *resetToAllButton;

@end

@implementation CalendarPopUpViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.datePicker setDateValue:[NSDate date]];
    
}
- (IBAction)resetToAllButtonClick:(id)sender {
    [self.delegate dateChosen:nil];
}

- (void) datePickerCell:(NSDatePickerCell *)aDatePickerCell validateProposedDateValue:(NSDate *__autoreleasing  _Nonnull *)proposedDateValue timeInterval:(NSTimeInterval *)proposedTimeInterval
{
    [self.delegate dateChosen:*proposedDateValue];
}

@end