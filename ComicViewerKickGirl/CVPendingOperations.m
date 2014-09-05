//
//  CVPendingOperations.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVPendingOperations.h"

@implementation CVPendingOperations

+(CVPendingOperations *)sharedInstance {
    static CVPendingOperations *_instance = nil;
    static dispatch_once_t predicate;
    dispatch_once(&predicate, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
}

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

- (NSCache *)thumbnailDownloaderCache {
    if (_thumbnailDownloaderCache) {
        return _thumbnailDownloaderCache;
    }
    _thumbnailDownloaderCache = [NSCache new];
    _thumbnailDownloaderCache.countLimit = 100;
    return _thumbnailDownloaderCache;
}

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

- (NSCache *)fullDownloaderCache {
    if(_fullDownloaderCache) {
        return _fullDownloaderCache;
    }
    _fullDownloaderCache = [NSCache new];
    _fullDownloaderCache.countLimit = 10;
    return _fullDownloaderCache;
}

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
