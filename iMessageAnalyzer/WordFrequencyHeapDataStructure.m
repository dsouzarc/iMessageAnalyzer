//
//  WordFrequencyHeapDataStructure.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/15/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "WordFrequencyHeapDataStructure.h"

@interface WordFrequencyHeapDataStructure ()

@property (strong, nonatomic) NSMutableArray *underlyingWords;
@property (strong, nonatomic) NSMutableArray *underlyingFrequencies;

@property NSInteger size;
@property NSInteger index;

@end


@implementation WordFrequencyHeapDataStructure

- (instancetype) initWithSize:(NSInteger)size
{
    self = [super init];
    
    if(self) {
        self.underlyingFrequencies = [[NSMutableArray alloc] initWithCapacity:size];
        self.underlyingWords = [[NSMutableArray alloc] initWithCapacity:size];
        
        self.size = size;
        self.index = 0;
        
        for(int i = 0; i < self.size + 1; i++) {
            [self.underlyingFrequencies addObject:[NSNumber numberWithInteger:INT32_MIN]];
            [self.underlyingWords addObject:[NSNumber numberWithInteger:INT32_MIN]];
        }
    }
    
    return self;
}

- (void) updateArrayWithAllWords:(NSMutableArray**)words andFrequencies:(NSMutableArray**)frequencies
{
    while (self.size > 0) {
        
        if(![self.underlyingFrequencies[1] isEqualToNumber:[NSNumber numberWithInteger:INT32_MIN]]) {
            [*words addObject:self.underlyingWords[1]];
            [*frequencies addObject:self.underlyingFrequencies[1]];
        }
        
        [self exchangeIndex:1 withIndex:self.size--];
        [self sinkFromIndex:1];
    }
}

- (void) addWord:(NSString *)word frequency:(NSNumber*)frequency
{
    self.index++;
    
    [self.underlyingWords setObject:word atIndexedSubscript:self.index];
    [self.underlyingFrequencies setObject:frequency atIndexedSubscript:self.index];
    
    [self swimFromIndex:self.index];
}

- (void) swimFromIndex:(NSInteger)index
{
    while(index > 1 && [self lessWithIndex:(index/2) otherIndex:index]) {
        [self exchangeIndex:(index/2) withIndex:index];
        index = (index / 2);
    }
}

- (void) sinkFromIndex:(NSInteger)index
{
    while (2 * index <= self.size) {
        NSInteger j = 2 * index;
        if(j < self.size && [self lessWithIndex:j otherIndex:(j + 1)]) {
            j++;
        }
        if(![self lessWithIndex:index otherIndex:j]) {
            break;
        }
        [self exchangeIndex:index withIndex:j];
        index = j;
    }
}

- (void) exchangeIndex:(NSInteger)index withIndex:(NSInteger)otherIndex
{
    NSObject *temp = self.underlyingWords[index];
    self.underlyingWords[index] = self.underlyingWords[otherIndex];
    self.underlyingWords[otherIndex] = temp;

    temp = self.underlyingFrequencies[index];
    self.underlyingFrequencies[index] = self.underlyingFrequencies[otherIndex];
    self.underlyingFrequencies[otherIndex] = temp;
}

- (BOOL) lessWithIndex:(NSInteger)index otherIndex:(NSInteger)otherIndex
{
    return [((NSNumber*) self.underlyingFrequencies[index]) isLessThan:((NSNumber*)self.underlyingFrequencies[otherIndex])];
}

@end
