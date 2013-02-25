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
#import "CoreFoundation/CoreFoundation.h"


@interface WindowController ()
- (BOOL) tryToEnableConvertButton;
- (void) convertAndPlace;
@end

@implementation WindowController
@synthesize tableNameTextField, fieldNameTextField, pathFieldTextField, dbInfoTextView;
@synthesize convertButton, insertButton;
static Boolean loopStop;
static SpeechChannel speechChennel;

static pascal void MySpeechDoneProc (SpeechChannel chan, SRefCon refCon);

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
            _theErr = NewSpeechChannel(NULL,&speechChennel);
            
            CFNumberRef callback = CFNumberCreate(NULL, kCFNumberLongType, MySpeechDoneProc);
            _theErr = SetSpeechProperty (speechChennel,kSpeechTextDoneCallBack, callback);
            
//            _theErr = SetSpeechProperty (_speechChennel,kSpeechOutputToFileURLProperty, NULL);
            dbFileIsSelected = NO;
            tableIsSelected = NO;
            fieldIsSelected = NO;
            
        }
    return self;
}

- (void)windowDidLoad
{
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
    [convertButton setEnabled:NO];
    [insertButton setEnabled:NO];
}

- (IBAction)showWindow:(id)sender
{
    [super showWindow:sender];
}

- (BOOL) tryToEnableConvertButton
{
    if (dbFileIsSelected && tableIsSelected && fieldIsSelected)
    {
        [convertButton setEnabled:YES];
        [insertButton setEnabled:YES];
        return YES;
    }
    return NO;
}

- (void)convertAndPlace
{
    NSArray* contentStringArray = [DataBaseQuery textQueryWithFile:[_databaseURL relativePath] AndQsql:[NSString stringWithFormat:@"select %@,rowid,section from %@",fieldNameTextField.stringValue,tableNameTextField.stringValue] ];
    
    CFURLRef fileCFURLRef = NULL;
    


    for (NSArray* recordI in contentStringArray)
    {
        loopStop = true;
        fieldNameTextField.stringValue=@"english";
        //NSLog(@"%@",[recordI objectAtIndex:0]);
        //        _fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"./%@_%@_%@.aiff", [recordI objectAtIndex:1], [recordI objectAtIndex:2], [recordI objectAtIndex:0] ] ];
        NSString* lool1=[recordI objectAtIndex:1];
        NSString* lool2=[recordI objectAtIndex:2];
        NSString* lool3=@"english";
        NSString* lool4=[recordI objectAtIndex:0];
        NSString* tempString = [NSString stringWithFormat:@"%@_%@_%@_%@.aiff", lool1, lool2, lool3, lool4];
        NSLog(@"%@",tempString);
        _fileURL = [[_saveDirectoryURL URLByAppendingPathComponent:tempString] copy];
        fileCFURLRef = CFBridgingRetain(_fileURL);
        _theErr = SetSpeechProperty (speechChennel,kSpeechOutputToFileURLProperty, fileCFURLRef);
        
        
        CFStringRef cFStringRef = CFBridgingRetain([recordI objectAtIndex:0]);
        
        _theErr = SpeakCFString(speechChennel, cFStringRef, NULL);
        //while (loopStop) {}
    }
    [convertButton setEnabled:NO];
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
- (IBAction)convertButtonPressed:(id)sender
{

    NSOpenPanel* directoryChooserPanel = [NSOpenPanel openPanel];
    [directoryChooserPanel setCanChooseDirectories:YES];
    [directoryChooserPanel setCanCreateDirectories:YES];
    [directoryChooserPanel setPrompt:@"Choose"];
    [directoryChooserPanel beginWithCompletionHandler:^(NSInteger result)
    {
        
        if (result == NSFileHandlingPanelOKButton)
        {
            _saveDirectoryURL = [directoryChooserPanel directoryURL];
            [self convertAndPlace];
        }
    }];
    
        
}

- (IBAction)insertButtonPressed:(id)sender
{
    NSMutableArray* qsqlArray = [NSMutableArray new];
    NSArray* contentStringArray = [DataBaseQuery textQueryWithFile:[_databaseURL relativePath] AndQsql:[NSString stringWithFormat:@"select %@,rowid,section from %@",fieldNameTextField.stringValue,tableNameTextField.stringValue] ];
    
    int i = 1;
    for (NSArray* recordI in contentStringArray)
    {
        NSString* qsqlStringI = [NSString stringWithFormat:@"UPDATE %@ SET %@='%@_%@_%@_%@.mp3' WHERE rowid='%d'",tableNameTextField.stringValue, pathFieldTextField.stringValue, [recordI objectAtIndex:1], [recordI objectAtIndex:2], fieldNameTextField.stringValue, [recordI objectAtIndex:0], i];
        NSLog(qsqlStringI);
        [qsqlArray addObject: qsqlStringI];
        ++i;
    }
    
    [DataBaseQuery executeQsqlArray:qsqlArray inFile:[_databaseURL relativePath]];
     
    [insertButton setEnabled:NO];
}
- (void)dealloc
{
    
}
static pascal void MySpeechDoneProc (SpeechChannel chan, SRefCon refCon)
{
    @autoreleasepool
    {
        int i =6;
        // Code benefitting from a local autorelease pool.
    }
    
}
@end
