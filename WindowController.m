//
//  WindowController.m
//  TextToMp3
//
//  Created by Kocsis Olivér on 2012.11.11..
//  Copyright (c) 2012 sciapps. All rights reserved.
//

#import "WindowController.h"
#import "ApplicationServices/ApplicationServices.h"
@interface WindowController ()

@end

@implementation WindowController
@synthesize textField;

- (id)init
{
    self=[self initWithWindowNibName:@"WindowController"];
    return self;
}

- (id)initWithWindowNibName:(NSString *)windowNibName
{
        self = [super initWithWindowNibName:windowNibName];
        if (self)
        {
            [self showWindow:self];
            // Initialization code here.
        }
    return self;
}
- (void)windowWillLoad
{
    [super windowWillLoad];
}
- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    self.textField.stringValue = @"Hello!";    
}
- (IBAction)showWindow:(id)sender
{
    
}
@end
