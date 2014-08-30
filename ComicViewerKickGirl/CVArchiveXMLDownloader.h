//
//  CVArchiveXMLDownloader.h
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 subscribe to this notification in order to know when the operation has been completed
 
 Notification will return a userInfo dictionary object with a key:value comicRecords:an_array_of_comicRecord_objects
 */
extern NSString *const kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOADER_NOTIFICATION;

@interface CVArchiveXMLDownloader : NSOperation <NSXMLParserDelegate>

@end

