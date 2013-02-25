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
    
    NSURL* _fileURL;
    NSURL* _databaseURL;
    NSURL* _saveDirectoryURL;
    AudioStreamBasicDescription _audioStreamBasicDescription;
    ExtAudioFileRef _extAudioFileRef;
    NSNumber* _extAudioFileRef_NSNumber;
    
    
    BOOL dbFileIsSelected;
    BOOL tableIsSelected;
    BOOL fieldIsSelected;

}

@property (strong, atomic) IBOutlet NSTextField* tableNameTextField;
@property (strong, atomic) IBOutlet NSTextField* fieldNameTextField;
@property (strong, atomic) IBOutlet NSTextField* pathFieldTextField;
@property (strong, atomic) IBOutlet NSTextView* dbInfoTextView;

@property (strong, atomic) IBOutlet NSButton* convertButton;
@property (strong, atomic) IBOutlet NSButton* insertButton;

//@property (assign) SpeechChannel speechChennel;

- (IBAction)openExistingDocument:(id)sender;
- (IBAction)checkButtonPressed:(id)sender;

- (IBAction)convertButtonPressed:(id)sender;
- (IBAction)insertButtonPressed:(id)sender;

@end
