//
//  WLWKCandyController.m
//  WrapLive
//
//  Created by Sergey Maximenko on 1/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKCandyController.h"
#import "WLCandy+Extended.h"
#import "WLAPIManager.h"
#import "WLWKCommentRow.h"
#import "WKInterfaceImage+WLImageFetcher.h"

@interface WLWKCandyController ()

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *image;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *photoByLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;

@property (weak, nonatomic) WLCandy* candy;

@end


@implementation WLWKCandyController

- (void)awakeWithContext:(WLCandy*)candy {
    [super awakeWithContext:candy];
    self.candy = candy;
    // Configure interface objects here.
    __weak typeof(self)weakSelf = self;
    [candy fetch:^(id object) {
        [weakSelf update];
    } failure:^(NSError *error) {
    }];
}

- (void)update {
    WLCandy *candy = self.candy;
    [self.photoByLabel setText:[NSString stringWithFormat:WLLS(@"formatted_photo_by"), candy.contributor.name]];
    [self.wrapNameLabel setText:candy.wrap.name];
    [self.dateLabel setText:candy.createdAt.timeAgoStringAtAMPM.stringByCapitalizingFirstCharacter];
    self.image.url = candy.picture.small;
    NSOrderedSet *comments = [self.candy.comments reversedOrderedSet];
    [self.table setNumberOfRows:[comments count] withRowType:@"comment"];
    for (WLComment *comment in comments) {
        NSUInteger index = [comments indexOfObject:comment];
        WLWKCommentRow* row = [self.table rowControllerAtIndex:index];
        [row setEntry:comment];
    }
}

- (id)contextForSegueWithIdentifier:(NSString *)segueIdentifier {
    return self.candy;
}

- (IBAction)writeComment {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"WLWKCommentReplyPresets" ofType:@"plist"];
    NSArray *presets = [NSArray arrayWithContentsOfFile:path];
    __weak typeof(self)weakSelf = self;
    [self presentTextInputControllerWithSuggestions:presets allowedInputMode:WKTextInputModeAllowEmoji completion:^(NSArray *results) {
        for (NSString *result in results) {
            if ([result isKindOfClass:[NSString class]]) {
                [weakSelf.candy uploadComment:result success:^(WLComment *comment) {
                    [weakSelf update];
                } failure:^(NSError *error) {
                    [weakSelf pushControllerWithName:@"error" context:WLError(@"error text")];
                }];
                break;
            }
        }
    }];
}

- (void)willActivate {
    // This method is called when watch view controller is about to be visible to user
    [super willActivate];
    [self update];
}

- (void)didDeactivate {
    // This method is called when watch view controller is no longer visible
    [super didDeactivate];
}

@end



