//
//  Message.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/6/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "Message.h"

@implementation Message

- (instancetype) initWithMessageId:(NSInteger)messageId handleId:(NSInteger)handleId messageGUID:(NSString *)messageGUID messageText:(NSString *)messageText dateSent:(NSDate *)dateSent dateRead:(NSDate *)dateRead isIMessage:(BOOL)isIMessage isFromMe:(BOOL)isFromMe
{
    self = [super init];
    
    if(self) {
        self.messageId = messageId;
        self.handleId = handleId;
        self.messageGUID = messageGUID;
        self.messageText = messageText;
        self.dateSent = dateSent;
        self.dateRead = dateRead;
        self.isIMessage = isIMessage;
        self.isFromMe = isFromMe;
    }
    
    return self;
}

@end
