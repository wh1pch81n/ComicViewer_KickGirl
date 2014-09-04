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
    CVFullImageTableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
    if (cell) {
        if ([[cell text] isHidden] == NO) {
            [self requestImageForIndexPath:indexPath];
            return;
        }
    }
}

- (void)hideNavigationbar:(BOOL)b animationDuration:(NSTimeInterval)animationDuration {
    __block BOOL isAnimating = NO;
    if (isAnimating) {
        return;
    }
   
    isAnimating = YES;
    [UIView animateWithDuration:animationDuration animations:^{
        [self.navigationController.navigationBar setAlpha:!b];
    } completion:^(BOOL finished) {
        isAnimating = NO;
    }];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    static int oldOffset = 0;
    int newOffset = scrollView.contentOffset.y;
    
    int dy = newOffset- oldOffset;
    if (dy > 0) {
        [self hideNavigationbar:YES animationDuration:0.5];
    } else  if (dy < 0) {
        [self hideNavigationbar:NO animationDuration:0.5];
    }
    
    oldOffset = newOffset;
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate == NO) {
        [self prioritizeVisisbleCells];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self prioritizeVisisbleCells];
}

- (void)prioritizeVisisbleCells {
     NSArray *ips = [self.tableView indexPathsForVisibleRows];
    [self.pendingOperations.fullDownloaderOperationQueue setSuspended:YES];
    NSArray *activeIndexPaths = [self.pendingOperations.fullDownloadersInProgress allKeys];
    //add visible cells to queue first
    NSSet *visible = [NSSet setWithArray:ips];
    NSMutableSet *invisible = [NSMutableSet setWithArray:activeIndexPaths];
    [invisible minusSet:visible];
    
    for (NSIndexPath *ip in invisible) {
        NSOperation *op = self.pendingOperations.fullDownloadersInProgress[ip];
        [op setQueuePriority:NSOperationQueuePriorityNormal];
    }
    
    for (NSIndexPath *ip in visible) {
        NSOperation *op = self.pendingOperations.fullDownloadersInProgress[ip];
        [op setQueuePriority:NSOperationQueuePriorityHigh];
    }
    [self.pendingOperations.fullDownloaderOperationQueue setSuspended:NO];
}

#pragma mark - reload after tableview loads 


- (void)goToSelectedIndexPath:(id)sender {    
    NSIndexPath *indexPath = self.indexpath;
    
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
    [self.tableView reloadData];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    NSArray *visible = [self.tableView indexPathsForVisibleRows];
    self.indexpath = [visible firstObject];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self goToSelectedIndexPath:self];
}

@end
