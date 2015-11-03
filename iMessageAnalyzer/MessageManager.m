//
//  MessageManager.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/8/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "MessageManager.h"

static MessageManager *messageInstance;

@interface MessageManager ()

@property (strong, nonatomic) DatabaseManager *databaseManager;
@property (strong, nonatomic) NSMutableDictionary* allChatsAndConversations;
@property (strong, nonatomic) NSMutableArray *allChats;

@property (strong, nonatomic) NSCalendar *calendar;

@end

@implementation MessageManager

+ (instancetype) getInstance
{
    @synchronized(self) {
        if(!messageInstance) {
            messageInstance = [[self alloc] init];
        }
    }
    
    return messageInstance;
}

- (instancetype) init
{
    if(!messageInstance) {
        messageInstance = [super init];
        self.databaseManager = [DatabaseManager getInstance];
        self.allChats = [self.databaseManager getAllChats];
        self.allChatsAndConversations = [[NSMutableDictionary alloc] init];
        
        for(Person *person in self.allChats) {
            NSMutableArray *messagesForPerson = [self.databaseManager getAllMessagesForPerson:person];
            [self.allChatsAndConversations setObject:messagesForPerson forKey:person.number];
            
            //NSLog(@"%@ %@\tSENT: %d\tRECEIVED: %d\tSENT ATTACHMENTS: %d\tRECEIVED ATTACHMENTS: %d\tHANDLE_1: %d\tHANDLE_2: %d\tCHAT ID: %d, %d", person.personName, person.number, person.statistics.numberOfSentMessages, person.statistics.numberOfReceivedMessages, person.statistics.numberOfSentAttachments, person.statistics.numberOfReceivedAttachments, [self.databaseManager getHandleForChatID:person.chatId], [self.databaseManager getHandleForChatID:person.secondaryChatId], person.chatId, person.secondaryChatId);
        }
        
        self.calendar = [NSCalendar currentCalendar];
        [self.calendar setTimeZone:[NSTimeZone systemTimeZone]];
    }
    
    return self;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person onDay:(NSDate *)day
{
    long startTime = [self timeAtBeginningOfDayForDate:day];
    long endTime = [self timeAtEndOfDayForDate:day];
    
    NSLog(@"Querying for: %ld\t%ld\t%d", startTime, endTime, person.handleID);
    
    return [self.databaseManager getAllMessagesForPerson:person startTimeInSeconds:startTime endTimeInSeconds:endTime];
}

- (long)timeAtEndOfDayForDate:(NSDate*)inputDate
{
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:inputDate];
    
    // Set the time components manually
    [dateComps setHour:11];
    [dateComps setMinute:59];
    [dateComps setSecond:59];
    
    // Convert back
    NSDate *endOfDay = [self.calendar dateFromComponents:dateComps];
    return [endOfDay timeIntervalSince1970];
}

- (long)timeAtBeginningOfDayForDate:(NSDate*)inputDate
{
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [self.calendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:inputDate];
    
    // Set the time components manually
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0];
    
    // Convert back
    NSDate *beginningOfDay = [self.calendar dateFromComponents:dateComps];
    return [beginningOfDay timeIntervalSince1970];
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person
{
    NSMutableArray *messages = [self.allChatsAndConversations objectForKey:person.number];
    
    if(!messages) {
        messages = [self.databaseManager getAllMessagesForPerson:person];
        [self.allChatsAndConversations setObject:messages forKey:person.number];
    }
    
    return messages;
}

- (NSMutableArray*) getAllChats
{
    return self.allChats;
}

- (NSMutableDictionary*) getAllChatsAndConversations
{
    return self.allChatsAndConversations;
}


@end
