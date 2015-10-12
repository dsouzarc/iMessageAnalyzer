//
//  DatabaseManager.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/8/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "DatabaseManager.h"

static DatabaseManager *databaseInstance;

static NSString *pathToDB = @"/Users/Ryan/FLV MP4/iMessage/mac_chat.db";

@interface DatabaseManager ()

@property sqlite3 *database;

@end

@implementation DatabaseManager

+ (instancetype) getInstance
{
    @synchronized(self) {
        if(!databaseInstance) {
            databaseInstance = [[self alloc] init];
        }
    }
    
    return databaseInstance;
}

- (instancetype) init
{
    if(!databaseInstance) {
        databaseInstance = [super init];
        
        if(sqlite3_open([pathToDB cStringUsingEncoding:NSASCIIStringEncoding], &_database) == SQLITE_OK) {
            printf("DATABASE SUCCESSFULLY OPENED\n");
        }
        else {
            printf("ERROR OPENING DB: %s", sqlite3_errmsg(_database));
        }
    }
    
    return self;
}

@end
