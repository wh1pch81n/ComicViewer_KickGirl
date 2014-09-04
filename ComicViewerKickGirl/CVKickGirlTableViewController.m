//
//  CVKickGirlTableViewController.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVKickGirlTableViewController.h"
#import "CVPendingOperations.h"
#import "CVArchiveXMLDownloader.h"
#import "CVThumbnailImageDownloader.h"
#import "CVComicRecord.h"
#import "CVViewController.h"

@interface CVKickGirlTableViewController ()

@property (strong, nonatomic) CVPendingOperations *pendingOperations;
@property (strong, nonatomic) NSArray *comicRecords;
@property (strong, nonatomic) NSCache *thumbnailImageCache;

@end

@implementation CVKickGirlTableViewController

- (NSCache *)thumbnailImageCache {
    if (_thumbnailImageCache) {
        return _thumbnailImageCache;
    }
    _thumbnailImageCache = [NSCache new];
    _thumbnailImageCache.countLimit = 50;
    return _thumbnailImageCache;
}

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
    
    { //add notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(archiveDidFinishDownloading:) name:kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOADER_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(archiveDidFail:) name:kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOAD_FAILED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailDidFinishDownloading:) name:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailDidFail:) name:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_FAILED_NOTIFICATION object:nil];
    }
    
    self.pendingOperations = [CVPendingOperations new];
    
    [self reloadArchive:self];
    
    {//setup navigation bar
        UIBarButtonItem *reload = [[UIBarButtonItem alloc] initWithTitle:@"Reload" style:UIBarButtonItemStylePlain target:self action:@selector(reloadArchive:)];
        [self.navigationItem setRightBarButtonItem:reload];
        
        [self.navigationItem setTitle:@"Kick Girl"];
    }
}

- (IBAction)reloadArchive:(id)sender {
    CVArchiveXMLDownloader *downloader = [[CVArchiveXMLDownloader alloc] init];
    [self.pendingOperations.archiveXMLDownloaderOperationQueue addOperation:downloader];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    if (self.comicRecords) {
        [self.tableView reloadData];
        NSNumber *row = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastPageSeen"];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row.integerValue
                                                    inSection:0];
        if (row.integerValue < 0 || row.integerValue >= self.comicRecords.count) {
            indexPath = [NSIndexPath indexPathForRow:0
                                           inSection:0];
        }
        [self.tableView scrollToRowAtIndexPath:indexPath
                              atScrollPosition:UITableViewScrollPositionTop
                                      animated:NO];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    }
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOADER_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOAD_FAILED_NOTIFICATION object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_FAILED_NOTIFICATION object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_NOTIFICATION object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source
/*
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}
*/

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    
    return self.comicRecords.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    
    // Configure the cell...
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    
    CVComicRecord *comicRecord = self.comicRecords[indexPath.row];
    cell.textLabel.text = comicRecord.title;
    cell.detailTextLabel.text = comicRecord.date;
    
    //if thumb nail results in nil then start downloader for it.

    if ((cell.imageView.image = [self.thumbnailImageCache objectForKey:indexPath]) == nil) {
        if ([tableView isDragging] || [tableView isDecelerating]) {
            //don't load images if scrolling
            return;
        }
        if (self.pendingOperations.thumbnailDownloadersInProgress[indexPath]) {
            //It is already on the queue.
            return;
        }
        CVThumbnailImageDownloader *downloader = [[CVThumbnailImageDownloader alloc] initWithComicRecord:comicRecord withIndexPath:indexPath];
        self.pendingOperations.thumbnailDownloadersInProgress[indexPath] = downloader;
        [self.pendingOperations.thumbnailDownloaderOperationQueue addOperation:downloader];
    }
}

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
    CVViewController *cvc = [segue destinationViewController];
    NSIndexPath *ip = [self.tableView indexPathForSelectedRow];
    cvc.comicRecords = self.comicRecords;
    cvc.indexpath = ip;
    cvc.pendingOperations = self.pendingOperations;
}

#pragma mark - notifications

- (void)archiveDidFinishDownloading:(NSNotification *)notification {
    self.comicRecords = notification.userInfo[@"comicRecords"];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
        NSNumber *row = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastPageSeen"];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:row.integerValue
                                                    inSection:0];
        if (row.integerValue < 0 || row.integerValue >= self.comicRecords.count) {
            indexPath = [NSIndexPath indexPathForRow:0
                                           inSection:0];
        }
        [self.tableView scrollToRowAtIndexPath:indexPath
                    atScrollPosition:UITableViewScrollPositionTop
                            animated:NO];
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionTop];
    });
}

- (void)archiveDidFail:(NSNotification *)notification {
    [[[UIAlertView alloc] initWithTitle:@"No Internet Connection" message:@"Unable to load images at this time.  Try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
}

- (void)thumbnailDidFinishDownloading:(NSNotification *)notification {
    NSDictionary *userinfo = notification.userInfo;
    NSIndexPath *indexpath = userinfo[@"indexPath"];
    //CVComicRecord *comicRecord = userinfo[@"comicRecord"];
    UIImage *thumbnailImage = userinfo[@"thumbnailImage"];
    
    [self.thumbnailImageCache setObject:thumbnailImage forKey:indexpath];
    [self.pendingOperations.thumbnailDownloadersInProgress removeObjectForKey:indexpath];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UITableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexpath];
        if (cell) {
            cell.imageView.image = thumbnailImage;
            BOOL wasSelected = NO;
            if (cell.isSelected) {
                wasSelected = YES;
            }
            [self.tableView reloadRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationNone];
            if (wasSelected) {
                [self.tableView selectRowAtIndexPath:indexpath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    });
}

- (void)thumbnailDidFail:(NSNotification *)notification {
    NSDictionary *userinfo = notification.userInfo;
    //NSIndexPath *indexpath = userinfo[@"indexPath"];
    CVComicRecord *comicRecord = userinfo[@"comicRecord"];
    comicRecord.failedThumb = YES;
}

#pragma mark - UIScrollView Delegate

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    if (decelerate == NO) {
        [self loadImagesForOnscreenCells];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    [self loadImagesForOnscreenCells];
}

- (void)loadImagesForOnscreenCells {
    NSArray *ips = [self.tableView indexPathsForVisibleRows];
    [self.tableView reloadRowsAtIndexPaths:ips withRowAnimation:UITableViewRowAnimationNone];
}

@end
