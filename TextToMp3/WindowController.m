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

void MySpeechDoneProc (SpeechChannel chan,long refCon);



@implementation WindowController
@synthesize tableNameTextField, fieldNameTextField, pathFieldTextField, dbInfoTextView;
@synthesize convertButton, insertButton;
@synthesize _speechChennel;
void MySpeechDoneProc (SpeechChannel chan,long refCon)
{
    voidPtr temp = refCon;
    WindowController* self = (__bridge WindowController *)(temp);
    self->fileExportIsReady = YES;
    
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
            
            NSInteger speechDoneIntPointer = &MySpeechDoneProc;
            
            _number = CFNumberCreate(NULL, kCFNumberNSIntegerType, &speechDoneIntPointer );
            _theErr = SetSpeechProperty (_speechChennel,kSpeechSpeechDoneCallBack, _number);
            
            
            NSInteger intSelf = self;
            
            _numberSelf = CFNumberCreate(NULL, kCFNumberNSIntegerType, &intSelf );
            _theErr = SetSpeechProperty (_speechChennel,kSpeechRefConProperty, _numberSelf);
            
            
            dbFileIsSelected = NO;
            tableIsSelected = NO;
            fieldIsSelected = NO;
            fileExportIsReady = NO;
            
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
    NSArray* contentStringArray = [DataBaseQuery textQueryWithFile:[_databaseURL relativePath]
                                                           AndQsql:[NSString stringWithFormat:@"select %@,rowid,section from %@",
                                                                    fieldNameTextField.stringValue,
                                                                    tableNameTextField.stringValue] ];
    

    for (NSArray* recordI in contentStringArray)
    {

        //NSLog(@"%@",[recordI objectAtIndex:0]);
        //        _fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"./%@_%@_%@.aiff", [recordI objectAtIndex:1], [recordI objectAtIndex:2], [recordI objectAtIndex:0] ] ];

        _fileURL = [_saveDirectoryURL URLByAppendingPathComponent:[NSString stringWithFormat:@"./%@_%@_%@_%@.aiff",
                                                                   [recordI objectAtIndex:1],
                                                                   [recordI objectAtIndex:2],
                                                                   fieldNameTextField.stringValue,
                                                                   [recordI objectAtIndex:0] ]];
        CFURLRef fileCFURLRef = (__bridge CFURLRef)_fileURL;
        
        _theErr = SetSpeechProperty (_speechChennel,kSpeechOutputToFileURLProperty, fileCFURLRef);
            
        CFStringRef cFStringRef = (__bridge CFStringRef)[recordI objectAtIndex:0];
        
        _theErr = SpeakCFString(_speechChennel, cFStringRef, NULL);
        while (!fileExportIsReady);
        fileExportIsReady = NO;
        
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
        NSString* qsqlStringI = [NSString stringWithFormat:@"UPDATE %@ SET %@='%@_%@_%@_%@.mp3' WHERE rowid='%d'",
                                 tableNameTextField.stringValue,
                                 pathFieldTextField.stringValue,
                                 [recordI objectAtIndex:1],
                                 [recordI objectAtIndex:2],
                                 fieldNameTextField.stringValue,
                                 [recordI objectAtIndex:0], i];
        NSLog(qsqlStringI);
        [qsqlArray addObject: qsqlStringI];
        ++i;
    }
    
    [DataBaseQuery executeQsqlArray:qsqlArray
                             inFile:[_databaseURL relativePath]];
     
    [insertButton setEnabled:NO];
}
- (void)dealloc
{
    
}

@end