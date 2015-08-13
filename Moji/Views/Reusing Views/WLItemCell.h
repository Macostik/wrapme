
#import <UIKit/UIKit.h>
#import "WLItemCellProtocol.h"

@interface WLItemCell : UITableViewCell <WLItemCellProtocol>

- (void)setupItemData:(id)item;

@end
