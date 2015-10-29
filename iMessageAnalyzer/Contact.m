//
//  Contact.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 10/15/15.
//  Copyright © 2015 Ryan D'souza. All rights reserved.
//

#import "Contact.h"

@implementation Contact

- (instancetype) initWithFirstName:(NSString *)firstName lastName:(NSString *)lastName number:(NSString *)number person:(ABPerson *)person
{
    self = [super init];
    
    if(self) {
        self.firstName = firstName;
        self.lastName = lastName;
        self.number = number;
        self.person = person;
    }
    
    return self;
}

- (NSString*) getName
{
    if(self.firstName && self.lastName) {
        return [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
    }
    else if(self.firstName) {
        return self.firstName;
    }
    else if(self.lastName) {
        return self.lastName;
    }
    else {
        return self.number ? self.number : @"PROBLEM WITH CONTACT NAME";
    }
}

@end
