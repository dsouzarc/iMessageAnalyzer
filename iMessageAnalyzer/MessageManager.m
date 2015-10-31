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
            NSMutableArray *messagesForPerson = [self.databaseManager getAllMessagesForChatID:person.chatId secondaryID:person.secondaryChatId];
            [self.allChatsAndConversations setObject:messagesForPerson forKey:person.number];
        }
    }
    
    return self;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person
{
    return [self.allChatsAndConversations objectForKey:person.number];
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
