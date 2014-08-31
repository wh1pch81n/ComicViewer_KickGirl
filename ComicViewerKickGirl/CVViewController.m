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

@interface CVViewController ()

@property (nonatomic, strong) CVPendingOperations *pendingOperations;

@property (nonatomic, strong) NSArray *comicRecords;
@property (weak, nonatomic) IBOutlet UIImageView *image;

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
    NSLog(@"%@", notification.userInfo);
    self.comicRecords = notification.userInfo[@"comicRecords"];
}

@end
