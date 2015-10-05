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
        self.personName = personName;
    }
    
    return self;
}

@end
