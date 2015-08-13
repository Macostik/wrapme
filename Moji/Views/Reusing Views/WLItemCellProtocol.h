
#import <Foundation/Foundation.h>

@protocol WLItemCellProtocol <NSObject>

@property (nonatomic, strong) id item;

+ (NSString*)reuseIdentifier;

+ (CGFloat)heightForItem:(id)item;

@end
