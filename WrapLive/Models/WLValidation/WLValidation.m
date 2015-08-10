//
//  WLValidation.m
//  moji
//
//  Created by Ravenpod on 11/24/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLValidation.h"

@implementation WLValidation

- (void)awakeFromNib {
    [super awakeFromNib];
    [self prepare];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        [self prepare];
    }
    return self;
}

- (void)prepare {
    
}

- (void)setStatus:(WLValidationStatus)status {
    if (_status != status) {
        _status = status;
        [self statusChanged:status];
    }
}

- (void)statusChanged:(WLValidationStatus)status {
    [self updateStatusView:status];
    [self.delegate validationStatusChanged:self];
}

- (void)updateStatusView:(WLValidationStatus)status {
    UIView *view = self.statusView;
    if (view) {
        view.userInteractionEnabled = status == WLValidationStatusValid;
        view.alpha = status == WLValidationStatusValid ? 1.0f : 0.5f;
    }
}

- (void)setStatusView:(UIView *)statusView {
    _statusView = statusView;
    [self updateStatusView:self.status];
}

- (WLValidationStatus)validate {
    WLValidationStatus status = self.status;
    status = [self defineCurrentStatus:self.inputView];
    self.status = status;
    return status;
}

- (WLValidationStatus)defineCurrentStatus:(UIView *)inputView {
    return WLValidationStatusValid;
}

@end
