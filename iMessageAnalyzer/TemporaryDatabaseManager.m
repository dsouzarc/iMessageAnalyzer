//
//  TemporaryDatabaseManager.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/25/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#define MAX_DB_TRIES 40

#import "TemporaryDatabaseManager.h"

static NSString *myMessagesTable = @"myMessagesTable";
static NSString *otherMessagesTable = @"otherMessagesTable";

static TemporaryDatabaseManager *databaseManager;

@interface TemporaryDatabaseManager ()

@property (strong, nonatomic) Person *person;
@property (strong, nonatomic) NSCalendar *calendar;

@property sqlite3 *database;

@end

@implementation TemporaryDatabaseManager

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
        
        const char *filePath = [self filePath]; //":memory:"; //
        
        if(sqlite3_open(filePath, &_database) == SQLITE_OK) {
            printf("OPENED TEMPORARY DATABASE\n");

            [self createMyMessagesTable];
            [self createOtherMessagesTable];
            [self addPragmas];
            
            [self addMessagesToDatabase:messages];
            
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
                [self addOtherMessagesToDatabase:[[DatabaseManager getInstance] getTemporaryInformationForAllConversationsExceptWith:person]];
            });
            
        }
        else {
            printf("ERROR OPENING TEMPORARY DATABASE: %s\n", sqlite3_errmsg(_database));
        }
    }
    
    return self;
}

+ (void) closeDatabase
{
    if(databaseManager) {
        databaseManager.person = nil;
        sqlite3_close(databaseManager.database);
    }
    
    databaseManager = nil;
}


/****************************************************************
 *
 *              INSERT MY MESSAGES
 *
*****************************************************************/

# pragma mark INSERT_MY_MESSAGES

- (NSString*) insertMessageQuery:(Message*)message
{
    int date = [message.dateSent timeIntervalSinceReferenceDate];
    int dateRead = message.dateRead ? [message.dateRead timeIntervalSinceReferenceDate] : 0;
    NSString *service = message.isIMessage ? @"iMessage" : @"SMS";
    int isFromMe = message.isFromMe ? 1 : 0;
    int cache_has_attachments = message.hasAttachment || message.attachments ? 1 : 0;
    int wordCount = (int)[message.messageText componentsSeparatedByString:@" "].count;
    NSString *text = [message.messageText stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    return [NSString stringWithFormat:@"INSERT INTO %@(ROWID, guid, text, handle_id, service, date, date_read, is_from_me, cache_has_attachments, wordCount) VALUES ('%d', '%@', '%@', '%d', '%@', '%d', '%d', '%d', '%d', '%d')", myMessagesTable, (int)message.messageId, message.messageGUID, text, (int) message.handleId, service, date, dateRead, isFromMe, cache_has_attachments, wordCount];
}

- (void) addMessagesToDatabase:(NSMutableArray*)messages
{
    char *errorMessage;
    
    sqlite3_exec(_database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
    
    for(Message *message in messages) {
        NSString *query = [self insertMessageQuery:message];
        [self executeSQLStatement:[query UTF8String] errorMessage:errorMessage];
    }
    
    sqlite3_exec(_database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
}


/****************************************************************
 *
 *              INSERT OTHER MESSAGES
 *
 *****************************************************************/

# pragma mark INSERT_OTHER_MESSAGES

- (void) addOtherMessagesToDatabase:(NSMutableArray*)otherMessages
{
    char *errorMessage;
    
    CFTimeInterval startTime = CACurrentMediaTime();
    
    sqlite3_exec(_database, "BEGIN TRANSACTION", NULL, NULL, &errorMessage);
    
    char buffer[] = "INSERT INTO otherMessagesTable VALUES (?1, ?2, ?3, ?4, ?5)";
    sqlite3_stmt* stmt;
    sqlite3_prepare_v2(_database, buffer, (int)strlen(buffer), &stmt, NULL);
    
    for(NSDictionary *otherMessage in otherMessages) {
        //NSString *query = [self insertOtherMessageQuery:otherMessage];
        //[self executeSQLStatement:[query UTF8String] errorMessage:errorMessage];
        
        sqlite3_bind_int(stmt, 1, [otherMessage[@"ROWID"] intValue]);
        sqlite3_bind_int(stmt, 2, [otherMessage[@"date"] intValue]);
        sqlite3_bind_int(stmt, 3, [otherMessage[@"wordCount"] intValue]);
        sqlite3_bind_int(stmt, 4, [otherMessage[@"is_from_me"] intValue]);
        sqlite3_bind_int(stmt, 5, [otherMessage[@"cache_has_attachments"] intValue]);
        if (sqlite3_step(stmt) != SQLITE_DONE) {
            //Left Blank
        }
        sqlite3_reset(stmt);
    }
    
    sqlite3_exec(_database, "COMMIT TRANSACTION", NULL, NULL, &errorMessage);
    sqlite3_finalize(stmt);
    
    NSLog(@"FINISHED ADDING ALL OTHER MESSAGES TO DB: %f", (CACurrentMediaTime() - startTime));
    self.finishedAddingEntries = YES;
}

- (NSString*) insertOtherMessageQuery:(NSDictionary*)otherMessage
{
    int rowID = [otherMessage[@"ROWID"] intValue];
    int date = [otherMessage[@"date"] intValue];
    int wordCount = [otherMessage[@"wordCount"] intValue];
    int isFromMe = [otherMessage[@"is_from_me"] intValue];
    int hasAttachment = [otherMessage[@"cache_has_attachments"] intValue];
    return [NSString stringWithFormat:@"INSERT INTO %@(ROWID, date, wordCount, is_from_me, cache_has_attachments) VALUES (%d, %d, %d, %d, %d)", otherMessagesTable, rowID, date, wordCount, isFromMe, hasAttachment];
}

/****************************************************************
 *
 *              GET MY MESSAGES
 *
 *****************************************************************/

# pragma mark GET_MY_MESSAGES

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
    
    const char *query = [[NSString stringWithFormat:@"SELECT ROWID, guid, text, service, date, date_read, is_from_me, cache_has_attachments, handle_id FROM %@ WHERE (date > %ld AND date < %ld) ORDER BY date", myMessagesTable, startTimeInSeconds, endTimeInSeconds] UTF8String];
    
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int32_t messageID = sqlite3_column_int(statement, 0);
            NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
            
            NSString *text = @"";
            if(sqlite3_column_text(statement, 2)) {
                text = [NSString stringWithUTF8String:sqlite3_column_text(statement, 2)];
                text = [text stringByReplacingOccurrencesOfString:@"''" withString:@"'"];
            }
            
            BOOL isIMessage = [[Constants instance] isIMessage:sqlite3_column_text(statement, 3)];
            int32_t dateInt = sqlite3_column_int(statement, 4);
            int32_t dateReadInt = sqlite3_column_int(statement, 5);
            
            BOOL isFromMe = sqlite3_column_int(statement, 6) == 1 ? YES : NO;
            BOOL hasAttachment = sqlite3_column_int(statement, 7) == 1 ? YES: NO;
            int32_t handleID = sqlite3_column_int(statement, 8);
            
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
    }
    else {
        NSLog(@"ERROR COMPILING ALL MESSAGES QUERY: %s", sqlite3_errmsg(_database));
    }
    
    sqlite3_finalize(statement);
    
    return allMessagesForChat;
}

- (NSMutableArray*) getAllOtherMessagesFromStartTime:(int)startTime endTime:(int)endTime
{
    NSMutableArray *allOtherMessages = [[NSMutableArray alloc] init];
    
    const char *query = [[NSString stringWithFormat:@"SELECT ROWID, date, wordCount, is_from_me, cache_has_attachments FROM %@ WHERE (date > %d AND date < %d) ORDER BY date", otherMessagesTable, startTime, endTime] UTF8String];

    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            
            int ROW_ID = sqlite3_column_int(statement, 0);
            int dateInt = sqlite3_column_int(statement, 1);
            int wordCount = sqlite3_column_int(statement, 2);
            BOOL isFromMe = sqlite3_column_int(statement, 3) == 1;
            BOOL hasAttachment = sqlite3_column_int(statement, 4) == 1;
            
            NSMutableDictionary *message = [[NSMutableDictionary alloc] init];
            [message setObject:[NSNumber numberWithInt:ROW_ID] forKey:@"ROW_ID"];
            [message setObject:[NSNumber numberWithInt:dateInt] forKey:@"date"];
            [message setObject:[NSNumber numberWithInt:wordCount] forKey:@"wordCount"];
            [message setObject:[NSNumber numberWithBool:isFromMe] forKey:@"isFromMe"];
            [message setObject:[NSNumber numberWithBool:hasAttachment] forKey:@"hasAttachment"];

            [allOtherMessages addObject:message];
        }
    }
    else {
        NSLog(@"ERROR COMPILING ALL MESSAGES QUERY: %s", sqlite3_errmsg(_database));
    }

    sqlite3_finalize(statement);
    
    return allOtherMessages;
}

#pragma mark GET_COUNTS

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

    sqlite3_stmt *statement;
    
    if(sqlite3_prepare(_database, [query UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int count = sqlite3_column_int(statement, 0);
            [counters addObject:[NSNumber numberWithInt:count]];
        }
    }
    
    sqlite3_finalize(statement);
    
    return counters;
}

- (int) getMySentMessagesWordCountInConversation:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM myMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='1'", startTime, endTime];
    return [self getSimpleAdditionFromQuery:query];
}

- (int) getMyReceivedMessagesWordCountInConversation:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM myMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='0'", startTime, endTime];
    return [self getSimpleAdditionFromQuery:query];
}

- (int) getMySentOtherMessagesWordCount:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM otherMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='1'", startTime, endTime];
    return [self getSimpleAdditionFromQuery:query];
}

- (int) getMyReceivedOtherMessagesWordCount:(int)startTime endTime:(int)endTime
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(*) FROM otherMessagesTable WHERE (date > %d AND date < %d) AND is_from_me='0'", startTime, endTime];
    return [self getSimpleAdditionFromQuery:query];
}

- (int) getSimpleAdditionFromQuery:(NSString*)queryString
{
    const char *query = [queryString UTF8String];
    int result = 0;
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            result += sqlite3_column_int(statement, 0);
        }
    }
    sqlite3_finalize(statement);
    return result;
}

- (int) getSimpleCountFromQuery:(NSString*)queryString
{
    const char *query = [queryString UTF8String];
    int result = 0;
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            result = sqlite3_column_int(statement, 0);
        }
    }
    
    sqlite3_finalize(statement);
    return result;
}

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

- (NSMutableArray*) getAllMessageTimingsQuery:(NSString*)query
{
    NSMutableArray *results = [[NSMutableArray alloc] init];
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare(_database, [query UTF8String], -1, &statement, NULL) == SQLITE_ROW) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            [results addObject:[NSNumber numberWithInt:sqlite3_column_int(statement, 0)]];
        }
    }
    sqlite3_finalize(statement);
    return results;
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
 *              SQLITE_HELPERS
 *
*****************************************************************/

# pragma mark SQLITE_HELPERS

- (BOOL) executeSQLStatement:(const char *)sqlStatement errorMessage:(char*)errorMessage
{
    int counter = 0;
    while(counter < MAX_DB_TRIES) {
        int result = sqlite3_exec(_database, sqlStatement, NULL, NULL, &errorMessage);
        if(result != SQLITE_OK) {
            counter++;
            if(result == SQLITE_BUSY || result == SQLITE_LOCKED) {
                printf("SQLITE_BUSY/LOCKED ERROR IN EXEC: %s\t%s\n", sqlStatement, sqlite3_errmsg(_database));
                [NSThread sleepForTimeInterval:0.01];
            }
            else {
                if(result == SQLITE_CONSTRAINT) {
                    //printf("Duplicate ROWID for insert: %s\n", sqlStatement);
                    return YES;
                }
                else {
                    printf("IN EXEC, ERROR: %s\t%d\t%s\t\n", sqlite3_errmsg(_database), result, sqlStatement);
                }
                return NO;
            }
        }
        else {
            return YES;
        }
    }
    printf("LEFT EXEC SQL STATEMENT AT MAX DB TRIES: %s\n", sqlStatement);
    return NO;
}

- (void) createOtherMessagesTable
{
    //CREATE TABLE %@ (ROWID INTEGER PRIMARY KEY, date INTEGER, wordCount INTEGER, is_from_me INTEGER DEFAULT 0, cache_has_attachments INTEGER
    NSString *createQuery = [NSString stringWithFormat:@"CREATE TABLE %@ (ROWID INTEGER PRIMARY KEY, date INTEGER, wordCount INTEGER, is_from_me INTEGER, cache_has_attachments INTEGER)", otherMessagesTable];
    [self createTable:otherMessagesTable createTableStatement:createQuery];
}

- (void) createMyMessagesTable
{
    NSString *createQuery = [NSString stringWithFormat:@"CREATE TABLE %@ (ROWID INTEGER PRIMARY KEY, guid TEXT UNIQUE NOT NULL, text TEXT, handle_id INTEGER DEFAULT 0, service TEXT, date INTEGER, date_read INTEGER, is_from_me, cache_has_attachments INTEGER DEFAULT 0, wordCount INTEGER)", myMessagesTable];
    [self createTable:myMessagesTable createTableStatement:createQuery];
}

- (void) createTable:(NSString*)tableName createTableStatement:(NSString*)createTableStatement
{
    char *errorMessage;
    if(sqlite3_exec(_database, [createTableStatement UTF8String], NULL, NULL, &errorMessage) == SQLITE_OK) {
        NSLog(@"SUCCESSFULLY CREATED %@", tableName);
    }
    else {
        printf("ERROR CREATING TABLE: %s\t%s\n", [tableName UTF8String], sqlite3_errmsg(_database));
    }
}

- (void) addPragmas
{
    char *errorMessage;
    [self executeSQLStatement:"PRAGMA journal_mode = MEMORY" errorMessage:errorMessage];
    [self executeSQLStatement:"PRAGMA synchronous = OFF" errorMessage:errorMessage];
}

- (const char *)filePath
{
    NSArray *paths=NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentDirectory=[paths objectAtIndex:0];
    return [[documentDirectory stringByAppendingPathComponent:@"LoginDatabase.db"] UTF8String];
}

@end