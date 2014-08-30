//
//  CVPendingOperations.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVPendingOperations.h"

@implementation CVPendingOperations

- (NSMutableDictionary *)archiveXMLDownloadersInProgress {
    return _archiveXMLDownloadersInProgress?:(_archiveXMLDownloadersInProgress = [NSMutableDictionary new]);
}

- (NSOperationQueue *)archiveXMLDownloaderOperationQueue {
    if (_archiveXMLDownloaderOperationQueue == nil) {
        _archiveXMLDownloaderOperationQueue = [NSOperationQueue new];
        _archiveXMLDownloaderOperationQueue.name = @"archiveXMLDownloaderOperationQueue";
        _archiveXMLDownloaderOperationQueue.maxConcurrentOperationCount = 1; //debugging to make it slower
    }
    return _archiveXMLDownloaderOperationQueue;
}
@end
