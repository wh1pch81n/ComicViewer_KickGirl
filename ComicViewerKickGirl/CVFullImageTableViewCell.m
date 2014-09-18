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
        [self.contentView addSubview:self.comicImageView];
    }
    self.comicImageView.image = img;
    if (img) {
        //[self layoutImageToMatchCell];
        [self.comicImageView sizeToFit];
        self.comicImageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height);
        [self.comicImageView setContentMode:UIViewContentModeScaleAspectFit];
    }
    [self.contentView bringSubviewToFront:self.text];
}

- (CGSize)size:(CGSize)size thatFitsWidthProportinally:(NSInteger)width {
    float scale = width/size.width ;
    return CGSizeMake(size.width * scale, size.height * scale);
}

- (void)layoutImageToMatchCell {
    //resize view to be same dimensions as the image
    [self.comicImageView sizeToFit];
    
    //shrink the image proportionally
    CGSize newImgSize = [self size:self.comicImageView.frame.size
        thatFitsWidthProportinally:self.frame.size.width];
    [self.comicImageView setFrame:CGRectMake(0, 0, newImgSize.width, newImgSize.height)];
}

@end
