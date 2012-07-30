//
//  TestTableViewController.m
//  UNNetworkingExample
//
//  Created by Alexander Bukov on 7/28/12.
//  Copyright (c) 2012 Company. All rights reserved.
//

#import "TestTableViewController.h"
#import "TestTableCell.h"
#import "DetailsViewController.h"

@interface TestTableViewController()

@property (weak, nonatomic) IBOutlet UITableView *testTableView;
@property (strong, nonatomic) NSArray* tableItemsArray;

@end


@implementation TestTableViewController

@synthesize testTableView;
@synthesize tableItemsArray;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        
        self.tableItemsArray = [NSArray array];

        //self.infoTableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
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
   
    NSString* dataPath = [[NSBundle mainBundle] pathForResource: @"RandomImagesUrl" ofType: @"plist"];
    
    NSDictionary* plistDictionary = [NSDictionary dictionaryWithContentsOfFile: dataPath];
    
    self.tableItemsArray = [plistDictionary allValues];

}

- (void)viewDidUnload {
    [self setTestTableView:nil];
    [super viewDidUnload];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
 
	return YES;
    //return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

// - (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
// }

#pragma mark - Table view data source
 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [self.tableItemsArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {

    static NSString *reusebleIdeintifier = @"TestTableCell";
    TestTableCell *cell = [tableView dequeueReusableCellWithIdentifier: reusebleIdeintifier];
    if (cell == nil)
    {
        cell = [[TestTableCell alloc] initWithStyle: UITableViewCellStyleDefault reuseIdentifier: reusebleIdeintifier];
    }
    
    // Configure the cell...
    
    [cell loadImageFromURLString:[tableItemsArray objectAtIndex:indexPath.row]];
    
    return cell;
}


#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    DetailsViewController* detailsController = [DetailsViewController new];
    
    [detailsController showImageFromUrlString:[tableItemsArray objectAtIndex:indexPath.row]];
    
    [self.navigationController pushViewController:detailsController animated:YES];
}


#pragma mark - Clear cache methods

//! Clear image memory cache
- (IBAction)clearMemoryButtonClicked:(id)sender {
    [UIImageView clearMemoryImageCache];
}

//! Clear image file cache
- (IBAction)clearFileButtonClicked:(id)sender {
    [UIImageView clearFileImageCache];
}

@end
