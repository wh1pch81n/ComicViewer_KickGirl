//
//  CVContentViewController.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVContentViewController.h"

@interface CVContentViewController ()
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
    NSLog(@"%@", self.view);
    self.canDisplayBannerAds = YES;
    [self.scrollView setContentSize:self.comicImageView.frame.size];
    [self.scrollView setMaximumZoomScale:5];
    [self.scrollView setMinimumZoomScale:1];
    [self.scrollView setDelegate:self];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/


#pragma mark - touches


- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"Touches ended");
    
    if (self.navigationController.isNavigationBarHidden) {
        self.navigationController.navigationBarHidden = NO;
    } else {
         self.navigationController.navigationBarHidden = YES;
    }
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    NSLog(@"touches canceled");
    self.navigationController.navigationBarHidden = YES;
}

#pragma mark - UIScrollView Delegate

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView {
    return self.comicImageView;
}

//- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(CGFloat)scale {
//    NSLog(@"%@", scrollView);
//    NSLog(@"%@", view);
//    NSLog(@"%f", scale);
//    
//    
//}

@end
