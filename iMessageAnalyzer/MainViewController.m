//
//  MainViewController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/27/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "MainViewController.h"

@interface MainViewController ()

@property (strong) IBOutlet NSTableView *contactsTableView;
@property (strong) IBOutlet NSTableView *messagesTableView;
@property (strong) IBOutlet NSSearchField *searchField;
@property (strong) IBOutlet NSButton *calendarButton;

@property (strong, nonatomic) MessageManager *messageManager;

@property (strong, nonatomic) NSPopover *calendarPopover;
@property (strong, nonatomic) CalendarPopUpViewController *calendarPopUpViewController;
@property (strong, nonatomic) NSDate *calendarChosenDate;

@property (strong, nonatomic) NSMutableArray *chats;
@property (strong, nonatomic) NSMutableArray *searchConversationChats;

@property (strong, nonatomic) NSMutableArray *currentConversationChats;
@property (strong, nonatomic) IBOutlet NSTextField *contactNameTextField;

@property (strong, nonatomic) NSTextView *sizingView;
@property (strong, nonatomic) NSTextField *sizingField;

@property (strong, nonatomic) NSTextField *noMessagesField;
@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property int lastSearchIndex;

@property (strong, nonatomic) Person *lastChosenPerson;

@property NSRect messageFromMe;
@property NSRect messageToMe;
@property NSRect timeStampRect;

@end

@implementation MainViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.messageManager = [MessageManager getInstance];
        
        self.chats = [self.messageManager getAllChats];
        self.searchConversationChats = [[NSMutableArray alloc] initWithArray:self.chats];
        
        self.currentConversationChats = [[NSMutableArray alloc] init];
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:@"MM/dd/yyyy"];
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
        NSLog(@"SIZE: %d", self.currentConversationChats.count);
    }
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

- (void) popoverDidClose:(NSNotification *)notification
{
    if(((NSPopover*)notification.object) == self.calendarPopover) {
        //Do nothing for now
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

/****************************************************************
 *
 *              HELPER METHODS
 *
*****************************************************************/

# pragma mark HELPERS

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


/****************************************************************
 *
 *              NSTABLEVIEW DELEGATE
 *
 *****************************************************************/

# pragma mark TABLEVIEW_DELEGATE

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

- (CGFloat) tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        if(!self.currentConversationChats || self.currentConversationChats.count == 0) {
            return 80.0;
        }
        
        NSString *text = ((Message*) self.currentConversationChats[row]).messageText;
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
        
        /*
        NSTextView *viewForSize = [[NSTextView alloc] initWithFrame:frame];
        [viewForSize setString:message.messageText];
        
        [viewForSize setAlignment:(message.isFromMe ? NSTextAlignmentRight : NSTextAlignmentLeft)];
        [viewForSize setHorizontallyResizable:YES];
        [viewForSize sizeToFit];
        [viewForSize setDrawsBackground:YES];
        
        if(message.isFromMe) {
            [viewForSize setFrameOrigin:CGPointMake(tableColumn.width - viewForSize.frame.size.width, viewForSize.frame.origin.y)];
            [viewForSize setBackgroundColor:[NSColor blueColor]];
            [viewForSize setTextColor:[NSColor whiteColor]];
        }
        else {
            [viewForSize setBackgroundColor:[NSColor lightGrayColor]];
            [viewForSize setTextColor:[NSColor blackColor]];
        } 
        
         float minSize = size.width > viewForSize.frame.size.width ? size.width : viewForSize.frame.size.width;
         [viewForSize setFrameSize:CGSizeMake(minSize, viewForSize.frame.size.height)];
         [encompassingView addSubview:viewForSize];
         */
        
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
        
        if(row == self.lastSearchIndex) {
            NSMutableAttributedString *searchString = [[NSMutableAttributedString alloc] initWithString:message.messageText];
            [searchString addAttribute:NSBackgroundColorAttributeName value:[NSColor yellowColor] range:[message.messageText rangeOfString:self.searchField.stringValue options:NSCaseInsensitiveSearch]];
            [messageField setAttributedStringValue:searchString];
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
        
        [cell.lastMessageSent setStringValue:person.number];
        
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

- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if(tableView == self.contactsTableView) {
        
        self.lastChosenPerson = self.searchConversationChats[row];
        self.currentConversationChats = [self.messageManager getAllMessagesForPerson:self.lastChosenPerson];
        
        [self.contactNameTextField setStringValue:[NSString stringWithFormat:@"%@ %@", self.lastChosenPerson.personName, self.lastChosenPerson.number]];
        
        [self.messagesTableView reloadData];
        
        self.lastSearchIndex = -1;
        return YES;
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


/****************************************************************
 *
 *              NSSEARCHFIELD DELEGATE
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
        
        for(Person *person in self.chats) {
            if([self conversationMatchesRequirement:person searchText:searchText]) {
                [self.searchConversationChats addObject:person];
            }
        }
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

@end
