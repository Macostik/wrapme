
#import <UIKit/UIKit.h>
#import "PGItemCellProtocol.h"

@interface PGCollectionItemCell : UICollectionViewCell <PGItemCellProtocol>

- (void)setupItemData:(id)item;

@end
