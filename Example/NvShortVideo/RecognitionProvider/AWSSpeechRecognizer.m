//
//  AWSSpeechRecognizer.m
//  NvShortVideo
//
//  Created by meishe on 2024/5/11.
//

#import "AWSSpeechRecognizer.h"

//pod 'AWSS3'
//pod 'AWSTranscribe'

#import <AWSS3/AWSS3.h>
#import <AWSTranscribe/AWSTranscribe.h>


static NSString * accessKey = @"YOUR KEY HERE";
static NSString * secretKey = @"YOUR KEY HERE";
static NSString * s3Bucket = @"YOUR S3 BUCKET";
static NSString * s3Key = @"YOUR S3 KEY";
static AWSRegionType region = AWSRegionUSEast1;

@interface AWSSpeechRecognizer ()

@property (nonatomic, strong) void (^recognitionCallback)(NSArray<NvRecognitionTextItem *> *textArray,
                                                         NSError *error);

@property (nonatomic, strong) NSArray <NSNumber *>* languageArray;

@end

@implementation AWSSpeechRecognizer

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupData];
    }
    return self;
}

- (void)setupData {
    NSMutableArray *mutArray = [NSMutableArray array];
    for (NSInteger i=1; i<=AWSTranscribeLanguageCodeZuZA; i++) {
        [mutArray addObject:@(i)];
    }
    self.languageArray = mutArray;
    
    // Set the required language
//    self.languageArray = @[@(AWSTranscribeLanguageCodeZhCN), @(AWSTranscribeLanguageCodePtBR), @(AWSTranscribeLanguageCodeEnUS)];
    
}

// !!!: -- 解析识别结果
- (NSArray<NvRecognitionTextItem *> * _Nullable)analyticResultData:(nullable NSDictionary *)resultData {
    if (!resultData) {
        return nil;
    }
    /*
    "items": [
          {
            "start_time": "0.54",
            "end_time": "0.95",
            "alternatives": [{ "confidence": "1.0", "content": "Hi" }],
            "type": "pronunciation"
          },
          {
            "alternatives": [{ "confidence": "0.0", "content": "," }],
            "type": "punctuation"
          },
          
          ...
          */
    NSArray *utterances = resultData[@"results"][@"items"];
    if (utterances &&
        [utterances isKindOfClass:[NSArray class]] &&
        utterances.count > 0) {
        NSMutableArray *mutArray = [NSMutableArray array];
        for (NSDictionary *lineDic in utterances) {
            NSDictionary *alternatives = lineDic[@"alternatives"];
            if (!alternatives) {
                continue;
            }
            NSString *line = alternatives[@"content"];
            if (!line) {
                continue;
            }
            NSString *type = lineDic[@"type"];
            if (![type isEqualToString:@"pronunciation"]) {
                NSLog(@"line: %@ , type:%@", line, type);
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
    NSMutableArray <NSString *>*mutArray = [NSMutableArray array];
    for (NSNumber *num in self.languageArray) {
        NSString *lang = [self localizedKeyForLanguageCode:num.integerValue];
        if (lang) {
            [mutArray addObject:lang];
        }
    }
    return mutArray;
}

- (NSString * _Nullable)defaulLanguage {
    return nil;
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
    
    self.recognitionCallback = ^(NSArray<NvRecognitionTextItem *> *textArray, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            completion(textArray, error);
        });
    };
    __weak typeof(self) weakSelf = self;
    [self uploadAudioFile:audioFilePath completion:^(NSString *audioUrl, NSError *error) {
        if (audioUrl) {
            [weakSelf transcription:audioFilePath languageIdentifier:languageIdentifier];
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


- (void)transcription:(NSString *)audioUrl languageIdentifier:(NSString *_Nullable)languageIdentifier {
    AWSTranscribeLanguageCode languageCode = [self languageCodeForLocaleIdentifier:languageIdentifier];
    __weak typeof(self) weakSelf = self;
    [self startTranscription:audioUrl 
                languageCode:languageCode
                  completion:^(NSString *transcriptionJobName, NSError *error) {
        if (error) {
            if (weakSelf.recognitionCallback) {
                weakSelf.recognitionCallback(nil, error);
                weakSelf.recognitionCallback = nil;
            }
        } else {
            //
        }
    }];
}

- (void)query:(NSString *)JobName {
    __weak typeof(self) weakSelf = self;
    [self queryTranscriptionInfo:JobName completion:^(NSString *transcriptFileUri, NSError *error) {
        if (!weakSelf.recognitionCallback) {
            return;
        }
        if (error) {
            weakSelf.recognitionCallback(nil, error);
            weakSelf.recognitionCallback = nil;
        } else {
            dispatch_async(dispatch_get_global_queue(0, 0), ^{
                NSURL *url = [NSURL URLWithString:transcriptFileUri];
                NSData *jsonData = [NSData dataWithContentsOfURL:url];
                if (!weakSelf.recognitionCallback) {
                    return;
                }
                NSDictionary *responseDictionary = [NSJSONSerialization JSONObjectWithData:jsonData options:kNilOptions error:nil];
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
            });
        }
    }];
}

// MARK: -- AWS SDK
- (void)uploadAudioFile:(NSString *)audioPath completion:(void (^)(NSString *audioUrl,
                                                                   NSError *error))completion {
    // 配置 AWS 认证凭证
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc] initWithAccessKey:accessKey
                                                                                                      secretKey:secretKey];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:region credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    // 创建 AWSS3TransferUtility 实例
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility defaultS3TransferUtility];
    
    // 设置文件上传路径
    NSURL *fileURL = [NSURL fileURLWithPath:audioPath];
    AWSS3TransferUtilityUploadExpression *expression = [AWSS3TransferUtilityUploadExpression new];
    [expression setValue:@"audio/*" forRequestHeader:@"Content-Type"];
    
    // 执行文件上传
    [transferUtility uploadFile:fileURL
                          bucket:s3Bucket
                             key:[NSString stringWithFormat:@"audio.%@", audioPath.pathExtension]
                     contentType:@"audio/*"
                      expression:expression
               completionHandler:^(AWSS3TransferUtilityUploadTask * _Nonnull task, NSError * _Nullable error) {
        if (error) {
            NSLog(@"Error uploading file: %@", error);
            completion(nil, error);
        } else {
            NSLog(@"File uploaded successfully");
            NSString *mediaFileURL = [NSString stringWithFormat:@"s3://%@/%@", task.bucket, task.key];
            completion(mediaFileURL, nil);
        }
    }];
}

- (void)startTranscription:(NSString *)mediaFileURL
              languageCode:(AWSTranscribeLanguageCode)languageCode
                completion:(void (^)(NSString *transcriptionJobName,
                                     NSError *error))completion{
    AWSTranscribeMedia *media = [AWSTranscribeMedia new];
    [media setValue:mediaFileURL forKey:@"MediaFileUri"];
    
    AWSTranscribeStartTranscriptionJobRequest *request = [AWSTranscribeStartTranscriptionJobRequest new];
    request.languageCode = AWSTranscribeLanguageCodePtBR;
    request.media = media;
    request.transcriptionJobName = [NSString stringWithFormat:@"aws-transcribe-ptbr-%@", [[NSUUID UUID] UUIDString]];
    
    AWSTranscribe *transcribe = [AWSTranscribe defaultTranscribe];
    
    [transcribe startTranscriptionJob:request completionHandler:^(AWSTranscribeStartTranscriptionJobResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR ON startTranscriptionJob: %@", error);
            completion(nil, error);
        } else {
            NSString *transcriptionJobName = response.transcriptionJob.transcriptionJobName;
            completion(transcriptionJobName, nil);
        }
    }];
}

- (void)queryTranscriptionInfo:(NSString *)transcriptionJobName completion:(void (^)(NSString *transcriptFileUri,
                                                                                     NSError *error))completion {
    
    AWSTranscribeGetTranscriptionJobRequest *request = [AWSTranscribeGetTranscriptionJobRequest new];
    request.transcriptionJobName = transcriptionJobName;
    __weak typeof(self) weakSelf = self;
    AWSTranscribe *transcribe = [AWSTranscribe defaultTranscribe];
    [transcribe getTranscriptionJob:request completionHandler:^(AWSTranscribeGetTranscriptionJobResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            NSLog(@"ERROR ON fetchTranscriptionInfo");
            completion(nil, error);
        } else {
            if (response.transcriptionJob.transcriptionJobStatus == AWSTranscribeTranscriptionJobStatusInProgress) {
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    if (!weakSelf.recognitionCallback) {
                        return;
                    }
                    [weakSelf queryTranscriptionInfo:transcriptionJobName completion:completion];
                });
            } else {
                NSString *transcriptFileUri = response.transcriptionJob.transcript.transcriptFileUri;
                completion(transcriptFileUri, error);
            }
        }
    }];
}

- (AWSTranscribeLanguageCode)languageCodeForLocaleIdentifier:(NSString *_Nullable)localeIdentifier {
    if (!localeIdentifier) {
        return AWSTranscribeLanguageCodeUnknown;
    }
    for (NSInteger i=1; i<=AWSTranscribeLanguageCodeZuZA; i++) {
        NSString *identifier = [self localizedKeyForLanguageCode:i];
        if ([localeIdentifier isEqualToString:identifier]) {
            return i;
        }
    }
    return AWSTranscribeLanguageCodeUnknown;
}

- (NSString *_Nullable)localizedKeyForLanguageCode:(AWSTranscribeLanguageCode)languageCode {
    if(languageCode == AWSTranscribeLanguageCodeUnknown) {
        return nil;
    }
    NSDictionary<NSNumber *, NSString *> *languageCodeToLocaleIdentifier = @{
        @(AWSTranscribeLanguageCodeAfZA) : @"af-ZA",
        @(AWSTranscribeLanguageCodeArAE) : @"ar-AE",
        @(AWSTranscribeLanguageCodeArSA) : @"ar-SA",
        @(AWSTranscribeLanguageCodeDaDK) : @"da-DK",
        @(AWSTranscribeLanguageCodeDeCH) : @"de-CH",
        @(AWSTranscribeLanguageCodeDeDE) : @"de-DE",
        @(AWSTranscribeLanguageCodeEnAB) : @"en-AE",
        @(AWSTranscribeLanguageCodeEnAU) : @"en-AU",
        @(AWSTranscribeLanguageCodeEnGB) : @"en-GB",
        @(AWSTranscribeLanguageCodeEnIE) : @"en-IE",
        @(AWSTranscribeLanguageCodeEnIN) : @"en-IN",
        @(AWSTranscribeLanguageCodeEnUS) : @"en-US",
        @(AWSTranscribeLanguageCodeEnWL) : @"en-WL",
        @(AWSTranscribeLanguageCodeEsES) : @"es-ES",
        @(AWSTranscribeLanguageCodeEsUS) : @"es-US",
        @(AWSTranscribeLanguageCodeFaIR) : @"fa-IR",
        @(AWSTranscribeLanguageCodeFrCA) : @"fr-CA",
        @(AWSTranscribeLanguageCodeFrFR) : @"fr-FR",
        @(AWSTranscribeLanguageCodeHeIL) : @"he-IL",
        @(AWSTranscribeLanguageCodeHiIN) : @"hi-IN",
        @(AWSTranscribeLanguageCodeIdID) : @"id-ID",
        @(AWSTranscribeLanguageCodeItIT) : @"it-IT",
        @(AWSTranscribeLanguageCodeJaJP) : @"ja-JP",
        @(AWSTranscribeLanguageCodeKoKR) : @"ko-KR",
        @(AWSTranscribeLanguageCodeMsMY) : @"ms-MY",
        @(AWSTranscribeLanguageCodeNlNL) : @"nl-NL",
        @(AWSTranscribeLanguageCodePtBR) : @"pt-BR",
        @(AWSTranscribeLanguageCodePtPT) : @"pt-PT",
        @(AWSTranscribeLanguageCodeRuRU) : @"ru-RU",
        @(AWSTranscribeLanguageCodeTaIN) : @"ta-IN",
        @(AWSTranscribeLanguageCodeTeIN) : @"te-IN",
        @(AWSTranscribeLanguageCodeTrTR) : @"tr-TR",
        @(AWSTranscribeLanguageCodeZhCN) : @"zh-Hans",
        @(AWSTranscribeLanguageCodeZhTW) : @"zh-Hant",
        @(AWSTranscribeLanguageCodeThTH) : @"th-TH",
        @(AWSTranscribeLanguageCodeEnZA) : @"en-ZA",
        @(AWSTranscribeLanguageCodeEnNZ) : @"en-NZ",
        @(AWSTranscribeLanguageCodeViVN) : @"vi-VN",
        @(AWSTranscribeLanguageCodeSvSE) : @"sv-SE",
        @(AWSTranscribeLanguageCodeAbGE) : @"ab-GE",
        @(AWSTranscribeLanguageCodeAstES) : @"ast-ES",
        @(AWSTranscribeLanguageCodeAzAZ) : @"az-AZ",
        @(AWSTranscribeLanguageCodeBaRU) : @"ba-RU",
        @(AWSTranscribeLanguageCodeBeBY) : @"be-BY",
        @(AWSTranscribeLanguageCodeBgBG) : @"bg-BG",
        @(AWSTranscribeLanguageCodeBnIN) : @"bn-IN",
        @(AWSTranscribeLanguageCodeBsBA) : @"bs-BA",
        @(AWSTranscribeLanguageCodeCaES) : @"ca-ES",
        @(AWSTranscribeLanguageCodeCkbIQ) : @"ckb-IQ",
        @(AWSTranscribeLanguageCodeCkbIR) : @"ckb-IR",
        @(AWSTranscribeLanguageCodeCsCZ) : @"cs-CZ",
        @(AWSTranscribeLanguageCodeCyWL) : @"cy-WL",
        @(AWSTranscribeLanguageCodeElGR) : @"el-GR",
        @(AWSTranscribeLanguageCodeEtET) : @"et-EE",
        @(AWSTranscribeLanguageCodeEuES) : @"eu-ES",
        @(AWSTranscribeLanguageCodeFiFI) : @"fi-FI",
        @(AWSTranscribeLanguageCodeGlES) : @"gl-ES",
        @(AWSTranscribeLanguageCodeGuIN) : @"gu-IN",
        @(AWSTranscribeLanguageCodeHaNG) : @"ha-NG",
        @(AWSTranscribeLanguageCodeHrHR) : @"hr-HR",
        @(AWSTranscribeLanguageCodeHuHU) : @"hu-HU",
        @(AWSTranscribeLanguageCodeHyAM) : @"hy-AM",
        @(AWSTranscribeLanguageCodeIsIS) : @"is-IS",
        @(AWSTranscribeLanguageCodeKaGE) : @"ka-GE",
        @(AWSTranscribeLanguageCodeKabDZ) : @"kab-DZ",
        @(AWSTranscribeLanguageCodeKkKZ) : @"kk-KZ",
        @(AWSTranscribeLanguageCodeKnIN) : @"kn-IN",
        @(AWSTranscribeLanguageCodeKyKG) : @"ky-KG",
        @(AWSTranscribeLanguageCodeLgIN) : @"lg-IN",
        @(AWSTranscribeLanguageCodeLtLT) : @"lt-LT",
        @(AWSTranscribeLanguageCodeLvLV) : @"lv-LV",
        @(AWSTranscribeLanguageCodeMhrRU) : @"mhr-RU",
        @(AWSTranscribeLanguageCodeMiNZ) : @"mi-NZ",
        @(AWSTranscribeLanguageCodeMkMK) : @"mk-MK",
        @(AWSTranscribeLanguageCodeMlIN) : @"ml-IN",
        @(AWSTranscribeLanguageCodeMnMN) : @"mn-MN",
        @(AWSTranscribeLanguageCodeMrIN) : @"mr-IN",
        @(AWSTranscribeLanguageCodeMtMT) : @"mt-MT",
        @(AWSTranscribeLanguageCodeNoNO) : @"no-NO",
        @(AWSTranscribeLanguageCodeOrIN) : @"or-IN",
        @(AWSTranscribeLanguageCodePaIN) : @"pa-IN",
        @(AWSTranscribeLanguageCodePlPL) : @"pl-PL",
        @(AWSTranscribeLanguageCodePsAF) : @"ps-AF",
        @(AWSTranscribeLanguageCodeRoRO) : @"ro-RO",
        @(AWSTranscribeLanguageCodeRwRW) : @"rw-RW",
        @(AWSTranscribeLanguageCodeSiLK) : @"si-LK",
        @(AWSTranscribeLanguageCodeSkSK) : @"sk-SK",
        @(AWSTranscribeLanguageCodeSlSI) : @"sl-SI",
        @(AWSTranscribeLanguageCodeSoSO) : @"so-SO",
        @(AWSTranscribeLanguageCodeSrRS) : @"sr-RS",
        @(AWSTranscribeLanguageCodeSuID) : @"su-ID",
        @(AWSTranscribeLanguageCodeSwBI) : @"sw-BI",
        @(AWSTranscribeLanguageCodeSwKE) : @"sw-KE",
        @(AWSTranscribeLanguageCodeSwRW) : @"sw-RW",
        @(AWSTranscribeLanguageCodeSwTZ) : @"sw-TZ",
        @(AWSTranscribeLanguageCodeSwUG) : @"sw-UG",
        @(AWSTranscribeLanguageCodeTlPH) : @"tl-PH",
        @(AWSTranscribeLanguageCodeTtRU) : @"tt-RU",
        @(AWSTranscribeLanguageCodeUgCN) : @"ug-CN",
        @(AWSTranscribeLanguageCodeUkUA) : @"uk-UA",
        @(AWSTranscribeLanguageCodeUzUZ) : @"uz-UZ",
        @(AWSTranscribeLanguageCodeWoSN) : @"wo-SN",
        @(AWSTranscribeLanguageCodeZuZA) : @"zu-ZA"
    };
//    for (NSString *languageIdentifier in languageCodeToLocaleIdentifier.allValues) {
//        NSLocale *locale = [NSLocale localeWithLocaleIdentifier:languageIdentifier];
//    NSString *string = [locale localizedStringForLanguageCode:languageIdentifier];
//        NSLog(@"----> %@: %@",languageIdentifier, string);
//    }
    
    return languageCodeToLocaleIdentifier[@(languageCode)];
}

@end
