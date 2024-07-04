//
//  AppDelegate.m
//  NvShortVideo
//
//  Created by chengww on 2022/1/4.
//

#import "AppDelegate.h"
#import <NvStreamingSdkCore/NvsStreamingContext.h>
#import <NvShortVideoCore/NvShortVideoCore.h>
#import "NvRootViewController.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    NSString *licPath = [[NSBundle mainBundle] pathForResource:@"meicam_licence" ofType:@"lic"];
    BOOL ret = [NvsStreamingContext verifySdkLicenseFile:licPath];
    if (!ret) {
        NSLog(@"verifySdkLicenseFile faild");
    }
    
    return YES;
}



@end
