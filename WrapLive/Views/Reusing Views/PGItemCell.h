
#import <UIKit/UIKit.h>
#import "PGItemCellProtocol.h"

@interface PGItemCell : UITableViewCell <PGItemCellProtocol>

- (void)setupItemData:(id)item;

@end
