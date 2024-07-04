//
//  NvQCloudFileRecognizer.m
//  NvShortVideo
//
//  Created by meishe on 2024/5/8.
//

#import "NvQCloudFileRecognizer.h"

#import <QCloudFileRecognizer/QCloudFlashFileRecognizeParams.h>
#import <QCloudFileRecognizer/QCloudFlashFileRecognizer.h>

NSString* kQDAppId = @"YOUR AppId";
NSString* kQDSecretId = @"YOUR SecretId";
NSString* kQDSecretKey = @"YOUR SecretKey";

@interface NvQCloudFileRecognizer () <QCloudFlashFileRecognizerDelegate>

@property (nonatomic, strong) QCloudFlashFileRecognizer *recognizer;

@property (nonatomic, strong) void (^recognitionCallback)(NSArray<NvRecognitionTextItem *> *textArray,
                                                          NSError *error);

@property (nonatomic, strong) NSArray <NSDictionary *>*languageInfoArray;

@property (nonatomic, strong) NSString *languageIdentifier;

@end

@implementation NvQCloudFileRecognizer

- (instancetype)init {
    self = [super init];
    if (self) {
        self.recognizer = [[QCloudFlashFileRecognizer alloc] initWithAppId:kQDAppId secretId:kQDSecretId secretKey:kQDSecretKey];
        [self.recognizer EnableDebugLog:YES];//是否打印日志
        self.recognizer.delegate = self;
        [self setupData];
    }
    return self;
}

- (void)setupData {
    self.languageInfoArray = @[
        @{@"languageCode":@"16k_zh",
          @"displayName":@"简体中文",
          @"spaceRequired":@(NO),
          @"clauseLength":@(15)},
        @{@"languageCode":@"16k_zh-PY",
          @"displayName":@"中英粤",
          @"spaceRequired":@(NO),
          @"clauseLength":@(15)},
        @{@"languageCode":@"16k_yue",
          @"displayName":@"粤语",
          @"spaceRequired":@(NO),
          @"clauseLength":@(15)},
        @{@"languageCode":@"16k_en",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_ja",
          @"spaceRequired":@(NO),
          @"clauseLength":@(15)},
        @{@"languageCode":@"16k_ko",
          @"spaceRequired":@(NO),
          @"clauseLength":@(15)},
        @{@"languageCode":@"16k_vi",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_ms",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_id",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_fil",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_th",
          @"spaceRequired":@(YES),
          @"clauseLength":@(32)},
        @{@"languageCode":@"16k_pt",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_tr",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_ar",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_es",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_hi",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_fr",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_de",
          @"spaceRequired":@(YES),
          @"clauseLength":@(35)},
        @{@"languageCode":@"16k_zh_dialect",
          @"displayName":@"方言",
          @"spaceRequired":@(NO),
          @"clauseLength":@(15)},
    ];
}

- (NSDictionary *)infoForLanguage:(NSString *)languageIdentifier {
    if (!languageIdentifier) {
        return nil;
    }
    NSString *prefix = @"16k_";
    for (NSDictionary *dic in self.languageInfoArray) {
        NSString *displayName = dic[@"displayName"];
        if (displayName && [displayName isEqualToString:languageIdentifier]) {
            return dic;
        } else {
            NSString *languageCode = dic[@"languageCode"];
            if (languageCode) {
                if ([languageCode hasPrefix:prefix]) {
                    // NSLocale localeIdentifier
                    NSString *resultString = [languageCode substringFromIndex:[prefix length]];
                    if ([resultString isEqualToString:languageIdentifier]) {
                        return dic;
                    }
                } else {
                    if ([languageCode isEqualToString:languageIdentifier]) {
                        return dic;
                    }
                }
            }
        }
    }
    return nil;
}

// !!!: -- 解析识别结果
- (NSArray<NvRecognitionTextItem *> * _Nullable)analyticResultData:(nullable NSDictionary *)resultData {
    if (!resultData) {
        return nil;
    }
    
    NSDictionary *info = [self infoForLanguage:self.languageIdentifier];
    BOOL spaceRequired = NO;
    NSInteger sentenceMaxLength = -1;
    if (info) {
        NSNumber *num = info[@"spaceRequired"];
        if (num) {
            spaceRequired = [num boolValue];
        }
        {
            NSNumber *num = info[@"clauseLength"];
            if (num) {
                sentenceMaxLength = [num integerValue];
            }
        }
    }
    
    // params.wordInfo = 2; //是否显示词级别时间戳，默认为0。0：不显示；1：显示，不包含标点时间戳，2：显示，包含标点时间戳。
    // 根据标点断句 "voice_type" = 1
    NSArray *flashResult = resultData[@"flash_result"];
    if (flashResult &&
        [flashResult isKindOfClass:[NSArray class]] &&
        flashResult.count > 0) {
        NSDictionary *flashResultDic = flashResult.firstObject;
        if (flashResultDic &&
            [flashResultDic isKindOfClass:[NSDictionary class]]) {
            
            if (!info) {
                NSString *text = flashResultDic[@"text"];
                if (text && ![self containsChineseCharacters:text]) {
                    // 按英文处理
                    spaceRequired = YES;
                    sentenceMaxLength = 50;
                }
            }
            
            NSArray *sentenceList = flashResultDic[@"sentence_list"];
            if (sentenceList &&
                [sentenceList isKindOfClass:[NSArray class]] &&
                sentenceList.count > 0) {
                NSMutableArray *mutArray = [NSMutableArray array];
                for (NSDictionary *sentenceDic in sentenceList) {
                    NSInteger sentenceStartTime = [sentenceDic[@"start_time"] integerValue] * 1000;
                    NSArray *wordList = sentenceDic[@"word_list"];
                    if (wordList &&
                        [wordList isKindOfClass:[NSArray class]] &&
                        wordList.count > 0) {
                        NvRecognitionTextItem *textItem;
                        for (NSDictionary *wordDic in wordList) {
                            NSString *word = wordDic[@"word"];
                            if (!word) {
                                continue;
                            }
                            NSInteger voice_type = [wordDic[@"voice_type"] integerValue];
                            if ([word isEqualToString:@"."]) { // 标点
                                voice_type = 1;
                            }
                            if (voice_type == 0) {
                                
                                if (sentenceMaxLength > 0 && textItem) {
                                    if ((textItem.text.length + word.length) > sentenceMaxLength) {
//                                        NSLog(@"---> %ld", textItem.text.length);
                                        // 结束 / break
                                        [mutArray addObject:textItem];
                                        textItem = nil;
                                    }
                                }
                                
                                NSInteger startTime = [wordDic[@"start_time"] integerValue] * 1000 + sentenceStartTime;
                                NSInteger endTime = [wordDic[@"end_time"] integerValue] * 1000 + sentenceStartTime;
                                if (endTime <= 0) {
                                    NSLog(@"word: %@ , end_time error:%ld", word, endTime);
                                    continue;
                                }
                                if (!textItem) {
                                    textItem = [[NvRecognitionTextItem alloc] init];
                                    textItem.text = [NSMutableString string];
                                    textItem.inPoint = startTime;
                                }
                                textItem.outPoint = endTime;
                                if (spaceRequired && textItem.text.length > 0) {
                                    [textItem.text appendString:@" "];
                                    [textItem.text appendString:word];
                                } else {
                                    [textItem.text appendString:word];
                                }
                            } else {
                                if (textItem) {
                                    //                                    NSLog(@"---> %ld", textItem.text.length);
                                    [mutArray addObject:textItem];
                                    textItem = nil;
                                }
                            }
                        }
                        if (textItem) {
//                            NSLog(@"---> %ld", textItem.text.length);
                            [mutArray addObject:textItem];
                            textItem = nil;
                        }
                        
                    }
                }
                return mutArray;
            }
        }
    }
    
    return nil;
}

- (BOOL)containsChineseCharacters:(NSString *)string {
    NSString *pattern = @"[\u4e00-\u9fa5]";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    NSRange range = NSMakeRange(0, [string length]);
    NSUInteger matchCount = [regex numberOfMatchesInString:string options:0 range:range];
    return matchCount > 0;
}


// MARK: -- NvRecognitionRecognizer

- (NSArray<NSString *> *_Nullable)supportedLanguages {
    NSMutableArray *mutArray = [NSMutableArray array];
    NSString *prefix = @"16k_";
    for (NSDictionary *dic in self.languageInfoArray) {
        NSString *displayName = dic[@"displayName"];
        if (displayName) {
            [mutArray addObject:displayName];
        } else {
            NSString *languageCode = dic[@"languageCode"];
            if (languageCode) {
                if ([languageCode hasPrefix:prefix]) {
                    // NSLocale localeIdentifier
                    NSString *resultString = [languageCode substringFromIndex:[prefix length]];
                    [mutArray addObject:resultString];
                } else {
                    [mutArray addObject:languageCode];
                }
            }
        }
    }
    return mutArray;
}

- (NSString * _Nullable)defaulLanguage {
    //    return nil;
    NSString *languageStr = NSLocale.preferredLanguages.firstObject;
    NSString *language = [languageStr hasPrefix:@"en"] ? @"en" : @"zh-Hans";
    return language;
}

- (CGFloat)recognizerProgressRate {
    return 0.2;
}

- (void)requestRecognitionAuthorization:(void (^)(BOOL authorized))completion {
    completion(YES);
}

- (BOOL)recognitionAudioFile:(NSString *)audioFilePath
          languageIdentifier:(NSString *_Nullable)languageIdentifier
                    progress:(void (^)(float progress))progressBlock
                  completion:(void (^)(NSArray<NvRecognitionTextItem *> *textArray,
                                       NSError *error))completion {
    
    QCloudFlashFileRecognizeParams *params = [QCloudFlashFileRecognizeParams defaultRequestParams];
    NSData *audioData = [[NSData alloc] initWithContentsOfFile:audioFilePath];
    if (!audioData) {
        return NO;
    }
    
    //    languageIdentifier = @"en";
    
    NSDictionary *info = [self infoForLanguage:languageIdentifier];
    
    self.languageIdentifier = languageIdentifier;
    self.recognitionCallback = completion;
    params.audioData = audioData;
    //音频格式。支持 wav、pcm、ogg-opus、speex、silk、mp3、m4a、aac。
    params.voiceFormat = audioFilePath.pathExtension;
    
    //以下参数不设置将使用默认值
    //    params.engineModelType = @"16k_en";//引擎模型类型,默认16k_zh。8k_zh：8k 中文普通话通用；16k_zh：16k 中文普通话通用；16k_zh_video：16k 音视频领域。
    if (languageIdentifier && info) {
        params.engineModelType = info[@"languageCode"];
    }
    params.filterDirty = 1;// 0 ：默认状态 不过滤脏话 1：过滤脏话
    //    params.filterModal = 0;// 0 ：默认状态 不过滤语气词  1：过滤部分语气词 2:严格过滤
    //    params.filterPunc = 0;// 0 ：默认状态 不过滤句末的句号 1：滤句末的句号
    //    params.convertNumMode = 1;;//1：默认状态 根据场景智能转换为阿拉伯数字；0：全部转为中文数字。
    //    params.speakerDiarization = 0; //是否开启说话人分离（目前支持中文普通话引擎），默认为0，0：不开启，1：开启。
    //    params.firstChannelOnly = 1; //是否只识别首个声道，默认为1。0：识别所有声道；1：识别首个声道。
    params.wordInfo = 2; //是否显示词级别时间戳，默认为0。0：不显示；1：显示，不包含标点时间戳，2：显示，包含标点时间戳。
    
    //    params.requestTimeoutInternval = 600;//网络超时时间，默认600s,您可以根据业务需求更改此值；
    //注意：如果设置过短的时间，网络超时断开将无法获取到识别结果，并且会消耗该音频时长的识别额度
    // params.reinforceHotword = 1; // 开启热词增强
    //    params.sentenceMaxLength = 50;
    
    params.sentenceMaxLength = 15;
    if (info) {
        NSNumber *num = info[@"clauseLength"];
        if (num) {
            params.sentenceMaxLength = [num integerValue];
        }
    }
    
    [_recognizer recognize:params];
    return YES;
}


- (void)cancleRecognition {
    self.recognitionCallback = nil;
}

#pragma mark - QCloudFlashFileRecognizerDelegate
//上传文件成功回调
- (void)FlashFileRecognizer:(QCloudFlashFileRecognizer *_Nullable)recognizer status:(nullable NSInteger *) status text:(nullable NSString *)text resultData:(nullable NSDictionary *) resultData
{
    if (!self.recognitionCallback) {
        return;
    }
    if(status == 0){
        NSLog(@"识别成功");
        //text为识别结果
        NSArray<NvRecognitionTextItem *> *textItems = [self analyticResultData:resultData];
        if (textItems) {
            self.recognitionCallback(textItems, nil);
            self.recognitionCallback = nil;
        } else {
            NSString *retText = @"analytic error";
            NSError *retError = [NSError errorWithDomain:@"-4" code:-4 userInfo:@{NSLocalizedDescriptionKey: retText}];
            self.recognitionCallback(nil, retError);
            self.recognitionCallback = nil;
        }
    }else{
        NSLog(@"上传文件成功，但服务器端识别失败");
        //text为错误原因
        NSString *retText = text;
        if (!retText) {
            retText = @"Recognizer error";
        }
        NSError *retError = [NSError errorWithDomain:@"-3" code:-3 userInfo:@{NSLocalizedDescriptionKey: retText}];
        self.recognitionCallback(nil, retError);
        self.recognitionCallback = nil;
    }
    
    /*以上只解析整段话内容，如需精确解析词级别时间戳 请根据业务需求自行解析resultData，以下为直接打印json结果，格式参考api文档
     https://cloud.tencent.com/document/product/1093/52097
     */
    
    //        NSData *jsonData = [NSJSONSerialization dataWithJSONObject:resultData options:NSJSONWritingPrettyPrinted error:nil];
    //        NSString* text2 =  [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    //    NSLog(@"QCloudFlashFileRecognizer text2:%@", text2);
    //        self.TextView.text = text2;
}

//识别错误回调，网络错误，返回结果无法解析等
- (void)FlashFileRecognizer:(QCloudFlashFileRecognizer *_Nullable)recognizer error:(nullable NSError *)error resultData:(nullable NSDictionary *)resultData
{
    if (self.recognitionCallback) {
        NSError *retError = error;
        if (!error) {
            retError = [NSError errorWithDomain:@"-3" code:-3 userInfo:@{NSLocalizedDescriptionKey: @"Recognizer error"}];
        }
        self.recognitionCallback(nil, retError);
        self.recognitionCallback = nil;
    }
}

-(void)FlashFileRecgnizerLogOutPutWithLog:(NSString *)log{
    
    NSLog(@"log===%@",log);
}

@end
