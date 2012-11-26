//
//  DVModalAuthViewController.m
//  Youtube
//
//  Created by Ilya Puchka on 27.11.12.
//  Copyright (c) 2012 Denivip. All rights reserved.
//

#import "DVModalAuthViewController.h"

@interface DVModalAuthViewController ()
@end

@implementation DVModalAuthViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(dismissViewController)];
    
    
    __weak id _self = self;
    self.popViewBlock = ^(void){
        [_self dismissViewController];
    };
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)dismissViewController
{
    [self dismissViewControllerAnimated:YES completion:NULL];
}

@end
