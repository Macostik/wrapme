//
//  GCDHelper.h
//  meWrap
//
//  Created by Ravenpod on 10/22/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

static inline void run_in_default_queue(dispatch_block_t block) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
}

static inline void run_in_background_queue(dispatch_block_t block) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block);
}

static inline void run_in_main_queue(dispatch_block_t block) {
    dispatch_async(dispatch_get_main_queue(), block);
}

static inline void run_with_completion(dispatch_block_t block, dispatch_block_t completion) {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        if (block) {
            block();
        }
        run_in_main_queue(completion);
    });
}

static inline void run_getting_object_in_queue(dispatch_queue_t queue, id (^block) (void), void (^completion)(id object)) {
    dispatch_async(queue, ^{
        id object = nil;
        if (block) {
            object = block();
        }
        if (completion) {
            run_in_main_queue(^{
                completion(object);
            });
        }
    });
}

static inline void run_getting_object(id (^block) (void), void (^completion)(id object)) {
    run_getting_object_in_queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block, completion);
}

static inline void run_getting_object_in_background(id (^block) (void), void (^completion)(id object)) {
    run_getting_object_in_queue(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), block, completion);
}

static inline void run_after(NSTimeInterval after, dispatch_block_t block) {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(after * NSEC_PER_SEC)), dispatch_get_main_queue(), block);
}

static inline void run_after_asap(dispatch_block_t block) {
    run_after(.0, block);
}

static inline void run_loop(NSUInteger count, void (^block) (NSUInteger i)) {
    NSUInteger i = count;
    while (i > 0) {
        block(count - i);
        --i;
    }
}

static inline void run_release(dispatch_block_t block) {
#ifndef DEBUG
    if (block) block();
#endif
}

static inline void run_debug(dispatch_block_t block) {
#ifdef DEBUG
    if (block) block();
#endif
}

static inline id didReceiveMemoryWarning(dispatch_block_t block) {
    return [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidReceiveMemoryWarningNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *note) {
        if (block) block();
    }];
}
