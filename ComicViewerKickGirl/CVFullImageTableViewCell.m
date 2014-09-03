//
//  CVFullImageTableViewCell.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 9/3/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVFullImageTableViewCell.h"

@interface CVFullImageTableViewCell ()

@property (strong, nonatomic) UIImageView *comicImageView;

@end

@implementation CVFullImageTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setComicFullImage:(UIImage *)img {
    if (self.comicImageView == nil) {
        self.comicImageView = [[UIImageView alloc] init];
    }
    self.comicImageView.image = img;
    
    //resize view to be same dimensions as the image
    [self.comicImageView sizeToFit];
    
    //shrink the image proportionally
    CGSize newImgSize = [self size:self.comicImageView.frame.size
        thatFitsWidthProportinally:self.frame.size.width];
    [self.comicImageView setFrame:CGRectMake(0, 0, newImgSize.width, newImgSize.height)];
    
    //remove any preexisting uiimageviews that are inside the uiscrollview
    for (UIView *subview in self.scrollView.subviews) {
        [subview removeFromSuperview];
    }
    
    //add the uiimageview
    [self.scrollView addSubview:self.comicImageView];
    
    //set the content size
    [self.scrollView setContentSize:self.comicImageView.frame.size];
    [self.scrollView setMaximumZoomScale:5];
    [self.scrollView setMinimumZoomScale:1];
    [self.scrollView setContentOffset:CGPointMake(0, 2)];
}

- (CGSize)size:(CGSize)size thatFitsWidthProportinally:(NSInteger)width {
    float scale = width/size.width ;
    return CGSizeMake(size.width * scale, size.height * scale);
}

@end