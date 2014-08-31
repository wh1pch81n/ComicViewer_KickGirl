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

@end

@implementation CVKickGirlTableViewController

- (NSArray *)comicRecords {
    if (_comicRecords) {
        return _comicRecords;
    }
    _comicRecords = [NSArray new];
    return _comicRecords;
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
    CVArchiveXMLDownloader *downloader = [[CVArchiveXMLDownloader alloc] init];
    //NSIndexPath *ip = [NSIndexPath indexPathForRow:0 inSection:0];
    //self.pendingOperations.archiveXMLDownloadersInProgress[ip] = downloader;
    [self.pendingOperations.archiveXMLDownloaderOperationQueue addOperation:downloader];
    
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
    if ((cell.imageView.image = comicRecord.thumbnailImage) == nil) {
        CVThumbnailImageDownloader *downloader = [[CVThumbnailImageDownloader alloc] initWithComicRecord:comicRecord withIndexPath:indexPath];
        self.pendingOperations.thumbnailDownloadersInProgress[indexPath] = downloader;
        [self.pendingOperations.thumbnailDownloaderOperationQueue addOperation:downloader];
    }
}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/


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
    NSMutableArray *reverseArray = [NSMutableArray new];
    NSArray *comicRecords = [NSMutableArray arrayWithArray:notification.userInfo[@"comicRecords"]];
    for (id element in [comicRecords reverseObjectEnumerator]) {
        [reverseArray addObject:element];
    }
    self.comicRecords = reverseArray;
    
    //[self.pendingOperations.archiveXMLDownloadersInProgress removeObjectForKey:notification.userInfo[@"indexPath"]];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.tableView reloadData];
    });
}

- (void)archiveDidFail:(NSNotification *)notification {
#warning implement error later
}

- (void)thumbnailDidFinishDownloading:(NSNotification *)notification {
    NSDictionary *userinfo = notification.userInfo;
    NSIndexPath *indexpath = userinfo[@"indexPath"];
    CVComicRecord *comicRecord = userinfo[@"comicRecord"];
    
    [self.pendingOperations.thumbnailDownloadersInProgress removeObjectForKey:indexpath];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        UITableViewCell *cell = (id)[self.tableView cellForRowAtIndexPath:indexpath];
        if (cell) {
            cell.imageView.image = comicRecord.thumbnailImage;
            [self.tableView reloadRowsAtIndexPaths:@[indexpath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    });
}

- (void)thumbnailDidFail:(NSNotification *)notification {
#warning implement error later
}

@end
