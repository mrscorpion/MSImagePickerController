//
//  TZPhotoPickerController.m
//  TZImagePickerController
//
//  Created by mr.scorpion on 15/12/24.
//  Copyright © 2015年 mr.scorpion. All rights reserved.
//

#import "TZPhotoPickerController.h"
#import "TZImagePickerController.h"
#import "TZPhotoPreviewController.h"
#import "TZAssetCell.h"
#import "TZAssetModel.h"
#import "UIView+Layout.h"
#import "TZImageManager.h"
#import "TZVideoPlayerController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import <objc/runtime.h>

#define kMaxColumnCount 3 //4

typedef NS_ENUM(NSUInteger, MediaType) {
    MediaTypeNone,
    MediaTypePhoto,
    MediaTypeVideo,
};

@interface TZPhotoPickerController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate> {
    NSMutableArray *_models;
    
    UIButton *_previewButton;
    UIButton *_okButton;
    UIImageView *_numberImageView;
    UILabel *_numberLable;
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLable;
    
    BOOL _shouldScrollToBottom;
}
@property CGRect previousPreheatRect;
@property (nonatomic, assign) BOOL isSelectOriginalPhoto;
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UIImagePickerController *imagePickerVc;

@property (nonatomic, assign) BOOL isVideo;
@property (nonatomic, assign) MediaType mediaType;
@end

static CGSize AssetGridThumbnailSize;

@implementation TZPhotoPickerController

- (UIImagePickerController *)imagePickerVc {
    if (_imagePickerVc == nil) {
        _imagePickerVc = [[UIImagePickerController alloc] init];
        _imagePickerVc.delegate = self;
        // set appearance / 改变相册选择页的导航栏外观
        _imagePickerVc.navigationBar.barTintColor = self.navigationController.navigationBar.barTintColor;
        _imagePickerVc.navigationBar.tintColor = self.navigationController.navigationBar.tintColor;
        UIBarButtonItem *tzBarItem, *BarItem;
        if (iOS9Later) {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[TZImagePickerController class]]];
            BarItem = [UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UIImagePickerController class]]];
        } else {
            tzBarItem = [UIBarButtonItem appearanceWhenContainedIn:[TZImagePickerController class], nil];
            BarItem = [UIBarButtonItem appearanceWhenContainedIn:[UIImagePickerController class], nil];
        }
        NSDictionary *titleTextAttributes = [tzBarItem titleTextAttributesForState:UIControlStateNormal];
        [BarItem setTitleTextAttributes:titleTextAttributes forState:UIControlStateNormal];
    }
    return _imagePickerVc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    _isSelectOriginalPhoto = tzImagePickerVc.isSelectOriginalPhoto;
    _shouldScrollToBottom = YES;
    self.view.backgroundColor = [UIColor whiteColor];
    self.navigationItem.title = _model.name;
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"取消" style:UIBarButtonItemStylePlain target:self action:@selector(cancel)];
    if ([_model.name isEqualToString:@"相机胶卷"] || [_model.name isEqualToString:@"Camera Roll"] ||  [_model.name isEqualToString:@"所有照片"] || !iOS8Later) {
        [[TZImageManager manager] getAssetsFromFetchResult:_model.result allowPickingVideo:tzImagePickerVc.allowPickingVideo allowPickingImage:tzImagePickerVc.allowPickingImage completion:^(NSArray<TZAssetModel *> *models) {
            _models = [NSMutableArray arrayWithArray:models];
            [self initSubviews];
        }];
    } else {
        _models = [NSMutableArray arrayWithArray:_model.models];
        [self initSubviews];
    }
    // [self resetCachedAssets];
}

- (void)initSubviews {
    [self checkSelectedModels];
    [self configCollectionView];
    [self configBottomToolBar];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    tzImagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    if (self.backButtonClickHandle) {
        self.backButtonClickHandle(_model);
    }
}

- (void)configCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    CGFloat margin = 4;
//    CGFloat itemWH = (self.view.tz_width - 2 * margin - 4) / 4 - margin;
    CGFloat itemWH = (self.view.tz_width - 2 * margin - 4) / kMaxColumnCount - margin;
    layout.itemSize = CGSizeMake(itemWH, itemWH);
    layout.minimumInteritemSpacing = margin;
    layout.minimumLineSpacing = margin;
    CGFloat top = margin + 44;
    if (iOS7Later) top += 20;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(margin, top, self.view.tz_width - 2 * margin, self.view.tz_height - 50 - top) collectionViewLayout:layout];
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.alwaysBounceHorizontal = NO;
    if (iOS7Later) _collectionView.contentInset = UIEdgeInsetsMake(0, 0, 0, 2);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, -2);
    if ([_model.name isEqualToString:@"相机胶卷"] || [_model.name isEqualToString:@"Camera Roll"] ||  [_model.name isEqualToString:@"所有照片"] ) {
        _collectionView.contentSize = CGSizeMake(self.view.tz_width, ((_model.count + 4) / 4) * self.view.tz_width);
    } else {
        _collectionView.contentSize = CGSizeMake(self.view.tz_width, ((_model.count + 3) / 4) * self.view.tz_width);
    }
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[TZAssetCell class] forCellWithReuseIdentifier:@"TZAssetCell"];
    [_collectionView registerClass:[TZAssetCameraCell class] forCellWithReuseIdentifier:@"TZAssetCameraCell"];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self scrollCollectionViewToBottom];
    // Determine the size of the thumbnails to request from the PHCachingImageManager
    CGFloat scale = [UIScreen mainScreen].scale;
    CGSize cellSize = ((UICollectionViewFlowLayout *)_collectionView.collectionViewLayout).itemSize;
    AssetGridThumbnailSize = CGSizeMake(cellSize.width * scale, cellSize.height * scale);
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (iOS8Later) {
        // [self updateCachedAssets];
    }
}

// 底部的toolbar -- 预览、确定
- (void)configBottomToolBar {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    UIView *bottomToolBar = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.tz_height - 50, self.view.tz_width, 50)];
    CGFloat rgb = 50 / 255.0; //253 / 255.0;
    bottomToolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
    
    _previewButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _previewButton.frame = CGRectMake(10, 3, 44, 44);
    [_previewButton addTarget:self action:@selector(previewButtonClick) forControlEvents:UIControlEventTouchUpInside];
    _previewButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_previewButton setTitle:@"预览" forState:UIControlStateNormal];
    [_previewButton setTitle:@"预览" forState:UIControlStateDisabled];
//    [_previewButton setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
//    [_previewButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    [_previewButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_previewButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateDisabled];
    _previewButton.enabled = tzImagePickerVc.selectedModels.count;
    
    if (tzImagePickerVc.allowPickingOriginalPhoto) {
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.frame = CGRectMake(50, self.view.tz_height - 50, 130, 50);
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, -8, 0, 0);
        _originalPhotoButton.contentEdgeInsets = UIEdgeInsetsMake(0, -45, 0, 0);
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:16];
        [_originalPhotoButton setTitle:@"原图" forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:@"原图" forState:UIControlStateSelected];
//        [_originalPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
//        [_originalPhotoButton setTitleColor:[UIColor blackColor] forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor lightTextColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_originalPhotoButton setImage:[UIImage imageNamedFromMyBundle:@"photo_original_def.png"] forState:UIControlStateNormal];
        [_originalPhotoButton setImage:[UIImage imageNamedFromMyBundle:@"photo_original_sel.png"] forState:UIControlStateSelected];
        _originalPhotoButton.selected = _isSelectOriginalPhoto;
        _originalPhotoButton.enabled = tzImagePickerVc.selectedModels.count > 0;
        
        _originalPhotoLable = [[UILabel alloc] init];
        _originalPhotoLable.frame = CGRectMake(70, 0, 60, 50);
        _originalPhotoLable.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLable.font = [UIFont systemFontOfSize:16];
//        _originalPhotoLable.textColor = [UIColor blackColor];
        _originalPhotoLable.textColor = [UIColor whiteColor];
        if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
    }
    
    _okButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _okButton.frame = CGRectMake(self.view.tz_width - 44 - 12, 3, 44, 44);
    _okButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_okButton addTarget:self action:@selector(okButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_okButton setTitle:@"确定" forState:UIControlStateNormal];
    [_okButton setTitle:@"确定" forState:UIControlStateDisabled];
//    [_okButton setTitleColor:tzImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
//    [_okButton setTitleColor:tzImagePickerVc.oKButtonTitleColorDisabled forState:UIControlStateDisabled];
    [_okButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_okButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateDisabled];
    _okButton.enabled = tzImagePickerVc.selectedModels.count;
    
    _numberImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamedFromMyBundle:@"photo_number_icon.png"]]; // 数字的背景图片
    _numberImageView.frame = CGRectMake(self.view.tz_width - 56 - 24, 12, 26, 26);
    _numberImageView.hidden = tzImagePickerVc.selectedModels.count <= 0;
    _numberImageView.backgroundColor = [UIColor clearColor];
    
    _numberLable = [[UILabel alloc] init];
    _numberLable.frame = _numberImageView.frame;
    _numberLable.font = [UIFont systemFontOfSize:16];
    _numberLable.textColor = [UIColor whiteColor];
    _numberLable.textAlignment = NSTextAlignmentCenter;
    _numberLable.text = [NSString stringWithFormat:@"%zd",tzImagePickerVc.selectedModels.count];
    _numberLable.hidden = tzImagePickerVc.selectedModels.count <= 0;
    _numberLable.backgroundColor = [UIColor clearColor];
    
    UIView *divide = [[UIView alloc] init];
    CGFloat rgb2 = 222 / 255.0;
    divide.backgroundColor =  [UIColor colorWithRed:rgb2 green:rgb2 blue:rgb2 alpha:1.0];
    divide.frame = CGRectMake(0, 0, self.view.tz_width, 1);

    [bottomToolBar addSubview:divide];
    [bottomToolBar addSubview:_previewButton];
    [bottomToolBar addSubview:_okButton];
    [bottomToolBar addSubview:_numberImageView];
    [bottomToolBar addSubview:_numberLable];
    [self.view addSubview:bottomToolBar];
    [self.view addSubview:_originalPhotoButton];
    [_originalPhotoButton addSubview:_originalPhotoLable];
}

#pragma mark - Click Event

- (void)cancel {
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    if ([imagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerControllerDidCancel:)]) {
        [imagePickerVc.pickerDelegate imagePickerControllerDidCancel:imagePickerVc];
    }
    if (imagePickerVc.imagePickerControllerDidCancelHandle) {
        imagePickerVc.imagePickerControllerDidCancelHandle();
    }
}

- (void)previewButtonClick {
    TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
    [self pushPhotoPrevireViewController:photoPreviewVc];
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLable.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)okButtonClick {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    [tzImagePickerVc showProgressHUD];
    NSMutableArray *photos = [NSMutableArray array];
    NSMutableArray *assets = [NSMutableArray array];
    NSMutableArray *infoArr = [NSMutableArray array];
    for (NSInteger i = 0; i < tzImagePickerVc.selectedModels.count; i++) { [photos addObject:@1];[assets addObject:@1];[infoArr addObject:@1]; }
    
    [TZImageManager manager].shouldFixOrientation = YES;
    for (NSInteger i = 0; i < tzImagePickerVc.selectedModels.count; i++) {
        TZAssetModel *model = tzImagePickerVc.selectedModels[i];
        [[TZImageManager manager] getPhotoWithAsset:model.asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
            if (isDegraded) return;
            if (photo) {
                photo = [self scaleImage:photo toSize:CGSizeMake(tzImagePickerVc.photoWidth, tzImagePickerVc.photoWidth * photo.size.height / photo.size.width)];
                [photos replaceObjectAtIndex:i withObject:photo];
            }
            if (info)  [infoArr replaceObjectAtIndex:i withObject:info];
            [assets replaceObjectAtIndex:i withObject:model.asset];

            for (id item in photos) { if ([item isKindOfClass:[NSNumber class]]) return; }
            
            if ([tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:)]) {
                [tzImagePickerVc.pickerDelegate imagePickerController:tzImagePickerVc didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto];
            }
            if ([tzImagePickerVc.pickerDelegate respondsToSelector:@selector(imagePickerController:didFinishPickingPhotos:sourceAssets:isSelectOriginalPhoto:infos:)]) {
                [tzImagePickerVc.pickerDelegate imagePickerController:tzImagePickerVc didFinishPickingPhotos:photos sourceAssets:assets isSelectOriginalPhoto:_isSelectOriginalPhoto infos:infoArr];
            }
            if (tzImagePickerVc.didFinishPickingPhotosHandle) {
                tzImagePickerVc.didFinishPickingPhotosHandle(photos,assets,_isSelectOriginalPhoto);
            }
            if (tzImagePickerVc.didFinishPickingPhotosWithInfosHandle) {
                tzImagePickerVc.didFinishPickingPhotosWithInfosHandle(photos,assets,_isSelectOriginalPhoto,infoArr);
            }
            [tzImagePickerVc hideProgressHUD];
            [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        }];
    }
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    if ([_model.name isEqualToString:@"相机胶卷"] || [_model.name isEqualToString:@"Camera Roll"] ||  [_model.name isEqualToString:@"所有照片"] ) {
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        if (tzImagePickerVc.allowPickingImage) { // 挑选图片
            return _models.count + 1;
        }
    }
//    return _models.count;
    return _models.count + 1; // 选择视频
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc.allowPickingImage) { // 挑选图片
        // the cell lead to take a picture / 去拍照的cell
        if (indexPath.row >= _models.count) {
            TZAssetCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCameraCell" forIndexPath:indexPath];
            cell.imageView.image = [UIImage imageNamed:@"chat_camera.png"];//[UIImage imageNamedFromMyBundle:@"chat_camera.png"];
            return cell;
        }
    } else {
        if (indexPath.row >= _models.count) {
            TZAssetCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCameraCell" forIndexPath:indexPath];
            cell.imageView.image = [UIImage imageNamed:@"chat_audio.png"];//[UIImage imageNamedFromMyBundle:@"chat_audio.png"];
            return cell;
        }
    }
    
//#pragma mark - 测试一下 - 拍照cell
//    if (indexPath.row == 0) {
//        TZAssetCameraCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCameraCell" forIndexPath:indexPath];
//        cell.imageView.image = [UIImage imageNamedFromMyBundle:@"takePicture.png"];
//        return cell;
//    }
    // the cell dipaly photo or video / 展示照片或视频的cell
    TZAssetCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZAssetCell" forIndexPath:indexPath];
    TZAssetModel *model = _models[indexPath.row];
    cell.model = model;
    
    __weak typeof(cell) weakCell = cell;
    __weak typeof(self) weakSelf = self;
    __weak typeof(_numberImageView.layer) weakLayer = _numberImageView.layer;
    cell.didSelectPhotoBlock = ^(BOOL isSelected) {
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)weakSelf.navigationController;
        // 1. cancel select / 取消选择
        if (isSelected) {
            weakCell.selectPhotoButton.selected = NO;
            model.isSelected = NO;
            NSArray *selectedModels = [NSArray arrayWithArray:tzImagePickerVc.selectedModels];
            for (TZAssetModel *model_item in selectedModels) {
                if ([model.asset isEqual:model_item.asset]) {
                    [tzImagePickerVc.selectedModels removeObject:model_item];
                }
            }
            [weakSelf refreshBottomToolBarStatus];
        } else {
            // 2. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
            if (tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount) {
                weakCell.selectPhotoButton.selected = YES;
                model.isSelected = YES;
                [tzImagePickerVc.selectedModels addObject:model];
                [weakSelf refreshBottomToolBarStatus];
            } else {
                [tzImagePickerVc showAlertWithTitle:[NSString stringWithFormat:@"你最多只能选择%zd张照片",tzImagePickerVc.maxImagesCount]];
            }
        }
         [UIView showOscillatoryAnimationWithLayer:weakLayer type:TZOscillatoryAnimationToSmaller];
    };
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (tzImagePickerVc.allowPickingImage) {
        // take a picture / 去拍照
        if (indexPath.row >= _models.count) {
            [self takePicture];
            return;
        }
    } else {
        // take a picture / 录像
        if (indexPath.row >= _models.count) {
            [self takeVideo];
            return;
        }
    }
//    // take a picture / 去拍照
//    if (indexPath.row >= _models.count) {
//        [self takePicture]; return;
//    }
//#pragma mark - 测试一下 - 拍照
//    if (indexPath.row == 0) {
//        [self takePicture];
//        return;
//    }
    // preview phote or video / 预览照片或视频
    TZAssetModel *model = _models[indexPath.row];
//    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    if (model.type == TZAssetModelMediaTypeVideo) {
        if (tzImagePickerVc.selectedModels.count > 0) {
            TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
            [imagePickerVc showAlertWithTitle:@"选择照片时不能选择视频"];
            self.mediaType = MediaTypePhoto;
        } else {
            TZVideoPlayerController *videoPlayerVc = [[TZVideoPlayerController alloc] init];
            videoPlayerVc.model = model;
            self.mediaType = MediaTypeVideo;
            [self.navigationController pushViewController:videoPlayerVc animated:YES];
        }
    } else {
        TZPhotoPreviewController *photoPreviewVc = [[TZPhotoPreviewController alloc] init];
        photoPreviewVc.currentIndex = indexPath.row;
        photoPreviewVc.models = _models;
        [self pushPhotoPrevireViewController:photoPreviewVc];
    }
}

#pragma mark - UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if (iOS8Later) {
        // [self updateCachedAssets];
    }
}

#pragma mark - Private Method
- (void)takePicture
{
    UIImagePickerControllerSourceType sourceType = UIImagePickerControllerSourceTypeCamera;
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        self.imagePickerVc.delegate = self;
        self.imagePickerVc.allowsEditing = YES; //设置拍照后的图片可被编辑
        self.imagePickerVc.sourceType = sourceType;
        if(iOS8Later) {
            _imagePickerVc.modalPresentationStyle = UIModalPresentationOverCurrentContext;
        }
        [self presentViewController:_imagePickerVc animated:YES completion:nil];
    } else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}
- (void)takeVideo
{
#if TARGET_IPHONE_SIMULATOR
    [self showHint:@"不支持相机功能"];
#elif TARGET_OS_IPHONE
    self.imagePickerVc.sourceType = UIImagePickerControllerSourceTypeCamera;
    self.imagePickerVc.mediaTypes = @[(NSString *)kUTTypeMovie];
    self.imagePickerVc.allowsEditing = YES;// 允许编辑
    self.imagePickerVc.videoMaximumDuration = 60.0f;//设置最长录制时间为1分钟
//    self.imagePickerVc.videoQuality = UIImagePickerControllerQualityTypeIFrame1280x720; //视频质量设置
//    self.imagePickerVc.cameraCaptureMode = UIImagePickerControllerCameraCaptureModeVideo;
    [self presentViewController:self.imagePickerVc animated:YES completion:NULL];
#endif
}

- (void)refreshBottomToolBarStatus {
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    
    _previewButton.enabled = imagePickerVc.selectedModels.count > 0;
    _okButton.enabled = imagePickerVc.selectedModels.count > 0;
    
    _numberImageView.hidden = imagePickerVc.selectedModels.count <= 0;
    _numberLable.hidden = imagePickerVc.selectedModels.count <= 0;
    _numberLable.text = [NSString stringWithFormat:@"%zd",imagePickerVc.selectedModels.count];
    
    _originalPhotoButton.enabled = imagePickerVc.selectedModels.count > 0;
    _originalPhotoButton.selected = (_isSelectOriginalPhoto && _originalPhotoButton.enabled);
    _originalPhotoLable.hidden = (!_originalPhotoButton.isSelected);
    if (_isSelectOriginalPhoto) [self getSelectedPhotoBytes];
}

- (void)pushPhotoPrevireViewController:(TZPhotoPreviewController *)photoPreviewVc {
    __weak typeof(self) weakSelf = self;
    photoPreviewVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
    photoPreviewVc.backButtonClickBlock = ^(BOOL isSelectOriginalPhoto) {
        weakSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        [weakSelf checkSelectedModels];
        [weakSelf.collectionView reloadData];
        [weakSelf refreshBottomToolBarStatus];
    };
    photoPreviewVc.okButtonClickBlock = ^(BOOL isSelectOriginalPhoto){
        weakSelf.isSelectOriginalPhoto = isSelectOriginalPhoto;
        [weakSelf okButtonClick];
    };
    [self.navigationController pushViewController:photoPreviewVc animated:YES];
}

- (void)getSelectedPhotoBytes {
    TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
    [[TZImageManager manager] getPhotosBytesWithArray:imagePickerVc.selectedModels completion:^(NSString *totalBytes) {
        _originalPhotoLable.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
}

/// Scale image / 缩放图片
- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size {
    if (image.size.width < size.width) {
        return image;
    }
    UIGraphicsBeginImageContext(size);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

- (void)scrollCollectionViewToBottom {
    if (_shouldScrollToBottom && _models.count > 0) {
        NSInteger item = _models.count - 1;
        if ([_model.name isEqualToString:@"相机胶卷"] || [_model.name isEqualToString:@"Camera Roll"] ||  [_model.name isEqualToString:@"所有照片"] ) {
            TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
            if (tzImagePickerVc.allowPickingImage) {
                item += 1;
            }
        }
        [_collectionView scrollToItemAtIndexPath:[NSIndexPath indexPathForItem:item inSection:0] atScrollPosition:UICollectionViewScrollPositionBottom animated:NO];
        _shouldScrollToBottom = NO;
    }
}

- (void)checkSelectedModels {
    for (TZAssetModel *model in _models) {
        model.isSelected = NO;
        NSMutableArray *selectedAssets = [NSMutableArray array];
        TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
        for (TZAssetModel *model in tzImagePickerVc.selectedModels) {
            [selectedAssets addObject:model.asset];
        }
        if ([[TZImageManager manager] isAssetsArray:selectedAssets containAsset:model.asset]) {
            model.isSelected = YES;
        }
    }
}

#pragma mark - UIImagePickerControllerDelegate
- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    [picker dismissViewControllerAnimated:YES completion:nil]; // //    NSString *mediaType = info[UIImagePickerControllerMediaType];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    if ([type isEqualToString:@"public.image"]) {
        TZImagePickerController *imagePickerVc = (TZImagePickerController *)self.navigationController;
        [imagePickerVc showProgressHUD];
        UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
        [[TZImageManager manager] savePhotoWithImage:image completion:^{
            [self reloadPhotoArray];
        }];
    } else if ([type isEqualToString:(NSString *)kUTTypeMovie]) { //选中了视频,发送
        NSURL *videoURL = info[UIImagePickerControllerMediaURL];
//        [picker dismissViewControllerAnimated:YES completion:^{}];
        // video url:  we will convert it to mp4 format 将mov转化成mp4格式
        NSURL *mp4 = [self convert2Mp4:videoURL];
        //        NSLog(@"image --> %@", [self getImage:[mp4 relativePath]]);
        NSFileManager *fileman = [NSFileManager defaultManager];
        if ([fileman fileExistsAtPath:videoURL.path]) {
            NSError *error = nil;
            [fileman removeItemAtURL:videoURL error:&error];
            if (error) {
                NSLog(@"failed to remove file, error:%@.", error);
            }
        }
        NSString *videoStr = [mp4 relativePath];
        //        NSLog(@"videoStr ---> %@", videoStr);
        UIImage *image = [self getImage:[mp4 relativePath]];
        int time = [self getDurationTime:[mp4 relativePath]];
        //        NSLog(@"image --> %@, time -- > %d", image, time);
        if (self.snycompleted) {
            self.snycompleted(image, videoStr, time); // 传缩略图和图片名
        }
        // 暂时先不做保存
        //         将视频MP4保存到系统相册
        if (UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(videoStr))
        {
            UISaveVideoAtPathToSavedPhotosAlbum(videoStr, self, @selector(video:didFinishSavingWithError:contextInfo:), nil);
        }
        [self reloadPhotoArray];
    }
}
#pragma mark - helper
/**
 *  转换MP4格式
 *
 *  @param movUrl MovieURL
 *
 *  @return MP4格式URL
 */
- (NSURL *)convert2Mp4:(NSURL *)movUrl {
    NSURL *mp4Url = nil;
    AVURLAsset *avAsset = [AVURLAsset URLAssetWithURL:movUrl options:nil];
    NSArray *compatiblePresets = [AVAssetExportSession exportPresetsCompatibleWithAsset:avAsset];
    
    if ([compatiblePresets containsObject:AVAssetExportPresetHighestQuality]) {
        AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:avAsset presetName:AVAssetExportPresetHighestQuality];
        mp4Url = [movUrl copy];
        mp4Url = [mp4Url URLByDeletingPathExtension];
        mp4Url = [mp4Url URLByAppendingPathExtension:@"mp4"];
        exportSession.outputURL = mp4Url;
        exportSession.shouldOptimizeForNetworkUse = YES;
        exportSession.outputFileType = AVFileTypeMPEG4;
        dispatch_semaphore_t wait = dispatch_semaphore_create(0l);
        [exportSession exportAsynchronouslyWithCompletionHandler:^{
            switch ([exportSession status]) {
                case AVAssetExportSessionStatusFailed: {
                    NSLog(@"failed, error:%@.", exportSession.error);
                } break;
                case AVAssetExportSessionStatusCancelled: {
                    NSLog(@"cancelled.");
                } break;
                case AVAssetExportSessionStatusCompleted: {
                    NSLog(@"completed.");
                } break;
                default: {
                    NSLog(@"others.");
                } break;
            }
            dispatch_semaphore_signal(wait);
        }];
        long timeout = dispatch_semaphore_wait(wait, DISPATCH_TIME_FOREVER);
        if (timeout) {
            NSLog(@"timeout.");
        }
        if (wait) {
            //dispatch_release(wait);
            wait = nil;
        }
    }
    return mp4Url;
}
- (int)getDurationTime:(NSString *)videoURL
{
    AVURLAsset *avUrl = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:videoURL]];
    CMTime time = [avUrl duration];
    int seconds = ceil(time.value/time.timescale);
    return seconds;
}
- (UIImage *)getImage:(NSString *)videoURL
{
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:[NSURL fileURLWithPath:videoURL] options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];
    gen.appliesPreferredTrackTransform = YES;
    CMTime time = CMTimeMakeWithSeconds(0.0, 600);
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *thumb = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);
    return thumb;
}
- (void)video:(NSString *)urlStr didFinishSavingWithError:(NSError *)error contextInfo:(void *)contextInfo
{
    if (error) {
        NSLog(@"保存失败");
    } else {
        NSLog(@"保存成功");
    }
}
- (void)setSnycompleted:(void (^)(UIImage *, NSString *, NSInteger))snycompleted
{
    objc_setAssociatedObject(self, @selector(snycompleted), snycompleted, OBJC_ASSOCIATION_COPY_NONATOMIC);
}
- (void(^)(UIImage *, NSString *, NSInteger))snycompleted
{
    return objc_getAssociatedObject(self, @selector(snycompleted));
}


- (void)reloadPhotoArray {
    TZImagePickerController *tzImagePickerVc = (TZImagePickerController *)self.navigationController;
    [[TZImageManager manager] getCameraRollAlbum:tzImagePickerVc.allowPickingVideo allowPickingImage:tzImagePickerVc.allowPickingImage completion:^(TZAlbumModel *model) {
        _model = model;
        [[TZImageManager manager] getAssetsFromFetchResult:_model.result allowPickingVideo:tzImagePickerVc.allowPickingVideo allowPickingImage:tzImagePickerVc.allowPickingImage completion:^(NSArray<TZAssetModel *> *models) {
            [tzImagePickerVc hideProgressHUD];
            
            TZAssetModel *model = [models lastObject];
            [_models addObject:model];
            if (tzImagePickerVc.selectedModels.count < tzImagePickerVc.maxImagesCount) {
                model.isSelected = YES;
                [tzImagePickerVc.selectedModels addObject:model];
                [self refreshBottomToolBarStatus];
            }
            [_collectionView reloadData];
            
            _shouldScrollToBottom = YES;
            [self scrollCollectionViewToBottom];
        }];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - Asset Caching

- (void)resetCachedAssets {
    [[TZImageManager manager].cachingImageManager stopCachingImagesForAllAssets];
    self.previousPreheatRect = CGRectZero;
}

- (void)updateCachedAssets {
    BOOL isViewVisible = [self isViewLoaded] && [[self view] window] != nil;
    if (!isViewVisible) { return; }
    
    // The preheat window is twice the height of the visible rect.
    CGRect preheatRect = _collectionView.bounds;
    preheatRect = CGRectInset(preheatRect, 0.0f, -0.5f * CGRectGetHeight(preheatRect));
    
    /*
     Check if the collection view is showing an area that is significantly
     different to the last preheated area.
     */
    CGFloat delta = ABS(CGRectGetMidY(preheatRect) - CGRectGetMidY(self.previousPreheatRect));
    if (delta > CGRectGetHeight(_collectionView.bounds) / 3.0f) {
        
        // Compute the assets to start caching and to stop caching.
        NSMutableArray *addedIndexPaths = [NSMutableArray array];
        NSMutableArray *removedIndexPaths = [NSMutableArray array];
        
        [self computeDifferenceBetweenRect:self.previousPreheatRect andRect:preheatRect removedHandler:^(CGRect removedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:removedRect];
            [removedIndexPaths addObjectsFromArray:indexPaths];
        } addedHandler:^(CGRect addedRect) {
            NSArray *indexPaths = [self aapl_indexPathsForElementsInRect:addedRect];
            [addedIndexPaths addObjectsFromArray:indexPaths];
        }];
        
        NSArray *assetsToStartCaching = [self assetsAtIndexPaths:addedIndexPaths];
        NSArray *assetsToStopCaching = [self assetsAtIndexPaths:removedIndexPaths];
        
        // Update the assets the PHCachingImageManager is caching.
        [[TZImageManager manager].cachingImageManager startCachingImagesForAssets:assetsToStartCaching
                                            targetSize:AssetGridThumbnailSize
                                           contentMode:PHImageContentModeAspectFill
                                               options:nil];
        [[TZImageManager manager].cachingImageManager stopCachingImagesForAssets:assetsToStopCaching
                                           targetSize:AssetGridThumbnailSize
                                          contentMode:PHImageContentModeAspectFill
                                              options:nil];
        
        // Store the preheat rect to compare against in the future.
        self.previousPreheatRect = preheatRect;
    }
}

- (void)computeDifferenceBetweenRect:(CGRect)oldRect andRect:(CGRect)newRect removedHandler:(void (^)(CGRect removedRect))removedHandler addedHandler:(void (^)(CGRect addedRect))addedHandler {
    if (CGRectIntersectsRect(newRect, oldRect)) {
        CGFloat oldMaxY = CGRectGetMaxY(oldRect);
        CGFloat oldMinY = CGRectGetMinY(oldRect);
        CGFloat newMaxY = CGRectGetMaxY(newRect);
        CGFloat newMinY = CGRectGetMinY(newRect);
        
        if (newMaxY > oldMaxY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, oldMaxY, newRect.size.width, (newMaxY - oldMaxY));
            addedHandler(rectToAdd);
        }
        
        if (oldMinY > newMinY) {
            CGRect rectToAdd = CGRectMake(newRect.origin.x, newMinY, newRect.size.width, (oldMinY - newMinY));
            addedHandler(rectToAdd);
        }
        
        if (newMaxY < oldMaxY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, newMaxY, newRect.size.width, (oldMaxY - newMaxY));
            removedHandler(rectToRemove);
        }
        
        if (oldMinY < newMinY) {
            CGRect rectToRemove = CGRectMake(newRect.origin.x, oldMinY, newRect.size.width, (newMinY - oldMinY));
            removedHandler(rectToRemove);
        }
    } else {
        addedHandler(newRect);
        removedHandler(oldRect);
    }
}

- (NSArray *)assetsAtIndexPaths:(NSArray *)indexPaths {
    if (indexPaths.count == 0) { return nil; }
    
    NSMutableArray *assets = [NSMutableArray arrayWithCapacity:indexPaths.count];
    for (NSIndexPath *indexPath in indexPaths) {
        TZAssetModel *model = _models[indexPath.item];
        [assets addObject:model.asset];
    }
    
    return assets;
}

- (NSArray *)aapl_indexPathsForElementsInRect:(CGRect)rect {
    NSArray *allLayoutAttributes = [_collectionView.collectionViewLayout layoutAttributesForElementsInRect:rect];
    if (allLayoutAttributes.count == 0) { return nil; }
    NSMutableArray *indexPaths = [NSMutableArray arrayWithCapacity:allLayoutAttributes.count];
    for (UICollectionViewLayoutAttributes *layoutAttributes in allLayoutAttributes) {
        NSIndexPath *indexPath = layoutAttributes.indexPath;
        [indexPaths addObject:indexPath];
    }
    return indexPaths;
}
@end
