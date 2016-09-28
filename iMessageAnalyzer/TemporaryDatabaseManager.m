//
//  TemporaryDatabaseManager.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/25/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "TemporaryDatabaseManager.h"

#pragma mark Static variables
#define MAX_DB_TRIES 40

static NSString *myMessagesTable = @"myMessagesTable";
static NSString *otherMessagesTable = @"otherMessagesTable";

static TemporaryDatabaseManager *databaseManager;


@interface TemporaryDatabaseManager ()

#pragma mark Private variables

@property (strong, nonatomic) Person *person;
@property (strong, nonatomic) NSCalendar *calendar;

@property sqlite3 *database;

@property (strong, nonatomic) FMDatabase *fmDatabase;

@end

@implementation TemporaryDatabaseManager


/****************************************************************
 *
 *              Constructor
 *
 *****************************************************************/

# pragma mark Constructor

+ (instancetype) getInstanceWithperson:(Person *)person messages:(NSMutableArray *)messages
{
    @synchronized(self) {
        if(!databaseManager || databaseManager.person != person) {
            databaseManager = [[self alloc] initWithPerson:person messages:messages];
        }
        return databaseManager;
    }
}

+ (instancetype) getInstance
{
    @synchronized(self) {
        if(!databaseManager) {
            [NSException raise:@"NO PERSON FOUND FOR" format:@"TEMPORARY DATABASE MANAGER"];
        }
        
        return databaseManager;
    }
}

- (instancetype) initWithPerson:(Person *)person messages:(NSMutableArray *)messages {
    self = [super init];
    
    if(self) {
        self.person = person;
        self.finishedAddingEntries = NO;
        
        self.calendar = [NSCalendar currentCalendar];
        [self.calendar setTimeZone:[NSTimeZone systemTimeZone]];
        
        self.fmDatabase = [FMDatabase databaseWithPath:nil];
        
        if([self.fmDatabase open]) {
            
            NSLog(@"OPENED TEMPORARY DATABASE");
            
            [self createMyMessagesTable];
            [self createOtherMessagesTable];
            [self addPragmas];
            
            [self addMessagesToDatabase:messages];
            
            //[self addOtherMessagesToDatabase:[[DatabaseManager getInstance] getTemporaryInformationForAllConversationsExceptWith:person]];
            
            NSMutableArray *others = [NSMutableArray arrayWithArray:[[DatabaseManager getInstance] getTemporaryInformationForAllConversationsExceptWith:person]];
            
            [self addOtherMessagesToDatabase:others];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                //TODO: HERE

                //[self addOtherMessagesToDatabase:[[DatabaseManager getInstance] getTemporaryInformationForAllConversationsExceptWith:person]];
            });
            
        } else {
            NSLog(@"ERROR OPENING TEMPORARY DATABASE");
        }
    }
    
    return self;
}

+ (void) closeDatabase
{
    if(databaseManager) {
        databaseManager.person = nil;
        [databaseManager.fmDatabase close];
    }
    
    databaseManager = nil;
}


/****************************************************************
 *
 *              Insert into my messages
 *
 *****************************************************************/

# pragma mark Insert into my messages

- (NSString*) insertMessageQuery:(Message*)message
{
    int date = [message.dateSent timeIntervalSinceReferenceDate];
    int dateRead = message.dateRead ? [message.dateRead timeIntervalSinceReferenceDate] : 0;
    NSString *service = message.isIMessage ? @"iMessage" : @"SMS";
    int isFromMe = message.isFromMe ? 1 : 0;
    int cache_has_attachments = message.hasAttachment || message.attachments ? 1 : 0;
    int wordCount = (int)[message.messageText componentsSeparatedByString:@" "].count;
    NSString *text = [message.messageText stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    return [NSString stringWithFormat:@"INSERT INTO %@(ROWID, guid, text, handle_id, service, date, date_read, is_from_me, cache_has_attachments, wordCount) VALUES ('%d', '%@', '%@', '%d', '%@', '%d', '%d', '%d', '%d', '%d');", myMessagesTable, (int)message.messageId, message.messageGUID, text, (int) message.handleId, service, date, dateRead, isFromMe, cache_has_attachments, wordCount];
}

- (void) addMessagesToDatabase:(NSMutableArray*)messages
{
    
    CFTimeInterval startTime = CACurrentMediaTime();

    NSMutableString *insertStatements = [[NSMutableString alloc] init];
    int messageCounter = 0;
    
    [self.fmDatabase executeQuery:@"BEGIN TRANSACTION"];
    
    for(Message *message in messages) {
        NSString *insertStatement = [self insertMessageQuery:message];
        [insertStatements appendString:insertStatement];
        messageCounter++;
        
        if(messageCounter % 50 == 0) {
            [self.fmDatabase executeStatements:insertStatements];
            
            messageCounter = 0;
            [insertStatements setString:@""];
        }
    }
    
    if(messageCounter > 0) {
        [self.fmDatabase executeStatements:insertStatements];
        [insertStatements setString:@""];
    }
    
    insertStatements = nil;
    
    [self.fmDatabase executeQuery:@"COMMIT TRANSACTION"];
    
    CFTimeInterval endTime = CACurrentMediaTime();
    NSLog(@"EXECUTION TIME FOR ADDING MESSAGES TO TEMP DB: %f", (endTime - startTime));
}


/****************************************************************
 *
 *              Insert into other messages
 *
 *****************************************************************/

# pragma mark Insert into other messages

- (NSString*) insertOtherMessageQuery:(NSDictionary*)otherMessage
{
    int rowID = [otherMessage[@"ROWID"] intValue];
    int date = [otherMessage[@"date"] intValue];
    int wordCount = [otherMessage[@"wordCount"] intValue];
    int isFromMe = [otherMessage[@"is_from_me"] intValue];
    int hasAttachment = [otherMessage[@"cache_has_attachments"] intValue];
    return [NSString stringWithFormat:@"INSERT INTO %@(ROWID, date, wordCount, is_from_me, cache_has_attachments) VALUES (%d, %d, %d, %d, %d)", otherMessagesTable, rowID, date, wordCount, isFromMe, hasAttachment];
}

- (void) addOtherMessagesToDatabase:(NSMutableArray*)otherMessages
{
    
    CFTimeInterval startTime = CACurrentMediaTime();
    
    NSMutableString *insertStatements = [[NSMutableString alloc] init];
    int messageCounter = 0;
    
    [self.fmDatabase executeQuery:@"BEGIN TRANSACTION"];
    
    for(NSDictionary *message in otherMessages) {
        NSString *insertStatement = [self insertOtherMessageQuery:message];
        
        [insertStatements appendString:insertStatement];
        messageCounter++;
        
        if(messageCounter % 150 == 0) {
            [self.fmDatabase executeStatements:insertStatements];
            
            messageCounter = 0;
            [insertStatements setString:@""];
        }
    }
    
    if(messageCounter > 0) {
        [self.fmDatabase executeStatements:insertStatements];
        [insertStatements setString:@""];
    }
    
    insertStatements = nil;
    
    [self.fmDatabase executeQuery:@"COMMIT TRANSACTION"];
    
    
    CFTimeInterval endTime = CACurrentMediaTime();
    NSLog(@"EXECUTION TIME FOR ADDING OTHER MESSAGES TO TEMP DB: %f", (endTime - startTime));

    self.finishedAddingEntries = YES;
}


/****************************************************************
 *
 *              Get my messages
 *
 *****************************************************************/

# pragma mark Get my messages

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person fromDay:(NSDate *)fromDay toDay:(NSDate*)toDay
{
    long startTime = [[Constants instance] timeAtBeginningOfDayForDate:fromDay];
    long endTime = [[Constants instance] timeAtEndOfDayForDate:toDay];
    return [self getAllMessagesForPerson:person startTimeInSeconds:startTime endTimeInSeconds:endTime];
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person onDay:(NSDate *)day
{
    long startTime = [[Constants instance] timeAtBeginningOfDayForDate:day];
    long endTime = [[Constants instance] timeAtEndOfDayForDate:day];
    return [self getAllMessagesForPerson:person startTimeInSeconds:startTime endTimeInSeconds:endTime];
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person
{
    Statistics *statistics = [[Statistics alloc] init];
    
    NSMutableArray *allMessagesForChat = [self getAllMessagesForConversationFromTimeInSeconds:0 endTimeInSeconds:INT_MAX statistics:&statistics];
    person.statistics = statistics;
    
    [[MessageManager getInstance] updateMessagesWithAttachments:allMessagesForChat person:person];
    
    return allMessagesForChat;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds
{
    Statistics *secondaryStatistics = [[Statistics alloc] init];
    
    NSMutableArray *messages = [self getAllMessagesForConversationFromTimeInSeconds:startTimeInSeconds endTimeInSeconds:endTimeInSeconds statistics:&secondaryStatistics];
    person.secondaryStatistics = secondaryStatistics;
    
    [[MessageManager getInstance] updateMessagesWithAttachments:messages person:person];
    
    return messages;
}

- (NSMutableArray*) getAllMessagesForConversationFromTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds statistics:(Statistics**)statisticsPointer
{
    NSMutableArray *allMessagesForChat = [[NSMutableArray alloc] init];
    
    if(*statisticsPointer == nil) {
        *statisticsPointer = [[Statistics alloc] init];
    }
    
    Statistics *statistics = *statisticsPointer;
    
    NSString *query = [NSString stringWithFormat:@"SELECT ROWID, guid, text, service, date, date_read, is_from_me, cache_has_attachments, handle_id FROM %@ WHERE (date > %ld AND date < %ld) ORDER BY date", myMessagesTable, startTimeInSeconds, endTimeInSeconds];
    
    FMResultSet *result = [self.fmDatabase executeQuery:query];
    
    while([result next]) {
        int messageID = [result intForColumnIndex:0];
        NSString *guid = [result stringForColumnIndex:1];
        
        NSString *text = [result stringForColumnIndex:2];
        if(text) {
            text = [text stringByReplacingOccurrencesOfString:@"''" withString:@"'"];
        } else {
            text = @"";
        }
        
        BOOL isIMessage = [Constants isIMessage:[result stringForColumnIndex:3]];
        int dateInt = [result intForColumnIndex:4];
        int32_t dateReadInt = [result intForColumnIndex:5];
        
        BOOL isFromMe = [result intForColumnIndex:6] == 1 ? YES : NO;
        BOOL hasAttachment = [result intForColumnIndex:7] == 1 ? YES: NO;
        int32_t handleID = [result intForColumnIndex:8];
        
        if(isFromMe) {
            statistics.numberOfSentMessages++;
            if(hasAttachment) {
                statistics.numberOfSentAttachments++;
            }
        }
        else {
            statistics.numberOfReceivedMessages++;
            if(hasAttachment) {
                statistics.numberOfReceivedAttachments++;
            }
        }
        
        NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:dateInt];
        NSDate *dateRead = dateReadInt == 0 ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:dateReadInt];
        
        Message *message = [[Message alloc] initWithMessageId:messageID handleId:handleID messageGUID:guid messageText:text dateSent:date dateRead:dateRead isIMessage:isIMessage isFromMe:isFromMe hasAttachment:hasAttachment];
        [allMessagesForChat addObject:message];
    }
    
    
    return allMessagesForChat;
}


/****************************************************************
 *
 *              Get other messages
 *
 *****************************************************************/

# pragma mark Get other messages

- (NSMutableArray*) getAllOtherMessagesFromStartTime:(int)startTime endTime:(int)endTime
{
    NSMutableArray *allOtherMessages = [[NSMutableArray alloc] init];
    
    NSString *query = [NSString stringWithFormat:@"SELECT ROWID, date, wordCount, is_from_me, cache_has_attachments FROM %@ WHERE (date > %d AND date < %d) ORDER BY date", otherMessagesTable, startTime, endTime];
    
    FMResultSet *result = [self.fmDatabase executeQuery:query];
    
    while([result next]) {
        
        int ROW_ID = [result intForColumnIndex:0];
        int dateInt =  [result intForColumnIndex:1];
        int wordCount =  [result intForColumnIndex:2];
        BOOL isFromMe =  [result intForColumnIndex:3] == 1;
        BOOL hasAttachment =  [result intForColumnIndex:4] == 1;
        
        NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
        [message setObject:[NSNumber numberWithInt:ROW_ID] forKey:@"ROW_ID"];
        [message setObject:[NSNumber numberWithInt:dateInt] forKey:@"date"];
        [message setObject:[NSNumber numberWithInt:wordCount] forKey:@"wordCount"];
        [message setObject:[NSNumber numberWithBool:isFromMe] forKey:@"isFromMe"];
        [message setObject:[NSNumber numberWithBool:hasAttachment] forKey:@"hasAttachment"];
        
        [allOtherMessages addObject:message];
    }
    
    
    return allOtherMessages;
}


/****************************************************************
 *
 *              Get dates for messages
 *
 *****************************************************************/

# pragma mark Get dates for messages

- (NSMutableArray*) getAllMessageTimingsForAll
{
    NSString *query = @"SELECT date FROM otherMessagesTable ORDER BY date";
    return [self getAllMessageTimingsQuery:query];
}

- (NSMutableArray*) getAllMessageTimingsInConversation
{
    NSString *query = @"SELECT date FROM myMessagesTable ORDER BY date";
    return [self getAllMessageTimingsQuery:query];
}


/****************************************************************
 *
 *              Get counts
 *
 *****************************************************************/

# pragma mark Get counts

- (int) getConversationMessageCountStartTime:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE (date > %d AND date < %d)", myMessagesTable, startTime, endTime];
    return [self getSimpleCountFromQuery:query];
}

- (int) getOtherMessagesCountStartTime:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE (date > %d AND date < %d)", otherMessagesTable, startTime, endTime];
    return [self getSimpleCountFromQuery:query];
}

- (int) getMySentMessagesCountInConversationStartTime:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE (date > %d AND date < %d) AND is_from_me='1'", myMessagesTable, startTime, endTime];
    return [self getSimpleCountFromQuery:query];
}

- (int) getMySentOtherMessagesCountStartTime:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE (date > %d AND date < %d) AND is_from_me='1'", otherMessagesTable, startTime, endTime];
    return [self getSimpleCountFromQuery:query];
}

- (int) getReceivedMessagesCountInConversationStartTime:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE (date > %d AND date < %d) AND is_from_me='0'", myMessagesTable, startTime, endTime];
    return [self getSimpleCountFromQuery:query];
}

- (int) getReceivedOtherMessagesCountStartTime:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM %@ WHERE (date > %d AND date < %d) AND is_from_me='0'", otherMessagesTable, startTime, endTime];
    return [self getSimpleCountFromQuery:query];
}

- (NSMutableArray*) getConversationAndOtherMessagesCountStartTime:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM myMessagesTable WHERE (date > %d AND date < %d) UNION ALL SELECT COUNT(*) FROM otherMessagesTable WHERE (date > %d AND date < %d)", startTime, endTime, startTime, endTime];
    
    NSMutableArray *counters = [[NSMutableArray alloc] init];
    
    FMResultSet *result = [self.fmDatabase executeQuery:query];
    
    while([result next]) {
        int count = [result intForColumnIndex:0];
        [counters addObject:@(count)];
    }
    
    return counters;
}


/****************************************************************
 *
 *              Get counts organized by hours
 *
 *****************************************************************/

# pragma mark Get counts organized by hours

- (NSMutableArray*) getMySentWordsInConversationOverHoursInDay:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT date, wordCount FROM myMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='1'", startTime, endTime];
    return [self getSumsOrganizedByHours:query];
}

- (NSMutableArray*) getReceivedWordsInConversationOverHoursInDay:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT date, wordCount FROM myMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='0'", startTime, endTime];
    return [self getSumsOrganizedByHours:query];
}

- (NSMutableArray*) getMySentMessagesInConversationOverHoursInDay:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT date FROM myMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='1'", startTime, endTime];
    return [self getCountsOrganizedByHours:query];
}

- (NSMutableArray*) getReceivedMessagesInConversationOverHoursInDay:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT date FROM myMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='0'", startTime, endTime];
    return [self getCountsOrganizedByHours:query];
}

- (NSMutableArray*) getThisConversationMessagesOverHoursInDay:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT date FROM myMessagesTable WHERE (date > %d AND date < %d)", startTime, endTime];
    return [self getCountsOrganizedByHours:query];
}

- (NSMutableArray*) getOtherMessagesOverHoursInDay:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT date FROM otherMessagesTable WHERE (date > %d AND date < %d)", startTime, endTime];
    return [self getCountsOrganizedByHours:query];
}


/****************************************************************
 *
 *              Get counts (sums)
 *
 *****************************************************************/

# pragma mark Get counts (sums)

- (int) getMySentMessagesWordCountInConversation:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT SUM(wordCount) FROM myMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='1'", startTime, endTime];
    return [self getSimpleCountFromQuery:query];
}

- (int) getMyReceivedMessagesWordCountInConversation:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT SUM(wordCount) FROM myMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='0'", startTime, endTime];
    return [self getSimpleCountFromQuery:query];
}

- (int) getMySentOtherMessagesWordCount:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT SUM(wordCount) FROM otherMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='1'", startTime, endTime];
    return [self getSimpleCountFromQuery:query];
}

- (int) getMyReceivedOtherMessagesWordCount:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT SUM(wordCount) FROM otherMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='0'", startTime, endTime];
    return [self getSimpleCountFromQuery:query];
}


/****************************************************************
 *
 *              Helpers to get data from queryString
 *
 *****************************************************************/

# pragma mark Helpers to get data from queryString

- (int) getSimpleCountFromQuery:(NSString*)queryString
{
    int result = 0;
    
    FMResultSet *resultSet = [self.fmDatabase executeQuery:queryString];
    
    while([resultSet next]) {
        result = [resultSet intForColumnIndex:0];
    }

    return result;
}

- (NSMutableArray*) getAllMessageTimingsQuery:(NSString*)query
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    FMResultSet *result = [self.fmDatabase executeQuery:query];
    
    while([result next]) {
        int timing = [result intForColumnIndex:0];
        [results addObject:@(timing)];
    }

    return results;
}


/****************************************************************
 *
 *              Helpers to organize by hours or days
 *
 *****************************************************************/

# pragma mark Helpers to organize by hours

- (NSMutableArray*) getSumsOrganizedByHours:(NSString*)query
{
    NSMutableArray *mySentMessages = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < 24; i++) {
        [mySentMessages addObject:@(0)];
    }
    
    FMResultSet *result = [self.fmDatabase executeQuery:query];
    
    while([result next]) {
        int dateInSeconds = [result intForColumnIndex:0];
        int hour = [[Constants instance] getDateHourFromDateInSeconds:dateInSeconds];
        
        int wordCount = [result intForColumnIndex:1];
        int newValue = [mySentMessages[hour] intValue] + wordCount;
        mySentMessages[hour] = @(newValue);
    }

    return mySentMessages;
}

- (NSMutableArray*) getCountsOrganizedByHours:(NSString*)query
{
    NSMutableArray *mySentMessages = [[NSMutableArray alloc] init];
    
    for(int i = 0; i < 24; i++) {
        [mySentMessages addObject:@(0)];
    }
    
    FMResultSet *result = [self.fmDatabase executeQuery:query];
    
    while([result next]) {
        int dateInSeconds = [result intForColumnIndex:0];
        int hour = [[Constants instance] getDateHourFromDateInSeconds:dateInSeconds];
        int newValue = [mySentMessages[hour] intValue] + 1;
        mySentMessages[hour] = @(newValue);
    }

    return mySentMessages;
}

- (NSMutableArray<NSMutableArray*>*) sortIntoDays:(NSMutableArray*)allMessages startTime:(int)startTime endTime:(int)endTime
{
    const CFTimeInterval methodStartTime = CACurrentMediaTime();
    
    const int timeInterval = 60 * 60 * 24;
    
    int counter = 0;
    int hour = 0;
    
    NSMutableArray<NSMutableArray*> *daysMessages = [[NSMutableArray alloc] init];
    
    while(startTime < endTime && counter < allMessages.count) {
        NSMutableArray *day = [[NSMutableArray alloc] init];
        NSDate *dateSent = nil;
        
        if([allMessages[counter] class] == [Message class]) {
            dateSent = ((Message*)allMessages[counter]).dateSent;
        }
        else if([allMessages[counter] class] == [NSMutableDictionary class] || [[NSString stringWithFormat:@"%@", [allMessages[counter] class]] isEqualToString:@"__NSDictionaryM"]) {
            NSDictionary *message = allMessages[counter];
            dateSent = [NSDate dateWithTimeIntervalSinceReferenceDate:[[message objectForKey:@"date"] intValue]];
        }
        
        if(!dateSent) {
            NSLog(@"ERROR HERE\t%@", [allMessages[counter] class]);
            break;
        }
        
        //Message occurs after time interval
        if([dateSent timeIntervalSinceReferenceDate] > (startTime + timeInterval)) {
            [daysMessages addObject:day];
        }
        else {
            while([dateSent timeIntervalSinceReferenceDate] <= (startTime + timeInterval) && counter+1 < allMessages.count) {
                [day addObject:allMessages[counter]];
                counter++;
                
                if([allMessages[counter] class] == [Message class]) {
                    dateSent = ((Message*)allMessages[counter]).dateSent;
                }
                else if([allMessages[counter] class] == [NSMutableDictionary class] || [[NSString stringWithFormat:@"%@", [allMessages[counter] class]] isEqualToString:@"__NSDictionaryM"]) {
                    NSDictionary *message = allMessages[counter];
                    dateSent = [NSDate dateWithTimeIntervalSinceReferenceDate:[[message objectForKey:@"date"] intValue]];
                }
            }
            [daysMessages addObject:day];
        }
        
        hour++;
        startTime += timeInterval;
    }
    
    NSLog(@"executionTime for max values = %f", (CACurrentMediaTime() - methodStartTime));
    
    return daysMessages;
}


/****************************************************************
 *
 *              SQLite Helpers
 *
 *****************************************************************/

# pragma mark SQLite Helpers

- (BOOL) executeSQLStatement:(NSString*)sqlStatement errorMessage:(char*)errorMessage
{
    return [self.fmDatabase executeStatements:sqlStatement];
}


#pragma mark Create tables

- (void) createOtherMessagesTable
{
    //CREATE TABLE %@ (ROWID INTEGER PRIMARY KEY, date INTEGER, wordCount INTEGER, is_from_me INTEGER DEFAULT 0, cache_has_attachments INTEGER
    NSString *createQuery = [NSString stringWithFormat:@"CREATE TABLE %@ (ROWID INTEGER, date INTEGER, wordCount INTEGER, is_from_me INTEGER, cache_has_attachments INTEGER)", otherMessagesTable];
    [self createTable:otherMessagesTable createTableStatement:createQuery];
}

- (void) createMyMessagesTable
{
    NSString *createQuery = [NSString stringWithFormat:@"CREATE TABLE %@ (ROWID INTEGER, guid TEXT UNIQUE NOT NULL, text TEXT, handle_id INTEGER DEFAULT 0, service TEXT, date INTEGER, date_read INTEGER, is_from_me, cache_has_attachments INTEGER DEFAULT 0, wordCount INTEGER)", myMessagesTable];
    [self createTable:myMessagesTable createTableStatement:createQuery];
}

- (void) createTable:(NSString*)tableName createTableStatement:(NSString*)createTableStatement
{
    if([self.fmDatabase executeStatements:createTableStatement]) {
        NSLog(@"SUCCESSFULLY CREATED %@", tableName);
    } else {
        NSLog(@"ERROR CREATING TABLE: %@", tableName);
    }
}


#pragma mark Misc. SQLite helpers

- (void) addPragmas
{
    char *errorMessage;
    [self executeSQLStatement:@"PRAGMA journal_mode = MEMORY" errorMessage:errorMessage];
    [self executeSQLStatement:@"PRAGMA synchronous = OFF" errorMessage:errorMessage];
}

- (const char *)filePath
{
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory=[paths objectAtIndex:0];
    return [[documentDirectory stringByAppendingPathComponent:@"LoginDatabase.db"] UTF8String];
}

@end
