//
//  WordFrequencyHeapDataStructure.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/15/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface WordFrequencyHeapDataStructure : NSObject

- (instancetype) initWithSize:(NSInteger)size;

- (void) addWord:(NSString*)word frequency:(NSNumber*)frequency;
- (void) updateArrayWithAllWords:(NSMutableArray**)words andFrequencies:(NSMutableArray**)frequencies;

@end
