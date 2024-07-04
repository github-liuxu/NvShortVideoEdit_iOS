//
//  AWSSpeechRecognizer.h
//  NvShortVideo
//
//  Amazon
//
//  Created by meishe on 2024/5/11.
//

#if __has_include(<NvShortVideoCore/NvShortVideoCore.h>)
#import <NvShortVideoCore/NvShortVideoCore.h>
#else
#import "NvShortVideoCore.h"
#endif

NS_ASSUME_NONNULL_BEGIN

@interface AWSSpeechRecognizer : NSObject <NvVoiceRecognizer>

@end

NS_ASSUME_NONNULL_END
