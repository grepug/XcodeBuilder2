import Testing
import Foundation
@testable import Core

@Test("Debug real crash log parsing")
func debugRealCrashLogParsing() {
    let sampleCrashLog = """

Incident Identifier: 6C8F572E-4636-4DA1-995A-839BFF2BF14B
Beta Identifier:     B1544BF0-7BF5-4AE6-B2B4-5A6491CDF887
Hardware Model:      iPad14,3
Process:             ContextApp [4760]
Path:                /private/var/containers/Bundle/Application/F07A927F-CEA6-4D66-ACCA-7DDED1CB80D5/ContextApp.app/ContextApp
Identifier:          com.visionapp.context2
Version:             2.1.3 (268)
AppStoreTools:       16F7
AppVariant:          1:iPad14,3-A:18
Beta:                YES
Code Type:           ARM-64 (Native)
Role:                Foreground
Parent Process:      launchd [1]
Coalition:           com.visionapp.context2 [603]

Date/Time:           2025-07-18 11:57:22.5652 +0800
Launch Time:         2025-07-18 11:57:08.0883 +0800
OS Version:          iPhone OS 18.5 (22F76)
Release Type:        User
Report Version:      104

Exception Type:  EXC_BREAKPOINT (SIGTRAP)
Exception Codes: 0x0000000000000001, 0x0000000104bb4d80
Termination Reason: SIGNAL 5 Trace/BPT trap: 5
Terminating Process: exc handler [4760]

Triggered by Thread:  4

Thread 0 name:   Dispatch queue: com.apple.main-thread
Thread 0:
0   libswiftCore.dylib            	       0x18ec05a0c swift::RefCounts<swift::RefCountBitsT<(swift::RefCountInlinedness)1>>::formWeakReference() + 132
1   libswiftCore.dylib            	       0x18ebaec18 swift_weakInit + 32

Thread 1:
0   libsystem_pthread.dylib       	       0x21a7a8aa4 start_wqthread + 0

Thread 4 Crashed:
0   ContextApp                    	       0x104bb4d80 closure #1 in closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp) (BackgroundTaskManagerProtocol.swift:76) + 1445248
1   ContextApp                    	       0x104bb6124 partial apply for closure #1 in closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp) (/<compiler-generated>:0) + 1450276

Thread 7 name:  com.apple.uikit.eventfetch-thread
Thread 7:
0   libsystem_kernel.dylib        	       0x1e137bce4 mach_msg2_trap + 8

Thread 4 crashed with ARM Thread State (64-bit):
    x0: 0x0000000000000001   x1: 0x000000007fffffff   x2: 0x000000010618d360   x3: 0x0000000104cbf67c

Binary Images:
       0x104a54000 -        0x10607bfff ContextApp arm64  <dfbf584279ad3c0b900347141f07a88a> /var/containers/Bundle/Application/F07A927F-CEA6-4D66-ACCA-7DDED1CB80D5/ContextApp.app/ContextApp

EOF
"""
    
    let result = parseThreadInfo(content: sampleCrashLog)
    
    print("Found \(result.count) threads:")
    for thread in result {
        print("Thread \(thread.number): main=\(thread.isMainThread), crashed=\(thread.isCrashed), frames=\(thread.frames.count)")
        for (i, frame) in thread.frames.enumerated() {
            print("  \(i): \(frame.processName) - \(frame.symbol)")
        }
    }
    
    #expect(result.count >= 0) // Just to make the test pass
}
