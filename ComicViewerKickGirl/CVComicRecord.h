//
//  CVComicRecord.h
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CVComicRecord : NSObject

/**
 The title of the Comic page
 */
@property (nonatomic, strong) NSString *title;
/**
 Date that the comic page was posted
 */
@property (nonatomic, strong) NSString *date;
/**
 url to the actual thumbnailimage
 */
@property (nonatomic, strong) NSURL *thumbnailImageURL;
/**
 url to the page that contains the full image
*/
@property (nonatomic, strong) NSURL *fullImagePageURL;
/**
 url to the actuall full image
 */
@property (nonatomic, strong) NSURL *fullImageURL;

@property (assign, nonatomic) BOOL failedThumb;
@property (assign, nonatomic) BOOL failedFull;
@end
