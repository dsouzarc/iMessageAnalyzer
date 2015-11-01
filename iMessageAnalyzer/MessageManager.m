//
//  MessageManager.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/8/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "MessageManager.h"

static MessageManager *messageInstance;

@interface MessageManager ()

@property (strong, nonatomic) DatabaseManager *databaseManager;
@property (strong, nonatomic) NSMutableDictionary* allChatsAndConversations;
@property (strong, nonatomic) NSMutableArray *allChats;

@end

@implementation MessageManager

+ (instancetype) getInstance
{
    @synchronized(self) {
        if(!messageInstance) {
            messageInstance = [[self alloc] init];
        }
    }
    
    return messageInstance;
}

- (instancetype) init
{
    if(!messageInstance) {
        messageInstance = [super init];
        self.databaseManager = [DatabaseManager getInstance];
        self.allChats = [self.databaseManager getAllChats];
        self.allChatsAndConversations = [[NSMutableDictionary alloc] init];
        
        for(Person *person in self.allChats) {
            NSMutableArray *messagesForPerson = [self.databaseManager getAllMessagesForPerson:person];
            [self.allChatsAndConversations setObject:messagesForPerson forKey:person.number];
            
            //NSLog(@"%@ %@\tSENT: %d\tRECEIVED: %d\tSENT ATTACHMENTS: %d\tRECEIVED ATTACHMENTS: %d\tHANDLE_1: %d\tHANDLE_2: %d\tCHAT ID: %d, %d", person.personName, person.number, person.statistics.numberOfSentMessages, person.statistics.numberOfReceivedMessages, person.statistics.numberOfSentAttachments, person.statistics.numberOfReceivedAttachments, [self.databaseManager getHandleForChatID:person.chatId], [self.databaseManager getHandleForChatID:person.secondaryChatId], person.chatId, person.secondaryChatId);
        }
    }
    
    return self;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person
{
    NSMutableArray *messages = [self.allChatsAndConversations objectForKey:person.number];
    
    if(!messages) {
        messages = [self.databaseManager getAllMessagesForPerson:person];
        [self.allChatsAndConversations setObject:messages forKey:person.number];
    }
    
    return messages;
}

- (NSMutableArray*) getAllChats
{
    return self.allChats;
}

- (NSMutableDictionary*) getAllChatsAndConversations
{
    return self.allChatsAndConversations;
}


@end
