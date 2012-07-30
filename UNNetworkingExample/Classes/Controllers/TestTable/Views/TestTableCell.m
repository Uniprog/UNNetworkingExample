//
//  TestTableCell.m
//  UNNetworkingExample
//
//  Created by Alexander Bukov on 7/28/12.
//  Copyright (c) 2012 Company. All rights reserved.
//

#import "TestTableCell.h"


@interface TestTableCell()
@property (weak, nonatomic) IBOutlet UIImageView *testImageView;
@property (weak, nonatomic) IBOutlet UILabel *urlLabel;
@end


@implementation TestTableCell
@synthesize testImageView;
@synthesize urlLabel = _urlLabel;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    NSArray *xibArray = [[NSBundle mainBundle] loadNibNamed: @"TestTableCell" owner: self options: nil];
    self = [xibArray lastObject];
    return self;
}


- (void)loadImageFromURLString:(NSString*)imageURLString{
    
    self.urlLabel.text = imageURLString;
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:imageURLString] 
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:20];

    
    [self.testImageView setImageWithURLRequest:request 
                              placeholderImage:nil 
                                  failureImage:nil 
                              progressViewSize:CGSizeMake(35, 4) 
                             progressViewStile:UIProgressViewStyleBar 
                             progressTintColor:[UIColor greenColor] 
                                trackTintColor:[UIColor redColor] 
                                    sizePolicy:UNImageSizePolicyScaleAspectFit 
                                   cachePolicy:UNImageCachePolicyMemoryAndFileCache 
                                       success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                           
                                       } 
                                       failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                           
                                       } 
                                      progress:^(NSURLRequest *request, NSHTTPURLResponse *response, float progress) {
                                          
                                      }];
}


@end
