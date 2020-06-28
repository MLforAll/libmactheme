//
//  MacTheme.m
//  MacTheme
//
//  Created by Kelian on 28/06/2020.
//  Copyright © 2020 MLforAll. All rights reserved.
//

#import "libmactheme.h"
#include <dlfcn.h>

#define SLSPATH    "/System/Library/PrivateFrameworks/SkyLight.framework/Versions/A/SkyLight"
#define SLSHDL      dlopen(SLSPATH, RTLD_LAZY)

static BOOL
skylightDetectAutomaticTheme(BOOL *ret)
{
    BOOL (*isThemeAutoSwitch)(void);
    void *handle;

    if (!(handle = SLSHDL))
        return NO;

    if (!(isThemeAutoSwitch = dlsym(handle, "SLSGetAppearanceThemeSwitchesAutomatically")))
    {
        (void) dlclose(handle);
        return NO;
    }
    *ret = isThemeAutoSwitch();

    (void) dlclose(handle);
    return YES;
}

static BOOL
skylightDetectTheme(os_theme_t *theme)
{
    void *handle;
    BOOL (*getTheme)(void);

    if (!(handle = SLSHDL))
        return NO;

    if (!(getTheme = dlsym(handle, "SLSGetAppearanceThemeLegacy")))
    {
        (void) dlclose(handle);
        return NO;
    }
    *theme = getTheme() ? kThemeDark : kThemeLight;

    (void) dlclose(handle);
    return YES;
}

static BOOL
skylightSetTheme(os_theme_t theme, NSString **errMsg)
{
    void (*setTheme)(BOOL);
    void (*setThemeAutoSwitch)(BOOL);
    void *handle;

    if (!(handle = SLSHDL))
    {
        if (errMsg)
            *errMsg = @"Skylight.framework Error";
        return NO;
    }

    if (!(setTheme = dlsym(handle, "SLSSetAppearanceThemeLegacy")))
    {
        (void) dlclose(handle);
        if (errMsg)
            *errMsg = @"function pointers not found";
        return NO;
    }

    if (theme != kThemeAuto)
        setTheme(theme == kThemeDark);
    if ((setThemeAutoSwitch = dlsym(handle, "SLSSetAppearanceThemeSwitchesAutomatically")))
        setThemeAutoSwitch(theme == kThemeAuto);
    return YES;
}

@implementation MacTheme

+ (os_theme_t)detectThemeIgnoringAuto
{
    os_theme_t ret;

    if (@available(macOS 10.12, *))
        if (skylightDetectTheme(&ret))
            return ret;

    NSDictionary *udsDict = [[NSUserDefaults standardUserDefaults] persistentDomainForName:NSGlobalDomain];
    NSString *style = [udsDict valueForKey:@"AppleInterfaceStyle"];
    return (style && [style.lowercaseString isEqualToString:@"dark"]) ? kThemeDark : kThemeLight;
}

+ (os_theme_t)detectTheme
{
    BOOL isAuto;

    if (@available(macOS 10.15, *))
        if (skylightDetectAutomaticTheme(&isAuto) && isAuto)
            return kThemeAuto;

    return [self detectThemeIgnoringAuto];
}

+ (BOOL)setTheme:(os_theme_t)theme error:(NSString **)errMsg
{
    if ([MacTheme detectTheme] == theme)
        return YES;

    if (@available(macOS 10.12, *))
    {
        NSString *errMsgTmp;
        if (skylightSetTheme(theme, &errMsgTmp))
            return YES;
        if (@available(macOS 10.15, *))
        {
            if (errMsg)
                *errMsg = errMsgTmp;
            return NO;
        }
    }

    NSDictionary <NSString *, id> *errInfo;
    NSString *scpt_src = [NSString stringWithFormat:@"tell application \"System Events\" to tell appearance preferences to set dark mode to %i", (int)theme];
    NSAppleScript *scpt = [[NSAppleScript alloc] initWithSource:scpt_src];
    BOOL ok = [scpt executeAndReturnError:&errInfo] != nil;
    if (!ok && errMsg)
        *errMsg = errInfo[@"NSAppleScriptErrorMessage"];
    return ok;
}

@end
