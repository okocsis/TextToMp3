//
//  AppDelegate.h
//  TextToMp3
//
//  Created by Kocsis Olivér on 2012.11.05..
//  Copyright (c) 2012 sciapps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "WindowController.h"
@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (assign) IBOutlet NSWindow *window;


@property (assign) IBOutlet WindowController* windowController;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;

- (IBAction)saveAction:(id)sender;

@end
