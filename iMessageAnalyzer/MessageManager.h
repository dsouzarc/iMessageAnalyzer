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

/** Manages getting messages from the database */

@interface MessageManager : NSObject

# pragma mark - Singleton

+ (instancetype) getInstance;
+ (instancetype) getInstanceForDatabase:(NSString*)databasePath;


# pragma mark - Getting information

- (NSMutableArray*) getAllChats;
- (NSMutableDictionary*) getAllChatsAndConversations;

- (NSMutableArray*) getAllMessagesForPerson:(Person*)person;
- (NSMutableArray*) getAllMessagesForPerson:(Person*)person onDay:(NSDate*)day;
- (NSMutableArray*) getAllMessagesForPerson:(Person*)person fromDay:(NSDate *)fromDay toDay:(NSDate *)toDay;
- (NSMutableArray*) getAllMessagesForPerson:(Person*)person startTime:(long)startTime endTime:(long)endTime;

- (int32_t) getMessageCountWithPersonOnDate:(NSDate*)date person:(Person*)person;
- (int32_t) getMessageCountOnDate:(NSDate*)date;
- (int32_t) getMessageCountWithPerson:(Person*)person;

- (NSArray*) peopleForSearchCriteria:(NSString*)searchText;
- (Person*) personForPhoneNumber:(NSString*)number;


# pragma mark - Auxillary methods

- (void) updateMessagesWithAttachments:(NSMutableArray*)messages person:(Person*)person;

@end
