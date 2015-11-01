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

@property (strong, nonatomic) MessageManager *messageManager;

@property (strong, nonatomic) NSMutableArray *chats;
@property (strong, nonatomic) NSMutableArray *searchConversationChats;

@property (strong, nonatomic) NSMutableArray *currentConversationChats;

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
    
    NSNib *cellNib = [[NSNib alloc] initWithNibNamed:@"ChatTableViewCell" bundle:[NSBundle mainBundle]];
    [self.contactsTableView registerNib:cellNib forIdentifier:@"chatTableViewCell"];
    
    NSNib *cellNib2 = [[NSNib alloc] initWithNibNamed:@"TextTableCellView" bundle:[NSBundle mainBundle]];
    [self.messagesTableView registerNib:cellNib2 forIdentifier:@"textTableCellView"];
    
    if(self.searchConversationChats.count > 0) {
        Person *firstPerson = self.searchConversationChats[0];
        self.currentConversationChats = [self.messageManager getAllMessagesForPerson:firstPerson];
        [self.messagesTableView reloadData];
        NSLog(@"SIZE: %d", self.currentConversationChats.count);
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
        
        NSRect frame = NSMakeRect(0, 0, 360, MAXFLOAT);
        NSTextView *viewForSize = [[NSTextView alloc] initWithFrame:frame];
        [[viewForSize textStorage] setAttributedString:[[NSAttributedString alloc] initWithString:text]];
        [viewForSize setHorizontallyResizable:YES];
        [viewForSize sizeToFit];
        
        return viewForSize.frame.size.height;
    }
    
    return 80.0;
    
}


- (NSView*) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        Message *message = self.currentConversationChats[row];
        
        TextTableCellView *tempView = [tableView makeViewWithIdentifier:@"textTableCellView" owner:self];
        NSView *encompassingView = [[NSView alloc] initWithFrame:tempView.frame];
        
        NSRect frame = NSMakeRect(message.isFromMe ? tableColumn.width/2 : 0, 0, 360, MAXFLOAT);
        
        NSTextView *viewForSize = [[NSTextView alloc] initWithFrame:frame];
        [viewForSize setString:message.messageText];
        
        [viewForSize setAlignment:(message.isFromMe ? NSTextAlignmentRight : NSTextAlignmentLeft)];
        [viewForSize setHorizontallyResizable:YES];
        [viewForSize sizeToFit];
        
        if(message.isFromMe) {
            [viewForSize setFrameOrigin:CGPointMake(tableColumn.width - viewForSize.frame.size.width, viewForSize.frame.origin.y)];
        }
        
        [encompassingView addSubview:viewForSize];
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
        Person *person = self.searchConversationChats[row];
        self.currentConversationChats = [self.messageManager getAllMessagesForPerson:person];
        [self.messagesTableView reloadData];
        
        return YES;
    }
    return NO;
}

- (NSCell*) tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if([[tableColumn identifier] isEqualToString:@"chatsIdentifier"]) {
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
