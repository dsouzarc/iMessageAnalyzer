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
        self.allChatsAndConversations = [[NSMutableDictionary alloc] init];
    }
    
    return self;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person
{
    //If we've already cached it
    if([self.allChatsAndConversations objectForKey:person.number]) {
        return [self.allChatsAndConversations objectForKey:person.number];
    }
    
    //Otherwise, get it from the DB and return it
    else {
        NSMutableArray *messagesForPerson = [self.databaseManager getAllMessagesForChatID:person.chatId];
        [self.allChatsAndConversations setObject:messagesForPerson forKey:person.number];
        return messagesForPerson;
    }
}

- (NSMutableArray*) getAllChats
{
    return [self.databaseManager getAllChats];
}

- (NSMutableDictionary*) getAllChatsAndConversations
{
    return self.allChatsAndConversations;
}


@end
