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
#import "WKInterfaceController+SimplifiedTextInput.h"

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
    __weak typeof(self)weakSelf = self;
    [self presentTextInputControllerWithSuggestionsFromFileNamed:@"WLWKCommentReplyPresets" completion:^(NSString *result) {
        [WKInterfaceController openParentApplication:@{@"action":@"post_comment",WLCandyUIDKey:weakSelf.candy.identifier,@"text":result} reply:^(NSDictionary *replyInfo, NSError *error) {
            if ([replyInfo[@"success"] boolValue] == NO) {
                [weakSelf pushControllerWithName:@"alert" context:WLError(replyInfo[@"message"])];
            } else {
                [weakSelf pushControllerWithName:@"alert" context:@"Comment sent!"];
            }
        }];
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



