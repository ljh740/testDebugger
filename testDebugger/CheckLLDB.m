//
//  CheckLLDB.m
//  testDebugger
//
//  Created by jie on 2020/4/13.
//  Copyright © 2020 jie. All rights reserved.
//

#import "CheckLLDB.h"
/// method1
#include <stdio.h>
#include <unistd.h>
#include <termios.h>
#include <sys/ioctl.h>
// method2
 #include <signal.h>
// method3

#include <sys/types.h>
#import "MyPtrace.h"

// method

@implementation CheckLLDB
+ (BOOL)method1 {
    struct winsize win;
    return isatty(1) && !ioctl(1, TIOCGWINSZ, &win) && !win.ws_col;
}

void handler(int signo)
{
    printf("not traced by lldb\n");
}

+ (BOOL)method2 {
    signal(SIGTRAP, handler);
    __asm__ ("int3");
    printf("traced by lldb\n");
    return NO;
}

+ (BOOL)method3 {
    int value = ptrace(PT_TRACE_ME, 0, NULL, 0);
    if (ptrace(0, 0, NULL, 0) == -1) {
        printf("traced by lldb");
    } else {
        printf("not traced by lldb");
    }
    // 中断调试
//    int value2 = ptrace(PT_DENY_ATTACH, 0, 1, 0);
    return value == -1;
}

//__attribute__((__always_inline)) bool checkTracing() {
//
//    size_t size = sizeof(struct kinfo_proc);
//
//    struct kinfo_proc proc;
//
//    memset(&proc, 0, size);
//
//    int name[4];
//
//    name[0] = CTL_KERN;
//
//    name[1] = KERN_PROC;
//
//    name[2] = KERN_PROC_PID;
//
//    name[3] = getpid();
//
//    sysctl(name, 4, &proc, &size, NULL, 0);
//
//    return proc.kp_proc.p_flag & P_TRACED;
//
//}
@end
