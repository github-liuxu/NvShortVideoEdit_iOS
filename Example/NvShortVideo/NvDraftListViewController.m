//
//  NvDraftListViewController.m
//  NvShortVideo
//
//  Created by 美摄 on 2022/2/25.
//

#import "NvDraftListViewController.h"
#import "Masonry.h"

#if __has_include(<NvShortVideoCore/NvShortVideoCore.h>)
#import <NvShortVideoCore/NvShortVideoCore.h>
#else
#import "NvShortVideoCore.h"
#endif


@interface NvDraftCell : UITableViewCell

@property(nonatomic,strong)UIImageView* coverImageView;
@property(nonatomic,strong)UILabel* infoLabel;

@end

@implementation NvDraftCell

-(instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        [self setupSubviews];
    }
    return self;
}

-(void)setupSubviews{
    self.backgroundColor = [UIColor clearColor];
    self.contentView.backgroundColor = [UIColor clearColor];
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.coverImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 30, 30)];
    self.coverImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.contentView addSubview:self.coverImageView];
    [self.coverImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.height.mas_equalTo(70);
        make.centerY.equalTo(self.contentView.mas_centerY);
        make.left.equalTo(self.contentView.mas_left).offset(20);
    }];
    self.coverImageView.backgroundColor = [UIColor blackColor];
    CGRect rect = [UIScreen mainScreen].bounds;
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, rect.size.width-30, 40)];
    self.infoLabel.textColor = [UIColor colorWithRed:196/255.0 green:196/255.0 blue:196/255.0 alpha:1.0];
    self.infoLabel.font = [UIFont systemFontOfSize:12];
    self.infoLabel.text = NSLocalizedString(@"add_description", @"请添加描述～");
    [self.contentView addSubview:self.infoLabel];
    [self.infoLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.coverImageView.mas_right).offset(15);
        make.top.equalTo(self.coverImageView);
    }];
}

-(void)loadDraftModel:(NvDraftModel*)draftModel{
    NSString* imagePath = draftModel.coverFilePath;
    self.coverImageView.image = [UIImage imageWithContentsOfFile:imagePath];
    self.infoLabel.text = (draftModel.draftInfo && draftModel.draftInfo.length>0) ? draftModel.draftInfo : NSLocalizedString(@"add_description", @"请添加描述～");
}

@end

@interface NvDraftListViewController ()<UITableViewDelegate,UITableViewDataSource>

@property(nonatomic,strong)UITableView* tableView;
@property(nonatomic,strong)UILabel* infoLabel;

@property(nonatomic,strong)NSMutableArray<NvDraftModel*> * draftArray;

@property (nonatomic, strong) NvVideoConfig *config;

@end

@implementation NvDraftListViewController

- (instancetype)initWithConfig:(NvVideoConfig *)config {
    self = [super initWithNibName:nil bundle:nil];
    if (self) {
        self.config = config;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.navigationItem.title = NSLocalizedString(@"DraftList", @"草稿箱");
    
    self.view.backgroundColor = [UIColor colorWithRed:18/255.f green:18/255.f blue:18/255.f alpha:1];
    CGFloat safeAreaTopHeight = [UIApplication sharedApplication].statusBarFrame.size.height+ 44.0;
    CGRect rect = [UIScreen mainScreen].bounds;
    self.infoLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, safeAreaTopHeight+20, rect.size.width-30, 40)];
    self.infoLabel.textColor = [UIColor colorWithRed:128/255.0 green:128/255.0 blue:128/255.0 alpha:1.0];
    self.infoLabel.font = [UIFont systemFontOfSize:13];
    self.infoLabel.numberOfLines = 0;
    self.infoLabel.text = NSLocalizedString(@"DraftListTip", nil);
    [self.view addSubview:self.infoLabel];
    [self.infoLabel sizeToFit];
    self.infoLabel.frame = CGRectMake(self.infoLabel.frame.origin.x, self.infoLabel.frame.origin.y, self.infoLabel.frame.size.width, self.infoLabel.frame.size.height);
    
    CGFloat tableY = self.infoLabel.frame.origin.y+self.infoLabel.frame.size.height;
    CGRect tableRect = CGRectMake(0, tableY, rect.size.width, rect.size.height - tableY);
    self.tableView = [[UITableView alloc] initWithFrame:tableRect style:(UITableViewStylePlain)];
    [self.view addSubview:self.tableView];
    self.tableView.backgroundColor = [UIColor clearColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [UIView new];
    [self.tableView registerClass:NvDraftCell.self forCellReuseIdentifier:@"NvDraftCell"];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    self.draftArray = [NvDraftManager getUserDraftFileArray];
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 80;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.draftArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NvDraftCell* cell = (NvDraftCell*)[tableView dequeueReusableCellWithIdentifier:@"NvDraftCell" forIndexPath:indexPath];
    NvDraftModel* draftModel = self.draftArray[indexPath.row];
    [cell loadDraftModel:draftModel];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    NvDraftModel* draftModel = self.draftArray[indexPath.row];
    [NvModuleManager.sharedInstance reeditDraft:draftModel presentViewController:self config:self.config];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath {
    return UITableViewCellEditingStyleDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"DraftDelete", @"确定删除") message:@"" preferredStyle:UIAlertControllerStyleAlert];

        UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"DraftConfirm", @"是") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            NvDraftModel* draftModel = self.draftArray[indexPath.row];
            [NvDraftManager deleteDraftFile:draftModel];
            [self.draftArray removeObjectAtIndex:indexPath.row];
            [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"DraftCancel", @"否") style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
        }];

        [alertController addAction:cancelAction];
        [alertController addAction:okAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

@end

