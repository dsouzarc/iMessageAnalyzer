//
//  Attachment.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/6/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Attachment : NSObject

- (instancetype) initWithAttachmentId:(NSInteger)attachmentId messageId:(NSInteger)messageId guid:(NSString*)guid filePath:(NSString*)filePath fileType:(NSString*)fileType sentDate:(NSDate*)sentDate isOutgoing:(BOOL)isOutgoing;

@property (strong, nonatomic) NSString *guid;
@property (strong, nonatomic) NSString *filePath;
@property (strong, nonatomic) NSString *fileType;

@property (strong, nonatomic) NSDate *sentDate;

@property NSInteger attachmentId;
@property NSInteger messageId;
@property BOOL isOutgoing;

@end