//
//  MoreAnalysisViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/14/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "MoreAnalysisViewController.h"

@interface MoreAnalysisViewController ()

@property (strong, nonatomic) Person *person;

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableArray *messagesToDisplay;

@property (strong) IBOutlet NSTableView *messagesTableView;

@property (strong) IBOutlet NSTableView *myWordFrequenciesTableView;
@property (strong) IBOutlet NSTableView *friendsWordFrequenciesTableView;

@property (strong, nonatomic) NSTextView *sizingView;
@property (strong, nonatomic) NSTextField *sizingField;

@property NSRect messageFromMe;
@property NSRect messageToMe;
@property NSRect timeStampRect;

@property (strong, nonatomic) NSTextField *noMessagesField;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (strong, nonatomic) MessageManager *messageManager;

@property (strong, nonatomic) NSDate *calendarChosenDate;

@property (strong, nonatomic) NSMutableDictionary *myWordFrequencies;
@property (strong, nonatomic) NSMutableDictionary *friendWordFrequencies;

@property int myWordCount;
@property int friendCount;

@end

@implementation MoreAnalysisViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person *)person messages:(NSMutableArray *)messages
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.person = person;
        self.messages = messages;
        
        self.messagesToDisplay = messages;
        
        self.messageManager = [MessageManager getInstance];
        
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MM/dd/yyyy"];
        
        self.myWordFrequencies = [[NSMutableDictionary alloc] init];
        self.friendWordFrequencies = [[NSMutableDictionary alloc] init];
        
        if(self.messagesToDisplay.count > 0) {
            self.calendarChosenDate = [[NSDate alloc] initWithTimeIntervalSinceReferenceDate:(long)((Message*) self.messagesToDisplay[0]).dateSent];
        }
        else {
            self.calendarChosenDate = [[NSDate alloc] init];
        }
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
    
    NSRect frame = NSMakeRect(0, 0, 400, MAXFLOAT);
    self.sizingView = [[NSTextView alloc] initWithFrame:frame];
    self.sizingField = [[NSTextField alloc] initWithFrame:frame];
    
    self.messageFromMe = NSMakeRect(self.messagesTableView.tableColumns[0].width/2, 0, 400, MAXFLOAT);
    self.messageToMe = NSMakeRect(0, 0, 400, MAXFLOAT);
    
    self.timeStampRect = NSMakeRect(0, 0, 400, MAXFLOAT);

}

- (void) viewDidAppear
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self calculateWordFrequenciesAndCounts];
    });
}

- (void) calculateWordFrequenciesAndCounts
{
    self.myWordCount = 0;
    self.friendCount = 0;
    
    for(Message *message in self.messagesToDisplay) {
        NSArray *words = [message.messageText componentsSeparatedByString:@" "];
        
        for(NSString *word in words) {
            
            NSNumber *frequency = message.isFromMe ? [self.myWordFrequencies objectForKey:word] : [self.friendWordFrequencies objectForKey:word];
            
            if(frequency) {
                frequency = [NSNumber numberWithInt:([frequency intValue] + 1)];
            }
            else {
                frequency = [NSNumber numberWithInt:1];
            }
            
            if(message.isFromMe) {
                [self.myWordFrequencies setObject:frequency forKey:word];
                self.myWordCount++;
            }
            else {
                [self.friendWordFrequencies setObject:frequency forKey:word];
                self.friendCount++;
            }
        }
    }
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView == self.messagesTableView) {
        return self.messagesToDisplay.count;
    }
    
    return 0;
}

- (NSView*) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        
        if(row > self.messagesToDisplay.count || self.messagesToDisplay.count == 0) {
            self.noMessagesField = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, self.messagesTableView.bounds.size.width, self.messagesTableView.bounds.size.height)];
            
            NSString *text;
            
            if(!self.person) {
                text = @"No messages or conversations";
            }
            else {
                text = [NSString stringWithFormat:@"No messages with %@ (%@)", self.person.personName, self.person.number];
                
                if(self.calendarChosenDate) {
                    text = [NSString stringWithFormat:@"%@ on %@", text, [self.dateFormatter stringFromDate:self.calendarChosenDate]];
                }
            }
            [self.noMessagesField setStringValue:text];
            [self.noMessagesField setAlignment:NSTextAlignmentCenter];
            [self.noMessagesField setFocusRingType:NSFocusRingTypeNone];
            [self.noMessagesField setBordered:NO];
            
            [self.messagesTableView addSubview:self.noMessagesField];
            
            return self.noMessagesField;
        }
        
        Message *message = self.messagesToDisplay[row];
        NSView *encompassingView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        NSRect frame = message.isFromMe ? self.messageFromMe : self.messageToMe;
        
        NSTextField *timeField = [[NSTextField alloc] initWithFrame:self.timeStampRect];
        [timeField setStringValue:[message getTimeStampAsString]];
        [timeField setFocusRingType:NSFocusRingTypeNone];
        [timeField setBordered:NO];
        
        NSTextField *messageField = [[NSTextField alloc] initWithFrame:frame];
        [messageField setStringValue:[NSString stringWithFormat:@"  %@", message.messageText]];
        
        [messageField setDrawsBackground:YES];
        [messageField setWantsLayer:YES];
        
        NSSize goodFrame = [messageField.cell cellSizeForBounds:frame];
        [messageField setFrameSize:CGSizeMake(goodFrame.width + 10, goodFrame.height + 4)];
        
        goodFrame = [timeField.cell cellSizeForBounds:self.timeStampRect];
        [timeField setFrameSize:CGSizeMake(goodFrame.width + 2, goodFrame.height)];
        
        if(message.isFromMe) {
            [messageField setFrameOrigin:CGPointMake(tableColumn.width - messageField.frame.size.width, 15)];
            
            if(message.isIMessage) {
                [messageField setBackgroundColor:[NSColor blueColor]];
            }
            else {
                [messageField setBackgroundColor:[NSColor greenColor]];
            }
            [messageField setTextColor:[NSColor whiteColor]];
            
            [timeField setFrameOrigin:CGPointMake(tableColumn.width - timeField.frame.size.width, 0)];
        }
        else {
            [messageField setFrameOrigin:CGPointMake(0, 15)];
            [messageField setBackgroundColor:[NSColor lightGrayColor]];
            [messageField setTextColor:[NSColor blackColor]];
            [timeField setFrameOrigin:CGPointMake(2, 0)];
        }
    
        [messageField setWantsLayer:YES];
        [messageField.layer setCornerRadius:14.0f];
        [messageField setFocusRingType:NSFocusRingTypeNone];
        [messageField setBordered:NO];
        
        [encompassingView addSubview:messageField];
        [encompassingView addSubview:timeField];
        
        return encompassingView;
    }
    
    return [[NSView alloc] init];
}


- (NSCell*) tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        return nil;
    }
    
    return [[NSCell alloc] initTextCell:@"Something..."];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        return nil;
    }
    
    return @"PROBLEM";
}

- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        if(!self.messagesToDisplay || self.messagesToDisplay.count == 0) {
            return 80.0;
        }
        
        NSString *text = ((Message*) self.messagesToDisplay[row]).messageText;
        [self.sizingField setStringValue:text];
        return [self.sizingField.cell cellSizeForBounds:self.sizingField.frame].height + 30;
        
        /*[self.sizingView setString:text];
         [self.sizingView sizeToFit];
         return self.sizingView.frame.size.height; */
    }
    
    return 80.0;
}

@end
