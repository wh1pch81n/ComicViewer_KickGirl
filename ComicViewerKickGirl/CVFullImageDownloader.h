//
//  CVFullImageDownloader.h
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 Subscrib to this notification to be notified that the full image has been downloaded
 nsnotification object contains a NSDictionary called userInfos it contains these key:value pares...
 
 comicRecord:_instanceOfComicRecord_
 indexPath:_indexPathOfGivenContainer_
 */
extern NSString *const kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION;

/**
 Subscrib to this notification to be notified that the full image has failed
 nsnotification object contains a NSDictionary called userInfos it contains these key:value pares...
 
 comicRecord:_instanceOfComicRecord_
 indexPath:_indexPathOfGivenContainer_
 */
extern NSString *const kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION;

@class CVComicRecord;
@interface CVFullImageDownloader : NSOperation <NSXMLParserDelegate>

/**
 It will use the comic record to access the fullimagepageurl and the fullimageurl
 The indexpath is the indexpath of whatever external container class uses it e.g. an array of CVComicRecord's
 */
- (id)initWithComicRecord:(CVComicRecord *)comicRecord withUUID:(NSString *)UUID;

@end
