//
//  NvPublicViewController.h
//  NvShortVideo
//
//  Created by 美摄 on 2022/2/22.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface NvPublicViewController : UIViewController

@property (nonatomic, strong) NSString *imagePath;
@property (nonatomic, strong, nullable) NSString *draftInfo;
@property (nonatomic, assign) BOOL hasDraft;
@property (nonatomic, strong) NSString *taskId;

@end

NS_ASSUME_NONNULL_END
