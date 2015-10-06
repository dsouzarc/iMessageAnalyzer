//
//  Attachment.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/6/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "Attachment.h"

@implementation Attachment

- (instancetype) initWithAttachmentId:(NSInteger)attachmentId messageId:(NSInteger)messageId guid:(NSString *)guid filePath:(NSString *)filePath fileType:(NSString *)fileType sentDate:(NSDate *)sentDate isOutgoing:(BOOL)isOutgoing
{
    self = [super init];
    
    if(self) {
        self.attachmentId = attachmentId;
        self.messageId = messageId;
        self.guid = guid;
        self.filePath = filePath;
        self.fileType = fileType;
        self.sentDate = sentDate;
        self.isOutgoing = isOutgoing;
    }
    
    return self;
}


@end
