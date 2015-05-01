//
//  WLReplyPresetsController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKReplyPresetsController.h"
#import "WLWKReplyPresetRow.h"
#import "NSString+Additions.h"

typedef NS_ENUM(NSUInteger, WLWKReplyPresetsStatus) {
    WLWKReplyPresetsStatusDefault,
    WLWKReplyPresetsStatusSuccess,
    WLWKReplyPresetsStatusFailed
};


@interface WLWKReplyPresetsController()

@property (strong, nonatomic) NSArray* presets;

@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;

@property (nonatomic) BOOL replying;

@property (weak, nonatomic) IBOutlet WKInterfaceGroup* errorGroup;

@property (weak, nonatomic) IBOutlet WKInterfaceGroup* successGroup;

@property (weak, nonatomic) IBOutlet WKInterfaceLabel* errorLabel;

@property (nonatomic) WLWKReplyPresetsStatus status;

@end


@implementation WLWKReplyPresetsController

- (NSString *)presetsPropertyListName {
    return nil;
}

- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
    // Configure interface objects here.
    NSString *name = [self presetsPropertyListName];
    if (name) {
        NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"plist"];
        NSArray *presets = self.presets = [NSArray arrayWithContentsOfFile:path];
        [self.table setNumberOfRows:[presets count] withRowType:@"preset"];
        for (NSString *preset in presets) {
            NSUInteger index = [presets indexOfObject:preset];
            WLWKReplyPresetRow* row = [self.table rowControllerAtIndex:index];
            [row setPreset:preset];
        }
    }
}

- (void)setStatus:(WLWKReplyPresetsStatus)status {
    _status = status;
    switch (status) {
        case WLWKReplyPresetsStatusDefault:
            [self.errorGroup setHidden:YES];
            [self.successGroup setHidden:YES];
            [self.table setHidden:NO];
            break;
        case WLWKReplyPresetsStatusSuccess:
            [self.errorGroup setHidden:YES];
            [self.successGroup setHidden:NO];
            [self.table setHidden:YES];
            break;
        case WLWKReplyPresetsStatusFailed:
            [self.errorGroup setHidden:NO];
            [self.successGroup setHidden:YES];
            [self.table setHidden:YES];
            break;
        default:
            break;
    }
}

- (void)handlePreset:(NSString *)preset success:(WLBlock)success failure:(WLFailureBlock)failure {
    if (success) success();
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
    if (self.replying) return;
    __weak typeof(self)weakSelf = self;
    NSString *preset = [self.presets objectAtIndex:rowIndex];
    if (preset.nonempty) {
        self.replying = YES;
        [self handlePreset:preset success:^{
            weakSelf.replying = NO;
            weakSelf.status = WLWKReplyPresetsStatusSuccess;
            run_after(3, ^{
                [weakSelf popController];
            });
        } failure:^(NSError *error) {
            weakSelf.replying = NO;
            [weakSelf.errorLabel setText:error.localizedDescription];
            weakSelf.status = WLWKReplyPresetsStatusFailed;
            run_after(3, ^{
                weakSelf.status = WLWKReplyPresetsStatusDefault;
            });
        }];
    }
}

@end



