//
//  convertMain.cpp
//  TextToMp3
//
//  Created by Kocsis Olivér on 2012.11.15..
//  Copyright (c) 2012 sciapps. All rights reserved.
//

#include "convertMain.h"


#import <AudioToolbox/AudioToolbox.h>



#include "CAStreamBasicDescription.h"
#include "CAXException.h"


const UInt32 kSrcBufSize = 32768;

int ConvertFile (CFURLRef					inputFileURL,
                 CAStreamBasicDescription	&inputFormat,
                 CFURLRef					outputFileURL,
                 AudioFileTypeID				outputFileType,
                 CAStreamBasicDescription	&outputFormat,
                 UInt32                      outputBitRate)
{
	ExtAudioFileRef infile, outfile;
    
    // first open the input file
	OSStatus err = ExtAudioFileOpenURL (inputFileURL, &infile);
	XThrowIfError (err, "ExtAudioFileOpen");
	
	// if outputBitRate is specified, this can change the sample rate of the output file
	// so we let this "take care of itself"
	if (outputBitRate)
		outputFormat.mSampleRate = 0.;
    
	// create the output file (this will erase an exsiting file)
	err = ExtAudioFileCreateWithURL (outputFileURL, outputFileType, &outputFormat, NULL, kAudioFileFlags_EraseFile, &outfile);
	XThrowIfError (err, "ExtAudioFileCreateNew");
	
	// get and set the client format - it should be lpcm
	CAStreamBasicDescription clientFormat = (inputFormat.mFormatID == kAudioFormatLinearPCM ? inputFormat : outputFormat);
	UInt32 size = sizeof(clientFormat);
	err = ExtAudioFileSetProperty(infile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
	XThrowIfError (err, "ExtAudioFileSetProperty inFile, kExtAudioFileProperty_ClientDataFormat");
	
	size = sizeof(clientFormat);
	err = ExtAudioFileSetProperty(outfile, kExtAudioFileProperty_ClientDataFormat, size, &clientFormat);
	XThrowIfError (err, "ExtAudioFileSetProperty outFile, kExtAudioFileProperty_ClientDataFormat");
	
	if( outputBitRate > 0 ) {
		printf ("Dest bit rate: %d\n", (int)outputBitRate);
		AudioConverterRef outConverter;
		size = sizeof(outConverter);
		err = ExtAudioFileGetProperty(outfile, kExtAudioFileProperty_AudioConverter, &size, &outConverter);
		XThrowIfError (err, "ExtAudioFileGetProperty outFile, kExtAudioFileProperty_AudioConverter");
		
		err = AudioConverterSetProperty(outConverter, kAudioConverterEncodeBitRate,
										sizeof(outputBitRate), &outputBitRate);
		XThrowIfError (err, "AudioConverterSetProperty, kAudioConverterEncodeBitRate");
		
		// we have changed the converter, so we should do this in case
		// setting a converter property changes the converter used by ExtAF in some manner
		CFArrayRef config = NULL;
		err = ExtAudioFileSetProperty(outfile, kExtAudioFileProperty_ConverterConfig, sizeof(config), &config);
		XThrowIfError (err, "ExtAudioFileSetProperty outFile, kExtAudioFileProperty_ConverterConfig");
	}
	
	// set up buffers
	char srcBuffer[kSrcBufSize];
    
	// do the read and write - the conversion is done on and by the write call
	while (1)
	{
		AudioBufferList fillBufList;
		fillBufList.mNumberBuffers = 1;
		fillBufList.mBuffers[0].mNumberChannels = inputFormat.mChannelsPerFrame;
		fillBufList.mBuffers[0].mDataByteSize = kSrcBufSize;
		fillBufList.mBuffers[0].mData = srcBuffer;
        
		// client format is always linear PCM - so here we determine how many frames of lpcm
		// we can read/write given our buffer size
		UInt32 numFrames = (kSrcBufSize / clientFormat.mBytesPerFrame);
		
		// printf("test %d\n", numFrames);
        
		err = ExtAudioFileRead (infile, &numFrames, &fillBufList);
		XThrowIfError (err, "ExtAudioFileRead");
		if (!numFrames) {
			// this is our termination condition
			break;
		}
		
		err = ExtAudioFileWrite(outfile, numFrames, &fillBufList);
		XThrowIfError (err, "ExtAudioFileWrite");
	}
    
    // close
	ExtAudioFileDispose(outfile);
	ExtAudioFileDispose(infile);
	
    return 0;
}


void UsageString(int exitCode)
{
	printf ("Usage: ConvertFile /path/to/input/file [-d formatID] [-r sampleRate] [-bd bitDepth] [-f fileType] [-b bitrate] [-h]\n");
	printf ("    output file written is /tmp/outfile.<EXT FOR FORMAT>\n");
	printf ("    if -d is specified, out file is written with that format\n");
	printf ("       if no format is specified and input file is 'lpcm', IMA is written\n");
	printf ("       if input file is compressed (ie. not 'lpcm'), then 'lpcm' is written\n");
	printf ("    if -r is specified, input file's format must be ('lpcm') and output ('lpcm') is written with new sample rate\n");
	printf ("    if -bd is specified, input file's format must be compressed (ie. not 'lpcm') and output is written with new bit depth\n");
	printf ("    if -f is not specified, CAF File is written ('caff')\n");
	printf ("    if -b is specified, the bit rate for the output file when using a VBR encoder\n");
	printf ("    if -h is specified, will print out this usage message\n");
	exit(exitCode);
}

void str2OSType (const char * inString, OSType &outType)
{
	if (inString == NULL) {
		outType = 0;
		return;
	}
	
	size_t len = strlen(inString);
	if (len <= 4) {
		char workingString[5];
		
		workingString[4] = 0;
		workingString[0] = workingString[1] = workingString[2] = workingString[3] = ' ';
		memcpy (workingString, inString, strlen(inString));
		outType = 	*(workingString + 0) <<	24	|
        *(workingString + 1) <<	16	|
        *(workingString + 2) <<	8	|
        *(workingString + 3);
		return;
	}
    
	if (len <= 8) {
		int32_t tmp;
		if (sscanf (inString, "%x", &tmp) == 0) {
			printf ("* * Bad conversion for OSType\n");
			UsageString(1);
		}
		outType = tmp;
		
		return;
	}
	printf ("* * Bad conversion for OSType\n");
	UsageString(1);
}

void ParseArgs (int argc, char * const argv[],
                AudioFileTypeID	&	outFormat,
                Float64	&			outSampleRate,
                OSType	&			outFileType,
                CFURLRef&			outInputFileURL,
                CFURLRef&			outOutputFileURL,
                UInt32  &			outBitDepth,
                UInt32  &			outBitRate)
{
	if (argc < 2) {
		printf ("No Input File specified\n");
		UsageString(1);
	}
	
	// support "ConvertFile -h" usage
	if (argc == 2 && !strcmp("-h", argv[1])) {
		UsageString(0);
	}
	
	// first validate our initial condition
	const char* inputFileName = argv[1];
	
	outInputFileURL = CFURLCreateFromFileSystemRepresentation (kCFAllocatorDefault, (const UInt8 *)inputFileName, strlen(inputFileName), false);
	if (!outInputFileURL) {
		printf ("* * Bad input file path\n");
		UsageString(1);
    }
	
	outBitRate = 0;
	outBitDepth = 0;
	
	// look to see if a format or different file output has been specified
	for (int i = 2; i < argc; ++i) {
		if (!strcmp ("-d", argv[i])) {
			str2OSType (argv[++i], outFormat);
			outSampleRate = 0;
		}
		else if (!strcmp ("-r", argv[i])) {
			sscanf (argv[++i], "%lf", &outSampleRate);
			outFormat = 0;
		}
		else if (!strcmp("-bd", argv[i])) {
			int temp;
			sscanf (argv[++i], "%d", &temp);
			outBitDepth = temp;
		}
		else if (!strcmp ("-f", argv[i])) {
			str2OSType (argv[++i], outFileType);
		}
		else if (!strcmp ("-b", argv[i])) {
			int temp;
			sscanf (argv[++i], "%u", &temp);
			outBitRate = temp;
		}
		else if (!strcmp ("-h", argv[i])) {
			UsageString(0);
		}
		else {
			printf ("* * Unknown command: %s\n", argv[i]);
			UsageString(1);
		}
	}
	
    // output file
	UInt32 size = sizeof(CFArrayRef);
	CFArrayRef extensions;
	OSStatus err = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_ExtensionsForType,
                                          sizeof(OSType), &outFileType,
                                          &size, &extensions);
	XThrowIfError (err, "Getting the file extensions for file type");
    
	// just take the first extension
	CFStringRef ext = (CFStringRef)CFArrayGetValueAtIndex(extensions, 0);
	char extstr[32];
	Boolean res = CFStringGetCString(ext, extstr, 32, kCFStringEncodingUTF8);
	XThrowIfError (!res, "CFStringGetCString");
	
	// release the array as we're done with this now
	CFRelease (extensions);
    
	char outFname[256];
#if TARGET_OS_WIN32
	char drive[3], dir[256];
	_splitpath_s(inputFileName, drive, 3, dir, 256, NULL, 0, NULL, 0);
	_makepath_s(outFname, 256, drive, dir, "outfile", extstr);
#else
    //	char outFname[64];
	sprintf (outFname, "/tmp/outfile.%s", extstr);
#endif
	outOutputFileURL = CFURLCreateFromFileSystemRepresentation (kCFAllocatorDefault, (const UInt8 *)outFname, strlen(outFname), false);
	if (!outOutputFileURL) {
		printf ("* * Bad output file path\n");
		UsageString(1);
    }
}

void	GetFormatFromInputFile (AudioFileID inputFile, CAStreamBasicDescription & inputFormat)
{
	bool doPrint = true;
	UInt32 size;
	XThrowIfError(AudioFileGetPropertyInfo(inputFile,
                                           kAudioFilePropertyFormatList, &size, NULL), "couldn't get file's format list info");
	UInt32 numFormats = size / sizeof(AudioFormatListItem);
	AudioFormatListItem *formatList = new AudioFormatListItem [ numFormats ];
    
	XThrowIfError(AudioFileGetProperty(inputFile,
                                       kAudioFilePropertyFormatList, &size, formatList), "couldn't get file's data format");
	numFormats = size / sizeof(AudioFormatListItem); // we need to reassess the actual number of formats when we get it
	if (numFormats == 1) {
        // this is the common case
		inputFormat = formatList[0].mASBD;
	} else {
		if (doPrint) {
			printf ("File has a %d layered data format:\n", (int)numFormats);
			for (unsigned int i = 0; i < numFormats; ++i)
				CAStreamBasicDescription(formatList[i].mASBD).Print();
			printf("\n");
		}
		// now we should look to see which decoders we have on the system
		XThrowIfError(AudioFormatGetPropertyInfo(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size), "couldn't get decoder id's");
		UInt32 numDecoders = size / sizeof(OSType);
		OSType *decoderIDs = new OSType [ numDecoders ];
		XThrowIfError(AudioFormatGetProperty(kAudioFormatProperty_DecodeFormatIDs, 0, NULL, &size, decoderIDs), "couldn't get decoder id's");
		unsigned int i = 0;
		for (; i < numFormats; ++i) {
			OSType decoderID = formatList[i].mASBD.mFormatID;
			bool found = false;
			for (unsigned int j = 0; j < numDecoders; ++j) {
				if (decoderID == decoderIDs[j]) {
					found = true;
					break;
				}
			}
			if (found) break;
		}
		delete [] decoderIDs;
		
		if (i >= numFormats) {
			fprintf (stderr, "Cannot play any of the formats in this file\n");
			throw kAudioFileUnsupportedDataFormatError;
		}
		inputFormat = formatList[i].mASBD;
	}
	delete [] formatList;
}


void	ConstructOutputFormatFromArgs (	CFURLRef inputFileURL,
                                       OSType fileType, OSType format, Float64 sampleRate,
                                       CAStreamBasicDescription &inputFormat,
                                       UInt32 bitDepth,
                                       CAStreamBasicDescription &outputFormat)
{
	AudioFileID infile;
	OSStatus err = AudioFileOpenURL(inputFileURL, kAudioFileReadPermission, 0, &infile);
	XThrowIfError (err, "AudioFileOpen");
	
    // get the input file format
	GetFormatFromInputFile (infile, inputFormat);
    
	if (inputFormat.mFormatID != kAudioFormatLinearPCM && sampleRate > 0) {
		printf ("Can only specify sample rate with linear pcm input file\n");
		UsageString(1);
	}
	
    // set up the output file format
	if (!format) {
		if (sampleRate > 0) {
			outputFormat = inputFormat;
			outputFormat.mSampleRate = sampleRate;
		} else {
			if (inputFormat.mFormatID != kAudioFormatLinearPCM)
				format = kAudioFormatLinearPCM;
			else
				format = kAudioFormatAppleIMA4;
		}
	}
    
	if (format) {
		if (format == kAudioFormatLinearPCM) {
			outputFormat.mFormatID = format;
			outputFormat.mSampleRate = inputFormat.mSampleRate;
			outputFormat.mChannelsPerFrame = inputFormat.mChannelsPerFrame;
			outputFormat.mBitsPerChannel = (bitDepth) ? bitDepth : 16;
            
			outputFormat.mBytesPerPacket = inputFormat.mChannelsPerFrame * (outputFormat.mBitsPerChannel / 8);
			outputFormat.mFramesPerPacket = 1;
			outputFormat.mBytesPerFrame = outputFormat.mBytesPerPacket;
            
			if (fileType == kAudioFileWAVEType)
				outputFormat.mFormatFlags = kLinearPCMFormatFlagIsSignedInteger
                | kLinearPCMFormatFlagIsPacked;
			else
				outputFormat.mFormatFlags = kLinearPCMFormatFlagIsBigEndian
                | kLinearPCMFormatFlagIsSignedInteger
                | kLinearPCMFormatFlagIsPacked;
			
            
		} else {
			// need to set at least these fields for kAudioFormatProperty_FormatInfo
			outputFormat.mFormatID = format;
			outputFormat.mSampleRate = inputFormat.mSampleRate;
			outputFormat.mChannelsPerFrame = inputFormat.mChannelsPerFrame;
			
            // use AudioFormat API to fill out the rest.
			UInt32 size = sizeof(outputFormat);
			err = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, 0, NULL, &size, &outputFormat);
            XThrowIfError (err, "AudioFormatGetProperty kAudioFormatProperty_FormatInfo");
		}
	}
	AudioFileClose (infile);
}

int convertMain (int argc, char * const argv[])
{
#if TARGET_OS_WIN32
  	QTLicenseRef aacEncoderLicenseRef = nil;
  	QTLicenseRef amrEncoderLicenseRef = nil;
	OSErr localerr;
#endif
	int result = 0;
	CFURLRef inputFileURL = NULL;
	CFURLRef outputFileURL = NULL;
    
#if TARGET_OS_WIN32
	InitializeQTML(0L);
	{
		OSErr localerr;
		const char *licenseDesc = "AAC Encode License Verification";
		const char *amrLicenseDesc = "AMR Encode License Verification";
        
		localerr = QTRequestLicensedTechnology("com.apple.quicktimeplayer","com.apple.aacencoder",
                                               (void *)licenseDesc,strlen(licenseDesc),&aacEncoderLicenseRef);
		localerr = QTRequestLicensedTechnology("com.apple.quicktimeplayer","1D07EB75-3D5E-4DA6-B749-D497C92B06D8",
                                               (void *)amrLicenseDesc,strlen(amrLicenseDesc),&amrEncoderLicenseRef);
	}
#endif
	
	try {
		OSType format = 0;
		Float64 sampleRate = 0;
		AudioFileTypeID outputFileType = kAudioFileCAFType;
 	  	UInt32 outputBitRate = 0;
		UInt32 outputBitDepth = 0;
		
		ParseArgs (argc, argv, format, sampleRate, outputFileType, inputFileURL, outputFileURL, outputBitDepth, outputBitRate);
        
        //	printf ("args:%4.4s, sample rate:%.1f, outputFileType: %4.4s\n", (char*)&format, sampleRate, (char*)&outputFileType);
        
		CAStreamBasicDescription inputFormat;
		CAStreamBasicDescription outputFormat;
		ConstructOutputFormatFromArgs (inputFileURL, outputFileType, format, sampleRate, inputFormat, outputBitDepth, outputFormat);
		
		printf ("Source File format:\n\t"); inputFormat.Print();
		printf ("Dest File format:\n\t"); outputFormat.Print();
		
		result = ConvertFile (inputFileURL, inputFormat, outputFileURL, outputFileType, outputFormat, outputBitRate);
        
		CFStringRef path = CFURLCopyPath(outputFileURL);
		printf("done: "); fflush(stdout); CFShow(path);
		if (path) CFRelease(path);
        
	} catch (CAXException e) {
		char buf[256];
		fprintf(stderr, "Error in: %s\nException thrown: %s\n", e.mOperation, e.FormatError(buf));
		result = 1;
	} catch (...) {
		fprintf(stderr, "Unspecified exception\n");
		result = 1;
	}
	if (inputFileURL) CFRelease(inputFileURL);
	if (outputFileURL) CFRelease(outputFileURL);
	
#if TARGET_OS_WIN32
	TerminateQTML();
 	if (aacEncoderLicenseRef)
	{
		localerr = QTReleaseLicensedTechnology(aacEncoderLicenseRef);
		aacEncoderLicenseRef = nil;
	}
	if(amrEncoderLicenseRef)
	{
		localerr = QTReleaseLicensedTechnology(amrEncoderLicenseRef);
		amrEncoderLicenseRef = nil;
	}
#endif
	return result;
}