//
//  CVContentViewController.h
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CVContentViewController : UIViewController <UIScrollViewDelegate>

@property (assign, nonatomic) NSInteger pageIndex;

- (void)setComicImage:(UIImage *)img;
@end
