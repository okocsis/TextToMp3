//
//  WindowController.h
//  TextToMp3
//
//  Created by Kocsis Olivér on 2012.11.11..
//  Copyright (c) 2012 sciapps. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "ApplicationServices/ApplicationServices.h"

@interface WindowController : NSWindowController
{
    OSErr _theErr;
    
    SpeechChannel _speechChennel;
}

@property (assign) IBOutlet NSTextField* textField;

-(IBAction)speakButtonPressed:(id)sender;
@end
