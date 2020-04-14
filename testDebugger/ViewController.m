//
//  ViewController.m
//  testDebugger
//
//  Created by jie on 2020/4/13.
//  Copyright © 2020 jie. All rights reserved.
//

#import "ViewController.h"
#import "CheckLLDB.h"
#include <sys/sysctl.h>
#include <unistd.h>
#include <stdint.h>
#import "MyPtrace.h"
#include <sys/wait.h>
#include <stdio.h>
#include <errno.h>

static int check_debugger( ) __attribute__((always_inline));
 
int check_debugger( )
{
    size_t size = sizeof(struct kinfo_proc);
    struct kinfo_proc info;
    int ret,name[4];
     
    memset(&info, 0, sizeof(struct kinfo_proc));
     
    name[0] = CTL_KERN;
    name[1] = KERN_PROC;
    name[2] = KERN_PROC_PID;
    name[3] = getpid();
     
    if((ret = (sysctl(name, 4, &info, &size, NULL, 0)))){
        return ret;  //sysctl() failed for some reason
    }
     
    return (info.kp_proc.p_flag & P_TRACED) ? 1 : 0;
}



static int debugger_attached(void)
{
    int pid;
     
    int from_child[2] = {-1, -1};
     
    if (pipe(from_child) < 0) {
        return -1;
    }
     
    pid = fork();
    if (pid == -1) {
        return -1;
    }
     
    if (pid == 0) {
        uint8_t ret = 0;
        int ppid = getppid();
         
        close(from_child[0]);
         
        if (ptrace(PT_ATTACH, ppid, NULL, NULL) == 0) {
            waitpid(ppid, NULL, 0);
             
            write(from_child[1], &ret, sizeof(ret));
             
            ptrace(PT_DETACH, ppid, NULL, NULL);
            exit(0);
        }
         
        ret = 1;
        write(from_child[1], &ret, sizeof(ret));
         
        exit(0);
    } else {
        uint8_t ret = -1;
 
        while ((read(from_child[0], &ret, sizeof(ret)) < 0)
            && (errno == EINTR));
         
        if (ret < 0) {
        }
         
        close(from_child[1]);
        close(from_child[0]);
         
        waitpid(pid, NULL, 0);
         
        return ret;
    }
}

@interface ViewController ()
@property (nonatomic, weak) UILabel *label;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    UILabel *label = UILabel.new;
    label.textColor = UIColor.redColor;
    label.frame = CGRectMake(0, 0, 200, 100);
    [self.view addSubview:label];

    label.center = self.view.center;
    label.textAlignment = NSTextAlignmentCenter;
    label.text = @"hello";
    self.label = label;

    BOOL isTrace = NO;
    /// 有效
//    isTrace = CheckLLDB.method1;
    /// 有效 直接关闭
//    [CheckLLDB method2];
    /// 无效 未知原因 在PT_DENY_ATTACH下闪退
//    isTrace = CheckLLDB.method3;

    // 有效
//    isTrace = check_debugger();
    
    // 有效
    isTrace = debugger_attached();
    
    label.text = isTrace ? @"traced by lldb" : @"no traced";
    
}

@end
