//
//  WLPhoneValidation.m
//  WrapLive
//
//  Created by Sergey Maximenko on 11/25/14.
//  Copyright (c) 2014 Ravenpod. All rights reserved.
//

#import "WLPhoneValidation.h"
#import "RMPhoneFormat.h"
#import "NSString+Additions.h"

@interface WLPhoneValidation ()

@property (strong, nonatomic) NSMutableCharacterSet *characters;

@end

@implementation WLPhoneValidation

- (void)prepare {
    [super prepare];
    self.characters = [NSMutableCharacterSet decimalDigitCharacterSet];
    [self.characters addCharactersInString:@"+*#,"];
}

- (void)setFormat:(RMPhoneFormat *)format {
    _format = format;
    NSString* text = self.inputView.text;
    if (text.nonempty) {
        self.inputView.text = [format format:text];
        [self validate];
    }
}

- (WLValidationStatus)defineCurrentStatus:(UITextField *)inputView {
    WLValidationStatus status = [super defineCurrentStatus:inputView];
    if (status == WLValidationStatusValid) {
        status = inputView.text.length > 5 ? WLValidationStatusValid : WLValidationStatusInvalid;
    }
    return status;
}

#pragma mark - UITextFieldDelegate

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
    // For some reason, the 'range' parameter isn't always correct when backspacing through a phone number
    // This calculates the proper range from the text field's selection range.
    UITextRange *selRange = textField.selectedTextRange;
    NSInteger start = [textField offsetFromPosition:textField.beginningOfDocument toPosition:selRange.start];
    NSInteger end = [textField offsetFromPosition:textField.beginningOfDocument toPosition:selRange.end];
    NSRange repRange;
    if (start == end && string.length == 0) {
        repRange = NSMakeRange(start - 1, 1);
    } else {
        repRange = NSMakeRange(start, end - start);
    }
    
    // This is what the new text will be after adding/deleting 'string'
    NSString *txt = [textField.text stringByReplacingCharactersInRange:repRange withString:string];
    // This is the newly formatted version of the phone number
    NSString *phone = [self.format format:txt];
    // If these are the same then just let the normal text changing take place
    if ([phone isEqualToString:txt]) {
        return YES;
    } else {
        // The two are different which means the adding/removal of a character had a bigger effect
        // from adding/removing phone number formatting based on the new number of characters in the text field
        // The trick now is to ensure the cursor stays after the same character despite the change in formatting.
        // So first let's count the number of non-formatting characters up to the cursor in the unchanged text.
        int cnt = 0;
        for (NSUInteger i = 0; i < repRange.location + string.length; i++) {
            if ([self.characters characterIsMember:[txt characterAtIndex:i]]) {
                cnt++;
            }
        }
        
        // Now let's find the position, in the newly formatted string, of the same number of non-formatting characters.
        NSUInteger pos = [phone length];
        int cnt2 = 0;
        for (NSUInteger i = 0; i < [phone length]; i++) {
            if ([self.characters characterIsMember:[phone characterAtIndex:i]]) {
                cnt2++;
            }
            
            if (cnt2 == cnt) {
                pos = i + 1;
                break;
            }
        }
        
        // Replace the text with the updated formatting
        textField.text = phone;
        
        // Make sure the caret is in the right place
        UITextPosition *startPos = [textField positionFromPosition:textField.beginningOfDocument offset:pos];
        UITextRange *textRange = [textField textRangeFromPosition:startPos toPosition:startPos];
        textField.selectedTextRange = textRange;
        return NO;
    }
}

@end
