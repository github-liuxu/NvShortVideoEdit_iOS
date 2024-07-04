//================================================================================
//
// (c) Copyright China Digital Video (Beijing) Limited, 2016. All rights reserved.
//
// This code and information is provided "as is" without warranty of any kind,
// either expressed or implied, including but not limited to the implied
// warranties of merchantability and/or fitness for a particular purpose.
//
//--------------------------------------------------------------------------------
//   Birth Date:    Feb 18. 2022
//   Author:        Meishe video team
//================================================================================

#pragma once
#import "NvsObject.h"

typedef enum {
    NvsAICutterFlag_LabelTypePhoto = 0,
    NvsAICutterFlag_LabelTypeActivity = 1,
    NvsAICutterFlag_LabelTypePlaceL1 = 2,
    NvsAICutterFlag_LabelTypePlaceL2 = 3,
    NvsAICutterFlag_LabelTypeObjectL1 = 4,
    NvsAICutterFlag_LabelTypeObjectL2 = 5,
    NvsAICutterFlag_LabelTypeFace = 6,
    NvsAICutterFlag_LabelTypeFaceRace = 7,
    NvsAICutterFlag_LabelTypeFaceAge = 8,
    NvsAICutterFlag_LabelTypeFaceGender = 9,
    NvsAICutterFlag_LabelTypeDate = 10,
    NvsAICutterFlag_LabelTypeDateCn = 11,
    NvsAICutterFlag_LabelTypeSkyStatus = 12,
    NvsAICutterFlag_LabelTypeSkyWeather = 13,
    NvsAICutterFlag_LabelTypeSkyRainbow = 14,
    NvsAICutterFlag_LabelTypeSkyFirecloud = 15,
    NvsAICutterFlag_LabelTypeSkyAirplanecloud = 16,
} NvsAICutterFlag;

NVS_EXPORT @interface NvsTimeStampValue : NSObject

@property(nonatomic, assign)int64_t timeStamp;
@property(nonatomic, assign)float value;
@property(nonatomic, strong)NSString *strValue;

@end

NVS_EXPORT @interface NvsUnitClip : NSObject

@property(nonatomic, assign) int64_t start;
@property(nonatomic, assign) int64_t end;
@property(nonatomic, assign) int fileIdx;
@property(nonatomic, strong) NSDictionary <NSString*,NSArray<NvsTimeStampValue*>*>*formulaValues;

@end

NVS_EXPORT @interface NvsAITag : NSObject

@property(nonatomic, strong) NSString *title;
@property(nonatomic, strong) NSString *userName;
@property(nonatomic, strong) NSDictionary <NSString *, NSString *>*tag;

@end

NVS_EXPORT @interface NvsClipInfo : NSObject
@property(nonatomic, strong) NSString *ID;
@property(nonatomic, strong) NSArray<NvsUnitClip*> *clips;
@property(nonatomic, strong) NvsAITag *tag;

@end

NVS_EXPORT @interface NvsLabelInfo : NSObject
@property(nonatomic, assign) int labelType;
@property(nonatomic, assign) int value;
@property(nonatomic, strong) NSString *strValue;

@end

NVS_EXPORT @interface NvsAICutter : NvsObject

- (BOOL)readTemplates:(NSArray<NSString*>*)template_jsons;

- (NSArray<NvsClipInfo*>*)matchTemplateHUD:(NSArray<NSString *>*)dataPaths extraParam:(NSArray<NSString *>*)extraParam;

- (NSArray<NvsClipInfo*>*)matchTemplateARSky:(NSArray<NSString *>*)dataPaths extraParam:(NSArray<NSString *>*)extraParam;

- (NSArray<NvsClipInfo*>*)matchTemplateVlog:(NSArray<NSString *>*)dataPaths extraParam:(NSArray<NSString *>*)extraParam;

- (NSArray<NvsClipInfo*>*)matchTemplateColor:(NSArray<NSString *>*)dataPaths extraParam:(NSArray<NSString *>*)extraParam;

- (NSArray<NvsClipInfo*>*)matchTemplateVlogIM:(NSArray<NSString *>*)dataPaths extraParam:(NSArray<NSString *>*)extraParam;

- (NSArray<NvsClipInfo*>*)matchTemplateSmart:(NSArray<NSString *>*)dataPaths extraParam:(NSArray<NSString *>*)extraParam;

- (NSArray<NvsLabelInfo*>*)induceAndRecommend:(NSArray<NSString *>*)dataPaths;

- (void)setSmartTemplateCutPreference:(int)type;

@end
