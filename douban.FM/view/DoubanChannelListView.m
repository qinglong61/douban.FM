//
//  DoubanChannelListView.m
//  douban.FM
//
//  Created by qinglun.duan on 14-6-10.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import "DoubanChannelListView.h"
#import "DoubanService.h"
#import "Constants.h"

#define FULLSIZE (NSViewMinXMargin | NSViewWidthSizable | NSViewMaxXMargin | NSViewMinYMargin | NSViewHeightSizable | NSViewMaxYMargin)

@implementation DoubanChannelListView
{
    NSOutlineView *_theOutlineView;
    NSArray *channels;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        
        channels = [[[DoubanService instance] fetchChannels] copy];
        
        NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, frameRect.size.width, frameRect.size.height)] autorelease];
        [scrollView setAutoresizingMask:FULLSIZE];
        [scrollView setHasVerticalScroller:YES];
        
        _theOutlineView = [[NSOutlineView alloc] initWithFrame:CGRectMake(0, 0, frameRect.size.width, frameRect.size.height)];
        [_theOutlineView setAutoresizesSubviews:FULLSIZE];
        [_theOutlineView setBackgroundColor:[NSColor lightGrayColor]];
        [_theOutlineView setGridColor:[NSColor darkGrayColor]];
        [_theOutlineView setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
        [_theOutlineView setUsesAlternatingRowBackgroundColors:YES];
        [_theOutlineView setAutosaveTableColumns:YES];
        [_theOutlineView setAllowsEmptySelection:YES];
        [_theOutlineView setAllowsColumnSelection:YES];
        [_theOutlineView setDataSource:self];
        [_theOutlineView setDelegate:self];
        [_theOutlineView setAutosaveName:@"channels"];
        [_theOutlineView setTarget:self];
        [_theOutlineView setDoubleAction:@selector(doubleClicked)];
        
        [self addColumn:@"channels"];
        
        [scrollView setDocumentView:_theOutlineView];
        [self addSubview:scrollView];
        
        [[DoubanService instance] addObserver:self forKeyPath:@"currentChannel" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [[DoubanService instance] removeObserver:self forKeyPath:@"currentChannel"];
    
    [channels release], channels = nil;
    [_theOutlineView release], _theOutlineView = nil;
    [super dealloc];
}

- (void)addColumn:(NSString*)title
{
	NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:title];
	[[column headerCell] setStringValue:title];
	[[column headerCell] setAlignment:NSCenterTextAlignment];
	[column setWidth:200.0];
	[column setMinWidth:50];
	[column setEditable:NO];
	[column setResizingMask:NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask];
	[_theOutlineView addTableColumn:column];
	[column release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"currentChannel"]) {
        [_theOutlineView reloadData];
        if ([[DoubanService instance].currentChannel.channelId isEqualToString:DOUBANFM_LIKED_CHANNEL]) {
            [_theOutlineView expandItem:channels[0]];
        }
    }
}

#pragma mark - NSOutlineViewDataSource

- (NSInteger)outlineView:(NSOutlineView *)outlineView numberOfChildrenOfItem:(id)item
{
    if (item == nil) {
        return channels.count;
    }
    return [(NSArray *)[item objectForKey:@"chls"] count];
}

- (id)outlineView:(NSOutlineView *)outlineView child:(NSInteger)index ofItem:(id)item
{
    if (item == nil) {
        return channels[index];
    }
    return [(NSArray *)[item objectForKey:@"chls"] objectAtIndex:index];
}

- (BOOL)outlineView:(NSOutlineView *)outlineView isItemExpandable:(id)item
{
    if ([item isKindOfClass:[DoubanChannel class]]) {
        return NO;
    }
    return YES;
}

- (id)outlineView:(NSOutlineView *)outlineView objectValueForTableColumn:(NSTableColumn *)tableColumn byItem:(id)item
{
    if ([item isKindOfClass:[DoubanChannel class]]) {
        return [(DoubanChannel *)item name];
    }
    return [item objectForKey:@"group_name"];
}

#pragma mark - NSOutlineViewDelegate

- (BOOL)outlineView:(NSOutlineView *)outlineView isGroupItem:(id)item
{
    return [item isKindOfClass:[DoubanChannel class]]?NO:YES;
}

- (CGFloat)outlineView:(NSOutlineView *)outlineView heightOfRowByItem:(id)item
{
    return 20.f;
}

- (NSView *)outlineView:(NSOutlineView *)outlineView viewForTableColumn:(NSTableColumn *)tableColumn item:(id)item
{
    NSTextField *textField = [[[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 100, 20)] autorelease];
    [textField setBordered:NO];
    
    if ([item isKindOfClass:[DoubanChannel class]]) {
        textField.stringValue = [(DoubanChannel *)item name];
        if (item == [DoubanService instance].currentChannel) {
            [textField setBackgroundColor:RGB(1, 0, 1, 0.2)];
        } else {
            [textField setBackgroundColor:[NSColor clearColor]];
        }
    } else {
        [item objectForKey:@"group_name"];
    }
    
    return textField;
}

#pragma mark - action

- (void)doubleClicked
{
    NSInteger selectedRow = [_theOutlineView selectedRow];
    if (selectedRow != -1) {
        id item = [_theOutlineView itemAtRow:selectedRow];
        if ([item isKindOfClass:[DoubanChannel class]]) {
            [[DoubanService instance] switchToChannel:(DoubanChannel *)item];
        }
    }
}

@end