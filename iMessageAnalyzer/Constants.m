
//
//  Constants.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/1/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "Constants.h"

static Constants *constants;

@interface Constants ()

@property (strong, nonatomic) NSCalendar *calendar;
@property (strong, nonatomic) NSDateFormatter *monthDateYearFormatter;
@property (strong, nonatomic) NSDateFormatter *shortMonthYearFormatter;
@property (strong, nonatomic) NSDateFormatter *yearMonthDayFormatter;
@property (strong, nonatomic) NSDateFormatter *timeFormatter;

@end

@implementation Constants


/****************************************************************
 *
 *              CONSTRUCTORS
 *
 *****************************************************************/

# pragma mark CONSTRUCTORS

- (instancetype) init
{
    self = [super init];
    
    if(self) {
        self.calendar = [NSCalendar currentCalendar];
        
        self.monthDateYearFormatter = [[NSDateFormatter alloc] init];
        [self.monthDateYearFormatter setDateFormat:@"MM/dd/yy"];
        
        self.shortMonthYearFormatter = [[NSDateFormatter alloc] init];
        [self.shortMonthYearFormatter setDateFormat:@"MMM yy"];
        
        self.yearMonthDayFormatter = [[NSDateFormatter alloc] init];
        [self.yearMonthDayFormatter setDateFormat:@"yyyy-MM-dd"];
        
        self.timeFormatter = [[NSDateFormatter alloc] init];
        [self.timeFormatter setDateFormat:@"hh.mm.ss"];
    }
    
    return self;
}

+ (instancetype) instance
{
    @synchronized(self) {
        if(!constants) {
            constants = [[self alloc] init];
        }
    }
    return constants;
}


/****************************************************************
 *
 *              DATE FROM INFORMATION
 *
 *****************************************************************/

# pragma mark DATE FROM INFORMATION

- (NSDate*) dateAtBeginningOfDay:(NSDate*)date
{
    NSDateComponents *components = [self dateComponentsForDay:date];
    [components setHour:0];
    [components setHour:0];
    [components setSecond:1];
    
    return [self.calendar dateFromComponents:components];
}

- (NSDate*) dateAtEndOfDay:(NSDate*)date
{
    NSDateComponents *components = [self dateComponentsForDay:date];
    [components setHour:23];
    [components setHour:59];
    [components setSecond:59];
    
    [components setDay:[components day] - 2];
    
    return [self.calendar dateFromComponents:components];
}

- (NSDate*) dateAtEndOfMonth:(NSDate*)date
{
    NSDateComponents *components = [self dateComponentsForDay:date];
    [components setMonth:[components month] + 1];
    [components setDay:0];
    
    return [self.calendar dateFromComponents:components];
}

- (NSDate*) dateAtBeginningOfMonth:(NSDate*)date
{
    NSDateComponents *components = [self dateComponentsForDay:date];
    [components setDay:1];
    return [self.calendar dateFromComponents:components];
}

- (NSDate*) dateAtBeginningOfNextMonth:(NSDate *)date
{
    NSDateComponents *components = [self dateComponentsForDay:date];
    [components setMonth:[components month] + 1];
    [components setDay:1];
    return [self.calendar dateFromComponents:components];
}

- (NSDate*) getDateAtEndOfYear:(NSDate*)inputDate
{
    NSDateComponents *dateComps = [self dateComponentsForDay:inputDate];
    [dateComps setHour:23];
    [dateComps setMinute:59];
    [dateComps setSecond:59];
    [dateComps setMonth:12];
    [dateComps setDay:31];
    
    return [self.calendar dateFromComponents:dateComps];
}

- (NSDate*) getDateAtBeginningOfYear:(NSDate*)inputDate
{
    NSDateComponents *dateComps = [self dateComponentsForDay:inputDate];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:1];
    [dateComps setMonth:1];
    [dateComps setDay:1];
    
    return [self.calendar dateFromComponents:dateComps];
}

- (NSDate*) dateByAddingDays:(NSDate*)date days:(int)days
{
    static NSDateComponents *dateComponent;
    
    if(!dateComponent) {
        dateComponent = [[NSDateComponents alloc] init];
    }
    dateComponent.day = days;
    
    return [self.calendar dateByAddingComponents:dateComponent toDate:date options:0];
}

- (NSDate*) dateBySubtractingMonths:(NSDate*)date months:(int)months
{
    NSDateComponents *components = [self dateComponentsForDay:date];
    [components setDay:1];
    [components setMonth:[components month] - months];
    return [self.calendar dateFromComponents:components];
}

- (NSDate*) dateByAddingMonths:(NSDate *)date months:(int)months
{
    return [self dateBySubtractingMonths:date months:(months * -1)];
}


/****************************************************************
 *
 *              NUMBERS FROM INFORMATION
 *
 *****************************************************************/

# pragma mark SEARCHFIELD_DELEGATE

- (int) daysInMonthForDate:(NSDate *)date
{
    NSRange range = [self.calendar rangeOfUnit:NSCalendarUnitDay inUnit:NSCalendarUnitMonth forDate:date];
    return (int) range.length;
}

- (int) getDateHour:(NSDate *)date
{
    NSDateComponents *components = [self.calendar components:NSCalendarUnitHour fromDate:date];
    return (int) [components hour];
}

- (int) getDateHourFromDateInSeconds:(int)dateInSeconds
{
    return [self getDateHour:[NSDate dateWithTimeIntervalSinceReferenceDate:dateInSeconds]];
}

- (int) monthsBetweenDates:(NSDate*)startDate endDate:(NSDate*)endDate
{
    NSDateComponents *components = [self.calendar components:NSCalendarUnitMonth fromDate:startDate toDate:endDate options:0];
    return (int)[components month];
}

- (int) daysBetweenDates:(NSDate*)startDate endDate:(NSDate*)endDate
{
    NSDateComponents *components = [self.calendar components:NSCalendarUnitDay fromDate:startDate toDate:endDate options:0];
    return (int)[components day];
}

- (long) timeAtBeginningOfDayForDate:(NSDate*)inputDate
{
    NSDateComponents *dateComps = [self dateComponentsForDay:inputDate];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0]; //Or should it be 1?
    return [[self.calendar dateFromComponents:dateComps] timeIntervalSinceReferenceDate];
}

- (long) timeAtEndOfDayForDate:(NSDate*)inputDate
{
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [self dateComponentsForDay:inputDate];
    
    // Set the time components manually
    [dateComps setHour:23];
    [dateComps setMinute:59];
    [dateComps setSecond:59];
    
    // Convert back
    NSDate *endOfDay = [self.calendar dateFromComponents:dateComps];
    return [endOfDay timeIntervalSinceReferenceDate];
}


/****************************************************************
 *
 *              BOOLS FROM INFORMATION
 *
 *****************************************************************/

# pragma mark BOOLS FROM INFORMATION

- (BOOL) isBeginningOfMonth:(NSDate *)date
{
    NSDateComponents *components = [self dateComponentsForDay:date];
    int day = (int) [components day];
    return  day <= 7;
}

- (BOOL) isIMessage:(char*)text
{
    return strcmp(text, "iMessage") == 0;
}

- (BOOL) isDateOnSameDay:(NSDate*)firstDate secondDate:(NSDate*)secondDate
{
    NSDateComponents *day1 = [self dateComponentsForDay:firstDate];
    NSDateComponents *day2 = [self dateComponentsForDay:secondDate];
    
    return (day1.day == day2.day) && (day1.month == day2.month) && (day1.year == day2.year);
}


/****************************************************************
 *
 *              STRING FROM DATE INFORMATION
 *
 *****************************************************************/

# pragma mark SEARCHFIELD_DELEGATE

- (NSString*) dayMonthYearString:(NSDate*)date
{
    return [self.monthDateYearFormatter stringFromDate:date];
}

- (NSString*) monthYearToString:(NSDate *)date
{
    NSString *result = [self.shortMonthYearFormatter stringFromDate:date];
    return [result stringByReplacingOccurrencesOfString:@" " withString:@" '"];
}

- (NSString*) MonthNameString:(int)monthNumber
{
    NSDateFormatter *formate = [NSDateFormatter new];
    NSArray *monthNames = [formate standaloneMonthSymbols];
    NSString *monthName = [monthNames objectAtIndex:monthNumber];
    
    return monthName;
}

- (NSString*) stringForDateAfterStart:(int)startDay
{
    NSDateComponents *dateComps = [self dateComponentsForDay:[NSDate date]];
    
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:1];
    [dateComps setMonth:1];
    [dateComps setDay:startDay];
    NSDate *beginningOfYear = [self.calendar dateFromComponents:dateComps];
    
    return [self.monthDateYearFormatter stringFromDate:beginningOfYear];
}

//EX: 2016-09-27
- (NSString*) yearMonthDayFormatter:(NSDate*)date
{
    return [self.yearMonthDayFormatter stringFromDate:date];
}

//EX: 08.45.26 OR 17.51.45
- (NSString*) timeFormatter:(NSDate*)date
{
    return [self.timeFormatter stringFromDate:date];
}


/****************************************************************
 *
 *              Miscellaneous
 *
 *****************************************************************/

# pragma mark Miscellaneous

+ (NSString*) getStrippedWord:(NSString*)original
{
    original = [original lowercaseString];
    
    NSCharacterSet *charactersToRemove = [[NSCharacterSet alphanumericCharacterSet] invertedSet];
    original = [[original componentsSeparatedByCharactersInSet:charactersToRemove] componentsJoinedByString:@""];
    return original;
}


/****************************************************************
 *
 *              AUXILLARY
 *
 *****************************************************************/

# pragma mark AUXILLARY

- (NSDateComponents*) dateComponentsForDay:(NSDate*)date
{
    return [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
}

- (NSDateComponents*) timeComponentsForDay:(NSDate*)date
{
    return [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:date];
}

+ (BOOL) isDevelopmentMode
{
    return DEVELOPMENT;
}

+ (BOOL) isDoubleMessage:(int)timeDifference
{
    return (timeDifference >= MIN_DOUBLE_MESSAGE) && (timeDifference <= MAX_DOUBLE_MESSAGE);
}

+ (BOOL) isConversationStarter:(int)timeDifference
{
    return timeDifference >= MIN_CONVERSATION_STARTER;
}

+ (NSDictionary*) getMessageWithAttachmentAttributes
{
    return [NSDictionary dictionaryWithObjectsAndKeys:[NSColor yellowColor], NSForegroundColorAttributeName,
            [NSNumber numberWithInt:NSUnderlineStyleSingle], NSUnderlineStyleAttributeName, nil];
}

@end
