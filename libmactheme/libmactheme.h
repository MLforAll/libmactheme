//
//  MacTheme.h
//  MacTheme
//
//  Created by Kelian on 28/06/2020.
//  Copyright © 2020 MLforAll. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : uint8_t
{
    kThemeUnknown = -1,
    kThemeLight = 0,
    kThemeDark = 1,
    kThemeAuto = 2,
} os_theme_t;

@interface MacTheme : NSObject

+ (os_theme_t)detectThemeIgnoringAuto;
+ (os_theme_t)detectTheme;

+ (BOOL)setTheme:(os_theme_t)theme error:(NSString **)errMsg;

@end
