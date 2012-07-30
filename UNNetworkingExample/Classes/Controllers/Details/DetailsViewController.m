//
//  DetailsViewController.m
//  UNNetworkingExample
//
//  Created by Alexander Bukov on 7/28/12.
//  Copyright (c) 2012 Company. All rights reserved.
//

#import "DetailsViewController.h"

@interface DetailsViewController()
@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UILabel *sizeLabel;
@property (weak, nonatomic) IBOutlet UILabel *byteSizeLabel;

@property (strong, nonatomic) NSString* imageUrlString;

@end


@implementation DetailsViewController
@synthesize imageView;
@synthesize sizeLabel;
@synthesize byteSizeLabel;
@synthesize imageUrlString = _imageUrlString;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
}

- (void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:self.imageUrlString] 
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:20];

    
    [self.imageView setImageWithURLRequest:request 
                          placeholderImage:nil 
                              failureImage:nil 
                          progressViewSize:CGSizeMake(self.imageView.bounds.size.width - 20, 6) 
                         progressViewStile:UIProgressViewStyleDefault 
                         progressTintColor:nil
                            trackTintColor:nil 
                                sizePolicy:UNImageSizePolicyOriginalSize 
                               cachePolicy:UNImageCachePolicyIgnoreCache
                                   success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                       //[imageView removeProgressView];
                                       self.sizeLabel.text = [NSString stringWithFormat:@"%d x %d", (int)image.size.width, (int)image.size.height];
                                       NSData* imageData = UIImagePNGRepresentation(image);
                                       self.byteSizeLabel.text = [NSString stringWithFormat:@"%d", [imageData length]];
                                   } 
                                   failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                       [imageView removeProgressView];
                                   } 
                                  progress:nil];
}

- (void)viewDidUnload {
    [self setImageView:nil];
    [self setSizeLabel:nil];
    [self setByteSizeLabel:nil];
    [super viewDidUnload];
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 
	return YES;
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// - (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
// }


- (void)showImageFromUrlString:(NSString *)imageUrlString{
    _imageUrlString = imageUrlString;
}

@end
