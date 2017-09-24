//
//  MoreAnalysisViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/14/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "MoreAnalysisViewController.h"

@interface MoreAnalysisViewController ()


# pragma mark - UI Variables

@property (strong) IBOutlet NSView *mainViewForGraph;

@property (strong) IBOutlet NSTableView *messagesTableView;
@property (strong) IBOutlet NSTableView *myWordFrequenciesTableView;
@property (strong) IBOutlet NSTableView *friendsWordFrequenciesTableView;
@property (strong) IBOutlet NSTextField *frequencySearchField;

@property (strong) IBOutlet NSTextField *friendsWordsFrequenciesTextField;
@property (strong) IBOutlet NSDatePicker *mainDatePicker;

@property (strong, nonatomic) NSTextView *sizingView;
@property (strong, nonatomic) NSTextField *sizingField;
@property (strong, nonatomic) NSTextField *noMessagesField;

@property NSRect messageFromMe;
@property NSRect messageToMe;
@property NSRect timeStampRect;

@property (strong, nonatomic) NSDictionary *messageWithAttachmentAttributes;

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDate *calendarChosenDate;
@property (strong, nonnull) NSDate *calendarChosenDateTo;


# pragma mark - View Controllers

@property (strong, nonatomic) NSPopover *viewAttachmentsPopover;
@property (strong, nonatomic) ViewAttachmentsViewController *viewAttachmentsViewController;
@property (strong, nonatomic) GraphViewController *graphViewController;


# pragma mark - Arrays for messages and frequencies

@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) NSMutableArray *messagesToDisplay;

@property (strong, nonatomic) NSMutableArray<NSDictionary*> *myWordsAndFrequencies;
@property (strong, nonatomic) NSMutableArray<NSDictionary*> *myWordsAndFrequenciesSearch;

@property (strong, nonatomic) NSMutableArray<NSDictionary*> *friendWordsAndFrequencies;
@property (strong, nonatomic) NSMutableArray<NSDictionary*> *friendWordsAndFrequenciesSearch;


# pragma mark - Person information

@property (strong, nonatomic) Person *person;
@property (strong, nonatomic) TemporaryDatabaseManager *databaseManager;

@property int myWordCount;
@property int friendCount;

@property int myDoubleMessage;
@property int friendDoubleMessage;

@property int myConversationStarter;
@property int friendConversationStarter;

@property double myAverageWordCountPerMessage;
@property double friendAverageWordCountPerMessage;

@end

@implementation MoreAnalysisViewController


/****************************************************************
 *
 *              Constructor
 *
*****************************************************************/

# pragma mark - Constructor

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil person:(Person *)person messages:(NSMutableArray *)messages databaseManager:(TemporaryDatabaseManager *)databaseManager
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.person = person;
        self.messages = messages;
        self.messagesToDisplay = messages;
        self.databaseManager = databaseManager;

        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MM/dd/yy"];

        if(self.messagesToDisplay.count > 0) {
            self.calendarChosenDate = ((Message*) self.messagesToDisplay[0]).dateSent;
        }
        else {
            self.calendarChosenDate = [[NSDate alloc] init];
        }
        self.calendarChosenDateTo = self.calendarChosenDate;
        
        self.myWordsAndFrequencies = [[NSMutableArray alloc] init];
        self.myWordsAndFrequenciesSearch = [[NSMutableArray alloc] init];
        
        self.friendWordsAndFrequencies = [[NSMutableArray alloc] init];
        self.friendWordsAndFrequenciesSearch = [[NSMutableArray alloc] init];
        
        self.messageWithAttachmentAttributes = [Constants getMessageWithAttachmentAttributes];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.messagesTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    
    NSRect frame = NSMakeRect(0, 0, 400, MAXFLOAT);
    self.sizingView = [[NSTextView alloc] initWithFrame:frame];
    self.sizingField = [[NSTextField alloc] initWithFrame:frame];
    
    self.messageFromMe = NSMakeRect(self.messagesTableView.tableColumns[0].width/2, 0, 400, MAXFLOAT);
    self.messageToMe = NSMakeRect(0, 0, 400, MAXFLOAT);
    
    self.timeStampRect = NSMakeRect(0, 0, 400, MAXFLOAT);
    
    [self.friendsWordsFrequenciesTextField setStringValue:[NSString stringWithFormat:@"%@'s Word Frequencies", self.person.personName]];
    
    if(self.person.statistics) {
        Statistics *stat = self.person.statistics;
        long totalSent = stat.numberOfSentMessages; // + stat.numberOfSentAttachments
        long totalReceived = stat.numberOfReceivedMessages; // + stat.numberOfReceivedAttachments;
        
        [self setTextFieldLong:totalSent forTag:10];
        [self setTextFieldLong:totalReceived forTag:14];
        [self setTextFieldLong:(totalSent + totalReceived) forTag:18];
    }
    
    self.graphViewController = [[GraphViewController alloc] initWithNibName:@"GraphViewController" bundle:[NSBundle mainBundle] person:self.person temporaryDatabase:self.databaseManager firstMessageDate:self.calendarChosenDate graphView:self.mainViewForGraph];
    
    [[self.graphViewController view] setFrame:self.mainViewForGraph.frame];
    [self.view addSubview:self.graphViewController.view positioned:NSWindowAbove relativeTo:self.mainViewForGraph];
    [self.frequencySearchField setDelegate:self];
}


- (void) viewDidAppear
{
    [self dealWithWordFrequencies];
}


/****************************************************************
 *
 *              Word Frequencies
 *
*****************************************************************/

# pragma mark - Word Frequencies

- (void) dealWithWordFrequencies
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
        [self calculateWordFrequenciesAndCounts];
        
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self.friendsWordFrequenciesTableView reloadData];
            [self.myWordFrequenciesTableView reloadData];
            
            //First time it's run
            if(self.messagesToDisplay.count == self.messages.count) {
                
                NSLog(@"HERE NOW");
                [self setTextFieldLong:self.myWordCount forTag:12];
                [self setTextFieldLong:self.friendCount forTag:16];
                [self setTextFieldLong:(self.myWordCount + self.friendCount) forTag:20];
                
                if(self.person.statistics) {
                    Statistics *stat = self.person.statistics;
                    long totalSent = stat.numberOfSentMessages; //+ stat.numberOfSentAttachments;
                    long totalReceived = stat.numberOfReceivedMessages;// + stat.numberOfReceivedAttachments;
                    
                    if(self.myWordCount == 0 || totalSent == 0) {
                        self.myAverageWordCountPerMessage = 0.0;
                    }
                    else {
                        self.myAverageWordCountPerMessage = (double) self.myWordCount / totalSent;
                    }
                    
                    if(self.friendCount == 0 || totalReceived == 0) {
                        self.friendAverageWordCountPerMessage = 0.0;
                    }
                    else {
                        self.friendAverageWordCountPerMessage = (double) self.friendCount / totalReceived;
                    }
                    
                    double average;
                    if(self.myAverageWordCountPerMessage == 0 || self.friendAverageWordCountPerMessage == 0) {
                        average = 0.0;
                    }
                    else {
                        average = (self.myAverageWordCountPerMessage + self.friendAverageWordCountPerMessage) / 2;
                    }
                    
                    [self setTextFieldDouble:self.myAverageWordCountPerMessage forTag:30];
                    [self setTextFieldDouble:self.friendAverageWordCountPerMessage forTag:31];
                    [self setTextFieldDouble:average forTag:32];
                }
            }
            else {
                int daysBetween = [[Constants instance] daysBetweenDates:self.calendarChosenDate endDate:self.calendarChosenDateTo] + 1;
                
                NSString *wordsOnText;
                if(daysBetween == 0) {
                    wordsOnText = [NSString stringWithFormat:@"Words on %@", [self.dateFormatter stringFromDate:self.calendarChosenDate]];
                }
                else {
                    wordsOnText = [NSString stringWithFormat:@"Words over %d days", daysBetween];
                }
                [self setTextFieldText:wordsOnText forTag:2];
                
                [self setTextFieldLong:self.myWordCount forTag:13];
                [self setTextFieldLong:self.friendCount forTag:17];
                [self setTextFieldLong:(self.myWordCount + self.friendCount) forTag:21];
            }
            
            [self.mainDatePicker setDateValue:self.calendarChosenDate];
            
        });
    });
}

- (void) calculateWordFrequenciesAndCounts
{
    self.myWordCount = 0;
    self.friendCount = 0;
    
    self.myDoubleMessage = 0;
    self.friendDoubleMessage = 0;
    
    NSMutableDictionary *myWordFrequencies = [[NSMutableDictionary alloc] init];
    NSMutableDictionary *friendWordFrequencies = [[NSMutableDictionary alloc] init];
    
    BOOL lastFromMeDoubleMessage;
    int lastMessageTimeDoubleMessage;
    Message *lastMessageDoubleMessage;
    
    BOOL lastFromMeConversationStarter;
    int lastMessageTimeConversationStarter;
    Message *lastMessageConversationStarter;
    
    if(self.messagesToDisplay.count > 0) {
        Message *first = [self.messagesToDisplay firstObject];
        
        lastFromMeDoubleMessage = first.isFromMe;
        lastMessageTimeDoubleMessage = (int) [first.dateSent timeIntervalSinceReferenceDate];
        lastMessageDoubleMessage = first;
        
        lastFromMeConversationStarter = first.isFromMe;
        lastFromMeConversationStarter = (int) [first.dateSent timeIntervalSinceReferenceDate];
        lastMessageConversationStarter = first;
    }
    else {
        lastFromMeDoubleMessage = NO;
        lastMessageTimeDoubleMessage = (int)[[NSDate date] timeIntervalSinceReferenceDate];
    
        lastFromMeConversationStarter = NO;
        lastMessageTimeConversationStarter = (int) [[NSDate date] timeIntervalSinceReferenceDate];
    }
    
    for(Message *message in self.messagesToDisplay) {
        
        //Last message isn't from me, but this one is - continuing conversation
        if(message.isFromMe && !lastFromMeDoubleMessage) {
            lastFromMeDoubleMessage = YES;
            lastFromMeConversationStarter = YES;
        }
        
        //Last message is from me, but this one isn't - continuing conversation
        else if(!message.isFromMe && lastFromMeDoubleMessage) {
            lastFromMeDoubleMessage = NO;
            lastFromMeConversationStarter = NO;
        }
        
        //Double message
        else {
            int sentTime = (int)[message.dateSent timeIntervalSinceReferenceDate];
            int timeDiscrepancy = sentTime - lastMessageTimeDoubleMessage;
            
            //If it should count as a double message
            if([Constants isDoubleMessage:timeDiscrepancy]) {
                if(message.isFromMe) {
                    self.myDoubleMessage++;
                }
                else {
                    self.friendDoubleMessage++;
                }
            }
            
            else if([Constants isConversationStarter:timeDiscrepancy]) {
                if(message.isFromMe) {
                    self.myConversationStarter++;
                }
                else {
                    self.friendConversationStarter++;
                }
            }
        }
        
        lastMessageTimeDoubleMessage = (int) [message.dateSent timeIntervalSinceReferenceDate];
        lastMessageDoubleMessage = message;
        
        lastMessageTimeConversationStarter = (int) [message.dateSent timeIntervalSinceReferenceDate];
        lastMessageConversationStarter = message;
        
        NSArray *words = [message.messageText componentsSeparatedByString:@" "];
        
        for(NSString *word in words) {
            NSString *wordToUse = word; //[Constants getStrippedWord:word];
            
            NSNumber *frequency = message.isFromMe ? [myWordFrequencies objectForKey:wordToUse] : [friendWordFrequencies objectForKey:wordToUse];
            
            if(frequency) {
                frequency = [NSNumber numberWithInt:([frequency intValue] + 1)];
            }
            else {
                frequency = [NSNumber numberWithInt:1];
            }
            
            if(word.length == 0) {
                continue;
            }
            
            if(message.isFromMe) {
                [myWordFrequencies setObject:frequency forKey:wordToUse];
                self.myWordCount++;
            }
            else {
                [friendWordFrequencies setObject:frequency forKey:wordToUse];
                self.friendCount++;
            }
        }
    }

    WordFrequencyHeapDataStructure *myWords = [[WordFrequencyHeapDataStructure alloc] initWithSize:myWordFrequencies.count];
    WordFrequencyHeapDataStructure *friendWords = [[WordFrequencyHeapDataStructure alloc] initWithSize:myWordFrequencies.count];
    
    for(NSString *word in myWordFrequencies.allKeys) {
        [myWords addWord:word frequency:[myWordFrequencies objectForKey:word]];
    }
    
    for(NSString *word in friendWordFrequencies.allKeys) {
        [friendWords addWord:word frequency:[friendWordFrequencies objectForKey:word]];
    }
    
    self.myWordsAndFrequencies = [myWords getAllWordsAndFrequencies];
    self.myWordsAndFrequenciesSearch = self.myWordsAndFrequencies;
    
    self.friendWordsAndFrequencies = [friendWords getAllWordsAndFrequencies];
    self.friendWordsAndFrequenciesSearch = self.friendWordsAndFrequencies;
    
    [self setTextFieldLong:self.myDoubleMessage forTag:36];
    [self setTextFieldLong:self.friendDoubleMessage forTag:37];
    [self setTextFieldLong:(self.myDoubleMessage + self.friendDoubleMessage) forTag:38];
    
    [self setTextFieldLong:self.myConversationStarter forTag:39];
    [self setTextFieldLong:self.friendConversationStarter forTag:40];
    [self setTextFieldLong:(self.myDoubleMessage + self.friendDoubleMessage) forTag:41];
}


/****************************************************************
 *
 *              NSTableView Delegate
 *
*****************************************************************/

# pragma mark - NSTableView Delegate

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
        
        NSTextField_Messages *messageField = [[NSTextField_Messages alloc] initWithFrame:frame];
        
        RSVerticallyCenteredTextFieldCell *verticleCenterCell = [[RSVerticallyCenteredTextFieldCell alloc] initTextCell:@""];
        [messageField setCell:verticleCenterCell];

        [messageField setDrawsBackground:YES];
        [messageField setWantsLayer:YES];
        [messageField setTextFieldNumber:(int)row];
        [messageField setTag:100];
        [messageField setDelegate:self];
        
        if(message.attachments) {
            
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:message.messageText];
            
            if(message.isFromMe) {
                [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, message.messageText.length)];
            }
            else {
                [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, message.messageText.length)];
            }
            
            if(message.attachments) {
                
                [messageField setAllowsEditingTextAttributes:YES];
                [messageField setSelectable:YES];
                
                NSMutableString *attachmentsValue = [[NSMutableString alloc] init];
                
                if(message.messageText.length == 0) {
                    [attachmentsValue appendString:@"  "];
                }
                
                for(int i = 0; i < message.attachments.count; i++) {
                    [attachmentsValue appendString:[NSString stringWithFormat:@"Attachment %d.", i]];
                }
                
                NSMutableAttributedString* attachmentsString = [[NSMutableAttributedString alloc] initWithString:(NSString*)attachmentsValue
                                                                                                      attributes:self.messageWithAttachmentAttributes];
                [attributedString appendAttributedString:attachmentsString];
            }
            
            [messageField setAttributedStringValue:attributedString];
        }
        else {
            NSFont *customFont = [NSFont fontWithName:@"Helvetica Neue" size:13.0];
            NSMutableAttributedString *customString;
            if(message.messageText.length < 55) {
                customString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", message.messageText]];
            }
            else {
                customString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@", message.messageText]];
            }
            [customString addAttribute:NSFontNameAttribute value:customFont range:NSMakeRange(0, customString.length)];
            [messageField setAttributedStringValue:customString];
        }

        NSSize goodFrame = [messageField.cell cellSizeForBounds:frame];
        [messageField setFrameSize:CGSizeMake(goodFrame.width + 10, goodFrame.height + 4)];
        
        goodFrame = [timeField.cell cellSizeForBounds:self.timeStampRect];
        [timeField setFrameSize:CGSizeMake(goodFrame.width + 2, goodFrame.height)];
        
        if(message.isFromMe) {
            [messageField setFrameOrigin:CGPointMake(tableColumn.width - messageField.frame.size.width, 15)];
            
            if(message.isIMessage) {
                [messageField setBackgroundColor:[NSColor colorWithRed:0.0 green:122.0/255.0 blue:1.0 alpha:1.0]];
                //[messageField setBackgroundColor:[NSColor blueColor]];
            }
            else {
                [messageField setBackgroundColor:[NSColor colorWithRed:90.0/255.0 green:212/255.0 blue:39.0/255.0 alpha:1.0]];
                //[messageField setBackgroundColor:[NSColor greenColor]];

            }
            [messageField setTextColor:[NSColor whiteColor]];
            
            [timeField setFrameOrigin:CGPointMake(tableColumn.width - timeField.frame.size.width, 0)];
        }
        else {
            [messageField setFrameOrigin:CGPointMake(0, 15)];
            [messageField setBackgroundColor:[NSColor colorWithRed:199.0/255.0 green:199.0/255.0 blue:204/255.0 alpha:1.0]];
            //[messageField setBackgroundColor:[NSColor lightGrayColor]];
            [messageField setTextColor:[NSColor blackColor]];
            [timeField setFrameOrigin:CGPointMake(2, 0)];
        }
    
        [messageField setWantsLayer:YES];
        [messageField.layer setCornerRadius:8.0f];
        [messageField setFocusRingType:NSFocusRingTypeNone];
        [messageField setBordered:NO];
        
        [encompassingView addSubview:messageField];
        [encompassingView addSubview:timeField];
        
        return encompassingView;
    }
    
    NSTextField *textField = [[NSTextField alloc] init];
    
    [textField setFocusRingType:NSFocusRingTypeNone];
    //[textField setBordered:NO];

    if(tableView == self.myWordFrequenciesTableView) {
        return textField;
    }
    
    if(tableView == self.friendsWordFrequenciesTableView) {
        return textField;
    }
    
    return textField;
}

- (NSCell*) tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        return nil;
    }
    
    if(tableView == self.myWordFrequenciesTableView) {
        return nil;
    }
    
    if(tableView == self.friendsWordFrequenciesTableView) {
        return nil;
    }
    
    return [[NSCell alloc] initTextCell:@"Something..."];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        return nil;
    }
    
    if(tableView == self.myWordFrequenciesTableView) {
        if([tableColumn.identifier isEqualToString:@"Occurrence"]) {
            return [self.myWordsAndFrequenciesSearch[row] objectForKey:@"frequency"];
        }
        else if([tableColumn.identifier isEqualToString:@"Word"]) {
            return [self.myWordsAndFrequenciesSearch[row] objectForKey:@"word"];
        }
    }
    
    if(tableView == self.friendsWordFrequenciesTableView) {
        if([tableColumn.identifier isEqualToString:@"Occurrence"]) {
            return [self.friendWordsAndFrequenciesSearch[row] objectForKey:@"frequency"];
        }
        else if([tableColumn.identifier isEqualToString:@"Word"]) {
            return [self.friendWordsAndFrequenciesSearch[row] objectForKey:@"word"];
        }
    }
    return @"PROBLEM";
}

- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        if(!self.messagesToDisplay || self.messagesToDisplay.count == 0) {
            return 80.0;
        }

        Message *message = self.messagesToDisplay[row];
        NSString *text = message.messageText;
        
        if(message.attachments) {
            for(int i = 0; i < message.attachments.count; i++) {
                text = [text stringByAppendingString:@"ATTACHMENT"];
            }
        }
        
        [self.sizingField setStringValue:text];
        return [self.sizingField.cell cellSizeForBounds:self.sizingField.frame].height + 30;
        
        /*[self.sizingView setString:text];
         [self.sizingView sizeToFit];
         return self.sizingView.frame.size.height; */
    }
    
    if(tableView == self.myWordFrequenciesTableView) {
        return 20.0;
    }
    
    if(tableView == self.friendsWordFrequenciesTableView) {
        return 20.0;
    }
    
    return 80.0;
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView == self.messagesTableView) {
        return self.messagesToDisplay.count;
    }
    
    if(tableView == self.myWordFrequenciesTableView && self.myWordsAndFrequenciesSearch) {
        return self.myWordsAndFrequenciesSearch.count;
    }
    
    if(tableView == self.friendsWordFrequenciesTableView && self.friendWordsAndFrequenciesSearch) {
        return self.friendWordsAndFrequenciesSearch.count;
    }
    
    return 0;
}

- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        if(((Message*)self.messagesToDisplay[row]).attachments) {
            return YES;
        }
    }
    
    return NO;
}

- (BOOL) tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    return NO;
}

- (BOOL) tableView:(NSTableView *)tableView writeRowsWithIndexes:(NSIndexSet *)rowIndexes toPasteboard:(NSPasteboard *)pboard
{
    return NO;
}

- (NSMutableArray*) getMessagesBetweenDateRange:(NSDate*)startDate endDate:(NSDate*)endDate
{
    NSMutableArray *messages = [[NSMutableArray alloc] init];
    
    self.person.secondaryStatistics = [[Statistics alloc] init];
    
    for(Message *message in self.messages) {
        NSComparisonResult compareStart = [startDate compare:message.dateSent];
        
        //message.dateSent came before
        if(compareStart == NSOrderedDescending) {
            continue;
        }
        
        NSComparisonResult compareEnd = [endDate compare:message.dateSent];
        if(compareEnd == NSOrderedAscending) {
            return messages;
        }
        
        NSArray *words = [message.messageText componentsSeparatedByString:@" "];
        
        if(message.isFromMe) {
            self.person.secondaryStatistics.numberOfSentMessages++;
            self.person.secondaryStatistics.numberOfSentWords += words.count;
            
            if(message.hasAttachment) {
                self.person.secondaryStatistics.numberOfSentAttachments++;
            }
        }
        else {
            self.person.secondaryStatistics.numberOfReceivedMessages++;
            self.person.secondaryStatistics.numberOfReceivedWords += words.count;
            
            if(message.hasAttachment) {
                self.person.secondaryStatistics.numberOfReceivedAttachments++;
            }
        }
        
        [messages addObject:message];
    }
    
    return messages;
}

/****************************************************************
 *
 *              DatePickerCell Delegate
 *
 *****************************************************************/

int tempCounter = 2;

# pragma mark - DatePickerCell Delegate

- (void) datePickerCell:(NSDatePickerCell *)aDatePickerCell validateProposedDateValue:(NSDate *__autoreleasing  _Nonnull *)proposedDateValue timeInterval:(NSTimeInterval *)proposedTimeInterval
{
    NSDate *startDay = *proposedDateValue;
    NSDate *endDay = [startDay dateByAddingTimeInterval:*proposedTimeInterval];

    //If the date chosen is the same day (not a range) and it's already displayed, don't do anything
    if(self.calendarChosenDate == startDay) {
        return;
    }

    startDay = [[Constants instance] dateAtBeginningOfDay:startDay];
    endDay = [[Constants instance] dateAtEndOfDay:endDay];
   
    self.calendarChosenDate = startDay;
    self.calendarChosenDateTo = endDay;
    self.messagesToDisplay = [self getMessagesBetweenDateRange:self.calendarChosenDate endDate:self.calendarChosenDateTo];
    
    NSLog(@"ANALYZING: %@\t%@", [self.dateFormatter stringFromDate:startDay], [self.dateFormatter stringFromDate:endDay]);
    
    [self dealWithWordFrequencies];
    [self.messagesTableView reloadData];
    
    NSString *messagesOn;
    int daysBetween = [[Constants instance] daysBetweenDates:startDay endDate:endDay] + 1;
    if(daysBetween == 0) {
        messagesOn = [NSString stringWithFormat:@"Messages on %@", [self.dateFormatter stringFromDate:self.calendarChosenDate]];
    }
    else {
        messagesOn = [NSString stringWithFormat:@"Messages over %d days", daysBetween];
    }
    [self setTextFieldText:messagesOn forTag:1];
    tempCounter++;
    
    if(self.messagesToDisplay.count == 0 || !self.person.secondaryStatistics) {
        [self setTextFieldLong:0 forTag:11];
        [self setTextFieldLong:0 forTag:15];
        [self setTextFieldLong:0 forTag:19];
        
        [self setTextFieldLong:0 forTag:33];
        [self setTextFieldLong:0 forTag:34];
        [self setTextFieldLong:0 forTag:35];
    }
    
    else if(self.person.secondaryStatistics) {
        
        //HERE
        Statistics *stat = self.person.secondaryStatistics;
        long totalSent = stat.numberOfSentMessages; //+ stat.numberOfSentAttachments;
        long totalReceived = stat.numberOfReceivedMessages;// + stat.numberOfReceivedAttachments;
        
        [self setTextFieldLong:totalSent forTag:11];
        [self setTextFieldLong:totalReceived forTag:15];
        [self setTextFieldLong:(totalSent + totalReceived) forTag:19];
        
        if(stat.numberOfSentWords == 0 || stat.numberOfSentMessages == 0) {
            self.myAverageWordCountPerMessage = 0.0;
        }
        else {
            self.myAverageWordCountPerMessage = (double) stat.numberOfSentWords / stat.numberOfSentMessages;
        }
        
        if(stat.numberOfReceivedWords == 0 || stat.numberOfReceivedMessages == 0) {
            self.friendAverageWordCountPerMessage = 0.0;
        }
        else {
            self.friendAverageWordCountPerMessage = (double) stat.numberOfReceivedWords / stat.numberOfReceivedMessages;
        }
        
        double average;
        if(self.myAverageWordCountPerMessage == 0 || self.friendAverageWordCountPerMessage == 0) {
            average = 0.0;
        }
        else {
            average = (self.myAverageWordCountPerMessage + self.friendAverageWordCountPerMessage) / 2;
        }
        
        [self setTextFieldDouble:self.myAverageWordCountPerMessage forTag:33];
        [self setTextFieldDouble:self.friendAverageWordCountPerMessage forTag:34];
        [self setTextFieldDouble:average forTag:35];
    }
}


/****************************************************************
 *
 *              NSTextField Delegate
 *
*****************************************************************/

# pragma mark - NSTextField

- (void) controlTextDidChange:(NSNotification *)obj
{
    NSString *searchValue = self.frequencySearchField.stringValue; //[Constants getStrippedWord:self.frequencySearchField.stringValue];
    
    if(searchValue == nil || searchValue.length == 0) {
        self.myWordsAndFrequenciesSearch = self.myWordsAndFrequencies;
        self.friendWordsAndFrequenciesSearch = self.friendWordsAndFrequencies;
    }
    else {
        NSMutableArray<NSDictionary*> *mySearchResults = [[NSMutableArray alloc] init];
        NSMutableArray<NSDictionary*> *friendSearchResults = [[NSMutableArray alloc] init];
        
        for(NSDictionary *wordFrequency in self.myWordsAndFrequencies) {
            NSString *word = wordFrequency[@"word"];
            if([word rangeOfString:searchValue options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [mySearchResults addObject:wordFrequency];
            }
        }
        
        for(NSDictionary *wordFrequency in self.friendWordsAndFrequencies) {
            NSString *word = wordFrequency[@"word"];
            if([word rangeOfString:searchValue options:NSCaseInsensitiveSearch].location != NSNotFound) {
                [friendSearchResults addObject:wordFrequency];
            }
        }
        self.myWordsAndFrequenciesSearch = mySearchResults;
        self.friendWordsAndFrequenciesSearch = friendSearchResults;
    }
    
    [self.myWordFrequenciesTableView reloadData];
    [self.friendsWordFrequenciesTableView reloadData];
}


/****************************************************************
 *
 *              TextField Delegate
 *
 *****************************************************************/

# pragma mark - TextField Delegate

- (void) clickedOnTextField:(int32_t)textFieldNumber
{
    NSMutableArray *attachments = ((Message*)self.messagesToDisplay[textFieldNumber]).attachments;
    
    if(!attachments || attachments.count == 0) {
        return;
    }
    
    NSTextField_Messages *textField = [((NSView*)[self.messagesTableView viewAtColumn:0 row:textFieldNumber makeIfNecessary:YES]) viewWithTag:100];
    self.viewAttachmentsViewController = [[ViewAttachmentsViewController alloc] initWithNibName:@"ViewAttachmentsViewController" bundle:[NSBundle mainBundle] attachments:attachments];
    
    self.viewAttachmentsPopover = [[NSPopover alloc] init];
    [self.viewAttachmentsPopover setContentSize:self.viewAttachmentsViewController.view.bounds.size];
    [self.viewAttachmentsPopover setContentViewController:self.viewAttachmentsViewController];
    [self.viewAttachmentsPopover setAnimates:YES];
    [self.viewAttachmentsPopover setBehavior:NSPopoverBehaviorTransient];
    [self.viewAttachmentsPopover showRelativeToRect:[textField bounds] ofView:textField preferredEdge:NSRectEdgeMaxX];
    self.viewAttachmentsPopover.delegate = self;
}


/****************************************************************
 *
 *              NSPopOver Delegate
 *
 *****************************************************************/

# pragma mark - NSPopOver Delegate

- (void) popoverDidClose:(NSNotification *)notification
{
    self.viewAttachmentsViewController = nil;
    self.viewAttachmentsPopover = nil;
}


/****************************************************************
 *
 *              Auxillary Methods
 *
*****************************************************************/

# pragma mark - Auxillary Methods

- (IBAction)clearCalendarButton:(id)sender {
    self.messagesToDisplay = self.messages;
    
    [self dealWithWordFrequencies];
    [self.messagesTableView reloadData];
}

- (void) setTextFieldDouble:(double)value forTag:(NSInteger)tag
{
    NSString *text = [NSNumberFormatter localizedStringFromNumber:@(value) numberStyle:NSNumberFormatterDecimalStyle];
    [self setTextFieldText:text forTag:tag];
    //[self setTextFieldText:[NSString stringWithFormat:@"%.2lf", value] forTag:tag];
}

- (void) setTextFieldLong:(long)value forTag:(NSInteger)tag
{
    NSString *text = [NSNumberFormatter localizedStringFromNumber:@(value) numberStyle:NSNumberFormatterDecimalStyle];
    [self setTextFieldText:text forTag:tag];
    //[self setTextFieldText:[NSString stringWithFormat:@"%ld", value] forTag:tag];
}

- (void) setTextFieldText:(NSString*)text forTag:(NSInteger)tag
{
    dispatch_async(dispatch_get_main_queue(), ^(void) {
        NSTextField *field = [self.view viewWithTag:tag];
        if(field) {
            [field setStringValue:text];
        }
        else {
            NSLog(@"Error getting view for: %ld", tag);
        }
    });
}

@end
