//
//  MessageManager.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/8/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "DatabaseManager.h"

#import "Constants.h"
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

- (NSArray*) peopleForSearchCriteria:(NSString*)searchText;

- (Person*) personForPhoneNumber:(NSString*)number;

- (int32_t) getMessageCountWithPersonOnDate:(NSDate*)date person:(Person*)person;
- (int32_t) getMessageCountOnDate:(NSDate*)date;
- (void) updateMessagesWithAttachments:(NSMutableArray*)messages person:(Person*)person;

@end
