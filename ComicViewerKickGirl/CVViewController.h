//
//  CVViewController.h
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CVPendingOperations;
@interface CVViewController : UIViewController <UIPageViewControllerDataSource>

@property (strong, nonatomic) NSArray *comicRecords;
@property (strong, nonatomic) CVPendingOperations *pendingOperations;
@property (strong, nonatomic) NSIndexPath *indexpath;

@end
