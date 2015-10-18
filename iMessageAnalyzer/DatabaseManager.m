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
        
        [self getContactNameForNumber:@"(609) 915-4930"];
        //[self getMessagesForHandleId:5];
    }
    
    return self;
}

- (void) getAllContacts
{
    ABAddressBook *addressBook = [ABAddressBook sharedAddressBook];
 
    for(ABPerson *person in addressBook.people) {
        
        NSString *firstName = [person valueForProperty:kABFirstNameProperty];
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
    NSCharacterSet *removeChars = [NSCharacterSet characterSetWithCharactersInString:@" ()-"];
    return [[originalNumber componentsSeparatedByCharactersInSet:removeChars] componentsJoinedByString:@""];
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
    
    return result;
}

- (BOOL) isIMessage:(char*)text {
    return strcmp(text, "iMessage") == 0;
}

@end
