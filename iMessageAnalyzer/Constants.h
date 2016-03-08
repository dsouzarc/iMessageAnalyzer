//
//  Constants.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/1/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

const static BOOL DEVELOPMENT = YES;
const static NSString *pathToDevelopmentDB = @"/Users/Ryan/FLV MP4/iMessage/iphone_chat.db";

/** Classless, helpful auxillary methods used by a variety of classes */

@interface Constants : NSObject

#pragma mark CONSTRUCTORS

+ (instancetype) instance;
+ (BOOL) isDevelopmentMode;
@property (readonly) Constants *instance;

#pragma mark STRING FROM INFORMATION

- (NSString*) MonthNameString:(int)monthNumber;
- (NSString*) dayMonthYearString:(NSDate*)date;
- (NSString*) monthYearToString:(NSDate*)date;
- (NSString*) stringForDateAfterStart:(int)startDay;


#pragma mark BOOL FROM INFORMATION

- (BOOL) isIMessage:(char*)text;
- (BOOL) isBeginningOfMonth:(NSDate*)date;


#pragma mark DATE FROM INFORMATION

- (NSDate*) getDateAtBeginningOfYear:(NSDate*)inputDate;
- (NSDate*) getDateAtEndOfYear:(NSDate*)inputDate;

- (NSDate*) dateAtEndOfMonth:(NSDate*)date;
- (NSDate*) dateAtBeginningOfMonth:(NSDate*)date;
- (NSDate*) dateAtBeginningOfNextMonth:(NSDate*)date;

- (NSDate*) dateBySubtractingMonths:(NSDate*)date months:(int)months;
- (NSDate*) dateByAddingMonths:(NSDate*)date months:(int)months;
- (NSDate*) dateByAddingDays:(NSDate*)date days:(int)days;

#pragma mark NUMBERS FROM INFORMATION

- (int) daysBetweenDates:(NSDate*)startDate endDate:(NSDate*)endDate;
- (int) daysInMonthForDate:(NSDate*)date;
- (int) monthsBetweenDates:(NSDate*)startDate endDate:(NSDate*)endDate;

- (long) timeAtBeginningOfDayForDate:(NSDate*)inputDate;
- (long) timeAtEndOfDayForDate:(NSDate*)inputDate;

- (int) getDateHour:(NSDate*)date;
- (int) getDateHourFromDateInSeconds:(int)dateInSeconds;

#pragma mark Miscellaneous

+ (NSString*) getStrippedWord:(NSString*)original;

@end