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
#import "CVPendingOperations.h"

@interface CVViewController ()

@property (assign, nonatomic) BOOL canRemoveFullQueueNotificationWhenDealloc;
@property (weak, nonatomic) NSCache *contentViewCache;

@end

@implementation CVViewController

- (NSCache *)contentViewCache{
    return CVPendingOperations.sharedInstance.fullDownloaderCache;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];

    // Do any additional setup after loading the view, typically from a nib.
    { //notification add observers
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullImageDidFinishDownloading:) name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullImageDidFail:) name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetListener:) name:RKReachabilityDidChangeNotification object:nil];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION object:nil];
     [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKReachabilityDidChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    {//make the view's origin start at behind the navigationbar rather than under it
        self.edgesForExtendedLayout = UIRectEdgeAll;
        self.automaticallyAdjustsScrollViewInsets = NO;
    }
    [self goToSelectedIndexPath:self];
    [self setCurrentPage:self.indexpath.row];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - notifications

- (void)internetListener:(NSNotification *)notification {
    if (CVPendingOperations.sharedInstance.reachabilityObserver.isNetworkReachable) {
        [self.tableView reloadData];
    }
}

- (void)fullImageDidFinishDownloading:(NSNotification *)notification {
    CVComicRecord *comicRecord = notification.userInfo[@"comicRecord"];
    NSString *UUID = notification.userInfo[@"UUID"];
    UIImage *fullImage = notification.userInfo[@"fullImage"];
    
    comicRecord.failedFull = NO;
    
    [self.contentViewCache setObject:fullImage forKey:UUID];
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSIndexPath *indexPath in [self.tableView indexPathsForVisibleRows]) {
            CVFullImageTableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
            if (cell) {
                if ([cell.UUID isEqualToString:UUID]) {
                    [cell.loaderGear stopAnimating];
                    [cell setComicFullImage:fullImage];
                    [cell layoutIfNeeded];
                }
            }
        }
    });
}

- (void)fullImageDidFail:(NSNotification *)notification {
    CVComicRecord *comicRecord = notification.userInfo[@"comicRecord"];
    NSString *UUID = notification.userInfo[@"UUID"];
    
    comicRecord.failedFull = YES;
    dispatch_async(dispatch_get_main_queue(), ^{
        for (NSIndexPath *indexPath in [self.tableView indexPathsForVisibleRows]) {
            CVFullImageTableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexPath];
            if (cell) {
                if ([cell.UUID isEqualToString:UUID]) {
                    cell.text.text = @"Tap to Reload";
                    [cell.loaderGear stopAnimating];
                    [cell setComicFullImage:nil];
                }
            }
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
    CVComicRecord *comicRecord = self.comicRecords[indexPath.row];
    [cell.loaderGear stopAnimating];
    [cell.text setText:comicRecord.title];
    NSString *UUID = comicRecord.fullImagePageURL.absoluteString;
    [cell setUUID:UUID];
    //Check if image is in the cache
    UIImage *fullImage = [self.contentViewCache objectForKey:UUID];
    [cell setComicFullImage:fullImage];
    
    [self requestImageAroundIndexpath:indexPath];
    
    if (fullImage) {
        return cell;
    }
    
    
    [cell.loaderGear startAnimating];
    
    [self requestImageForIndexPath:indexPath];
    [self requestImageAroundIndexpath:indexPath];
    
    return cell;
}

/**
 calls requestImageForIndexPath: for indexpaths that is one row up and one row down from the given indexpath but only if the row is within bounds of the comicRecords array.
 */
- (void)requestImageAroundIndexpath:(NSIndexPath *)indexPath {
    NSInteger limit = self.contentViewCache.countLimit/2;
    //try to load front and back
    NSInteger back = indexPath.row + 1;
    for (; back < indexPath.row + limit; back++) {
        if (back >= 0 && back < self.comicRecords.count) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:back inSection:0];
            [self requestImageForIndexPath:ip];
        }
    }
    
    NSInteger front = indexPath.row -1;
    for (;front > indexPath.row - limit; front--) {
        if (front >= 0 && front < self.comicRecords.count) {
            NSIndexPath *ip = [NSIndexPath indexPathForRow:front inSection:0];
            [self requestImageForIndexPath:ip];
        }
    }
}

/**
 loads the operation that will download the image for the given indexpath
 */
- (void)requestImageForIndexPath:(NSIndexPath *)indexPath {
    //NSLog(@"indexpath %@", indexPath);
    CVComicRecord *comicRecord = self.comicRecords[indexPath.row];
    NSString *UUID = comicRecord.fullImagePageURL.absoluteString;
    
    if ([self.contentViewCache objectForKey:UUID]) {
        //if it is already cached, I do not need to make a request.
        return;
    }
    [[[CVPendingOperations sharedInstance] fullQueueLock] lock];
    id fd = CVPendingOperations.sharedInstance.fullDownloadersInProgress[UUID];
    [[[CVPendingOperations sharedInstance] fullQueueLock] unlock];
    if (fd) {
        //if it is in the queue you do no need to make a request
        return;
    }
    
    comicRecord.failedFull = NO;
    CVFullImageDownloader *downloader = [[CVFullImageDownloader alloc] initWithComicRecord:comicRecord withUUID:UUID];
    [CVPendingOperations.sharedInstance.fullDownloaderOperationQueue addOperation:downloader];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    CVComicRecord *comicRecord = self.comicRecords[indexPath.row];
    if (comicRecord.failedFull) {
        [tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        //[self requestImageForIndexPath:indexPath];
    }
}

- (void)hideNavigationbar:(BOOL)b animationDuration:(NSTimeInterval)animationDuration {
    __block BOOL isAnimating = NO;
    if (isAnimating) {
        return;
    }
   
    isAnimating = YES;
    if (self.navigationController.navigationBar.alpha != b) {
        return;
    }
    [UIView animateWithDuration:animationDuration animations:^{
        [self.navigationController.navigationBar setAlpha:!b];
    } completion:^(BOOL finished) {
        isAnimating = NO;
    }];
}

#pragma mark - Scroll

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
        [self setCurrentPage:[self currentlyViewedComicIndexPath].row];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self prioritizeVisisbleCells];
    [self setCurrentPage:[self currentlyViewedComicIndexPath].row];
}

- (void)prioritizeVisisbleCells {
    NSArray *ips = [self.tableView indexPathsForVisibleRows];
    [[[CVPendingOperations sharedInstance] fullQueueLock] lock];
    NSArray *activeIndexPaths = [CVPendingOperations.sharedInstance.fullDownloadersInProgress allKeys];
    [[[CVPendingOperations sharedInstance] fullQueueLock] unlock];
    //add visible cells to queue first
    NSSet *visible = [NSSet setWithArray:ips];
    NSMutableSet *invisible = [NSMutableSet setWithArray:activeIndexPaths];
    [invisible minusSet:visible];
    
    for (NSIndexPath *ip in invisible) {
        [[[CVPendingOperations sharedInstance] fullQueueLock] lock];
        NSOperation *op = CVPendingOperations.sharedInstance.fullDownloadersInProgress[ip];
        [[[CVPendingOperations sharedInstance] fullQueueLock] unlock];
        [op setQueuePriority:NSOperationQueuePriorityNormal];
    }
    
    for (NSIndexPath *ip in visible) {
        [[[CVPendingOperations sharedInstance] fullQueueLock] lock];
        NSOperation *op = CVPendingOperations.sharedInstance.fullDownloadersInProgress[ip];
        [[[CVPendingOperations sharedInstance] fullQueueLock] unlock];
        [op setQueuePriority:NSOperationQueuePriorityHigh];
    }
}

#pragma mark - reload after tableview loads 


- (void)goToSelectedIndexPath:(id)sender {
    NSIndexPath *indexPath = self.indexpath;
    //NSLog(@"gotoselectdindexpath %@", indexPath);
    [self.tableView scrollToRowAtIndexPath:indexPath
                          atScrollPosition:UITableViewScrollPositionTop
                                  animated:NO];
    //[self.tableView scrollToRowAtIndexPath:indexPath
    //                    atScrollPosition:UITableViewScrollPositionTop
    //                            animated:NO];
    //[self.tableView reloadData];//Reloading data seems to help it scroll to the correct position
    //[self.tableView layoutIfNeeded];
    [self hideNavigationbar:NO animationDuration:0.2];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    self.indexpath = [self currentlyViewedComicIndexPath];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    [self goToSelectedIndexPath:self];
    [self setCurrentPage:self.indexpath.row];
}

- (NSIndexPath *)currentlyViewedComicIndexPath {
    NSIndexPath *chosenIndexpath;
    NSArray *visibleIndexPaths = [self.tableView indexPathsForVisibleRows];
    chosenIndexpath = visibleIndexPaths.firstObject;
    float center_y = self.tableView.contentOffset.y + self.tableView.frame.size.height/2;
    
    for (NSIndexPath *ip in visibleIndexPaths) {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:ip];
        if (cell) {
            int top = CGRectGetMinY(cell.frame);
            int bot = CGRectGetMaxY(cell.frame);
            // NSLog(@"%d ... %d ||  %f", top, bot, center_y);
            if (top <= center_y && center_y <= bot) {
                chosenIndexpath = ip;
                break;
            }
        }
    }
    return chosenIndexpath;
}

- (void)setCurrentPage:(NSInteger)page {
    [[NSUserDefaults standardUserDefaults] setObject:@(page) forKey:@"lastPageSeen"];
}
@end
