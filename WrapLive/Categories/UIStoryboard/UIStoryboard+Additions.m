//
//  UIStoryboard+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIStoryboard+Additions.h"

@implementation UIStoryboard (Additions)

- (id)homeViewController {
	return [self instantiateViewControllerWithIdentifier:WLStoryboardHomeViewControllerIdentifier];
}

- (id)cameraViewController {
	return [self instantiateViewControllerWithIdentifier:WLStoryboardCameraViewControllerIdentifier];
}

@end

@implementation UIStoryboardSegue (Additions)

- (BOOL)isContributorsSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueContributorsIdentifier];
}

- (BOOL)isWrapSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueWrapIdentifier];
}

@end
