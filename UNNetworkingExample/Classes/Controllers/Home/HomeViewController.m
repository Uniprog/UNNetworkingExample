//
//  HomeViewController.m
//  UNNetworkingExample
//
//  Created by Alexander Bukov on 7/28/12.
//  Copyright (c) 2012 Company. All rights reserved.
//

#import "HomeViewController.h"
#import "TestTableViewController.h"

@interface HomeViewController()
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *showTableViewButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIImageView *exampleImageView;
@end


@implementation HomeViewController
@synthesize showTableViewButton;
@synthesize exampleImageView;

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
    
    NSString* urlString = @"http://wallpaper.us.com/upload/DesktopWallpapers/cache/Smile-Wallpapers-animation-smile-cartoon-wallpaper-1920x1200.jpg";
    NSURLRequest* request = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString] 
                                             cachePolicy:NSURLRequestReloadIgnoringCacheData
                                         timeoutInterval:20];
    
    [self.exampleImageView setImageWithURLRequest:request
                                 placeholderImage:nil
                                     failureImage:[UIImage imageNamed:@"failed-big.png"]
                                 progressViewSize:CGSizeMake(exampleImageView.bounds.size.width - 20, 10)
                                progressViewStile:UIProgressViewStyleBar 
                                progressTintColor:[UIColor greenColor] 
                                   trackTintColor:[UIColor redColor] 
                                       sizePolicy:UNImageSizePolicyScaleAspectFit 
                                      cachePolicy:UNImageCachePolicyIgnoreCache
                                          success:^(NSURLRequest *request, NSHTTPURLResponse *response, UIImage *image) {
                                              [self.exampleImageView removeProgressView];
                                              NSLog(@"image size = %fx%f", image.size.width, image.size.height);
                                          } 
                                          failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error) {
                                              [self.exampleImageView removeProgressView];
                                          } 
                                         progress:^(NSURLRequest *request, NSHTTPURLResponse *response, float progress) {
                                             
                                         }];
}

- (void)viewDidUnload {
    [self setExampleImageView:nil];
    [self setShowTableViewButton:nil];
    [super viewDidUnload];
    
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 
	return YES;
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// - (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
// }

- (IBAction)showTableViewButtonClicked:(id)sender {
    
    TestTableViewController* testController = [TestTableViewController new];
    [self.navigationController pushViewController:testController animated:YES];
    
}

@end
