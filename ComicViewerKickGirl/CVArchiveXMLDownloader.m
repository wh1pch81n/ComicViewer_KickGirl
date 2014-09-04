//
//  CVArchiveXMLDownloader.m
//  ComicViewerKickGirl
//
//  Created by Derrick Ho on 8/30/14.
//  Copyright (c) 2014 dnthome. All rights reserved.
//

#import "CVArchiveXMLDownloader.h"
#import "CVComicRecord.h"

NSString *const kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOADER_NOTIFICATION = @"kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOADER_NOTIFICATION";
NSString *const kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOAD_FAILED_NOTIFICATION = @"kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOAD_FAILED_NOTIFICATION";

NSString *const kComicSourceURL = @"http://www.kick-girl.com/?cat=3";
NSString *const kComicThumbnail = @"comicthumbnail";
NSString *const kComicThumbDate = @"comicthumbdate";
NSString *const kComicArray = @"post-content";
NSString *const kComicArrayObject = @"comicthumbwrap";

@interface CVArchiveXMLDownloader ()

@property (strong, nonatomic) NSMutableArray *comicRecords;
@property (strong, nonatomic) CVComicRecord *comicRecord;
@property (strong, nonatomic) NSURL *urlOfArchive;

@end

@implementation CVArchiveXMLDownloader {
    BOOL _shouldAcquireDate;
}

- (void)main {
    @autoreleasepool {
#warning remember to add cancelation checking later
        //get xml from website
        NSError *err;
        NSString *text = [NSString stringWithContentsOfURL:self.urlOfArchive encoding:NSUTF8StringEncoding error:&err];
        if (err) {
            //create error message
            [self operationFailed];
            return;
        }
        if (self.isCancelled) {
            [self operationFailed];
            return;
        }
        text = [self cleanText:text];
        if (self.isCancelled) {
            [self operationFailed];
            return;
        }
        //use XML parser to get the array of archive objects
        NSData *stringData = [text dataUsingEncoding:NSUTF8StringEncoding];
        NSXMLParser *xmlparser = [[NSXMLParser alloc] initWithData:stringData];
        xmlparser.delegate = self;
        [xmlparser parse];
        if (self.isCancelled) {
            [self operationFailed];
            return;
        }
        //Send notification
        //YOu should be able to have information about title,date,thumbImageURL, and fullPageURL
        [self operationCompleted];
    }
}

- (void)operationCompleted {
    [[NSNotificationCenter defaultCenter] postNotificationName:kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOADER_NOTIFICATION
                                                            object:self
                                                          userInfo:@{@"comicRecords":self.comicRecords}];

}

- (void)operationFailed {
    [[NSNotificationCenter defaultCenter] postNotificationName:kCOMIC_VIEWER_ARCHIVE_XML_DOWNLOAD_FAILED_NOTIFICATION
                                                        object:self
                                                      userInfo:@{@"comicRecords":self.comicRecords}];
}

- (NSString *)cleanText:(NSString *)text {
    NSString *beginTag = [NSString stringWithFormat:@"<div class=\"%@\"></div>", @"post-head"];
    NSString *endTag = [NSString stringWithFormat:@"<div class=\"%@\"></div>", @"post-foot"];
    NSRange beginRange = [text rangeOfString:beginTag];
    NSRange endRange = [text rangeOfString:endTag];
    text = [text substringWithRange:NSMakeRange(beginRange.location + beginTag.length, endRange.location - beginRange.location - beginTag.length)];
    text = [text stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"\t" withString:@""];
    text = [text stringByReplacingOccurrencesOfString:@"\r" withString:@""];
    return text;
}

- (NSURL *)urlOfArchive {
    return _urlOfArchive?: (_urlOfArchive = [NSURL URLWithString:kComicSourceURL]);
}

#pragma mark - NSXMLparser

- (void)parserDidStartDocument:(NSXMLParser *)parser {
    
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    NSString *class = attributeDict[@"class"];
    NSString *src = attributeDict[@"src"];
    NSString *title = attributeDict[@"title"];
    NSString *href = attributeDict[@"href"];
    
    if ([elementName isEqualToString:@"div"]) {
        if ([class isEqualToString:kComicArray]) {
            self.comicRecords = [NSMutableArray new];
        } else if ([class isEqualToString:kComicArrayObject]) {
            if (self.comicRecord) {
                [self.comicRecords addObject:self.comicRecord];
            }
            self.comicRecord = [CVComicRecord new];
        } else if ([class isEqualToString:kComicThumbDate]) {
            _shouldAcquireDate = YES;
        }
    } else if ([elementName isEqualToString:@"a"]) {
        self.comicRecord.fullImagePageURL = [NSURL URLWithString:href];
        self.comicRecord.title = title;
    } else if ([elementName isEqualToString:@"img"]) {
        if ([class isEqualToString:kComicThumbnail]) {
            self.comicRecord.thumbnailImageURL = [NSURL URLWithString:src];
        }
    }
}

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (_shouldAcquireDate) {
        _shouldAcquireDate = NO;
        self.comicRecord.date = string;
    }
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    [self.comicRecords addObject:self.comicRecord];
    self.comicRecord = nil;
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"%@", parseError);
    [self cancel];
}

@end
