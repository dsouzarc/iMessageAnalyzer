//
//  Message.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/6/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Message : NSObject

- (instancetype) initWithMessageId:(NSInteger)messageId handleId:(NSInteger)handleId messageGUID:(NSString*)messageGUID messageText:(NSString*)messageText dateSent:(NSDate*)dateSent dateRead:(NSDate*)dateRead isIMessage:(BOOL)isIMessage isFromMe:(BOOL)isFromMe hasAttachment:(BOOL)hasAttachment;

@property (strong, nonatomic) NSString *messageText;
@property (strong, nonatomic) NSString *messageGUID;

@property (strong, nonatomic) NSMutableArray *attachments;

@property (strong, nonatomic) NSDate *dateSent;
@property (strong, nonatomic) NSDate *dateRead;

@property NSInteger messageId;
@property NSInteger handleId;

@property BOOL isIMessage;
@property BOOL isFromMe;
@property BOOL hasAttachment;

- (NSString*) getTimeStampAsString;
- (NSString*) lastMessagedOn;

@end
