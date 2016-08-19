//
//  ViewController.m
//  TZImagePickerController
//
//  Created by mr.scorpion on 15/12/24.
//  Copyright © 2015年 mr.scorpion. All rights reserved.
//

#import "ViewController.h"
#import "IBActionSheet.h"
#import "TZImagePickerController.h"
#import "UIView+Layout.h"
#import "TZTestCell.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <Photos/Photos.h>
#import "LxGridViewFlowLayout.h"
#import "TZImageManager.h"
#import "AddCollectionCell.h"

@interface ViewController ()
<
TZImagePickerControllerDelegate,
UICollectionViewDataSource,
UICollectionViewDelegate,
IBActionSheetDelegate
>
{
    NSMutableArray *_selectedPhotos;
    NSMutableArray *_selectedAssets;
    BOOL _isSelectOriginalPhoto;

    CGFloat _itemWH;
    CGFloat _margin;
    LxGridViewFlowLayout *_layout;
}
@property (nonatomic, strong) UICollectionView *collectionView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    _selectedPhotos = [NSMutableArray array];
    _selectedAssets = [NSMutableArray array];
    [self configCollectionView];
}

- (void)configCollectionView {
    _layout = [[LxGridViewFlowLayout alloc] init];
    _margin = 4;
//    _itemWH = (self.view.tz_width - 2 * _margin - 4) / 3 - _margin;
    _itemWH = (self.view.tz_width - 5 * _margin) / 4 - _margin;
    _layout.itemSize = CGSizeMake(_itemWH, _itemWH);
    _layout.minimumInteritemSpacing = _margin;
    _layout.minimumLineSpacing = _margin;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(_margin, 120, self.view.tz_width - 2 * _margin, 400) collectionViewLayout:_layout];
    CGFloat rgb = 244 / 255.0;
    _collectionView.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
    _collectionView.contentInset = UIEdgeInsetsMake(4, 0, 0, 2);
    _collectionView.scrollIndicatorInsets = UIEdgeInsetsMake(0, 0, 0, -2);
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    [self.view addSubview:_collectionView];
    _collectionView.backgroundColor = [UIColor orangeColor];
    [_collectionView registerClass:[TZTestCell class] forCellWithReuseIdentifier:@"TZTestCell"];
    [_collectionView registerClass:[AddCollectionCell class] forCellWithReuseIdentifier:@"AddCell"];
}

#pragma mark UICollectionView
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return _selectedPhotos.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
//    TZTestCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZTestCell" forIndexPath:indexPath];
    if (indexPath.row == _selectedPhotos.count) {
        UICollectionViewCell *addCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"AddCell" forIndexPath:indexPath];
//        addCell.deleteBtn.hidden = YES;
        return addCell;
//        cell.imageView.image = [UIImage imageNamed:@"group_add.png"];
//        cell.deleteBtn.hidden = YES;
    } else {
        TZTestCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZTestCell" forIndexPath:indexPath];
        cell.imageView.image = _selectedPhotos[indexPath.row];
        cell.deleteBtn.hidden = NO;
        cell.deleteBtn.tag = indexPath.row;
        [cell.deleteBtn addTarget:self action:@selector(deleteBtnClik:) forControlEvents:UIControlEventTouchUpInside];
        return cell;
    }
//    cell.deleteBtn.tag = indexPath.row;
//    [cell.deleteBtn addTarget:self action:@selector(deleteBtnClik:) forControlEvents:UIControlEventTouchUpInside];
//    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.row == _selectedPhotos.count) {
        [self pickPhotoButtonClick:nil];
    } else { // preview photos / 预览照片
        TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithSelectedAssets:_selectedAssets selectedPhotos:_selectedPhotos index:indexPath.row];
        imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
//         imagePickerVc.allowPickingOriginalPhoto = NO;
        [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
            NSLog(@"assets--> %@", assets);
            
            _selectedPhotos = [NSMutableArray arrayWithArray:photos];
            _selectedAssets = [NSMutableArray arrayWithArray:assets];
            _isSelectOriginalPhoto = isSelectOriginalPhoto;
            _layout.itemCount = _selectedPhotos.count;
            [_collectionView reloadData];
            _collectionView.contentSize = CGSizeMake(0, ((_selectedPhotos.count + 2) / 3 ) * (_margin + _itemWH));
         }];
        [self presentViewController:imagePickerVc animated:YES completion:nil];
    }
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)sourceIndexPath didMoveToIndexPath:(NSIndexPath *)destinationIndexPath {
    if (sourceIndexPath.item >= _selectedPhotos.count || destinationIndexPath.item >= _selectedPhotos.count) return;
    UIImage *image = _selectedPhotos[sourceIndexPath.item];
    if (image) {
        [_selectedPhotos exchangeObjectAtIndex:sourceIndexPath.item withObjectAtIndex:destinationIndexPath.item];
        [_selectedAssets exchangeObjectAtIndex:sourceIndexPath.item withObjectAtIndex:destinationIndexPath.item];
        [_collectionView reloadData];
    }
}

#pragma mark Click Event

- (void)deleteBtnClik:(UIButton *)sender {
    [_selectedPhotos removeObjectAtIndex:sender.tag];
    [_selectedAssets removeObjectAtIndex:sender.tag];
    _layout.itemCount = _selectedPhotos.count;
    
    [_collectionView performBatchUpdates:^{
        NSIndexPath *indexPath = [NSIndexPath indexPathForItem:sender.tag inSection:0];
        [_collectionView deleteItemsAtIndexPaths:@[indexPath]];
    } completion:^(BOOL finished) {
        [_collectionView reloadData];
    }];
}

- (IBAction)pickPhotoButtonClick:(UIButton *)sender
{
    [self showSheetView];
//    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
//    imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
//    imagePickerVc.selectedAssets = _selectedAssets; // optional, 可选的
////    imagePickerVc.allowPickingImage = NO; // 用户将不能选择发送图片
//    imagePickerVc.allowPickingOriginalPhoto = NO;
//    // You can get the photos by block, the same as by delegate.
//    // 你可以通过block或者代理，来得到用户选择的照片.
//    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
//    }];
//    
//    // Set the appearance
//    // 在这里设置imagePickerVc的外观
////    imagePickerVc.navigationBar.barTintColor = [UIColor greenColor];
//    // imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
////     imagePickerVc.oKButtonTitleColorNormal = [UIColor greenColor];
//    // Set allow picking video & photo & originalPhoto or not
//    // 设置是否可以选择视频/图片/原图
//    // imagePickerVc.allowPickingVideo = NO;
//    // imagePickerVc.allowPickingImage = NO;
//    // imagePickerVc.allowPickingOriginalPhoto = NO;
//    [self presentViewController:imagePickerVc animated:YES completion:nil];
}

#pragma mark - 选择录像，弹框（视频，录像，制作）
/**
 *  点击"筛选"，底部弹窗
 */
- (void)showSheetView
{
    // "筛选附近的人", "清除我的信息并退出"
    IBActionSheet *customIBAS = [[IBActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"图片", @"视频", @"制作", nil];
    [customIBAS setButtonTextColor:[UIColor redColor]];
    [customIBAS showInView:[UIApplication sharedApplication].keyWindow];
}
/**
 *  点击底部弹窗选项（筛选附近的人、清除我的信息并退出、取消）
 */
- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSLog(@"%ld", (long)buttonIndex);
    switch (buttonIndex) {
        case 0: // 图片选择
        {
            TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:9 delegate:self];
            imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
            imagePickerVc.selectedAssets = _selectedAssets; // optional, 可选的
            imagePickerVc.allowPickingVideo = NO; // 用户将不能选择发送视频
            imagePickerVc.allowPickingOriginalPhoto = NO;
            // You can get the photos by block, the same as by delegate.
            // 你可以通过block或者代理，来得到用户选择的照片.
            [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
            }];
        
            // Set the appearance
            // 在这里设置imagePickerVc的外观
        //    imagePickerVc.navigationBar.barTintColor = [UIColor greenColor];
            // imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightGrayColor];
        //     imagePickerVc.oKButtonTitleColorNormal = [UIColor greenColor];
            // Set allow picking video & photo & originalPhoto or not
            // 设置是否可以选择视频/图片/原图
            // imagePickerVc.allowPickingVideo = NO;
            // imagePickerVc.allowPickingImage = NO;
            // imagePickerVc.allowPickingOriginalPhoto = NO;
            [self presentViewController:imagePickerVc animated:YES completion:nil];
        }
            break;
        case 1: // 视频选择
        {
            TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithMaxImagesCount:1 delegate:self];
            //            imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
            //            imagePickerVc.selectedAssets = _selectedAssets; // optional, 可选的
            // Set the appearance
            // 在这里设置imagePickerVc的外观
            //    imagePickerVc.navigationBar.barTintColor = [UIColor greenColor];
            //             imagePickerVc.oKButtonTitleColorDisabled = [UIColor lightTextColor];
            //             imagePickerVc.oKButtonTitleColorNormal = [UIColor lightTextColor];
            // Set allow picking video & photo & originalPhoto or not
            // 设置是否可以选择视频/图片/原图
            // imagePickerVc.allowPickingVideo = NO;
            
            imagePickerVc.allowPickingImage = NO; // 用户将不能选择发送图片
            imagePickerVc.allowPickingOriginalPhoto = NO;
            // You can get the photos by block, the same as by delegate.
            [imagePickerVc setDidFinishPickingVideoHandle:^(UIImage *image, id asset) {
                NSLog(@"asset-->%@, class-->%@", asset, [asset class]);
                [[TZImageManager manager] getPhotoWithAsset:asset completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
//                    [[TZImageManager manager] getVideoWithAsset:asset completion:^(AVPlayerItem * playerItem, NSDictionary * info, NSString *outPutPath) {
//                        NSLog(@"info-->%@, outPutUrl-->%@, playerItem--> %@", info, outPutPath, playerItem);
//                        CMTime duration = playerItem.asset.duration;
//                        //                        AVURLAsset *urlAsset = (AVURLAsset *)playerItem.asset;
//                        //                        NSURL *url = urlAsset.URL;
//                        //                        NSLog(@"durationTime-->%lld, url-->%@", duration.value, url);
//                        dispatch_async(dispatch_get_main_queue(), ^{
//                            // 隐藏掉图片的collection view, ToDo: 清空图片资源
//                            
//                        });
//                    }];
                }];
            }];
            [self presentViewController:imagePickerVc animated:YES completion:nil];
        }
            break;
        case 2: //制作
        {
        }
            break;
        case 3: //取消
            break;
        default:
            break;
    }
}
- (void)willPresentActionSheet:(UIActionSheet *)actionSheet
{
    for (UIView *subView in actionSheet.subviews) {
        if ([subView isKindOfClass:[UIButton class]]) {
            UIButton *button = (UIButton*)subView;
            [button setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
            [button setTitleColor:[UIColor redColor] forState:UIControlStateHighlighted];
        }
    }
}








#pragma mark TZImagePickerControllerDelegate

/// User click cancel button
/// 用户点击了取消
- (void)imagePickerControllerDidCancel:(TZImagePickerController *)picker {
    // NSLog(@"cancel");
}

/// User finish picking photo，if assets are not empty, user picking original photo.
/// 用户选择好了图片，如果assets非空，则用户选择了原图。
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingPhotos:(NSArray *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    _selectedPhotos = [NSMutableArray arrayWithArray:photos];
    _selectedAssets = [NSMutableArray arrayWithArray:assets];
    _isSelectOriginalPhoto = isSelectOriginalPhoto;
    _layout.itemCount = _selectedPhotos.count;
    [_collectionView reloadData];
    _collectionView.contentSize = CGSizeMake(0, ((_selectedPhotos.count + 2) / 3 ) * (_margin + _itemWH));
}

/// User finish picking video,
/// 用户选择好了视频
- (void)imagePickerController:(TZImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(id)asset {
    _selectedPhotos = [NSMutableArray arrayWithArray:@[coverImage]];
    _selectedAssets = [NSMutableArray arrayWithArray:@[asset]];
    _layout.itemCount = _selectedPhotos.count;
    // open this code to send video / 打开这段代码发送视频
    // [[TZImageManager manager] getVideoOutputPathWithAsset:asset completion:^(NSString *outputPath) {
        // NSLog(@"视频导出到本地完成,沙盒路径为:%@",outputPath);
        // Export completed, send video here, send by outputPath or NSData
        // 导出完成，在这里写上传代码，通过路径或者通过NSData上传
        
    // }];
    [_collectionView reloadData];
    _collectionView.contentSize = CGSizeMake(0, ((_selectedPhotos.count + 2) / 3 ) * (_margin + _itemWH));
}

@end
