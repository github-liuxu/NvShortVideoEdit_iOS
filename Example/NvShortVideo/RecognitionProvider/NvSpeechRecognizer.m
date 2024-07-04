//
//  NvSpeechRecognizer.m
//  NvShortVideo
//
//  Created by meishe on 2024/5/8.
//

#import "NvSpeechRecognizer.h"
#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

@interface NvSpeechRecognizer ()

@property (nonatomic, strong) SFSpeechRecognizer *recognizer;

@property (nonatomic, strong) SFSpeechRecognitionTask *task;
@property (nonatomic, assign) NSInteger maxLength;

@property (nonatomic, strong) NSArray<NSString *> *spaceRequiredArray;

@property (nonatomic, strong) void (^recognitionCallback)(NSArray<NvRecognitionTextItem *> *textArray,
                                                         NSError *error);

@property (nonatomic, strong) NSString *languageIdentifier;

@end

@implementation NvSpeechRecognizer

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupData];
    }
    return self;
}

- (void)setupData {
    self.maxLength = 32;
    self.spaceRequiredArray = @[@"zh-CN", @"zh-TW", @"zh-Hans", @"zh-Hant", @"ja-JP", @"ja", @"ko-KR", @"ko"];
}

// !!!: -- 解析识别结果

// 不带标点符号 / No punctuation
- (NSArray<NvRecognitionTextItem *> * _Nullable)analyticResultData:(SFSpeechRecognitionResult *) resultData {
    if (!resultData) {
        return nil;
    }
    BOOL spaceRequired = YES;
    if (self.languageIdentifier) {
        spaceRequired = ![self.spaceRequiredArray containsObject:self.languageIdentifier];
    }
    
    // 没有标点符号的情况下，比较Segment时间差
    NSTimeInterval breakInterval = 0.02; // 断句间隔
    
    NSMutableArray *mutArray = [NSMutableArray array];
    NvRecognitionTextItem *textItem;
    NSTimeInterval preSegTime = 0;
    for (SFTranscriptionSegment *seg in resultData.bestTranscription.segments) {
        NSString *segText = seg.substring;
        NSTimeInterval timeDiff = seg.timestamp - preSegTime;
        if (timeDiff >= breakInterval) {
            // 结束 / break
            if (textItem) {
                [mutArray addObject:textItem];
                textItem = nil;
            }
        }
        // 检查长度
        if (textItem) {
            if ((textItem.text.length + segText.length) > self.maxLength) {
                // 结束 / break
                [mutArray addObject:textItem];
                textItem = nil;
            }
        }
        
        // 追加
        if (!textItem) {
            textItem = [[NvRecognitionTextItem alloc] init];
            textItem.text = [NSMutableString string];
            textItem.inPoint = seg.timestamp * 1000000;
        }
        textItem.outPoint = (seg.timestamp + seg.duration) * 1000000;
        if (spaceRequired && textItem.text.length > 0) {
            [textItem.text appendString:@" "];
            [textItem.text appendString:segText];
        } else {
            [textItem.text appendString:segText];
        }
        
        
        preSegTime = seg.timestamp + seg.duration;
    }
    if (textItem) {
        [mutArray addObject:textItem];
        textItem = nil;
    }
    
    return mutArray;
}

// 带标点符号 / Punctuation
- (NSArray<NvRecognitionTextItem *> * _Nullable)analyticResultDataWithPunctuation:(SFSpeechRecognitionResult *) resultData {
    if (!resultData) {
        return nil;
    }
    BOOL spaceRequired = YES;
    if (self.languageIdentifier) {
        spaceRequired = ![self.spaceRequiredArray containsObject:self.languageIdentifier];
    }
    
    // 创建正则表达式，匹配中英文断句符号
    NSString *pattern = @"[\\p{P}\\p{S}&&[^,%'\"]]";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    
    NSMutableArray *mutArray = [NSMutableArray array];
    NvRecognitionTextItem *textItem;
    
    for (SFTranscriptionSegment *seg in resultData.bestTranscription.segments) {
        NSString *segText = seg.substring;
        NSArray<NSTextCheckingResult *> *matches = [regex matchesInString:segText options:0 range:NSMakeRange(0, [segText length])];
        if (matches.count > 0) {
            NSUInteger textLenght = segText.length;
            for (NSTextCheckingResult *match in matches) {
                NSRange matchRange = [match range];
                textLenght -= matchRange.length;
            }
            if (textLenght == 0) {
                // 结束
                if (textItem) {
                    [mutArray addObject:textItem];
                    textItem = nil;
                }
                continue;
            }
            NSTimeInterval runDuration = seg.duration / textLenght;
            
            NSUInteger preIndex = 0;
            NSUInteger proTextLength = 0;
            for (NSTextCheckingResult *match in matches) {
                NSRange matchRange = [match range];
                if (matchRange.location > 0) {
                    NSString *sText = [segText substringWithRange:NSMakeRange(preIndex, matchRange.location - preIndex)];
                    // 检查长度
                    if (textItem) {
                        if ((textItem.text.length + sText.length) > self.maxLength) {
                            // 结束 / break
                            [mutArray addObject:textItem];
                            textItem = nil;
                        }
                    }
                    // 追加
                    if (!textItem) {
                        textItem = [[NvRecognitionTextItem alloc] init];
                        textItem.text = [NSMutableString string];
                        textItem.inPoint = (seg.timestamp + proTextLength*runDuration) * 1000000;
                    }
                    textItem.outPoint = (seg.timestamp + proTextLength*runDuration + sText.length*runDuration) * 1000000;
                    if (spaceRequired && textItem.text.length > 0) {
                        [textItem.text appendString:@" "];
                        [textItem.text appendString:sText];
                    } else {
                        [textItem.text appendString:sText];
                    }
                    // 结束
                    [mutArray addObject:textItem];
                    textItem = nil;
                    
                    proTextLength += sText.length;
                } else {
                    // 结束
                    if (textItem) {
                        [mutArray addObject:textItem];
                        textItem = nil;
                    }
                }
                preIndex = matchRange.location + matchRange.length;
            }
            if (preIndex < segText.length) {
                NSString *sText = [segText substringWithRange:NSMakeRange(preIndex, segText.length - preIndex)];
                
                // 检查长度
                if (textItem) {
                    if ((textItem.text.length + sText.length) > self.maxLength) {
                        // 结束 / break
                        [mutArray addObject:textItem];
                        textItem = nil;
                    }
                }
                // 追加
                if (!textItem) {
                    textItem = [[NvRecognitionTextItem alloc] init];
                    textItem.text = [NSMutableString string];
                    textItem.inPoint = (seg.timestamp + proTextLength*runDuration) * 1000000;
                }
                textItem.outPoint = (seg.timestamp + proTextLength*runDuration + sText.length*runDuration) * 1000000;
                if (spaceRequired && textItem.text.length > 0) {
                    [textItem.text appendString:@" "];
                    [textItem.text appendString:sText];
                } else {
                    [textItem.text appendString:sText];
                }
            }
        } else {
            // 检查长度
            if (textItem) {
                if ((textItem.text.length + seg.substring.length) > self.maxLength) {
                    // 结束 / break
                    [mutArray addObject:textItem];
                    textItem = nil;
                }
            }
            // 追加
            if (!textItem) {
                textItem = [[NvRecognitionTextItem alloc] init];
                textItem.text = [NSMutableString string];
                textItem.inPoint = seg.timestamp * 1000000;
            }
            textItem.outPoint = (seg.timestamp + seg.duration) * 1000000;
            if (spaceRequired && textItem.text.length > 0) {
                [textItem.text appendString:@" "];
                [textItem.text appendString:seg.substring];
            } else {
                [textItem.text appendString:seg.substring];
            }
        }
    }
    return mutArray;
}

// MARK: -- NvRecognitionRecognizer

- (NSArray<NSString *> *_Nullable)supportedLanguages {
    NSSet<NSLocale *> * lSet = [SFSpeechRecognizer supportedLocales];
    NSMutableArray *mutArray = [NSMutableArray array];
    
    for (NSLocale *locale in lSet) {
        [mutArray addObject:locale.localeIdentifier];
    }
    return nil;
}

- (NSString * _Nullable)defaulLanguage {
    return nil;
}

- (CGFloat)recognizerProgressRate {
    return 0.5;
}

- (void)requestRecognitionAuthorization:(void (^)(BOOL authorized))completion {
    SFSpeechRecognizerAuthorizationStatus preStatus = [SFSpeechRecognizer authorizationStatus];
    if (preStatus == SFSpeechRecognizerAuthorizationStatusNotDetermined) {
        [SFSpeechRecognizer requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
            completion(status == SFSpeechRecognizerAuthorizationStatusAuthorized || status == SFSpeechRecognizerAuthorizationStatusRestricted);
        }];
    } else {
        completion(preStatus == SFSpeechRecognizerAuthorizationStatusAuthorized || preStatus == SFSpeechRecognizerAuthorizationStatusRestricted);
    }
}

- (NSTimeInterval)audioDurationForFileAtURL:(NSURL *)fileURL {
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:fileURL options:nil];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeAudio];
    if ([tracks count] > 0) {
        AVAssetTrack *track = [tracks objectAtIndex:0];
        NSTimeInterval duration = [track timeRange].duration.value / [track timeRange].duration.timescale;
        return duration;
    }
    return 0.0; // 如果无法获取时长，则返回0
}

- (BOOL)recognitionAudioFile:(NSString *)audioFilePath
          languageIdentifier:(NSString *_Nullable)languageIdentifier
                    progress:(void (^)(float progress))progressBlock
                  completion:(void (^)(NSArray<NvRecognitionTextItem *> *textArray,
                                                  NSError *error))completion {
    
    if (languageIdentifier) {
        NSLocale *locale = [[NSLocale alloc] initWithLocaleIdentifier:languageIdentifier];
        self.recognizer = [[SFSpeechRecognizer alloc] initWithLocale:locale];
    } else {
        self.recognizer = [[SFSpeechRecognizer alloc] init];
    }
            
    if (!self.recognizer.isAvailable) {
        return NO;
    }
    self.languageIdentifier = languageIdentifier;
    self.recognitionCallback = completion;
    NSURL *audioFileUrl = [NSURL fileURLWithPath:audioFilePath];
    NSTimeInterval audioDuration = [self audioDurationForFileAtURL:audioFileUrl];
    SFSpeechURLRecognitionRequest *request = [[SFSpeechURLRecognitionRequest alloc] initWithURL:audioFileUrl];
    request.shouldReportPartialResults = YES;
    if (@available(iOS 16, *)) {
        request.addsPunctuation = YES;
    }
    __weak typeof(self) weakSelf = self;
    SFSpeechRecognitionTask *task = [self.recognizer recognitionTaskWithRequest:request resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (!weakSelf.recognitionCallback) {
            return;
        }
        if (error) {
            weakSelf.recognitionCallback(nil, error);
            weakSelf.recognitionCallback = nil;
        } else {
            if (result.isFinal) {
                NSArray<NvRecognitionTextItem *> *textList;
                if (@available(iOS 16, *)) {
                    textList = [weakSelf analyticResultDataWithPunctuation:result];
                } else {
                    textList = [weakSelf analyticResultData:result];
                }
                if (progressBlock) {
                    progressBlock(1.0);
                }
                weakSelf.recognitionCallback(textList, nil);
                weakSelf.recognitionCallback = nil;
                dispatch_async(dispatch_get_main_queue(), ^{
                    [weakSelf cleanRecognizer];
                });
            } else {
                SFTranscriptionSegment *segment = result.bestTranscription.segments.lastObject;
                if (audioDuration > 0 && segment) {
                    NSTimeInterval time = segment.timestamp + segment.duration;
                    if (progressBlock) {
                        progressBlock(time * 32 / audioDuration);
                    }
                }
            }
        }
    }];
    self.task = task;
    return YES;
}

- (void)cleanRecognizer {
    self.task = nil;
}

- (void)cancleRecognition {
    self.recognitionCallback = nil;
    if (self.task) {
        [self.task cancel];
        self.task = nil;
    }
}

@end
