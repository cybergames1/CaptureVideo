//
//  CaptureVideoController.m
//  CaptureVideoController
//
//  Created by jianting on 15/11/10.
//  Copyright © 2015年 jianting. All rights reserved.
//

#import "CaptureVideoController.h"

@interface CaptureVideoController () <AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
{
    AVCaptureSession                    *_captureSession;
    
    AVCaptureDeviceInput                *_videoDeviceInput;
    AVCaptureDeviceInput                *_audioDeviceInput;
    AVCaptureMovieFileOutput            *_movieFileOutput;
    
    CaptureVideoPreView                 *_preView;
    
    AVCaptureConnection					*_audioConnection;
    AVCaptureConnection					*_videoConnection;
    
    AVCaptureVideoDataOutput            *_videoDataOutput;
    AVCaptureAudioDataOutput            *_audioDataOutput;
    
    AVAssetWriter						*_assetWriter;
    AVAssetWriterInput					*_assetWriterAudioIn;
    AVAssetWriterInput					*_assetWriterVideoIn;
    
    dispatch_queue_t					_movieWritingQueue;
    BOOL								_readyToRecordAudio;
    BOOL								_readyToRecordVideo;
    
    NSURL                               *_outputURL;
}

@property (nonatomic, assign) AVCaptureVideoOrientation	referenceOrientation;
@property (nonatomic, readwrite) AVCaptureVideoOrientation videoOrientation;


@end

@implementation CaptureVideoController

- (void)dealloc {
    [_preView release];_preView = nil;
    [_captureSession release];_captureSession = nil;
    [_assetWriter release];_assetWriter = nil;
    [_videoDataOutput release];_videoDataOutput = nil;
    [_audioDataOutput release];_audioDataOutput = nil;
    [_outputURL release];_outputURL = nil;
    dispatch_release(_movieWritingQueue);
    [super dealloc];
}

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.referenceOrientation = AVCaptureVideoOrientationPortrait;
        [[self view] setCaptureSession:[self captureSession]];
    }
    return self;
}

- (UIView *)view {
    if (!_preView) {
        _preView = [[CaptureVideoPreView alloc] init];
        [(AVCaptureVideoPreviewLayer *)[_preView layer] setVideoGravity:AVLayerVideoGravityResizeAspectFill];
        [[_preView layer] setMasksToBounds:YES];
    }
    return _preView;
}

//初始化session
- (AVCaptureSession *)captureSession {
    _movieWritingQueue = dispatch_queue_create("Movie Writing Queue", DISPATCH_QUEUE_SERIAL);
    
    if (!_captureSession) {
        _captureSession = [[AVCaptureSession alloc] init];
        
        //输入
        if ([_captureSession canAddInput:[self videoDeviceInput]]) {
            [_captureSession addInput:[self videoDeviceInput]];
        }
        
        if ([_captureSession canAddInput:[self audioDeviceInput]]) {
            [_captureSession addInput:[self audioDeviceInput]];
        }
        
        //输出
        if ([_captureSession canAddOutput:[self videoDataOutput]]) {
            [_captureSession addOutput:[self videoDataOutput]];
        }
        _videoConnection = [_videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
        _videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
        self.videoOrientation = _videoConnection.videoOrientation;
        
        if ([_captureSession canAddOutput:[self audioDataOutput]]) {
            [_captureSession addOutput:[self audioDataOutput]];
        }
        _audioConnection = [_audioDataOutput connectionWithMediaType:AVMediaTypeAudio];
        
        //preset
        if ([_captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
            [_captureSession setSessionPreset:AVCaptureSessionPresetHigh];
        }
    }
    return _captureSession;
}

//视频输入
- (AVCaptureDeviceInput *)videoDeviceInput {
    if (!_videoDeviceInput) {
        _videoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[self cameraDevice] error:nil];
    }
    return _videoDeviceInput;
}

//音频输入
- (AVCaptureDeviceInput *)audioDeviceInput {
    if (!_audioDeviceInput) {
        _audioDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio] error:nil];
    }
    return _audioDeviceInput;
}

//视频输出
- (AVCaptureVideoDataOutput *)videoDataOutput {
    if (!_videoDataOutput) {
        _videoDataOutput = [[AVCaptureVideoDataOutput alloc] init];
        [_videoDataOutput setAlwaysDiscardsLateVideoFrames:YES];
        [_videoDataOutput setVideoSettings:@{(id)kCVPixelBufferPixelFormatTypeKey : [NSNumber numberWithInt:kCVPixelFormatType_32BGRA]}];
        dispatch_queue_t videoCaptureQueue = dispatch_queue_create("Video Capture Queue", DISPATCH_QUEUE_SERIAL);
        [_videoDataOutput setSampleBufferDelegate:self queue:videoCaptureQueue];
    }
    return _videoDataOutput;
}

//音频输出
- (AVCaptureAudioDataOutput *)audioDataOutput {
    if (!_audioDataOutput) {
        _audioDataOutput = [[AVCaptureAudioDataOutput alloc] init];
        dispatch_queue_t audioCaptureQueue = dispatch_queue_create("Audio Capture Queue", DISPATCH_QUEUE_SERIAL);
        [_audioDataOutput setSampleBufferDelegate:self queue:audioCaptureQueue];
    }
    return _audioDataOutput;
}

//初始化摄像头
- (AVCaptureDevice *)cameraDevice {
    AVCaptureDevice *backCamera = nil;
    
    NSArray *cameras = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *camera in cameras) {
        if (camera.position == AVCaptureDevicePositionBack) {
            backCamera = camera;
            break;
        }
    }
    
    return backCamera;
}

- (void)startCamera {
    [[self captureSession] startRunning];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(subjectAreaDidChange:) name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[[self videoDeviceInput] device]];
}

- (void)stopCamera {
    [[self captureSession] stopRunning];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVCaptureDeviceSubjectAreaDidChangeNotification object:[_videoDeviceInput device]];
}

- (void)setVideoScale:(CGFloat)scale {
    AVCaptureDevice *device = [_videoDeviceInput device];
    if ([device lockForConfiguration:nil]) {
        [[_videoDeviceInput device] setVideoZoomFactor:scale];
        [device unlockForConfiguration];
    }
    
}

///////////////////////////////////////////////////
// 聚焦
///////////////////////////////////////////////////

- (void)subjectAreaDidChange:(NSNotification *)notification {
    
    CGPoint devicePoint = CGPointMake(.5, .5);
    [self focusWithMode:AVCaptureFocusModeContinuousAutoFocus exposeWithMode:AVCaptureExposureModeContinuousAutoExposure atDevicePoint:devicePoint monitorSubjectAreaChange:NO];
}

- (void)focusAndExposeTap:(UIGestureRecognizer *)gestureRecognizer
{
    CGPoint devicePoint = [(AVCaptureVideoPreviewLayer *)_preView.layer captureDevicePointOfInterestForPoint:[gestureRecognizer locationInView:_preView]];
    [self focusWithMode:AVCaptureFocusModeAutoFocus exposeWithMode:AVCaptureExposureModeAutoExpose atDevicePoint:devicePoint monitorSubjectAreaChange:YES];
}

#pragma mark Device Configuration

- (void)focusWithMode:(AVCaptureFocusMode)focusMode exposeWithMode:(AVCaptureExposureMode)exposureMode atDevicePoint:(CGPoint)point monitorSubjectAreaChange:(BOOL)monitorSubjectAreaChange
{
    dispatch_async(_movieWritingQueue, ^{
        AVCaptureDevice *device = _videoDeviceInput.device;
        NSError *error = nil;
        if ( [device lockForConfiguration:&error] ) {
            // Setting (focus/exposure)PointOfInterest alone does not initiate a (focus/exposure) operation.
            // Call -set(Focus/Exposure)Mode: to apply the new point of interest.
            if ( device.isFocusPointOfInterestSupported && [device isFocusModeSupported:focusMode] ) {
                device.focusPointOfInterest = point;
                device.focusMode = focusMode;
            }
            
            if ( device.isExposurePointOfInterestSupported && [device isExposureModeSupported:exposureMode] ) {
                device.exposurePointOfInterest = point;
                device.exposureMode = exposureMode;
            }
            
            device.subjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange;
            [device unlockForConfiguration];
        }
        else {
            NSLog( @"Could not lock device for configuration: %@", error );
        }
    } );
}

#pragma mark - Asset writing

- (void)writeSampleBuffer:(CMSampleBufferRef)sampleBuffer ofType:(NSString *)mediaType
{
    if ( _assetWriter.status == AVAssetWriterStatusUnknown )
    {
        if ([_assetWriter startWriting])
            [_assetWriter startSessionAtSourceTime:CMSampleBufferGetPresentationTimeStamp(sampleBuffer)];
        else
            [self showError:_assetWriter.error];
    }
    
    if ( _assetWriter.status == AVAssetWriterStatusWriting )
    {
        if (mediaType == AVMediaTypeVideo)
        {
            if (_assetWriterVideoIn.readyForMoreMediaData)
            {
                if (![_assetWriterVideoIn appendSampleBuffer:sampleBuffer])
                    [self showError:_assetWriter.error];
            }
        }
        else if (mediaType == AVMediaTypeAudio)
        {
            if (_assetWriterAudioIn.readyForMoreMediaData)
            {
                if (![_assetWriterAudioIn appendSampleBuffer:sampleBuffer])
                    [self showError:_assetWriter.error];
            }
        }
    }
}


//音频写入
- (BOOL)setupAssetWriterAudioInput:(CMFormatDescriptionRef)currentFormatDescription
{
    // Create audio output settings dictionary which would be used to configure asset writer input
    const AudioStreamBasicDescription *currentASBD = CMAudioFormatDescriptionGetStreamBasicDescription(currentFormatDescription);
    size_t aclSize = 0;
    const AudioChannelLayout *currentChannelLayout = CMAudioFormatDescriptionGetChannelLayout(currentFormatDescription, &aclSize);
    
    NSData *currentChannelLayoutData = nil;
    // AVChannelLayoutKey must be specified, but if we don't know any better give an empty data and let AVAssetWriter decide.
    if ( currentChannelLayout && aclSize > 0 )
        currentChannelLayoutData = [NSData dataWithBytes:currentChannelLayout length:aclSize];
    else
        currentChannelLayoutData = [NSData data];
    
    NSDictionary *audioCompressionSettings = @{AVFormatIDKey : [NSNumber numberWithInteger:kAudioFormatMPEG4AAC],
                                               AVSampleRateKey : [NSNumber numberWithFloat:currentASBD->mSampleRate],
                                               AVEncoderBitRatePerChannelKey : [NSNumber numberWithInt:64000],
                                               AVNumberOfChannelsKey : [NSNumber numberWithInteger:currentASBD->mChannelsPerFrame],
                                               AVChannelLayoutKey : currentChannelLayoutData};
    
    if ([_assetWriter canApplyOutputSettings:audioCompressionSettings forMediaType:AVMediaTypeAudio])
    {
        // Intialize asset writer audio input with the above created settings dictionary
        _assetWriterAudioIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:audioCompressionSettings];
        _assetWriterAudioIn.expectsMediaDataInRealTime = YES;
        
        // Add asset writer input to asset writer
        if ([_assetWriter canAddInput:_assetWriterAudioIn])
        {
            [_assetWriter addInput:_assetWriterAudioIn];
        }
        else
        {
            NSLog(@"Couldn't add asset writer audio input.");
            return NO;
        }
    }
    else
    {
        NSLog(@"Couldn't apply audio output settings.");
        return NO;
    }
    
    return YES;
}

//视频写入
- (BOOL)setupAssetWriterVideoInput:(CMFormatDescriptionRef)currentFormatDescription
{
    // Create video output settings dictionary which would be used to configure asset writer input
    CGFloat bitsPerPixel;
    CMVideoDimensions dimensions = CMVideoFormatDescriptionGetDimensions(currentFormatDescription);
    NSUInteger numPixels = dimensions.width * dimensions.height;
    NSUInteger bitsPerSecond;
    
    // Assume that lower-than-SD resolutions are intended for streaming, and use a lower bitrate
    if ( numPixels < (640 * 480) )
        bitsPerPixel = 4.05; // This bitrate matches the quality produced by AVCaptureSessionPresetMedium or Low.
    else
        bitsPerPixel = 11.4; // This bitrate matches the quality produced by AVCaptureSessionPresetHigh.
    
    bitsPerSecond = numPixels * bitsPerPixel;
    
    NSDictionary *videoCompressionSettings = @{AVVideoCodecKey : AVVideoCodecH264,
                                               AVVideoScalingModeKey:AVVideoScalingModeResizeAspectFill,
                                               AVVideoWidthKey : [NSNumber numberWithInteger:320],
                                               AVVideoHeightKey : [NSNumber numberWithInteger:240],
                                               AVVideoCompressionPropertiesKey : @{
                                                                                    AVVideoMaxKeyFrameIntervalKey :[NSNumber numberWithInteger:15]}};
    
    if ([_assetWriter canApplyOutputSettings:videoCompressionSettings forMediaType:AVMediaTypeVideo])
    {
        // Intialize asset writer video input with the above created settings dictionary
        _assetWriterVideoIn = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:videoCompressionSettings];
        _assetWriterVideoIn.expectsMediaDataInRealTime = YES;
        //_assetWriterVideoIn.transform = [self transformFromCurrentVideoOrientationToOrientation:_videoOrientation];
        
        // Add asset writer input to asset writer
        if ([_assetWriter canAddInput:_assetWriterVideoIn])
        {
            [_assetWriter addInput:_assetWriterVideoIn];
        }
        else
        {
            NSLog(@"Couldn't add asset writer video input.");
            return NO;
        }
    }
    else
    {
        NSLog(@"Couldn't apply video output settings.");
        return NO;
    }
    
    return YES;
}


///////////////////////////////////////////////////
// Public Methods
///////////////////////////////////////////////////

- (void)startRecordingToOutputFileURL:(NSURL *)fileURL {
    if (!fileURL || [[fileURL absoluteString] length] <= 0) return;
    
    [_outputURL release];
    _outputURL = [fileURL retain];
    
    if (_delegate && [_delegate respondsToSelector:@selector(captureVideoWillStartRecording:)]) {
        [_delegate captureVideoWillStartRecording:self];
    }
    
    unlink([[fileURL path] UTF8String]);
    NSError *error;
    _assetWriter = [[AVAssetWriter alloc] initWithURL:fileURL fileType:AVFileTypeQuickTimeMovie error:&error];
    if (error)
        [self showError:error];
}

- (void)stopRecording {
    
    if (_delegate && [_delegate respondsToSelector:@selector(captureVideoWillStopRecording:)]) {
        [_delegate captureVideoWillStopRecording:self];
    }
    
    dispatch_async(_movieWritingQueue, ^{
    [_assetWriter finishWritingWithCompletionHandler:^()
     {
         AVAssetWriterStatus completionStatus = _assetWriter.status;
         switch (completionStatus)
         {
             case AVAssetWriterStatusCompleted:
             {
                 _readyToRecordVideo = NO;
                 _readyToRecordAudio = NO;
                 _assetWriter = nil;
                 
                 if (_delegate && [_delegate respondsToSelector:@selector(captureVideoDidStopRecording:)]) {
                     [_delegate captureVideoDidStopRecording:self];
                 }
                 
                 break;
             }
             case AVAssetWriterStatusFailed:
             {
                 [self showError:_assetWriter.error];
                 break;
             }
             default:
                 break;
         }
         
     }];
    });
}

- (NSURL *)outputURL {
    return _outputURL;
}

- (CGFloat)angleOffsetFromPortraitOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
    CGFloat angle = 0.0;
    
    switch (orientation)
    {
        case AVCaptureVideoOrientationPortrait:
            angle = 0.0;
            break;
        case AVCaptureVideoOrientationPortraitUpsideDown:
            angle = M_PI;
            break;
        case AVCaptureVideoOrientationLandscapeRight:
            angle = -M_PI_2;
            break;
        case AVCaptureVideoOrientationLandscapeLeft:
            angle = M_PI_2;
            break;
        default:
            break;
    }
    
    return angle;
}

- (CGAffineTransform)transformFromCurrentVideoOrientationToOrientation:(AVCaptureVideoOrientation)orientation
{
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    // Calculate offsets from an arbitrary reference orientation (portrait)
    CGFloat orientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:orientation];
    CGFloat videoOrientationAngleOffset = [self angleOffsetFromPortraitOrientationToOrientation:self.videoOrientation];
    
    // Find the difference in angle between the passed in orientation and the current video orientation
    CGFloat angleOffset = orientationAngleOffset - videoOrientationAngleOffset;
    transform = CGAffineTransformMakeRotation(angleOffset);
    
    return transform;
}


#pragma mark - Capture

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CFRetain(sampleBuffer);
    dispatch_async(_movieWritingQueue, ^{
        if (_assetWriter)
        {
            BOOL wasReadyToRecord = [self inputsReadyToRecord];
            
            if (connection == _videoConnection)
            {
                // Initialize the video input if this is not done yet
                if (!_readyToRecordVideo)
                    _readyToRecordVideo = [self setupAssetWriterVideoInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
                
                // Write video data to file only when all the inputs are ready
                if ([self inputsReadyToRecord])
                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeVideo];
            }
            else if (connection == _audioConnection)
            {
                // Initialize the audio input if this is not done yet
                if (!_readyToRecordAudio)
                    _readyToRecordAudio = [self setupAssetWriterAudioInput:CMSampleBufferGetFormatDescription(sampleBuffer)];
                
                // Write audio data to file only when all the inputs are ready
                if ([self inputsReadyToRecord])
                    [self writeSampleBuffer:sampleBuffer ofType:AVMediaTypeAudio];
            }
            
            BOOL isReadyToRecord = [self inputsReadyToRecord];
            
            if (!wasReadyToRecord && isReadyToRecord)
            {
                if (_delegate && [_delegate respondsToSelector:@selector(captureVideoDidStartRecording:)]) {
                    [_delegate captureVideoDidStartRecording:self];
                }
            }
        }
        CFRelease(sampleBuffer);
    });
}

- (BOOL)inputsReadyToRecord
{
    // Check if all inputs are ready to begin recording.
    return (_readyToRecordAudio && _readyToRecordVideo);
}

#pragma mark - Error Handling

- (void)showError:(NSError *)error
{

}

@end
