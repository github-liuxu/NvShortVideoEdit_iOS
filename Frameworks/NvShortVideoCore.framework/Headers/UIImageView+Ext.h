//
//  UIImageView+Ext.h
//  NvShortVideo
//
//  Created by chengww on 2021/11/2.
//  Copyright © 2021 MEISHE. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^NvImageCompletionBlock)(UIImage * _Nullable image,
                                       NSURL *url,
                                       NSError * _Nullable error);

@interface UIImageView (Ext)

+ (UIImageView *)animatedImageView:(CGRect)frame;

- (void)nv_setAnimatedImage:(NSString *)imageFilePath;

- (void)setImage:(UIImage *)image withSelectColor:(UIColor *)color;

- (void)nv_setImageWithURLString:(NSString *)url;

- (void)nv_setImageWithURL:(NSURL *_Nullable)url;

- (void)nv_setImageWithURL:(NSURL *_Nullable)url placeholder:(nullable UIImage *)pImage;

- (void)nv_setImageWithURL:(NSURL *_Nullable)url placeholder:(nullable UIImage *)pImage completion:(nullable NvImageCompletionBlock)completion;

- (void)nv_setImageWithURLString:(NSString *_Nullable)urlString placeholderImageName:(NSString *)pImageName;

//- (void)nv_setImageWithURL:(nullable NSURL *)imageURL
//               placeholder:(nullable UIImage *)placeholder
//                 transform:(nullable YYWebImageTransformBlock)transform
//                completion:(nullable YYWebImageCompletionBlock)completion;

+ (float)totalCost;
+ (void)removeAllCacheObjects;
@end

NS_ASSUME_NONNULL_END
