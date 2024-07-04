//
//  NvSpeechRecognizer.h
//  NvShortVideo
//
//  iOS Speech 语音识别
//
//  Created by meishe on 2024/5/8.
//

#import <Foundation/Foundation.h>

#if __has_include(<NvShortVideoCore/NvShortVideoCore.h>)
#import <NvShortVideoCore/NvShortVideoCore.h>
#else
#import "NvShortVideoCore.h"
#endif

// !!!: -- 需要系统授权：Privacy - Speech Recognition Usage Description
// !!!: -- System authorization required：Privacy - Speech Recognition Usage Description

NS_ASSUME_NONNULL_BEGIN

@interface NvSpeechRecognizer : NSObject <NvVoiceRecognizer>

@end

NS_ASSUME_NONNULL_END
