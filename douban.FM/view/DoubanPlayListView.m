//
//  DoubanPlayListView.m
//  douban.FM
//
//  Created by qinglun.duan on 14-5-29.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import "DoubanPlayListView.h"
#import "DoubanService.h"

#define FULLSIZE (NSViewMinXMargin | NSViewWidthSizable | NSViewMaxXMargin | NSViewMinYMargin | NSViewHeightSizable | NSViewMaxYMargin)

@implementation DoubanPlayListView
{
    NSTableView *_theTableView;
    NSMutableArray *songs;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        
        NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, frameRect.size.width, frameRect.size.height)] autorelease];
        [scrollView setAutoresizingMask:FULLSIZE];
        [scrollView setHasVerticalScroller:YES];
        
        _theTableView = [[NSTableView alloc] initWithFrame:CGRectMake(0, 0, frameRect.size.width, frameRect.size.height)];
        [_theTableView setAutoresizesSubviews:FULLSIZE];
        [_theTableView setBackgroundColor:[NSColor lightGrayColor]];
        [_theTableView setGridColor:[NSColor darkGrayColor]];
        [_theTableView setGridStyleMask:NSTableViewSolidHorizontalGridLineMask];
        [_theTableView setUsesAlternatingRowBackgroundColors:YES];
        [_theTableView setAutosaveTableColumns:YES];
        [_theTableView setAllowsEmptySelection:YES];
        [_theTableView setAllowsColumnSelection:YES];
        [_theTableView setDataSource:self];
        [_theTableView setDelegate:self];
        [_theTableView setAutosaveName:@"playlist"];
        [_theTableView setTarget:self];
        [_theTableView setDoubleAction:@selector(doubleClicked)];
        
        [self addColumn:@"playlist"];
        
        [scrollView setDocumentView:_theTableView];
        [self addSubview:scrollView];
        
        [[DoubanService instance] addObserver:self forKeyPath:@"playlist" options:NSKeyValueObservingOptionNew context:NULL];
        [[DoubanService instance] addObserver:self forKeyPath:@"currentIndex" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [[DoubanService instance] removeObserver:self forKeyPath:@"playlist"];
    [[DoubanService instance] removeObserver:self forKeyPath:@"currentIndex"];
    
    [songs release], songs = nil;
    [_theTableView release], _theTableView = nil;
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
	[_theTableView addTableColumn:column];
	[column release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"playlist"]) {
        [songs release];
        songs = [[[DoubanService instance] playlist] mutableCopy];
        [_theTableView reloadData];
    } else if ([keyPath isEqualToString:@"currentIndex"]) {
        [_theTableView reloadData];
        [_theTableView scrollRowToVisible:[DoubanService instance].currentIndex-1];
    }
}

#pragma mark - NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [songs count];
}

#pragma mark - NSTableViewDelegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 20.f;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSParameterAssert(row >= 0 && row < [songs count]);
    NSTextField *textField = [[[NSTextField alloc] initWithFrame:CGRectMake(0, 0, 100, 20)] autorelease];
    [textField setBordered:NO];
    NSDictionary *song = [songs objectAtIndex:row];
	textField.stringValue = [song objectForKey:@"title"];
    
    if (row == [DoubanService instance].currentIndex-1) {
        [textField setBackgroundColor:RGB(1, 0, 1, 0.2)];
    } else {
        [textField setBackgroundColor:[NSColor clearColor]];
    }
    
    return textField;
}

- (void)tableViewSelectionDidChange:(NSNotification *)notification
{
    NSInteger selectedRow = [_theTableView selectedRow];
    if (selectedRow != -1) {
        [_theTableView scrollRowToVisible:selectedRow];
    }
}

#pragma mark - action

- (void)doubleClicked
{
    NSInteger selectedRow = [_theTableView selectedRow];
    if (selectedRow != -1) {
        [[DoubanService instance] playSongAtIndex:selectedRow];
    }
}

@end