//
//  CVFullImageTableViewCell.h
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 9/3/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CVFullImageTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIActivityIndicatorView *loaderGear;
@property (weak, nonatomic) IBOutlet UILabel *text;

- (void)setComicFullImage:(UIImage *)img;
//- (void)clearContentView;
- (void)layoutImageToMatchCell;

@end
