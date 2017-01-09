//
//  DatabaseManager.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/8/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <AddressBook/AddressBook.h>
#import <Foundation/Foundation.h>

#include <string.h>
#import <sqlite3.h>

#import "Contact.h"
#import "Constants.h"
#import "Message.h"
#import "Attachment.h"
#import "Person.h"
#import "Statistics.h" 


/** Manages the user's messages database */

@interface DatabaseManager : NSObject

#pragma mark Singleton constructor

+ (instancetype) getInstance;
+ (instancetype) getInstanceForDatabasePath:(NSString*)path;
- (void) deleteDatabase;

#pragma mark Getting chats

- (NSMutableArray*) getAllChats;


#pragma mark Getting messages and counts

- (NSMutableArray*) getAllMessagesForPerson:(Person*)person;
- (NSMutableArray*) getAllMessagesForPerson:(Person *)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds;
- (NSMutableArray*) getTemporaryInformationForAllConversationsExceptWith:(Person*)person;

- (int32_t) messageCountForPerson:(Person*)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds;
- (int32_t) totalMessagesForStartTime:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds;
- (int32_t) getTotalMessageCount;


#pragma mark Getting attachments

- (NSMutableArray*) getAttachmentsForMessageID:(int32_t)messageID;
- (NSMutableDictionary*) getAllAttachmentsForPerson:(Person*)person;


#pragma mark Get handle ids

- (NSMutableSet*) getHandleIDsForMessageText:(NSString*)messageText;
- (int32_t) getHandleForChatID:(int32_t)chatID;

@end
