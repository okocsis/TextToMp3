//
//  WindowController.h
//  TextToMp3
//
//  Created by Kocsis Olivér on 2012.11.11..
//  Copyright (c) 2012 sciapps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ApplicationServices/ApplicationServices.h"
#import "CoreAudio/CoreAudioTypes.h"
#import "AudioToolbox/ExtendedAudioFile.h"

@interface WindowController : NSWindowController
{
    OSErr _theErr;
    
    SpeechChannel _speechChennel;
    NSURL* _fileURL;
    NSURL* _databaseURL;
    AudioStreamBasicDescription _audioStreamBasicDescription;
    ExtAudioFileRef _extAudioFileRef;
    NSNumber* _extAudioFileRef_NSNumber;
    
    BOOL dbFileIsSelected;
    BOOL tableIsSelected;
    BOOL fieldIsSelected;

}

@property (assign) IBOutlet NSTextField* tableNameTextField;
@property (assign) IBOutlet NSTextField* fieldNameTextField;
@property (assign) IBOutlet NSTextView* dbInfoTextView;

@property (assign) IBOutlet NSButton* convertButton;

- (IBAction)convertButtonPressed:(id)sender;
- (IBAction)checkButtonPressed:(id)sender;
- (IBAction)openExistingDocument:(id)sender;
@end
