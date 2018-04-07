//
//  HTMLKitTestUtil.m
//  HTMLKit
//
//  Created by Iska on 11/04/16.
//  Copyright © 2016 BrainCookie. All rights reserved.
//

#import "HTMLKitTestUtil.h"
#import <objc/runtime.h>

@implementation HTMLKitTestUtil

+ (NSInvocation *)addTestToClass:(Class)cls withName:(NSString *)name block:(id)block
{
	IMP implementation = imp_implementationWithBlock(block);
	const char *types = [[NSString stringWithFormat:@"%s%s%s", @encode(id), @encode(id), @encode(SEL)] UTF8String];
	
	SEL selector = NSSelectorFromString(name);
	class_addMethod(cls, selector, implementation, types);

	NSMethodSignature *signature = [cls instanceMethodSignatureForSelector:selector];
	NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
	invocation.selector = selector;

	return invocation;
}

+ (id)ivarForInstacne:(id)instance name:(NSString *)name
{
	Ivar ivar = class_getInstanceVariable([instance class], [name UTF8String]);
	return object_getIvar(instance, ivar);
}

+ (NSString *)pathForFixture:(NSString *)fixture ofType:(NSString *)type inDirectory:(NSString *)directory
{
	// Try testing bundle first
	NSString *path = [[NSBundle bundleForClass:self.class] pathForResource:fixture ofType:type inDirectory:directory];
	if (path) {
		return path;
	}

	path = [[@(__FILE__) stringByDeletingLastPathComponent] stringByDeletingLastPathComponent];
	if (directory) {
		path = [path stringByAppendingPathComponent:directory];
	}

	NSString *resource = type ? [NSString stringWithFormat:@"%@.%@", fixture, type] : fixture;
	path = [path stringByAppendingPathComponent:resource];

	return path;
}

@end
