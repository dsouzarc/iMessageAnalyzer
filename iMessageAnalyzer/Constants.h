//
//  Constants.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/1/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Constants : NSObject

+ (instancetype) instance;

@property (readonly) Constants *instance;

- (long)timeAtBeginningOfDayForDate:(NSDate*)inputDate;
- (NSDate*) getDateAtBeginningOfYear:(NSDate*)inputDate;
- (NSDate*) getDateAtEndOfYear:(NSDate*)inputDate;
- (NSString*)MonthNameString:(int)monthNumber;
- (NSString*) stringForDateAfterStart:(int)startDay;

- (long)timeAtEndOfDayForDate:(NSDate*)inputDate;
- (BOOL) isIMessage:(char*)text;

- (int) monthsBetweenDates:(NSDate*)startDate endDate:(NSDate*)endDate;

- (NSString*) dayMonthYearString:(NSDate*)date;

- (NSDate*) dateAtEndOfMonth:(NSDate*)date;
- (NSDate*) dateAtBeginningOfMonth:(NSDate*)date;

@end
