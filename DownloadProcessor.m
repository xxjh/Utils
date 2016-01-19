//
//  DownloadProcesser.m
//  FilmPicker
//
//  Created by sing on 11-5-23.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "DownloadProcessor.h"
#import "Common.h"

@implementation DownloadProcessor


@synthesize postData;
@synthesize receiveData;
@synthesize connection;
@synthesize delegate;
@synthesize tag = _tag;
@synthesize autoEncodeToGbkEncode = _autoEncodeToGbkEncode;


#pragma mark initialization

-(id)initWithTag:(NSUInteger)aTag
{
    self = [super init];
    
    if (self != nil) {
        self.tag = aTag;
                
        _autoEncodeToGbkEncode = YES;
    }
    
    return self;
}

-(id)initWithRequestUrl:(NSString *)url method:(NSString*)requestMethod postData:(NSString*)aPostData delegate:(id)aDelegate tag:(NSUInteger)aTag
{
    self = [super init];
    
    if (self != nil) {
        
//        NSLog(@"url request : %@", url);
        
        self.delegate = aDelegate;
        self.tag = aTag;
        
        NSMutableURLRequest *urlReq = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        [urlReq setHTTPMethod:requestMethod];
        [urlReq setTimeoutInterval:10.0];
        if ([requestMethod isEqualToString:HTTP_POST]) {
            self.postData = aPostData;
            NSData *postBody = [[NSData alloc] initWithData:[aPostData dataUsingEncoding:NSUTF8StringEncoding]];
            [urlReq setHTTPBody:postBody];
            [postBody release];
        }
        
        
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:urlReq delegate:self];
        self.connection = conn;
        [conn release];
        [urlReq release];
        
        _autoEncodeToGbkEncode = YES;
    }
    
    return self;
}

-(id)initWithRequestUrl:(NSString*)url method:(NSString*)requestMethod timeOut:(NSTimeInterval)timeInterval postData:(NSString*)aPostData delegate:(id)aDelegate tag:(NSUInteger)aTag
{
    self = [super init];
    
    if (self != nil) {

//        NSLog(@"url request : %@", url);
        
        self.delegate = aDelegate;
        self.tag = aTag;
        
        NSMutableURLRequest *urlReq = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
        [urlReq setHTTPMethod:requestMethod];
        if ([requestMethod isEqualToString:HTTP_POST]) {
            self.postData = aPostData;
            NSData *postBody = [[NSData alloc] initWithData:[aPostData dataUsingEncoding:NSUTF8StringEncoding]];
            [urlReq setHTTPBody:postBody];
            [postBody release];
        }
        [urlReq setTimeoutInterval:timeInterval];
        
        
        NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:urlReq delegate:self];
        self.connection = conn;
        [conn release];
        [urlReq release];
        
        _autoEncodeToGbkEncode = YES;
    }
    
    return self;
}

#pragma mark processor

-(void)start
{
    [self.connection start];
    _isRunning = YES;
}

-(void)startWithUrl:(NSString *)url method:(NSString*)aMethod postData:(NSString *)aPostData
{
//    NSLog(@"url request : %@", url);
    
    if (_isRunning) {
        [self stop];
    }
    
    NSMutableURLRequest *urlReq = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    [urlReq setHTTPMethod:aMethod];
    
    //set post data
    if ([aMethod isEqualToString:HTTP_POST]) {
        self.postData = aPostData;
        NSData *postBody = [[NSData alloc] initWithData:[aPostData dataUsingEncoding:NSUTF8StringEncoding]];
        [urlReq setHTTPBody:postBody];
        [postBody release];
    }
    
    NSURLConnection *conn = [[NSURLConnection alloc] initWithRequest:urlReq delegate:self];
    self.connection = conn;
    [conn release];
    [urlReq release];
    
    //clear old data
    self.receiveData = nil;
    
    [self.connection start];
    _isRunning = YES;
}

-(void)stop
{
    [self.connection cancel];
    _isRunning = NO;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
//    NSHTTPURLResponse *resp = (NSHTTPURLResponse*)response;
//    NSInteger statusCode = [resp statusCode];
//    NSLog(@"status code : %d", statusCode);
    
    if ([delegate respondsToSelector:@selector(didReceiveResponse:tag:)]) {
        [delegate didReceiveResponse:response tag:_tag];
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (receiveData == nil) {
        NSMutableData *tempData = [[NSMutableData alloc] initWithData:data];
        self.receiveData = tempData;
        [tempData release];
    } else {
        [receiveData appendData:data];
    }
    
//    NSLog(@"receive data...");
    
    if ([delegate respondsToSelector:@selector(didReceiveData:tag:)]) {
        [delegate didReceiveData:data tag:_tag];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)aConnection
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    [self stop];
    
    NSData *utf8Data = receiveData;
    if (_autoEncodeToGbkEncode) {
        utf8Data = [Common gbkDataConverToUtf8EncodingData:receiveData];
    }
    
    if ([delegate respondsToSelector:@selector(didFinishLoading:data:tag:)]) {
        [delegate didFinishLoading:aConnection data:utf8Data tag:_tag];
    }
    
    self.receiveData = nil;
    
    [pool release];
    
//    NSLog(@"finish download!");
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self stop];
    
//    NSString *errorStr = [NSString stringWithFormat:@"reason : %@; recovery suggestion : %@ Description : %@", 
//                          [error localizedFailureReason], [error localizedRecoverySuggestion],
//                          [error localizedDescription]];
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:[error localizedDescription] message:errorStr delegate:nil cancelButtonTitle:@"ok" otherButtonTitles:nil, nil];
//    [alert show];
//    [alert release];
    
    if ([delegate respondsToSelector:@selector(didFailWithError:tag:)]) {
        [delegate didFailWithError:error tag:_tag];
    }
}

-(void)dealloc
{
    [self stop];
    [postData release];
    [receiveData release];
    [connection release];
    [super dealloc];
}

@end
