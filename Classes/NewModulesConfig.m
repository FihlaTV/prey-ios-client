//
//  NewModulesConfig.m
//  Prey
//
//  Created by Carlos Yaconi on 11-01-13.
//  Copyright (c) 2013 Fork Ltd. All rights reserved.
//

#import "NewModulesConfig.h"
#import "PreyModule.h"

@implementation NewModulesConfig

- (id) init {
	self = [super init];
	if (self != nil) {
		dataModules = [[NSMutableArray alloc] init];
		actionModules = [[NSMutableArray alloc] init];
        settingModules = [[NSMutableArray alloc] init];
	}
	return self;
}

- (void) addModule: (NSDictionary *) jsonModuleConfig {
    PreyModule *module = [[PreyModule newModuleForName:[jsonModuleConfig objectForKey:@"target"]] retain];
    if (module != nil){
        module.command = [jsonModuleConfig objectForKey:@"command"];
        module.options = [jsonModuleConfig objectForKey:@"options"];
        
        if (module.type == DataModuleType)
            [dataModules addObject:module];
        else if (module.type == ActionModuleType)
            [actionModules addObject:module];
        else if (module.type == SettingModuleType)
            [settingModules addObject:module];
    }
    
    [module release];
}

- (void) runAllModules {
    PreyModule *module;
    
	for (module in dataModules){
        [module performSelector:NSSelectorFromString(module.command)];
	}
    for (module in actionModules){
        [module performSelector:NSSelectorFromString(module.command)];
	}
    for (module in settingModules){
        [module performSelector:NSSelectorFromString(module.command)];
	}
}

@end
