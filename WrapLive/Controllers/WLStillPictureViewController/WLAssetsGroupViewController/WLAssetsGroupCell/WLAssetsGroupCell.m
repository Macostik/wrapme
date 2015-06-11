//
//  PGPhotoLibraryCell.m
//  PressGram-iOS
//
//  Created by Ivanov Andrey on 04.06.13.
//  Copyright (c) 2013 Nickolay Rybalko. All rights reserved.
//

#import "WLAssetsGroupCell.h"
#import "ALAssetsLibrary+Additions.h"

@interface WLAssetsGroupCell()

@property (weak, nonatomic) IBOutlet UILabel *libraryNameLabel;
@property (weak, nonatomic) IBOutlet UILabel *countLabel;
@property (weak, nonatomic) IBOutlet UIImageView *thumbnailImageView;

@end

@implementation WLAssetsGroupCell

- (void)setup:(ALAssetsGroup*)group {
    self.libraryNameLabel.text = group.name;
    self.countLabel.text = [NSString stringWithFormat:@"%ld", (long)group.numberOfAssets];
    self.thumbnailImageView.image = [UIImage imageWithCGImage:group.posterImage];
}

- (IBAction)select:(id)sender {
	[self.delegate assetsGroupCell:self didSelectGroup:self.entry];
}

@end
