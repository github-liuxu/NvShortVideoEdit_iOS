//
//  NvQCloudFileRecognizer.h
//  NvShortVideo
//
//  腾讯语音识别 / Tencent speech recognition
//
//  Created by meishe on 2024/5/8.
//

#import <Foundation/Foundation.h>

#if __has_include(<NvShortVideoCore/NvShortVideoCore.h>)
#import <NvShortVideoCore/NvShortVideoCore.h>
#else
#import "NvShortVideoCore.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface NvQCloudFileRecognizer : NSObject <NvVoiceRecognizer>

@end

NS_ASSUME_NONNULL_END
