//
//  Person.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/5/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "Person.h"

@implementation Person

- (instancetype) initWithChatId:(NSInteger)chatId guid:(NSString *)guid accountId:(NSString *)accountId chatIdentifier:(NSString *)chatIdentifier groupId:(NSString *)groupId isIMessage:(bool)isImessage personName:(NSString *)personName
{
    self = [super init];
    
    if(self) {
        self.chatId = chatId;
        self.guid = guid;
        self.accountId = accountId;
        self.chatIdentifier = chatIdentifier;
        self.groupId = groupId;
        self.isIMessage = isImessage;
        
        static int counter = 1;
        self.personName = [NSString stringWithFormat:@"Anonymous person %d", counter];
        counter++;
        
        //self.personName = personName;
        
        self.secondaryChatId = -1;
        self.handleID = -1;
        self.secondaryHandleId = -1;
        
        self.timeOfLastMessage = 0;
        self.messagesWithPerson = INT_MIN;
        
        self.statistics = [[Statistics alloc] init];
    }
    
    return self;
}

@end
