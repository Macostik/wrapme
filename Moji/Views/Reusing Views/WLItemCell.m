
#import "WLItemCell.h"
#import <objc/runtime.h>

@implementation WLItemCell

@synthesize item = _item;

- (void)setItem:(id)item {
    _item = item;
    
    [self setupItemData:item];
}

- (void)setupItemData:(id)item {
}

+ (CGFloat)heightForItem:(id)item {
    return 44;
}

+ (NSString *)reuseIdentifier {
    return NSStringFromClass([self class]);
}

@end
