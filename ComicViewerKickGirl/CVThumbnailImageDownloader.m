//
//  CVThumbnailImageDownloader.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVThumbnailImageDownloader.h"
#import "CVComicRecord.h"

#pragma mark - notification constants
NSString *const kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_NOTIFICATION = @"kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_NOTIFICATION";
NSString *const kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_FAILED_NOTIFICATION = @"kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_FAILED_NOTIFICATION";

#pragma mark - constants
static NSString *const kComicRecord = @"comicRecord";
static NSString *const kIndexPath = @"indexPath";
static NSString *const kThumbnailImage = @"thumbnailImage";

@interface CVThumbnailImageDownloader ()

@property (nonatomic, strong, readonly) CVComicRecord *comicRecord;
@property (nonatomic, strong) NSIndexPath *indexpath;
@property (nonatomic, strong) UIImage *thumbImage;

@end

@implementation CVThumbnailImageDownloader

-(id)initWithComicRecord:(CVComicRecord *)comicRecord withIndexPath:(NSIndexPath *)indexpath {
    if (self = [super init]) {
        _comicRecord = comicRecord;
        _indexpath = indexpath;
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        NSData *imgData = [NSData dataWithContentsOfURL:self.comicRecord.thumbnailImageURL];
        if (self.isCancelled || (imgData == nil)) {
            [self failedOperation];
            return;
        }
        UIImage *img = [[UIImage alloc] initWithData:imgData];
        if (self.isCancelled || (img == nil)) {
            [self failedOperation];
            return;
        }
        
        self.thumbImage = img;
    
        [self succesfulOperation];
    }
}

- (void)failedOperation {
    NSDictionary *d = @{kComicRecord:self.comicRecord,
                        kIndexPath:self.indexpath,
                        kThumbnailImage:self.thumbImage
                        };
    [[NSNotificationCenter defaultCenter] postNotificationName:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_FAILED_NOTIFICATION object:self userInfo:d];
}

- (void)succesfulOperation {
    NSDictionary *d = @{kComicRecord:self.comicRecord,
                        kIndexPath:self.indexpath,
                        kThumbnailImage:self.thumbImage
                        };
    [[NSNotificationCenter defaultCenter] postNotificationName:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_NOTIFICATION object:self userInfo:d];
}

@end
