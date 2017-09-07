//
//  NSObject+JDOneWayBinding.m
//
//  Created by Johannes Dörr on 15.09.12.
//
//

#import <objc/message.h>
#import "NSObject+JDOneWayBinding.h"


static char bindingsKey;

@implementation JDPropertyUpdater

- (id)initWithReceiver:(NSObject *)aReceiver
       andPropertyName:(NSString *)aPropertyName
             andSender:(NSObject *)aSender
           andKeyPaths:(NSArray *)theKeyPaths
          andTransform:(JDTransformBlockType)aTransform
       skipEqualsCheck:(BOOL)skipEqualsCheckVal
{
    if (self = [super init]) {
        receiver = aReceiver;
        propertyName = aPropertyName;
        sender = aSender;
        keyPaths = theKeyPaths;
        transform = aTransform;
        skipEqualsCheck = skipEqualsCheckVal;
        for (NSString *keyPath in keyPaths) {
            [sender addObserver:self forKeyPath:keyPath options:NSKeyValueObservingOptionNew+NSKeyValueObservingOptionOld context:nil];
        }
        [self setNewValue];
        //NSLog(@"Init OneWayBinding: %@ -> %@ %d %d", keyPath, propertyName, (int)self, (int)sender);
    }
    return self;
}

- (void)dealloc
{
    //NSLog(@"Dealloc OneWayBinding: %@ -> %@ %d %d", keyPath, propertyName, (int)self, (int)sender);
    for (NSString *keyPath in keyPaths) {
        [sender removeObserver:self forKeyPath:keyPath];
    }
}

- (void)observeValueForKeyPath:(NSString *)aKeyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if (object != sender || ![keyPaths containsObject:aKeyPath]) return;
    id newValue = [change objectForKey:NSKeyValueChangeNewKey];
    BOOL isImmutable = ([newValue isKindOfClass:([NSString class])] || [newValue isKindOfClass:([NSNumber class])] || [newValue isKindOfClass:([NSValue class])]);
    if (skipEqualsCheck ||
        (isImmutable && ![[change objectForKey:NSKeyValueChangeNewKey] isEqual:[change objectForKey:NSKeyValueChangeOldKey]]) ||
        (!isImmutable && [change objectForKey:NSKeyValueChangeNewKey] != [change objectForKey:NSKeyValueChangeOldKey])) {
        //NSLog(@"Notification in OneWayBinding: %@ -> %@ (%@)", keyPath, propertyName, isImmutable ? @"immutable" : @"mutable");
        [self setNewValue];
    }
}

- (void)setNewValue
{
    if (keyPaths.count == 1) {
        [receiver setValue:transform([sender valueForKeyPath:keyPaths[0]]) forKeyPath:propertyName];
    }
    else {
        NSMutableDictionary *values = [NSMutableDictionary dictionaryWithCapacity:keyPaths.count];
        for (NSString *keyPath in keyPaths) {
            values[keyPath] = [sender valueForKeyPath:keyPath];
        }
        [receiver setValue:transform(values) forKeyPath:propertyName];
    }
}

@end


@implementation NSObject (JDOneWayBinding)

- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPath:(NSString *)keyPath
{
    [self bind:property toObject:object withKeyPath:keyPath or:nil];
}

- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPath:(NSString *)keyPath or:(id)defaultValue;
{
    JDTransformBlockType transform = ^(id value) {
        if (value == nil) {
            return defaultValue;
        }
        return value;
    };
    [self bind:property toObject:object withKeyPath:keyPath withTransform:transform skipEqualsCheckVal:FALSE];
}

- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPath:(NSString *)keyPath withTransform:(JDTransformBlockType)transform
{
    [self bind:property toObject:object withKeyPaths:(keyPath != nil ? @[keyPath] : nil) withTransform:transform skipEqualsCheckVal:FALSE];
}

- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPath:(NSString *)keyPath withTransform:(JDTransformBlockType)transform skipEqualsCheckVal:(BOOL)skipEqualsCheckVal
{
    [self bind:property toObject:object withKeyPaths:(keyPath != nil ? @[keyPath] : nil) withTransform:transform skipEqualsCheckVal:skipEqualsCheckVal];
}

- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPaths:(NSArray *)keyPaths withTransform:(JDTransformBlockType)transform
{
    [self bind:property toObject:object withKeyPaths:keyPaths withTransform:transform skipEqualsCheckVal:FALSE];
}

- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPaths:(NSArray *)keyPaths withTransform:(JDTransformBlockType)transform skipEqualsCheckVal:(BOOL)skipEqualsCheckVal
{
    //NSLog(@"bind %@ to %@", property, keyPath);
    NSMutableDictionary *bindings = objc_getAssociatedObject(self, &bindingsKey);
    if (bindings == nil) {
        bindings = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &bindingsKey, bindings, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    JDPropertyUpdater *updater = [bindings objectForKey:property];
    if (updater != nil) {
        [bindings removeObjectForKey:property];
    }
    if (object != nil) {
        updater = [[JDPropertyUpdater alloc] initWithReceiver:self
                                              andPropertyName:property
                                                    andSender:object
                                                  andKeyPaths:keyPaths
                                                 andTransform:transform
                                              skipEqualsCheck:skipEqualsCheckVal];
        [bindings setObject:updater forKey:property];
    }
}

- (void)removeAllBindings
{
    NSMutableDictionary *bindings = objc_getAssociatedObject(self, &bindingsKey);
    if (bindings != nil) {
        [bindings removeAllObjects];
    }
}

+ (JDTransformBlockType)invertNumberTransform
{
    return ^NSNumber *(NSNumber *val) {
        return @(![val boolValue]);
    };
}

@end
