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

- (NSCell*) tableView:(NSTableView *)tableView dataCellForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(!tableColumn) {
        return nil;
    }
    if([[tableColumn identifier] isEqualToString:@"chatsIdentifier"]) {
        return [[NSTextFieldCell alloc] initTextCell:((Person*)self.chats[row]).number];
    }
    
    return [[NSTextFieldCell alloc] initTextCell:@"Uh oh"];
}

- (id) tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if(tableView == self.contactsTableView) {
        Person *person = ((Person*)self.chats[row]);
        
        if(person.personName && person.personName.length > 0) {
            return person.personName;
        }
        else {
            return person.number;
        }
    }
    return @"PROBLEM";
}

@end
