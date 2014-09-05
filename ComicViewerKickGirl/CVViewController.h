//
//  CVViewController.h
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <iAd/iAd.h>

@class CVPendingOperations;
@interface CVViewController : UITableViewController

@property (strong, nonatomic) NSArray *comicRecords;
@property (strong, nonatomic) NSIndexPath *indexpath;

@end
