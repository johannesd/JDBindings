//
//  NSObject+Observation.m
//
//  Created by Johannes Dörr on 23.09.12.
//
//

#import <objc/message.h>
#import "NSObject+Observation.h"

static char observersKey;

@implementation JDKeyPathObserver

- (id)initWithReceiver:(NSObject *)aReceiver
           andSelector:(SEL)aSelector
            andKeyPath:(NSString *)aKeyPath
             andSender:(NSObject *)aSender
{
    if (self = [super init]) {
        receiver = aReceiver;
        keyPath = aKeyPath;
        sender = aSender;
        selector = aSelector;
        [sender addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:nil];
    }
    return self;
}

- (void)dealloc
{
    [sender removeObserver:self forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    //NSLog(@"Notification in Observation: %@ %@", NSStringFromSelector(selector), keyPath);
    if (object != sender || ![aKeyPath isEqualToString:keyPath]) return;
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    BOOL isImmutable = ([newValue isKindOfClass:([NSString class])] || [newValue isKindOfClass:([NSNumber class])]);
    if ((isImmutable && ![[change objectForKey:NSKeyValueChangeNewKey] isEqual:[change objectForKey:NSKeyValueChangeOldKey]]) ||
        (!isImmutable && [change objectForKey:NSKeyValueChangeNewKey] != [change objectForKey:NSKeyValueChangeOldKey])) {
        //NSLog(@"Notification in Observation: %@", keyPath);
        objc_msgSend(receiver, selector, sender, keyPath);
    }
}

@end


@implementation NSObject (Observation)

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
        observers = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &observersKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSArray *key = [NSArray arrayWithObjects:observer, keyPath, NSStringFromSelector(selector), nil];
    JDKeyPathObserver *keyPathObserver = [observers objectForKey:key];
    if (keyPathObserver != nil) {
        [observers removeObjectForKey:key];
    }
}

- (void)observeKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector
{
    for (NSString *keyPath in keyPaths) {
        [self observeKeyPath:keyPath withObserver:observer withSelector:selector];
    }
}

- (void)observeKeyPath:(NSString *)keyPath withObserver:(NSObject *)observer withSelector:(SEL)selector
{
    NSMutableDictionary *observers = objc_getAssociatedObject(self, &observersKey);
    if (observers == nil) {
        observers = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &observersKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSArray *key = [NSArray arrayWithObjects:observer, keyPath, NSStringFromSelector(selector), nil];
    JDKeyPathObserver *keyPathObserver = [observers objectForKey:key];
    if (keyPathObserver != nil) {
        [observers removeObjectForKey:key];
    }
    keyPathObserver = [[JDKeyPathObserver alloc] initWithReceiver:observer andSelector:selector andKeyPath:keyPath andSender:self];
    [observers setObject:keyPathObserver forKey:key];
}

@end
