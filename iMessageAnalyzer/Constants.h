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
- (BOOL) isBeginningOfMonth:(NSDate*)date;

- (int) monthsBetweenDates:(NSDate*)startDate endDate:(NSDate*)endDate;
- (NSDate*) dateByAddingDays:(NSDate*)date days:(int)days;
- (NSString*) dayMonthYearString:(NSDate*)date;

- (NSDate*) dateAtEndOfMonth:(NSDate*)date;
- (NSDate*) dateAtBeginningOfMonth:(NSDate*)date;
- (NSDate*) dateAtBeginningOfNextMonth:(NSDate*)date;

- (int) daysBetweenDates:(NSDate*)startDate endDate:(NSDate*)endDate;
- (int) daysInMonthForDate:(NSDate*)date;

- (NSString*) monthYearToString:(NSDate*)date;

- (NSDate*) dateBySubtractingMonths:(NSDate*)date months:(int)months;
- (NSDate*) dateByAddingMonths:(NSDate*)date months:(int)months;

@end
