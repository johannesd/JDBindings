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
    NSString *keyPath;
    __unsafe_unretained NSObject *sender;
}

- (id)initWithReceiver:(NSObject*)receiver
           andSelector:(SEL)selector
            andKeyPath:(NSString *)keyPath
             andSender:(NSObject *)sender;

@end


@interface NSObject (JDObservation)

- (void)unobserveKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector;
- (void)unobserveKeyPath:(NSString *)keyPath withObserver:(NSObject *)observer withSelector:(SEL)selector;
- (void)observeKeyPaths:(NSArray *)keyPaths withObserver:(NSObject *)observer withSelector:(SEL)selector;
- (void)observeKeyPath:(NSString *)keyPath withObserver:(NSObject *)observer withSelector:(SEL)selector;

@end
