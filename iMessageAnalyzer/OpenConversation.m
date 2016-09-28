//
//  OpenConversation.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 9/27/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "OpenConversation.h"

static NSString *scriptName = @"OpenConversation";
static NSString *scriptType = @"applescript";

@interface OpenConversation ()

@end

@implementation OpenConversation

+ (void) executeWithPhoneNumber:(NSString*)phoneNumber
{
    NSError *error;
    
    NSString *path = [[NSBundle mainBundle] pathForResource:scriptName ofType:scriptType];
    NSString *appleScriptCode = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    
    if(error) {
        NSLog(@"ERROR OPENING %@.%@", scriptName, scriptType);
    } else {
        
        appleScriptCode = [appleScriptCode stringByReplacingOccurrencesOfString:@"{phoneNumber}" withString:phoneNumber];
        
        NSAppleScript *appleScript = [[NSAppleScript alloc] initWithSource:appleScriptCode];
        
        NSDictionary *errors = [[NSDictionary alloc] init];
        [appleScript executeAndReturnError:&errors];
        
        if(errors && errors.count > 0) {
            NSLog(@"ERROR EXECUTING CODE: %@", errors);
        }
    }
}

@end
