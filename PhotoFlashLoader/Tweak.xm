#import "../../PS.h"
#import <dlfcn.h>

%ctor {
    if (isiOS10Up)
        dlopen("/Library/Application Support/PhotoFlash/PhotoFlashiOS10.dylib", RTLD_LAZY);
    else if (isiOS9)
        dlopen("/Library/Application Support/PhotoFlash/PhotoFlashiOS9.dylib", RTLD_LAZY);
    else if (isiOS8)
        dlopen("/Library/Application Support/PhotoFlash/PhotoFlashiOS8.dylib", RTLD_LAZY);
    else if (isiOS7)
        dlopen("/Library/Application Support/PhotoFlash/PhotoFlashiOS7.dylib", RTLD_LAZY);
    else
        dlopen("/Library/Application Support/PhotoFlash/PhotoFlashiOS6.dylib", RTLD_LAZY);
}
