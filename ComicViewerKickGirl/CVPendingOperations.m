//
//  CVPendingOperations.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVPendingOperations.h"

@implementation CVPendingOperations

#pragma mark - ARchive
- (NSMutableDictionary *)archiveXMLDownloadersInProgress {
    return _archiveXMLDownloadersInProgress?:(_archiveXMLDownloadersInProgress = [NSMutableDictionary new]);
}

- (NSOperationQueue *)archiveXMLDownloaderOperationQueue {
    if (_archiveXMLDownloaderOperationQueue == nil) {
        _archiveXMLDownloaderOperationQueue = [NSOperationQueue new];
        _archiveXMLDownloaderOperationQueue.name = @"archiveXMLDownloaderOperationQueue";
        // _archiveXMLDownloaderOperationQueue.maxConcurrentOperationCount = 1; //debugging to make it slower
    }
    return _archiveXMLDownloaderOperationQueue;
}

#pragma mark - thumbnail

- (NSMutableDictionary *)thumbnailDownloadersInProgress {
    return _thumbnailDownloadersInProgress?:(_thumbnailDownloadersInProgress = [NSMutableDictionary new]);
}

- (NSOperationQueue *)thumbnailDownloaderOperationQueue {
    if (_thumbnailDownloaderOperationQueue == nil) {
        _thumbnailDownloaderOperationQueue = [NSOperationQueue new];
        _thumbnailDownloaderOperationQueue.name = @"thumbnailDownloaderOperationQueue";
        //_thumbnailDownloaderOperationQueue.maxConcurrentOperationCount = 1; //debugging to make it slower
    }
    return _thumbnailDownloaderOperationQueue;
}

#pragma mark - fullimage

- (NSMutableDictionary *)fullDownloadersInProgress {
    return _fullDownloadersInProgress?:(_fullDownloadersInProgress = [NSMutableDictionary new]);
}

- (NSOperationQueue *)fullDownloaderOperationQueue {
    if (_fullDownloaderOperationQueue == nil) {
        _fullDownloaderOperationQueue = [NSOperationQueue new];
        _fullDownloaderOperationQueue.name = @"archiveXMLDownloaderOperationQueue";
        _fullDownloaderOperationQueue.maxConcurrentOperationCount = 2; //debugging to make it slower
    }
    return _fullDownloaderOperationQueue;
}

@end
