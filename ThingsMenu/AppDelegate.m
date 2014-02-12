//
//  AppDelegate.m
//  ThingsMenu
//
//  Created by Hiroshi Horie on 2013/03/27.
//  Copyright (c) 2013年 Mobiq, Inc. All rights reserved.
//

#import "AppDelegate.h"

#import "FMDatabase.h"
#import "FMDatabaseAdditions.h"
#import "FMDatabasePool.h"
#import "FMDatabaseQueue.h"

NSInteger const kTagTask = 10;

@interface AppDelegate()
- (void)clearMenu;
@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    // Insert code here to initialize your application

    NSImage *statusItemImage = [NSImage imageNamed:@"status-item"];
    [statusItemImage setTemplate:YES];

    NSImage *exitImage = [NSImage imageNamed:@"icon-exit"];
    [exitImage setTemplate:YES];
    
    NSString *version = [[NSBundle mainBundle] infoDictionary][@"CFBundleVersion"];
    
    _statusMenu = [[NSMenu alloc] init];
    _statusMenu.delegate = self;
    _statusMenu.font = [NSFont systemFontOfSize:12.0f];
    //_statusMenu.autoenablesItems = NO;
    
    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    [_statusItem setImage:statusItemImage];
    [_statusItem setHighlightMode:YES];
    [_statusItem setMenu:_statusMenu];
    
    //_statusItem.doubleAction = @selector(launchThings:);
    
    NSMenuItem *menuItem = nil;
    
    menuItem = [_statusMenu addItemWithTitle:@"Things"
                                      action:@selector(launchThings:)
                               keyEquivalent:@""];
    [menuItem setImage:[NSImage imageNamed:@"Things"]];
    
//    menuItem = [_statusMenu addItemWithTitle:NSLocalizedString(@"Preferences...", nil) action:@selector(preferencesAction:) keyEquivalent:@""];
//    [menuItem setImage:gearImage];

    menuItem = [_statusMenu addItemWithTitle:[NSString stringWithFormat:
                                              NSLocalizedString(@"ThingsMenu(%@) Check for Updates...", nil), version]
                                      action:@selector(checkForUpdates:) keyEquivalent:@""];
//    [menuItem setImage:exitImage];

    menuItem = [_statusMenu addItemWithTitle:NSLocalizedString(@"Quit", nil) action:@selector(quitAction:) keyEquivalent:@""];
    //[menuItem setImage:exitImage];

    
    [_statusMenu addItem:[NSMenuItem separatorItem]];

}

- (void)quitAction:(id)sender {
    [NSApp terminate:self];
}

- (void)clearMenu {
    NSMenuItem *taskItem;
    while ((taskItem = [_statusMenu itemWithTag:kTagTask])) {
        [_statusMenu removeItem:taskItem];
    }
}

- (void)menuWillOpen:(NSMenu *)menu {
    NSImage *checkboxNotDoneImage = [NSImage imageNamed:@"checkbox_yellow-N"];
    NSImage *checkboxDoneImage = [NSImage imageNamed:@"checkbox_done-N"];
    [checkboxDoneImage setTemplate:YES];

    //[checkboxImage setTemplate:YES];

    NSString *bundleName = [[NSBundle mainBundle] infoDictionary][@"CFBundleIdentifier"];
    NSString *tempDir = [NSTemporaryDirectory() stringByAppendingPathComponent:bundleName];
    NSString *tempDBPath = [tempDir stringByAppendingString:@"/ThingsLibrary.tmp.db"];
    NSString *tempDBJournalPath = [tempDir stringByAppendingString:@"/ThingsLibrary.tmp.db-journal"];

    // create the temp dir if doesn't exist
    [[NSFileManager defaultManager] createDirectoryAtPath:tempDir withIntermediateDirectories:NO attributes:nil error:nil];

    // get path for user library dir
    NSArray *dirs = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    if ([dirs count]) {
        NSString *dbDir = [dirs[0] stringByAppendingString:@"/Containers/com.culturedcode.things/Data/Library/Application Support/Cultured Code/Things/"];
        NSString *dbPath = [dbDir stringByAppendingString:@"ThingsLibrary.db"];
        NSString *dbJournalPath = [dbDir stringByAppendingString:@"ThingsLibrary.db-journal"];

        [[NSFileManager defaultManager] removeItemAtPath:tempDBPath error:nil];
        [[NSFileManager defaultManager] copyItemAtPath:dbPath
                                                toPath:tempDBPath
                                                 error:nil];
        [[NSFileManager defaultManager] removeItemAtPath:tempDBJournalPath error:nil];
        [[NSFileManager defaultManager] copyItemAtPath:dbJournalPath
                                                toPath:tempDBJournalPath
                                                 error:nil];
        //NSLog(@"tempDBPath : %@", tempDBPath);

    }

    NSMutableArray *tasks = [NSMutableArray array];
    NSMutableDictionary *projects = [NSMutableDictionary dictionary];
    
    FMDatabase *db = [FMDatabase databaseWithPath:tempDBPath];
    if ([db open]) {
        
        NSMutableSet *projectIndexes = [NSMutableSet set];

        NSString *sql = @"SELECT Z_PK, ZTITLE, ZSTATUS, ZPROJECT, ZAREA, ZNOTES FROM ZTHING WHERE ZTYPE IS NOT NULL AND ZTRASHED = 0 AND ZSTARTDATE IS NOT NULL AND ZSTOPPEDDATE IS NULL ORDER BY ZTODAYINDEX";
        FMResultSet *todayResult = [db executeQuery:sql];
        
        while ([todayResult next]) {
            NSDictionary *columns = [todayResult resultDictionary];

            // build the indexes
            if (columns[@"ZPROJECT"] != [NSNull null]) [projectIndexes addObject:columns[@"ZPROJECT"]];
            if (columns[@"ZAREA"] != [NSNull null]) [projectIndexes addObject:columns[@"ZAREA"]];

            [tasks addObject:columns];
        }
        
        if ([projectIndexes count]) {
            NSString *sql = [NSString stringWithFormat:@"SELECT Z_PK, ZTITLE FROM ZTHING WHERE Z_PK IN (%@)",
                             [[projectIndexes allObjects] componentsJoinedByString:@","]];
            FMResultSet *projectResult = [db executeQuery:sql];
            while ([projectResult next]) {
                NSDictionary *columns = [projectResult resultDictionary];
                projects[columns[@"Z_PK"]] = columns;
            }
        }
    

        [db close];
    }

    
    NSDictionary *taskAttributes = @{
                                     NSForegroundColorAttributeName: [NSColor blackColor],
                                     NSFontAttributeName: [NSFont systemFontOfSize:14.0f],
                                     //NSParagraphStyleAttributeName
                                     };
    
    //NSMutableParagraphStyle *p = [[NSMutableParagraphStyle alloc] init];
    
    NSDictionary *projectAttributes = @{
                                        NSForegroundColorAttributeName: [NSColor grayColor],
                                        NSFontAttributeName: [NSFont systemFontOfSize:10.0f],
                                        //NSParagraphStyleAttributeName: p,
                                        };

    [self clearMenu];
    for (NSDictionary *task in tasks) {
        NSMenuItem *menuItem = [[NSMenuItem alloc] init];
        menuItem.action = @selector(taskAction:);
        menuItem.tag = kTagTask;
        NSMutableAttributedString *attributedTitle = [[NSMutableAttributedString alloc] initWithString:task[@"ZTITLE"]
                                                                                            attributes:taskAttributes];
        
        if (task[@"ZPROJECT"] != [NSNull null] || task[@"ZAREA"] != [NSNull null]) {
            NSString *string = projects[task[@"ZPROJECT"]][@"ZTITLE"];
            if ( ! string) {
                string = projects[task[@"ZAREA"]][@"ZTITLE"];
            }

            NSAttributedString *attributedProject = [[NSAttributedString alloc] initWithString:
                                                     [NSString stringWithFormat:@"  %@", string]
                                                                                    attributes:projectAttributes];
            //[attributedTitle insertAttributedString:attributedProject atIndex:0];
            [attributedTitle appendAttributedString:attributedProject];
        }
        
        menuItem.attributedTitle = attributedTitle;
        
        if ([task[@"ZSTATUS"] intValue] == 3) {
            [menuItem setImage:checkboxDoneImage];
        //    menuItem.action = nil;
        } else {
            [menuItem setImage:checkboxNotDoneImage];
            //menuItem.action = @selector(launchThings:);
        }
        
        [_statusMenu addItem:menuItem];
        
        if (task[@"ZNOTES"] != [NSNull null] ) {
            NSMenu *subMenu = [[NSMenu alloc] init];
            NSMenuItem *subMenuItem = [[NSMenuItem alloc] init];
            NSData *noteData = [task[@"ZNOTES"] dataUsingEncoding:NSUTF8StringEncoding];
            NSAttributedString *attributedNote = [[NSAttributedString alloc] initWithHTML:noteData options:nil documentAttributes:nil];
            NSLog(@"a : %@", attributedNote);
            subMenuItem.attributedTitle = attributedNote;
            [subMenu addItem:subMenuItem];
            [menuItem setSubmenu:subMenu];
        }
        
        
        //[_statusMenu addItem:[NSMenuItem separatorItem]];
    }

    NSMenuItem *menuItem = [_statusMenu itemWithTag:kTagTask];
    if ( ! menuItem) {
        menuItem = [[NSMenuItem alloc] init];
        menuItem.title = NSLocalizedString(@"No unfinished tasks Today !", nil);
        menuItem.tag = kTagTask;
        [_statusMenu addItem:menuItem];
    }
    
}

- (void)taskAction:(id)sender {
    [self launchThings:sender];
}

- (void)launchThings:(id)sender {
    BOOL success = [[NSWorkspace sharedWorkspace] launchApplication:@"/Applications/Things.app"];
    if ( ! success) {
        [[NSAlert alertWithMessageText:@"Failed to launch Things"
                         defaultButton:@"OK"
                       alternateButton:nil
                           otherButton:nil
             informativeTextWithFormat:@""] runModal];
        
    }
}
- (void)checkForUpdates:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:@"http://mobiq-inc.com/thingsmenu"]];
}

@end
