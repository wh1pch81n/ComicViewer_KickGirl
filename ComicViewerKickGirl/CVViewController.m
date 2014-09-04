//
//  CVViewController.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVViewController.h"
#import "CVPendingOperations.h"
#import "CVArchiveXMLDownloader.h"
#import "CVFullImageDownloader.h"
#import "CVThumbnailImageDownloader.h"
#import "CVComicRecord.h"
#import "CVFullImageTableViewCell.h"

@interface CVViewController ()
//@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (assign, nonatomic) BOOL canRemoveFullQueueNotificationWhenDealloc;
@property (strong, nonatomic) NSCache *contentViewCache;

@end

@implementation CVViewController

- (NSCache *)contentViewCache{
    if (_contentViewCache) {
        return _contentViewCache;
    }
    _contentViewCache = [NSCache new];
    _contentViewCache.countLimit = 10;
    
    return _contentViewCache;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
    
    {//make the view's origin start at behind the navigationbar rather than under it
        self.edgesForExtendedLayout = UIRectEdgeAll;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    // Do any additional setup after loading the view, typically from a nib.
    { //notification add observers
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullImageDidFinishDownloading:) name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullImageDidFail:) name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION object:nil];
     [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self goToSelectedIndexPath:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - notifications


- (void)fullImageDidFinishDownloading:(NSNotification *)notification {
    //CVComicRecord *comicRecord = notification.userInfo[@"comicRecord"];
    NSIndexPath *indexpath = notification.userInfo[@"indexPath"];
    UIImage *fullImage = notification.userInfo[@"fullImage"];
    
    [self.contentViewCache setObject:fullImage forKey:indexpath];
    dispatch_async(dispatch_get_main_queue(), ^{
        CVFullImageTableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexpath];
        if (cell) {
            cell.text.hidden = YES;
            [cell.loaderGear stopAnimating];
            [cell setComicFullImage:fullImage];
            [self.tableView reloadData];
            //[self.tableView reloadRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationNone];
        }
    });
    [self.pendingOperations.fullDownloadersInProgress removeObjectForKey:indexpath];
}

- (void)fullImageDidFail:(NSNotification *)notification {
    //CVComicRecord *comicRecord = notification.userInfo[@"comicRecord"];
    NSIndexPath *indexpath = notification.userInfo[@"indexPath"];
    //UIImage *fullImage = notification.userInfo[@"fullImage"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        CVFullImageTableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexpath];
        if (cell) {
            cell.text.hidden = NO;
            [cell.loaderGear stopAnimating];
        }
    });
}

#pragma mark - UITableView Protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.comicRecords.count;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 1000;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    CGSize prototypeSize = CGSizeMake(677, 1000);
    float scale = self.view.frame.size.width / prototypeSize.width;
    return prototypeSize.height*scale;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CVFullImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    [cell.loaderGear stopAnimating];
    //save the current row we are on
    if (cell) {
        [[NSUserDefaults standardUserDefaults] setObject:@(indexPath.row) forKey:@"lastPageSeen"];
    }
    
    //Check if image is in the cache
    UIImage *fullImage = [self.contentViewCache objectForKey:indexPath];
    [cell setComicFullImage:fullImage];
    [self requestImageAroundIndexpath:indexPath];
    
    if (fullImage) {
        return cell;
    }
    
    [cell.text setHidden:YES];
    [cell.loaderGear startAnimating];
    
    [self requestImageForIndexPath:indexPath];
    [self requestImageAroundIndexpath:indexPath];
    
    return cell;
}

/**
 calls requestImageForIndexPath: for indexpaths that is one row up and one row down from the given indexpath but only if the row is within bounds of the comicRecords array.
 */
- (void)requestImageAroundIndexpath:(NSIndexPath *)indexPath {
    //try to load front and back
    NSInteger front = indexPath.row -5;
    for (;front < indexPath.row; front++) {
        if (front >= 0 && front < self.comicRecords.count) {
            [self requestImageForIndexPath:[NSIndexPath indexPathForRow:front inSection:0]];
        }
    }
    NSInteger back = indexPath.row + 5;
    for (; back > indexPath.row; back--) {
        if (back >= 0 && back < self.comicRecords.count) {
            [self requestImageForIndexPath:[NSIndexPath indexPathForRow:back inSection:0]];
        }
    }
}

/**
 loads the operation that will download the image for the given indexpath
 */
- (void)requestImageForIndexPath:(NSIndexPath *)indexPath {
//    if (self.tableView.isDecelerating) {
//        //is momentum scrolling should not request.
//        return;
//    }
    
    if ([self.contentViewCache objectForKey:indexPath]) {
        //if it is already cached, I do not need to make a request.
        return;
    }
    
    if (self.pendingOperations.fullDownloadersInProgress[indexPath]) {
        //if it is in the queue you do no need to make a request
        return;
    }
    
    CVComicRecord *comicRecord = self.comicRecords[indexPath.row];
    CVFullImageDownloader *downloader = [[CVFullImageDownloader alloc] initWithComicRecord:comicRecord withIndexPath:indexPath];
    self.pendingOperations.fullDownloadersInProgress[indexPath] = downloader;
    [self.pendingOperations.fullDownloaderOperationQueue addOperation:downloader];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    static float animationDuration = 0.5;
    
    CVFullImageTableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        NSArray *subviews = [cell.contentView subviews];
        UIView *subview = subviews.firstObject;
        if ([subview isKindOfClass:[UILabel class]]) {
            [self requestImageForIndexPath:indexPath];
            return;
        }
    }
    [self toggleNavBarWithAnimationDuration:animationDuration];
}


- (void)toggleNavBarWithAnimationDuration:(NSTimeInterval)seconds {
    __block BOOL isAnimating = NO;
    float animationDuration = seconds;
    if (isAnimating) {
        return;
    }
    if (self.navigationController.isNavigationBarHidden) {
        [self.navigationController.navigationBar setAlpha:1];
        self.navigationController.navigationBarHidden = NO;
    } else {
        isAnimating = YES;
        [self.navigationController.navigationBar setAlpha:1];
        [UIView animateWithDuration:animationDuration
                         animations:^{
                             [self.navigationController.navigationBar setAlpha:0];
                         }
                         completion:^(BOOL finished) {
                             isAnimating = NO;
                             self.navigationController.navigationBarHidden = YES;
                         }];
    }
}

- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.navigationController.navigationBarHidden = YES;
}

//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
//    if (decelerate == NO) {
//        [self loadImagesForOnscreenCells];
//    }
//}
//
//- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
//    [self loadImagesForOnscreenCells];
//}
//
//- (void)loadImagesForOnscreenCells {
//    [[self tableView] reloadData];
//    //    NSArray *ips = [self.tableView indexPathsForVisibleRows];
////    [self.tableView reloadRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationNone];
//}

#pragma mark - reload after tableview loads 


- (void)goToSelectedIndexPath:(id)sender {
    static float animationDuration = 2;
    
    NSIndexPath *indexPath = self.indexpath;
    
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
    [self.tableView reloadData];
    [self toggleNavBarWithAnimationDuration:animationDuration];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSArray *visible = [self.tableView indexPathsForVisibleRows];
    self.indexpath = [visible firstObject];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self goToSelectedIndexPath:self];
}

@end
