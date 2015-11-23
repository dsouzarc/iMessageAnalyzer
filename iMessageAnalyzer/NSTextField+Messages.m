//
//  NSTextField+Messages.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/22/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "NSTextField+Messages.h"

@implementation NSTextField_Messages

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    
    // Drawing code here.
}

- (void)mouseDown:(NSEvent *)theEvent;
{
    [self.delegate clickedOnTextField:self.textFieldNumber];
    //[self sendAction:[self action] to:[self delegate]];
}

- (void) selectText:(id)sender
{
    
}

@end
