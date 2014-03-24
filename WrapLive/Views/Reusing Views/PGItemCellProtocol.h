
#import <Foundation/Foundation.h>

@protocol PGItemCellProtocol <NSObject>

@property (nonatomic, strong) id item;

+ (NSString*)reuseIdentifier;

+ (CGFloat)heightForItem:(id)item;

@end
