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
#import "RKReachabilityObserver.h"

@interface CVKickGirlTableViewController ()

@property (strong, nonatomic) NSArray *comicRecords;
@property (weak, nonatomic) NSCache *thumbnailImageCache;

@property (strong, nonatomic) NSURL *actionMessageURL;

@end

@implementation CVKickGirlTableViewController

- (NSCache *)thumbnailImageCache {
    return CVPendingOperations.sharedInstance.thumbnailDownloaderCache;
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
    { //add notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(archiveDidFinishDownloading:) name:kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOADER_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(archiveDidFail:) name:kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOAD_FAILED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailDidFinishDownloading:) name:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_NOTIFICATION object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(thumbnailDidFail:) name:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_FAILED_NOTIFICATION object:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(internetListener:) name:RKReachabilityDidChangeNotification object:nil];
    }
    
    [self reloadArchive:self];
    
    {//setup navigation bar
        UIBarButtonItem *reload = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(reloadArchive:)];
        [self.navigationItem setRightBarButtonItem:reload];
        
        [self.navigationItem setTitle:@"Kick Girl"];
        
        UIBarButtonItem *source = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(goToKickGirlWebsite:)];
        [self.navigationItem setLeftBarButtonItem:source];
    }
    [self fetchSpecialMessage];
}

- (IBAction)goToKickGirlWebsite:(id)sender {
    NSURL *url = [NSURL URLWithString:@"http://www.kick-girl.com"];
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)reloadArchive:(id)sender {
    CVArchiveXMLDownloader *downloader = [[CVArchiveXMLDownloader alloc] init];
    [CVPendingOperations.sharedInstance.archiveXMLDownloaderOperationQueue addOperation:downloader];

}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.navigationController.navigationBar.alpha = 1;
    {//make the view's origin start at behind the navigationbar rather than under it
        self.edgesForExtendedLayout = UIRectEdgeNone;
        self.automaticallyAdjustsScrollViewInsets = YES;
    }
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
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKReachabilityDidChangeNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
 return self.comicRecords.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
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
        if ([CVPendingOperations sharedInstance].thumbnailDownloadersInProgress[indexPath]) {
            //It is already on the queue.
            return;
        }
        CVThumbnailImageDownloader *downloader = [[CVThumbnailImageDownloader alloc] initWithComicRecord:comicRecord withIndexPath:indexPath];
        CVPendingOperations.sharedInstance.thumbnailDownloadersInProgress[indexPath] = downloader;
        [CVPendingOperations.sharedInstance.thumbnailDownloaderOperationQueue addOperation:downloader];
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
}

#pragma mark - notifications

- (void)internetListener:(NSNotification *)notification {
    if (CVPendingOperations.sharedInstance.reachabilityObserver.isNetworkReachable) {
        if (self.comicRecords == nil) { //archive failed to load at least once
            [self reloadArchive:notification];
        }
        [self.tableView reloadData];
    }
}

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
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIAlertView alloc] initWithTitle:@"No Internet Connection" message:@"Unable to load images at this time.  Try again later" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil] show];
    });
}

- (void)thumbnailDidFinishDownloading:(NSNotification *)notification {
    NSDictionary *userinfo = notification.userInfo;
    NSIndexPath *indexpath = userinfo[@"indexPath"];
    //CVComicRecord *comicRecord = userinfo[@"comicRecord"];
    UIImage *thumbnailImage = userinfo[@"thumbnailImage"];
    
    [self.thumbnailImageCache setObject:thumbnailImage forKey:indexpath];
    [CVPendingOperations.sharedInstance.thumbnailDownloadersInProgress removeObjectForKey:indexpath];
    
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
    NSIndexPath *indexpath = userinfo[@"indexPath"];
    CVComicRecord *comicRecord = userinfo[@"comicRecord"];
    comicRecord.failedThumb = YES;
    [CVPendingOperations.sharedInstance.thumbnailDownloadersInProgress removeObjectForKey:indexpath];
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

#pragma mark - Special message

/**
 fetches a special message asynchrounously and displays the message if it hasn't been seen yet
 */
- (void)fetchSpecialMessage {
    static NSString *const urlString = @"https://raw.githubusercontent.com/wh1pch81n/ComicViewer_KickGirl/uialertview/specialmessage";
   
    NSOperationQueue *oq = [NSOperationQueue new];
    [oq addOperationWithBlock:^{
        NSURL *url = [NSURL URLWithString:urlString];
        NSData *data = [NSData dataWithContentsOfURL:url];
        NSError *err;
        NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:data
                                                            options:kNilOptions
                                                              error:&err];
        NSLog(@"%@", dic);
        if (err) {
            return;
        }
        for (NSDictionary *d in dic[@"alerts"]) {
            dic = d;
            NSString *messageDate = dic[@"post_date"];
            NSString *messageTitle = dic[@"title"];
            NSString *messageMessage = dic[@"message"];
            NSString *messageActionURL = dic[@"actionURL"];
            self.actionMessageURL = [NSURL URLWithString:messageActionURL];
            
            //if todays date matches post date
            NSDateFormatter *dateFormatter = NSDateFormatter.new;
            dateFormatter.dateFormat = @"MM.dd.yyyy";
            NSString *todaysDate = [dateFormatter stringFromDate:NSDate.new];
            NSLog(@"%@.....%@", messageDate, todaysDate);
            if ([messageDate isEqualToString:todaysDate] == NO) {
                //if post date doesn't match then don't post message
                continue;
            }
            
            NSString *specialMessageDate = [[NSUserDefaults standardUserDefaults]
                                            objectForKey:@"specialMessageDate"];
            if ([specialMessageDate isEqualToString:messageDate] == NO) {
                [NSUserDefaults.standardUserDefaults setObject:messageDate
                                                        forKey:@"specialMessageDate"];
                //show the thing
                dispatch_async(dispatch_get_main_queue(), ^{
                    UIAlertView *alert =
                    [[UIAlertView alloc] initWithTitle:messageTitle
                                               message:messageMessage
                                              delegate:self
                                     cancelButtonTitle:@"cancel"
                                     otherButtonTitles:@"OK", nil];
                    [alert show];
                });
            }
        }
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == alertView.cancelButtonIndex) {
        return;
    }
    if ([UIApplication.sharedApplication canOpenURL:self.actionMessageURL]) {
        [UIApplication.sharedApplication openURL:self.actionMessageURL];
    }
}

@end
