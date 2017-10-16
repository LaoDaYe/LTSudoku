//
//  LTSudukuGameView.m
//  LTSoduku
//
//  Created by lt on 2017/9/4.
//  Copyright © 2017年 tl. All rights reserved.
//

#import "LTSudukuGameView.h"
#import "LTSudokuEditToolView.h"
#import "LTSudokuCollectionViewCell.h"

@interface LTSudukuGameView () <UICollectionViewDelegate, UICollectionViewDataSource, LTSudokuEditToolViewDelegate>

@property (nonatomic, strong) UICollectionView *sudokuView;
@property (nonatomic, strong) LTSudokuEditToolView *toolView;
@property (nonatomic, strong) UILabel *timeLabel;

@property (nonatomic, readonly) LTSodukuCellModel *selectedCellModel;

@end

@implementation LTSudukuGameView {
    NSIndexPath *_selectedIndex;        // 当前选择的cell index
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self initView];
    }
    return self;
}


# pragma mark - ui

- (void)initView
{
    [self addSubview:self.timeLabel];
    [self addSubview:self.sudokuView];
    [self addSubview:self.toolView];
    
    for (NSInteger i = 0; i < 10; i++) {
        UIView *xLineView = [[UIView alloc] init];
        UIView *yLineView = [[UIView alloc] init];
        xLineView.backgroundColor = [UIColor blackColor];
        yLineView.backgroundColor = [UIColor blackColor];
        xLineView.frame = CGRectMake(0, [GState cellWidthHeight] * i, [GState sudokuViewWidth] + 1.f, [GState sudokuLayerWidth]);
        yLineView.frame = CGRectMake([GState cellWidthHeight] * i, 0, [GState sudokuLayerWidth], [GState sudokuViewWidth] + 1.f);
        if (i % 3 == 0) {
            xLineView.height = 1.5f;
            yLineView.width = 1.5f;
        }
        [self.sudokuView addSubview:xLineView];
        [self.sudokuView addSubview:yLineView];
    }

}

- (void)layoutSubviews
{
    self.timeLabel.size = CGSizeMake(50, 20);
    self.timeLabel.center = CGPointMake(self.width / 2, self.timeLabel.height / 2);
    self.sudokuView.frame = CGRectMake([GState defaultTopSpace], self.timeLabel.bottom + 5, [GState sudokuViewWidth], [GState sudokuViewWidth]);
    self.toolView.frame = CGRectMake(self.sudokuView.left, self.sudokuView.bottom + [GState defaultTopSpace], [GState sudokuViewWidth], (self.width - [GState sudokuButtonSpace] * 5) / 6.5 * 2 + [GState sudokuButtonSpace]);
}

# pragma mark - public

- (void)restartGame
{
    [self.sudokuView reloadData];
    self.timeLabel.text = @"0";
}

- (void)timerCallBack:(NSTimer *)timer
{
    NSTimeInterval time = [self.timeLabel.text integerValue];
    time += timer.timeInterval;
    self.timeLabel.text = [NSString stringWithFormat:@"%.0f", time];
}

# pragma mark - private

// 开始新的一局游戏的时候需要重置cell的背景颜色与边框颜色等
- (void)resetCellColor
{
    for (NSInteger x = 0; x < 9; x++) {
        for (NSInteger y = 0; y < 9; y++) {
            LTSudokuCollectionViewCell *selectedCell = (LTSudokuCollectionViewCell *)[self.sudokuView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:x inSection:y]];
            selectedCell.backgroundColor = [UIColor whiteColor];
            selectedCell.borderLayer.borderWidth = .5f;
        }
    }
}

- (void)updateCellColor
{
    LTSudokuCollectionViewCell *selectedCell = (LTSudokuCollectionViewCell *)[self.sudokuView cellForItemAtIndexPath:_selectedIndex];
    
    NSInteger y = _selectedIndex.section;
    NSInteger x = _selectedIndex.row;
    NSString *highlightValue = @"000";
    if (selectedCell.model.inputValue.length > 0) {
        highlightValue = selectedCell.model.inputValue;
    } else if(selectedCell.model.editEnabled == NO) {
        highlightValue = selectedCell.model.realValue;
    }
    
    for (NSInteger i = 0; i < 9; i++) {
        for (NSInteger j = 0; j < 9; j++) {
            LTSudokuCollectionViewCell *cell = (LTSudokuCollectionViewCell *)[self.sudokuView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]];
            cell.borderLayer.borderWidth = 0;
            if (i == x || j == y ) {
                cell.backgroundColor = [GState selectedCellColor];
            } else {
                cell.backgroundColor = [UIColor whiteColor];
            }
            
            if (highlightValue == (cell.model.editEnabled == YES ? cell.model.inputValue : cell.model.realValue)) {
                cell.backgroundColor = RGBACOLOR(248, 196, 113, .5f);
            }
            
        }
    }
    
    selectedCell.borderLayer.borderWidth = 1.5f;
}



# pragma mark - CollectionViewDatasource

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView
{
    return 9;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return 9;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    LTSudokuCollectionViewCell * cell = (LTSudokuCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.borderLayer.borderColor = [UIColor flatRedColor].CGColor;
    [cell setModel:[LTSudokuLogic modelWithX:indexPath.row y:indexPath.section]];
    
    return cell;
}


# pragma mark CollectionViewDelegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedIndex = indexPath;
    LTSudokuCollectionViewCell *selectedCell = (LTSudokuCollectionViewCell *)[self.sudokuView cellForItemAtIndexPath:indexPath];
    if (selectedCell.borderLayer.borderWidth == 1.5f) {
        [self collectionView:self.sudokuView didDeselectItemAtIndexPath:_selectedIndex];
        return;
    }
    
    [self updateCellColor];
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    _selectedIndex = nil;
    NSLog(@"x = %ld y = %ld  取消选中",indexPath.row,indexPath.section);
    for (NSInteger i = 0; i < 9; i++) {
        for (NSInteger j = 0; j < 9; j++) {
            LTSudokuCollectionViewCell *cell = (LTSudokuCollectionViewCell *)[collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForRow:i inSection:j]];
            cell.backgroundColor = [UIColor whiteColor];
            cell.borderLayer.borderWidth = 0;
        }
    }
}

# pragma mark - LTSudokuEditToolViewDelegate

- (void)setInputValue:(NSString *)value
{
    if (_selectedIndex && self.selectedCellModel.editEnabled == YES) {
        self.selectedCellModel.inputValue = value;
        [self.selectedCellModel.noteList removeAllObjects];
        [self.sudokuView reloadItemsAtIndexPaths:[NSArray arrayWithObject:_selectedIndex]];
        [self collectionView:self.sudokuView didSelectItemAtIndexPath:_selectedIndex];
        
        if ([LTSudokuLogic isGameOver]) {
            UIAlertController * alertVC = [UIAlertController alertControllerWithTitle:nil message:@"YOU WIN!" preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *action = [UIAlertAction actionWithTitle:@"下一局" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                _selectedIndex = nil;
                [LTSudokuLogic restartGame];
            }];
            [alertVC addAction:action];
            [self.window.rootViewController presentViewController:alertVC animated:NO completion:nil];
        }
    } else {
        NSLog(@"请选择要操作的方格");
    }
}

- (void)setNoteValue:(NSString *)value
{
    if (_selectedIndex && self.selectedCellModel.editEnabled == YES) {
        self.selectedCellModel.inputValue = @"";
        if ([self.selectedCellModel.noteList containsObject:value]) {
            [self.selectedCellModel.noteList removeObject:value];
        } else {
            [self.selectedCellModel.noteList addObject:value];
        }
        
        [self.sudokuView reloadItemsAtIndexPaths:[NSArray arrayWithObject:_selectedIndex]];
        [self collectionView:self.sudokuView didSelectItemAtIndexPath:_selectedIndex];
    } else {
        NSLog(@"请选择要操作的方格");
    }
}

- (void)clearAllValue
{
    if (_selectedIndex && self.selectedCellModel.editEnabled == YES) {
        self.selectedCellModel.inputValue = @"";
        [self.selectedCellModel.noteList removeAllObjects];
        [self.sudokuView reloadItemsAtIndexPaths:[NSArray arrayWithObject:_selectedIndex]];
        [self collectionView:self.sudokuView didSelectItemAtIndexPath:_selectedIndex];
    } else {
        NSLog(@"请选择要操作的方格");
    }
}

# pragma mark - get

- (UICollectionView *)sudokuView
{
    if (!_sudokuView)
    {
        UICollectionViewFlowLayout *viewLayout = [[UICollectionViewFlowLayout alloc] init];
        viewLayout.itemSize = CGSizeMake([GState cellWidthHeight], [GState cellWidthHeight]);
        viewLayout.minimumLineSpacing = 0;
        viewLayout.minimumInteritemSpacing = 0;
        _sudokuView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:viewLayout];
        _sudokuView.clipsToBounds = NO;
        _sudokuView.backgroundColor = [UIColor whiteColor];
        _sudokuView.delegate = self;
        _sudokuView.dataSource = self;
        [_sudokuView registerClass:[LTSudokuCollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
        
    }
    return _sudokuView;
}

- (LTSudokuEditToolView *)toolView
{
    if (!_toolView)
    {
        _toolView = [[LTSudokuEditToolView alloc] initWithFrame:CGRectZero];
        _toolView.delegate = self;
    }
    return _toolView;
}

- (LTSodukuCellModel *)selectedCellModel
{
    if (!_selectedIndex) {
        NSLog(@"请选择要操作的方格");
        return nil;
    }
    return [LTSudokuLogic modelWithX:_selectedIndex.row y:_selectedIndex.section];
}

- (UILabel *)timeLabel
{
    if (!_timeLabel)
    {
        _timeLabel = [[UILabel alloc] init];
        _timeLabel.textAlignment = NSTextAlignmentCenter;
        _timeLabel.text = @"0";
    }
    return _timeLabel;
}

@end
