//
//  DatabaseManager.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/8/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <sqlite3.h>
#import <AddressBook/AddressBook.h>

#include <string.h>

#import "Contact.h"
#import "Message.h"
#import "Attachment.h"
#import "Person.h"
#import "Statistics.h" 

@interface DatabaseManager : NSObject

+ (instancetype) getInstance;

- (NSMutableArray*) getAllChats;

- (NSMutableArray*) getAllMessagesForPerson:(Person*)person;
- (NSMutableArray*) getAllMessagesForPerson:(Person *)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds;

- (NSMutableSet*) getHandleIDsForMessageText:(NSString*)messageText;
- (int32_t) getHandleForChatID:(int32_t)chatID;

- (int32_t) messageCountForPerson:(Person*)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds;
- (int32_t) totalMessagesForStartTime:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds;

- (NSMutableArray*) getAttachmentsForMessageID:(int32_t)messageID;
- (NSMutableDictionary*) getAllAttachmentsForPerson:(Person*)person;

- (NSMutableArray*) getTemporaryInformationForAllConversationsExceptWith:(Person*)person;

@end