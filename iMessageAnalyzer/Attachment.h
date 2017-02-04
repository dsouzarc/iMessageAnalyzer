//
//  Attachment.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/6/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Realm/Realm.h>

@interface Attachment : RLMObject

- (instancetype) initWithAttachmentID:(int32_t)attachmentID attachmentGUID:(NSString*)guid filePath:(NSString*)filePath fileType:(NSString*)fileType sentDate:(NSDate*)sentDate attachmentSize:(long)attachmentSize messageID:(int32_t)messageID fileName:(NSString*)fileName;

@property (strong, nonatomic) NSString *guid;
@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) NSString *fileType;
@property (strong, nonatomic) NSString *fileName;

@property (strong, nonatomic) NSDate *sentDate;

@property int32_t attachmentId;
@property int32_t messageId;
@property long size;

@end

RLM_ARRAY_TYPE(Attachment)
