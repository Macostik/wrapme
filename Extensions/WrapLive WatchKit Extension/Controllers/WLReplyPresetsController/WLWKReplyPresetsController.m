//
//  WLReplyPresetsController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKReplyPresetsController.h"
#import "WLWKReplyPresetRow.h"
#import "WLCandy+Extended.h"
#import "WLAPIManager.h"
#import "NSString+Additions.h"

@interface WLWKReplyPresetsController()

@property (strong, nonatomic) WLCandy* candy;

@property (strong, nonatomic) NSArray* presets;

@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;

@property (nonatomic) BOOL replying;

@end


@implementation WLWKReplyPresetsController

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    self.candy = context;
    // Configure interface objects here.
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WLWKReplyPresets" ofType:@"plist"];
    NSArray *presets = self.presets = [NSArray arrayWithContentsOfFile:path];
    [self.table setNumberOfRows:[presets count] withRowType:@"preset"];
    for (NSString *preset in presets) {
        NSUInteger index = [presets indexOfObject:preset];
        WLWKReplyPresetRow* row = [self.table rowControllerAtIndex:index];
        [row setPreset:preset];
    }
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    if (self.replying) return;
    __weak typeof(self)weakSelf = self;
    NSString *preset = [self.presets objectAtIndex:rowIndex];
    if (preset.nonempty) {
        self.replying = YES;
        [self.candy uploadComment:preset success:^(WLComment *comment) {
            weakSelf.replying = NO;
            [weakSelf popController];
        } failure:^(NSError *error) {
            weakSelf.replying = NO;
        }];
    }
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



