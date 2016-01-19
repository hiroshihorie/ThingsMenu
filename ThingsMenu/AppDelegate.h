//
//  AppDelegate.h
//  ThingsMenu
//
//  Created by Hiroshi Horie on 2013/03/27.
//  Copyright (c) 2013 mobiq, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate, NSMenuDelegate>
@property (strong, readonly) NSStatusItem *statusItem;
@property (strong, readonly) NSMenu *statusMenu;
@end
