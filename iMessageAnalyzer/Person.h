//
//  Person.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/5/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <Foundation/Foundation.h>

#include "Statistics.h"

@interface Person : NSObject

- (instancetype) initWithChatId:(NSInteger)chatId guid:(NSString*)guid accountId:(NSString*)accountId chatIdentifier:(NSString*)chatIdentifier groupId:(NSString*)groupId isIMessage:(bool)isImessage personName:(NSString*)personName;

@property (strong, nonatomic) NSString *personName;
@property (strong, nonatomic) NSString *guid;
@property (strong, nonatomic) NSString *accountId;
@property (strong, nonatomic) NSString *chatIdentifier;
@property (strong, nonatomic) NSString *groupId;

@property (strong, nonatomic) NSString *number;

@property (strong, nonatomic) ABPerson *contact;

@property (strong, nonatomic) Statistics *statistics;
@property (strong, nonatomic) Statistics *secondaryStatistics;

@property NSInteger chatId;
@property NSInteger secondaryChatId;

@property int32_t handleID;
@property int32_t secondaryHandleId;

@property BOOL isIMessage;

@property long timeOfLastMessage;
@property int messagesWithPerson;

@end
