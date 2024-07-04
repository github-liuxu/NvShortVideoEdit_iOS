//
//  NvRootViewController.m
//  NvShortVideo
//
//  Created by chengww on 2021/12/31.
//

#import "NvRootViewController.h"
#import <NvShortVideoCore/NvShortVideoCore.h>
#import <NvShortVideoEdit/NvHttpRequest.h>

#import "NvPublicViewController.h"
#import "NvDraftListViewController.h"
#import <YYModel/YYModel.h>
#import "NvHttpRequestUtlHeader.h"

//#import "NvQCloudFileRecognizer.h"
//#import "NvSpeechRecognizer.h"
//#import "BDSpeechRecognizer.h"
//#import "AWSSpeechRecognizer.h"

#import <Network/Network.h>

@import Photos;

@interface NvRootViewController ()<NvModuleManagerDelegate, NvThemeDelegate>
@property (weak, nonatomic) IBOutlet UILabel *versionLbl;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *versionLayoutY;
@property (weak, nonatomic) IBOutlet UIView *editView;
@property (weak, nonatomic) IBOutlet UIView *draftView;
@property (weak, nonatomic) IBOutlet UIView *dualView;
@property (weak, nonatomic) IBOutlet UIView *captureView;

@property (weak, nonatomic) IBOutlet UIView *contentView;

@property (nonatomic, strong) NSString *selectedConfigPath;

@property (nonatomic, strong) NvVideoConfig *videoConfig;

@end

@implementation NvRootViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"";
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    navigationBar.tintColor = [UIColor whiteColor];
    navigationBar.barTintColor = [UIColor blackColor];
    NSMutableDictionary*attributes = [NSMutableDictionary dictionary];
    attributes[NSForegroundColorAttributeName] = [UIColor whiteColor];
    attributes[NSFontAttributeName] = [UIFont systemFontOfSize:16];
    navigationBar.titleTextAttributes = attributes;
    
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *versionString = infoDictionary[@"CFBundleShortVersionString"];
    NSLog(@"Version: %@", versionString);
    
    NSString * version = self.versionLbl.text;
    self.versionLbl.text = [NSString stringWithFormat:@"%@ v%@",version,versionString];
    
    // gradient
    CAGradientLayer *gl = [CAGradientLayer layer];
    gl.frame = self.view.bounds;
//    gl.startPoint = CGPointMake(-0.15, -0.16);
//    gl.endPoint = CGPointMake(1, 1.04);
    gl.colors = @[(__bridge id)[UIColor colorWithRed:0/255.0 green:0/255.0 blue:0/255.0 alpha:1.0].CGColor, (__bridge id)[UIColor colorWithRed:42/255.0 green:49/255.0 blue:61/255.0 alpha:1.0].CGColor];
//    gl.locations = @[@(0), @(1.0f)];
    [self.view.layer insertSublayer:gl atIndex:0];
    
    self.editView.clipsToBounds = YES;
    self.editView.layer.cornerRadius = self.editView.frame.size.height * 0.5;
    self.draftView.clipsToBounds = YES;
    self.draftView.layer.cornerRadius = self.draftView.frame.size.height * 0.5;
    self.dualView.clipsToBounds = YES;
    self.dualView.layer.cornerRadius = self.dualView.frame.size.height * 0.5;
    self.captureView.clipsToBounds = YES;
    self.captureView.layer.cornerRadius = self.captureView.frame.size.height * 0.5;
    
    self.contentView.clipsToBounds = YES;
    self.contentView.layer.cornerRadius = 9;
    
    CAGradientLayer *gl1 = [CAGradientLayer layer];
    gl1.frame = self.contentView.bounds;
//    gl.startPoint = CGPointMake(-0.15, -0.16);
//    gl.endPoint = CGPointMake(1, 1.04);
    gl1.colors = @[(__bridge id)[UIColor colorWithRed:33/255.0 green:39/255.0 blue:41/255.0 alpha:1.0].CGColor, (__bridge id)[UIColor colorWithRed:40/255.0 green:47/255.0 blue:59/255.0 alpha:1.0].CGColor];
//    gl.locations = @[@(0), @(1.0f)];
    [self.contentView.layer insertSublayer:gl1 atIndex:0];
    
    if ([UIApplication sharedApplication].statusBarFrame.size.height < 20.1) {
        self.versionLayoutY.constant = 20;
    }
    
    NvModuleManager* moduleManager = [NvModuleManager sharedInstance];
    
    moduleManager.delegate = self;
    moduleManager.themeDelegate = self;
    
//    NSObject<NvVoiceRecognizer> *fileRecognizer = [[NvQCloudFileRecognizer alloc] init];
//        NSObject<NvVoiceRecognizer> *fileRecognizer = [[NvSpeechRecognizer alloc] init];
    //    NSObject<NvVoiceRecognizer> *fileRecognizer = [[BDSpeechRecognizer alloc] init];
    //    NSObject<NvVoiceRecognizer> *fileRecognizer = [[AWSSpeechRecognizer alloc] init];
        
//        moduleManager.voiceRecognizer = fileRecognizer;
    
    NvHttpRequest *request = [NvHttpRequest sharedInstance];
    [self configUrl:request];
    
    NvMaterialCenter* materialCenter = [NvMaterialCenter sharedInstance];
    materialCenter.netDelegate = request;
    [materialCenter prepareDownloadFolders];
    
    [self networkState];
}

- (void)configUrl:(NvHttpRequest *)request {
    request.assetRequestUrl = NV_ASSET_REQUEST_URL;
    request.assetCategoryUrl = NV_ASSET_CATEGORY_URL;
    request.assetMusiciansUrl = NV_ASSET_MUSICIANS_URL;
    request.assetFontUrl = NV_ASSET_FONT_URL;
    request.assetDownloadUrl = NV_ASSET_DOWNLOAD_URL;
    request.assetPrefabricatedUrl = NV_ASSET_PREFABRICATED_URL;
    request.assetAutoCutUrl = NV_ASSET_AUTOCUT_URL;
    request.assetTagUrl = NV_ASSET_TAG_URL;
    
    request.clientId = NV_ClientId;
    request.clientSecret = NV_ClientSecret;
    request.assemblyId = NV_AssemblyId;
    
    request.isAbroad = 1;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:animated];
}

- (void)networkState{
    // 联网后，请求、下载模型文件
    // After networking, request and download the model file
    nw_path_monitor_t monitor = nw_path_monitor_create();
    nw_path_monitor_set_queue(monitor, dispatch_get_main_queue());
    nw_path_monitor_set_update_handler(monitor, ^(nw_path_t path) {
        if (nw_path_get_status(path) == nw_path_status_satisfied) {
            NvModuleManager* moduleManager = [NvModuleManager sharedInstance];
            [moduleManager preloadedResource];
            nw_path_monitor_cancel(monitor);
        } else {
//            NSLog(@"Network not reachable");
        }
    });
    nw_path_monitor_start(monitor);
}

- (IBAction)sendertapCapture:(UIButton*)bt {
    bt.enabled = NO;
    NvModuleManager* moduleManager = [NvModuleManager sharedInstance];
    [moduleManager startCaptureWithPresentViewController:self.navigationController config:self.videoConfig music:nil with:^{
        bt.enabled = YES;
    }];
}

- (IBAction)tapDualCapture:(UIButton*)bt {
    bt.enabled = NO;
    NvModuleManager* moduleManager = [NvModuleManager sharedInstance];
    [moduleManager startDualCaptureWithPresentViewController:self.navigationController config:self.videoConfig with:^{
        bt.enabled = YES;
    }];
}

- (IBAction)editBtClicked:(UIButton*)bt {
    bt.enabled = NO;
    NvModuleManager* moduleManager = [NvModuleManager sharedInstance];
    [moduleManager startEditWithPresentViewController:self.navigationController config:self.videoConfig with:^{
        bt.enabled = YES;
    }];
}

- (IBAction)draftBtClicked:(UIButton*)bt {
    bt.enabled = NO;
    NvDraftListViewController* draftListVc = [[NvDraftListViewController alloc] initWithConfig:self.videoConfig];
    [self.navigationController pushViewController:draftListVc animated:YES];
    bt.enabled = YES;
}

- (IBAction)settingsBtClicked:(UIButton*)bt {
    bt.enabled = NO;
    bt.enabled = YES;
}

- (void)test{
    self.videoConfig = [[NvVideoConfig alloc] init];
    self.videoConfig.primaryColor = [UIColor colorWithHexRGBA:@"#0000FF"];
    self.videoConfig.backgroundColor = [UIColor colorWithHexRGBA:@"#00FA9A"];
    self.videoConfig.panelBackgroundColor = [UIColor colorWithHexRGBA:@"#000080"];
    self.videoConfig.textColor = [UIColor colorWithHexRGBA:@"#FFA500"];
    self.videoConfig.secondaryTextColor = [UIColor colorWithHexRGBA:@"#8A2BE2"];
    self.videoConfig.enableLocalMusic = false;
    
    //相册配置 albumConfig
    self.videoConfig.albumConfig.type = 1;
    self.videoConfig.albumConfig.maxSelectCount = 5;
    self.videoConfig.albumConfig.useAutoCut = false;
    
    //拍摄配置 captureConfig
    self.videoConfig.captureConfig.captureMenuItems = @[
        NvCaptureMenuItemDevice,
        NvCaptureMenuItemSpeed,
        NvCaptureMenuItemBeauty,
        NvCaptureMenuItemOriginal,
        NvCaptureMenuItemFilter
    ];
    self.videoConfig.captureConfig.captureBottomMenuItems = @[
        NvCaptureBottomMenuItemImage,
        NvCaptureBottomMenuItemVideo
    ];
    self.videoConfig.captureConfig.captureDeviceIndex = 0;
    self.videoConfig.captureConfig.resolution = NvVideoPreviewResolution_720;
    self.videoConfig.captureConfig.ignoreVideoRotation = false;
    self.videoConfig.captureConfig.imageDuration = 6 * 1000;
    self.videoConfig.captureConfig.autoSavePhotograph = true;
    NvTimePair *pair1 = [[NvTimePair alloc] init];
    pair1.minDuration = 1 * 1000;
    pair1.maxDuration = 10 * 1000;
    NvTimePair *pair2 = [[NvTimePair alloc] init];
    pair2.minDuration = 0;
    pair2.maxDuration = 50 * 1000;
    self.videoConfig.captureConfig.timeRanges = @[pair1, pair2];
    NvTimePair *pair3 = [[NvTimePair alloc] init];
    pair3.minDuration = 0;
    pair3.maxDuration = 30 * 1000;
    self.videoConfig.captureConfig.smartTimeRange = pair3;
    
    self.videoConfig.captureConfig.beautyConfig = [[NvBeautyConfig alloc] init];
    self.videoConfig.captureConfig.beautyConfig.categoricalArray = @[
        NvBeautyCategoricalSkin,
        NvBeautyCategoricalMicroShape
    ];
    self.videoConfig.captureConfig.beautyConfig.beautyEffectArray = @[
        NvBeautyEffectStandard,
        NvBeautyEffectWhiteA,
        NvBeautyEffectRosy
    ];
    
    self.videoConfig.captureConfig.dualMenuItems = @[
        NvCaptureMenuItemDevice,
        NvCaptureMenuItemDualType,
        NvCaptureMenuItemOriginal
    ];
    self.videoConfig.captureConfig.dualConfig = [[NvDualConfig alloc] init];
    self.videoConfig.captureConfig.dualConfig.left = 50.0 / 375.0;
    self.videoConfig.captureConfig.dualConfig.top = 50.0 / 666.67;
    self.videoConfig.captureConfig.dualConfig.limitWidth = 200 / 375.0;
    self.videoConfig.captureConfig.dualConfig.defaultType = NvDualType_topDown;
    self.videoConfig.captureConfig.dualConfig.supportedTypes = NvDualType_topDown | NvDualType_leftRight;
    self.videoConfig.captureConfig.dualConfig.autoDisablesMic = true;
    
    self.videoConfig.captureConfig.filterDefaultValue = 1.0;
    self.videoConfig.captureConfig.enableCaptureAlbum = true;
    self.videoConfig.captureConfig.autoDisablesMic = true;
    
    //编辑配置 albumConfig
    self.videoConfig.editConfig.editMenuItems = @[
        NvEditMenuItemRelease,
        NvEditMenuItemDownload,
        NvEditMenuItemText
    ];
    self.videoConfig.editConfig.resolution = NvVideoPreviewResolution_1080;
    self.videoConfig.editConfig.fps = 25;
    self.videoConfig.editConfig.minEffectDuration = 1000;
    self.videoConfig.editConfig.minAudioDuration = 3000;
    self.videoConfig.editConfig.captionColor = @"#FFA500";
    self.videoConfig.editConfig.captionColorList = @[
        @"#FFFFFF",
        @"#000000",
        @"#0099F6",
        @"#50C23B",
    ];
    self.videoConfig.editConfig.supportedCaptionStyles = 9;
    self.videoConfig.editConfig.editModeSource = NvEditModeSourceFirstAsset;
    self.videoConfig.editConfig.editMode = NvEditMode9v16;
    self.videoConfig.editConfig.supportedEditModes =
    NvEditMode9v16 |
    NvEditMode16v9 |
    NvEditMode3v4 |
    NvEditMode4v3 |
    NvEditMode1v1 |
    NvEditMode18v9 |
    NvEditMode9v18 |
    NvEditMode8v9 |
    NvEditMode9v8;
    self.videoConfig.editConfig.bubbleConfig = [[NvBubbleConfig alloc] init];
    self.videoConfig.editConfig.bubbleConfig.titleTheme = [[NvLabelTheme alloc] init];
    self.videoConfig.editConfig.bubbleConfig.titleTheme.textColor = [UIColor colorWithHexRGBA:@"#0000FF"];
    self.videoConfig.editConfig.bubbleConfig.backgroundBlurStyle = NvBubbleBgBlurStyleLight;
    
    self.videoConfig.editConfig.filterDefaultValue = 1.0;
    self.videoConfig.editConfig.maxVolume = 1;
    
    //导出配置 compile Config
    self.videoConfig.compileConfig.resolution = NvVideoCompileResolution_720;
    self.videoConfig.compileConfig.fps = 25;
    self.videoConfig.compileConfig.bitrateGrade = NvsCompileBitrateGradeHigh;
    self.videoConfig.compileConfig.bitrate = -1;
    self.videoConfig.compileConfig.autoSaveVideo = true;
    
    //模版配置 compile Config
    self.videoConfig.templateConfig.maxSelectCount = 5;
    self.videoConfig.templateConfig.useAutoCut = false;

    //模型配置 model Config
//    self.videoConfig.modelConfig.use240 = true;
//    self.videoConfig.modelConfig.face240 = "ms_face240_v2.0.8.model";

    //以”capture_capture_close_bt“为例
    NvButtonTheme *buttonTheme = [[NvButtonTheme alloc] init];
    buttonTheme.imageName = @"homepage_logo";
    self.videoConfig.captureConfig.customTheme[NvCaptureCloseBtKey] = buttonTheme;

    //以”capture_duration_label“为例
    NvLabelTheme *labelTheme = [[NvLabelTheme alloc] init];
    labelTheme.textColor = UIColor.redColor;
    self.videoConfig.captureConfig.customTheme[NvCaptureDurationLabelKey] = labelTheme;

    //以”capture_music_menu_view“为例
    NvViewTheme *viewTheme = [[NvViewTheme alloc] init];
    viewTheme.backgroundColor = UIColor.redColor;
    self.videoConfig.captureConfig.customTheme[NvCaptureMusicMenuViewKey] = viewTheme;

    //以”capture_capture_record_bt_set“为例
    NvRecordBtTheme *record = [[NvRecordBtTheme alloc]init];
    record.minimumTrackTintColor = UIColor.redColor;
    self.videoConfig.captureConfig.customTheme[NvCaptureRecordBtSetKey] = record;
}

//MARK: -- NvSettingViewControllerDelegate

- (void)applyConfigFile:(NSString *)configFile {
    if (configFile) {
        self.selectedConfigPath = configFile;
        NSData *data = [NSData dataWithContentsOfFile:configFile];
        self.videoConfig = [NvVideoConfig yy_modelWithJSON:data];
    } else {
        self.videoConfig = nil;
    }
}


- (void)publishWithTaskId:(NSString *)taskId
           coverImagePath:(NSString *)coverImagePath
                 hasDraft:(BOOL)hasDraft
                draftInfo:(NSString *_Nullable)draftInfo
videoEditNavigationController:(UINavigationController *)videoEditNavigationController {
    NvPublicViewController *publicVc = [[UIStoryboard storyboardWithName:@"Main" bundle:nil] instantiateViewControllerWithIdentifier:@"NvPublicViewController"];
    publicVc.imagePath = coverImagePath;
    publicVc.hasDraft = hasDraft;
    publicVc.draftInfo = draftInfo;
    publicVc.taskId = taskId;
    [videoEditNavigationController pushViewController:publicVc animated:YES];
}

//MARK: -- NvThemeDelegate

- (void)configView:(UIView *)view viewIndicate:(NSString *)viewIndicate {
    NSLog(@"---> configView");
}

- (void)configTableCell:(UITableViewCell *)cell
           viewIndicate:(NSString *)viewIndicate
               selected:(BOOL)selected {
    NSLog(@"---> configTableCell");
}

- (void)configCollectViewCell:(UICollectionView *)cell
                 viewIndicate:(NSString *)viewIndicate
                     selected:(BOOL)selected {
    NSLog(@"---> configCollectViewCell");
}
@end
