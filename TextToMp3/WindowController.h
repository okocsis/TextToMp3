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
}

@property (assign) IBOutlet NSTextField* textField;

-(IBAction)speakButtonPressed:(id)sender;
- (IBAction)openExistingDocument:(id)sender;
@end
