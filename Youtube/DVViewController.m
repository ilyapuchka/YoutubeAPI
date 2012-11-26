//
//  DVViewController.m
//  Youtube
//
//  Created by Ilya Puchka on 26.11.12.
//  Copyright (c) 2012 Denivip. All rights reserved.
//

#import "DVViewController.h"
#import "GTMOAuth2ViewControllerTouch.h"
#import "GTMOAuth2Authentication.h"
#import "GTLYouTubeVideoPlayer+VideoSrc.h"
#import "DVModalAuthViewController.h"
#import "DVYoutubePlayerViewController.h"
#import "UIImageView+AFNetworking.h"

#define kKeychainItemName @"Youtube API Test: Google Key"
#define kClienID @""
#define kClientSecret @""
#define kYoutubeDeveloperKey (@"")

enum YoutubeAPICallsSections {
    YoutubeAPICallsSectionMyChannel,
    YoutubeAPICallsSectionMyPlaylists,
    YoutubeAPICallsSectionMySubscriptions,
    YoutubeAPICallsSectionMyFavoriteVideos,
    YoutubeAPICallsSectionMyUploadedVideos,
    YoutubeAPICallsSectionsCount
};

@interface DVViewController () 

@property (nonatomic, strong) GTLServiceYouTube *youtubeService;
@property (nonatomic, strong) UIBarButtonItem *signButton;
@property (nonatomic, strong) UIBarButtonItem *activityItem;

@property (nonatomic, strong) GTLYouTubeChannel *currentUserChannel;
@property (nonatomic, strong) NSArray *currentUserPlaylists;
@property (nonatomic, strong) NSArray *currentUserSubscriptions;
@property (nonatomic, strong) NSArray *currentUserFavorites;
@property (nonatomic, strong) NSArray *currentUserUploads;

@property (nonatomic) BOOL gotPlaylists;
@property (nonatomic) BOOL gotFavorites;
@property (nonatomic) BOOL gotSubscriptions;
@property (nonatomic) BOOL gotChannel;
@property (nonatomic) BOOL gotUploads;


- (IBAction)signButtonTapped:(id)sender;
- (IBAction)getChannelsTapped:(id)sender;

@end

@implementation DVViewController

- (UIBarButtonItem *)signButton
{
    return [[UIBarButtonItem alloc] initWithTitle:self.isSignedIn?@"Sign out":@"Sign in" style:UIBarButtonItemStyleBordered target:self action:@selector(signButtonTapped:)];

}

- (UIBarButtonItem *)activityItem
{
    if (!_activityItem) {
        UIActivityIndicatorView *activityIndicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 0, 35, 20)];
        _activityItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicator];
        [activityIndicator startAnimating];
    }
    return _activityItem;
}

- (GTLServiceYouTube *)youtubeService
{
    if (!_youtubeService) {
        _youtubeService = [[GTLServiceYouTube alloc] init];
        _youtubeService.retryEnabled = YES;
        _youtubeService.APIKey = kYoutubeDeveloperKey;
    }
    return _youtubeService;
}

- (void)setCurrentUserChannel:(GTLYouTubeChannel *)currentUserChannel
{
    _currentUserChannel = currentUserChannel;
    
    self.gotChannel = (currentUserChannel != nil);
    self.gotFavorites = self.gotPlaylists = self.gotUploads = self.gotSubscriptions = NO;
    self.currentUserFavorites = self.currentUserPlaylists = self.currentUserSubscriptions = self.currentUserUploads = nil;

    if (currentUserChannel) {
        
        [self.tableView beginUpdates];
        
        [self getUserFavoritesOnCompletion:NULL];
        [self getUserUploadsVideosOnCompletion:NULL];
        [self getSubscriptionsOnCompletion:NULL];
        [self getPlaylistsOnCompletion:NULL];
    }
    
}

- (void)setGotChannel:(BOOL)gotChannel
{
    if (_gotChannel ^ gotChannel) {
        _gotChannel = gotChannel;
        if (gotChannel) {
            [self updateTableViewIfNeeded];
        }
        else {
            [self.tableView reloadData];
        }
    }
}

- (void)setGotFavorites:(BOOL)gotFavorites
{
    if (_gotFavorites ^ gotFavorites) {
        _gotFavorites = gotFavorites;
        if (gotFavorites) {
            [self updateTableViewIfNeeded];
        }
    }
}

- (void)setGotPlaylists:(BOOL)gotPlaylists
{
    if (_gotPlaylists ^ gotPlaylists) {
        _gotPlaylists = gotPlaylists;
        if (gotPlaylists) {
            [self updateTableViewIfNeeded];
        }
    }
}

- (void)setGotSubscriptions:(BOOL)gotSubscriptions
{
    if (_gotSubscriptions ^ gotSubscriptions) {
        _gotSubscriptions = gotSubscriptions;
        if (gotSubscriptions) {
            [self updateTableViewIfNeeded];
        }
    }
}

- (void)setGotUploads:(BOOL)gotUploads
{
    if (_gotUploads^ gotUploads) {
        _gotUploads = gotUploads;
        if (gotUploads) {
            [self updateTableViewIfNeeded];
        }
    }
}

- (void)updateTableViewIfNeeded
{
    if (self.gotChannel &&
        self.gotFavorites &&
        self.gotPlaylists &&
        self.gotSubscriptions &&
        self.gotUploads) {
        
        self.navigationItem.rightBarButtonItem = nil;
        [self.tableView endUpdates];
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    self.navigationItem.backBarButtonItem =
    [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                     style:UIBarButtonItemStyleBordered
                                    target:nil
                                    action:nil];

    GTMOAuth2Authentication *auth;
    auth = [GTMOAuth2ViewControllerTouch authForGoogleFromKeychainForName:kKeychainItemName
                                                                 clientID:kClienID
                                                             clientSecret:kClientSecret];
    
    self.youtubeService.authorizer = auth;
    
    [self updateUI];
    
    [self authUserIfNeeded];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - TableView DataSource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return YoutubeAPICallsSectionsCount;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case YoutubeAPICallsSectionMyFavoriteVideos:
            return self.currentUserFavorites.count;
            break;

        case YoutubeAPICallsSectionMyUploadedVideos:
            return self.currentUserUploads.count;
            break;

        case YoutubeAPICallsSectionMyPlaylists:
            return self.currentUserPlaylists.count;
            break;

        case YoutubeAPICallsSectionMySubscriptions:
            return self.currentUserSubscriptions.count;
            break;

        default:
            return self.currentUserChannel?1:0;
            break;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case YoutubeAPICallsSectionMyFavoriteVideos:
            return @"My favorites";
            break;
            
        case YoutubeAPICallsSectionMyUploadedVideos:
            return @"My uploads";
            break;
            
        case YoutubeAPICallsSectionMyPlaylists:
            return @"My playlists";
            break;
            
        case YoutubeAPICallsSectionMySubscriptions:
            return @"My subscriptions";
            break;
            
        default:
            return @"My channel";
            break;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Cell"];
    }

    switch (indexPath.section) {
            
        case YoutubeAPICallsSectionMyFavoriteVideos:
        {
            GTLYouTubeVideo *video = self.currentUserFavorites[indexPath.row];
            
            cell.textLabel.text = video.snippet.title;
            cell.detailTextLabel.text = video.snippet.descriptionProperty;
            
            GTLYouTubeThumbnail *thumbnail = [video.snippet.thumbnails additionalPropertyForName:@"default"];
                
            NSURL *imageURL = [NSURL URLWithString:thumbnail.url];
            [[AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:imageURL] success:^(UIImage *image) {
                cell.imageView.image = image;
                [cell setNeedsLayout];
            }] start];
        }
            break;
        
        case YoutubeAPICallsSectionMyUploadedVideos:
        {
            GTLYouTubeVideo *video = self.currentUserUploads[indexPath.row];
            
            cell.textLabel.text = video.snippet.title;
            cell.detailTextLabel.text = video.snippet.descriptionProperty;
            
            GTLYouTubeThumbnail *thumbnail = [video.snippet.thumbnails additionalPropertyForName:@"default"];
            
            NSURL *imageURL = [NSURL URLWithString:thumbnail.url];
            [[AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:imageURL] success:^(UIImage *image) {
                cell.imageView.image = image;
                [cell setNeedsLayout];
            }] start];

        }
            break;
            
        case YoutubeAPICallsSectionMySubscriptions:
        {
            GTLYouTubeSubscription *subscription = self.currentUserSubscriptions[indexPath.row];
            
            cell.textLabel.text = subscription.snippet.title;
            cell.detailTextLabel.text = subscription.snippet.descriptionProperty;
            
            [self getChannel:[subscription.snippet.resourceId additionalPropertyForName:@"channelId"] onCompletion:^(GTLYouTubeChannelListResponse *response) {
                GTLYouTubeChannel *channel = response.items.lastObject;
                
                GTLYouTubeThumbnail *thumbnail = [channel.snippet.thumbnails additionalPropertyForName:@"default"];
                
                NSURL *imageURL = [NSURL URLWithString:thumbnail.url];
                [[AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:imageURL] success:^(UIImage *image) {
                    cell.imageView.image = image;
                    [cell setNeedsLayout];
                }] start];

            }];
        }
            break;
            
        case YoutubeAPICallsSectionMyPlaylists:
        {
            GTLYouTubePlaylist *playlist = self.currentUserPlaylists[indexPath.row];
            
            cell.textLabel.text = playlist.snippet.title;
            cell.detailTextLabel.text = playlist.snippet.descriptionProperty;
            
            GTLYouTubeThumbnail *thumbnail = [playlist.snippet.thumbnails additionalPropertyForName:@"default"];
            
            NSURL *imageURL = [NSURL URLWithString:thumbnail.url];
            [[AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:imageURL] success:^(UIImage *image) {
                cell.imageView.image = image;
                [cell setNeedsLayout];
            }] start];
        }
            break;
            
        default:
            cell.textLabel.text = self.currentUserChannel.snippet.title;
            cell.detailTextLabel.text = self.currentUserChannel.snippet.descriptionProperty;
            
            GTLYouTubeThumbnail *thumbnail = [self.currentUserChannel.snippet.thumbnails additionalPropertyForName:@"default"];
            
            NSURL *imageURL = [NSURL URLWithString:thumbnail.url];
            [[AFImageRequestOperation imageRequestOperationWithRequest:[NSURLRequest requestWithURL:imageURL] success:^(UIImage *image) {
                cell.imageView.image = image;
                [cell setNeedsLayout];
            }] start];
            
            break;
    }
    
    return cell;
}

#pragma mark - TableView Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case YoutubeAPICallsSectionMyUploadedVideos:
        case YoutubeAPICallsSectionMyFavoriteVideos:
        {
            GTLYouTubePlaylistItem *playlistItem;
            if (indexPath.section == YoutubeAPICallsSectionMyFavoriteVideos) {
                playlistItem = self.currentUserFavorites[indexPath.row];
            }
            else {
                playlistItem = self.currentUserUploads[indexPath.row];
            }
            
            [self playVideoWithID:playlistItem.contentDetails.videoId];
        }
            break;
            
        default:
            break;
    }
}


- (void)signButtonTapped:(id)sender {
    if (![self isSignedIn]) {
        [self authUserIfNeeded];
    }
    else {
        [GTMOAuth2ViewControllerTouch removeAuthFromKeychainForName:kKeychainItemName];
        self.youtubeService.authorizer = nil;
        self.currentUserChannel = nil;
        self.gotChannel = NO;
        [self updateUI];
    }
}

- (NSString *)signedInUsername
{
    GTMOAuth2Authentication *auth = self.youtubeService.authorizer;
    BOOL isSignedIn = auth.canAuthorize;
    if (isSignedIn) {
        return auth.userEmail;
    } else {
        return nil;
    }
}

- (BOOL)isSignedIn {
    NSString *name = [self signedInUsername];
    return (name != nil);
}

- (void)updateUI
{
    self.navigationItem.leftBarButtonItem = self.signButton;
    self.title = self.signedInUsername;
    [self.tableView reloadData];
}

- (void)authUserIfNeeded
{
    self.navigationItem.rightBarButtonItem = self.activityItem;
    
    if (self.isSignedIn) {
        [self getUserChannel];
        [self updateUI];
        return;
    }
    
    self.navigationItem.rightBarButtonItem = self.activityItem;
    
    DVModalAuthViewController *authViewController =
    [[DVModalAuthViewController alloc] initWithScope:kGTLAuthScopeYouTube
                                               clientID:kClienID
                                           clientSecret:kClientSecret
                                       keychainItemName:kKeychainItemName
                                      completionHandler:^(GTMOAuth2ViewControllerTouch *viewController, GTMOAuth2Authentication *auth, NSError *error) {
                                          
                                          self.navigationItem.rightBarButtonItem = nil;
                                          
                                          if (!error) {
                                              self.youtubeService.authorizer = auth;
                                              
                                              [self getUserChannel];
                                          }
                                          else {
                                              
                                              self.youtubeService.authorizer = nil;
                                              
                                              NSLog(@"Authentication error: %@", error);
                                              NSData *responseData = [[error userInfo] objectForKey:@"data"]; // kGTMHTTPFetcherStatusDataKey
                                              if ([responseData length] > 0) {
                                                  // show the body of the server's authentication failure response
                                                  NSString *str = [[NSString alloc] initWithData:responseData
                                                                                        encoding:NSUTF8StringEncoding];
                                                  NSLog(@"%@", str);
                                              }

                                              
                                          }
                                          
                                          [self updateUI];
                                          
                                      }];
    
    NSString *html = @"<html><body bgcolor=white><div align=center>Loading sign-in page...</div></body></html>";
    authViewController.initialHTMLString = html;

    [self.navigationController presentViewController:[[UINavigationController alloc] initWithRootViewController:authViewController] animated:YES completion:NULL];
}

- (void)embedYouTubeVideo:(NSString *)urlString toWebView:(UIWebView *)webView{
	NSString *embedHTML = @"\
    <html>\
    <head>\
    <style type=\"text/css\">\
    iframe {position:absolute; top:50%%; margin-top:-130px;}\
    body {background-color:#000; margin:0;}\
    </style>\
    </head>\
    <body>\
    <iframe width=\"100%%\" height=\"240px\" src=\"%@\" frameborder=\"0\" allowfullscreen></iframe>\
    </body>\
    </html>";
	NSString *html = [NSString stringWithFormat:embedHTML, urlString];
	[webView loadHTMLString:html baseURL:nil];
}


#pragma mark - API methods


- (void)getActivity
{
    GTLQueryYouTube *videoQuery = [GTLQueryYouTube queryForActivitiesListWithPart:@"id, snippet, contentDetails"];
    
    videoQuery.home = @"TRUE";
    videoQuery.maxResults = 10;
    
    
    [self.youtubeService executeQuery:videoQuery
                    completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeActivityListResponse *object, NSError *error) {
                        NSArray *activityItems = object.items;
                        GTLYouTubeActivity *activity = activityItems.lastObject;
                        [activityItems enumerateObjectsUsingBlock:^(GTLYouTubeActivity *activity, NSUInteger idx, BOOL *stop) {
                            NSLog(@"activity title: %@", activity.snippet.title);
                        }];
                    }];
}

- (void)getUserChannel
{
    GTLQueryYouTube *videoQuery = [GTLQueryYouTube queryForChannelsListWithPart:@"id, snippet, contentDetails"];
    
    videoQuery.mine = YES;
    
    [self.youtubeService executeQuery:videoQuery
                    completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeChannelListResponse *object, NSError *error) {
                        self.currentUserChannel = object.items.lastObject;
                        
                        [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:0 inSection:YoutubeAPICallsSectionMyChannel]] withRowAnimation:UITableViewRowAnimationNone];
                    }];

}

- (void)getChannel:(NSString *)channelId onCompletion:(void(^)(GTLYouTubeChannelListResponse *response))completion
{
    if (!channelId) {
        [self getUserChannel];
        return;
    }

    GTLQueryYouTube *videoQuery = [GTLQueryYouTube queryForChannelsListWithPart:@"id, snippet, contentDetails"];
    
    videoQuery.identifier = channelId;
    
    [self.youtubeService executeQuery:videoQuery
                    completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeChannelListResponse *object, NSError *error) {
                        if (completion) completion(object);
                    }];

}

- (void)getPlaylistsOnCompletion:(void(^)(void))completion
{
    GTLQueryYouTube *videoQuery = [GTLQueryYouTube queryForPlaylistsListWithPart:@"id, snippet"];
    
    videoQuery.mine = YES;
    videoQuery.maxResults = 50;
    
    [self.youtubeService executeQuery:videoQuery
                    completionHandler:^(GTLServiceTicket *ticket, GTLYouTubePlaylistListResponse *object, NSError *error) {
                        self.currentUserPlaylists = object.items;
                        
                        NSMutableArray *indexPaths = [@[] mutableCopy];
                        
                        for (int i = 0; i<self.currentUserPlaylists.count; i++) {
                            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:YoutubeAPICallsSectionMyPlaylists]];
                        }
                        
                        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                        
                        self.gotPlaylists = YES;
                        
                        if (completion) completion();
                        
                    }];
}

- (void)getSubscriptionsOnCompletion:(void(^)(void))completion
{
    GTLQueryYouTube *videoQuery = [GTLQueryYouTube queryForSubscriptionsListWithPart:@"id, snippet, contentDetails"];
    
    videoQuery.mine = YES;
    videoQuery.maxResults = 50;
    
    [self.youtubeService executeQuery:videoQuery
                    completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeSubscriptionListResponse *object, NSError *error) {
                        self.currentUserSubscriptions = object.items;
                        
                        NSMutableArray *indexPaths = [@[] mutableCopy];
                        
                        for (int i = 0; i<self.currentUserSubscriptions.count; i++) {
                            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:YoutubeAPICallsSectionMySubscriptions]];
                        }
                        
                        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                        
                        self.gotSubscriptions = YES;
                        
                        if (completion) completion();
                        
                    }];
}

- (void)playVideoWithID:(NSString *)videoId
{
    GTLQueryYouTube *videoQuery = [GTLQueryYouTube queryForVideosListWithIdentifier:videoId
                                                                               part:@"player"];
    
    [self.youtubeService executeQuery:videoQuery
                    completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeVideoListResponse *videoList, NSError *error){
                        
                        GTLYouTubeVideo *video = videoList.items.lastObject;
                        
                        DVYoutubePlayerViewController *playerViewController = [[DVYoutubePlayerViewController alloc] init];
                        
                        [self embedYouTubeVideo:video.videoSrc toWebView:playerViewController.webView];
                        
                        [self.navigationController pushViewController:playerViewController animated:YES];
                    }];
}

- (void)getUserUploadsVideosOnCompletion:(void (^)(void))completion
{
    GTLQueryYouTube *videoQuery = [GTLQueryYouTube queryForPlaylistItemsListWithPart:@"id, snippet, contentDetails"];
    
    videoQuery.playlistId = self.currentUserChannel.contentDetails.relatedPlaylists.uploads;
    videoQuery.maxResults = 50;
    
    [self.youtubeService executeQuery:videoQuery
                    completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeVideoListResponse *object, NSError *error) {
                        self.currentUserUploads = object.items;
                        NSMutableArray *indexPaths = [@[] mutableCopy];
                        
                        for (int i = 0; i<self.currentUserUploads.count; i++) {
                            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:YoutubeAPICallsSectionMyUploadedVideos]];
                        }
                        
                        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                        
                        self.gotUploads = YES;
                        
                        if (completion) completion();
                    }];

}

- (void)getUserFavoritesOnCompletion:(void (^)(void))completion
{
    GTLQueryYouTube *videoQuery = [GTLQueryYouTube queryForPlaylistItemsListWithPart:@"id, snippet, contentDetails"];
    
    videoQuery.playlistId = self.currentUserChannel.contentDetails.relatedPlaylists.favorites;
    videoQuery.maxResults = 50;
    
    [self.youtubeService executeQuery:videoQuery
                    completionHandler:^(GTLServiceTicket *ticket, GTLYouTubeVideoListResponse *object, NSError *error) {
                        self.currentUserFavorites = object.items;
                        
                        NSMutableArray *indexPaths = [@[] mutableCopy];
                        
                        for (int i = 0; i<self.currentUserFavorites.count; i++) {
                            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:YoutubeAPICallsSectionMyFavoriteVideos]];
                        }
                        
                        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationNone];
                        
                        self.gotFavorites = YES;
                        
                        if (completion) completion();

                    }];
    
}

@end
