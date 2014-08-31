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

@interface CVViewController ()

@property (nonatomic, strong) CVPendingOperations *pendingOperations;

@property (nonatomic, strong) NSArray *comicRecords;
@property (weak, nonatomic) IBOutlet UIImageView *image;

@property (assign, nonatomic) BOOL canRemoveThumbQueueNotificationWhenDealloc;
@property (assign, nonatomic) BOOL canRemoveFullQueueNotificationWhenDealloc;
@end

@implementation CVViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(archiveFinishedDownloading:) name:kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOADER_NOTIFICATION object:nil];
    CVArchiveXMLDownloader *archiveOperation = [[CVArchiveXMLDownloader alloc] init];
    
    [self.pendingOperations.archiveXMLDownloaderOperationQueue addOperation:archiveOperation];
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOADER_NOTIFICATION object:nil];
    if (self.canRemoveFullQueueNotificationWhenDealloc) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION object:nil];
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (CVPendingOperations *)pendingOperations {
    return _pendingOperations?:(_pendingOperations = [CVPendingOperations new]);
}

#pragma mark - kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOADER_NOTIFICATION

- (void)archiveFinishedDownloading:(NSNotification *)notification {
    //NSLog(@"%@", notification.userInfo);
    self.comicRecords = notification.userInfo[@"comicRecords"];
    
    self.canRemoveFullQueueNotificationWhenDealloc = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullImageDownloaded:) name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullImageDownloadFailed:) name:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION object:nil];
    
    NSIndexPath *ip = [NSIndexPath indexPathForRow:arc4random_uniform(self.comicRecords.count)
                                         inSection:0];
    CVComicRecord *comicRecord = self.comicRecords[ip.row];
    CVFullImageDownloader *downloader = [[CVFullImageDownloader alloc] initWithComicRecord:comicRecord withIndexPath:ip];
    self.pendingOperations.fullDownloadersInProgress[ip] = downloader;
    [self.pendingOperations.fullDownloaderOperationQueue addOperation:downloader];
    
//    self.canRemoveThumbQueueNotificationWhenDealloc = YES;
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailImageDownloaded:) name:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_NOTIFICATION object:nil];
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailImageDownloadFailed:) name:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_FAILED_NOTIFICATION object:nil];
//    
//    NSIndexPath *ip = [NSIndexPath indexPathForRow:arc4random_uniform(self.comicRecords.count)
//                                         inSection:0];
//    CVComicRecord *comicRecord = self.comicRecords[ip.row];
//    CVThumbnailImageDownloader *downloader = [[CVThumbnailImageDownloader alloc] initWithComicRecord:comicRecord withIndexPath:ip];
//    self.pendingOperations.thumbnailDownloadersInProgress[ip] = downloader;
//    [self.pendingOperations.thumbnailDownloaderOperationQueue addOperation:downloader];
}

- (void)fullImageDownloaded:(NSNotification *)notification {
    CVComicRecord *comicRecord = notification.userInfo[@"comicRecord"];
    dispatch_async(dispatch_get_main_queue(), ^{
        ((UIImageView *)self.image).image = comicRecord.fullImage;
    });
   
    [self.pendingOperations.fullDownloadersInProgress removeObjectForKey:notification.userInfo[@"indexPath"]];
}

- (void)fullImageDownloadFailed:(NSNotification *)notification {
    [[[UIAlertView alloc] initWithTitle:@"oops" message:@"try again later" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] show];
}

- (void)thumbnailImageDownloaded:(NSNotification *)notification {
    CVComicRecord *comicRecord = notification.userInfo[@"comicRecord"];
    dispatch_async(dispatch_get_main_queue(), ^{
        ((UIImageView *)self.image).image = comicRecord.thumbnailImage;
    });
    [self.pendingOperations.thumbnailDownloadersInProgress removeObjectForKey:notification.userInfo[@"indexPath"]];
}

- (void)thumbnailImageDownloadFailed:(NSNotification *)notification {
    [[[UIAlertView alloc] initWithTitle:@"oops" message:@"try again later" delegate:nil cancelButtonTitle:nil otherButtonTitles:nil] show];
}

@end
