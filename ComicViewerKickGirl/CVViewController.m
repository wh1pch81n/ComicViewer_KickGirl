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
    
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
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

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - notifications


- (void)fullImageDidFinishDownloading:(NSNotification *)notification {
    CVComicRecord *comicRecord = notification.userInfo[@"comicRecord"];
    NSIndexPath *indexpath = notification.userInfo[@"indexPath"];
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
    
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 150;
    //return self.view.frame.size.height;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    CVFullImageTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    CVComicRecord *comicRecord = self.comicRecords[indexPath.row];
    CVFullImageDownloader *downloader = [[CVFullImageDownloader alloc] initWithComicRecord:comicRecord withIndexPath:indexPath];
    self.pendingOperations.fullDownloadersInProgress[indexPath] = downloader;
    [self.pendingOperations.fullDownloaderOperationQueue addOperation:downloader];
    
    return cell;
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


@end
