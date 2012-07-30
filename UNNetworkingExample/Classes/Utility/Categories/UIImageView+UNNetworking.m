//
//  UIImageView+UNNetworking.m
//  UNNetworkingExample
//
//  Created by Alexander Bukov on 7/28/12.
//  Copyright (c) 2012 Company. All rights reserved.
//


#import <objc/runtime.h>
#import <CommonCrypto/CommonHMAC.h>
#import <Foundation/Foundation.h>
#import "UIImageView+UNNetworking.h"


//! Memory cache class interface.
@interface UNImageCache : NSCache

- (UIImage *)cachedImageForRequest:(NSURLRequest*)request
                           forSize:(CGSize)size
                        sizePolicy:(UNImageSizePolicy)sizePolicy
                        withPolicy:(UNImageCachePolicy)policy;

- (void)cacheImage:(UIImage *)image
        forRequest:(NSURLRequest *)request
        withPolicy:(UNImageCachePolicy)policy
           forSize:(CGSize)size
        sizePolicy:(UNImageSizePolicy)sizePolicy;
@end


//! File cache class interface.
@interface UNFileCache : NSObject

@property (strong, nonatomic) NSString* cachePath;

- (BOOL)isCachedImageForRequest:(NSURLRequest *)request 
                        forSize:(CGSize)size 
                     sizePolicy:(UNImageSizePolicy)sizePolicy
                     withPolicy:(UNImageCachePolicy)policy
                      completed:(void(^)(NSURLRequest* request, CGSize size, UIImage* image))block;

- (void)cacheImage:(UIImage*)image
        forRequest:(NSURLRequest*)request
        withPolicy:(UNImageCachePolicy)policy
           forSize:(CGSize)size
        sizePolicy:(UNImageSizePolicy)sizePolicy;

- (void)removeAllFiles;

@end


//! Load image operation interface.
@interface LoadOperation : NSOperation

@property (nonatomic, strong) NSURLRequest* request;
@property (nonatomic, strong) NSMutableData* connectionData;
@property (strong, nonatomic) NSURLConnection* connection;
@property (strong, nonatomic) NSURLResponse *response;

@property (nonatomic, copy) UIImage* (^processingBlock)(LoadOperation* operation, NSData* connectionData);
@property (nonatomic, copy) void (^successBlock)(LoadOperation* operation, UIImage* image);
@property (nonatomic, copy) void (^failureBlock)(LoadOperation* operation, NSError* error);
@property (nonatomic, copy) void (^progressBlock)(LoadOperation* operation, float progress);

- (id)initWithRequest:(NSURLRequest*)request;

@end


//! Keys for associate objects
static char kUNImageLoadOperationObjectKey;
static char kUNImageRequestObjectKey;
static char kUNProgressObjectKey;


//! Declaration of associated objects
@interface UIImageView (_UNNetworking)
@property (readwrite, nonatomic, retain, setter = un_setImageLoadOperation:) LoadOperation *un_imageLoadOperation;
@property (readwrite, nonatomic, retain, setter = un_setImageRequest:) NSURLRequest *un_imageRequest;
@property (readwrite, nonatomic, retain, setter = un_setProgressView:) UIProgressView *un_progressView;
@end


@implementation UIImageView (_UNNetworking)
@dynamic un_imageLoadOperation;
@dynamic un_imageRequest;
@dynamic un_progressView;
@end


#pragma mark -
#pragma mark  Additional categories

//! Catecory for MD5 string
@interface NSString (UN_MD5)
- (NSString *)un_md5String;
@end

//! Category for resizing image
@interface UIImage(UN_Resizing)
- (UIImage*)imageResizedToSize:(CGSize)size;
@end


#pragma mark -
#pragma mark  UIImageView (UNNetworking)

//! Implementation UNNetworking category
@implementation UIImageView (UNNetworking)

//! Getter and Setter for image load operation.
- (LoadOperation*)un_imageLoadOperation {
    return (LoadOperation*)objc_getAssociatedObject(self, &kUNImageLoadOperationObjectKey);
}

- (void)un_setImageLoadOperation:(LoadOperation*)loadOperation {
    objc_setAssociatedObject(self, &kUNImageLoadOperationObjectKey, loadOperation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


//! Getter and Setter for progress view.
- (UIProgressView*)un_progressView {
    return (UIProgressView*)objc_getAssociatedObject(self, &kUNProgressObjectKey);
}

- (void)un_setProgressView:(UIProgressView *)progressView {
    objc_setAssociatedObject(self, &kUNProgressObjectKey, progressView, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


//! Getter and Setter for image request.
- (NSURLRequest*)un_imageRequest {
    return (NSURLRequest*)objc_getAssociatedObject(self, &kUNImageRequestObjectKey);
}

- (void)un_setImageRequest:(NSURLRequest*)imageRequest {
    objc_setAssociatedObject(self, &kUNImageRequestObjectKey, imageRequest, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}


//! NSOperationQoeue for image load operations.(One for UIImageView class)
+ (NSOperationQueue*)un_sharedImageRequestOperationQueue {
    
    static NSOperationQueue* _un_imageRequestOperationQueue = nil;
    
    if (!_un_imageRequestOperationQueue) {
        _un_imageRequestOperationQueue = [[NSOperationQueue alloc] init];
        [_un_imageRequestOperationQueue setMaxConcurrentOperationCount:3];
    }
    
    return _un_imageRequestOperationQueue;
}

//! UNImageCache - memory cache.(One for UIImageView class)
+ (UNImageCache*)un_sharedImageCache {
    
    static UNImageCache* _un_imageCache = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _un_imageCache = [[UNImageCache alloc] init];
    });
    
    return _un_imageCache;
}

//! UNFileCache - file cache.(One for UIImageView class)
+ (UNFileCache*)un_sharedFileCache {
    
    static UNFileCache* _un_fileCache = nil;
    if (!_un_fileCache) {
        _un_fileCache = [[UNFileCache alloc] init];
    }
    return _un_fileCache;
}

//! Method for clearing memory cache
+ (void)clearMemoryImageCache{
    [[[self class] un_sharedImageCache] removeAllObjects];
}

//! Method for clearing file cache
+ (void)clearFileImageCache{
    [[[self class] un_sharedFileCache] removeAllFiles];
}


#pragma mark -
#pragma mark  Image load methods

//! load without progress view
- (void)setImageWithURLRequest:(NSURLRequest *)urlRequest 
              placeholderImage:(UIImage *)placeholderImage
                  failureImage:(UIImage *)failureImage
                    sizePolicy:(UNImageSizePolicy)sizePolicy
                   cachePolicy:(UNImageCachePolicy)cachePolicy
                       success:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image))success
                       failure:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error))failure
                      progress:(void (^)(NSURLRequest *request, NSHTTPURLResponse *response, float progress))progress{
    
    
    [self setImageWithURLRequest:urlRequest
                placeholderImage:placeholderImage
                    failureImage:failureImage
                progressViewSize:CGSizeZero
               progressViewStile:UIProgressViewStyleDefault
               progressTintColor:nil
                  trackTintColor:nil
                      sizePolicy:sizePolicy
                     cachePolicy:cachePolicy
                         success:success
                         failure:failure
                        progress:progress];
}


//! Base method for loading image (from memory cache, file cache or network)
- (void)setImageWithURLRequest:(NSURLRequest*)urlRequest 
              placeholderImage:(UIImage*)placeholderImage
                  failureImage:(UIImage*)failureImage
              progressViewSize:(CGSize)progressViewSize
             progressViewStile:(UIProgressViewStyle)progressViewStile
             progressTintColor:(UIColor*)progressTintColor
                trackTintColor:(UIColor*)trackTintColor
                    sizePolicy:(UNImageSizePolicy)sizePolicy
                   cachePolicy:(UNImageCachePolicy)cachePolicy
                       success:(void (^)(NSURLRequest* request, NSHTTPURLResponse* response, UIImage* image))success
                       failure:(void (^)(NSURLRequest* request, NSHTTPURLResponse* response, NSError* error))failure
                      progress:(void (^)(NSURLRequest* request, NSHTTPURLResponse* response, float progress))progress{
    
    [self unCancelImageRequestOperation];
    self.un_imageRequest = urlRequest;
    
    [self un_progressView].progress = 0;
    self.un_progressView.hidden = YES;
    
    //! Try to find image in memory cache
    UIImage *cachedImage = [[[self class] un_sharedImageCache] cachedImageForRequest:urlRequest 
                                                                             forSize:self.frame.size
                                                                          sizePolicy:sizePolicy
                                                                          withPolicy:cachePolicy];
    
    if (cachedImage) {
        self.image = cachedImage;
        self.un_imageLoadOperation = nil;
        
        if (success) {
            success(nil, nil, cachedImage);
        }
        
    } else {
        
        //! Try to find image in file cache
        BOOL isCached = [[[self class] un_sharedFileCache] 
                         isCachedImageForRequest:urlRequest
                         forSize:self.frame.size
                         sizePolicy:sizePolicy
                         withPolicy:cachePolicy 
                         completed:^(NSURLRequest *request, CGSize size, UIImage *image) {
                             //! At this point image loaded form file.
                             if ([[urlRequest URL] isEqual:[self.un_imageRequest URL]]) {
                                 [self unCancelImageRequestOperation];
                                 self.image = image;
                                 
                                 if (success) {
                                     success(nil, nil, image);
                                 }
                                 
                                 //! Save image to memory cache
                                 [[[self class] un_sharedImageCache] cacheImage:image 
                                                                     forRequest:urlRequest 
                                                                     withPolicy:cachePolicy
                                                                        forSize:self.frame.size 
                                                                     sizePolicy:sizePolicy];
                             }
                         }];
        
        if (isCached) {
            self.image = placeholderImage;
            return;
        }else {
            
            self.image = placeholderImage;
            
            //Create progress view if necessary
            [self createProgressView:progressViewStile 
                                size:progressViewSize
                   progressTintColor:(UIColor*)progressTintColor
                      trackTintColor:(UIColor*)trackTintColor
             ];
            
            [self un_progressView].progress = 0;
            [self un_progressView].hidden = NO;
            
            
            //! NSOperation for image loading
            LoadOperation* operation = [[LoadOperation alloc] initWithRequest:urlRequest];
            
            operation.processingBlock = ^UIImage*(LoadOperation* op, NSData* connectionData){
                //(operation background thread)
                
                UIImage* image = [UIImage imageWithData:connectionData];
                
                UIImage* resImage = nil;
                
                CGFloat horizontalRatio = self.bounds.size.width / image.size.width;
                CGFloat verticalRatio = self.bounds.size.height / image.size.height;
                
                //! Resize image if necessary 
                switch (sizePolicy) {
                    case UNImageSizePolicyOriginalSize:
                        resImage = image;
                        break;
                    case UNImageSizePolicyResizeToRect:
                        resImage = [image imageResizedToSize:self.bounds.size];
                        break;
                    case UNImageSizePolicyScaleAspectFill:;
                        resImage = [self scaleImage:image scaleValue:MAX(horizontalRatio, verticalRatio)];
                        break;
                        
                    case UNImageSizePolicyScaleAspectFit:;
                        resImage = [self scaleImage:image scaleValue:MIN(horizontalRatio, verticalRatio)];
                        break;
                        
                    default:
                        break;
                }
                
                //! Save image to memory cache if necessary
                [[[self class] un_sharedImageCache] cacheImage:resImage 
                                                    forRequest:urlRequest
                                                    withPolicy:cachePolicy
                                                       forSize:self.frame.size 
                                                    sizePolicy:sizePolicy];
                
                //! Save image to file cache if necessary
                [[[self class] un_sharedFileCache] cacheImage:resImage 
                                                   forRequest:urlRequest 
                                                   withPolicy:cachePolicy
                                                      forSize:self.frame.size 
                                                   sizePolicy:sizePolicy];     
                return resImage;
            };
            
            operation.successBlock = ^(LoadOperation* op, UIImage* image){
                
                self.un_progressView.hidden = YES;
                self.image = image;
                
                if (success) {
                    success(urlRequest, (NSHTTPURLResponse*)op.response, image);
                }
                
                self.un_imageLoadOperation = nil;
            };
            
            operation.failureBlock = ^(LoadOperation* op, NSError* error){
                
                self.image = failureImage;
                
                if (failure) {
                    failure(urlRequest, (NSHTTPURLResponse*)op.response, error);
                }
                self.un_progressView.hidden = YES;
                self.un_imageLoadOperation = nil;
            };
            
            operation.progressBlock = ^(LoadOperation* op, float progressValue){
                
                [self un_progressView].progress = progressValue;
                
                if (progress) {
                    progress(urlRequest, (NSHTTPURLResponse*)op.response, progressValue);
                }
            };
            
            self.un_imageLoadOperation = operation;
            
            [[[self class] un_sharedImageRequestOperationQueue] addOperation:operation];
        }
    }
}

//! Method create progress view and transform it if necessary.
- (UIProgressView*)createProgressView:(UIProgressViewStyle)stile 
                                 size:(CGSize)size
                    progressTintColor:(UIColor*)progressTintColor
                       trackTintColor:(UIColor*)trackTintColor{
    
    //! Create progress view once for UIImageView object
    if ([self un_progressView] == nil && size.width > 0 && size.height >0) {
        
        CGFloat transformValue = 1;
        if (size.width > self.bounds.size.width) size.width = self.bounds.size.width;
        if (size.height > 9) size.height = 9; //max height for progress view (9 - default height)
        if (size.height < 9) {
            transformValue = size.height / 9; 
            size.width = size.width * (9 / size.height);
        }
        
        UIProgressView* progressView = [[UIProgressView alloc] initWithProgressViewStyle:stile];
        
        //! If iOS >= 5.0, set colors.
        if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0f) {
            if (progressTintColor) {
                progressView.progressTintColor = progressTintColor;
            }
            if (trackTintColor) {
                progressView.trackTintColor = trackTintColor;
            }
        }
        
        progressView.frame = CGRectMake(0, 0, size.width, 9);
        progressView.center = CGPointMake(CGRectGetMidX(self.bounds), self.bounds.size.height - 9 * transformValue);
        
        
        
        if (transformValue != 1) { // transform progress view if it height < 9
            CGAffineTransform transform = progressView.transform;
            progressView.transform = CGAffineTransformScale(transform, transformValue, transformValue);
        }
        progressView.autoresizingMask = UIViewAutoresizingFlexibleTopMargin | UIViewAutoresizingFlexibleWidth;
        [self addSubview:progressView];
        [self un_setProgressView:progressView];
        
        
    }
    return [self un_progressView]; 
}

//! Method remove progress view from supper view
- (void)removeProgressView{
    [[self un_progressView] removeFromSuperview];
    self.un_progressView = nil;
}

//! Cancel and nil load operation(main thread only)
- (void)unCancelImageRequestOperation {
    [self.un_imageLoadOperation cancel];
    self.un_imageLoadOperation = nil;
}


//! Scale image method
- (UIImage*)scaleImage:(UIImage*)image
            scaleValue:(CGFloat)scaleValue{
    
    CGSize size = CGSizeMake(image.size.width * scaleValue, image.size.height * scaleValue);
    
    return [image imageResizedToSize:size];
}

@end


#pragma mark -
#pragma mark  UNImageCache

//! Cache key for image.
static inline NSString* UNImageCacheKeyFromURLRequest(NSURLRequest* request, CGSize size, UNImageSizePolicy sizePolicy) {
    
    switch (sizePolicy) {
        case UNImageSizePolicyOriginalSize:
            return [[request URL] absoluteString];
            break;
        case UNImageSizePolicyResizeToRect:
            return [[[request URL] absoluteString] stringByAppendingFormat:@"andThumbSize%fx%f", size.width, size.height];
            break;
        case UNImageSizePolicyScaleAspectFill:
            return [[[request URL] absoluteString] stringByAppendingFormat:@"andThumbSize%fx%fScaleAspectFill", size.width, size.height];
            break;
        case UNImageSizePolicyScaleAspectFit:
            return [[[request URL] absoluteString] stringByAppendingFormat:@"andThumbSize%fx%fScaleAspectFit", size.width, size.height];
            break;
            
        default:
            return [[request URL] absoluteString];
            break;
    }
}

//! Memory cache implementation
@implementation UNImageCache

//! Method return cached image or nil;
- (UIImage*) cachedImageForRequest:(NSURLRequest*)request
                           forSize:(CGSize)size
                        sizePolicy:(UNImageSizePolicy)sizePolicy
                        withPolicy:(UNImageCachePolicy)policy{
    
    switch (policy) {
        case UNImageCachePolicyIgnoreCache:
            return nil;
        default:
            break;
    }
    return [self objectForKey:UNImageCacheKeyFromURLRequest(request, size, sizePolicy)];
}

//! Method cache image if necessory
- (void)cacheImage:(UIImage*)image
        forRequest:(NSURLRequest*)request
        withPolicy:(UNImageCachePolicy)policy
           forSize:(CGSize)size
        sizePolicy:(UNImageSizePolicy)sizePolicy{
    
    switch (policy) {
        case UNImageCachePolicyIgnoreCache:
            return;
        default:
            break;
    }
    
    if (image && request) {
        [self setObject:image forKey:UNImageCacheKeyFromURLRequest(request, size, sizePolicy)];
    }
}

@end


#pragma mark -
#pragma mark  UNFileCache

//! Cache name(folder name)
static NSString* const kUNFileCacheName = @"com.uniprog.default.UNFilleCache";

//! Cache key for image.
static inline NSString* UNFileCacheKeyFromURLRequest(NSURLRequest* request, CGSize size, UNImageSizePolicy sizePolicy) {
    
    switch (sizePolicy) {
        case UNImageSizePolicyOriginalSize:
            return [[[request URL] absoluteString] un_md5String];
            break;
        case UNImageSizePolicyResizeToRect:
            return [[[[request URL] absoluteString] stringByAppendingFormat:@"andThumbSize%fx%f", size.width, size.height] un_md5String];
            break;
        case UNImageSizePolicyScaleAspectFill:
            return [[[[request URL] absoluteString] stringByAppendingFormat:@"andThumbSize%fx%fScaleAspectFill", size.width, size.height] un_md5String];
            break;
        case UNImageSizePolicyScaleAspectFit:
            return [[[[request URL] absoluteString] stringByAppendingFormat:@"andThumbSize%fx%fScaleAspectFit", size.width, size.height] un_md5String];
            break;
            
        default:
            return [[[request URL] absoluteString] un_md5String];
            break;
    }
}


//! File cache implementation
@implementation UNFileCache
@synthesize cachePath;
//! dispatch queue for loading images from file
static dispatch_queue_t af_image_queue;
static dispatch_queue_t file_queue() {
    if (af_image_queue == NULL) {
        af_image_queue = dispatch_queue_create("com.uniprog.un-networking.file-cache", 0);
    }
    return af_image_queue;
}

- (id)init{
    
    self = [super init];
    if (self) {
        self.cachePath = [[NSHomeDirectory() stringByAppendingPathComponent:@"Library"]
                          stringByAppendingPathComponent:kUNFileCacheName];
        
        //! Create file cache path if necessray
        if (![[NSFileManager defaultManager] fileExistsAtPath:cachePath])
        {
            [[NSFileManager defaultManager] createDirectoryAtPath:cachePath 
                                      withIntermediateDirectories:YES 
                                                       attributes:nil 
                                                            error:nil];
        }
    }
    return self;
}

//! Return YES and begin asinc. loading image.
//! Return NO if image not exist.
- (BOOL)isCachedImageForRequest:(NSURLRequest*)request 
                        forSize:(CGSize)size 
                     sizePolicy:(UNImageSizePolicy)sizePolicy
                     withPolicy:(UNImageCachePolicy)policy
                      completed:(void(^)(NSURLRequest* request, CGSize size, UIImage* image))block{
    
    switch (policy) {
        case UNImageCachePolicyIgnoreCache:
        case UNImageCachePolicyMemoryCache:
            return NO;
        default:
            break;
    }
    
    NSString* fullFilePath = [cachePath stringByAppendingPathComponent:
                              UNFileCacheKeyFromURLRequest(request, size, sizePolicy)];
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:fullFilePath]){
        
        dispatch_async(file_queue(), ^{
            UIImage* image = [UIImage imageWithContentsOfFile:fullFilePath];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                if (block) {
                    block(request, size, image);
                }
            });
        });
        
        return YES;
    }
    return NO;
}


//! Method cache image if necessory
- (void)cacheImage:(UIImage*)image
        forRequest:(NSURLRequest*)request
        withPolicy:(UNImageCachePolicy)policy
           forSize:(CGSize)size
        sizePolicy:(UNImageSizePolicy)sizePolicy{
    
    switch (policy) {
        case UNImageCachePolicyIgnoreCache:
        case UNImageCachePolicyMemoryCache:
            return;
        default:
            break;
    }
    
    if (image && request) {
        NSString* fullFilePath = [cachePath stringByAppendingPathComponent:
                                  UNFileCacheKeyFromURLRequest(request, size, sizePolicy)];
        
        [UIImagePNGRepresentation(image) writeToFile:fullFilePath atomically:YES];
    }
}


//! Method remove all files from cache folder
- (void)removeAllFiles{
    
    NSFileManager* fileManager = [NSFileManager defaultManager];
    NSError* error = nil;
    
    NSArray* filesArray = [fileManager contentsOfDirectoryAtPath:cachePath error:&error];
    
    for (NSString* file in filesArray) {
        BOOL success = [fileManager removeItemAtPath:[NSString stringWithFormat:@"%@/%@", cachePath, file] error:&error];
        if (!success || error) {
            NSLog(@"Can't remove file when cleare file cache. Error = %@", error);
        }
    }
}

@end


#pragma mark -
#pragma mark  LoadOperation

//! Load image operation implementation.
@implementation LoadOperation
@synthesize request;
@synthesize connectionData;
@synthesize connection;
@synthesize response;
@synthesize successBlock, failureBlock, progressBlock, processingBlock;

- (void)dealloc
{
    //NSLog(@"LoadOperation DEALLOC");
}

- (id)initWithRequest:(NSURLRequest *)urlRequest{
    self = [super init];
    if (self) {
        self.request = urlRequest;
    }
    return self;
}

//! Background method
- (void)main {
    
    self.connectionData = [NSMutableData data];
    
    self.connection = [[NSURLConnection alloc] initWithRequest:self.request delegate:self startImmediately:NO];
    
    //! If request = nil or something wrong.
    if (connection == nil) {
        NSError* error = [[NSError alloc] initWithDomain:@"com.uniprog.un-networking.error" code:NSURLErrorBadURL userInfo:nil];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            
            if (self.failureBlock) {
                self.failureBlock(self, error);
            }
        });
    }
    
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [self.connection start];
    
    while (self.connection) {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
    }
}

#pragma mark -
#pragma mark  NSURLConnectionDelegate

- (void)connection:(NSURLConnection*)connection didReceiveResponse:(NSURLResponse*)_response{
    
    self.response = _response;
    [self.connectionData setLength:0];
}

-(void)connection:(NSURLConnection*)connection didReceiveData:(NSData*)data{
    
    [self.connectionData appendData:data];
    float progressValue = ((float) [self.connectionData length] / (float) self.response.expectedContentLength);
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progressBlock) {
            self.progressBlock(self, progressValue);
        }
    });
}


-(void)connectionDidFinishLoading:(NSURLConnection*)connection{
    
    UIImage* resImage = nil;
    
    //! Run processing block in background thread.
    if (self.processingBlock) {
        resImage = self.processingBlock(self, self.connectionData);
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.successBlock) {
            self.successBlock(self, resImage);
        }
    });
    
    self.connection = nil; 
    self.connectionData = nil;
    CFRunLoopWakeUp([[NSRunLoop currentRunLoop] getCFRunLoop]);// to test
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error{
    
    dispatch_async(dispatch_get_main_queue(), ^{
        
        if (self.failureBlock) {
            self.failureBlock(self, error);
        }
    });
    
    self.connection = nil;
    CFRunLoopWakeUp([[NSRunLoop currentRunLoop] getCFRunLoop]);// to test
}


- (NSCachedURLResponse *)connection:(NSURLConnection *)connection 
                  willCacheResponse:(NSCachedURLResponse *)cachedResponse 
{
    return nil;
}


//! Nil all callback blocks and cancel operation
- (void)cancel{
    self.successBlock = nil;
    self.failureBlock = nil;
    self.progressBlock = nil;
    self.connection = nil;
    CFRunLoopWakeUp([[NSRunLoop currentRunLoop] getCFRunLoop]);// to test
    [super cancel];
}

@end


#pragma mark -
#pragma mark  Additional categories
 
@implementation NSString (UN_MD5)

- (NSString *)un_md5String
{
	if ([self length] == 0) {
		return nil;
	}
	// Borrowed from: http://stackoverflow.com/questions/652300/using-md5-hash-on-a-string-in-cocoa
	const char *cStr = [self UTF8String];
	unsigned char result[16];
	CC_MD5(cStr, (CC_LONG)strlen(cStr), result);
	return [NSString stringWithFormat:@"%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X%02X",result[0], result[1], result[2], result[3], result[4], result[5], result[6], result[7],result[8], result[9], result[10], result[11],result[12], result[13], result[14], result[15]]; 	
}
@end


//! Category for resizing image
@implementation UIImage(UN_Resizing)

- (UIImage*)imageResizedToSize:(CGSize)size
    {
    // Check for Retina display and then double the size of image (we assume size is in points)
    if ([[UIScreen mainScreen] respondsToSelector: @selector(scale)])
    {
        CGFloat scale = [[UIScreen mainScreen] scale];
        
        size.width  *= scale;
        size.height *= scale;
    }

    // Create context on which image will be drawn
    UIGraphicsBeginImageContext(size);

    // Draw image on this context used provided size
    [self drawInRect: CGRectMake(0, 0, size.width, size.height)];

    // Convert context to an image
    UIImage* resizedImage = UIGraphicsGetImageFromCurrentImageContext();    

    // Remove context
    UIGraphicsEndImageContext();

    return resizedImage;
}

@end

