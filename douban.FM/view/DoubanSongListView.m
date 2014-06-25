//
//  DoubanSongListView.m
//  douban.FM
//
//  Created by qinglun.duan on 14-5-29.
//  Copyright (c) 2014年 duan.qinglun. All rights reserved.
//

#import "DoubanSongListView.h"
#import "DoubanService.h"

#define FULLSIZE (NSViewMinXMargin | NSViewWidthSizable | NSViewMaxXMargin | NSViewMinYMargin | NSViewHeightSizable | NSViewMaxYMargin)

@implementation DoubanSongListView
{
    NSTableView *_theTableView;
    NSInteger currentRow;
    NSMutableArray *dataArray;
}

- (id)initWithFrame:(NSRect)frameRect
{
    if (self = [super initWithFrame:frameRect]) {
        dataArray = [DoubanService instance].likedSongs;
        
        NSScrollView *scrollView = [[[NSScrollView alloc] initWithFrame:CGRectMake(0, 0, frameRect.size.width, frameRect.size.height)] autorelease];
        [scrollView setAutoresizingMask:FULLSIZE];
        [scrollView setHasVerticalScroller:YES];
        
        _theTableView = [[NSTableView alloc] initWithFrame:CGRectMake(0, 0, frameRect.size.width, frameRect.size.height)];
        [_theTableView setAutoresizesSubviews:FULLSIZE];
        [_theTableView setBackgroundColor:[NSColor whiteColor]];
        [_theTableView setGridColor:[NSColor lightGrayColor]];
        [_theTableView setGridStyleMask: NSTableViewSolidHorizontalGridLineMask];
        [_theTableView setUsesAlternatingRowBackgroundColors:YES];
        [_theTableView setAutosaveTableColumns:YES];
        [_theTableView setAllowsEmptySelection:YES];
        [_theTableView setAllowsColumnSelection:YES];
        [_theTableView setDataSource:self];
        [_theTableView setDelegate:self];
        [_theTableView setSortDescriptors:[NSArray arrayWithObjects:
                                           [NSSortDescriptor sortDescriptorWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)],
                                           nil]];
        [_theTableView setAutosaveName:@"likedSongs"];
        [_theTableView setTarget:self];
        [_theTableView setDoubleAction:@selector(doubleClicked)];
        NSMenu *menu = [[[NSMenu alloc] init] autorelease];
        [menu addItemWithTitle:@"Reveal in Finder" action:@selector(menuRevealInFinder) keyEquivalent:@""];
        [menu addItemWithTitle:@"Play" action:@selector(menuPlay) keyEquivalent:@""];
        [menu addItemWithTitle:@"like" action:@selector(menuLikeAction) keyEquivalent:@""];
        [menu addItemWithTitle:@"Remove" action:@selector(menuRemove) keyEquivalent:@""];
        [menu addItemWithTitle:@"Remove and Clear Cache" action:@selector(menuRemoveAndClearCache) keyEquivalent:@""];
        [menu addItemWithTitle:@"Refetch" action:@selector(menuRefetch) keyEquivalent:@""];
        menu.delegate = self;
        [_theTableView setMenu:menu];
        
        [self addColumn:@"artist"];
        [self addColumn:@"songId"];
        [self addColumn:@"liked"];
        [self addColumn:@"path"];
        [self addColumn:@"picture"];
        [self addColumn:@"title"];
        [self addColumn:@"cached"];
        [self addColumn:@"remotePath"];
        
        [scrollView setDocumentView:_theTableView];
        [self addSubview:scrollView];
        
        [[DoubanService instance] addObserver:self forKeyPath:@"currentIndex" options:NSKeyValueObservingOptionNew context:NULL];
        [[DoubanService instance] addObserver:self forKeyPath:@"likedSongs" options:NSKeyValueObservingOptionNew context:NULL];
        [[DoubanService instance] addObserver:self forKeyPath:@"searchedSongs" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [[DoubanService instance] removeObserver:self forKeyPath:@"currentIndex"];
    [[DoubanService instance] removeObserver:self forKeyPath:@"likedSongs"];
    [_theTableView release], _theTableView = nil;
    [super dealloc];
}

- (void)addColumn:(NSString*)title
{
	NSTableColumn *column = [[NSTableColumn alloc] initWithIdentifier:title];
	[[column headerCell] setStringValue:title];
	[[column headerCell] setAlignment:NSCenterTextAlignment];
	[column setMinWidth:50];
	[column setEditable:NO];
	[column setResizingMask:NSTableColumnAutoresizingMask | NSTableColumnUserResizingMask];
    if ([title isEqualToString:@"liked"] || [title isEqualToString:@"cached"]) {
        [column setSortDescriptorPrototype:[NSSortDescriptor sortDescriptorWithKey:title ascending:YES selector:@selector(compare:)]];
        [column setWidth:50.0];
    } else {
        [column setSortDescriptorPrototype:[NSSortDescriptor sortDescriptorWithKey:title ascending:YES selector:@selector(caseInsensitiveCompare:)]];
        [column setWidth:100.0];
    }
	[_theTableView addTableColumn:column];
	[column release];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"likedSongs"]) {
        dataArray = [DoubanService instance].likedSongs;
    }
    if ([keyPath isEqualToString:@"searchedSongs"]) {
        dataArray = [DoubanService instance].searchedSongs;
    }
    [_theTableView reloadData];
    [_theTableView scrollRowToVisible:currentRow];
}

#pragma mark NSTableViewDataSource

- (NSInteger)numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [dataArray count];
}

- (void)tableView:(NSTableView *)tableView sortDescriptorsDidChange:(NSArray *)oldDescriptors
{
    [dataArray sortUsingDescriptors:[tableView sortDescriptors]];
    [tableView reloadData];
}

#pragma mark NSTableViewDelegate

- (CGFloat)tableView:(NSTableView *)tableView heightOfRow:(NSInteger)row
{
    return 20.f;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSParameterAssert(row >= 0 && row < [dataArray count]);
    NSTextField *textField = [[[NSTextField alloc] initWithFrame:CGRectMake(0, 0, tableColumn.width, 20)] autorelease];
    [textField setBordered:NO];
    DoubanSong *song = [dataArray objectAtIndex:row];
    id value = [song performSelector:NSSelectorFromString([tableColumn identifier])];
    if ([[tableColumn identifier] isEqualToString:@"cached"] || [[tableColumn identifier] isEqualToString:@"liked"]) {
        value = value?@"YES":@"NO";
    }
    textField.stringValue = value?value:@"";
    if ([song.songId isEqualToString:[DoubanService instance].currentSong.songId]) {
        [textField setBackgroundColor:RGB(1, 0, 1, 0.2)];
        currentRow = row;
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
    NSInteger clickedRow = [_theTableView clickedRow];
    NSInteger clickedColumn = [_theTableView clickedColumn];
    if (clickedRow != -1 && clickedColumn != -1) {
        DoubanSong *song = [dataArray objectAtIndex:clickedRow];
        if (song) {
            if (clickedColumn == 6) {
                [[DoubanService instance] revealInFinderBySongId:song.songId];
            } else if (clickedColumn == 2) {
                [[DoubanService instance] like:song.songId Action:song.liked?NO:YES];
            } else {
                [[DoubanService instance] playLocalSongBySid:song.songId];
            }
        }
    }
}

- (void)menuRevealInFinder
{
    NSInteger clickedRow = [_theTableView clickedRow];
    if (clickedRow != -1) {
        NSString *sid = [self getValueForColumnWithIdentifier:@"songId" row:clickedRow];
        if (sid) {
            [[DoubanService instance] revealInFinderBySongId:sid];
        }
    }
}

- (void)menuPlay
{
    NSInteger clickedRow = [_theTableView clickedRow];
    if (clickedRow != -1) {
        NSString *sid = [self getValueForColumnWithIdentifier:@"songId" row:clickedRow];
        if (sid) {
            [[DoubanService instance] playLocalSongBySid:sid];
        }
    }
}

- (void)menuLikeAction
{
    NSInteger clickedRow = [_theTableView clickedRow];
    if (clickedRow != -1) {
        DoubanSong *song = [dataArray objectAtIndex:clickedRow];
        if (song) {
            [[DoubanService instance] like:song.songId Action:song.liked?NO:YES];
        }
    }
}

- (void)menuRemove
{
    NSInteger clickedRow = [_theTableView clickedRow];
    if (clickedRow != -1) {
        DoubanSong *song = [dataArray objectAtIndex:clickedRow];
        if (song) {
            [[DoubanService instance] removeSong:song.songId];
        }
    }
}

- (void)menuRemoveAndClearCache
{
    NSInteger clickedRow = [_theTableView clickedRow];
    if (clickedRow != -1) {
        DoubanSong *song = [dataArray objectAtIndex:clickedRow];
        if (song) {
            [[DoubanService instance] removeSong:song.songId];
            [[DoubanService instance] removeCachedSong:song.songId];
        }
    }
}

- (void)menuRefetch
{
    [[DoubanService instance] fetchLikedSongs];
}

#pragma mark - NSMenuDelegate

- (void)menuWillOpen:(NSMenu *)menu
{
    NSInteger clickedRow = [_theTableView clickedRow];
    if (clickedRow != -1) {
        DoubanSong *song = [dataArray objectAtIndex:clickedRow];
        if (song) {
            NSString *title = song.liked?@"unlike":@"like";
            [[menu itemAtIndex:2] setTitle:title];
        }
    }
}

#pragma mark - helper

- (NSString *)getValueForColumnWithIdentifier:(NSString *)identifier row:(NSInteger)row
{
    NSInteger column = [_theTableView columnWithIdentifier:identifier];
    NSTextField *textField = [_theTableView viewAtColumn:column row:row makeIfNecessary:NO];
    return [textField stringValue];
}

@end