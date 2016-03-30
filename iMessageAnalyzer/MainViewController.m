//
//  MainViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/27/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "MainViewController.h"

static NSString *orderByRecent = @"Recent";
static NSString *orderByMostMessages = @"Most messages";

@interface MainViewController ()


#pragma mark UI Elements

@property (strong) IBOutlet NSTableView *contactsTableView;
@property (strong) IBOutlet NSTableView *messagesTableView;

@property (strong) IBOutlet NSTextField *contactNameTextField;
@property (strong) IBOutlet NSSearchField *searchField;
@property (strong) IBOutlet NSButton *calendarButton;
@property (strong) IBOutlet NSPopUpButton *orderByPopUpButton;

@property (strong, nonatomic) NSTextView *sizingView;
@property (strong, nonatomic) NSTextField *sizingField;
@property (strong, nonatomic) NSTextField *noMessagesField;

@property NSRect messageFromMe;
@property NSRect messageToMe;
@property NSRect timeStampRect;


#pragma mark View Controllers and Popovers

@property (strong, nonatomic) NSPopover *calendarPopover;
@property (strong, nonatomic) CalendarPopUpViewController *calendarPopUpViewController;

@property (strong, nonatomic) NSPopover *viewAttachmentsPopover;
@property (strong, nonatomic) ViewAttachmentsViewController *viewAttachmentsViewController;

@property (strong, nonatomic) NSPopover *simpleAnalyticsPopOver;
@property (strong, nonatomic) SimpleAnalyticsPopUpViewController *simpleAnalyticsViewController;

@property (strong, nonatomic) MoreAnalysisWindowController *moreAnalysisWindowController;


#pragma mark Date formatters

@property (strong, nonatomic) NSDateFormatter *dateFormatter;
@property (strong, nonatomic) NSDate *calendarChosenDate;


#pragma mark Chat and conversation variables

@property (strong, nonatomic) NSMutableArray *chats;
@property (strong, nonatomic) NSMutableArray *searchConversationChats;
@property (strong, nonatomic) NSMutableArray *currentConversationChats;


#pragma mark Managers and last chosen person

@property (strong, nonatomic) MessageManager *messageManager;
@property (strong, nonatomic) NSDictionary *messageWithAttachmentAttributes;

@property (strong, nonatomic) Person *lastChosenPerson;
@property (nonatomic) NSInteger lastChosenPersonIndex;
@property int lastSearchIndex;

@end

@implementation MainViewController


/****************************************************************
 *
 *              Constructor
 *
*****************************************************************/

# pragma mark Constructor

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil databasePath:(NSString *)databasePath
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.messageManager = [MessageManager getInstanceForDatabase:databasePath];
        
        self.chats = [self.messageManager getAllChats];
        self.searchConversationChats = [[NSMutableArray alloc] initWithArray:self.chats];
        
        self.currentConversationChats = [[NSMutableArray alloc] init];
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MM/dd/yyyy"];
        
        self.messageWithAttachmentAttributes = [NSDictionary dictionaryWithObjectsAndKeys:[NSColor yellowColor], NSForegroundColorAttributeName,
                                                [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName, nil];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSRect frame = NSMakeRect(0, 0, 400, MAXFLOAT);
    self.sizingView = [[NSTextView alloc] initWithFrame:frame];
    self.sizingField = [[NSTextField alloc] initWithFrame:frame];
    
    self.messageFromMe = NSMakeRect(self.messagesTableView.tableColumns[0].width/2, 0, 400, MAXFLOAT);
    self.messageToMe = NSMakeRect(0, 0, 400, MAXFLOAT);
    
    self.timeStampRect = NSMakeRect(0, 0, 400, MAXFLOAT);
    
    NSNib *cellNib = [[NSNib alloc] initWithNibNamed:@"ChatTableViewCell" bundle:[NSBundle mainBundle]];
    [self.contactsTableView registerNib:cellNib forIdentifier:@"chatTableViewCell"];
    
    NSNib *cellNib2 = [[NSNib alloc] initWithNibNamed:@"TextTableCellView" bundle:[NSBundle mainBundle]];
    [self.messagesTableView registerNib:cellNib2 forIdentifier:@"textTableCellView"];
    
    if(self.searchConversationChats.count > 0) {
        self.lastChosenPerson = self.searchConversationChats[0];
        self.currentConversationChats = [self.messageManager getAllMessagesForPerson:self.lastChosenPerson];
        [self.messagesTableView reloadData];
        [self.contactNameTextField setStringValue:[NSString stringWithFormat:@"%@ %@", self.lastChosenPerson.personName, self.lastChosenPerson.number]];
    }
    
    [self.messagesTableView setSelectionHighlightStyle:NSTableViewSelectionHighlightStyleNone];
    [self.contactsTableView setDoubleAction:@selector(doubleClickedContactCell:)];
    
    //TODO: UNHIDE AND IMPLEMENT
    [self.orderByPopUpButton setHidden:NO];
    [self.orderByPopUpButton removeAllItems];
    [self.orderByPopUpButton addItemWithTitle:orderByRecent];
    [self.orderByPopUpButton addItemWithTitle:orderByMostMessages];
}


/****************************************************************
 *
 *              Click handlers
 *
*****************************************************************/

# pragma mark Click handlers

- (void) doubleClickedContactCell:(id)object
{
    if(!self.simpleAnalyticsPopOver || !self.simpleAnalyticsViewController) {
        self.simpleAnalyticsViewController = [[SimpleAnalyticsPopUpViewController alloc] initWithNibName:@"SimpleAnalyticsPopUpViewController" bundle:[NSBundle mainBundle]];
        self.simpleAnalyticsViewController.delegate = self;
        
        self.simpleAnalyticsPopOver = [[NSPopover alloc] init];
        [self.simpleAnalyticsPopOver setContentSize:self.simpleAnalyticsViewController.view.bounds.size];
        [self.simpleAnalyticsPopOver setContentViewController:self.simpleAnalyticsViewController];
        [self.simpleAnalyticsPopOver setAnimates:YES];
        [self.simpleAnalyticsPopOver setDelegate:self];
        [self.simpleAnalyticsPopOver setBehavior:NSPopoverBehaviorTransient];
    }
    
    Statistics *statistics = self.lastChosenPerson.statistics;
    
    if(statistics) {
        int totalSent = (int) statistics.numberOfSentMessages; // + statistics.numberOfSentAttachments;
        int totalReceived = (int) statistics.numberOfReceivedMessages; // + statistics.numberOfReceivedAttachments;
        
        [self.simpleAnalyticsViewController.numberOfSentMessages setStringValue:[NSString stringWithFormat:@"%d", totalSent]];
        [self.simpleAnalyticsViewController.numberOfReceivedMessages setStringValue:[NSString stringWithFormat:@"%d", totalReceived]];
        [self.simpleAnalyticsViewController.totalNumberOfMessages setStringValue:[NSString stringWithFormat:@"%d", totalReceived + totalSent]];
    }
    
    NSView *selectedView = [self.contactsTableView viewAtColumn:0 row:self.lastChosenPersonIndex makeIfNecessary:YES];
    [self.simpleAnalyticsPopOver showRelativeToRect:selectedView.bounds ofView:selectedView preferredEdge:NSMaxXEdge];
}

- (IBAction)calendarButtonClick:(id)sender {

    if(!self.calendarPopover) {
        self.calendarPopUpViewController = [[CalendarPopUpViewController alloc] initWithNibName:@"CalendarPopUpViewController" bundle:[NSBundle mainBundle]];
        self.calendarPopUpViewController.delegate = self;
        self.calendarPopover = [[NSPopover alloc] init];
        [self.calendarPopover setContentSize:self.calendarPopUpViewController.view.bounds.size];
        [self.calendarPopover setContentViewController:self.calendarPopUpViewController];
        [self.calendarPopover setAnimates:YES];
        [self.calendarPopover setBehavior:NSPopoverBehaviorTransient];
        self.calendarPopover.delegate = self;
    }
    
    NSDate *lastDate = [NSDate date];
    if(self.currentConversationChats.count > 0) {
        Message *lastMessage = self.currentConversationChats[self.currentConversationChats.count - 1];
        lastDate = lastMessage.dateSent;
    }
    self.calendarPopUpViewController.dateToShow = lastDate;
    [self.calendarPopover showRelativeToRect:[self.calendarButton bounds] ofView:self.calendarButton preferredEdge:NSMaxXEdge];
}

- (IBAction)orderByButton:(id)sender {
    
    if([self.orderByPopUpButton.titleOfSelectedItem isEqualToString:orderByRecent]) {
        self.searchConversationChats = self.chats;
    }
    else if([self.orderByPopUpButton.titleOfSelectedItem isEqualToString:orderByMostMessages]) {
        Person *person = self.lastChosenPerson;
        
        if(!self.lastChosenPerson) {
            return;
        }
        
        //We need to find the counts for each person
        if(person.messagesWithPerson == INT_MIN || person.messagesWithPerson == 0) {
            for(Person *person in self.searchConversationChats) {
                person.messagesWithPerson = [self.messageManager getMessageCountWithPerson:person];
                NSLog(@"GOT: %d", person.messagesWithPerson);
            }
        }
        
        NSArray *mostMessages = [self.searchConversationChats sortedArrayUsingComparator:^NSComparisonResult(id a, id b) {
            Person *first = (Person*) a;
            Person *second = (Person*) b;
            
            return [[NSNumber numberWithInt:first.messagesWithPerson] compare:[NSNumber numberWithInt:second.messagesWithPerson]];
        }];
        self.searchConversationChats = [[NSMutableArray alloc] initWithArray:mostMessages];
        [self.contactsTableView reloadData];
        
        NSLog(@"FINISHED WITH SORTING");
    }
}

- (void) dateChosen:(NSDate *)chosenDate
{
    self.calendarChosenDate = chosenDate;
    
    //Reset to show all messages
    if(!self.calendarChosenDate) {
        self.currentConversationChats = [self.messageManager getAllMessagesForPerson:self.lastChosenPerson];
    }
    else {
        self.currentConversationChats = [self.messageManager getAllMessagesForPerson:self.lastChosenPerson onDay:self.calendarChosenDate];
    }
    
    [self.messagesTableView reloadData];
    
    if(!chosenDate) {
        [self.calendarPopover performClose:@"close"];
    }
}

- (void) wantsMoreAnalysis
{
    self.moreAnalysisWindowController = [[MoreAnalysisWindowController alloc] initWithWindowNibName:@"MoreAnalysisWindowController" person:self.lastChosenPerson messages:[self.messageManager getAllMessagesForPerson:self.lastChosenPerson]];
    [self.moreAnalysisWindowController showWindow:self];
    self.moreAnalysisWindowController.delegate = self;
}

- (void) moreAnalysisWindowControllerDidClose
{
    self.moreAnalysisWindowController = nil;
}


/****************************************************************
 *
 *              NSTableView Delegate
 *
 *****************************************************************/

# pragma mark NSTableView Delegate

- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        if(!self.currentConversationChats || self.currentConversationChats.count == 0) {
            return 80.0;
        }
        
        Message *message = self.currentConversationChats[row];
        NSString *text = message.messageText;
        
        if(!text || text.length == 0) {
            if(message.hasAttachment) {
                text = @"ATTACHMENT";
            }
            else {
                text = @"";
            }
        }
        
        if(message.attachments) {
            for(int i = 0; i < message.attachments.count; i++) {
                text = [text stringByAppendingString:@"ATTACHMENT  "];
            }
        }
        
        [self.sizingField setStringValue:text];
        return [self.sizingField.cell cellSizeForBounds:self.sizingField.frame].height + 30;
    
        /*[self.sizingView setString:text];
        [self.sizingView sizeToFit];
        return self.sizingView.frame.size.height; */
    }
    
    return 80.0;
}

- (NSView*) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        
        if(row > self.currentConversationChats.count || self.currentConversationChats.count == 0) {
            [self setupNoMessagesView];
            [self.messagesTableView addSubview:self.noMessagesField];
            return self.noMessagesField;
        }
        
        Message *message = self.currentConversationChats[row];
        NSView *encompassingView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        NSRect frame = message.isFromMe ? self.messageFromMe : self.messageToMe;
        
        NSTextField *timeField = [[NSTextField alloc] initWithFrame:self.timeStampRect];
        [timeField setStringValue:[message getTimeStampAsString]];
        [timeField setFocusRingType:NSFocusRingTypeNone];
        [timeField setBordered:NO];
        
        NSTextField_Messages *messageField = [[NSTextField_Messages alloc] initWithFrame:frame];
        [messageField setTextFieldNumber:(int)row];
        [messageField setTag:100];
        [messageField setDelegate:self];
        [messageField setDrawsBackground:YES];
        [messageField setWantsLayer:YES];
        
        if(row == self.lastSearchIndex || message.attachments) {
            
            NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@", message.messageText]];
            
            if(message.isFromMe) {
                [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor whiteColor] range:NSMakeRange(0, attributedString.length)];
            }
            else {
                [attributedString addAttribute:NSForegroundColorAttributeName value:[NSColor blackColor] range:NSMakeRange(0, attributedString.length)];
            }

            if(row == self.lastSearchIndex) {
                [attributedString addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:[attributedString.string rangeOfString:self.searchField.stringValue options:NSCaseInsensitiveSearch]];
            }
            
            if(message.attachments) {
                
                [messageField setAllowsEditingTextAttributes:YES];
                [messageField setSelectable:YES];
                
                NSMutableString *attachmentsValue = [[NSMutableString alloc] init];
                
                if(message.messageText.length == 0) {
                    [attachmentsValue appendString:@"  "];
                }
                
                for(int i = 0; i < message.attachments.count; i++) {
                    [attachmentsValue appendString:[NSString stringWithFormat:@"Attachment %d. ", i]];
                }
                
                NSMutableAttributedString* attachmentsString = [[NSMutableAttributedString alloc] initWithString:(NSString*)attachmentsValue
                                                                                               attributes:self.messageWithAttachmentAttributes];
                [attributedString appendAttributedString:attachmentsString];
            }
            
            [messageField setAttributedStringValue:attributedString];
        }
        else {
            [messageField setStringValue:[NSString stringWithFormat:@"  %@", message.messageText]];
        }

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
    
    else if(tableView == self.contactsTableView) {
        ChatTableViewCell *cell = (ChatTableViewCell*)[tableView makeViewWithIdentifier:@"chatTableViewCell" owner:self];
        Person *person = self.searchConversationChats[row];
        
        if(person.personName.length > 0) {
            [cell.contactName setStringValue:person.personName];
        }
        else {
            [cell.contactName setStringValue:person.number];
        }
        [cell.contactNumber setStringValue:person.number];

        NSMutableArray *messages = [self.messageManager getAllMessagesForPerson:person];
        if(messages && messages.count > 0) {
            Message *lastMessage = messages[messages.count - 1];
            [cell.lastMessagedOn setStringValue:[lastMessage lastMessagedOn]];
        }
        
        [cell.contactPhoto setWantsLayer: YES];
        cell.contactPhoto.layer.borderWidth = 0.0;
        cell.contactPhoto.layer.cornerRadius = 30.0;
        cell.contactPhoto.layer.masksToBounds = YES;
        
        NSData *contactPhotoData = [person.contact imageData];
        
        if(!contactPhotoData) {
            contactPhotoData = [[NSData alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"blank_profile_outline" ofType:@"png"]];
        }
        
        [cell.contactPhoto setImage:[[NSImage alloc] initWithData:contactPhotoData]];
        
        return cell;
    }
    
    return [[NSView alloc] init];
}

- (void) setupNoMessagesView
{
    self.noMessagesField = [[NSTextField alloc] initWithFrame:CGRectMake(0, 0, self.messagesTableView.bounds.size.width, self.messagesTableView.bounds.size.height)];
    
    NSString *text;
    
    if(!self.lastChosenPerson) {
        text = @"No messages or conversations";
    }
    else {
        text = [NSString stringWithFormat:@"No messages with %@ (%@)", self.lastChosenPerson.personName, self.lastChosenPerson.number];
        
        if(self.calendarChosenDate) {
            text = [NSString stringWithFormat:@"%@ on %@", text, [self.dateFormatter stringFromDate:self.calendarChosenDate]];
        }
    }
    [self.noMessagesField setStringValue:text];
    [self.noMessagesField setAlignment:NSTextAlignmentCenter];
    [self.noMessagesField setFocusRingType:NSFocusRingTypeNone];
    [self.noMessagesField setBordered:NO];
}

- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if(tableView == self.contactsTableView) {
        
        if(self.lastChosenPersonIndex == row) {
            return YES;
        }
        
        self.lastChosenPersonIndex = row;
        self.lastChosenPerson = self.searchConversationChats[row];
        self.currentConversationChats = [self.messageManager getAllMessagesForPerson:self.lastChosenPerson];
        
        [self.contactNameTextField setStringValue:[NSString stringWithFormat:@"%@ %@", self.lastChosenPerson.personName, self.lastChosenPerson.number]];
        
        [self.messagesTableView reloadData];
        
        self.lastSearchIndex = -1;
        return YES;
    }
    
    if(tableView == self.messagesTableView) {
        if(((Message*)self.currentConversationChats[row]).hasAttachment) {
            return YES;
        }
    }
    
    return NO;
}

- (NSCell*) tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.contactsTableView) {
        return nil;
    }
    else if(tableView == self.messagesTableView) {
        return nil;
    }
    
    return [[NSCell alloc] initTextCell:@"Something..."];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.contactsTableView) {
        return nil;
    }
    
    else if(tableView == self.messagesTableView) {
        return nil;
    }
    
    return @"PROBLEM";
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView == self.contactsTableView) {
        return self.searchConversationChats.count;
    }
    else if(tableView == self.messagesTableView) {
        
        if(self.currentConversationChats.count > 0) {
            if(self.noMessagesField) {
                [self.noMessagesField setHidden:YES];
            }
            return self.currentConversationChats.count;
        }
        return 1;
    }
    else {
        return 0;
    }
}

- (void) doubleClickContactCell
{
    self.calendarPopUpViewController = [[CalendarPopUpViewController alloc] initWithNibName:@"CalendarPopUpViewController" bundle:[NSBundle mainBundle]];
    self.calendarPopUpViewController.delegate = self;
    self.calendarPopover = [[NSPopover alloc] init];
    [self.calendarPopover setContentSize:self.calendarPopUpViewController.view.bounds.size];
    [self.calendarPopover setContentViewController:self.calendarPopUpViewController];
    [self.calendarPopover setAnimates:YES];
    [self.calendarPopover setBehavior:NSPopoverBehaviorTransient];
    self.calendarPopover.delegate = self;
}


/****************************************************************
 *
 *              NSearchField Delegate
 *
 *****************************************************************/

# pragma mark SEARCHFIELD_DELEGATE

- (void) controlTextDidEndEditing:(NSNotification *)obj
{
    if(self.searchField.stringValue.length == 0) {
        self.searchConversationChats = [[NSMutableArray alloc] initWithArray:self.chats];
        [self.contactsTableView reloadData];
    }
    else {
        NSString *searchText = [self.searchField stringValue];
        if([[[obj userInfo] objectForKey:@"NSTextMovement"] intValue] == NSReturnTextMovement) {
            if(self.lastSearchIndex >= self.currentConversationChats.count) {
                self.lastSearchIndex = -1;
            }
            int i;
            for(i = self.lastSearchIndex + 1; i < self.currentConversationChats.count; i++) {
                Message *message = self.currentConversationChats[i];
                if([message.messageText rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                    self.lastSearchIndex = i;
                    i = INT16_MAX;
                }
            }
            
            //We reached the end without finding anything, so start from the beginning
            if(i == self.currentConversationChats.count) {
                for(i = 0; i < self.currentConversationChats.count; i++) {
                    Message *message = self.currentConversationChats[i];
                    if([message.messageText rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
                        self.lastSearchIndex = i;
                        i = INT16_MAX;
                    }
                }
            }
            
            [self.messagesTableView reloadDataForRowIndexes:[NSIndexSet indexSetWithIndex:self.lastSearchIndex] columnIndexes:[NSIndexSet indexSetWithIndex:0]];
            //Results in a smoother scroll
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                [self.messagesTableView scrollRowToVisible:self.lastSearchIndex];
            }];

        }
    }
}

- (void) controlTextDidChange:(NSNotification *)obj
{
    if(self.searchField.stringValue.length == 0) {
        self.searchConversationChats = [[NSMutableArray alloc] initWithArray:self.chats];
    }
    else {
        [self.searchConversationChats removeAllObjects];
        
        NSString *searchText = self.searchField.stringValue;
        
        [self.searchConversationChats addObjectsFromArray:[self.messageManager peopleForSearchCriteria:searchText]];
    }
    
    [self.contactsTableView reloadData];
    
    if(self.searchConversationChats.count > 0 && self.searchConversationChats[0] != self.lastChosenPerson) {
        self.lastChosenPerson = self.searchConversationChats[0];
        self.currentConversationChats = [self.messageManager getAllMessagesForPerson:self.lastChosenPerson];
        [self.contactNameTextField setStringValue:[NSString stringWithFormat:@"%@ %@", self.lastChosenPerson.personName, self.lastChosenPerson.number]];
        [self.messagesTableView reloadData];
    }
    else if(self.searchConversationChats.count == 0) {
        self.lastChosenPerson = nil;
        self.currentConversationChats = [[NSMutableArray alloc] init];
        [self.contactNameTextField setStringValue:@""];
        [self.messagesTableView reloadData];
    }
}


/****************************************************************
 *
 *              NSTextField Delegate
 *
 *****************************************************************/

# pragma mark NSTextField Delegate

- (void) clickedOnTextField:(int32_t)textFieldNumber
{
    NSMutableArray *attachments = ((Message*)self.currentConversationChats[textFieldNumber]).attachments;
    
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
 *              NSPopover Delegate
 *
 *****************************************************************/

# pragma mark NSPopover Delegate

- (void) popoverDidClose:(NSNotification *)notification
{
    if(((NSPopover*)notification.object) == self.viewAttachmentsPopover) {
        self.viewAttachmentsPopover = nil;
        self.viewAttachmentsViewController = nil;
    }
}


/****************************************************************
 *
 *              Helper Methods
 *
 *****************************************************************/

# pragma mark Helper Methods

/** Deprecated */
- (BOOL) conversationMatchesRequirement:(Person*)person searchText:(NSString*)searchText {
    
    if([person.personName rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return YES;
    }
    
    if([person.number rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
        return YES;
    }
    
    NSMutableArray *messages = [self.messageManager getAllMessagesForPerson:person];
    for(Message *message in messages) {
        if([message.messageText rangeOfString:searchText options:NSCaseInsensitiveSearch].location != NSNotFound) {
            return YES;
        }
    }
    
    return NO;
}

@end