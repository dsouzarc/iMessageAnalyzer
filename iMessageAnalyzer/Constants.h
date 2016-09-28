//
//  Constants.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/1/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

const static BOOL DEVELOPMENT = YES;
const static NSString *pathToDevelopmentDB = @"/Users/Ryan/FLV MP4/iMessage/iphone_chat.db";

//Range for a message to be considered a double message - 3min to 11 hours
const static int MIN_DOUBLE_MESSAGE = 180;
const static int MAX_DOUBLE_MESSAGE = 39600;

//Range for a message to be considered a conversation starter - 11 hours
const static int MIN_CONVERSATION_STARTER = MAX_DOUBLE_MESSAGE + 1;

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
- (NSString*) yearMonthDayFormatter:(NSDate*)date;
- (NSString*) timeFormatter:(NSDate*)date;


#pragma mark BOOL FROM INFORMATION

+ (BOOL) isIMessage:(NSString*)text;
- (BOOL) isBeginningOfMonth:(NSDate*)date;
- (BOOL) isDateOnSameDay:(NSDate*)firstDate secondDate:(NSDate*)secondDate;


#pragma mark DATE FROM INFORMATION

- (NSDate*) dateAtBeginningOfDay:(NSDate*)date;
- (NSDate*) dateAtEndOfDay:(NSDate*)date;

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
+ (BOOL) isDoubleMessage:(int)timeDifference;
+ (BOOL) isConversationStarter:(int)timeDifference;

+ (NSDictionary*) getMessageWithAttachmentAttributes;

@end
