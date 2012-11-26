//
//  GTLYouTubeVideoPlayer+ExtractVideoSrc.m
//  Youtube
//
//  Created by Ilya Puchka on 26.11.12.
//  Copyright (c) 2012 Denivip. All rights reserved.
//

#import "GTLYouTubeVideoPlayer+VideoSrc.h"

@implementation GTLYouTubeVideo (VideoSrc)

- (NSString *)videoSrc
{
    //extract url from player <iframe>
    NSError *_error = nil;
    
    NSString *regexpPattern = [NSString stringWithFormat:@"src='(.+?)(')"];
    
    NSRegularExpression *regexp = [NSRegularExpression regularExpressionWithPattern:regexpPattern options:NSRegularExpressionCaseInsensitive error:&_error];
    
    NSTextCheckingResult* result = [regexp firstMatchInString:self.player.embedHtml
                                                      options:0
                                                        range:NSMakeRange(0, self.player.embedHtml.length)];
    
    NSString *sourceURL;
    
    if (result) {
         sourceURL = [self.player.embedHtml substringWithRange:[result rangeAtIndex:1]];
    }
    
    return sourceURL;
}

@end
