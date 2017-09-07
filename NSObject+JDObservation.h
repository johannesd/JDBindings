//
//  NSObject+JDObservation.h
//
//  Created by Johannes Dörr on 23.09.12.
//
//

#import <Foundation/Foundation.h>


@interface JDKeyPathObserver : NSObject
{
    __weak NSObject *receiver;
    SEL selector;
    BOOL selectorContainsChange;
    NSInvocation *invocation;
    NSString *keyPath;
    __unsafe_unretained NSObject *sender;
    BOOL skipEqualsCheck;
    NSKeyValueObservingOptions options;
}

- (id)initWithReceiver:(NSObject*)receiver
           andSelector:(SEL)selector
            andKeyPath:(NSString *)keyPath
             andSender:(NSObject *)sender
               options:(NSKeyValueObservingOptions)options
       skipEqualsCheck:(BOOL)skipEqualsCheck;

- (void)destroy;
- (void)valueChanged:(NSDictionary *)change;

@end


@interface NSObject (JDObservation)

- (Class)keyPathObserverClass;
- (void)unobserveKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector;
- (void)unobserveKeyPath:(NSString *)keyPath withObserver:(NSObject *)observer withSelector:(SEL)selector;
- (void)observeKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector;
- (void)observeKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector options:(NSKeyValueObservingOptions)options skipEqualsCheckVal:(BOOL)skipEqualsCheckVal;
- (void)observeKeyPath:(NSString *)keyPath withObserver:(NSObject *)observer withSelector:(SEL)selector;
- (void)observeKeyPath:(NSString *)keyPath withObserver:(NSObject *)observer withSelector:(SEL)selector options:(NSKeyValueObservingOptions)options skipEqualsCheckVal:(BOOL)skipEqualsCheckVal;

@end
