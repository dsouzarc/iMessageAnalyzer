//
//  Message.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/6/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "Message.h"

static NSDateFormatter *dateFormatter;

@implementation Message


- (instancetype) initWithMessageId:(NSInteger)messageId handleId:(NSInteger)handleId messageGUID:(NSString *)messageGUID messageText:(NSString *)messageText dateSent:(NSDate *)dateSent dateRead:(NSDate *)dateRead isIMessage:(BOOL)isIMessage isFromMe:(BOOL)isFromMe hasAttachment:(BOOL)hasAttachment
{
    self = [super init];
    
    if(self) {
        
        if(!dateFormatter) {
            dateFormatter = [[NSDateFormatter alloc] init];
            [dateFormatter setDateFormat:@"HH:mm MM/dd/yyyy"];
        }
        
        self.messageId = messageId;
        self.handleId = handleId;
        self.messageGUID = messageGUID;
        self.messageText = messageText;
        self.dateSent = dateSent;
        self.dateRead = dateRead;
        self.isIMessage = isIMessage;
        self.isFromMe = isFromMe;
        self.hasAttachment = hasAttachment;
    }
    
    return self;
}

- (NSString*) getTimeStampAsString
{
    if(!self.dateSent) {
        return @"";
    }
    
    NSString *text = [NSString stringWithFormat:@"Sent: %@", [dateFormatter stringFromDate:self.dateSent]];
    
    if(self.dateRead) {
        text = [NSString stringWithFormat:@"%@| Read: %@", text, [dateFormatter stringFromDate:self.dateRead]];
    }
    
    return text;
}

@end
