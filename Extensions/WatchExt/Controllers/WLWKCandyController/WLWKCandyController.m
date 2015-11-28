//
//  WLWKCandyController.m
//  meWrap
//
//  Created by Ravenpod on 1/23/15.
//  Copyright (c) 2015 Ravenpod. All rights reserved.
//

#import "WLWKCandyController.h"
#import "WLWKCommentRow.h"

@interface WLWKCandyController ()

@property (weak, nonatomic) IBOutlet WKInterfaceGroup *image;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *photoByLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *wrapNameLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceLabel *dateLabel;
@property (weak, nonatomic) IBOutlet WKInterfaceButton *commentButton;

@property (weak, nonatomic) Candy *candy;

@end


@implementation WLWKCandyController

- (void)awakeWithContext:(Candy *)candy {
    [super awakeWithContext:candy];
    [EntryContext.sharedContext refreshObject:candy mergeChanges:NO];
    self.candy = candy;
    [self.commentButton setTitle:@"comment".ls];
}

- (void)update {
    Candy *candy = self.candy;
    [self.photoByLabel setText:[NSString stringWithFormat:(candy.isVideo ? @"formatted_video_by" : @"formatted_photo_by").ls,candy.contributor.name]];
    [self.wrapNameLabel setText:candy.wrap.name];
    [self.dateLabel setText:candy.createdAt.timeAgoStringAtAMPM];
    self.image.URL = candy.picture.small;
    NSArray *comments = [candy sortedComments];
    [self.table setNumberOfRows:[comments count] withRowType:@"comment"];
    for (Comment *comment in comments) {
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
    [self presentTextSuggestionsFromPlistNamed:@"comment_presets" completionHandler:^(NSString *result) {
        [[WCSession defaultSession] postComment:result candy:weakSelf.candy.identifier success:^(NSDictionary *replyInfo) {
            [EntryContext.sharedContext refreshObject:weakSelf.candy mergeChanges:NO];
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



