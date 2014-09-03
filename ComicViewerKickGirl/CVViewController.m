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
#import "CVContentViewController.h"
#import "CVFullImageTableViewCell.h"

@interface CVViewController ()
//@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (assign, nonatomic) BOOL canRemoveFullQueueNotificationWhenDealloc;
@property (strong, nonatomic) NSCache *contentViewCache;
@property (strong, nonatomic) CVContentViewController *currentContentViewController;
@end

@implementation CVViewController

- (NSCache *)contentViewCache{
    if (_contentViewCache) {
        return _contentViewCache;
    }
    _contentViewCache = [NSCache new];
    _contentViewCache.countLimit = 5;
    
    return _contentViewCache;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
    self.edgesForExtendedLayout = UIRectEdgeNone;
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
    CVComicRecord *comicRecord = notification.userInfo[@"comicRecord"];
    NSIndexPath *indexpath = notification.userInfo[@"indexPath"];
    [self.contentViewCache setObject:comicRecord.fullImage forKey:indexpath];
    dispatch_async(dispatch_get_main_queue(), ^{
        CVFullImageTableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexpath];
        if (cell) {
            [cell setComicFullImage:comicRecord.fullImage];
        }
    });
    [self.pendingOperations.fullDownloadersInProgress removeObjectForKey:indexpath];
}

- (void)fullImageDidFail:(NSNotification *)notification {
    [[[UIAlertView alloc] initWithTitle:@"oops" message:@"try again later" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] show];
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
    
    //save the current row we are on
    if (cell) {
        [[NSUserDefaults standardUserDefaults] setObject:@(indexPath.row) forKey:@"lastPageSeen"];
    }
    
    //Check if image is in the cache
    UIImage *fullImage = [self.contentViewCache objectForKey:indexPath];
    if (fullImage) {
        [cell setComicFullImage:fullImage];
        [self requestImageAroundIndexpath:indexPath];
        return cell;
    }
    [cell clearContentView];
    
    UIActivityIndicatorView *view = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    [view startAnimating];
    [cell.contentView addSubview:view];
    
    [self requestImageForIndexPath:indexPath];
    [self requestImageAroundIndexpath:indexPath];
    
    return cell;
}

/**
 calls requestImageForIndexPath: for indexpaths that is one row up and one row down from the given indexpath but only if the row is within bounds of the comicRecords array.
 */
- (void)requestImageAroundIndexpath:(NSIndexPath *)indexPath {
    //try to load front and back
    NSInteger front = indexPath.row -1;
    NSInteger back = indexPath.row + 1;
    if (front >= 0 && front < self.comicRecords.count) {
        [self requestImageForIndexPath:[NSIndexPath indexPathForRow:front inSection:0]];
    }
    if (back >= 0 && back < self.comicRecords.count) {
        [self requestImageForIndexPath:[NSIndexPath indexPathForRow:back inSection:0]];
    }
}

/**
 loads the operation that will download the image for the given indexpath
 */
- (void)requestImageForIndexPath:(NSIndexPath *)indexPath {
    //if it is already cached, I do not need to make a request.
    if ([self.contentViewCache objectForKey:indexPath]) {
        return;
    }
    //if it is in the queue you do no need to make a request
    if (self.pendingOperations.fullDownloadersInProgress[indexPath]) {
        return;
    }
    
    CVComicRecord *comicRecord = self.comicRecords[indexPath.row];
    CVFullImageDownloader *downloader = [[CVFullImageDownloader alloc] initWithComicRecord:comicRecord withIndexPath:indexPath];
    self.pendingOperations.fullDownloadersInProgress[indexPath] = downloader;
    [self.pendingOperations.fullDownloaderOperationQueue addOperation:downloader];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"Selected Row");
}

//#pragma mark - UIScrollView Delegate
//
//- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
//    return self.comicImageView;
//}
//
//- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
//    //    NSLog(@"%@", scrollView);
//    //    NSLog(@"%@", view);
//    //    NSLog(@"%f", scale);
//    //
//    //
//}
//
//- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
//    static int const kPagePullTolerance = 50;
//    NSInteger dy = scrollView.contentOffset.y; //positive y means it is above the screen.  negative means below.
//    NSInteger scrollViewHeight = scrollView.frame.size.height;
//    NSInteger contentSizeHeight = scrollView.contentSize.height;
//    NSLog(@"%ld", dy);
//    if (dy <  -kPagePullTolerance) { //scrolls beyond top
//        NSLog(@"scrolls beyond top");
//        [[UIApplication sharedApplication] sendAction:@selector(goToPreviousPage:)
//                                                   to:nil from:nil forEvent:nil];
//    }
//    else if (dy > contentSizeHeight + kPagePullTolerance - scrollViewHeight) { //scrolls beyond bottom
//        NSLog(@"scrolls beyond bottom");
//        [[UIApplication sharedApplication] sendAction:@selector(goToNextPage:)
//                                                   to:nil from:nil forEvent:nil];
//    }
//}
//
//- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
//    NSLog(@"%@", self.view);
//    CGSize newImgSize = [self size:self.comicImageView.frame.size
//        thatFitsWidthProportinally:self.view.frame.size.width];
//    [self.comicImageView setFrame:CGRectMake(0, 0, newImgSize.width, newImgSize.height)];
//
//    //set the content size
//    [self.scrollView setContentSize:self.comicImageView.frame.size];
//    [self.scrollView setMaximumZoomScale:5];
//    [self.scrollView setMinimumZoomScale:1];
//    [self.scrollView setContentOffset:CGPointMake(0, 2)];
//}



#pragma mark - reload after tableview loads 


- (void)goToSelectedIndexPath:(id)sender {
    NSLog(@"%@", self.indexpath);
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
    //[self goToSelectedIndexPath:self];
    NSLog(@"%@", self.indexpath);
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"%@", self.indexpath);
    [self goToSelectedIndexPath:self];
}

@end
