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

#pragma mark Variables for holding all information

@property (strong, nonatomic) NSMutableDictionary* allChatsAndConversations;
@property (strong, nonatomic) NSMutableDictionary *allPeople;
@property (strong, nonatomic) NSMutableArray *allChats;


#pragma mark Auxillary variables

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSSortDescriptor *lastMessageSentDescriptor;

@end

@implementation MessageManager


/****************************************************************
 *
 *              Constructor
 *
*****************************************************************/

# pragma mark Constructor

+ (instancetype) getInstance
{
    @synchronized(self) {
        if(!messageInstance) {
            messageInstance = [[self alloc] init];
        }
    }
    
    return messageInstance;
}

+ (instancetype) getInstanceForDatabase:(NSString *)databasePath
{
    @synchronized(self) {
        if(!messageInstance) {
            messageInstance = [[self alloc] initWithPath:databasePath];
        }
    }
    
    return messageInstance;
}

- (instancetype) initWithPath:(NSString*)databasePath
{
    if(!messageInstance) {
        messageInstance = [super init];
        self.databaseManager = [DatabaseManager getInstanceForDatabasePath:databasePath];
        self.allChats = [self.databaseManager getAllChats];
        
        self.allPeople = [[NSMutableDictionary alloc] init];
        self.allChatsAndConversations = [[NSMutableDictionary alloc] init];
        
        self.lastMessageSentDescriptor = [[NSSortDescriptor alloc] initWithKey:@"timeOfLastMessage" ascending:NO];
        
        for(Person *person in self.allChats) {
            NSMutableArray *messagesForPerson = [self.databaseManager getAllMessagesForPerson:person];
            [self.allPeople setObject:person forKey:person.number];
            
            [self.allChatsAndConversations setObject:messagesForPerson forKey:person.number];
            [self updateMessagesWithAttachments:messagesForPerson person:person];
            
            if(messagesForPerson.count > 0) {
                Message *lastMessage = messagesForPerson[messagesForPerson.count - 1];
                person.timeOfLastMessage = [lastMessage.dateSent timeIntervalSinceReferenceDate];
            }
            
            //NSLog(@"%@ %@\tSENT: %d\tRECEIVED: %d\tSENT ATTACHMENTS: %d\tRECEIVED ATTACHMENTS: %d\tHANDLE_1: %d\tHANDLE_2: %d\tCHAT ID: %d, %d", person.personName, person.number, person.statistics.numberOfSentMessages, person.statistics.numberOfReceivedMessages, person.statistics.numberOfSentAttachments, person.statistics.numberOfReceivedAttachments, [self.databaseManager getHandleForChatID:person.chatId], [self.databaseManager getHandleForChatID:person.secondaryChatId], person.chatId, person.secondaryChatId);
        }
        
        self.calendar = [NSCalendar currentCalendar];
        [self.calendar setTimeZone:[NSTimeZone systemTimeZone]];
        self.allChats = [self sortChatsByLastMessageSent:self.allChats];
        
    }
    
    return self;
}


/****************************************************************
 *
 *              Getting information
 *
*****************************************************************/

# pragma mark Getting information

- (NSMutableArray*) getAllNumbersForSearchText:(NSString *)text
{
    NSMutableSet *results = [[NSMutableSet alloc] init];
    
    //All handle_ids of those who sent text that match this condition
    NSMutableSet *handle_ids = [self.databaseManager getHandleIDsForMessageText:text];
    
    for(Person *person in self.allChats) {
        
        //If the person sent text that contains the text (from handle_ids method), save them
        NSNumber *handleID = [NSNumber numberWithInt:person.handleID];
        NSNumber *handleID2 = [NSNumber numberWithInt:person.secondaryHandleId];
        if([handle_ids containsObject:handleID] || [handle_ids containsObject:handleID2]) {
            [results addObject:person.number];
        }
        
        //If the contact name contains the search text
        else if([person.personName rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [results addObject:person.number];
        }
        
        //If the contact info contains the search text
        else if([person.number rangeOfString:text options:NSCaseInsensitiveSearch].location != NSNotFound) {
            [results addObject:person.number];
        }
    }
    
    return [results allObjects];
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person onDay:(NSDate *)day
{
    long startTime = [[Constants instance] timeAtBeginningOfDayForDate:day];
    long endTime = [[Constants instance] timeAtEndOfDayForDate:day];
    
    /*NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"MM/dd/yyyy HH:mm"];
    NSLog(@"IN HERE: %@\t%@", [formatter stringFromDate:[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:startTime]], [formatter stringFromDate:[[NSDate alloc] initWithTimeIntervalSinceReferenceDate:endTime]]);
    NSLog(@"time: %ld\t%ld\t%d", startTime, endTime, person.handleID);*/
    
    NSMutableArray *messages = [self.databaseManager getAllMessagesForPerson:person startTimeInSeconds:startTime endTimeInSeconds:endTime];
    [self updateMessagesWithAttachments:messages person:person];
    
    return messages;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person
{
    NSMutableArray *messages = [self.allChatsAndConversations objectForKey:person.number];
    
    if(!messages) {
        messages = [self.databaseManager getAllMessagesForPerson:person];
        [self updateMessagesWithAttachments:messages person:person];
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

#pragma mark Get people

- (NSArray*) peopleForSearchCriteria:(NSString*)searchText
{
    NSMutableArray *numbers = [self getAllNumbersForSearchText:searchText];
    return [self peopleForNumbers:numbers];
}

- (NSArray*) peopleForNumbers:(NSMutableArray*)numbers
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    for(NSString *number in numbers) {
        [results addObject:[self.allPeople objectForKey:number]];
    }
    
    return [self sortChatsByLastMessageSent:results];
}

- (NSArray*) sortChatsByLastMessageSent:(NSMutableArray*)arrayOfPeople
{
    return [arrayOfPeople sortedArrayUsingDescriptors:[NSArray arrayWithObject:self.lastMessageSentDescriptor]];
}

- (Person*) personForPhoneNumber:(NSString *)number
{
    return [self.allPeople objectForKey:number];
}


#pragma mark Get counts

- (int32_t) getMessageCountWithPersonOnDate:(NSDate*)date person:(Person*)person
{
    long startTime = [[Constants instance] timeAtBeginningOfDayForDate:date];
    long endTime = [[Constants instance] timeAtEndOfDayForDate:date];
    
    return [self.databaseManager messageCountForPerson:person startTimeInSeconds:startTime endTimeInSeconds:endTime];
}

- (int32_t) getMessageCountOnDate:(NSDate*)date
{
    long startTime = [[Constants instance] timeAtBeginningOfDayForDate:date];
    long endTime = [[Constants instance] timeAtEndOfDayForDate:date];
    
    return [self.databaseManager totalMessagesForStartTime:startTime endTimeInSeconds:endTime];
}


#pragma mark Update messages

- (void) updateMessagesWithAttachments:(NSMutableArray*)messages person:(Person*)person
{
    NSMutableDictionary *attachmentsForPerson = [self.databaseManager getAllAttachmentsForPerson:person];
    
    //For each message
    for(Message *message in messages) {
        NSMutableArray *attachments = [attachmentsForPerson objectForKey:message.messageGUID];
        
        //If the message has an attachment
        if(attachments) {
            message.attachments = attachments;
            
            [attachmentsForPerson removeObjectForKey:message.messageGUID];
            
            //If there aren't any more attachments, we're done here
            if(attachmentsForPerson.count == 0) {
                return;
            }
        }
    }
}

@end