//
//  ViewController.m
//  RACStudyProject
//
//  Created by wangjing on 2019/6/11.
//  Copyright © 2019年 Jerry. All rights reserved.
//

#import "ViewController.h"
#import <ReactiveObjC.h>

typedef NS_ENUM(NSUInteger, AccessTwitterResultType) {
    AccessTwitterResultTypeSuccess,
    AccessTwitterResultTypeRefused,
    AccessTwitterResultTypeError,
};


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *accountField;
@property (weak, nonatomic) IBOutlet UITextField *passwordField;
@property (weak, nonatomic) IBOutlet UIButton *loginBtn;

@property (weak, nonatomic) IBOutlet UILabel *stateLabel;
@property (weak, nonatomic) IBOutlet UIButton *accessBtn;
@property (nonatomic,assign) NSInteger clickCount;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.title = @"RACStudy";
    
    [self studyDemoOne_login];
    [self studyDemoTwo_accessTwitter];
    
}

- (void)studyDemoTwo_accessTwitter{
    
    RACSignal *resultSignal = [[self.accessBtn rac_signalForControlEvents:UIControlEventTouchUpInside] flattenMap:^__kindof RACSignal * _Nullable(__kindof UIControl * _Nullable value) {
        return [self requestToAccessTwitterAccount];
    }];
    
    RAC(self.stateLabel,text,@"Nothing now!") = resultSignal;

}

- (RACSignal *)requestToAccessTwitterAccount{
    
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        
        switch (self.clickCount++ % 3) {
                
            case AccessTwitterResultTypeSuccess:
                [subscriber sendNext:@"Access success!"];
                break;
                
            case AccessTwitterResultTypeRefused:
//                [subscriber sendError:[NSError errorWithDomain:@"AccessDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"Access refused!"}]];
                [subscriber sendNext:@"Access refused!"];
                break;
            case AccessTwitterResultTypeError:
//                [subscriber sendError:[NSError errorWithDomain:@"AccessDomain" code:0 userInfo:@{NSLocalizedDescriptionKey:@"An error occurred!"}]];
                [subscriber sendNext:@"Access error!"];
                break;
        }
        
        [subscriber sendCompleted];
        return nil;
    }];
}

- (void)studyDemoOne_login{
    
    // rac signal
    
    RACSignal *validAccountSignal = [self.accountField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return value.length >= 6 ? @(YES) : @(NO);
    }];
    
    RACSignal *validPasswordSignal = [self.passwordField.rac_textSignal map:^id _Nullable(NSString * _Nullable value) {
        return value.length >= 8 ? @(YES) : @(NO);
    }];
    
    // bind signal to property
    
    RAC(self.accountField,backgroundColor) = [validAccountSignal map:^id _Nullable(NSNumber *isValid) {
        return [isValid boolValue] ? [UIColor greenColor] : [UIColor clearColor];
    }];
    RAC(self.passwordField,backgroundColor) = [validPasswordSignal map:^id _Nullable(NSNumber *isValid) {
        return [isValid boolValue] ? [UIColor greenColor] : [UIColor clearColor];
    }];
    
    // 聚合信号，来决定登录按钮是否可用
    
    RACSignal *signUpActiveSignal = [RACSignal combineLatest:@[validAccountSignal,validPasswordSignal] reduce:^id _Nonnull(NSNumber *validAccount,NSNumber *validPassword){
        return @([validAccount boolValue] && [validPassword boolValue]);
    }];
    @weakify(self);
    [signUpActiveSignal subscribeNext:^(NSNumber * signUpValid) {
        @strongify(self);
        self.loginBtn.enabled = [signUpValid boolValue];
    }];
    
    // bind event for login btn
    
    [[[[self.loginBtn rac_signalForControlEvents:UIControlEventTouchUpInside] doNext:^(__kindof UIControl * _Nullable x) {
        @strongify(self);
        self.loginBtn.enabled = NO;
    }] flattenMap:^__kindof RACSignal * _Nullable(__kindof UIControl * _Nullable value) {
        return [self signInSignal];
    }] subscribeNext:^(NSNumber *success) {
        @strongify(self);
        self.loginBtn.enabled = YES;
        if (success) {
            [self performSegueWithIdentifier:@"HomeVC" sender:self];
        }
    }];
}


#pragma mark - private method for demos

// create login callback infomation signal

- (RACSignal *)signInSignal{
    return [RACSignal createSignal:^RACDisposable * _Nullable(id<RACSubscriber>  _Nonnull subscriber) {
        // 请求登录接口
        NSLog(@"登录中...");
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            NSLog(@"登录成功，即将跳转...");
            [subscriber sendNext:@(YES)];
            [subscriber sendCompleted];
        });
        return nil;
    }];
}

@end
