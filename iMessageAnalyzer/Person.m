//
//  Person.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/5/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "Person.h"

@implementation Person

- (instancetype) initWithChatId:(NSInteger)chatId guid:(NSString *)guid
                      accountId:(NSString *)accountId chatIdentifier:(NSString *)chatIdentifier
                        groupId:(NSString *)groupId isIMessage:(bool)isImessage
                     personName:(NSString *)personName
{
    self = [super init];
    
    if(self) {
        self.guid = guid;
        self.accountId = accountId;
        self.chatIdentifier = chatIdentifier;
        self.groupId = groupId;
        self.isIMessage = isImessage;
        
        self.personName = personName;
        
        self.handleIDs = [[NSMutableSet alloc] init];
        self.chatIDs = [[NSMutableSet alloc] init];
        [self.chatIDs addObject:[NSNumber numberWithInteger:chatId]];
        
        self.timeOfLastMessage = 0;
        self.messagesWithPerson = INT_MIN;
        
        self.statistics = [[Statistics alloc] init];
    }
    
    return self;
}

- (NSString*) getChatIDsString
{
    return [[self.chatIDs allObjects] componentsJoinedByString:@","];
}

@end
