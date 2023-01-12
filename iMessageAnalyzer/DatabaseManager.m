//
//  DatabaseManager.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/8/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "DatabaseManager.h"

static DatabaseManager *databaseInstance;
static NSString *pathToDB;

@interface DatabaseManager ()

# pragma mark - Private variables

@property sqlite3 *database;

@property (strong, nonatomic) NSMutableDictionary *allContacts;
@property (strong, nonatomic) NSMutableDictionary *allChats;

@end

@implementation DatabaseManager


/****************************************************************
 *
 *              Constructor
 *
*****************************************************************/

# pragma mark - Constructor

+ (instancetype) getInstance
{
    @synchronized(self) {
        if(!databaseInstance) {
            if([Constants isDevelopmentMode]) {
                pathToDB = pathToDevelopmentDB;
            }
            else {
                pathToDB = [NSString stringWithFormat:@"%@/Library/Messages/chat.db", NSHomeDirectory()];
            }
            databaseInstance = [[self alloc] initWithDatabasePath:pathToDB];
        }
    }
    
    return databaseInstance;
}

+ (instancetype) getInstanceForDatabasePath:(NSString *)path
{
    @synchronized(self) {
        if(!databaseInstance) {
            databaseInstance = [[self alloc] initWithDatabasePath:path];
        }
    }
    
    return databaseInstance;
}

- (instancetype) initWithDatabasePath:(NSString*)path
{
    if(!databaseInstance) {
        databaseInstance = [super init];
        
        if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
            NSLog(@"ERROR FINDING DATABASE: %@\n", path);
        }
        else if(sqlite3_open([path UTF8String], &_database) == SQLITE_OK) {
            printf("DATABASE SUCCESSFULLY OPENED: %s\n", [path UTF8String]);
        }
        else {
            printf("ERROR OPENING DB: %s", sqlite3_errmsg(_database));
        }
        
        self.allContacts = [[NSMutableDictionary alloc] init];
        [self getAllContacts];
        
        self.allChats = [[NSMutableDictionary alloc] init];
        
        [self updateAllChatsGlobalVariable];
        //[self getMessagesForHandleId:5];
        
        //[self getHandleIDsForMessageText:@"Hi"];
    }
    
    return self;
}


/****************************************************************
 *
 *              Handle IDs
 *
*****************************************************************/

# pragma mark - Handle IDs

- (NSMutableSet*) getHandleIDsForMessageText:(NSString*)messageText
{
    NSMutableSet *handle_ids = [[NSMutableSet alloc] init];
    
    messageText = [messageText stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    NSString *query = [NSString stringWithFormat:@"SELECT handle_id from message WHERE text like '%%%@%%' GROUP BY handle_id", messageText];
    
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare(_database, [query UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int32_t handle_id = sqlite3_column_int(statement, 0);
            [handle_ids addObject:[NSNumber numberWithInt:handle_id]];
        }
    }
    else {
        NSLog(@"PROBLEM HERE: %s\t%@", sqlite3_errmsg(_database), query);
    }

    sqlite3_finalize(statement);
    
    return handle_ids;
}

- (NSMutableSet*) getHandleIDsForChatIDs:(NSMutableSet*)chatIDs
{
    NSMutableSet *handleIDs = [[NSMutableSet alloc] init];
    
    NSString *chatIDsString = [[chatIDs allObjects] componentsJoinedByString:@","];
    NSString *query = [NSString stringWithFormat:@"SELECT handle_id FROM chat_handle_join WHERE chat_id IN (%@)", chatIDsString];
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int handleID = sqlite3_column_int(statement, 0);
            [handleIDs addObject:[NSNumber numberWithInt:handleID]];
        }
    }
    
    sqlite3_finalize(statement);
    
    return handleIDs;
}


- (void) updateHandleIDsForPerson:(Person*)person
{
    person.handleIDs = [self getHandleIDsForChatIDs:person.chatIDs];
}


/****************************************************************
 *
 *              Chats
 *
*****************************************************************/

# pragma mark - Chats

- (void) updateAllChatsGlobalVariable
{
    const char *query = "SELECT ROWID, guid, account_id, chat_identifier, service_name, group_id, display_name FROM chat";
    sqlite3_stmt *statement;

    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int chatId = sqlite3_column_int(statement, 0);
            NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
            NSString *accountID = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 2)];
            NSString *chatIdentifier = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 3)];
            NSString *number = [self cleanNumber:chatIdentifier];
            const unsigned char *isIMessage = sqlite3_column_text(statement, 4);
            NSString *groupID = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 5)];
            NSString *chatName = [NSString stringWithFormat:@"%s", sqlite3_column_text16(statement, 6)];
            
            Contact *contact = [self.allContacts objectForKey:number];
            NSString *name = contact ? contact.getName : @"";
            
            if(chatName && chatName.length != 0) {
                name = chatName;
            }
            
            ABPerson *abPerson = contact ? contact.person : nil;
            
            if([self.allChats objectForKey:number]) {
                Person *person = [self.allChats objectForKey:number];
                [person.chatIDs addObject:[NSNumber numberWithInteger:chatId]];
            }
            else {
                
                if(!name || [name length] == 0) {
                    name = number;
                }
                
                Person *person = [[Person alloc] initWithChatId:chatId guid:guid accountId:accountID
                                                 chatIdentifier:chatIdentifier groupId:groupID
                                                     isIMessage:isIMessage personName:name];
                person.number = number;
                person.contact = abPerson;
                
                [self.allChats setObject:person forKey:number];
            }
        }
    }
    
    sqlite3_finalize(statement);
}


/****************************************************************
 *
 *              Contacts
 *
*****************************************************************/

# pragma mark - Contacts

- (void) getAllContacts
{
    ABAddressBook *addressBook = [ABAddressBook sharedAddressBook];
    
    for(ABPerson *person in addressBook.people) {
        
        NSString *firstName = [person valueForProperty:kABFirstNameProperty];
        NSString *lastName = [person valueForProperty:kABLastNameProperty];
        
        
        //Add the middle name to the first name
        @try {
            if([person valueForProperty:kABMiddleNameProperty]) {
                firstName = [NSString stringWithFormat:@"%@ %@", firstName, [person valueForProperty:kABMiddleNameProperty]];
            }
        }
        @catch(NSException *exception) {
            //No middle name - not a big deal
        }
        
        
        //Save all the phone numbers
        @try {
            ABMultiValue *phoneValues = [person valueForProperty:kABPhoneProperty];
            
            for(int i = 0; i < [phoneValues count]; i++) {
                if([phoneValues valueAtIndex:i]) {
                    NSString *cleanNumber = [self cleanNumber:[phoneValues valueAtIndex:i]];
                    Contact *contact = [[Contact alloc] initWithFirstName:firstName
                                                                 lastName:lastName
                                                                   number:cleanNumber
                                                                   person:person];
                    [self.allContacts setObject:contact forKey:cleanNumber];
                }
            }
        }
        @catch(NSException *exception) {
            //No phone numbers - that's fine
        }
        

        //Save all the emails
        @try {
            ABMultiValue *emailValues = [person valueForProperty:kABEmailProperty];
            
            for(int i = 0; i < emailValues.count; i++) {
                if([emailValues valueAtIndex:i]) {
                    NSString *email = [emailValues valueAtIndex:i];
                    Contact *contact = [[Contact alloc] initWithFirstName:firstName
                                                                 lastName:lastName
                                                                   number:email
                                                                   person:person];
                    [self.allContacts setObject:contact forKey:email];
                }
            }
        }
        @catch(NSException *exception) {
            //No email addresses - that's fine
        }
    }
}

- (NSMutableArray*) getAllNumbersForSearchText:(NSString*)text
{
    NSMutableArray *numbers = [[NSMutableArray alloc] init];
    NSArray *handle_ids = [[self getHandleIDsForMessageText:text] allObjects];
    
    sqlite3_stmt *statement;
    
    for(NSNumber *number in handle_ids) {
        const char *query = [[NSString stringWithFormat:@"SELECT id FROM handle WHERE ROWID='%d'", [number intValue]] UTF8String];
        
        if(sqlite3_prepare(_database, query, -1, &statement, NULL) == SQLITE_OK) {
            while(sqlite3_step(statement) == SQLITE_ROW) {
                NSString *number = [self cleanNumber:[NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 0)]];
                [numbers addObject:number];
            }
        }
        else {
            NSLog(@"ERROR: %s", sqlite3_errmsg(_database));
        }
        
        sqlite3_finalize(statement);
    }
    
    return numbers;
}


/****************************************************************
 *
 *              Messages
 *
*****************************************************************/

# pragma mark - Messages

- (int32_t) totalMessagesForStartTime:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds
{
    const char *query = [[NSString stringWithFormat:@"SELECT count(*) from message WHERE date > %ld AND date < %ld",
                          startTimeInSeconds, endTimeInSeconds] UTF8String];
    
    sqlite3_stmt *statement;
    
    int result = 0;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        result = sqlite3_column_int(statement, 0);
    }
    
    sqlite3_finalize(statement);
    return result;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person
                         startTimeInSeconds:(long)startTimeInSeconds
                           endTimeInSeconds:(long)endTimeInSeconds
{
    Statistics *secondaryStatistics = [[Statistics alloc] init];
    
    NSMutableArray *messages = [self getAllMessagesForPerson:person
                                          startTimeInSeconds:startTimeInSeconds
                                            endTimeInSeconds:endTimeInSeconds
                                                  statistics:&secondaryStatistics];
    person.secondaryStatistics = secondaryStatistics;

    return messages;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person
                         startTimeInSeconds:(long)startTimeInSeconds
                           endTimeInSeconds:(long)endTimeInSeconds
                                 statistics:(Statistics**)statisticsPointer
{
    NSMutableArray *allMessagesForChat = [[NSMutableArray alloc] init];
    person.messageIDToIndexMapping = [[NSMutableDictionary alloc] init];
    
    if(*statisticsPointer == nil) {
        *statisticsPointer = [[Statistics alloc] init];
    }
    Statistics *statistics = *statisticsPointer;
    
    NSString *chatIDsString = [[person.chatIDs allObjects] componentsJoinedByString:@","];
    
    NSString *query = [NSString stringWithFormat:@"SELECT ROWID, guid, text, service, account_guid, "
                                                            //NOTE: This handles the timestamp change (As of Feb 2018, Apple uses 18+ digits)
                                                            "CASE WHEN LENGTH(date) >= 18 "
                                                                    "THEN (date / 1000000000) "
                                                                "ELSE date END AS adjusted_date, "
                                                            "date_read, is_from_me, cache_has_attachments, handle_id, attributedBody "
                                                    "FROM message AS messageT "
                                                    "INNER JOIN chat_message_join AS chatMessageT "
                                                        "ON chatMessageT.chat_id IN (%@) "
                                                                "AND messageT.ROWID = chatMessageT.message_id "
                                                                "AND adjusted_date BETWEEN %ld AND %ld "
                                                    "ORDER BY adjusted_date",
                                                chatIDsString, startTimeInSeconds, endTimeInSeconds];

    sqlite3_stmt *statement;
    int counter = 0;
    
    if(sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            
            int32_t messageID = sqlite3_column_int(statement, 0);
            NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
            
            NSString *text = @"";
            if(sqlite3_column_text(statement, 2) != NULL) {
                text = [NSString stringWithUTF8String: (const char*) sqlite3_column_text(statement, 2)];
            } else {
                const void *blob = sqlite3_column_blob(statement, 10);
                int blob_size = sqlite3_column_bytes(statement, 10);
                                
                NSData *data = [NSData dataWithBytes:blob length:blob_size];
                
                const char *bytes = [data bytes];
                char hexBuffer[2 * [data length] + 1]; // a buffer 2 times the size of data + 1 null character
                int len = 0;
                for (int i = 0; i < [data length]; i++) {
                    len += sprintf(hexBuffer + len, "%02x", bytes[i] & 0xff);
                }
                NSString* hexString = [NSString stringWithUTF8String:hexBuffer];
                NSRange range = [hexString rangeOfString:@"4e53537472696e67"];
                if (range.location != NSNotFound) {
                    hexString = [hexString substringFromIndex:range.location + range.length];
                    hexString = [hexString substringFromIndex:12];
                }
                range = [hexString rangeOfString:@"8684"];
                if (range.location != NSNotFound) {
                    hexString = [hexString substringToIndex:range.location];
                }
                //            hexString = [hexString stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSMutableData *newData= [[NSMutableData alloc] init];
                unsigned char whole_byte;
                char byte_chars[3] = {'\0','\0','\0'};
                int i;
                for (i=0; i < [hexString length]/2; i++) {
                    byte_chars[0] = [hexString characterAtIndex:i*2];
                    byte_chars[1] = [hexString characterAtIndex:i*2+1];
                    whole_byte = strtol(byte_chars, NULL, 16);
                    [newData appendBytes:&whole_byte length:1];
                }
                NSString *result = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
                if (result) {
                    text = result;
                }
            }
            
            const unsigned char *isIMessage = sqlite3_column_text(statement, 3);
            NSString *accountGUID = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 4)];
            
            int32_t dateInt = sqlite3_column_int(statement, 5);
            int32_t dateReadInt = sqlite3_column_int(statement, 6);
            
            BOOL isFromMe = sqlite3_column_int(statement, 7) == 1 ? YES : NO;
            BOOL hasAttachment = sqlite3_column_int(statement, 8) == 1 ? YES: NO;
            int32_t handleID = sqlite3_column_int(statement, 9);
            
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
            
            Message *message = [[Message alloc] initWithMessageId:messageID handleId:handleID
                                                      messageGUID:guid messageText:text dateSent:date
                                                         dateRead:dateRead isIMessage:isIMessage
                                                         isFromMe:isFromMe hasAttachment:hasAttachment];
            
            [allMessagesForChat addObject:message];
            [person.messageIDToIndexMapping setObject:@(counter) forKey:guid];
            counter += 1;
        }
    }
    else {
        NSLog(@"ERROR COMPILING ALL MESSAGES QUERY: %s", sqlite3_errmsg(_database));
    }

    sqlite3_finalize(statement);
    
    return allMessagesForChat;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person
{
    Statistics *statistics = [[Statistics alloc] init];
    
    NSMutableArray *allMessagesForChat = [self getAllMessagesForPerson:person startTimeInSeconds:0
                                                       endTimeInSeconds:LONG_MAX statistics:&statistics];
    person.statistics = statistics;
    
    return allMessagesForChat;
}

- (NSMutableArray*) getTemporaryInformationForAllConversationsExceptWith:(Person*)person
{
    NSMutableArray *temporaryInformation = [[NSMutableArray alloc] init];
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT messageT.ROWID, "
                                                                "CASE WHEN LENGTH(messageT.date) >= 18 "
                                                                    "THEN (messageT.date / 1000000000) "
                                                                    "ELSE messageT.date END, "
                                                                "messageT.text, messageT.is_from_me, "
                                                                "messageT.cache_has_attachments "
                                                            "FROM message messageT "
                                                            "INNER JOIN chat_message_join chatMessageT "
                                                                "ON chatMessageT.chat_id NOT IN (%@) "
                                                                     "AND messageT.ROWID = chatMessageT.message_id "
                                                             "ORDER BY messageT.date",
                                                     [person getChatIDsString]];
    sqlite3_stmt *statement;
    
    /*if(sqlite3_open([pathToDB UTF8String], &_database) == SQLITE_OK){
        //Temporary fix - need to do this for OSX Sierra for some reason
    } else {
        NSLog(@"Error opening database");
    } */
    
    if(sqlite3_prepare(_database, [queryString UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int rowID = sqlite3_column_int(statement, 0);
            int date = sqlite3_column_int(statement, 1);
            NSString *text = @"";
            
            const char *messageTextChar = (const char *)sqlite3_column_text(statement, 2);
            if(messageTextChar != NULL) {
                text = [NSString stringWithUTF8String:messageTextChar];
            }
            
            int wordCount = (int) [text componentsSeparatedByString:@" "].count;
            int isFromMe = sqlite3_column_int(statement, 3);
            int hasAttachments = sqlite3_column_int(statement, 4);
            
            NSDictionary *items = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:rowID], @"ROWID",
                                                                           [NSNumber numberWithInt:date], @"date",
                                                                           [NSNumber numberWithInt:wordCount], @"wordCount",
                                                                           [NSNumber numberWithInt:isFromMe], @"is_from_me",
                                                                           [NSNumber numberWithInt:hasAttachments], @"cache_has_attachments",
                                                                           nil];
            [temporaryInformation addObject:items];
        }
    }
    
    sqlite3_finalize(statement);
    
    return temporaryInformation;
}

- (NSMutableArray*) getMessagesForHandleId:(int32_t)handleId
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    const char *query = [[NSString stringWithFormat:@"SELECT ROWID, guid, text, handle_id, service, "
                                                                "CASE WHEN LENGTH(date) >= 18 "
                                                                    "THEN (date / 1000000000) "
                                                                    "ELSE date END, "
                                                                "date_read, is_from_me, cache_has_attachments "
                                                        "FROM message"
                                                            "WHERE handle_id = '%d'", handleId] UTF8String];
    
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int rowID = sqlite3_column_int(statement, 0);
            NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
            NSString *text = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 2)];
            int handleId = sqlite3_column_int(statement, 3);
            const unsigned char *isIMessage = sqlite3_column_text(statement, 4);
            int32_t dateInt = sqlite3_column_int(statement, 5);
            int32_t dateReadInt = sqlite3_column_int(statement, 6);
            BOOL isFromMe = sqlite3_column_int(statement, 7) == 1;
            BOOL hasAttachment = sqlite3_column_int(statement, 8) == 1 ? YES : NO;
            
            NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:dateInt];
            NSDate *dateRead = dateReadInt == 0 ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:dateReadInt];
            
            Message *message = [[Message alloc] initWithMessageId:rowID handleId:handleId messageGUID:guid
                                                      messageText:text dateSent:date dateRead:dateRead
                                                       isIMessage:isIMessage isFromMe:isFromMe hasAttachment:hasAttachment];
            [result addObject:message];
        }
    }
    else {
        printf("ERROR GETTING MESSAGES: %s\n", sqlite3_errmsg(_database));
    }
    
    sqlite3_finalize(statement);
    
    return result;
}

- (int32_t) messageCountForPerson:(Person*)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds
{
    NSString *query = [NSString stringWithFormat:@"SELECT COUNT(ROWID) "
                                                           "FROM message AS messageT "
                                                       "INNER JOIN chat_message_join AS chatMessageT "
                                                           "ON chatMessageT.chat_id IN (%@) "
                                                               "AND messageT.ROWID=chatMessageT.message_id "
                                                               "AND (CASE "
                                                                    "WHEN LENGTH(date) >= 18 "
                                                                    "THEN date / 1000000000 "
                                                                    "ELSE date "
                                                                "END) "
                                                                "BETWEEN %ld AND %ld "
                                                        "ORDER BY date",
                       [person getChatIDsString], startTimeInSeconds, endTimeInSeconds];

    sqlite3_stmt *statement;
    
    int result = 0;
    if(sqlite3_prepare_v2(_database, [query UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        result = sqlite3_column_int(statement, 0);
    }
    
    sqlite3_finalize(statement);
    return result;
}

- (NSMutableArray*) getMessageGUIDsForText:(NSString*)searchText handleIDs:(NSMutableSet*)handleIDs
{
    NSMutableArray *messageGUIDs = [[NSMutableArray alloc] init];
    
    NSString *query = [NSString stringWithFormat:@"SELECT guid "
                                                           "FROM message "
                                                       "WHERE handle_id IN (%@) AND text LIKE '%%%@%%';",
                                   [[handleIDs allObjects] componentsJoinedByString:@","], searchText];
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare(_database, [query UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            NSString *messageGUID = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 0)];
            [messageGUIDs addObject:messageGUID];
        }
    }
    
    return messageGUIDs;
}

- (int32_t) getTotalMessageCount
{
    const char *query2 = "SELECT count(*) from message";
    sqlite3_stmt *statement;
    int32_t totalMessageCount = 0;
    
    if(sqlite3_prepare(_database, query2, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            totalMessageCount = sqlite3_column_int(statement, 0);
        }
    }
    sqlite3_finalize(statement);
    return totalMessageCount;
}


/****************************************************************
 *
 *             Attachments
 *
*****************************************************************/

# pragma mark - Attachments

- (NSMutableDictionary*) getAllAttachmentsForPerson:(Person*)person
{
    //Uninitialized handleID
    if([person.handleIDs count] == 0) {
        [self updateHandleIDsForPerson:person];
    }
    
    NSMutableDictionary *attachments = [[NSMutableDictionary alloc] init];
    
    //NSString *queryString = [NSString stringWithFormat:@"SELECT messageT.ROWID, messageT.guid, attachmentT.ROWID, attachmentT.guid, attachmentT.filename, attachmentT.mime_type, attachmentT.start_date, attachmentT.total_bytes, attachmentT.transfer_name FROM message messageT INNER JOIN attachment attachmentT INNER JOIN message_attachment_join meAtJoinT ON attachmentT.ROWID= meAtJoinT.attachment_id WHERE meAtJoinT.message_id=messageT.ROWID AND (messageT.handle_id=%d OR messageT.handle_id=%d) GROUP BY messageT.ROWID", person.handleID, person.secondaryHandleId];
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT messageT.ROWID, messageT.guid, attachmentT.ROWID, attachmentT.guid, "
                                                                     "attachmentT.filename, attachmentT.mime_type, attachmentT.start_date, "
                                                                     "attachmentT.total_bytes, attachmentT.transfer_name "
                                                                 "FROM message AS messageT "
                                                             "INNER JOIN chat_message_join AS chatMessageT "
                                                                 "ON chatMessageT.chat_id IN (%@) "
                                                                    "AND messageT.ROWID = chatMessageT.message_id "
                                                             "INNER JOIN attachment AS attachmentT "
                                                             "INNER JOIN message_attachment_join AS meAtJoinT "
                                                                 "ON attachmentT.ROWID = meAtJoinT.attachment_id "
                                                                     "AND meAtJoinT.message_id = messageT.ROWID ",
                                                             [person getChatIDsString]];

    sqlite3_stmt *statement;
    
    /*if(sqlite3_open([pathToDB UTF8String], &_database) == SQLITE_OK){
        //Temporary fix - need to do this for OSX Sierra for some reason
    } else {
        NSLog(@"ERROR OPENING DATABASE");
    }*/
    
    if(sqlite3_prepare(_database, [queryString UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int32_t messageID = sqlite3_column_int(statement, 0);
            NSString *messageGUID = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
            int32_t attachmentID = sqlite3_column_int(statement, 2);
            NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 3)];
            NSString *filePath = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 4)];
            NSString *fileType = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 5)];
            
            int32_t sentTimestamp = sqlite3_column_int(statement, 6);
            NSDate *sentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:sentTimestamp];
            
            long fileSize = sqlite3_column_int64(statement, 7);
            NSString *fileName = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 8)];
            
            Attachment *attachment = [[Attachment alloc] initWithAttachmentID:attachmentID attachmentGUID:guid
                                                                     filePath:filePath fileType:fileType
                                                                     sentDate:sentDate attachmentSize:fileSize
                                                                    messageID:messageID fileName:fileName];
            
            NSMutableArray *attachmentsForMessage = [attachments objectForKey:messageGUID];
            if(!attachmentsForMessage) {
                attachmentsForMessage = [[NSMutableArray alloc] init];
                [attachments setObject:attachmentsForMessage forKey:messageGUID];
            }
            [attachmentsForMessage addObject:attachment];
        }
    }
    
    sqlite3_finalize(statement);
    
    return attachments;
}

- (NSMutableArray*) getAttachmentsForMessageID:(int32_t)messageID
{
    NSMutableArray *attachments = [[NSMutableArray alloc] init];
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT ROWID, guid, filename, mime_type, start_date, total_bytes, transfer_name FROM attachment t1 INNER JOIN message_attachment_join t2 ON t1.ROWID=t2.attachment_id WHERE t2.message_id=%d", messageID];
    const char *query = [queryString UTF8String];
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int32_t attachmentID = sqlite3_column_int(statement, 0);
            NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
            NSString *filePath = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 2)];
            NSString *fileType = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 3)];
            
            int32_t sentTimestamp = sqlite3_column_int(statement, 4);
            NSDate *sentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:sentTimestamp];
            long fileSize = sqlite3_column_int64(statement, 5);
            NSString *fileName = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 6)];
            
            Attachment *attachment = [[Attachment alloc] initWithAttachmentID:attachmentID
                                                               attachmentGUID:guid filePath:filePath
                                                                     fileType:fileType sentDate:sentDate
                                                               attachmentSize:fileSize messageID:messageID fileName:fileName];
            [attachments addObject:attachment];
        }
    }
    
    sqlite3_finalize(statement);

    return attachments;
}


/****************************************************************
 *
 *              Helper methods
 *
*****************************************************************/

# pragma mark - Helper methods

- (NSString*) cleanNumber:(NSString*)originalNumber
{
    NSCharacterSet *removeChars = [NSCharacterSet characterSetWithCharactersInString:@" ()-+"];
    NSString *newNumber = [[originalNumber componentsSeparatedByCharactersInSet:removeChars] componentsJoinedByString:@""];
    
    if([newNumber length] > 0 && [newNumber characterAtIndex:0] == '1') {
        newNumber = [newNumber substringFromIndex:1];
    }
    
    return newNumber;
}

- (NSString*) getContactNameForNumber:(NSString*)phoneNumber
{
    Contact *contact = [self.allContacts objectForKey:[self cleanNumber:phoneNumber]];
    
    if(contact) {
        return [contact getName];
    }
    else {
        return @"";
    }
}

- (NSMutableArray*) getAllChats
{
    return [NSMutableArray arrayWithArray:[self.allChats allValues]];
}

/** Deprecated */
- (void) getSequentialMessagesForChatID:(int32_t)chatID
{
    NSMutableArray *messageIDs = [[NSMutableArray alloc] init];
    
    const char *query = [[NSString stringWithFormat:@"SELECT message_id FROM chat_message_join WHERE chat_id=%d", chatID] UTF8String];
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int32_t message_id = sqlite3_column_int(statement, 0);
            [messageIDs addObject:[NSNumber numberWithInt:message_id]];
        }
    }
    
    sqlite3_finalize(statement);
    
    for(NSNumber *message_id in messageIDs) {
        const char *query = [[NSString stringWithFormat:@"SELECT ROWID, guid, text, service, account_guid, date, date_read, is_from_me, handle_id, cache_has_attachments FROM message WHERE ROWID=%d", [message_id intValue]] UTF8String];
        
        if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
            while(sqlite3_step(statement) == SQLITE_ROW) {
                int32_t messageID = sqlite3_column_int(statement, 0);
                NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
                NSString *text = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 2)];
                const unsigned char *isIMessage = sqlite3_column_text(statement, 3);
                NSString *accountGUID = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 4)];
                int32_t dateInt = sqlite3_column_int(statement, 5);
                int32_t dateReadInt = sqlite3_column_int(statement, 6);
                BOOL isFromMe = sqlite3_column_int(statement, 7) == 1 ? YES : NO;
                int32_t handleID = sqlite3_column_int(statement, 8);
                BOOL hasAttachment = sqlite3_column_int(statement, 9) == 1 ? YES : NO;
                
                NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:dateInt];
                NSDate *dateRead = dateReadInt == 0 ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:dateReadInt];
                
                Message *message = [[Message alloc] initWithMessageId:messageID handleId:handleID
                                                          messageGUID:guid messageText:text dateSent:date
                                                             dateRead:dateRead isIMessage:isIMessage
                                                             isFromMe:isFromMe hasAttachment:hasAttachment];
                //printf("%s\n", [text UTF8String]);
            }
        }
        else {
            NSLog(@"ERROR COMPILING ALL MESSAGES QUERY: %s", sqlite3_errmsg(_database));
        }
        
        sqlite3_finalize(statement);
    }
}

- (void) deleteDatabase
{
    if([Constants isDevelopmentMode]) {
        sqlite3_close(self.database);
        NSLog(@"Closed temporary DB");
        return;
    }
    
    //If we're not dealing with the original
    if(![pathToDB isEqualToString:[NSString stringWithFormat:@"%@/Library/Messages/chat.db", NSHomeDirectory()]]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:pathToDB error:NULL];
        NSLog(@"Temporary database deleted");
    }
}

@end
