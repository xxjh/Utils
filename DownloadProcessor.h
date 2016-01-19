//
//  DownloadProcesser.h
//  FilmPicker
//
//  Created by sing on 11-5-23.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DelegateDef.h"

#define HTTP_GET  @"GET"
#define HTTP_POST @"POST"

@interface DownloadProcessor : NSObject {
    NSString *postData;
    NSMutableData *receiveData;
    NSURLConnection *connection;
    NSObject<DownloadProcessorDelegate> *delegate;
@private
    NSUInteger _tag;
    BOOL _autoEncodeToGbkEncode;
    BOOL _isRunning;     //the download is active
}


@property (nonatomic, copy) NSString *postData;
@property (nonatomic, retain) NSMutableData *receiveData;
@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, assign) NSObject<DownloadProcessorDelegate> *delegate;
@property (nonatomic, assign) NSUInteger tag;
@property (nonatomic, assign) BOOL autoEncodeToGbkEncode;

#pragma mark initialization

-(id)initWithTag:(NSUInteger)aTag;
-(id)initWithRequestUrl:(NSString*)url method:(NSString*)requestMethod postData:(NSString*)aPostData delegate:(id)aDelegate tag:(NSUInteger)aTag;
-(id)initWithRequestUrl:(NSString*)url method:(NSString*)requestMethod timeOut:(NSTimeInterval)timeInterval postData:(NSString*)aPostData delegate:(id)aDelegate tag:(NSUInteger)aTag;

#pragma mark processor

-(void)start;
-(void)stop;
-(void)startWithUrl:(NSString*)url method:(NSString*)aMethod postData:(NSString *)aPostData;


@end
