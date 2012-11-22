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
            _fileURL = [NSURL fileURLWithPath:@"./out.aiff"];
            
//            _audioStreamBasicDescription.mSampleRate = 0;
//            _audioStreamBasicDescription.mFormatID = kAudioFormatMPEGLayer3;
//            _audioStreamBasicDescription.mFormatFlags = 0; //no flags supported
//            _audioStreamBasicDescription.mBytesPerPacket = 2;
//            _audioStreamBasicDescription.mFramesPerPacket = 1;
//            _audioStreamBasicDescription.mBytesPerFrame = 2;
//            _audioStreamBasicDescription.mChannelsPerFrame = 2;
//            _audioStreamBasicDescription.mBitsPerChannel = 16;
            
            
            
            
            
            _theErr = NewSpeechChannel(NULL,&_speechChennel);
            
            _theErr = SetSpeechProperty (_speechChennel,kSpeechOutputToFileURLProperty, NULL);

            
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
    [super showWindow:sender];
}
- (IBAction)speakButtonPressed:(id)sender
{
    NSArray* fieldStringArray = [DataBaseQuery textQueryWithFile:[_databaseURL relativePath] AndQsql:@"SELECT sql FROM sqlite_master WHERE tbl_name = 'words'"];
    for (NSArray* recordI in fieldStringArray)
    {
        NSLog(@"%@",[recordI objectAtIndex:0]);
    }
    NSArray* contentStringArray = [DataBaseQuery textQueryWithFile:[_databaseURL relativePath] AndQsql:@"select russian from words where section=1"];
    
    for (NSArray* recordI in contentStringArray)
    {
        NSLog(@"%@",[recordI objectAtIndex:0]);
        _fileURL = [NSURL fileURLWithPath:[NSString stringWithFormat:@"./%@.aiff",[recordI objectAtIndex:0] ] ];
        CFURLRef fileCFURLRef = (__bridge CFURLRef)_fileURL;
        
        _theErr = SetSpeechProperty (_speechChennel,kSpeechOutputToFileURLProperty, fileCFURLRef);
        
        CFStringRef cFStringRef = (__bridge CFStringRef)[recordI objectAtIndex:0];
        
        _theErr = SpeakCFString(_speechChennel, cFStringRef, NULL);

    }
        
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
            // Open  the document.
        }
    }];
    
    
    
}
- (void)dealloc
{
    _theErr = DisposeSpeechChannel(_speechChennel);
}
@end
