//
//  DVYoutubePlayerViewController.m
//  Youtube
//
//  Created by Ilya Puchka on 27.11.12.
//  Copyright (c) 2012 Denivip. All rights reserved.
//

#import "DVYoutubePlayerViewController.h"

@interface DVYoutubePlayerViewController ()

@end

@implementation DVYoutubePlayerViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.view.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
