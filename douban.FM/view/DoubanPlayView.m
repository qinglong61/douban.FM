//
//  DoubanPlayView.m
//  douban.FM
//
//  Created by qinglun.duan on 14-5-29.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import "DoubanPlayView.h"
#import "DoubanService.h"
#import "DoubanFMUtilities.h"
#import "DoubanDownloader.h"
#import "DoubanWindow.h"

static void *currentTimeContext = &currentTimeContext;
static void *currentSongLikedContext = &currentSongLikedContext;
static void *AVSPPlayerItemStatusContext = &AVSPPlayerItemStatusContext;
static void *AVSPPlayerRateContext = &AVSPPlayerRateContext;

static void *DownloadingContext = &DownloadingContext;
static void *DownloadProgressContext = &DownloadProgressContext;
static void *IsIndeterminateContext = &IsIndeterminateContext;

@implementation NSControl (target_action)

- (void)setTarget:(id)anObject action:(SEL)aSelector
{
    [self setTarget:anObject];
    [self setAction:aSelector];
}

@end

@implementation DoubanPlayView
{
    NSButton *pauseBtn;
    NSButton *replayBtn;
    NSButton *nextBtn;
    NSButton *likeBtn;
    
    NSTextField *searchTextField;
    NSButton *searchBtn;
    
    NSSlider *rateSlider;
    NSTextField *rateLbl;
    
    NSSlider *timeSlider;
    NSTextField *timeLbl;
    
    NSSlider *volumeSlider;
    NSTextField *volumeLbl;
    
    NSProgressIndicator *progressBar;
    
    double currentTime;
    double duration;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        
        pauseBtn = [[[NSButton alloc] initWithFrame:CGRectMake(130, 10, 100, 40)] autorelease];
        [self addSubview:pauseBtn];
        [pauseBtn setTarget:self action:@selector(pauseOrResume:)];
        [pauseBtn setTitle:@"play"];
        
        replayBtn = [[[NSButton alloc] initWithFrame:CGRectMake(250, 10, 100, 40)] autorelease];
        [self addSubview:replayBtn];
        [replayBtn setTarget:self action:@selector(rePlay:)];
        [replayBtn setTitle:@"replay"];
        [replayBtn setEnabled:NO];
        
        nextBtn = [[[NSButton alloc] initWithFrame:CGRectMake(370, 10, 100, 40)] autorelease];
        [self addSubview:nextBtn];
        [nextBtn setTarget:self action:@selector(next:)];
        [nextBtn setTitle:@"next"];
        [nextBtn setEnabled:NO];
        
        likeBtn = [[[NSButton alloc] initWithFrame:CGRectMake(490, 10, 100, 40)] autorelease];
        [self addSubview:likeBtn];
        [likeBtn setTarget:self action:@selector(like:)];
        [likeBtn setTitle:@"like"];
        [likeBtn setEnabled:NO];
        
        rateSlider = [[[NSSlider alloc] initWithFrame:CGRectMake(610, 10, 180, 30)] autorelease];
        [self addSubview:rateSlider];
        [rateSlider setMaxValue:3.0];
        [rateSlider setMinValue:-3.0];
        [rateSlider setDoubleValue:0.0];
        [rateSlider setTarget:self action:@selector(rateSliderValueChanged)];
        
        rateLbl = [[[NSTextField alloc] initWithFrame:CGRectMake(800, 10, 100, 30)] autorelease];
        [rateLbl setBezeled:NO];
        [rateLbl setDrawsBackground:NO];
        [rateLbl setEditable:NO];
        [rateLbl setSelectable:NO];
        [self addSubview:rateLbl];
        rateLbl.stringValue = @"100%";
        
        searchTextField = [[[NSTextField alloc] initWithFrame:CGRectMake(950, 10, 100, 40)] autorelease];
        [self addSubview:searchTextField];
        
        searchBtn = [[[NSButton alloc] initWithFrame:CGRectMake(1090, 10, 100, 40)] autorelease];
        [self addSubview:searchBtn];
        [searchBtn setTarget:self action:@selector(search:)];
        [searchBtn setTitle:@"search"];
        
        timeSlider = [[[NSSlider alloc] initWithFrame:CGRectMake(100, 150, 1000, 30)] autorelease];
        [self addSubview:timeSlider];
        [timeSlider setTarget:self action:@selector(timeSliderValueChanged)];
        
        volumeSlider = [[[NSSlider alloc] initWithFrame:CGRectMake(10, 10, 30, 180)] autorelease];
        [self addSubview:volumeSlider];
        [volumeSlider setMaxValue:1.0];
        [volumeSlider setMinValue:0.0];
        [volumeSlider setTarget:self action:@selector(volumeSliderValueChanged)];
        
        timeLbl = [[[NSTextField alloc] initWithFrame:CGRectMake(1100, 150, 100, 30)] autorelease];
        [timeLbl setBezeled:NO];
        [timeLbl setDrawsBackground:NO];
        [timeLbl setEditable:NO];
        [timeLbl setSelectable:NO];
        [self addSubview:timeLbl];
        
        volumeLbl = [[[NSTextField alloc] initWithFrame:CGRectMake(50, 10, 100, 30)] autorelease];
        [volumeLbl setBezeled:NO];
        [volumeLbl setDrawsBackground:NO];
        [volumeLbl setEditable:NO];
        [volumeLbl setSelectable:NO];
        [self addSubview:volumeLbl];
        
        progressBar = [[[NSProgressIndicator alloc] initWithFrame:CGRectMake(100, 100, 1000, 30)] autorelease];
        [self addSubview:progressBar];
        progressBar.maxValue = 1.0;
        [progressBar setHidden:YES];
        
        [[DoubanService instance] addObserver:self forKeyPath:@"currentTime" options:NSKeyValueObservingOptionNew context:currentTimeContext];
        [[DoubanService instance] addObserver:self forKeyPath:@"currentSong.liked" options:NSKeyValueObservingOptionNew context:currentSongLikedContext];
        [[DoubanService instance] addObserver:self forKeyPath:@"player.rate" options:NSKeyValueObservingOptionNew context:AVSPPlayerRateContext];
        [[DoubanService instance] addObserver:self forKeyPath:@"player.currentItem.status" options:NSKeyValueObservingOptionNew context:AVSPPlayerItemStatusContext];
        
        [[DoubanDownloader instance] addObserver:self forKeyPath:@"downloading" options:NSKeyValueObservingOptionNew context:DownloadingContext];
        [[DoubanDownloader instance] addObserver:self forKeyPath:@"downloadProgress" options:NSKeyValueObservingOptionNew context:DownloadProgressContext];
        [[DoubanDownloader instance] addObserver:self forKeyPath:@"downloadIsIndeterminate" options:NSKeyValueObservingOptionNew context:IsIndeterminateContext];
    }
    return self;
}

- (void)dealloc
{
    [[DoubanService instance] removeObserver:self forKeyPath:@"currentTime"];
    [[DoubanService instance] removeObserver:self forKeyPath:@"currentSong.liked"];
    [[DoubanService instance] removeObserver:self forKeyPath:@"player.rate"];
    [[DoubanService instance] removeObserver:self forKeyPath:@"player.currentItem.status"];
    [[DoubanDownloader instance] removeObserver:self forKeyPath:@"downloading"];
    [[DoubanDownloader instance] removeObserver:self forKeyPath:@"downloadProgress"];
    [[DoubanDownloader instance] removeObserver:self forKeyPath:@"downloadIsIndeterminate"];
    
    [super dealloc];
}

- (void)drawRect:(NSRect)dirtyRect
{
	[super drawRect:dirtyRect];
    
    [[NSColor lightGrayColor] set];
    NSRectFill(dirtyRect);
}

- (void)rePlay:(id)sender
{
    [[DoubanService instance] seekToTime:0.f];
    [[DoubanService instance].player play];
}

- (void)pauseOrResume:(id)sender
{
    if (![DoubanService instance].playlist && [DoubanService instance].player.rate == 0) {
        [[DoubanService instance] startPlay];
        volumeSlider.doubleValue = 0.5;
        [DoubanService instance].player.volume = 0.5;
        volumeLbl.stringValue = [NSString stringWithFormat:@"%d%%", (int)ceil(volumeSlider.doubleValue * 100)];
    } else {
        if ([DoubanService instance].player.rate != 1.f) {
            pauseBtn.title = @"pause";
            if ([[DoubanService instance] currentTime] == [[DoubanService instance] duration])
                [[DoubanService instance] seekToTime:0.f];
            [[DoubanService instance].player play];
        } else {
            pauseBtn.title = @"resume";
            [[DoubanService instance].player pause];
        }
    }
}

- (void)next:(id)sender
{
    [[DoubanService instance] switchPlaylist];
}

- (void)like:(id)sender
{
    if ([likeBtn.title isEqualToString:@"like"]) {
        [[DoubanService instance] redHeart];
    } else if ([likeBtn.title isEqualToString:@"unlike"]) {
        [[DoubanService instance] unRedHeart];
    }
}

- (void)search:(id)sender
{
    if (searchTextField.stringValue) {
        [[DoubanService instance] searchSong:searchTextField.stringValue];
    }
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	if (context == AVSPPlayerItemStatusContext) {
		AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
		BOOL enable = NO;
		switch (status) {
			case AVPlayerItemStatusUnknown:
				break;
			case AVPlayerItemStatusReadyToPlay:
				enable = YES;
				break;
			case AVPlayerItemStatusFailed:
				break;
		}
        duration = [[DoubanService instance] duration];
        [[DoubanService instance].player play];
        [pauseBtn setEnabled:enable];
        [replayBtn setEnabled:enable];
        [nextBtn setEnabled:enable];
        [likeBtn setEnabled:enable];
	} else if (context == AVSPPlayerRateContext) {
		float rate = [[change objectForKey:NSKeyValueChangeNewKey] floatValue];
		if (rate != 1.f) {
			[pauseBtn setTitle:@"Play"];
        } else {
			[pauseBtn setTitle:@"Pause"];
        }
    } else if (context == currentSongLikedContext) {
        BOOL liked = [[change objectForKey:NSKeyValueChangeNewKey] boolValue];
        if (liked) {
            [likeBtn setTitle:@"unlike"];
            [[likeBtn cell] setBackgroundColor:[NSColor controlColor]];
        } else {
            [likeBtn setTitle:@"like"];
            [[likeBtn cell] setBackgroundColor:[NSColor redColor]];
        }
	} else if (context == currentTimeContext) {
        currentTime = [DoubanService instance].currentTime;
        timeSlider.doubleValue = currentTime / duration;
        timeLbl.stringValue = [NSString stringWithFormat:@"%@ / %@", [self textFromTime:currentTime], [self textFromTime:duration]];
    } else if (context == DownloadingContext) {
        if ([DoubanDownloader instance].downloading) {
            [progressBar setHidden:NO];
            [progressBar startAnimation:nil];
        } else {
            [progressBar stopAnimation:nil];
            [progressBar setHidden:YES];
        }
    } else if (context == DownloadProgressContext) {
        progressBar.doubleValue = [DoubanDownloader instance].downloadProgress;
    } else if (context == IsIndeterminateContext) {
        [progressBar setIndeterminate:[DoubanDownloader instance].downloadIsIndeterminate];
    } else {
		[super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
	}
}

- (void)timeSliderValueChanged
{
    [[DoubanService instance] seekToTime:timeSlider.doubleValue * duration];
}

- (void)volumeSliderValueChanged
{
    [DoubanService instance].player.volume = volumeSlider.doubleValue;
    volumeLbl.stringValue = [NSString stringWithFormat:@"%d%%", (int)ceil(volumeSlider.doubleValue * 100)];
}

- (void)rateSliderValueChanged
{
    if (rateSlider.doubleValue >= 0) {
        [DoubanService instance].player.rate = rateSlider.doubleValue + 1.0;
    } else {
        [DoubanService instance].player.rate = 1.0 / ((-1.0)*rateSlider.doubleValue + 1.0);
    }
    rateLbl.stringValue = [NSString stringWithFormat:@"%d%%", (int)ceil([DoubanService instance].player.rate * 100)];
}

- (NSString *)textFromTime:(double)seconds
{
    int intSeconds = (int)ceil(seconds);
    return [NSString stringWithFormat:@"%d:%@", intSeconds/60, intSeconds%60 > 9 ? [NSString stringWithFormat:@"%d", intSeconds%60] : [NSString stringWithFormat:@"0%d", intSeconds%60]];
}

@end