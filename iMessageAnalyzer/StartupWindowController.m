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
    NSString *description = [NSString stringWithFormat:@"Choose the source from which to analyze your messages:\n\nThe default Mac Messages.app: %@\n\nThe most recent iPhone backup: %@\n\nPlease note the following loading might take some time as the database is being copied to the file's directory so that the original will not be corrupted.\nThat temporary database will be deleted when the app is exited.", self.messagesPath, self.iPhonePath];
    
    NSAlert *prompt = [[NSAlert alloc] init];
    [prompt setAlertStyle:NSWarningAlertStyle];
    [prompt setMessageText:@"Choose Messages database source"];
    [prompt setInformativeText:description];
    [prompt addButtonWithTitle:@"Messages.app"];
    [prompt addButtonWithTitle:@"iPhone backup"];
    
    [prompt beginSheetModalForWindow:self.window completionHandler:^(NSModalResponse response) {
        switch (response) {
            case NSAlertFirstButtonReturn:
                [self messagesDataSource];
                break;
            case NSAlertSecondButtonReturn:
                [self iPhoneDataSource];
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
