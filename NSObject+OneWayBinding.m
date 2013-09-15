//
//  NSObject+OneWayBinding.m
//
//  Created by Johannes Dörr on 15.09.12.
//
//

#import <objc/message.h>
#import "NSObject+OneWayBinding.h"


static char bindingsKey;

@implementation JDPropertyUpdater

- (id)initWithReceiver:(NSObject *)aReceiver
       andPropertyName:(NSString *)aPropertyName
             andSender:(NSObject *)aSender
            andKeyPath:(NSString *)aKeyPath
          andTransform:(JDTransformBlockType)aTransform
       skipEqualsCheck:(BOOL)skipEqualsCheckVal;
{
    if (self = [super init]) {
        receiver = aReceiver;
        propertyName = aPropertyName;
        sender = aSender;
        keyPath = aKeyPath;
        transform = aTransform;
        skipEqualsCheck = skipEqualsCheckVal;
        [sender addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:nil];
        [receiver setValue:transform([sender valueForKeyPath:keyPath]) forKeyPath:propertyName];
        //NSLog(@"Init OneWayBinding: %@ -> %@ %d %d", keyPath, propertyName, (int)self, (int)sender);
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"Dealloc OneWayBinding: %@ -> %@ %d %d", keyPath, propertyName, (int)self, (int)sender);
    [sender removeObserver:self forKeyPath:keyPath];
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object != sender || ![aKeyPath isEqualToString:keyPath]) return;
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    BOOL isImmutable = ([newValue isKindOfClass:([NSString class])] || [newValue isKindOfClass:([NSNumber class])]);
    if (skipEqualsCheck ||
        (isImmutable && ![[change objectForKey:NSKeyValueChangeNewKey] isEqual:[change objectForKey:NSKeyValueChangeOldKey]]) ||
        (!isImmutable && [change objectForKey:NSKeyValueChangeNewKey] != [change objectForKey:NSKeyValueChangeOldKey])) {
        //NSLog(@"Notification in OneWayBinding: %@ -> %@ (%@)", keyPath, propertyName, isImmutable ? @"immutable" : @"mutable");
        [receiver setValue:transform([sender valueForKeyPath:keyPath]) forKeyPath:propertyName];
    }
}

@end


@implementation NSObject (OneWayBinding)

- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPath:(NSString *)keyPath
{
    JDTransformBlockType transform = ^(id value) {
        return value;
    };
    [self bind:property toObject:object withKeyPath:keyPath withTransform:transform skipEqualsCheckVal:FALSE];
}

- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPath:(NSString *)keyPath withTransform:(JDTransformBlockType)transform
{
    [self bind:property toObject:object withKeyPath:keyPath withTransform:transform skipEqualsCheckVal:FALSE];
}

- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPath:(NSString *)keyPath withTransform:(JDTransformBlockType)transform skipEqualsCheckVal:(BOOL)skipEqualsCheckVal
{
    //NSLog(@"bind %@ to %@", property, keyPath);
    NSMutableDictionary* bindings = objc_getAssociatedObject(self, &bindingsKey);
    if (bindings == nil) {
        bindings = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &bindingsKey, bindings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    JDPropertyUpdater* updater = [bindings objectForKey:property];
    if (updater != nil) {
        [bindings removeObjectForKey:property];
    }
    if (object != nil) {
        updater = [[JDPropertyUpdater alloc] initWithReceiver:self
                                            andPropertyName:property
                                                  andSender:object andKeyPath:keyPath
                                               andTransform:transform
                                            skipEqualsCheck:skipEqualsCheckVal];
        [bindings setObject:updater forKey:property];
    }
}

@end
