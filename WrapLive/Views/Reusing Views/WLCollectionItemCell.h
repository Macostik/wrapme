
#import <UIKit/UIKit.h>
#import "WLItemCellProtocol.h"

@interface WLCollectionItemCell : UICollectionViewCell <WLItemCellProtocol>

- (void)setupItemData:(id)item;

@end
