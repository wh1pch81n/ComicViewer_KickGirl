//
//  CVFullImageDownloader.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVFullImageDownloader.h"
#import "CVComicRecord.h"

#pragma mark - notification constants
NSString *const kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION = @"kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION";
NSString *const kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION = @"kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION";

#pragma mark - constants
static NSString *const kComicRecord = @"comicRecord";
static NSString *const kIndexPath = @"indexPath";

@interface CVFullImageDownloader ()

@property (strong, nonatomic) CVComicRecord *comicRecord;
@property (strong, nonatomic) NSIndexPath *indexPath;

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
        NSError *err;
        NSString *text = [NSString stringWithContentsOfURL:self.comicRecord.fullImagePageURL encoding:NSUTF8StringEncoding error:&err];
        if (self.isCancelled || err) {
            [self failedOperation];
            return;
        }
        text = [self cleanText:text];
        // NSLog(@"%@", text);
        NSData *textData = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithData:textData];
        xmlparser.delegate = self;
        [xmlparser parse];
        if (self.isCancelled) {
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
        if (self.isCancelled) {
            [self failedOperation];
            return;
        }
        self.comicRecord.fullImage = img;
        
        [self completedOperation];
    }
}

- (void)failedOperation {
    [[NSNotificationCenter defaultCenter] postNotificationName:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_FAILED_NOTIFICATION
                                                        object:self
                                                      userInfo:@{
                                                                 kComicRecord: self.comicRecord,
                                                                 kIndexPath: self.indexPath
                                                                 }];
}


- (void)completedOperation {
    [[NSNotificationCenter defaultCenter] postNotificationName:kCOMIC_VIEWER_FULLIMAGE_DOWNLOADER_NOTIFICATION
                                                        object:self
                                                      userInfo:@{
                                                                 kComicRecord: self.comicRecord,
                                                                 kIndexPath: self.indexPath
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


@end
