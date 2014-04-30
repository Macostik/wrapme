//
//  UIStoryboard+Additions.m
//  WrapLive
//
//  Created by Sergey Maximenko on 27.03.14.
//  Copyright (c) 2014 Mobidev. All rights reserved.
//

#import "UIStoryboard+Additions.h"

@implementation UIStoryboard (Additions)

- (id)welcomeViewController {
	return [self instantiateViewControllerWithIdentifier:WLStoryboardWelcomeViewControllerIdentifier];
}

- (id)homeViewController {
	return [self instantiateViewControllerWithIdentifier:WLStoryboardHomeViewControllerIdentifier];
}

- (id)cameraViewController {
	return [self instantiateViewControllerWithIdentifier:WLStoryboardCameraViewControllerIdentifier];
}

- (id)wrapViewController {
	return [self instantiateViewControllerWithIdentifier:WLStoryboardWrapViewControllerIdentifier];
}

- (id)signUpViewController {
	return [self instantiateViewControllerWithIdentifier:WLStoryboardSignUpViewControllerIdentifier];
}

- (id)candyViewController {
	return [self instantiateViewControllerWithIdentifier:WLStoryboardCandyViewControllerIdentifier];
}

- (id)chatViewController {
	return [self instantiateViewControllerWithIdentifier:WLStoryboardChatViewControllerIdentifier];
}

- (id)editWrapViewController {
	return [self instantiateViewControllerWithIdentifier:WLStoryboardEditWrapViewControllerIdentifier];
}

@end

@implementation UIStoryboardSegue (Additions)

- (BOOL)isContributorsSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueContributorsIdentifier];
}

- (BOOL)isWrapSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueWrapIdentifier];
}

- (BOOL)isCameraSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueCameraIdentifier];
}

- (BOOL)isTopWrapSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueTopWrapIdentifier];
}

- (BOOL)isChangeWrapSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueChangeWrapIdentifier];
}

- (BOOL)isImageSegue {
	return [self.identifier isEqualToString:WLStoryboardSegueImageIdentifier];
}

@end
