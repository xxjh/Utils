//
//  ImageAccessor.m
//  FilmPicker
//
//  Created by sing on 11-6-9.
//  Copyright 2011年 __MyCompanyName__. All rights reserved.
//

#import "ImageAccessor.h"
#import "Common.h"

#pragma mark - ImageItem class

@implementation ImageItem

@synthesize image;
@synthesize imageUrl;
@synthesize imageLocalPath;
@synthesize retryCount = _retryCount;
@synthesize status = _status;

- (id)initWithImageUrl:(NSString*)url
{
    if ((self = [super init]) != nil) {
        self.imageUrl = url;
    }
    
    return self;
}

- (void)dealloc
{
    [image release];
    [imageUrl release];
    [imageLocalPath release];
    [super dealloc];
}

+ (id)imageItemWithImageUrl:(NSString*)url
{
    ImageItem *item = [[[ImageItem alloc] init] autorelease];
    
    if (item != nil) {
        item.imageUrl = url;
        item.retryCount = 0;
    }
    return item;
}

@end


#pragma mark - imageacessor class

@implementation ImageAccessor


@synthesize imageTaskList;
@synthesize imageProcessorLock;
@synthesize workThread;
@synthesize exitThread = _exitThread;
@synthesize httpProcessor;
@synthesize defaultImage;
@synthesize delegate;

-(id)init
{
    if ((self = [super init]) != nil) {

        NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(run) object:nil];
        [thread setName:@"workThread"];
        [thread start];
        self.workThread = thread;
        [thread release];
                
        DownloadProcessor *processor = [[DownloadProcessor alloc] initWithTag:0];
        processor.delegate = self;
        processor.autoEncodeToGbkEncode = NO;
        self.httpProcessor = processor;
        [processor release];        
        
    }
    
    return self;
}

-(void)dealloc
{
    _exitThread = YES;
    [imageTaskList release];
    [imageProcessorLock release];
    [workThread release];
    [httpProcessor release];
    [defaultImage release];
    [super dealloc];
}

- (UIImage*)imageFromPath:(NSString *)imagePath
{
    UIImage *tempImage = nil;
    
    NSRange foundRange = [imagePath rangeOfString:@"http://"];
    
    //local path
    if (foundRange.location == NSNotFound) {
        tempImage = [UIImage imageNamed:imagePath];
    } else { //url path
        NSURL *url = [NSURL URLWithString:imagePath];
        NSData *imageData = [[NSData alloc] initWithContentsOfURL:url];
        tempImage = [[[UIImage alloc] initWithData:imageData] autorelease];
        [imageData release];        
    }
    
    return tempImage;
}

- (void)threadSync:(SyncLockFlag)flag
{
    if (imageProcessorLock == nil) {
        imageProcessorLock = [[NSCondition alloc] init];
    }
    if (flag == sync_lock) {
        [imageProcessorLock lock];
    } else {
        [imageProcessorLock unlock];
    }
}

- (NSMutableArray*)imageTaskList
{
    if (imageTaskList == nil) {
        imageTaskList = [[NSMutableArray alloc] initWithCapacity:1];
    }
    return imageTaskList;
}

//return count after insert
- (NSInteger)addToImageTaskList:(ImageItem*)imageItem
{
    if (imageItem == nil) {
        return 0;
    }
    
    //lock
    [self threadSync:sync_lock];
    
    //process code
    NSMutableArray *list = [self imageTaskList];
    
    [list addObject:imageItem];  //add to end
    
    NSInteger count = [list count];
    
    [self threadSync:sync_unLock];
    
    return count;
}

- (ImageItem*)getFromImageTaskList
{
    //lock
    [self threadSync:sync_lock];
    
    //process code
    NSMutableArray *list = [self imageTaskList];
    ImageItem *item = nil;
    
    if ([list count] > 0) {
        item = [list objectAtIndex:0];    //get the first item
    }
    
    [self threadSync:sync_unLock];
    
    return item;
}

//return the count of list after remove
- (NSInteger)removeTaskFromList:(ImageItem*)item
{
    //lock
    [self threadSync:sync_lock];
    
    //process code
    NSMutableArray *list = [self imageTaskList];
    
    //add to end and retry!
    if (item.status == status_failed && item.retryCount < 3) {
        ImageItem *newItem = [[ImageItem alloc] initWithImageUrl:item.imageUrl];
        newItem.retryCount = item.retryCount + 1;
        [list addObject:newItem];
        [newItem release];
    }

    [list removeObject:item];
    item = nil;
    
    NSInteger count = [list count];
    
    [self threadSync:sync_unLock];
    
    return count;
}

-(void)clearImageTaskList
{
    //lock
    [self threadSync:sync_lock];
    
    //process code
    NSMutableArray *list = [self imageTaskList];
    if ([list count] > 1) {
        id item = [list objectAtIndex:0];   //backup the first item, anvoid it is downloding in thread!
        [item retain];
        [list removeAllObjects];
        [list addObject:item];
        [item release];
    }
    
    [self threadSync:sync_unLock];
}

- (BOOL)writeImageToDisk:(NSData*)imageData filePath:(NSString*)path
{    
    BOOL succeed = NO;
    if (imageData != nil) {
        succeed = [imageData writeToFile:path atomically:YES];
        NSAssert(succeed, @"write image file to disk failed!");
    }
    return succeed;
}

- (UIImage*)readImageFromDisk:(NSString*)imageUrl
{
    NSRange foundRange = [imageUrl rangeOfString:@"http://"];
    NSString *filePath = nil;
    
    ImageItem *imageItem = [[ImageItem alloc] init];
    UIImage *image = nil;
    
    //local path
    if (foundRange.location == NSNotFound) {
        foundRange = [imageUrl rangeOfString:@"/"];
        if (foundRange.location == NSNotFound) {    //image is in resource
            image = [UIImage imageNamed:imageUrl];
        } else {    //image is in disk
            image = [UIImage imageWithContentsOfFile:filePath];
        }
        filePath = imageUrl;
        imageItem.imageUrl = imageUrl;
        imageItem.imageLocalPath = imageUrl;
    } else {
        filePath = [ImageAccessor converUrlToLocalPath:imageUrl];
        imageItem.imageUrl = imageUrl;
        imageItem.imageLocalPath = filePath;
        image = [UIImage imageWithContentsOfFile:filePath];
    }
    
    imageItem.image = image;
    
    if (image == nil) {
        //default image
        image = defaultImage;
        
        //add to task list to download
        NSInteger count = [self addToImageTaskList:imageItem];
        //the first time to add task
        if (count == 1) {
            [self setLoopFlag:YES];
        }
    }
    
    [imageItem release];
    
    return image;
}

//before new task, clear all task in task list.
- (UIImage*)readImageFromDisk:(NSString*)imageUrl clearTask:(BOOL)clear
{
    if (clear) {
        [self clearImageTaskList];
    }
    
    return [self readImageFromDisk:imageUrl];
}

-(void)startDownload:(NSString*)url
{
    [self.httpProcessor startWithUrl:url method:HTTP_GET postData:nil];
}

-(void)setLoopFlag:(BOOL)flag
{
    [self threadSync:sync_lock];
    _nextTask = flag;
    [self threadSync:sync_unLock];
}

-(void)run
{ 
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    while (!_exitThread) {
        
        if (_nextTask) {
            ImageItem *item = [self getFromImageTaskList];
            if (item == nil) {
                [NSThread sleepForTimeInterval:1.0];
                continue;
            }
            _currentTaskImageItem = item;
            [self setLoopFlag:NO];
            
            //process on main thread
//            [self performSelectorOnMainThread:@selector(startDownload:) withObject:item.imageUrl waitUntilDone:NO];
            
            //or on worker thread
            {
                [self performSelector:@selector(startDownload:) withObject:item.imageUrl];
                CFRunLoopRunInMode(kCFRunLoopDefaultMode, 1.0, false);
                [self setLoopFlag:YES];
            }
            
        } else {
            [NSThread sleepForTimeInterval:1.0];
        }
    }
    
    [pool release];
}

+ (NSString*)getFileNameFromUrl:(NSString*)url
{
    NSArray *components = [url componentsSeparatedByString:@"/"];
    NSString *fileName = [components lastObject];
    NSAssert(fileName != nil, @"file name is nil");
    return fileName;
}

+ (NSString*)converUrlToLocalPath:(NSString*)url
{
    NSString *path = [Common tmpDirectory];
    
    NSString *imageName = [ImageAccessor getFileNameFromUrl:url];
    NSString *imageLocalPath = [path stringByAppendingPathComponent:imageName];
    
    return imageLocalPath;
}

#pragma mark - http download processor

-(void)didReceiveResponse:(NSURLResponse *)response tag:(NSUInteger)aTag
{
    NSHTTPURLResponse *resp = (NSHTTPURLResponse*)response;
    NSInteger statusCode = [resp statusCode];
    
    if (statusCode != 200) {
        [httpProcessor stop];
        _currentTaskImageItem.status = status_failed;
        [self removeTaskFromList:_currentTaskImageItem];
        [self setLoopFlag:YES];
    }
}

-(void)didReceiveData:(NSData *)data tag:(NSUInteger)aTag
{

}

-(void)didFailWithError:(NSError *)error tag:(NSUInteger)aTag
{
    _currentTaskImageItem.status = status_failed;
    [self removeTaskFromList:_currentTaskImageItem];
    [self setLoopFlag:YES];
}

-(void)didFinishLoading:(NSURLConnection *)connection data:(NSData *)responseData tag:(NSUInteger)aTag
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *imageUrl = _currentTaskImageItem.imageUrl;
    NSString *filePath = _currentTaskImageItem.imageLocalPath;
    
    ImageItem *imageItem = [[[ImageItem alloc] initWithImageUrl:imageUrl] autorelease];
    imageItem.imageLocalPath = filePath;
    imageItem.status = status_succeed;
    
    [responseData retain];
    UIImage *image = [UIImage imageWithData:responseData];
    [responseData release];
    
    //save to file
    //NSData *imageData = [[NSData alloc] initWithData:UIImagePNGRepresentation(image)];         //png data    
    NSData *imageData = [[NSData alloc] initWithData:UIImageJPEGRepresentation(image, 1.0)];     //jpg data
    [self writeImageToDisk:imageData filePath:filePath];
    [imageData release];
    
    NSInteger count = [self removeTaskFromList:_currentTaskImageItem];
    
    //task list is empty
    BOOL flag = YES;
    if (count == 0) {
        flag = NO;
    }
    [self setLoopFlag:flag];
    
    imageItem.image = image;
    [delegate updateWhenImageFinishDownload:imageItem];
    
    [pool release];
}


@end
