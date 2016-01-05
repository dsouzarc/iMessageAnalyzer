
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

@end

@implementation Constants

- (instancetype) init
{
    self = [super init];
    
    if(self) {
        self.calendar = [NSCalendar currentCalendar];
        
        self.monthDateYearFormatter = [[NSDateFormatter alloc] init];
        [self.monthDateYearFormatter setDateFormat:@"MM/dd/yy"];
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

- (int) monthsBetweenDates:(NSDate*)startDate endDate:(NSDate*)endDate
{
    NSDateComponents *components = [self.calendar components:NSCalendarUnitMonth fromDate:startDate toDate:endDate options:0];
    return (int)[components month];
}

- (NSString*) stringForDateAfterStart:(int)startDay
{
    // Selectively convert the date components (year, month, day) of the input date
    NSDateComponents *dateComps = [self dateComponentsForDay:[NSDate date]];
    
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:1];
    [dateComps setMonth:1];
    [dateComps setDay:startDay];
    NSDate *beginningOfYear = [self.calendar dateFromComponents:dateComps];
    
    return [self.monthDateYearFormatter stringFromDate:beginningOfYear];
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

- (NSDateComponents*) dateComponentsForDay:(NSDate*)date
{
    return [self.calendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay fromDate:date];
}

- (NSString*) dayMonthYearString:(NSDate*)date
{
    return [self.monthDateYearFormatter stringFromDate:date];
}

- (NSString*) MonthNameString:(int)monthNumber
{
    NSDateFormatter *formate = [NSDateFormatter new];
    NSArray *monthNames = [formate standaloneMonthSymbols];
    NSString *monthName = [monthNames objectAtIndex:monthNumber];
    
    return monthName;
}

- (NSDate*) getDateAtEndOfYear:(NSDate*)inputDate
{
    NSDateComponents *dateComps = [self dateComponentsForDay:inputDate];
    [dateComps setHour:23];
    [dateComps setMinute:59];
    [dateComps setSecond:59];
    [dateComps setMonth:12];
    [dateComps setDay:31];
    
    //TODO: CHANGE
    [dateComps setYear:2015];
    
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
    
    //TODO: CHANGE
    [dateComps setYear:2015];
    
    return [self.calendar dateFromComponents:dateComps];
}

- (long)timeAtBeginningOfDayForDate:(NSDate*)inputDate
{
    NSDateComponents *dateComps = [self dateComponentsForDay:inputDate];
    [dateComps setHour:0];
    [dateComps setMinute:0];
    [dateComps setSecond:0]; //Or should it be 1?
    return [[self.calendar dateFromComponents:dateComps] timeIntervalSinceReferenceDate];
}

- (long)timeAtEndOfDayForDate:(NSDate*)inputDate
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

- (BOOL) isIMessage:(char*)text
{
    return strcmp(text, "iMessage") == 0;
}

@end
