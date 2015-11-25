//
//  TemporaryDatabaseManager.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 11/25/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <sqlite3.h>

#import "MessageManager.h"

#import "Message.h"
#import "Person.h"
#import "Statistics.h"


@interface TemporaryDatabaseManager : NSObject

- (instancetype) initWithPerson:(Person*)person;

- (void) addMessagesToDatabase:(NSMutableArray*)messages;
- (void) addOtherMessagesToDatabase:(NSMutableArray*)otherMessages;

- (NSMutableArray*) getAllMessagesForPerson:(Person *)person;
- (NSMutableArray*) getAllMessagesForPerson:(Person *)person startTimeInSeconds:(long)startTimeInSeconds endTimeInSeconds:(long)endTimeInSeconds;

@end
