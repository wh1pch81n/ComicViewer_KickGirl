//
//  CVContentViewController.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVContentViewController.h"

@interface CVContentViewController ()

@property (strong, nonatomic) UIImageView *comicImageView;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;

@end

@implementation CVContentViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)setComicImage:(UIImage *)img {
    if (self.comicImageView == nil) {
        self.comicImageView = [[UIImageView alloc] init];
    }
    self.comicImageView.image = img;

    //resize view to be same dimensions as the image
    [self.comicImageView sizeToFit];
    
    //shrink the image proportionally
    CGSize newImgSize = [self size:self.comicImageView.frame.size
        thatFitsWidthProportinally:self.view.frame.size.width];
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

#pragma mark - UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.comicImageView;
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    static int const kPagePullTolerance = 50;
    NSInteger dy = scrollView.contentOffset.y; //positive y means it is above the screen.  negative means below.
    NSInteger scrollViewHeight = scrollView.frame.size.height;
    NSInteger contentSizeHeight = scrollView.contentSize.height;

    if (dy <  -kPagePullTolerance) { //scrolls beyond top
        NSLog(@"scrolls beyond top");
        [[UIApplication sharedApplication] sendAction:@selector(goToPreviousPage:)
                                                   to:nil from:nil forEvent:nil];
    }
    else if (dy > contentSizeHeight + kPagePullTolerance - scrollViewHeight) { //scrolls beyond bottom
        NSLog(@"scrolls beyond bottom");
        [[UIApplication sharedApplication] sendAction:@selector(goToNextPage:)
                                                   to:nil from:nil forEvent:nil];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
    NSLog(@"%@", self.view);
    CGSize newImgSize = [self size:self.comicImageView.frame.size
        thatFitsWidthProportinally:self.view.frame.size.width];
    [self.comicImageView setFrame:CGRectMake(0, 0, newImgSize.width, newImgSize.height)];
    
    //set the content size
    [self.scrollView setContentSize:self.comicImageView.frame.size];
    [self.scrollView setMaximumZoomScale:5];
    [self.scrollView setMinimumZoomScale:1];
    [self.scrollView setContentOffset:CGPointMake(0, 2)];
}



@end
