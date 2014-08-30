//
//  CVComicRecord.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVComicRecord.h"

@implementation CVComicRecord

- (NSString *)description {
    NSString *desc;
    desc = [NSString stringWithFormat:
            @"Title:%@\n"
            "Date:%@\n"
            "ThumbImageURL:%@\n"
            "FullPageURL:%@\n"
            "FullImageURL:%@\n",self.title, self.date, self.thumbnailImageURL, self.fullImagePageURL, self.fullImageURL];

    return desc;
}

@end
