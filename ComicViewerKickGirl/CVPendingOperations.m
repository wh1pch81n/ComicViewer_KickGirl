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

- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:RKReachabilityDidChangeNotification object:nil];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self name:RKReachabilityDidChangeNotification object:nil];
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

- (NSLock *)thumbnailQueueLock {
    if (_thumbnailQueueLock) {
        return _thumbnailQueueLock;
    }
    _thumbnailQueueLock = [NSLock new];
    return _thumbnailQueueLock;
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

- (NSLock *)fullQueueLock {
    if (_fullQueueLock) {
        return _fullQueueLock;
    }
    _fullQueueLock = [NSLock new];
    return _fullQueueLock;
}

#pragma mark - RKReachability observer

- (RKReachabilityObserver *)reachabilityObserver{
    if (_reachabilityObserver) {
        return _reachabilityObserver;
    }
    _reachabilityObserver = [RKReachabilityObserver reachabilityObserverForInternet];
    return _reachabilityObserver;
}

- (void)reachabilityChanged:(NSNotification *)notification {
    BOOL online = self.reachabilityObserver.isNetworkReachable;
    
    if (online) {
//        [self.archiveXMLDownloaderOperationQueue
//         setSuspended:NO];
//        [self.thumbnailDownloaderOperationQueue
//         setSuspended:NO];
//        [self.fullDownloaderOperationQueue
//         setSuspended:NO];
    } else {
//        [self.archiveXMLDownloaderOperationQueue
//         setSuspended:YES];
//        [self.thumbnailDownloaderOperationQueue
//         setSuspended:YES];
//        [self.fullDownloaderOperationQueue
//         setSuspended:YES];]
        dispatch_async(dispatch_get_main_queue(), ^{
            [[[UIAlertView alloc] initWithTitle:@"No Internet Connection"
                                        message:@"This Application Requires an Internet connection."
                                       delegate:nil
                              cancelButtonTitle:@"OK"
                              otherButtonTitles:nil]
             show];
        });
    }
}

@end
