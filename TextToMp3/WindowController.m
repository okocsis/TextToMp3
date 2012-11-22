//
//  WindowController.m
//  TextToMp3
//
//  Created by Kocsis Olivér on 2012.11.11..
//  Copyright (c) 2012 sciapps. All rights reserved.
//

#import "WindowController.h"
#import "ApplicationServices/ApplicationServices.h"
#import "AudioToolbox/AudioToolbox.h"
#import "DataBaseQuery.h"


@interface WindowController ()
- (BOOL) tryToEnableConvertButton;
@end

@implementation WindowController
@synthesize tableNameTextField, fieldNameTextField, dbInfoTextView;
@synthesize convertButton;

- (BOOL) tryToEnableConvertButton
{
    if (dbFileIsSelected && tableIsSelected && fieldIsSelected)
    {
        [convertButton setEnabled:YES];
        return YES;
    }
    return NO;
}


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
            _theErr = NewSpeechChannel(NULL,&_speechChennel);
            
            _theErr = SetSpeechProperty (_speechChennel,kSpeechOutputToFileURLProperty, NULL);
            dbFileIsSelected = NO;
            tableIsSelected = NO;
            fieldIsSelected = NO;
            
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
    [convertButton setEnabled:NO];
}

- (IBAction)showWindow:(id)sender
{
    [super showWindow:sender];
}
- (IBAction)convertButtonPressed:(id)sender
{
    
    
    NSArray* contentStringArray = [DataBaseQuery textQueryWithFile:[_databaseURL relativePath] AndQsql:[NSString stringWithFormat:@"select %@,rowid,section from %@",fieldNameTextField.stringValue,tableNameTextField.stringValue] ];
    
    for (NSArray* recordI in contentStringArray)
    {
        //NSLog(@"%@",[recordI objectAtIndex:0]);
        _fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"./%@_%@_%@.aiff", [recordI objectAtIndex:1], [recordI objectAtIndex:2], [recordI objectAtIndex:0] ] ];
        CFURLRef fileCFURLRef = (__bridge CFURLRef)_fileURL;
        
        _theErr = SetSpeechProperty (_speechChennel,kSpeechOutputToFileURLProperty, fileCFURLRef);
        
        CFStringRef cFStringRef = (__bridge CFStringRef)[recordI objectAtIndex:0];
        
        _theErr = SpeakCFString(_speechChennel, cFStringRef, NULL);

    }
    [sender setEnabled:NO];
        
}

- (IBAction)openExistingDocument:(id)sender {
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    
    // This method displays the panel and returns immediately.
    // The completion handler is called when the user selects an
    // item or cancels the panel.
    [panel beginWithCompletionHandler:^(NSInteger result)
    {
        if (result == NSFileHandlingPanelOKButton)
        {
            _databaseURL = [[panel URLs] objectAtIndex:0];
            dbFileIsSelected = YES;
            NSArray* fieldStringArray = [DataBaseQuery textQueryWithFile:[_databaseURL relativePath] AndQsql:@"SELECT sql FROM sqlite_master"];
            for (NSArray* recordI in fieldStringArray)
            {
                [dbInfoTextView insertText:[recordI objectAtIndex:0]]; ;
            }
            
            // Open  the document.
        }
    }];
    
    
    
}
- (IBAction)checkButtonPressed:(id)sender
{
    tableIsSelected = [tableNameTextField.stringValue isEqualToString:@""] ? NO : YES;
    fieldIsSelected = [fieldNameTextField.stringValue isEqualToString:@""] ? NO : YES;
    [self tryToEnableConvertButton];
}
- (void)dealloc
{
    _theErr = DisposeSpeechChannel(_speechChennel);
}
@end
