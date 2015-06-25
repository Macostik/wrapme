//
//  WLDrawingSessionView.h
//  wrapLive
//
//  Created by Sergey Maximenko on 6/24/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import <UIKit/UIKit.h>

@class WLDrawingSession;

@interface WLDrawingCanvas : UIView

@property (strong, nonatomic) WLDrawingSession *session;

- (IBAction)panning:(UIPanGestureRecognizer*)sender;

@end
