//
//  CVThumbnailImageDownloader.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVThumbnailImageDownloader.h"
#import "CVComicRecord.h"
#import "CVPendingOperations.h"

#pragma mark - notification constants
NSString *const kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_NOTIFICATION = @"kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_NOTIFICATION";
NSString *const kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_FAILED_NOTIFICATION = @"kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_FAILED_NOTIFICATION";

#pragma mark - constants
static NSString *const kComicRecord = @"comicRecord";
static NSString *const kUUID = @"UUID";
static NSString *const kThumbnailImage = @"thumbnailImage";

@interface CVThumbnailImageDownloader ()

@property (nonatomic, strong, readonly) CVComicRecord *comicRecord;
@property (nonatomic, strong) NSString *UUID;
@property (nonatomic, strong) UIImage *thumbImage;

@end

@implementation CVThumbnailImageDownloader

-(id)initWithComicRecord:(CVComicRecord *)comicRecord withUUID:(NSString *)UUID {
    if (self = [super init]) {
        _comicRecord = comicRecord;
        _UUID = UUID;
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        if ([CVPendingOperations sharedInstance].reachabilityObserver.isNetworkReachable == NO) {
            [self failedOperation];
            return;
        }
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
    NSMutableDictionary *d = [NSMutableDictionary new];
    [d setValue:self.comicRecord forKey:kComicRecord];
    [d setValue:self.UUID forKey:kUUID];

    [[NSNotificationCenter defaultCenter] postNotificationName:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_FAILED_NOTIFICATION object:self userInfo:d];
}

- (void)succesfulOperation {
    NSDictionary *d = @{kComicRecord:self.comicRecord,
                        kUUID:self.UUID,
                        kThumbnailImage:self.thumbImage
                        };
    [[NSNotificationCenter defaultCenter] postNotificationName:kCOMIC_VIEWER_THUMBNAIL_DOWNLOADER_NOTIFICATION object:self userInfo:d];
}

- (void)start {
    [[CVPendingOperations sharedInstance].thumbnailQueueLock lock];
    [CVPendingOperations sharedInstance].thumbnailDownloadersInProgress[self.UUID] = self;
    [[CVPendingOperations sharedInstance].thumbnailQueueLock unlock];
    [self addObserver:self
           forKeyPath:NSStringFromSelector(@selector(isFinished))
              options:NSKeyValueObservingOptionNew
              context:nil];
    [super start];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(isFinished))]) {
        [[[CVPendingOperations sharedInstance] thumbnailQueueLock] lock];
        [[CVPendingOperations sharedInstance].thumbnailDownloadersInProgress removeObjectForKey:self.UUID];
        [[[CVPendingOperations sharedInstance] thumbnailQueueLock] unlock];
        [self removeObserver:self
                  forKeyPath:keyPath
                     context:nil];
    }
}



@end
