//
//  Person.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/5/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <AddressBook/AddressBook.h>

#include "Statistics.h"

@interface Person : NSObject

- (instancetype) initWithChatId:(NSInteger)chatId
                           guid:(NSString*)guid
                      accountId:(NSString*)accountId
                 chatIdentifier:(NSString*)chatIdentifier
                        groupId:(NSString*)groupId
                     isIMessage:(bool)isImessage
                     personName:(NSString*)personName;

@property (strong, nonatomic) NSString *personName;
@property (strong, nonatomic) NSString *guid;
@property (strong, nonatomic) NSString *accountId;
@property (strong, nonatomic) NSString *chatIdentifier;
@property (strong, nonatomic) NSString *groupId;

@property (strong, nonatomic) NSString *number;

@property (strong, nonatomic) ABPerson *contact;

@property (strong, nonatomic) Statistics *statistics;
@property (strong, nonatomic) Statistics *secondaryStatistics;

@property NSMutableSet<NSNumber*> *handleIDs;
@property NSMutableSet<NSNumber*> *chatIDs;

@property NSMutableDictionary *messageIDToIndexMapping;

@property BOOL isIMessage;

@property long timeOfLastMessage;
@property int messagesWithPerson;

- (NSString*) getChatIDsString;

@end
