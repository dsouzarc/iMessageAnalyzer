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

#pragma mark Private variables

@property (strong, nonatomic) FMDatabase *fmDatabase;

@property (strong, nonatomic) NSMutableDictionary *allContacts;
@property (strong, nonatomic) NSMutableDictionary *allChats;

@end

@implementation DatabaseManager


/****************************************************************
 *
 *              Constructor
 *
 *****************************************************************/

# pragma mark Constructor

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
        pathToDB = path;
        
        self.fmDatabase = [FMDatabase databaseWithPath:pathToDB];
        
        if(![self.fmDatabase open]) {
            NSLog(@"ERROR OPENING DATABASE AT PATH: %@", pathToDB);
        } else {
            NSLog(@"DATABASE SUCCESSFULLY OPENED: %@", pathToDB);
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
 *              Handle IDs
 *
 *****************************************************************/

# pragma mark Handle IDs

- (NSMutableSet*) getHandleIDsForMessageText:(NSString*)messageText
{
    NSMutableSet *handleIds = [[NSMutableSet alloc] init];
    
    messageText = [messageText stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
    NSString *query = [NSString stringWithFormat:@"SELECT handle_id from message WHERE text like '%%%@%%' GROUP BY handle_id", messageText];
    
    FMResultSet *result = [self.fmDatabase executeQuery:query];
    
    while([result next]) {
        int handleId = [result intForColumnIndex:0];
        [handleIds addObject:[NSNumber numberWithInt:handleId]];
    }
    
    return handleIds;
}

- (int) getHandleForChatID:(int32_t)chatID
{
    int handleId = -1;

    NSString *query = [NSString stringWithFormat:@"SELECT handle_id FROM chat_handle_join WHERE chat_id=%d", chatID];
    FMResultSet *result = [self.fmDatabase executeQuery:query];
    
    while([result next]) {
        handleId = [result intForColumnIndex:0];
    }
    
    return handleId;
}


- (void) updateHandleIDsForPerson:(Person*)person
{
    //Uninitialized handleID
    if(person.handleID < 0) {
        int handleID = [self getHandleForChatID:(int)person.chatId];
        person.handleID = handleID;
        
        //If there is a secondary chat id, get its handle form
        int handleID2 = person.secondaryChatId < 0 ? handleID : [self getHandleForChatID:(int)person.secondaryChatId];
        person.secondaryHandleId = handleID2;
    }
}


/****************************************************************
 *
 *              Chats
 *
 *****************************************************************/

# pragma mark Chats

- (void) updateAllChatsGlobalVariable
{
    NSString *query = @"SELECT ROWID, guid, account_id, chat_identifier, service_name, group_id, display_name FROM chat";
    
    FMResultSet *result = [self.fmDatabase executeQuery:query];
    
    while([result next]) {
        int chatId = [result intForColumnIndex:0];
        NSString *guid = [result stringForColumnIndex:1];
        NSString *accountID = [result stringForColumnIndex:2];
        
        NSString *chatIdentifier = [result stringForColumnIndex:3];
        NSString *number = [self cleanNumber:chatIdentifier];
        
        NSString *iMessageText = [result stringForColumnIndex:4];
        BOOL isIMessage = [self isIMessage:iMessageText];
        
        NSString *groupID = [result stringForColumnIndex:5];
        NSString *chatName = [result stringForColumnIndex:6];
        
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
            
            if(!name || name.length == 0) {
                name = number;
            }
            
            Person *person = [[Person alloc] initWithChatId:chatId guid:guid accountId:accountID chatIdentifier:chatIdentifier groupId:groupID isIMessage:isIMessage personName:name];
            person.number = number;
            person.contact = abPerson;
            
            [self.allChats setObject:person forKey:number];
        }
    }
}


/****************************************************************
 *
 *              Contacts
 *
 *****************************************************************/

# pragma mark Contacts

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
    
    for(NSNumber *number in handle_ids) {
        NSString *query = [NSString stringWithFormat:@"SELECT id FROM handle WHERE ROWID='%d'", [number intValue]];
        
        FMResultSet *result = [self.fmDatabase executeQuery:query];
        
        while([result next]) {
            NSString *rawNumber = [result stringForColumnIndex:0];
            NSString *number = [self cleanNumber:rawNumber];
            [numbers addObject:number];
        }
    }
    
    return numbers;
}


/****************************************************************
 *
 *              Messages
 *
 *****************************************************************/

# pragma mark Messages

- (int32_t) totalMessagesForStartTime:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds
{
    int result = 0;
    
    NSString *query = [NSString stringWithFormat:@"SELECT count(*) from message WHERE date > %ld AND date < %ld", startTimeInSeconds, endTimeInSeconds];
    FMResultSet *queryResult = [self.fmDatabase executeQuery:query];
    
    while([queryResult next]) {
        result = [queryResult intForColumnIndex:0];
    }
    
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
    
    NSString *query = [NSString stringWithFormat:@"SELECT ROWID, guid, text, service, account_guid, date, date_read, is_from_me, cache_has_attachments, handle_id FROM message messageT INNER JOIN chat_message_join chatMessageT ON (chatMessageT.chat_id=%ld OR chatMessageT.chat_id=%ld) AND messageT.ROWID=chatMessageT.message_id AND (messageT.date > %ld AND messageT.date < %ld) ORDER BY messageT.date", person.chatId, person.secondaryChatId, startTimeInSeconds, endTimeInSeconds];
    
    FMResultSet *result = [self.fmDatabase executeQuery:query];
    
    while([result next]) {
        int messageID = [result intForColumnIndex:0];
        NSString *guid = [result stringForColumnIndex:1];
        
        NSString *text = [result stringForColumnIndex:2];
        if(!text) {
            text = @"";
        }
        
        NSString *iMessageText = [result stringForColumnIndex:3];
        BOOL isIMessage = [self isIMessage:iMessageText];
        
        NSString *accountGUID = [result stringForColumnIndex:4];
        int32_t dateInt = [result intForColumnIndex:5];
        int32_t dateReadInt = [result intForColumnIndex:6];
        
        BOOL isFromMe = [result intForColumnIndex:7] == 1 ? YES : NO;
        BOOL hasAttachment = [result intForColumnIndex:8] == 1 ? YES: NO;
        int handleID =  [result intForColumnIndex:9];
        
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

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person
{
    Statistics *statistics = [[Statistics alloc] init];
    
    NSMutableArray *allMessagesForChat = [self getAllMessagesForPerson:person startTimeInSeconds:0 endTimeInSeconds:LONG_MAX statistics:&statistics];
    person.statistics = statistics;
    
    return allMessagesForChat;
}

- (NSMutableArray*) getTemporaryInformationForAllConversationsExceptWith:(Person*)person
{
    NSMutableArray *temporaryInformation = [[NSMutableArray alloc] init];
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT messageT.ROWID, messageT.date, messageT.text, messageT.is_from_me, messageT.cache_has_attachments FROM message messageT INNER JOIN chat_message_join chatMessageT ON (chatMessageT.chat_id!=%d AND chatMessageT.chat_id!=%d) AND messageT.ROWID=chatMessageT.message_id ORDER BY messageT.date", (int) person.chatId, (int) person.secondaryChatId];

    FMResultSet *result = [self.fmDatabase executeQuery:queryString];
    
    while([result next]) {
        int rowID = [result intForColumnIndex:0];
        int date = [result intForColumnIndex:1];
        
        NSString *text = [result stringForColumnIndex:2];
        if(!text) {
            text = @"";
        }
        int wordCount = (int) [text componentsSeparatedByString:@" "].count;
        
        int isFromMe = [result intForColumnIndex:3];
        int hasAttachments = [result intForColumnIndex:4];
        
        NSDictionary *items = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithInt:rowID], @"ROWID", [NSNumber numberWithInt:date], @"date", [NSNumber numberWithInt:wordCount], @"wordCount", [NSNumber numberWithInt:isFromMe], @"is_from_me", [NSNumber numberWithInt:hasAttachments], @"cache_has_attachments", nil];
        [temporaryInformation addObject:items];
    }
    
    return temporaryInformation;
}

- (NSMutableArray*) getMessagesForHandleId:(int32_t)handleId
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    NSString *query = [NSString stringWithFormat:@"SELECT ROWID, guid, text, handle_id, service, date, date_read, is_from_me, cache_has_attachments FROM message WHERE handle_id = '%d'", handleId];
    
    FMResultSet *queryResult = [self.fmDatabase executeQuery:query];
    
    while([queryResult next]) {
        int rowID = [queryResult intForColumnIndex:0];
        NSString *guid = [queryResult stringForColumnIndex:1];
        NSString *text =  [queryResult stringForColumnIndex:2];
        int handleId = [queryResult intForColumnIndex:3];
        BOOL isIMessage = [self isIMessage:[queryResult stringForColumnIndex:4]];
        int dateInt = [queryResult intForColumnIndex:5];
        int date_readInt = [queryResult intForColumnIndex:6];
        BOOL isFromMe = [queryResult intForColumnIndex:7] == 1;
        BOOL hasAttachment = [queryResult intForColumnIndex:8] == 1 ? YES : NO;
        
        NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:dateInt];
        NSDate *dateRead = date_readInt == 0 ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:date_readInt];
        
        Message *message = [[Message alloc] initWithMessageId:rowID handleId:handleId messageGUID:guid messageText:text dateSent:date dateRead:dateRead isIMessage:isIMessage isFromMe:isFromMe hasAttachment:hasAttachment];
        [result addObject:message];
    }
    
    return result;
}

- (int32_t) messageCountForPerson:(Person*)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds
{
    //const char *query = [[NSString stringWithFormat:@"SELECT count(*) from message WHERE (handle_id=%d OR handle_id=%d) AND date > %ld AND date < %ld", person.handleID, person.secondaryHandleId, startTimeInSeconds, endTimeInSeconds] UTF8String];
    NSString *query = [NSString stringWithFormat:@"SELECT count(*) FROM message messageT INNER JOIN chat_message_join chatMessageT ON (chatMessageT.chat_id=%ld OR chatMessageT.chat_id=%ld) AND messageT.ROWID=chatMessageT.message_id AND (messageT.date > %ld AND messageT.date < %ld) ORDER BY messageT.date", person.chatId, person.secondaryChatId, startTimeInSeconds, endTimeInSeconds];

    int result = 0;
    
    FMResultSet *queryResult = [self.fmDatabase executeQuery:query];
    
    while([queryResult next]) {
        result = [queryResult intForColumnIndex:0];
    }
    
    return result;
}


/****************************************************************
 *
 *             Attachments
 *
 *****************************************************************/

# pragma mark Attachments

- (NSMutableDictionary*) getAllAttachmentsForPerson:(Person*)person
{
    [self updateHandleIDsForPerson:person];
    
    NSMutableDictionary *attachments = [[NSMutableDictionary alloc] init];
    
    //NSString *queryString = [NSString stringWithFormat:@"SELECT messageT.ROWID, messageT.guid, attachmentT.ROWID, attachmentT.guid, attachmentT.filename, attachmentT.mime_type, attachmentT.start_date, attachmentT.total_bytes, attachmentT.transfer_name FROM message messageT INNER JOIN attachment attachmentT INNER JOIN message_attachment_join meAtJoinT ON attachmentT.ROWID= meAtJoinT.attachment_id WHERE meAtJoinT.message_id=messageT.ROWID AND (messageT.handle_id=%d OR messageT.handle_id=%d) GROUP BY messageT.ROWID", person.handleID, person.secondaryHandleId];
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT messageT.ROWID, messageT.guid, attachmentT.ROWID, attachmentT.guid, attachmentT.filename, attachmentT.mime_type, attachmentT.start_date, attachmentT.total_bytes, attachmentT.transfer_name FROM message messageT INNER JOIN chat_message_join chatMessageT ON messageT.ROWID=chatMessageT.message_id INNER JOIN attachment attachmentT INNER JOIN message_attachment_join meAtJoinT ON attachmentT.ROWID=meAtJoinT.attachment_id WHERE meAtJoinT.message_id=messageT.ROWID AND (chatMessageT.chat_id=%ld OR chatMessageT.chat_id=%ld)", person.chatId, person.secondaryChatId];
    
    FMResultSet *result = [self.fmDatabase executeQuery:queryString];
    
    while([result next]) {
        int messageID = [result intForColumnIndex:0];
        NSString *messageGUID = [result stringForColumnIndex:1];
        int attachmentID = [result intForColumnIndex:2];
        NSString *guid = [result stringForColumnIndex:3];
        NSString *filePath = [result stringForColumnIndex:4];
        NSString *fileType = [result stringForColumnIndex:5];
        NSDate *sentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[result intForColumnIndex:6]];
        long fileSize = [result longForColumnIndex:7];
        NSString *fileName = [result stringForColumnIndex:8];
        
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
    
    return attachments;
}

- (NSMutableArray*) getAttachmentsForMessageID:(int32_t)messageID
{
    NSMutableArray *attachments = [[NSMutableArray alloc] init];
    
    NSString *queryString = [NSString stringWithFormat:@"SELECT ROWID, guid, filename, mime_type, start_date, total_bytes, transfer_name FROM attachment t1 INNER JOIN message_attachment_join t2 ON t1.ROWID=t2.attachment_id WHERE t2.message_id=%d", messageID];
    
    FMResultSet *result = [self.fmDatabase executeQuery:queryString];
    
    while([result next]) {
        int attachmentID = [result intForColumnIndex:0];
        NSString *guid = [result stringForColumnIndex:1];
        NSString *filePath = [result stringForColumnIndex:2];
        NSString *fileType = [result stringForColumnIndex:3];
        NSDate *sentDate = [NSDate dateWithTimeIntervalSinceReferenceDate:[result intForColumnIndex:4]];
        long fileSize = [result longForColumnIndex:5];
        NSString *fileName = [result stringForColumnIndex:6];
        
        Attachment *attachment = [[Attachment alloc] initWithAttachmentID:attachmentID attachmentGUID:guid filePath:filePath fileType:fileType sentDate:sentDate attachmentSize:fileSize messageID:messageID fileName:fileName];
        [attachments addObject:attachment];
    }
    
    return attachments;
}


/****************************************************************
 *
 *              Helper methods
 *
 *****************************************************************/

# pragma mark Helper methods

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

- (BOOL) isIMessage:(NSString*)text{
    return [text isEqualToString:@"iMessage"];
}

- (NSMutableArray*) getAllChats
{
    return [[NSMutableArray alloc] initWithArray:[self.allChats allValues]];
}

- (void) deleteDatabase
{
    if([Constants isDevelopmentMode]) {
        [self.fmDatabase close];
        NSLog(@"Closed temporary DB");
        return;
    }
    
    //If we're not dealing with the original or with my copy of it
    if(![pathToDB isEqualToString:[NSString stringWithFormat:@"%@/Library/Messages/chat.db", NSHomeDirectory()]] && ![pathToDB isEqualToString:pathToDevelopmentDB]) {
        NSFileManager *fileManager = [NSFileManager defaultManager];
        [fileManager removeItemAtPath:pathToDB error:NULL];
        NSLog(@"Temporary database deleted");
    }
}

@end