//
//  RNBackgroundTimer.m
//  react-native-background-timer
//
//  Created by IjzerenHein on 06-09-2016.
//  Copyright (c) ATO Gear. All rights reserved.
//

@import UIKit;
#import "RNBackgroundTimer.h"

@implementation RNBackgroundTimer {
    UIBackgroundTaskIdentifier bgTask;
    int delay;
    int elapsed;
    NSTimer *timer;
}

RCT_EXPORT_MODULE()

- (NSArray<NSString *> *)supportedEvents { return @[@"backgroundTimer", @"backgroundTimer.timeout", @"backgroundTimer.interval", @"backgroundTimer.chronoTick"]; }

- (void) _start
{
    [self _stop];
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"RNBackgroundTimer" expirationHandler:^{
        // Clean up any unfinished task business by marking where you
        // stopped or ending the task outright.
        [[UIApplication sharedApplication] endBackgroundTask:self->bgTask];
        self->bgTask = UIBackgroundTaskInvalid;
    }];
    
    UIBackgroundTaskIdentifier thisBgTask = bgTask;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([self bridge] != nil && thisBgTask == self->bgTask) {
            [self sendEventWithName:@"backgroundTimer" body:[NSNumber numberWithInt:(int)thisBgTask]];
        }
    });
}

- (void) _stop
{
    if (bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
}

- (void) onTimer:(NSTimer*)timer {
    int timeoutId = [timer.userInfo intValue];
    if ([self bridge] != nil) {
        [self sendEventWithName:@"backgroundTimer.interval" body:[NSNumber numberWithInt: timeoutId]];
    }
}

- (void) onChronoTick {
    elapsed++;
    if ([self bridge] != nil) {
        [self sendEventWithName:@"backgroundTimer.chronoTick" body:[NSNumber numberWithInt: elapsed]];
    }
}

RCT_EXPORT_METHOD(start:(double)_delay
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    delay = _delay;
    [self _start];
    resolve([NSNumber numberWithBool:YES]);
}

RCT_EXPORT_METHOD(stop:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [self _stop];
    resolve([NSNumber numberWithBool:YES]);
}

RCT_EXPORT_METHOD(setTimeout:(int)timeoutId
                     timeout:(double)timeout
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    __block UIBackgroundTaskIdentifier task = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"RNBackgroundTimer" expirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:task];
    }];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, timeout * NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        if ([self bridge] != nil) {
            [self sendEventWithName:@"backgroundTimer.timeout" body:[NSNumber numberWithInt:timeoutId]];
        }
        [[UIApplication sharedApplication] endBackgroundTask:task];
    });
    resolve([NSNumber numberWithBool:YES]);
}

RCT_EXPORT_METHOD(setInterval:(int)timeoutId
                  timeout:(double)timeout
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"RNBackgroundTimer" expirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self->bgTask];
    }];
    
    timer = [NSTimer timerWithTimeInterval:timeout/1000 target:self selector:@selector(onTimer:) userInfo:@(timeoutId) repeats:YES];
      [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

    resolve([NSNumber numberWithBool:YES]);
}

RCT_EXPORT_METHOD(clearInterval:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if (bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
    if (timer) {
            [timer invalidate];
            timer = nil;
        }
    resolve([NSNumber numberWithBool:YES]);
}

RCT_EXPORT_METHOD(startChrono:(int)timeout
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    bgTask = [[UIApplication sharedApplication] beginBackgroundTaskWithName:@"RNBackgroundTimer" expirationHandler:^{
        [[UIApplication sharedApplication] endBackgroundTask:self->bgTask];
    }];
    
    elapsed = 0;
    
    timer = [NSTimer timerWithTimeInterval:timeout/1000 target:self selector:@selector(onChronoTick) userInfo:nil repeats:YES];
      [[NSRunLoop mainRunLoop] addTimer:timer forMode:NSRunLoopCommonModes];

    resolve([NSNumber numberWithBool:YES]);
}


RCT_EXPORT_METHOD(stopChrono:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    elapsed = 0;
    if (bgTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:bgTask];
        bgTask = UIBackgroundTaskInvalid;
    }
    if (timer) {
            [timer invalidate];
            timer = nil;
        }
    resolve([NSNumber numberWithBool:YES]);
}
/*
RCT_EXPORT_METHOD(clearTimeout:(int)timeoutId
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    // Do nothing :)
    // timeout will be ignored in javascript anyway :)
}*/

@end




