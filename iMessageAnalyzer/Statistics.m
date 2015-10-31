//
//  Statistics.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/31/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "Statistics.h"

@implementation Statistics

- (instancetype) init
{
    self = [super init];
    
    if(self) {
        self.numberOfReceivedMessages = 0;
        self.numberOfSentMessages = 0;
    }
    
    return self;
}

@end
