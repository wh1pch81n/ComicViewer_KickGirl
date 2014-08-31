//
//  CVPendingOperations.h
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CVPendingOperations : NSObject

@property (nonatomic, strong) NSMutableDictionary *archiveXMLDownloadersInProgress;
@property (nonatomic, strong) NSOperationQueue  *archiveXMLDownloaderOperationQueue;

@property (nonatomic, strong) NSMutableDictionary *thumbnailDownloadersInProgress;
@property (nonatomic, strong) NSOperationQueue *thumbnailDownloaderOperationQueue;

@property (nonatomic, strong) NSMutableDictionary *fullDownloadersInProgress;
@property (nonatomic, strong) NSOperationQueue *fullDownloaderOperationQueue;

@end
