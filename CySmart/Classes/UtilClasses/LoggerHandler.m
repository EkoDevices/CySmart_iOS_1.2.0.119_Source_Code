/*
 * Copyright Cypress Semiconductor Corporation, 2014-2018 All rights reserved.
 *
 * This software, associated documentation and materials ("Software") is
 * owned by Cypress Semiconductor Corporation ("Cypress") and is
 * protected by and subject to worldwide patent protection (UnitedStates and foreign), United States copyright laws and international
 * treaty provisions. Therefore, unless otherwise specified in a separate license agreement between you and Cypress, this Software
 * must be treated like any other copyrighted material. Reproduction,
 * modification, translation, compilation, or representation of this
 * Software in any other form (e.g., paper, magnetic, optical, silicon)
 * is prohibited without Cypress's express written permission.
 *
 * Disclaimer: THIS SOFTWARE IS PROVIDED AS-IS, WITH NO WARRANTY OF ANY
 * KIND, EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO,
 * NONINFRINGEMENT, IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
 * FOR A PARTICULAR PURPOSE. Cypress reserves the right to make changes
 * to the Software without notice. Cypress does not assume any liability
 * arising out of the application or use of Software or any product or
 * circuit described in the Software. Cypress does not authorize its
 * products for use as critical components in any products where a
 * malfunction or failure may reasonably be expected to result in
 * significant injury or death ("High Risk Product"). By including
 * Cypress's product in a High Risk Product, the manufacturer of such
 * system or application assumes all risk of such use and in doing so
 * indemnifies Cypress against all liability.
 *
 * Use of this Software may be limited by and subject to the applicable
 * Cypress software license agreement.
 *
 *
 */


#define LOGGER_KEY @"Logger_Data"
#define DATE_DATA_KEY @"Date_Log"

#import "LoggerHandler.h"
#import "CoreDataHandler.h"
#import "Utilities.h"


/*!
 *  @class LoggerHandler
 *
 *  @discussion Class to handle data logging operations
 *
 */
@interface LoggerHandler ()
{
    NSMutableArray *DateLogArray;
    CoreDataHandler *loggerDataHandler;
}

@end

@implementation LoggerHandler
@synthesize Logger;

+ (id)logManager {
    static LoggerHandler *sharedMyManager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    return sharedMyManager;
}

- (id)init {
    if (self = [super init])
    {
        if (!loggerDataHandler)
        {
            loggerDataHandler = [[CoreDataHandler alloc] init];
        }
    }
    return self;
}

/*!
 *  @method addLogData:
 *
 *  @discussion Add log data
 *
 */
-(void)addLogData:(NSString*)data {
    NSString *event = [NSString stringWithFormat:@"[%@]%@%@", [self formatDate:[NSDate date]], DATE_SEPARATOR, data];
    [loggerDataHandler addLogEvent:event date:[Utilities getTodayDateString]];
}

/*!
 *  @method getTodayLogData
 *
 *  @discussion Return today log data
 *
 */
-(NSArray *) getTodayLogData
{
    return [loggerDataHandler getLogEventsForDate:[Utilities getTodayDateString]];
}

/*!
 *  @method formatDate:
 *
 *  @discussion Format date as date-time string
 *
 */
-(NSString *)formatDate:(NSDate *)date {
    NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
    dateTimeFormatter.dateFormat = [NSString stringWithFormat:@"%@|%@", DATE_FORMAT, TIME_FORMAT];
    
    NSString *dateTimeString = [dateTimeFormatter stringFromDate:date];
    return dateTimeString;
}

/*!
 *  @method parseDate:
 *
 *  @discussion Parse date from date-time string
 *
 */
-(NSDate*)parseDate:(NSString *)dateTimeString {
    NSDateFormatter *dateTimeFormatter = [[NSDateFormatter alloc] init];
    dateTimeFormatter.dateFormat = [NSString stringWithFormat:@"%@|%@", DATE_FORMAT, TIME_FORMAT];
    
    NSDate *date = [dateTimeFormatter dateFromString:dateTimeString];
    return date;
}

/*!
 *  @method deleteOldLogData
 *
 *  @discussion Delete old log data
 *
 */
-(void)deleteOldLogData {
    NSArray *dates = [loggerDataHandler getLogDates];
    if(dates && [dates count]) {
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = DATE_FORMAT;

        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSCalendarUnit flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
        
        BOOL(^areDatesEqual)(NSDate *date1, NSDate *date2) = ^BOOL(NSDate *date1, NSDate *date2) {
            NSDateComponents *comp1 = [calendar components:flags fromDate:date1];
            NSDateComponents *comp2 = [calendar components:flags fromDate:date2];
            return ([comp1 year] == [comp2 year]) && ([comp1 month] == [comp2 month]) && ([comp1 day] == [comp2 day]);
        };

        // Collect
        NSDate *now = [NSDate date];
        NSMutableDictionary *dict = [NSMutableDictionary new];
        for (NSString *dateString in dates) {
            NSDate *date = [dateFormatter dateFromString:dateString];
            // Exclude today
            if (!areDatesEqual(now, date)) {
                [dict setValue:date forKey:dateString];
            }
        }
        
        // Sort DESC
        NSArray *keys = [dict keysSortedByValueUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            NSDate *date1 = (NSDate *)obj1;
            NSDate *date2 = (NSDate *)obj2;
            return [date2 compare:date1];
        }];
        
        // Leave the first 7 records (including today) and delete the rest.
        int count = 0;
        for (NSString *dateString in keys) {
            if (++count > 6) { // 7 = 6 + today
                [loggerDataHandler deleteLogEventsForDate:dateString];
            }
        }
    }
}

@end
