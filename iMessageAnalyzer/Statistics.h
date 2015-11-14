//
//  Statistics.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/31/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Statistics : NSObject

@property NSInteger numberOfSentMessages;
@property NSInteger numberOfReceivedMessages;

@property NSInteger numberOfSentAttachments;
@property NSInteger numberOfReceivedAttachments;

@property BOOL hasPerformedDetailedAnalysis;

@property NSInteger numberOfSentWords;
@property NSInteger numberOfReceivedWords;

@property NSString *mostFrequentedSentWord;
@property NSString *mostFrequentedReceivedWord;


@end
