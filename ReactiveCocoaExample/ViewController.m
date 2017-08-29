//
//  ViewController.m
//  ReactiveCocoaExample
//
//  Created by MAC-MiNi on 2017/8/16.
//  Copyright © 2017年 MAC-MiNi. All rights reserved.
//

// Pods
#import <ReactiveCocoa/ReactiveCocoa.h>
#import <ReactiveCocoa/RACReturnSignal.h>

#import "ViewController.h"

typedef void(^Blk)(void);

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (weak, nonatomic) IBOutlet UIButton *button;
@property (nonatomic, strong) NSMutableArray *mutableArray;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
//    self.mutableArray = [[NSMutableArray alloc] init];
//    [RACObserve(self, mutableArray) subscribeNext:^(id x) {
//        NSLog(@"发生变化");
//    }];
//    
//    [[self.textField.rac_textSignal flattenMap:^RACStream *(id value) {
//        return [RACReturnSignal return:[NSString stringWithFormat:@"输出:%@", value]];
//    }] subscribeNext:^(id x) {
//        NSLog(@"%@", x);
//    }];
    
    RACSignal *signal = [RACSignal createSignal:^RACDisposable *(id<RACSubscriber> subscriber) {
        [subscriber sendNext:@(99)];
        [subscriber sendCompleted];
        return nil;
    }];
    
    [[signal map:^id(id value) {
        return @([value integerValue] + 100);
    }] subscribeNext:^(id x) {
        NSLog(@"%d", [x integerValue]);
    }];
    
    Blk blk = ^{
        NSLog(@"hello world!");
    };
    
    Blk blk1 = blk();
}

- (IBAction)test:(id)sender {
    [self.mutableArray addObject:@"hello"];
    [self.mutableArray addObject:@"world"];
    [self.mutableArray removeObjectAtIndex:0];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (instancetype)map:(id (^)(id value))block {
    NSCParameterAssert(block != nil);
    
    Class class = self.class;
    
    RACStream *stream = [[self flattenMap:^(id value) {
        
        return [class return:block(value)];
        
    }] setNameWithFormat:@"[%@] -map:", self.name];
    
    return stream;
}

- (instancetype)flattenMap:(RACStream * (^)(id value))block {
    Class class = self.class;
    
    RACStream *stream = [[self bind:^{
        return ^(id value, BOOL *stop) {
            id stream = block(value) ?: [class empty];
            NSCAssert([stream isKindOfClass:RACStream.class], @"Value returned from -flattenMap: is not a stream: %@", stream);
            
            return stream;
        };
    }] setNameWithFormat:@"[%@] -flattenMap:", self.name];
    
    return stream;
}


- (RACSignal *)bind:(RACStreamBindBlock (^)(void))block {
    NSCParameterAssert(block != NULL);
    
    /*
     * -bind: should:
     *
     * 1. Subscribe to the original signal of values.
     * 2. Any time the original signal sends a value, transform it using the binding block.
     * 3. If the binding block returns a signal, subscribe to it, and pass all of its values through to the subscriber as they're received.
     * 4. If the binding block asks the bind to terminate, complete the _original_ signal.
     * 5. When _all_ signals complete, send completed to the subscriber.
     *
     * If any signal sends an error at any point, send that to the subscriber.
     */
    
    RACSignal *signal = [[RACSignal createSignal:^(id<RACSubscriber> subscriber) {
        RACStreamBindBlock bindingBlock = block();
        
        NSMutableArray *signals = [NSMutableArray arrayWithObject:self];
        
        RACCompoundDisposable *compoundDisposable = [RACCompoundDisposable compoundDisposable];
        
        void (^completeSignal)(RACSignal *, RACDisposable *) = ^(RACSignal *signal, RACDisposable *finishedDisposable) {
            BOOL removeDisposable = NO;
            
            @synchronized (signals) {
                [signals removeObject:signal];
                
                if (signals.count == 0) {
                    [subscriber sendCompleted];
                    [compoundDisposable dispose];
                } else {
                    removeDisposable = YES;
                }
            }
            
            if (removeDisposable) [compoundDisposable removeDisposable:finishedDisposable];
        };
        
        void (^addSignal)(RACSignal *) = ^(RACSignal *signal) {
            @synchronized (signals) {
                [signals addObject:signal];
            }
            
            RACSerialDisposable *selfDisposable = [[RACSerialDisposable alloc] init];
            [compoundDisposable addDisposable:selfDisposable];
            
            RACDisposable *disposable = [signal subscribeNext:^(id x) {
                [subscriber sendNext:x];
            } error:^(NSError *error) {
                [compoundDisposable dispose];
                [subscriber sendError:error];
            } completed:^{
                @autoreleasepool {
                    completeSignal(signal, selfDisposable);
                }
            }];
            
            selfDisposable.disposable = disposable;
        };
        
        @autoreleasepool {
            RACSerialDisposable *selfDisposable = [[RACSerialDisposable alloc] init];
            [compoundDisposable addDisposable:selfDisposable];
            
            RACDisposable *bindingDisposable = [self subscribeNext:^(id x) {          // 外层的订阅会订阅original信号，对应于说明1
                // Manually check disposal to handle synchronous errors.
                if (compoundDisposable.disposed) return;
                
                BOOL stop = NO;
                id signal = bindingBlock(x, &stop);                                   // 对应于说明2
                
                @autoreleasepool {
                    if (signal != nil) addSignal(signal);                             // 流程中创建的信号回去订阅，对应于说明3
                    if (signal == nil || stop) {
                        [selfDisposable dispose];
                        completeSignal(self, selfDisposable);
                    }
                }
            } error:^(NSError *error) {
                [compoundDisposable dispose];
                [subscriber sendError:error];
            } completed:^{
                @autoreleasepool {
                    completeSignal(self, selfDisposable);
                }
            }];
            
            selfDisposable.disposable = bindingDisposable;
        }
        
        return compoundDisposable;
    }] setNameWithFormat:@"[%@] -bind:", self.name];
    
    return signal;
}

@end
