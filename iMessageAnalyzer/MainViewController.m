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

@property (strong, nonatomic) MessageManager *messageManager;
@property (strong, nonatomic) NSMutableArray *chats;
@end

@implementation MainViewController

- (instancetype) initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    
    if(self) {
        self.messageManager = [MessageManager getInstance];
        
        self.chats = [self.messageManager getAllChats];
    }
    
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSNib *cellNib = [[NSNib alloc] initWithNibNamed:@"ChatTableViewCell" bundle:[NSBundle mainBundle]];
    [self.contactsTableView registerNib:cellNib forIdentifier:@"chatTableViewCell"];
}

- (NSInteger) numberOfRowsInTableView:(NSTableView *)tableView
{
    if(tableView == self.contactsTableView) {
        return self.chats.count;
    }
    else {
        return 0;
    }
}

- (NSView*) tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
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
    
    [cell.contactPhoto setImage:[[NSImage alloc] initWithData:[person.contact imageData]]];
    
    return cell;
}

- (NSCell*) tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(!tableColumn) {
        return nil;
    }
    if([[tableColumn identifier] isEqualToString:@"chatsIdentifier"]) {
        return nil;
    }

    return [[NSCell alloc] initTextCell:@""];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.contactsTableView) {
        return nil;
    }
    return @"PROBLEM";
}

@end
