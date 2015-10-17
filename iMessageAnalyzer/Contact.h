//
//  Contact.h
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/15/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBook/AddressBook.h>

@interface Contact : NSObject

- (instancetype) initWithFirstName:(NSString*)firstName lastName:(NSString*)lastName number:(NSString*)number person:(ABPerson*)person;

@property (strong, nonatomic) NSString *firstName;
@property (strong, nonatomic) NSString *lastName;
@property (strong, nonatomic) NSString *number;
@property (strong, nonatomic) ABPerson *person;

- (NSString*) getName;

@end