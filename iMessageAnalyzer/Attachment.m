//
//  Attachment.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/6/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "Attachment.h"

@implementation Attachment

- (instancetype) initWithAttachmentID:(int32_t)attachmentID attachmentGUID:(NSString *)guid filePath:(NSString *)filePath fileType:(NSString *)fileType sentDate:(NSDate *)sentDate attachmentSize:(long)attachmentSize messageID:(int32_t)messageID fileName:(NSString *)fileName
{
    self = [super init];
    
    if(self) {
        self.attachmentId = attachmentID;
        self.messageId = messageID;
        self.guid = guid;
        self.fileType = fileType;
        self.sentDate = sentDate;
        self.size = attachmentSize;
        self.fileName = fileName;
        
        //filePath Example: ~/Library/Messages/Attachments/1c/12/FBB3B1E5-9477-4E5F-ADD6-6EE1D3C0F7D0/IMG_0418.JPG
        
        //Now: /Library/Messages/Attachments/1c/12/FBB3B1E5-9477-4E5F-ADD6-6EE1D3C0F7D0/IMG_0418.JPG
        filePath = [filePath substringFromIndex:1];
        
        //Now: /Users/Ryan/Library/Messages/Attachments/1c/12/FBB3B1E5-9477-4E5F-ADD6-6EE1D3C0F7D0/IMG_0418.JPG
        filePath = [NSString stringWithFormat:@"%@%@", NSHomeDirectory(), filePath];
        self.filePath = filePath;
    }
    
    return self;
}


@end
