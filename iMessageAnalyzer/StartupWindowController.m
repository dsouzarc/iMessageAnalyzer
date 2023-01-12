//
//  StartupWindowController.m
//  iMessageAnalyzer
//
//  Created by Ryan D'souza on 1/10/16.
//  Copyright © 2016 Ryan D'souza. All rights reserved.
//

#import "StartupWindowController.h"

@interface StartupWindowController ()

@property (strong, nonatomic) MainWindowController *mainWindowController;
@property (strong, nonatomic) StartupViewController *startupViewController;

@property (strong, nonatomic) NSString *messagesPath;
@property (strong, nonatomic) NSString *iPhonePath;
@property (strong, nonatomic) NSString *backupLocation;

@end

@implementation StartupWindowController


/****************************************************************
 *
 *              Constructor
 *
 *****************************************************************/

# pragma mark - Constructor

- (instancetype) initWithWindowNibName:(NSString *)windowNibName
{
    self = [super initWithWindowNibName:windowNibName];
    
    if(self) {
        self.startupViewController = [[StartupViewController alloc] initWithNibName:@"StartupViewController" bundle:[NSBundle mainBundle]];
        
        self.messagesPath = [NSString stringWithFormat:@"%@/Library/Messages", NSHomeDirectory()];
        self.iPhonePath = [NSString stringWithFormat:@"%@/Library/Application Support/MobileSync/Backup", NSHomeDirectory()];
        
        //Ex: /var/folders/yj/79s69tld3hq8fqs7j_yqbpg00000gn/T//imessage_analyzer_copy_on_504626384.439504.db
        NSString *backupName = [NSString stringWithFormat:@"imessage_analyzer_copy_on_%f.db", [[NSDate date] timeIntervalSinceReferenceDate]];
        self.backupLocation = [NSString stringWithFormat:@"%@%@", NSTemporaryDirectory(), backupName];
        
    }
    
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    //[self.window setContentSize:NSMakeSize(544, 650)];
    //[self.window setMaxSize:NSMakeSize(544, 650)];
    
    [self.window setShowsResizeIndicator:NO];
    [self.window setTitle:@"iMessage Analyzer"];
    [self.window setBackgroundColor:[NSColor whiteColor]];
    
    [self.startupViewController setDelegate:self];
    [self.window setContentViewController:self.startupViewController];
    
    [self checkForLatestVersion];
}

- (void) checkForLatestVersion
{
    //Check if we should update the app
    NSURL *updateUrl = [NSURL URLWithString:(NSString*)versionInfoURL];
    NSURLSession *session = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:updateUrl completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        
        if(error) {
            NSLog(@"Error checking for latest version: %@", [error description]);
            return;
        }
        
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if(error) {
            NSLog(@"Error parsing JSON response: %@", jsonResponse);
            return;
        }
        
        NSArray *versions = jsonResponse[@"versionInfo"];
        if(!versions || versions.count == 0) {
            return;
        }
        
        const NSNumber *myVersion = [NSNumber numberWithDouble:[[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleShortVersionString"] doubleValue]];
        
        //For keeping track of the greatest version number
        NSNumber *latestVersionNumber = [NSNumber numberWithDouble:0.0];
        NSDictionary *latestVersion = nil;
        
        for(NSDictionary *version in versions) {
            NSNumber *versionNumber = [NSNumber numberWithDouble:[version[@"version"] doubleValue]];
            
            if([versionNumber isGreaterThan:latestVersionNumber]) {
                latestVersionNumber = versionNumber;
                latestVersion = version;
            }
        }
        
        //If there's a later version, prompt for update
        if([latestVersionNumber isGreaterThan:myVersion] && latestVersion) {
            
            NSString *informativeText = [NSString stringWithFormat:@"There is a newer version of the iMessage Analyzer Available\nChanges include: %@", latestVersion[@"changes"]];
            
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                
                NSAlert *prompt = [[NSAlert alloc] init];
                [prompt setAlertStyle:NSWarningAlertStyle];
                [prompt setMessageText:@"Update available"];
                [prompt setInformativeText:informativeText];
                [prompt addButtonWithTitle:@"Download the new version"];
                [prompt addButtonWithTitle:@"Continue with the old version"];
                
                [prompt beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
                    switch (response) {
                        case NSAlertFirstButtonReturn:
                            [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:(NSString*)versionLatestURL]];
                            break;
                        case NSAlertSecondButtonReturn:
                            break;
                        default:
                            break;
                    }
                }];
            });
        }
        
    }];
    [dataTask resume];
}


/****************************************************************
 *
 *              StartupViewController Delegate
 *
 *****************************************************************/

# pragma mark - StartupViewController Delegate

- (void) didWishToContinue
{
    NSString *description = [NSString stringWithFormat:@"Choose the source from which to analyze your messages:\n\n1. The default Mac Messages.app: %@\n\n2. The most recent iPhone backup: %@\n\n3. A specific database file that you can choose.\n\nPlease note the following loading might take some time as the database is being copied to the file's directory so that the original will not be corrupted.\nThat temporary database will be deleted when the app is exited.", self.messagesPath, self.iPhonePath];
    
    NSAlert *prompt = [[NSAlert alloc] init];
    [prompt setAlertStyle:NSWarningAlertStyle];
    [prompt setMessageText:@"Choose Messages database source"];
    [prompt setInformativeText:description];
    [prompt addButtonWithTitle:@"Messages.app"];
    [prompt addButtonWithTitle:@"iPhone backup"];
    [prompt addButtonWithTitle:@"Specify file"];
    
    [prompt beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        switch (response) {
            case NSAlertFirstButtonReturn:
                [self messagesDataSource];
                break;
            case NSAlertSecondButtonReturn:
                [self iPhoneDataSource];
                break;
            case NSAlertThirdButtonReturn:
                [self specificFileDataSource];
                break;
            default:
                break;
        }
    }];
}

- (void) didWishToExit
{
    [NSApp terminate:self];
}


/****************************************************************
 *
 *              Auxillary methods
 *
 *****************************************************************/

# pragma mark - Auxillary methods

- (void) messagesDataSource
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSString *pathForFile = [NSString stringWithFormat:@"%@/chat.db", self.messagesPath];
    
    if ([fileManager fileExistsAtPath:pathForFile]){
        
        NSError *error;
        [fileManager copyItemAtPath:pathForFile toPath:self.backupLocation error:&error];
        
        if(error) {
            [self showErrorPrompt:@"Error making a backup of chat.db" informationText:[NSString stringWithFormat:@"We were not able to make a backup of your Messages.db\n%@", [error description]]];
            NSLog(@"ERROR COPYING FILE: %@", error.description);
        }
        else {
            NSLog(@"Copied DB\nFROM: %@\nTO: %@\n", pathForFile, self.backupLocation);
            [self showMainWindow:self.backupLocation];
        }
        
    }
    else {
        [self showErrorPrompt:@"Error finding chat.db" informationText:[NSString stringWithFormat:@"Error finding Mac's Messages.app chat database at %@. \n\nMaybe Messages.app is not synced with an iCloud account", pathForFile]];
    }
}

- (void) iPhoneDataSource
{
    NSString *fileName = @"3d0d7e5fb2ce288813306e4d4636395e047a3d28";
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSOpenPanel *directoryPanel = [NSOpenPanel openPanel];
    [directoryPanel setCanChooseDirectories:YES];
    
    [directoryPanel setCanChooseFiles:NO];
    [directoryPanel setCanHide:NO];
    [directoryPanel setCanCreateDirectories:NO];
    [directoryPanel setTitle:@"Choose the iPhone backup"];
    [directoryPanel setMessage:@"Open the directory of the iPhone backup to analyze"];
    [directoryPanel setDirectoryURL:[NSURL fileURLWithPath:self.iPhonePath]];
    
    if([directoryPanel runModal] == NSModalResponseOK) {
        NSArray *files = [directoryPanel URLs];
        
        if(files.count == 0) {
            [self showErrorPrompt:@"No backups found" informationText:@"No backups found in this directory"];
            return;
        }
        
        NSString *filePath = [((NSURL*) files[0]) path];
        if([filePath isEqualToString:self.iPhonePath]) {
            [self showErrorPrompt:@"No backup was chosen" informationText:@"No backup was chosen"];
            return;
        }
        
        //iOS 10 backup - the default
        NSString *iPhoneBackup = [NSString stringWithFormat:@"%@/3d/%@", filePath, fileName];
        
        //Is this not an iOS 10 backup?
        if(![fileManager fileExistsAtPath:iPhoneBackup]) {
            iPhoneBackup = [NSString stringWithFormat:@"%@/%@", filePath, fileName];
        }
        
        if([fileManager fileExistsAtPath:iPhoneBackup]) {
            
            NSError *error;
            [fileManager copyItemAtPath:iPhoneBackup toPath:self.backupLocation error:&error];
            if(error) {
                [self showErrorPrompt:@"Error making a backup of iPhone chat" informationText:[NSString stringWithFormat:@"We were not able to make a backup of your Messages.db\n%@", [error description]]];
            }
            else {
                NSLog(@"Copied DB\nFROM: %@\nTO: %@\n", iPhoneBackup, self.backupLocation);
                [self showMainWindow:self.backupLocation];
            }
        }
        else {
            [self showErrorPrompt:@"iPhone backup not found" informationText:@"Either the iPhone's text message backups were not found in this directory or they were encrypted. When syncing or backing up with iTunes, disable encryption"];
            return;
        }
    }
}

- (void) specificFileDataSource
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    NSOpenPanel *directoryPanel = [NSOpenPanel openPanel];
    [directoryPanel setCanChooseDirectories:YES];
    
    [directoryPanel setCanChooseFiles:YES];
    [directoryPanel setCanChooseDirectories:NO];
    [directoryPanel setCanCreateDirectories:NO];
    [directoryPanel setAllowsMultipleSelection:NO];
    [directoryPanel setCanHide:NO];
    [directoryPanel setTitle:@"Choose the database file you would like to open"];
    [directoryPanel setMessage:@"Specify the file of the database you would like to analyze"];
    [directoryPanel setDirectoryURL:[NSURL fileURLWithPath:NSHomeDirectory()]];
    
    if([directoryPanel runModal] == NSModalResponseOK) {
        NSArray *files = [directoryPanel URLs];
        
        if(files.count == 0) {
            [self showErrorPrompt:@"No backups found" informationText:@"No backups found in this directory"];
            return;
        }
        
        NSString *databaseFilePath = [((NSURL*) files[0]) path];
        
        if(![fileManager fileExistsAtPath:databaseFilePath]) {
            [self showErrorPrompt:@"Database file not found"
                  informationText:@"Either the database file was not found in this directory or it is encrypted. When syncing or backing up with iTunes, disable encryption"];
            return;
        }
        
        NSError *error;
        [fileManager copyItemAtPath:databaseFilePath toPath:self.backupLocation error:&error];
        if(error) {
            [self showErrorPrompt:@"Error making a backup of the database file"
                  informationText:[NSString stringWithFormat:@"We were unable to make a backup of your Messages database \n%@", [error description]]];
        }
        else {
            NSLog(@"Copied DB\nFROM: %@\nTO: %@\n", databaseFilePath, self.backupLocation);
            [self showMainWindow:self.backupLocation];
        }
        //-----------------
        // Open the database
        /*
//        while (true) {
            sqlite3 *db;
            sqlite3_stmt *stmt;
            int rc;
            
            NSString *databasePath = self.backupLocation;
            rc = sqlite3_open([databasePath UTF8String], &db);
            if (rc != SQLITE_OK) {
                // Error handling goes here
            }
            
            // Prepare the SELECT statement
            const char *sql = "SELECT ROWID, attributedBody FROM message WHERE text IS NULL AND attributedBody != '' ORDER BY date DESC";
            rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
            if (rc != SQLITE_OK) {
                // Error handling goes here
            }
            
            // Bind the parameter to the statement
            rc = sqlite3_bind_text(stmt, 1, "some value", -1, SQLITE_STATIC);
            if (rc != SQLITE_OK) {
                // Error handling goes here
            }
            
            NSMutableDictionary *toUpdate = [[NSMutableDictionary alloc] init];
            
            // Step through the result set
            while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
                // Extract the field of type blob
                
                int rowid = sqlite3_column_int(stmt, 0);
                NSLog(@"%d", rowid);
                
                const void *blob = sqlite3_column_blob(stmt, 1);
                int blob_size = sqlite3_column_bytes(stmt, 1);
                
                NSLog(@"%s", (char *) blob);
                
                NSData *data = [NSData dataWithBytes:blob length:blob_size];
                
                const char *bytes = [data bytes];
                char hexBuffer[2 * [data length] + 1]; // a buffer 2 times the size of data + 1 null character
                int len = 0;
                for (int i = 0; i < [data length]; i++) {
                    len += sprintf(hexBuffer + len, "%02x", bytes[i] & 0xff);
                }
                NSString* hexString = [NSString stringWithUTF8String:hexBuffer];
                NSRange range = [hexString rangeOfString:@"4e53537472696e67"];
                if (range.location != NSNotFound) {
                    hexString = [hexString substringFromIndex:range.location + range.length];
                    hexString = [hexString substringFromIndex:12];
                }
                range = [hexString rangeOfString:@"8684"];
                if (range.location != NSNotFound) {
                    hexString = [hexString substringToIndex:range.location];
                }
                NSLog(@"%@", hexString);
                //            hexString = [hexString stringByReplacingOccurrencesOfString:@" " withString:@""];
                NSMutableData *newData= [[NSMutableData alloc] init];
                unsigned char whole_byte;
                char byte_chars[3] = {'\0','\0','\0'};
                int i;
                for (i=0; i < [hexString length]/2; i++) {
                    byte_chars[0] = [hexString characterAtIndex:i*2];
                    byte_chars[1] = [hexString characterAtIndex:i*2+1];
                    whole_byte = strtol(byte_chars, NULL, 16);
                    [newData appendBytes:&whole_byte length:1];
                }
                NSString *result = [[NSString alloc] initWithData:newData encoding:NSUTF8StringEncoding];
                NSLog(@"%@", result);
                
                if (!result) {
                    continue;
                }
                
                [toUpdate setObject:result forKey:[NSNumber numberWithInt:rowid]];
                
                // Update the row's text field
                //            NSString *updateSQL = [NSString stringWithFormat:@"UPDATE tablename SET text = '%@' WHERE rowid = %d", result, rowid];
                //            const char *update_stmt = [updateSQL UTF8String];
                /*
                 NSString *updateSQL = [NSString stringWithFormat:@"UPDATE message SET text = '%@' WHERE ROWID = %d", result, rowid];
                 const char *updateSql = [updateSQL UTF8String];
                 
                 //            char *updateSql = "UPDATE message SET text = 'new_text' WHERE rowid = x";
                 char *errMsg;
                 int updateResult = sqlite3_exec(db, updateSql, NULL, NULL, &errMsg);
                 if (updateResult != SQLITE_OK) {
                 NSLog(@"Error");
                 // Handle the error
                 }
                 
                
                NSLog(@"----------------------");
            }
            
            // Finalize the statement
            rc = sqlite3_finalize(stmt);
            if (rc != SQLITE_OK) {
                // Error handling goes here
            }
            
            
            
            for (id key in toUpdate) {
                NSString *value = [toUpdate objectForKey:key];
                if (!value) {
                    continue;
                }
                value = [value stringByReplacingOccurrencesOfString:@"'" withString:@"''"];
                NSString *sql = [NSString stringWithFormat:@"UPDATE message SET text = '%@' WHERE rowid = %@", value, key];
                NSLog(@"%@", sql);
                char *err_msg;
                sqlite3_exec(db, [sql UTF8String], NULL, NULL, &err_msg);
                if (err_msg != nil) {
                    NSLog(@"SQL Error: %s", err_msg);
                }
            }
            */
            // Close the database
//            rc = sqlite3_close(db);
//            if (rc != SQLITE_OK) {
//                // Error handling goes here
//            }
        /*
            sql = "SELECT text FROM message WHERE rowid = 384496";
            rc = sqlite3_prepare_v2(db, sql, -1, &stmt, NULL);
            if (rc != SQLITE_OK) {
                // Error handling goes here
            }
            
            // Bind the parameter to the statement
            rc = sqlite3_bind_text(stmt, 1, "some value", -1, SQLITE_STATIC);
            if (rc != SQLITE_OK) {
                // Error handling goes here
            }
                        
            // Step through the result set
            while ((rc = sqlite3_step(stmt)) == SQLITE_ROW) {
                // Extract the field of type blob
                
                const unsigned char *text = sqlite3_column_text(stmt, 0);
                NSLog(@"384496: %s", text);
            }
        */
//        }
        
        
    }
}

- (void) showErrorPrompt:(NSString*)messageText informationText:(NSString*)informationText
{
    NSAlert *prompt = [[NSAlert alloc] init];
    [prompt setAlertStyle:NSWarningAlertStyle];
    [prompt setMessageText:messageText];
    [prompt setInformativeText:informationText];
    [prompt addButtonWithTitle:@"Return to main screen"];
    [prompt beginSheetModalForWindow:self.window completionHandler:nil];
}

- (void) showMainWindow:(NSString*)databasePath
{
    self.mainWindowController = [[MainWindowController alloc] initWithWindowNibName:@"MainWindowController" databasePath:databasePath];
    [self.mainWindowController showWindow:self];
    [self.mainWindowController.window makeKeyAndOrderFront:self];
    [self.window close];
}


/****************************************************************
 *
 *              NSWindow Delegate
 *
 *****************************************************************/

# pragma mark - NSWindow Delegate

- (NSSize) windowWillResize:(NSWindow *)sender toSize:(NSSize)frameSize
{
    return self.window.frame.size;
}

@end
