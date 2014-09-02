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

@interface CVViewController ()
@property (strong, nonatomic) UIPageViewController *pageViewController;
@property (assign, nonatomic) BOOL canRemoveFullQueueNotificationWhenDealloc;
@property (strong, nonatomic) NSCache *contentViewCache;
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
    {//hide navigation bar
     // self.navigationController.navigationBarHidden = YES;
    }
    { //create page view controller
        self.pageViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageViewController"];
        self.pageViewController.dataSource = self;
        
        CVContentViewController *startingViewController = [self viewControllerAtIndexpath:self.indexpath];
        [self.pageViewController setViewControllers:@[startingViewController]
                                          direction:UIPageViewControllerNavigationDirectionForward
                                           animated:NO completion:nil];
        
        {//Change the size of the page view controller
         //self.pageViewController.view.frame = CGRectMake(0, 0, CGRectGetWidth(self.view.frame), CGRectGetHeight(self.view.frame)-50);
         //left constraint
//            [NSLayoutConstraint constraintWithItem:self.pageViewController.view
//                                         attribute:NSLayoutAttributeLeading
//                                         relatedBy:NSLayoutRelationEqual
//                                            toItem:self.view
//                                         attribute:NSLayoutAttributeLeft
//                                        multiplier:1 constant:0];
//            
//            //right constraint
//            [NSLayoutConstraint constraintWithItem:self.pageViewController.view
//                                         attribute:NSLayoutAttributeTrailing
//                                         relatedBy:NSLayoutRelationEqual
//                                            toItem:self.view
//                                         attribute:NSLayoutAttributeRight
//                                        multiplier:1 constant:0];
//            //top constraint
//            [NSLayoutConstraint constraintWithItem:self.pageViewController.view
//                                         attribute:NSLayoutAttributeTop
//                                         relatedBy:NSLayoutRelationEqual
//                                            toItem:self.view
//                                         attribute:NSLayoutAttributeTop
//                                        multiplier:1 constant:0];
//            //bottom constraint
//            [NSLayoutConstraint constraintWithItem:self.pageViewController.view
//                                         attribute:NSLayoutAttributeBottom
//                                         relatedBy:NSLayoutRelationEqual
//                                            toItem:self.view
//                                         attribute:NSLayoutAttributeBottom
//                                        multiplier:1 constant:75];
//            [self.view layoutIfNeeded];
        }
        [self addChildViewController:_pageViewController];
        [self.view addSubview:_pageViewController.view];
        [self.pageViewController didMoveToParentViewController:self];
    }
    // self.canDisplayBannerAds = YES;
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
    CVContentViewController *contentViewController = [self.contentViewCache objectForKey:indexpath];
    dispatch_async(dispatch_get_main_queue(), ^{
        contentViewController.comicImageView.image = comicRecord.fullImage;
    });
    
    [self.pendingOperations.fullDownloadersInProgress removeObjectForKey:indexpath];
}

- (void)fullImageDidFail:(NSNotification *)notification {
    [[[UIAlertView alloc] initWithTitle:@"oops" message:@"try again later" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] show];
}

#pragma mark - UIPageViewControllerDataSource Protocol

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(CVContentViewController *)contentViewController {
    NSUInteger index = contentViewController.pageIndex;
    if (index == self.comicRecords.count -1 || (index == NSNotFound)) {
        return nil;
    }
    index++;
    return [self viewControllerAtIndexpath:[NSIndexPath indexPathForRow:index inSection:0]];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(CVContentViewController *)contentViewController {
    NSUInteger index = contentViewController.pageIndex;
    if ((index == 0) || (index == NSNotFound)) {
        return nil;
    }
    index--;
    return [self viewControllerAtIndexpath:[NSIndexPath indexPathForRow:index inSection:0]];
}

- (CVContentViewController *)viewControllerAtIndexpath:(NSIndexPath *)index {
    if (([self.comicRecords count] == 0) || (index.row >= [self.comicRecords count])) {
        return nil;
    }
    
    CVContentViewController *contentViewController;
    if ((contentViewController = [self.contentViewCache objectForKey:index])) {
        return contentViewController;
    }
    
    //Create a new view controller and pass suitable data
    contentViewController = [self.storyboard instantiateViewControllerWithIdentifier:@"PageContentViewController"];
    //contentViewController.imageFile = self.pageImages[index];
    
    //add this instance of the contentViewController to the cache so you can reference it later.
    [self.contentViewCache setObject:contentViewController forKey:index];
    
    contentViewController.pageIndex = index.row;
    
    CVComicRecord *comicRecord = self.comicRecords[index.row];
    if (comicRecord.fullImage) {
        dispatch_async(dispatch_get_main_queue(), ^{
            contentViewController.comicImageView.image = comicRecord.fullImage;
        });
    } else {
        CVFullImageDownloader *downloader = [[CVFullImageDownloader alloc] initWithComicRecord:comicRecord withIndexPath:index];
        self.pendingOperations.fullDownloadersInProgress[index] = downloader;
        [self.pendingOperations.fullDownloaderOperationQueue addOperation:downloader];
    }
    return contentViewController;
}





@end
