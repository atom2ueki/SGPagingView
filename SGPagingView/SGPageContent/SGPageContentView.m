//
//  如遇到问题或有更好方案，请通过以下方式进行联系
//      QQ群：429899752
//      Email：kingsic@126.com
//      GitHub：https://github.com/kingsic/SGPagingView
//
//  SGPageContentView.m
//  SGPagingViewExample
//
//  Created by kingsic on 16/10/6.
//  Copyright © 2016年 kingsic. All rights reserved.
//

#import "SGPageContentView.h"
#import "UIView+SGPagingView.h"
#import <Masonry/Masonry.h>

@interface SGPageContentView () <UICollectionViewDataSource, UICollectionViewDelegate>
/// collectionView
@property (nonatomic, strong) UICollectionView *collectionView;
/// 记录刚开始时的偏移量
@property (nonatomic, assign) NSInteger startOffsetX;
/// 标记按钮是否点击
@property (nonatomic, assign) BOOL isClickBtn;
    
/// check whether init setup done
@property (nonatomic, assign) BOOL initSetup;

@end

@implementation SGPageContentView

#pragma mark - init
- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _initSetup = NO;
    }
    return self;
}
    
- (instancetype)initWithFrame:(CGRect)frame parentVC:(UIViewController *)parentVC childVCs:(NSArray *)childVCs {
    if (self = [super initWithFrame:frame]) {
        if (parentVC == nil) {
            @throw [NSException exceptionWithName:@"SGPagingView" reason:@"SGPageContentView 所在控制器必须设置" userInfo:nil];
        }
        self.parentViewController = parentVC;
        if (childVCs == nil || [childVCs count] == 0) {
            @throw [NSException exceptionWithName:@"SGPagingView" reason:@"SGPageContentView 子控制器必须设置, 且不能为空vc组" userInfo:nil];
        }
        self.childViewControllers = childVCs;
        
        _initSetup = NO;
        
        [self initialization];
    }
    return self;
}

+ (instancetype)pageContentViewWithFrame:(CGRect)frame parentVC:(UIViewController *)parentVC childVCs:(NSArray *)childVCs {
    return [[self alloc] initWithFrame:frame parentVC:parentVC childVCs:childVCs];
}
    
#pragma mark - getter & setter
- (CGFloat)collectionViewWidth {
    if (!_collectionViewWidth) {
        _collectionViewWidth = self.bounds.size.width;
    }
    return _collectionViewWidth;
}
    
- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
        flowLayout.itemSize = CGSizeMake(self.collectionViewWidth, self.bounds.size.height);
        flowLayout.minimumLineSpacing = 0;
        flowLayout.minimumInteritemSpacing = 0;
        flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
        _collectionView.showsVerticalScrollIndicator = NO;
        _collectionView.showsHorizontalScrollIndicator = NO;
        _collectionView.pagingEnabled = YES;
        _collectionView.bounces = NO;
        _collectionView.backgroundColor = [UIColor whiteColor];
        
        [_collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
    }
    return _collectionView;
}

#pragma mark - instance methods
- (void)initialization {
    self.isClickBtn = NO;
    self.startOffsetX = 0;
}

- (void)setupSubviews {
    // 0、处理偏移量
    UIView *tempView = [[UIView alloc] initWithFrame:CGRectZero];
    [self addSubview:tempView];
    // 1、将所有的子控制器添加父控制器中
    for (UIViewController *childVC in self.childViewControllers) {
        [self.parentViewController addChildViewController:childVC];
    }
    // 2、添加UICollectionView, 用于在Cell中存放控制器的View
    [self addSubview:self.collectionView];
    
    // 3. add constraints to collectionView
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    
    if (@available(iOS 10.0, *)) {
        // TODO: make a configuration setting for this option
        _collectionView.prefetchingEnabled = NO;
    }
}

#pragma mark - lifecycle
- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!_initSetup) {
        
        // check compulsory variables are valid
        if (self.parentViewController == nil) {
            @throw [NSException exceptionWithName:@"SGPagingView" reason:@"SGPageContentView 所在控制器必须设置" userInfo:nil];
        }
        if (self.childViewControllers == nil || [self.childViewControllers count] == 0) {
            @throw [NSException exceptionWithName:@"SGPagingView" reason:@"SGPageContentView 子控制器必须设置, 且不能为空vc组" userInfo:nil];
        }
        
        // when view is ready, add subviews
        [self setupSubviews];
        
        _initSetup = YES;
    }
}

#pragma mark - UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.childViewControllers.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    [cell.contentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    // 设置内容
    UIViewController *childVC = self.childViewControllers[indexPath.item];
    [cell.contentView addSubview:childVC.view];
    
    [childVC.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(cell.contentView);
    }];
    
    return cell;
}

#pragma mark - - - UICollectionViewDelegate
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(self.collectionViewWidth, self.frame.size.height);
}

#pragma mark - - - UIScrollViewDelegate
- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView {
    self.isClickBtn = NO;
    self.startOffsetX = scrollView.contentOffset.x;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView {
    CGFloat offsetX = scrollView.contentOffset.x;
    // pageContentView:offsetX:
    if (self.delegatePageContentView && [self.delegatePageContentView respondsToSelector:@selector(pageContentView:offsetX:)]) {
        [self.delegatePageContentView pageContentView:self offsetX:offsetX];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    CGFloat offsetX = scrollView.contentOffset.x;
    // pageContentView:offsetX:
    if (self.delegatePageContentView && [self.delegatePageContentView respondsToSelector:@selector(pageContentView:offsetX:)]) {
        [self.delegatePageContentView pageContentView:self offsetX:offsetX];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    // 1、定义获取需要的数据
    CGFloat progress = 0;
    NSInteger originalIndex = 0;
    NSInteger targetIndex = 0;
    // 2、判断是左滑还是右滑
    CGFloat currentOffsetX = scrollView.contentOffset.x;
    CGFloat scrollViewW = self.collectionViewWidth;
    if (currentOffsetX > self.startOffsetX) { // 左滑
        // 1、计算 progress
        progress = currentOffsetX / scrollViewW - floor(currentOffsetX / scrollViewW);
        // 2、计算 originalIndex
        originalIndex = currentOffsetX / scrollViewW;
        // 3、计算 targetIndex
        targetIndex = originalIndex + 1;
        if (targetIndex >= self.childViewControllers.count) {
            progress = 1;
            targetIndex = originalIndex;
        }
        // 4、如果完全划过去
        if (currentOffsetX - self.startOffsetX == scrollViewW) {
            progress = 1;
            targetIndex = originalIndex;
        }
    } else { // 右滑
        // 1、计算 progress
        progress = 1 - (currentOffsetX / scrollViewW - floor(currentOffsetX / scrollViewW));
        // 2、计算 targetIndex
        targetIndex = currentOffsetX / scrollViewW;
        // 3、计算 originalIndex
        originalIndex = targetIndex + 1;
        if (originalIndex >= self.childViewControllers.count) {
            originalIndex = self.childViewControllers.count - 1;
        }
    }
    // 3、pageContentViewDelegare; 将 progress／sourceIndex／targetIndex 传递给 SGPageTitleView
    if (self.delegatePageContentView && [self.delegatePageContentView respondsToSelector:@selector(pageContentView:progress:originalIndex:targetIndex:)]) {
        [self.delegatePageContentView pageContentView:self progress:progress originalIndex:originalIndex targetIndex:targetIndex];
    }
}

#pragma mark - - - 给外界提供的方法，获取 SGPageTitleView 选中按钮的下标
- (void)setPageContentViewCurrentIndex:(NSInteger)currentIndex {
    self.isClickBtn = YES;
    CGFloat offsetX = currentIndex * self.collectionViewWidth;
    // 1、处理内容偏移
    self.collectionView.contentOffset = CGPointMake(offsetX, 0);
    // 2、pageContentView:offsetX:
    if (self.delegatePageContentView && [self.delegatePageContentView respondsToSelector:@selector(pageContentView:offsetX:)]) {
        [self.delegatePageContentView pageContentView:self offsetX:offsetX];
    }
}

#pragma mark - - - set
- (void)setIsScrollEnabled:(BOOL)isScrollEnabled {
    _isScrollEnabled = isScrollEnabled;
    if (isScrollEnabled) {
        
    } else {
        _collectionView.scrollEnabled = NO;
    }
}


@end

