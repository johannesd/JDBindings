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
//    if (![[change objectForKey:NSKeyValueChangeNewKey] isEqual:[change objectForKey:NSKeyValueChangeOldKey]] ||
//        (!isImmutable && [change objectForKey:NSKeyValueChangeNewKey] != [change objectForKey:NSKeyValueChangeOldKey])) {
//        NSLog(@"Notification in Observation: %@", keyPath);
//        objc_msgSend(receiver, selector, sender, keyPath);
//        id (*response)(id, SEL, id, id) = (id (*)(id, SEL, id, id)) objc_msgSend;
//        response(receiver, selector, sender, keyPath);
//        [receiver performSelector:selector withObject:sender];
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
        [receiver performSelector:selector withObject:sender withObject:keyPath];
#pragma clang diagnostic pop
    }
}

@end


@implementation NSObject (JDObservation)

- (void)unobserveKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector
{
    NSMutableDictionary *observers = objc_getAssociatedObject(self, &observersKey);
    if (observers == nil) {
        return;
    }
    for (NSString *keyPath in keyPaths) {
        NSArray *key = @[[NSValue valueWithNonretainedObject:observer], keyPath, NSStringFromSelector(selector)];
        JDKeyPathObserver *keyPathObserver = [observers objectForKey:key];
        if (keyPathObserver != nil) {
            [observers removeObjectForKey:key];
        }
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
        [observers removeObjectForKey:key];
    }
}

- (void)observeKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector
{
    NSMutableDictionary *observers = objc_getAssociatedObject(self, &observersKey);
    if (observers == nil) {
        observers = [NSMutableDictionary dictionaryWithCapacity:keyPaths.count];
        objc_setAssociatedObject(self, &observersKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    for (NSString *keyPath in keyPaths) {
        NSArray *key = @[[NSValue valueWithNonretainedObject:observer], keyPath, NSStringFromSelector(selector)];
        JDKeyPathObserver *keyPathObserver = [[JDKeyPathObserver alloc] initWithReceiver:observer andSelector:selector andKeyPath:keyPath andSender:self];
        [observers setObject:keyPathObserver forKey:key];
    }
}

- (void)observeKeyPath:(NSString *)keyPath withObserver:(NSObject *)observer withSelector:(SEL)selector
{
    NSMutableDictionary *observers = objc_getAssociatedObject(self, &observersKey);
    if (observers == nil) {
        observers = [NSMutableDictionary dictionaryWithCapacity:1];
        objc_setAssociatedObject(self, &observersKey, observers, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    NSArray *key = @[[NSValue valueWithNonretainedObject:observer], keyPath, NSStringFromSelector(selector)];
    JDKeyPathObserver *keyPathObserver = [[JDKeyPathObserver alloc] initWithReceiver:observer andSelector:selector andKeyPath:keyPath andSender:self];
    [observers setObject:keyPathObserver forKey:key];
}

@end
