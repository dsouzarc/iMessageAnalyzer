//
//  DatabaseManager.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/8/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "DatabaseManager.h"

static DatabaseManager *databaseInstance;

static NSString *pathToDB = @"/Users/Ryan/FLV MP4/iMessage/mac_chat.db";

@interface DatabaseManager ()

@property sqlite3 *database;

@property (strong, nonatomic) NSMutableDictionary *allContacts;
@property (strong, nonatomic) NSMutableDictionary *allChats;

@end

@implementation DatabaseManager

+ (instancetype) getInstance
{
    @synchronized(self) {
        if(!databaseInstance) {
            databaseInstance = [[self alloc] init];
        }
    }
    
    return databaseInstance;
}

- (instancetype) init
{
    if(!databaseInstance) {
        databaseInstance = [super init];
        
        if(sqlite3_open([pathToDB cStringUsingEncoding:NSASCIIStringEncoding], &_database) == SQLITE_OK) {
            printf("DATABASE SUCCESSFULLY OPENED\n");
        }
        else {
            printf("ERROR OPENING DB: %s", sqlite3_errmsg(_database));
        }
        
        self.allContacts = [[NSMutableDictionary alloc] init];
        [self getAllContacts];
        
        self.allChats = [[NSMutableDictionary alloc] init];
        
        [self updateAllChatsGlobalVariable];
        //[self getMessagesForHandleId:5];
        
        [self getHandleIDsForMessageText:@"Hi"];
    }
    
    return self;
}


/****************************************************************
 *
 *              GET_CONTACTS
 *
*****************************************************************/

# pragma mark GET_CONTACTS

- (NSMutableSet*) getHandleIDsForMessageText:(NSString*)messageText
{
    NSMutableSet *handle_ids = [[NSMutableSet alloc] init];
    
    NSString *query = [NSString stringWithFormat:@"SELECT handle_id from message WHERE text like '%%%@%%' GROUP BY handle_id", messageText];
    
    sqlite3_stmt *statement;
    
    int counter = 0;
    
    if(sqlite3_prepare(_database, [query UTF8String], -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int32_t handle_id = sqlite3_column_int(statement, 0);
            [handle_ids addObject:[NSNumber numberWithInt:handle_id]];
            counter++;
        }
    }
    else {
        NSLog(@"PROBLEM HERE: %s", sqlite3_errmsg(_database));
    }

    sqlite3_finalize(statement);
    
    return handle_ids;
}

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
            BOOL isIMessage = [self isIMessage:sqlite3_column_text(statement, 4)];
            NSString *groupID = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 5)];
            NSString *chatName = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 6)];
            
            Contact *contact = [self.allContacts objectForKey:number];
            NSString *name = contact ? contact.getName : @"";
            
            if(chatName && chatName.length != 0) {
                name = chatName;
            }
            
            ABPerson *abPerson = contact ? contact.person : nil;
            
            if([self.allChats objectForKey:number]) {
                Person *person = [self.allChats objectForKey:number];
                person.secondaryChatId = chatId;
            }
            else {
                Person *person = [[Person alloc] initWithChatId:chatId guid:guid accountId:accountID chatIdentifier:chatIdentifier groupId:groupID isIMessage:isIMessage personName:name];
                person.number = number;
                person.contact = abPerson;
                
                [self.allChats setObject:person forKey:number];
            }
        }
    }
    
    sqlite3_finalize(statement);
}

- (int32_t) getHandleForChatID:(int32_t)chatID
{
    const char *query = [[NSString stringWithFormat:@"SELECT handle_id FROM chat_handle_join WHERE chat_id=%d", chatID] UTF8String];
    sqlite3_stmt *statement;
    
    int result = -1;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            result = sqlite3_column_int(statement, 0);
        }
    }

    sqlite3_finalize(statement);
    
    return result;
}


- (void) updateHandleIDsForPerson:(Person*)person
{
    //Uninitialized handleID
    if(person.handleID < 0) {
        int handleID = [self getHandleForChatID:person.chatId];
        person.handleID = handleID;
        
        //If there is a secondary chat id, get its handle form
        int handleID2 = person.secondaryChatId < 0 ? handleID : [self getHandleForChatID:person.secondaryChatId];
        person.secondaryHandleId = handleID2;
    }
}


- (void) getAllContacts
{
    ABAddressBook *addressBook = [ABAddressBook sharedAddressBook];
    
    for(ABPerson *person in addressBook.people) {
        
        NSString *firstName = [person valueForProperty:kABFirstNameProperty];
        
        //Add the middle name to the first name
        if([person valueForProperty:kABMiddleNameProperty]) {
            firstName = [NSString stringWithFormat:@"%@ %@", firstName, [person valueForProperty:kABMiddleNameProperty]];
        }
        
        NSString *lastName = [person valueForProperty:kABLastNameProperty];
        
        //Save all the phone numbers
        ABMultiValue *phoneValues = [person valueForProperty:kABPhoneProperty];
        if(phoneValues) {
            for(int i = 0; i < phoneValues.count; i++) {
                if([phoneValues valueAtIndex:i]) {
                    NSString *cleanNumber = [self cleanNumber:[phoneValues valueAtIndex:i]];
                    Contact *contact = [[Contact alloc] initWithFirstName:firstName lastName:lastName number:cleanNumber person:person];
                    [self.allContacts setObject:contact forKey:cleanNumber];
                }
            }
        }
        
        //Save all the emails
        ABMultiValue *emailValues = [person valueForProperty:kABEmailProperty];
        if(emailValues) {
            for(int i = 0; i < emailValues.count; i++) {
                if([emailValues valueAtIndex:i]) {
                    NSString *email = [emailValues valueAtIndex:i];
                    //Add it to our dictionary
                    Contact *contact = [[Contact alloc] initWithFirstName:firstName lastName:lastName number:email person:person];
                    [self.allContacts setObject:contact forKey:email];
                }
            }
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
 *              GET MESSAGES
 *
*****************************************************************/

# pragma mark GET_MESSAGES

- (int32_t) totalMessagesForStartTime:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds
{
    const char *query = [[NSString stringWithFormat:@"SELECT count(*) from message WHERE date > %ld AND date < %ld", startTimeInSeconds, endTimeInSeconds] UTF8String];
    
    sqlite3_stmt *statement;
    
    int result = 0;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        result = sqlite3_column_int(statement, 0);
    }
    
    sqlite3_finalize(statement);
    return result;
}

- (int32_t) messageCountForPerson:(Person*)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds
{
    //const char *query = [[NSString stringWithFormat:@"SELECT count(*) from message WHERE (handle_id=%d OR handle_id=%d) AND date > %ld AND date < %ld", person.handleID, person.secondaryHandleId, startTimeInSeconds, endTimeInSeconds] UTF8String];
    const char *query = [[NSString stringWithFormat:@"SELECT count(*) FROM message messageT INNER JOIN chat_message_join chatMessageT ON (chatMessageT.chat_id=%ld OR chatMessageT.chat_id=%ld) AND messageT.ROWID=chatMessageT.message_id AND (messageT.date > %ld AND messageT.date < %ld) ORDER BY messageT.date", person.chatId, person.secondaryChatId, startTimeInSeconds, endTimeInSeconds] UTF8String];
    
    sqlite3_stmt *statement;
    
    int result = 0;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        result = sqlite3_column_int(statement, 0);
    }
    
    sqlite3_finalize(statement);
    return result;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds
{
    Statistics *secondaryStatistics = [[Statistics alloc] init];
    
    NSMutableArray *messages = [self getAllMessagesForPerson:person startTimeInSeconds:startTimeInSeconds endTimeInSeconds:endTimeInSeconds statistics:&secondaryStatistics];
    person.secondaryStatistics = secondaryStatistics;

    return messages;
}

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds statistics:(Statistics**)statisticsPointer
{
    NSMutableArray *allMessagesForChat = [[NSMutableArray alloc] init];
    
    if(*statisticsPointer == nil) {
        *statisticsPointer = [[Statistics alloc] init];
    }
    Statistics *statistics = *statisticsPointer;
    
    const char *query = [[NSString stringWithFormat:@"SELECT ROWID, guid, text, service, account_guid, date, date_read, is_from_me, cache_has_attachments, handle_id FROM message messageT INNER JOIN chat_message_join chatMessageT ON (chatMessageT.chat_id=%ld OR chatMessageT.chat_id=%ld) AND messageT.ROWID=chatMessageT.message_id AND (messageT.date > %ld AND messageT.date < %ld) ORDER BY messageT.date", person.chatId, person.secondaryChatId, startTimeInSeconds, endTimeInSeconds] UTF8String];
    
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int32_t messageID = sqlite3_column_int(statement, 0);
            NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
            
            NSString *text = @"";
            if(sqlite3_column_text(statement, 2)) {
                text = [NSString stringWithUTF8String:sqlite3_column_text(statement, 2)];//[NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 2)];
            }
            
            BOOL isIMessage = [self isIMessage:sqlite3_column_text(statement, 3)];
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
            
            Message *message = [[Message alloc] initWithMessageId:messageID handleId:handleID messageGUID:guid messageText:text dateSent:date dateRead:dateRead isIMessage:isIMessage isFromMe:isFromMe hasAttachment:hasAttachment];
            
            [allMessagesForChat addObject:message];
            
            //printf("%s\n", [text UTF8String]);
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
    
    NSMutableArray *allMessagesForChat = [self getAllMessagesForPerson:person startTimeInSeconds:0 endTimeInSeconds:LONG_MAX statistics:&statistics];
    person.statistics = statistics;
    
    return allMessagesForChat;
}

- (NSMutableArray*) getMessagesForHandleId:(int32_t)handleId
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    const char *query = [[NSString stringWithFormat:@"SELECT ROWID, guid, text, handle_id, service, date, date_read, is_from_me, cache_has_attachments FROM message WHERE handle_id = '%d'", handleId] UTF8String];
    
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int rowID = sqlite3_column_int(statement, 0);
            NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
            NSString *text = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 2)];
            int handleId = sqlite3_column_int(statement, 3);
            BOOL isIMessage = [self isIMessage:sqlite3_column_text(statement, 4)];
            int dateInt = sqlite3_column_int(statement, 5);
            int date_readInt = sqlite3_column_int(statement, 6);
            BOOL isFromMe = sqlite3_column_int(statement, 7) == 1;
            BOOL hasAttachment = sqlite3_column_int(statement, 8) == 1 ? YES : NO;
            
            NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:dateInt];
            NSDate *dateRead = date_readInt == 0 ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:date_readInt];
            
            Message *message = [[Message alloc] initWithMessageId:rowID handleId:handleId messageGUID:guid messageText:text dateSent:date dateRead:dateRead isIMessage:isIMessage isFromMe:isFromMe hasAttachment:hasAttachment];
            [result addObject:message];
        }
    }
    else {
        printf("ERROR GETTING MESSAGES: %s\n", sqlite3_errmsg(_database));
    }
    
    sqlite3_finalize(statement);
    
    return result;
}


/****************************************************************
 *
 *             GET ATTACHMENTS
 *
*****************************************************************/

# pragma mark GET_ATTACHMENTS

- (NSMutableDictionary*) getAllAttachmentsForPerson:(Person*)person
{
    [self updateHandleIDsForPerson:person];
    
    NSMutableDictionary *attachments = [[NSMutableDictionary alloc] init];
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT messageT.ROWID, messageT.guid, attachmentT.ROWID, attachmentT.guid, attachmentT.filename, attachmentT.mime_type, attachmentT.start_date, attachmentT.total_bytes, attachmentT.transfer_name FROM message messageT INNER JOIN attachment attachmentT INNER JOIN message_attachment_join meAtJoinT ON attachmentT.ROWID= meAtJoinT.attachment_id WHERE meAtJoinT.message_id=messageT.ROWID AND (messageT.handle_id=%d OR messageT.handle_id=%d) GROUP BY messageT.ROWID", person.handleID, person.secondaryHandleId];
    
    const char *query = [queryString UTF8String];
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int32_t messageID = sqlite3_column_int(statement, 0);
            NSString *messageGUID = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
            int32_t attachmentID = sqlite3_column_int(statement, 2);
            NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 3)];
            NSString *filePath = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 4)];
            NSString *fileType = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 5)];
            NSDate *sentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:sqlite3_column_int(statement, 6)];
            long fileSize = sqlite3_column_int64(statement, 7);
            NSString *fileName = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 8)];
            
            Attachment *attachment = [[Attachment alloc] initWithAttachmentID:attachmentID attachmentGUID:guid filePath:filePath fileType:fileType sentDate:sentDate attachmentSize:fileSize messageID:messageID fileName:fileName];
            
            //If we do not have any attachments for this message
            if(![attachments objectForKey:messageGUID]) {
                NSMutableArray *attachmentsForMessage = [[NSMutableArray alloc] init];
                [attachmentsForMessage addObject:attachment];
                [attachments setObject:attachmentsForMessage forKey:messageGUID];
            }
            
            //We do have attachments for this message
            else {
                NSMutableArray *attachmentsForMessage = [attachments objectForKey:messageGUID];
                [attachmentsForMessage addObject:attachment];
            }
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
            NSDate *sentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:sqlite3_column_int(statement, 4)];
            long fileSize = sqlite3_column_int64(statement, 5);
            NSString *fileName = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 6)];
            
            Attachment *attachment = [[Attachment alloc] initWithAttachmentID:attachmentID attachmentGUID:guid filePath:filePath fileType:fileType sentDate:sentDate attachmentSize:fileSize messageID:messageID fileName:fileName];
            [attachments addObject:attachment];
        }
    }
    
    sqlite3_finalize(statement);

    return attachments;
}


/****************************************************************
 *
 *              MISC_METHODS
 *
*****************************************************************/

# pragma mark MISC_METHODS

- (NSString*) cleanNumber:(NSString*)originalNumber
{
    NSCharacterSet *removeChars = [NSCharacterSet characterSetWithCharactersInString:@" ()-+"];
    NSString *newNumber = [[originalNumber componentsSeparatedByCharactersInSet:removeChars] componentsJoinedByString:@""];
    
    if([newNumber characterAtIndex:0] == '1') {
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

- (BOOL) isIMessage:(char*)text {
    return strcmp(text, "iMessage") == 0;
}

- (NSMutableArray*) getAllChats
{
    return [self.allChats allValues];
}

/** Slow - gets every message_id associated with a handle_id
 searches the messages db for everything associated with that handle */
- (void) getSequentialMessagesForChatID:(int32_t)chatID
{
    NSMutableArray *messageIDs = [[NSMutableArray alloc] init];
    
    char *query = [[NSString stringWithFormat:@"SELECT message_id FROM chat_message_join WHERE chat_id=%d", chatID] UTF8String];
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int32_t message_id = sqlite3_column_int(statement, 0);
            [messageIDs addObject:[NSNumber numberWithInt:message_id]];
        }
    }
    
    sqlite3_finalize(statement);
    
    for(NSNumber *message_id in messageIDs) {
        char *query = [[NSString stringWithFormat:@"SELECT ROWID, guid, text, service, account_guid, date, date_read, is_from_me, handle_id, cache_has_attachments FROM message WHERE ROWID=%d", [message_id intValue]] UTF8String];
        
        if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
            while(sqlite3_step(statement) == SQLITE_ROW) {
                int32_t messageID = sqlite3_column_int(statement, 0);
                NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
                NSString *text = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 2)];
                BOOL isIMessage = [self isIMessage:sqlite3_column_text(statement, 3)];
                NSString *accountGUID = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 4)];
                int32_t dateInt = sqlite3_column_int(statement, 5);
                int32_t dateReadInt = sqlite3_column_int(statement, 6);
                BOOL isFromMe = sqlite3_column_int(statement, 7) == 1 ? YES : NO;
                int32_t handleID = sqlite3_column_int(statement, 8);
                BOOL hasAttachment = sqlite3_column_int(statement, 9) == 1 ? YES : NO;
                
                NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:dateInt];
                NSDate *dateRead = dateReadInt == 0 ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:dateReadInt];
                
                Message *message = [[Message alloc] initWithMessageId:messageID handleId:handleID messageGUID:guid messageText:text dateSent:date dateRead:dateRead isIMessage:isIMessage isFromMe:isFromMe hasAttachment:hasAttachment];
                //printf("%s\n", [text UTF8String]);
            }
        }
        else {
            NSLog(@"ERROR COMPILING ALL MESSAGES QUERY: %s", sqlite3_errmsg(_database));
        }
        
        sqlite3_finalize(statement);
    }
}

@end