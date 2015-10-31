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

@property (strong, nonatomic) MessageManager *messageManager;
@property (strong, nonatomic) NSMutableArray *chats;

@property (strong, nonatomic) NSMutableArray *currentConversationChats;

@end

@implementation MainViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.messageManager = [MessageManager getInstance];
        
        self.chats = [self.messageManager getAllChats];
        self.currentConversationChats = [[NSMutableArray alloc] init];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNib *cellNib = [[NSNib alloc] initWithNibNamed:@"ChatTableViewCell" bundle:[NSBundle mainBundle]];
    [self.contactsTableView registerNib:cellNib forIdentifier:@"chatTableViewCell"];
    
    Person *firstPerson = self.chats[0];
    self.currentConversationChats = [self.messageManager getAllMessagesForPerson:firstPerson];
    [self.messagesTableView reloadData];
    NSLog(@"SIZE: %d", self.currentConversationChats.count);
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView == self.contactsTableView) {
        return self.chats.count;
    }
    else if(tableView == self.messagesTableView) {
        return self.currentConversationChats.count;
    }
    else {
        return 0;
    }
}

- (NSView*) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.messagesTableView) {
        Message *message = self.currentConversationChats[row];
        NSTableCellView *view = [tableView makeViewWithIdentifier:@"messageCellViewIdentifier" owner:self];
        view.textField.stringValue = message.messageText;
        
        if(message.isFromMe) {
            [view.textField setAlignment:NSTextAlignmentRight];
        }
        else {
            [view.textField setAlignment:NSTextAlignmentLeft];
        }
        
        return view;
    }
    
    ChatTableViewCell *cell = (ChatTableViewCell*)[tableView makeViewWithIdentifier:@"chatTableViewCell" owner:self];
    Person *person = self.chats[row];
    
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
    
    NSImage *contactPhoto = [[NSImage alloc] initWithData:[person.contact imageData]];
    
    if(!contactPhoto) {
        [NSGraphicsContext saveGraphicsState];
        
    }
    
    [cell.contactPhoto setImage:contactPhoto];
    
    return cell;
}

- (BOOL) tableView:(NSTableView *)tableView shouldSelectRow:(NSInteger)row
{
    if(tableView == self.contactsTableView) {
        Person *person = self.chats[row];
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

@end
