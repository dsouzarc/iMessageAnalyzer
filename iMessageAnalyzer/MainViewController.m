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
@property (strong) IBOutlet NSTextField *contactNameTextField;

@property (strong, nonatomic) NSTextView *sizingView;
@property (strong, nonatomic) NSTextField *sizingField;

@property (strong, nonatomic) Person *lastChosenPerson;

@property NSRect messageFromMe;
@property NSRect messageToMe;

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
        return self.currentConversationChats.count;
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
        return [self.sizingField.cell cellSizeForBounds:self.sizingField.frame].height + 10;
    
        /*[self.sizingView setString:text];
        [self.sizingView sizeToFit];
        return self.sizingView.frame.size.height; */
    }
    
    return 80.0;
}


- (NSView*) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        
        Message *message = self.currentConversationChats[row];
        NSView *encompassingView = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 0, 0)];
        NSRect frame = message.isFromMe ? self.messageFromMe : self.messageToMe;
        
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
        
        NSTextField *field = [[NSTextField alloc] initWithFrame:frame];
        [field setStringValue:[NSString stringWithFormat:@"  %@", message.messageText]];
        
        [field setDrawsBackground:YES];
        [field setWantsLayer:YES];
        
        NSSize goodFrame = [field.cell cellSizeForBounds:frame];
        [field setFrameSize:CGSizeMake(goodFrame.width + 10, goodFrame.height + 4)];
        
        if(message.isFromMe) {
            [field setFrameOrigin:CGPointMake(tableColumn.width - field.frame.size.width, field.frame.origin.y)];
            [field setBackgroundColor:[NSColor blueColor]];
            [field setTextColor:[NSColor whiteColor]];
        }
        else {
            [field setBackgroundColor:[NSColor lightGrayColor]];
            [field setTextColor:[NSColor blackColor]];
        }
        
        [field setWantsLayer:YES];
        [field.layer setCornerRadius:14.0f];
        [field setFocusRingType:NSFocusRingTypeNone];
        [field setBordered:NO];
        
        
        [encompassingView addSubview:field];
        
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
    }
    [self.contactsTableView reloadData];
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
}

@end
