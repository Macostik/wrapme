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

@property (weak, nonatomic) IBOutlet WKInterfaceImage *image;
@property (weak, nonatomic) IBOutlet WKInterfaceTable *table;

@property (strong, nonatomic) WLCandy* candy;

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
    self.image.url = self.candy.picture.small;
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



