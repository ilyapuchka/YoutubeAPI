//
//  DVContentViewController.m
//  Youtube
//
//  Created by Ilya Puchka on 27.11.12.
//  Copyright (c) 2012 Denivip. All rights reserved.
//

#import "DVContentViewController.h"

@interface DVContentViewController ()

@end

@implementation DVContentViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"ContentCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    id item = self.items[indexPath.row];
    
    if ([item isKindOfClass:[GTLYouTubeChannel class]]) {
        GTLYouTubeChannel *channel = (GTLYouTubeChannel *)item;
        cell.textLabel.text = channel.snippet.title;
        cell.detailTextLabel.text = channel.snippet.descriptionProperty;
        
        [channel.snippet.thumbnails.additionalProperties enumerateKeysAndObjectsUsingBlock:^(id key, GTLYouTubeThumbnail *thumbnail, BOOL *stop) {
            
            cell.imageView.image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:thumbnail.url]]];
        }];
        
        NSDictionary *json = channel.JSON;
        
    }
    else if ([item isKindOfClass:[GTLYouTubePlaylist class]]) {
        
    }
    else if ([item isKindOfClass:[GTLYouTubeVideo class]]) {
        
    }
    else if ([item isKindOfClass:[GTLYouTubeSubscription class]]) {
        
    }
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

@end
