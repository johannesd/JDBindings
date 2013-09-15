//
//  NSObject+OneWayBinding.h
//
//  Created by Johannes Dörr on 15.09.12.
//
//

#import <Foundation/Foundation.h>


typedef id (^JDTransformBlockType)(id);

@interface JDPropertyUpdater : NSObject
{
    __weak NSObject *receiver;
    NSString *propertyName;
    __unsafe_unretained NSObject *sender;
    NSString *keyPath;
    JDTransformBlockType transform;
    BOOL skipEqualsCheck;
}

- (id)initWithReceiver:(NSObject *)receiver
       andPropertyName:(NSString *)propertyName
             andSender:(NSObject *)sender
            andKeyPath:(NSString *)keyPath
          andTransform:(JDTransformBlockType)transform
       skipEqualsCheck:(BOOL)skipEqualsCheck;

@end


@interface NSObject (OneWayBinding)

- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPath:(NSString *)keyPath;
- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPath:(NSString *)keyPath withTransform:(JDTransformBlockType)transform;
- (void)bind:(NSString *)property toObject:(NSObject *)object withKeyPath:(NSString *)keyPath withTransform:(JDTransformBlockType)transform skipEqualsCheckVal:(BOOL)skipEqualsCheckVal;

@end
