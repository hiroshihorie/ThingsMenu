//
//  main.m
//  ThingsMenu
//
//  Created by Hiroshi Horie on 2013/03/27.
//  Copyright (c) 2013年 Mobiq, Inc. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "AppDelegate.h"

int main(int argc, char *argv[]) {
    @autoreleasepool {
        NSApplication * app = [NSApplication sharedApplication];
        
//        ProcessSerialNumber psn = { 0, kCurrentProcess };
//        TransformProcessType(&psn, kProcessTransformToUIElementApplication);
     
        id delegate = [[AppDelegate alloc] init];
        
        [app setDelegate:delegate];
        [app run];
    }
    return EXIT_SUCCESS;
}
