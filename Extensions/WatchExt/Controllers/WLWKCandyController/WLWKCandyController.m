//
//  WLWKCandyController.m
//  meWrap
//
//  Created by Ravenpod on 1/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKCandyController.h"
#import "WLCandy+Extended.h"
#import "WLWKCommentRow.h"
#import "WKInterfaceImage+WLImageFetcher.h"
#import "WKInterfaceController+SimplifiedTextInput.h"
#import "WLWKParentApplicationContext.h"

@interface WLWKCandyController ()

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *image;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *photoByLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *commentButton;

@property (weak, nonatomic) WLCandy* candy;

@end


@implementation WLWKCandyController

- (void)awakeWithContext:(WLCandy*)candy {
    [super awakeWithContext:candy];
    [[WLEntryManager manager].context refreshObject:candy mergeChanges:NO];
    self.candy = candy;
    [self.commentButton setTitle:WLLS(@"comment")];
}

- (void)update {
    WLCandy *candy = self.candy;
    [self.photoByLabel setText:[NSString stringWithFormat:WLLS(@"formatted_photo_by"), candy.contributor.name]];
    [self.wrapNameLabel setText:candy.wrap.name];
    [self.dateLabel setText:candy.createdAt.timeAgoStringAtAMPM];
    self.image.url = candy.picture.small;
    NSOrderedSet *comments = [candy sortedComments];
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
        [WLWKParentApplicationContext postComment:result candy:weakSelf.candy.identifier success:^(NSDictionary *replyInfo) {
            [[WLEntryManager manager].context refreshObject:weakSelf.candy mergeChanges:NO];
            [weakSelf update];
            [weakSelf.table scrollToRowAtIndex:0];
        } failure:^(NSError *error) {
            [weakSelf pushControllerWithName:@"alert" context:error];
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



