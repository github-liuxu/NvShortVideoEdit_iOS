//
//  BDSpeechRecognizer.m
//  NvShortVideo
//
//  Created by meishe on 2024/5/10.
//

#import "BDSpeechRecognizer.h"

static NSString *SUBMIT_URL = @"https://openspeech.bytedance.com/api/v1/vc/submit?appid=%@&language=%@&use_itn=True&use_capitalize=True&max_lines=1&words_per_line=15";
static NSString *QUERY_URL = @"https://openspeech.bytedance.com/api/v1/vc/query?appid=%@&id=%@";
static NSString *LANGUAGE = @"zh-CN";
//static NSString *APPID = @"${your_appid}";
//static NSString *TOKEN = @"${your_token}";

static NSString *APPID = @"YOUR APPID";
static NSString *TOKEN = @"YOUR TOKEN";


@interface BDSpeechRecognizer ()

@property (nonatomic, strong) NSString *jobID;
@property (nonatomic, strong) void (^recognitionCallback)(NSArray<NvRecognitionTextItem *> *textArray,
                                                         NSError *error);

@property (nonatomic, strong) NSArray *languageInfoArray;

@end

@implementation BDSpeechRecognizer

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupData];
    }
    return self;
}

- (void)setupData {
    self.languageInfoArray = @[
        @{@"languageCode":@"zh-CN",
          @"clauseLength":@(15)},
        @{@"languageCode":@"yue",
          @"clauseLength":@(15)},
        @{@"languageCode":@"wuu",
          @"clauseLength":@(15)},
        @{@"languageCode":@"nan",
          @"clauseLength":@(15)},
        @{@"languageCode":@"xghu",
          @"clauseLength":@(15)},
        @{@"languageCode":@"zgyu",
          @"clauseLength":@(15)},
        @{@"languageCode":@"ug",
          @"clauseLength":@(55)},
        @{@"languageCode":@"en-US",
          @"clauseLength":@(55)},
        @{@"languageCode":@"ja-JP",
          @"clauseLength":@(32)},
        @{@"languageCode":@"ko-KR",
          @"clauseLength":@(32)},
        @{@"languageCode":@"es-MX",
          @"clauseLength":@(55)},
        @{@"languageCode":@"ru-RU",
          @"clauseLength":@(55)},
        @{@"languageCode":@"fr-FR",
          @"clauseLength":@(55)}];
    
}

// !!!: -- 解析识别结果
- (NSArray<NvRecognitionTextItem *> * _Nullable)analyticResultData:(nullable NSDictionary *)resultData {
    if (!resultData) {
        return nil;
    }
    NSArray *utterances = resultData[@"utterances"];
    if (utterances &&
        [utterances isKindOfClass:[NSArray class]] &&
        utterances.count > 0) {
        NSMutableArray *mutArray = [NSMutableArray array];
        for (NSDictionary *lineDic in utterances) {
            NSString *line = lineDic[@"text"];
            if (!line) {
                continue;
            }
            NSInteger startTime = [lineDic[@"start_time"] integerValue] * 1000;
            NSInteger endTime = [lineDic[@"end_time"] integerValue] * 1000;
            if (endTime <= 0) {
                NSLog(@"line: %@ , end_time error:%ld", line, endTime);
                continue;
            }
            NvRecognitionTextItem *textItem = [[NvRecognitionTextItem alloc] init];
            textItem.text = [NSMutableString string];
            textItem.inPoint = startTime;
            textItem.outPoint = endTime;
            [textItem.text appendString:line];
            [mutArray addObject:textItem];
        }
        return mutArray;
    }
    return nil;
}

// MARK: -- NvVoiceRecognizer

- (NSArray<NSString *> *_Nullable)supportedLanguages {
//    NSLocale *locale = [NSLocale currentLocale];
//    NSLog(@"---> %@", [locale localizedStringForLanguageCode:locale.localeIdentifier]);
    
    NSMutableArray *mutArray = [NSMutableArray array];
    for (NSDictionary *dic in self.languageInfoArray) {
        NSString *languageCode = dic[@"languageCode"];
        if (languageCode) {
            [mutArray addObject:languageCode];
        }
    }
    return mutArray;
}

- (NSString * _Nullable)defaulLanguage {
    return @"zh-CN";
}

- (CGFloat)recognizerProgressRate {
    return 0.3;
}

- (void)requestRecognitionAuthorization:(void (^)(BOOL authorized))completion {
    completion(YES);
}

- (BOOL)recognitionAudioFile:(NSString *)audioFilePath
          languageIdentifier:(NSString *_Nullable)languageIdentifier
                    progress:(void (^)(float progress))progressBlock
                  completion:(void (^)(NSArray<NvRecognitionTextItem *> *textArray,
                                                  NSError *error))completion {
    
    NSData *audioData = [[NSData alloc] initWithContentsOfFile:audioFilePath];
    if (!audioData) {
        return NO;
    }
    self.recognitionCallback = ^(NSArray<NvRecognitionTextItem *> *textArray, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(textArray, error);
        });
    };
    __weak typeof(self) weakSelf = self;
    [self submitWithAudioData:audioData languageIdentifier:languageIdentifier handler:^(NSString *jobID, NSError *error) {
        if (jobID) {
            weakSelf.jobID = jobID;
            [weakSelf query:jobID];
        } else {
            if (weakSelf.recognitionCallback) {
                weakSelf.recognitionCallback(nil, error);
                weakSelf.recognitionCallback = nil;
            }
        }
    }];
    return YES;
}


- (void)cancleRecognition {
    self.recognitionCallback = nil;
}

- (void)query:(NSString *)jobID {
    NSString *urlString = [NSString stringWithFormat:QUERY_URL, APPID, jobID];
    NSURL *url = [NSURL URLWithString:urlString];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:[NSString stringWithFormat:@"Bearer; %@", TOKEN] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    
    NSURLSession *session = [NSURLSession sharedSession];
    __weak typeof(self) weakSelf = self;
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (!weakSelf.recognitionCallback) {
            return;
        }
        if (error) {
            weakSelf.recognitionCallback(nil, error);
            weakSelf.recognitionCallback = nil;
        } else {
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSInteger code = [responseDictionary[@"code"] integerValue];
            if (code == 2000) {
                // 处理中，稍后再查
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!weakSelf.recognitionCallback) {
                        return;
                    }
                    [weakSelf query:jobID];
                });
            } else {
                NSArray<NvRecognitionTextItem *> *textItems = [self analyticResultData:responseDictionary];
                if (textItems) {
                    weakSelf.recognitionCallback(textItems, nil);
                    weakSelf.recognitionCallback = nil;
                } else {
                    NSString *retText = @"analytic error";
                    NSError *retError = [NSError errorWithDomain:@"-4" code:-4 userInfo:@{NSLocalizedDescriptionKey: retText}];
                    weakSelf.recognitionCallback(nil, retError);
                    weakSelf.recognitionCallback = nil;
                }
            }
        }
    }];
    [task resume];
}

- (void)submitWithAudioData:(NSData *)audioData
         languageIdentifier:(NSString *_Nullable)languageIdentifier
                    handler:(void (^)(NSString *jobID, NSError *error))handler {
//    NSString *urlString = [NSString stringWithFormat:SUBMIT_URL, APPID, LANGUAGE];
    
    NSInteger clauseLength = 15;
    if (languageIdentifier) {
        NSNumber *num;
        for (NSDictionary *dic in self.languageInfoArray) {
            NSString *languageCode = dic[@"languageCode"];
            if ([languageCode isEqualToString:languageIdentifier]) {
                num = dic[@"clauseLength"];
            }
        }
        if (num) {
            clauseLength = num.integerValue;
        }
    }
    NSString *urlString = [self submitUrlWithLanguage:languageIdentifier clauseLength:clauseLength];
    NSURL *url = [NSURL URLWithString:urlString];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"audio/*" forHTTPHeaderField:@"Content-Type"];
//    [request setValue:@"*/*" forHTTPHeaderField:@"Accept"];
    [request setValue:[NSString stringWithFormat:@"Bearer; %@", TOKEN] forHTTPHeaderField:@"Authorization"];
    [request setValue:@"keep-alive" forHTTPHeaderField:@"Connection"];
    [request setHTTPBody:audioData];
    
    
    NSURLSession *session = [NSURLSession sharedSession];
    NSURLSessionDataTask *task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            handler(nil, error);
        } else {
            NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:nil];
            NSLog(@"%@", responseDictionary);
            NSString *jobID = responseDictionary[@"id"];
            if (jobID) {
                handler(jobID, nil);
            } else {
                NSString *msg = responseDictionary[@"message"];
                if (!msg) {
                    msg = @"request error";
                }
                NSError *retError = [NSError errorWithDomain:@"-4" code:-4 userInfo:@{NSLocalizedDescriptionKey: msg}];
                handler(nil, retError);
            }
        }
    }];
    [task resume];
}

- (NSString *)submitUrlWithLanguage:(NSString *)language
                       clauseLength:(NSInteger)clauseLength {
    NSMutableString *mutString = [NSMutableString string];
    [mutString appendFormat:@"https://openspeech.bytedance.com/api/v1/vc/submit?appid=%@&use_itn=True&use_capitalize=True&max_lines=1", APPID];
    if (language) {
        [mutString appendFormat:@"&language=%@", language];
    }
    if (clauseLength > 0) {
        [mutString appendFormat:@"&words_per_line=%ld", clauseLength];
    }
//    @"https://openspeech.bytedance.com/api/v1/vc/submit?appid=%@&language=%@&use_itn=True&use_capitalize=True&max_lines=1&words_per_line=15";
    return mutString;
}

@end
