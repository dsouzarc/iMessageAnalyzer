//
//  NSTextField+Messages.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/22/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#import "RSVerticallyCenteredTextFieldCell.h"


@protocol NSTextField_MessagesDelegate <NSObject>

- (void) clickedOnTextField:(int32_t)textFieldNumber;

@end


@interface NSTextField_Messages : NSTextField

@property (weak, nonatomic) id<NSTextField_MessagesDelegate> messagesDelegate;

@property int32_t textFieldNumber;

@end
