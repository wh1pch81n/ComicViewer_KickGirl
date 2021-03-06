//
//  CVFullImageDownloader.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVFullImageDownloader.h"
#import "CVComicRecord.h"
#import "CVPendingOperations.h"

#pragma mark - notification constants
NSString *const kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION = @"kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION";
NSString *const kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION = @"kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION";

#pragma mark - constants
static NSString *const kComicRecord = @"comicRecord";
static NSString *const kIndexPath = @"indexPath";
static NSString *const kFullImage = @"fullImage";

@interface CVFullImageDownloader ()

@property (strong, nonatomic) CVComicRecord *comicRecord;
@property (strong, nonatomic) NSIndexPath *indexPath;
@property (strong, nonatomic) UIImage *fullImage;

@end

@implementation CVFullImageDownloader

- (id)initWithComicRecord:(CVComicRecord *)comicRecord withIndexPath:(NSIndexPath *)indexpath {
    if (self = [super init]) {
        _comicRecord = comicRecord;
        _indexPath = indexpath;
    }
    return self;
}

- (void)main {
    @autoreleasepool {
        if ([CVPendingOperations sharedInstance].reachabilityObserver.isNetworkReachable == NO) {
            [self failedOperation];
            return;
        }
        if (self.comicRecord.fullImageURL == nil){
            NSError *err;
            NSString *text = [NSString stringWithContentsOfURL:self.comicRecord.fullImagePageURL
                                                      encoding:NSUTF8StringEncoding error:&err];
            if (self.isCancelled || err) {
                [self failedOperation];
                return;
            }
            text = [self cleanText:text];
            
            NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
            NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithData:textData];
            xmlparser.delegate = self;
            
            if (self.isCancelled || ([xmlparser parse] == NO)) {
                [self failedOperation];
                return;
            }
        }
        if ([CVPendingOperations sharedInstance].reachabilityObserver.isNetworkReachable == NO) {
            [self failedOperation];
            return;
        }
        //download full images
        NSData *imgData = [NSData dataWithContentsOfURL:self.comicRecord.fullImageURL];
        if (self.isCancelled) {
            [self failedOperation];
            return;
        }
        UIImage *img = [UIImage imageWithData:imgData];
        if (self.isCancelled || !img) {
            [self failedOperation];
            return;
        }
        self.fullImage = img;
        
        [self completedOperation];
    }
}

- (void)failedOperation {
    NSMutableDictionary *d = [NSMutableDictionary new];
    [d setValue:self.comicRecord forKey:kComicRecord];
    [d setValue:self.indexPath forKey:kIndexPath];
    [[NSNotificationCenter defaultCenter] postNotificationName:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION
                                                        object:self
                                                      userInfo:d];
}


- (void)completedOperation {
    [[NSNotificationCenter defaultCenter] postNotificationName:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION
                                                        object:self
                                                      userInfo:@{
                                                                 kComicRecord: self.comicRecord,
                                                                 kIndexPath: self.indexPath,
                                                                 kFullImage: self.fullImage,
                                                                 }];
}

#pragma mark - xmlparser

- (NSString *)cleanText:(NSString *)text {
    NSString *page = text;
    NSString *beginTag = @"<div id=\"comic\">";
    NSString *endTag = @"<div class=\"clear\">";
    NSRange beginRange = [page rangeOfString:beginTag];
    
    page = [page substringWithRange:NSMakeRange(beginRange.location, page.length - beginRange.location)];
    NSRange endRage = [page rangeOfString:endTag];
    page = [page substringWithRange:NSMakeRange(0, endRage.location)];

    return page;
}

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    NSString *src = attributeDict[@"src"];
    if ([elementName isEqualToString:@"img"]) {
        NSURL *imgURL = [NSURL URLWithString:src];
        self.comicRecord.fullImageURL = imgURL;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    [self cancel];
    NSLog(@"%@", parseError);
}

- (void)start {
    [[[CVPendingOperations sharedInstance] fullQueueLock] lock];
    [CVPendingOperations sharedInstance].fullDownloadersInProgress[self.indexPath] = self;
    [[[CVPendingOperations sharedInstance] fullQueueLock] unlock];
    [self addObserver:self
           forKeyPath:NSStringFromSelector(@selector(isFinished))
              options:NSKeyValueObservingOptionNew
              context:nil];
    [super start];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(isFinished))]) {
        [[[CVPendingOperations sharedInstance] fullQueueLock] lock];
        [[CVPendingOperations sharedInstance].fullDownloadersInProgress removeObjectForKey:self.indexPath];
        [[[CVPendingOperations sharedInstance] fullQueueLock] unlock];
        [self removeObserver:self
                  forKeyPath:keyPath
                     context:nil];
    }
}

@end
