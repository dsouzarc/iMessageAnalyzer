//
//  TemporaryDatabaseManager.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/25/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sqlite3.h>

#import "MessageManager.h"
#import "Constants.h"
#import "Message.h"
#import "Person.h"
#import "Statistics.h"


/** Manages a temporary database for MoreAnalysisViewController */

@interface TemporaryDatabaseManager : NSObject

#pragma mark Constructors and Misc.

+ (instancetype) getInstance;
+ (instancetype) getInstanceWithperson:(Person*)person messages:(NSMutableArray*)messages;
+ (void) closeDatabase;

@property (nonatomic) BOOL finishedAddingEntries;


#pragma mark Get messages

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person;
- (NSMutableArray*) getAllMessagesForPerson:(Person*)person onDay:(NSDate*)day;
- (NSMutableArray*) getAllMessagesForPerson:(Person *)person fromDay:(NSDate *)fromDay toDay:(NSDate*)toDay;
- (NSMutableArray*) getAllMessagesForPerson:(Person *)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds;
- (NSMutableArray*) getAllOtherMessagesFromStartTime:(int)startTime endTime:(int)endTime;

- (NSMutableArray*) getAllMessageTimingsInConversation;
- (NSMutableArray*) getAllMessageTimingsForAll;

- (NSMutableArray<NSMutableArray*>*) sortIntoDays:(NSMutableArray*)allMessages startTime:(int)startTime endTime:(int)endTime;


#pragma Get counts

- (NSMutableArray*) getConversationAndOtherMessagesCountStartTime:(int)startTime endTime:(int)endTime;

- (int) getConversationMessageCountStartTime:(int)startTime endTime:(int)endTime;
- (int) getOtherMessagesCountStartTime:(int)startTime endTime:(int)endTime;

- (int) getMySentMessagesCountInConversationStartTime:(int)startTime endTime:(int)endTime;
- (int) getMySentOtherMessagesCountStartTime:(int)startTime endTime:(int)endTime;

- (int) getReceivedMessagesCountInConversationStartTime:(int)startTime endTime:(int)endTime;
- (int) getReceivedOtherMessagesCountStartTime:(int)startTime endTime:(int)endTime;

- (int) getMySentMessagesWordCountInConversation:(int)startTime endTime:(int)endTime;
- (int) getMyReceivedMessagesWordCountInConversation:(int)startTime endTime:(int)endTime;

- (int) getMySentOtherMessagesWordCount:(int)startTime endTime:(int)endTime;
- (int) getMyReceivedOtherMessagesWordCount:(int)startTime endTime:(int)endTime;


#pragma mark Get counts organized by hours

- (NSMutableArray*) getMySentWordsInConversationOverHoursInDay:(int)startTime endTime:(int)endTime;
- (NSMutableArray*) getReceivedWordsInConversationOverHoursInDay:(int)startTime endTime:(int)endTime;

- (NSMutableArray*) getMySentMessagesInConversationOverHoursInDay:(int)startTime endTime:(int)endTime;
- (NSMutableArray*) getReceivedMessagesInConversationOverHoursInDay:(int)startTime endTime:(int)endTime;

- (NSMutableArray*) getThisConversationMessagesOverHoursInDay:(int)startTime endTime:(int)endTime;
- (NSMutableArray*) getOtherMessagesOverHoursInDay:(int)startTime endTime:(int)endTime;


@end