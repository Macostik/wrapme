//
//  WLDrawingSessionView.h
//  meWrap
//
//  Created by Ravenpod on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLDrawingSession;

@interface WLDrawingCanvas : UIView

@property (strong, nonatomic) WLDrawingSession *session;

- (IBAction)panning:(UIPanGestureRecognizer*)sender;

- (void)render;

- (void)undo;

- (void)erase;

@end
