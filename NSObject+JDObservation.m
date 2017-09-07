//
//  NSObject+JDObservation.m
//
//  Created by Johannes Dörr on 23.09.12.
//
//

#import <objc/message.h>
#import "NSObject+JDObservation.h"

static char observersKey;

@implementation JDKeyPathObserver

- (id)initWithReceiver:(NSObject *)aReceiver
           andSelector:(SEL)aSelector
            andKeyPath:(NSString *)aKeyPath
             andSender:(NSObject *)aSender
               options:(NSKeyValueObservingOptions)theOptions
       skipEqualsCheck:(BOOL)skipEqualsCheckVal
{
    if (self = [super init]) {
        receiver = aReceiver;
        keyPath = aKeyPath;
        sender = aSender;
        selector = aSelector;
        selectorContainsChange = [NSStringFromSelector(selector) componentsSeparatedByString:@":"].count > 3;
        
        invocation = [NSInvocation invocationWithMethodSignature:[receiver methodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:receiver];
        [invocation setArgument:&sender atIndex:2];
        [invocation setArgument:&keyPath atIndex:3];

        options = theOptions;
        skipEqualsCheck = skipEqualsCheckVal;
        [self createObserver];
    }
    return self;
}

- (void)destroy
{
    [self deleteObserver];
}

- (void)createObserver
{
    [sender addObserver:self
             forKeyPath:keyPath
                options:options+NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld
                context:nil];
}

- (void)deleteObserver
{
    [sender removeObserver:self forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object != sender || ![aKeyPath isEqualToString:keyPath]) return;
    [self valueChanged:change];
}

- (void)valueChanged:(NSDictionary *)change
{
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    BOOL isImmutable = ([newValue isKindOfClass:([NSString class])] || [newValue isKindOfClass:([NSNumber class])]);
    if (skipEqualsCheck ||
        (isImmutable && ![[change objectForKey:NSKeyValueChangeNewKey] isEqual:[change objectForKey:NSKeyValueChangeOldKey]]) ||
        (!isImmutable && [change objectForKey:NSKeyValueChangeNewKey] != [change objectForKey:NSKeyValueChangeOldKey])) {
        if (selectorContainsChange) {
            [invocation setArgument:&change atIndex:4];
        }
        [invocation invoke];
    }
}

@end


@implementation NSObject (JDObservation)

- (Class)keyPathObserverClass
{
    return JDKeyPathObserver.class;
}

- (void)unobserveKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector
{
    for (NSString *keyPath in keyPaths) {
        [self unobserveKeyPath:keyPath withObserver:observer withSelector:selector];
    }
}

- (void)unobserveKeyPath:(NSString *)keyPath withObserver:(NSObject *)observer withSelector:(SEL)selector
{
    NSMutableDictionary *observers = objc_getAssociatedObject(self, &observersKey);
    if (observers == nil) {
        return;
    }
    NSArray *key = @[[NSValue valueWithNonretainedObject:observer], keyPath, NSStringFromSelector(selector)];
    JDKeyPathObserver *keyPathObserver = [observers objectForKey:key];
    if (keyPathObserver != nil) {
        [keyPathObserver destroy];
        [observers removeObjectForKey:key];
    }
}

- (void)observeKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector
{
    [self observeKeyPaths:keyPaths withObserver:observer withSelector:selector options:0 skipEqualsCheckVal:FALSE];
}

- (void)observeKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector options:(NSKeyValueObservingOptions)options skipEqualsCheckVal:(BOOL)skipEqualsCheckVal
{
    for (NSString *keyPath in keyPaths) {
        [self observeKeyPath:keyPath withObserver:observer withSelector:selector options:options skipEqualsCheckVal:skipEqualsCheckVal];
    }
}

- (void)observeKeyPath:(NSString *)keyPath withObserver:(NSObject *)observer withSelector:(SEL)selector
{
    [self observeKeyPath:keyPath withObserver:observer withSelector:selector options:0 skipEqualsCheckVal:FALSE];
}

- (void)observeKeyPath:(NSString *)keyPath withObserver:(NSObject *)observer withSelector:(SEL)selector options:(NSKeyValueObservingOptions)options skipEqualsCheckVal:(BOOL)skipEqualsCheckVal
{
    NSMutableDictionary *observers = objc_getAssociatedObject(self, &observersKey);
    if (observers == nil) {
        observers = [NSMutableDictionary dictionaryWithCapacity:1];
        objc_setAssociatedObject(self, &observersKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSArray *key = @[[NSValue valueWithNonretainedObject:observer], keyPath, NSStringFromSelector(selector)];
    JDKeyPathObserver *keyPathObserver = [[self.keyPathObserverClass alloc] initWithReceiver:observer andSelector:selector andKeyPath:keyPath andSender:self options:options skipEqualsCheck:skipEqualsCheckVal];
    [observers setObject:keyPathObserver forKey:key];
}

@end
