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


@protocol AIParserDelegate <NSObject>
@optional
- (void)onDetectStarted:(NSString*)mediaPath taskId:(int64_t)taskId;
- (void)onDetectFinished:(NSString*)mediaPath scdPath:(NSString*)scdPath;
- (void)onDetectError:(int)errorType;
- (void)onDetectProgress:(NSString*)mediaPath progress:(float)progress;

@end

typedef enum {
    NvsAIParserFlag_None = 0,
    NvsAIParserFlag_ModelPlace = 0,
    NvsAIParserFlag_ModelSkySeg = 1,
    NvsAIParserFlag_ModelSkyClass = 2,
    NvsAIParserFlag_ModelFace = 3,
    NvsAIParserFlag_ModelActivity = 4,
    NvsAIParserFlag_ModelObjDet = 5,
    NvsAIParserFlag_ModelFaceAttr = 6,
    NvsAIParserFlag_ModelPhoto = 7,
    NvsAIParserFlag_ModelImageClass = 8,
    NvsAIParserFlag_ModelPlaceClassNew = 9,
    NvsAIParserFlag_OnlyDetectKeyFrameFrameSpace = 1000000,
} NvsAIParserFlag;

NVS_EXPORT @interface NvsCarFrameInfo : NSObject

@property(nonatomic, strong) NSString *placel1;
@property(nonatomic, strong) NSString *placel2;
@property(nonatomic, strong) NSString *activity;
@property(nonatomic, strong) NSString *skytype;
@property(nonatomic, strong) NSString *skycolor;
@property(nonatomic, strong) NSString *moon;
@property(nonatomic, strong) NSString *rainbow;
@property(nonatomic, strong) NSString *airplanecloud;
@property(nonatomic, strong) NSString *weather;
@property(nonatomic, strong) NSString *time;
@property(nonatomic, strong) NSString *sky;
@property(nonatomic, strong) NSString *firecloud;

@end

NVS_EXPORT @interface NvsDetectData : NSObject

@property(nonatomic, strong) NSString *mediaPath;
@property(nonatomic, assign) int frameSpace;
@property(nonatomic, assign) NvsSize detectSize;
@property(nonatomic, assign) int year;
@property(nonatomic, assign) int month;
@property(nonatomic, assign) int day;
@property(nonatomic, assign) int hour;
@property(nonatomic, assign) int minute;
@property(nonatomic, assign) int second;

@end

NVS_EXPORT @interface NvsAIParser : NSObject

+ (instancetype)sharedInstance;
+ (instancetype)sharedInstanceWithFlags:(int)flags;
@property (nonatomic, weak) id<AIParserDelegate> delegate;

+ (BOOL)initModel:(NSString *)modelFilePath type:(int)type;

+ (void)setModelStatus:(int)type status:(BOOL)status;

+ (void)close;

- (BOOL)setMaxThreadCount:(int)threadCount;

- (BOOL)detectMediaFiles:(NSArray <NvsDetectData*>*)dataList;

- (void)cancelTask:(int64_t)taskId;

- (void)cancelAllTasks;

- (void)suspend;

- (void)resume;

+ (NvsCarFrameInfo*)read:(NSString *)infodata;

+ (void)installDescData:(NSString *)descpath;

@end
