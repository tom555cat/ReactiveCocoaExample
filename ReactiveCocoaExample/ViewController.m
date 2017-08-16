//
//  ViewController.m
//  ReactiveCocoaExample
//
//  Created by MAC-MiNi on 2017/8/16.
//  Copyright © 2017年 MAC-MiNi. All rights reserved.
//

#import <ReactiveCocoa/ReactiveCocoa.h>
#import "ViewController.h"


@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *button;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    NSArray *array = @[@(1), @(2), @(3)];
    RACSequence *stream = [array rac_sequence];
    
    [stream map:^id(id value) {
        return @(pow([value integerValue], 2));
    }];
    
    NSLog(@"%@", [stream array]);
    
    NSLog(@"%@", [[[array rac_sequence] map:^id(id value) {
        return @(pow([value doubleValue], 2.0));
    }] array]);
    
    NSLog(@"%@", [[[array rac_sequence] map:^id(id value) {
        return [value stringValue];
    }] foldLeftWithStart:@"" reduce:^id(id accumulator, id value) {
        return [accumulator stringByAppendingString:value];
    }]);
    
    RAC(self.button, enabled) = [self.textField.rac_textSignal map:^id(id value) {
        return @([value rangeOfString:@"@"].location != NSNotFound);
    }];
    
    RACSignal *validEmailSignal = [self.textField.rac_textSignal map:^id(id value) {
        return @([value rangeOfString:@"@"].location != NSNotFound);
    }];
    
    self.button.rac_command = [[RACCommand alloc] initWithEnabled:validEmailSignal
                                                      signalBlock:^RACSignal *(id input)
    {
        NSLog(@"Button was pressed.");
        return [RACSignal empty];
    }];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
