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
@property (strong, nonatomic) NSMutableDictionary *chatsAndMessages;

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
        self.chatsAndMessages = [[NSMutableDictionary alloc] init];
        
        [self updateAllChatsGlobalVariable];
        [self getAllMessagesForChats];
        
        Person *person = [self.allChats objectForKey:@"7323577282"];
        NSLog(@"PERSON: %@", person.personName);
        
        [self getAllMessagesForChatID:person.chatId];
        
        NSLog(@"NAME: %@", [self getContactNameForNumber:@"(609) 915-4930"]);
        //[self getMessagesForHandleId:5];
    }
    
    return self;
}

- (void) getAllMessagesForChats
{
    for(NSString *number in self.chatsAndMessages) {
        Person *person = [self.allChats objectForKey:number];
        NSMutableArray *messagesForPerson = [self getAllMessagesForChatID:person.chatId];
        NSMutableArray *temp = [self.chatsAndMessages objectForKey:number];
        [temp addObjectsFromArray:messagesForPerson];
    }
}

- (NSMutableArray*) getAllChats
{
    return [self.allChats allValues];
}

- (void) updateAllChatsGlobalVariable
{
    const char *query = "SELECT ROWID, guid, account_id, chat_identifier, service_name, group_id FROM chat";
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
            
            Contact *contact = [self.allContacts objectForKey:number];
            NSString *name = contact ? contact.getName : @"";
            ABPerson *abPerson = contact ? contact.person : nil;
            
            Person *person = [[Person alloc] initWithChatId:chatId guid:guid accountId:accountID chatIdentifier:chatIdentifier groupId:groupID isIMessage:isIMessage personName:name];
            person.number = number;
            person.contact = abPerson;
            
            [self.allChats setObject:person forKey:number];
            [self.chatsAndMessages setObject:[[NSMutableArray alloc] init] forKey:number];
        }
    }
    
    sqlite3_finalize(statement);
}

- (int32_t) getHandleForChatID:(int32_t)chatID
{
    char *query = [[NSString stringWithFormat:@"SELECT handle_id FROM chat_handle_join WHERE chat_id=%d", chatID] UTF8String];
    sqlite3_stmt *statement;
    
    int result = 0;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            result = sqlite3_column_int(statement, 0);
        }
    }

    sqlite3_finalize(statement);
    
    return result;
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
        char *query = [[NSString stringWithFormat:@"SELECT ROWID, guid, text, service, account_guid, date, date_read, is_from_me, handle_id FROM message WHERE ROWID=%d", [message_id intValue]] UTF8String];
        
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
                
                NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:dateInt];
                NSDate *dateRead = dateReadInt == 0 ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:dateReadInt];
                
                Message *message = [[Message alloc] initWithMessageId:messageID handleId:handleID messageGUID:guid messageText:text dateSent:date dateRead:dateRead isIMessage:isIMessage isFromMe:isFromMe];
                //printf("%s\n", [text UTF8String]);
            }
        }
        else {
            NSLog(@"ERROR COMPILING ALL MESSAGES QUERY: %s", sqlite3_errmsg(_database));
        }
        
        sqlite3_finalize(statement);
    }
}

- (NSMutableDictionary*) getAllChatsAndConversations
{
    return self.chatsAndMessages;
}

- (NSMutableArray*) getAllMessagesForChatID:(int32_t)chatID
{
    NSMutableArray *allMessagesForChat = [[NSMutableArray alloc] init];
    
    int handleID = [self getHandleForChatID:chatID];
    
    char *query = [[NSString stringWithFormat:@"SELECT ROWID, guid, text, service, account_guid, date, date_read, is_from_me FROM message WHERE handle_id=%d ORDER BY date", handleID] UTF8String];
    sqlite3_stmt *statement;
    
    if(sqlite3_prepare_v2(_database, query, -1, &statement, NULL) == SQLITE_OK) {
        while(sqlite3_step(statement) == SQLITE_ROW) {
            int32_t messageID = sqlite3_column_int(statement, 0);
            NSString *guid = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 1)];
            
            NSString *text = @"";
            
            if(sqlite3_column_text(statement, 2)) {
                text = [NSString stringWithUTF8String:sqlite3_column_text(statement, 2)];//[NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 2)];
            }
            
            NSLog(@"Yo: %@", text);
            BOOL isIMessage = [self isIMessage:sqlite3_column_text(statement, 3)];
            NSString *accountGUID = [NSString stringWithFormat:@"%s", sqlite3_column_text(statement, 4)];
            int32_t dateInt = sqlite3_column_int(statement, 5);
            int32_t dateReadInt = sqlite3_column_int(statement, 6);
            BOOL isFromMe = sqlite3_column_int(statement, 7) == 1 ? YES : NO;
            
            NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:dateInt];
            NSDate *dateRead = dateReadInt == 0 ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:dateReadInt];
            
            Message *message = [[Message alloc] initWithMessageId:messageID handleId:handleID messageGUID:guid messageText:text dateSent:date dateRead:dateRead isIMessage:isIMessage isFromMe:isFromMe];
            
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

- (NSMutableArray*) getMessagesForHandleId:(int32_t)handleId
{
    NSMutableArray *result = [[NSMutableArray alloc] init];
    
    const char *query = [[NSString stringWithFormat:@"SELECT ROWID, guid, text, handle_id, service, date, date_read, is_from_me FROM message WHERE handle_id = '%d'", handleId] UTF8String];
    
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
            
            NSDate *date = [NSDate dateWithTimeIntervalSinceReferenceDate:dateInt];
            NSDate *dateRead = date_readInt == 0 ? nil : [NSDate dateWithTimeIntervalSinceReferenceDate:date_readInt];
            
            Message *message = [[Message alloc] initWithMessageId:rowID handleId:handleId messageGUID:guid messageText:text dateSent:date dateRead:dateRead isIMessage:isIMessage isFromMe:isFromMe];
            [result addObject:message];
        }
    }
    else {
        printf("ERROR GETTING MESSAGES: %s\n", sqlite3_errmsg(_database));
    }
    
    sqlite3_finalize(statement);
    
    return result;
}

- (BOOL) isIMessage:(char*)text {
    return strcmp(text, "iMessage") == 0;
}

@end
