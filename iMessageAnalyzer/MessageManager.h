//
//  MessageManager.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/8/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DatabaseManager.h"

#import "Person.h"
#import "Attachment.h"
#import "Message.h"
#import "Statistics.h"

@interface MessageManager : NSObject

+ (instancetype) getInstance;

- (NSMutableArray*) getAllChats;
- (NSMutableDictionary*) getAllChatsAndConversations;

- (NSMutableArray*) getAllMessagesForPerson:(Person*)person;
- (NSMutableArray*) getAllMessagesForPerson:(Person*)person onDay:(NSDate*)day;

@end
