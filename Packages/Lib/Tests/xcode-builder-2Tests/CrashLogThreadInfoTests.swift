import Testing
import Foundation
@testable import Core

@Suite("CrashLogThreadInfo Tests")
struct CrashLogThreadInfoTests {
    
    // MARK: - Test Data
    
    private static let sampleCrashLog = """

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
2   SwiftUICore                   	       0x2507831d0 EnvironmentValues.preferenceBridge.setter + 36
3   SwiftUI                       	       0x194a2be60 closure #1 in PlatformViewChild.updateValue() + 1616
4   SwiftUICore                   	       0x250782b88 Signpost.traceInterval<A>(object:_:_:closure:) + 452
5   SwiftUI                       	       0x194c8ba78 PlatformViewChild.updateValue() + 176
6   SwiftUI                       	       0x1949b6d30 partial apply for implicit closure #1 in closure #1 in closure #1 in Attribute.init<A>(_:) + 32
7   AttributeGraph                	       0x1bd6fb418 AG::Graph::UpdateStack::update() + 524
8   AttributeGraph                	       0x1bd6fafec AG::Graph::update_attribute(AG::data::ptr<AG::Node>, unsigned int) + 420
9   AttributeGraph                	       0x1bd700368 AG::Subgraph::update(unsigned int) + 848
10  SwiftUICore                   	       0x250e11cdc specialized GraphHost.runTransaction(_:do:id:) + 328
11  SwiftUICore                   	       0x2507019f4 GraphHost.flushTransactions() + 180
12  SwiftUI                       	       0x194a56eb8 <deduplicated_symbol> + 24
13  SwiftUICore                   	       0x25070c884 partial apply for closure #1 in ViewGraphDelegate.updateGraph<A>(body:) + 28
14  SwiftUICore                   	       0x2506f9c44 ViewRendererHost.updateViewGraph<A>(body:) + 120
15  SwiftUICore                   	       0x25070c85c ViewGraphDelegate.updateGraph<A>(body:) + 84
16  SwiftUI                       	       0x194a56e64 closure #1 in closure #1 in closure #1 in _UIHostingView.beginTransaction() + 172
17  SwiftUI                       	       0x194a56e98 partial apply for closure #1 in closure #1 in closure #1 in _UIHostingView.beginTransaction() + 24
18  SwiftUICore                   	       0x2506ea6c0 closure #1 in static Update.ensure<A>(_:) + 56
19  SwiftUICore                   	       0x2506e9f28 static Update.ensure<A>(_:) + 96
20  SwiftUI                       	       0x194a56da8 partial apply for closure #1 in closure #1 in _UIHostingView.beginTransaction() + 80
21  SwiftUICore                   	       0x2507e15c0 <deduplicated_symbol> + 28
22  SwiftUICore                   	       0x2507ebf0c specialized closure #1 in static NSRunLoop.addObserver(_:) + 120
23  CoreFoundation                	       0x19016f2a0 __CFRUNLOOP_IS_CALLING_OUT_TO_AN_OBSERVER_CALLBACK_FUNCTION__ + 36
24  CoreFoundation                	       0x19016f91c __CFRunLoopDoObservers + 536
25  CoreFoundation                	       0x19016d0e8 __CFRunLoopRun + 944
26  CoreFoundation                	       0x19016ec3c CFRunLoopRunSpecific + 572
27  GraphicsServices              	       0x1dd34d454 GSEventRunModal + 168
28  UIKitCore                     	       0x192b81274 -[UIApplication _run] + 816
29  UIKitCore                     	       0x192b4ca28 UIApplicationMain + 336
30  SwiftUI                       	       0x194c917a4 closure #1 in KitRendererCommon(_:) + 168
31  SwiftUI                       	       0x19499701c runApp<A>(_:) + 112
32  SwiftUI                       	       0x194996ed0 static App.main() + 180
33  ContextApp                    	       0x104c4e7d8 main (in ContextApp) (ContextBackendModelsTestApp.swift:0) + 2074584
34  dyld                          	       0x1b7043f08 start + 6040

Thread 1:
0   libsystem_pthread.dylib       	       0x21a7a8aa4 start_wqthread + 0

Thread 2:
0   libsystem_pthread.dylib       	       0x21a7a8aa4 start_wqthread + 0

Thread 3:
0   libsystem_pthread.dylib       	       0x21a7a8aa4 start_wqthread + 0

Thread 4 Crashed:
0   ContextApp                    	       0x104bb4d80 closure #1 in closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp) (BackgroundTaskManagerProtocol.swift:76) + 1445248
1   ContextApp                    	       0x104bb6124 partial apply for closure #1 in closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp) (/<compiler-generated>:0) + 1450276
2   ContextApp                    	       0x105110cfc closure #1 in Shared.withLock<A>(_:fileID:filePath:line:column:) (in ContextApp) (Shared.swift:168) + 7064828
3   ContextApp                    	       0x10511280c partial apply for closure #1 in Shared.withLock<A>(_:fileID:filePath:line:column:) (in ContextApp) (/<compiler-generated>:0) + 7071756
4   ContextApp                    	       0x105105a50 closure #1 in closure #1 in _PersistentReference<>.withLock<A>(_:) (in ContextApp) (Reference.swift:417) + 7019088
5   ContextApp                    	       0x105105610 closure #1 in _PersistentReference<>.withLock<A>(_:) (in ContextApp) (Reference.swift:416) + 7018000
6   ContextApp                    	       0x105108f88 partial apply for closure #1 in _PersistentReference<>.withLock<A>(_:) (in ContextApp) (/<compiler-generated>:0) + 7032712
7   ContextApp                    	       0x105103e78 _BoxReference.withMutation<A, B>(keyPath:_:) (in ContextApp) + 608 + 7011960
8   ContextApp                    	       0x105105428 _PersistentReference<>.withLock<A>(_:) (in ContextApp) (Reference.swift:398) + 7017512
9   ContextApp                    	       0x105106128 protocol witness for MutableReference.withLock<A>(_:) in conformance <> _PersistentReference<A> (in ContextApp) (/<compiler-generated>:0) + 7020840
10  ContextApp                    	       0x1051106ec Shared.withLock<A>(_:fileID:filePath:line:column:) (in ContextApp) (Shared.swift:145) + 7063276
11  ContextApp                    	       0x104bb4b8c closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp) (/<compiler-generated>:0) + 1444748
12  ContextApp                    	       0x104a65ae5 <deduplicated_symbol> (in ContextApp) + 1 + 72421
13  ContextApp                    	       0x104b44545 <deduplicated_symbol> (in ContextApp) + 1 + 984389
14  ContextApp                    	       0x104a7849d <deduplicated_symbol> (in ContextApp) + 1 + 148637
15  libswift_Concurrency.dylib    	       0x19bd41241 completeTaskWithClosure(swift::AsyncContext*, swift::SwiftError*) + 1

Thread 5:
0   libsystem_kernel.dylib        	       0x1e137bce4 mach_msg2_trap + 8
1   libsystem_kernel.dylib        	       0x1e137f39c mach_msg2_internal + 76
2   libsystem_kernel.dylib        	       0x1e137f2b8 mach_msg_overwrite + 428
3   libsystem_kernel.dylib        	       0x1e137f100 mach_msg + 24
4   libdispatch.dylib             	       0x198103be0 _dispatch_mach_send_and_wait_for_reply + 548
5   libdispatch.dylib             	       0x198103f80 dispatch_mach_send_with_result_and_wait_for_reply + 60
6   libxpc.dylib                  	       0x21a8037f0 xpc_connection_send_message_with_reply_sync + 256
7   Foundation                    	       0x18ee329b0 __NSXPCCONNECTION_IS_WAITING_FOR_A_SYNCHRONOUS_REPLY__ + 16
8   Foundation                    	       0x18eded88c -[NSXPCConnection _sendInvocation:orArguments:count:methodSignature:selector:withProxy:] + 2100
9   CoreFoundation                	       0x19018b82c ___forwarding___ + 996
10  CoreFoundation                	       0x19018baa0 _CF_forwarding_prep_0 + 96
11  AudioSession                  	       0x1af8b30a8 -[AVAudioSession privateSetActive:withOptions:error:accessor:] + 320
12  AudioSession                  	       0x1af8b2f28 -[AVAudioSession setActive:withOptions:error:] + 72
13  ContextApp                    	       0x104b8853c specialized SoundManager.configureAudioSession() (in ContextApp) (SoundManager.swift:69) + 1262908
14  ContextApp                    	       0x104b85780 SoundManager.play(data:) (in ContextApp) (SoundManager.swift:51) + 1251200
15  ContextApp                    	       0x104b88a85 specialized SoundManager.speak(item:region:) (in ContextApp) (SoundManager.swift:43) + 1264261
16  ContextApp                    	       0x104b25855 closure #4 in ContextSegmentView.body.getter (in ContextApp) (ContextSegmentView.swift:126) + 858197
17  ContextApp                    	       0x104a7849d <deduplicated_symbol> (in ContextApp) + 1 + 148637
18  ContextApp                    	       0x104d02ef9 closure #1 in DebounceViewModifier.body(content:) (in ContextApp) (TaskWithOldValueViewModifier.swift:63) + 2813689
19  ContextApp                    	       0x104a65ae5 <deduplicated_symbol> (in ContextApp) + 1 + 72421
20  ContextApp                    	       0x104d02671 closure #1 in closure #1 in TaskWithOldValueViewModifier.body(content:) (in ContextApp) (TaskWithOldValueViewModifier.swift:43) + 2811505
21  ContextApp                    	       0x104a7849d <deduplicated_symbol> (in ContextApp) + 1 + 148637
22  ContextApp                    	       0x104b44545 <deduplicated_symbol> (in ContextApp) + 1 + 984389
23  ContextApp                    	       0x104a7849d <deduplicated_symbol> (in ContextApp) + 1 + 148637
24  libswift_Concurrency.dylib    	       0x19bd41241 completeTaskWithClosure(swift::AsyncContext*, swift::SwiftError*) + 1

Thread 6:
0   libsystem_pthread.dylib       	       0x21a7a8aa4 start_wqthread + 0

Thread 7 name:  com.apple.uikit.eventfetch-thread
Thread 7:
0   libsystem_kernel.dylib        	       0x1e137bce4 mach_msg2_trap + 8
1   libsystem_kernel.dylib        	       0x1e137f39c mach_msg2_internal + 76
2   libsystem_kernel.dylib        	       0x1e137f2b8 mach_msg_overwrite + 428
3   libsystem_kernel.dylib        	       0x1e137f100 mach_msg + 24
4   CoreFoundation                	       0x19016e900 __CFRunLoopServiceMachPort + 160
5   CoreFoundation                	       0x19016d1f0 __CFRunLoopRun + 1208
6   CoreFoundation                	       0x19016ec3c CFRunLoopRunSpecific + 572
7   Foundation                    	       0x18ede679c -[NSRunLoop(NSRunLoop) runMode:beforeDate:] + 212
8   Foundation                    	       0x18edec020 -[NSRunLoop(NSRunLoop) runUntilDate:] + 64
9   UIKitCore                     	       0x192b6b56c -[UIEventFetcher threadMain] + 424
10  Foundation                    	       0x18ee4c804 __NSThread__start__ + 732
11  libsystem_pthread.dylib       	       0x21a7ab344 _pthread_start + 136
12  libsystem_pthread.dylib       	       0x21a7a8ab8 thread_start + 8

Thread 8 name:  com.apple.NSURLConnectionLoader
Thread 8:
0   libsystem_kernel.dylib        	       0x1e137bce4 mach_msg2_trap + 8
1   libsystem_kernel.dylib        	       0x1e137f39c mach_msg2_internal + 76
2   libsystem_kernel.dylib        	       0x1e137f2b8 mach_msg_overwrite + 428
3   libsystem_kernel.dylib        	       0x1e137f100 mach_msg + 24
4   CoreFoundation                	       0x19016e900 __CFRunLoopServiceMachPort + 160
5   CoreFoundation                	       0x19016d1f0 __CFRunLoopRun + 1208
6   CoreFoundation                	       0x19016ec3c CFRunLoopRunSpecific + 572
7   CFNetwork                     	       0x19178e30c +[__CFN_CoreSchedulingSetRunnable _run:] + 416
8   Foundation                    	       0x18ee4c804 __NSThread__start__ + 732
9   libsystem_pthread.dylib       	       0x21a7ab344 _pthread_start + 136
10  libsystem_pthread.dylib       	       0x21a7a8ab8 thread_start + 8

Thread 9:
0   libsystem_kernel.dylib        	       0x1e137bc60 semaphore_wait_trap + 8
1   libdispatch.dylib             	       0x1980ea8e0 _dispatch_sema4_wait + 28
2   libdispatch.dylib             	       0x1980eae90 _dispatch_semaphore_wait_slow + 132
3   UIKitCore                     	       0x192ffc050 0x192a4c000 + 5963856
4   UIKitCore                     	       0x192a6c7d0 0x192a4c000 + 133072
5   Foundation                    	       0x18ee4c804 __NSThread__start__ + 732
6   libsystem_pthread.dylib       	       0x21a7ab344 _pthread_start + 136
7   libsystem_pthread.dylib       	       0x21a7a8ab8 thread_start + 8

Thread 10 name:  AudioSession - RootQueue
Thread 10:
0   libsystem_kernel.dylib        	       0x1e137bc78 semaphore_timedwait_trap + 8
1   libdispatch.dylib             	       0x19811d198 _dispatch_sema4_timedwait + 64
2   libdispatch.dylib             	       0x1980eae58 _dispatch_semaphore_wait_slow + 76
3   libdispatch.dylib             	       0x1980faba8 _dispatch_worker_thread + 324
4   libsystem_pthread.dylib       	       0x21a7ab344 _pthread_start + 136
5   libsystem_pthread.dylib       	       0x21a7a8ab8 thread_start + 8


Thread 4 crashed with ARM Thread State (64-bit):
    x0: 0x0000000000000001   x1: 0x000000007fffffff   x2: 0x000000010618d360   x3: 0x0000000104cbf67c
    x4: 0x0000000000000012   x5: 0x00000000000000fc   x6: 0x000000018eba362c   x7: 0x0000000000000000
    x8: 0x0000000000000000   x9: 0x00000000ffffffff  x10: 0x000000010618d2e8  x11: 0x000000010618d358
   x12: 0x0017b0bd00419120  x13: 0x0017a0bc80418884  x14: 0x0000000000019000  x15: 0x0000000000000028
   x16: 0x000000010618d2e8  x17: 0x2e3f00010618d358  x18: 0x0000000000000000  x19: 0x0000000000000000
   x20: 0x000000016b5d6930  x21: 0x0000000000000000  x22: 0x000000016b5d63a0  x23: 0x000000010618d360
   x24: 0x000000016b5d6480  x25: 0x000000012b54d540  x26: 0x000000016b5d6930  x27: 0x000000012b6398e8
   x28: 0x0000000107585060   fp: 0x000000016b5d63e0   lr: 0x0000000104bb4d48
    sp: 0x000000016b5d63a0   pc: 0x0000000104bb4d80 cpsr: 0x60001000
   far: 0x0000000000000000  esr: 0xf2000001 (Breakpoint) brk 1

Binary Images:
       0x104a54000 -        0x10607bfff ContextApp arm64  <dfbf584279ad3c0b900347141f07a88a> /var/containers/Bundle/Application/F07A927F-CEA6-4D66-ACCA-7DDED1CB80D5/ContextApp.app/ContextApp
       0x10723c000 -        0x107247fff libobjc-trampolines.dylib arm64e  <9136d8ba22ff3f129caddfc4c6dc51de> /private/preboot/Cryptexes/OS/usr/lib/libobjc-trampolines.dylib
       0x18e815000 -        0x18ed7e19f libswiftCore.dylib arm64e  <b215a4918bca3d2d81cd39e3c145ea07> /usr/lib/swift/libswiftCore.dylib
       0x2506e4000 -        0x251264adf SwiftUICore arm64e  <d4a1e5b0b937369095667ef1af91cab8> /System/Library/Frameworks/SwiftUICore.framework/SwiftUICore
       0x19498e000 -        0x195c1133f SwiftUI arm64e  <165d3305401e37c28387c1bfb54cffde> /System/Library/Frameworks/SwiftUI.framework/SwiftUI
       0x1bd6f2000 -        0x1bd73509f AttributeGraph arm64e  <3f57745ef22d35b6aa63db7041ffd20d> /System/Library/PrivateFrameworks/AttributeGraph.framework/AttributeGraph
       0x19015d000 -        0x1906d9fff CoreFoundation arm64e  <7821f73c378b3a10be90ef526b7dba93> /System/Library/Frameworks/CoreFoundation.framework/CoreFoundation
       0x1dd34c000 -        0x1dd354c7f GraphicsServices arm64e  <5ba62c226d3731999dfd0e0f7abebfa9> /System/Library/PrivateFrameworks/GraphicsServices.framework/GraphicsServices
       0x192a4c000 -        0x19498db5f UIKitCore arm64e  <96636f64106f30c8a78082dcebb0f443> /System/Library/PrivateFrameworks/UIKitCore.framework/UIKitCore
       0x1b7005000 -        0x1b709f857 dyld arm64e  <86d5253d4fd136f3b4ab25982c90cbf4> /usr/lib/dyld
               0x0 - 0xffffffffffffffff ??? unknown-arch  <00000000000000000000000000000000> ???
       0x21a7a8000 -        0x21a7b43f3 libsystem_pthread.dylib arm64e  <b37430d8e3af33e481e1faed9ee26e8a> /usr/lib/system/libsystem_pthread.dylib
       0x19bcdc000 -        0x19bd5ba3f libswift_Concurrency.dylib arm64e  <dcb9e73a92ba3782bc6d3e1906622689> /usr/lib/swift/libswift_Concurrency.dylib
       0x1e137b000 -        0x1e13b4ebf libsystem_kernel.dylib arm64e  <9e195be11733345ea9bf50d0d7059647> /usr/lib/system/libsystem_kernel.dylib
       0x1980e7000 -        0x19812cb1f libdispatch.dylib arm64e  <395da84f715d334e8d41a16cd93fc83c> /usr/lib/system/libdispatch.dylib
       0x21a7f3000 -        0x21a83adbf libxpc.dylib arm64e  <a46c2755958633b89ea9377f71175516> /usr/lib/system/libxpc.dylib
       0x18edd7000 -        0x18fa4addf Foundation arm64e  <34de055d8683380a9198c3347211d13d> /System/Library/Frameworks/Foundation.framework/Foundation
       0x1af89b000 -        0x1af8fa4bf AudioSession arm64e  <59e071b5055d3de0b60d47b4dce20666> /System/Library/PrivateFrameworks/AudioSession.framework/AudioSession
       0x1916ee000 -        0x191ab3b9f CFNetwork arm64e  <a35a109c49d23986965d4ed7e0b6681e> /System/Library/Frameworks/CFNetwork.framework/CFNetwork
       0x1a24aa000 -        0x1a26fcc3f MediaExperience arm64e  <15f78a5afa943f0cbb4a0e3e26e38ab3> /System/Library/PrivateFrameworks/MediaExperience.framework/MediaExperience

EOF
"""
    
    private static let emptyContent = ""
    
    private static let noThreadsContent = """
Some random content
Binary Images:
       0x104a54000 -        0x10607bfff ContextApp arm64
EOF
"""
    
    private static let singleThreadContent = """
Thread 0 name:   Dispatch queue: com.apple.main-thread
Thread 0:
0   libswiftCore.dylib                     0x18ec05a0c swift::RefCounts + 132
1   libswiftCore.dylib                     0x18ebaec18 swift_weakInit + 32
"""
    
    // MARK: - Basic Parsing Tests
    
    @Test("Parse empty content")
    func parseEmptyContent() {
        let result = parseThreadInfo(content: Self.emptyContent)
        #expect(result.isEmpty)
    }
    
    @Test("Parse content with no threads")
    func parseContentWithNoThreads() {
        let result = parseThreadInfo(content: Self.noThreadsContent)
        #expect(result.isEmpty)
    }
    
    @Test("Parse single thread")
    func parseSingleThread() {
        let result = parseThreadInfo(content: Self.singleThreadContent)
        
        #expect(result.count == 1)
        
        let thread = result[0]
        #expect(thread.number == 0)
        #expect(thread.isMainThread == true)
        #expect(thread.isCrashed == false)
        #expect(thread.frames.count == 2)
        #expect(thread.frames[0].processName == "libswiftCore.dylib")
        #expect(thread.frames[1].processName == "libswiftCore.dylib")
    }
    
    @Test("Parse multiple threads with crash")
    func parseMultipleThreadsWithCrash() {
        let result = parseThreadInfo(content: Self.sampleCrashLog)
        
        #expect(result.count == 11) // Threads 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10
        
        // Check main thread (Thread 0)
        let mainThread = result.first { $0.number == 0 }
        #expect(mainThread != nil)
        #expect(mainThread?.isMainThread == true)
        #expect(mainThread?.isCrashed == false)
        #expect(mainThread?.frames.count == 35) // Full stack trace from SwiftUI app
        #expect(mainThread?.frames[0].processName == "libswiftCore.dylib")
        #expect(mainThread?.frames[33].processName == "ContextApp")
        
        // Check crashed thread (Thread 4)
        let crashedThread = result.first { $0.number == 4 }
        #expect(crashedThread != nil)
        #expect(crashedThread?.isMainThread == false)
        #expect(crashedThread?.isCrashed == true)
        #expect(crashedThread?.frames.count == 16) // Full crash stack
        #expect(crashedThread?.frames[0].processName == "ContextApp")
        #expect(crashedThread?.frames[0].symbol.contains("BackgroundTaskManagerProtocol.swift:76") == true)
        
        // Check regular thread (Thread 1)
        let regularThread = result.first { $0.number == 1 }
        #expect(regularThread != nil)
        #expect(regularThread?.isMainThread == false)
        #expect(regularThread?.isCrashed == false)
        #expect(regularThread?.frames.count == 1)
        #expect(regularThread?.frames[0].symbol.contains("start_wqthread") == true)
        
        // Check Thread 5 with detailed stack
        let thread5 = result.first { $0.number == 5 }
        #expect(thread5 != nil)
        #expect(thread5?.isMainThread == false)
        #expect(thread5?.isCrashed == false)
        #expect(thread5?.frames.count == 25) // Long stack trace
        #expect(thread5?.frames[0].symbol.contains("mach_msg2_trap") == true)
        
        // Check named thread (Thread 7)
        let namedThread = result.first { $0.number == 7 }
        #expect(namedThread != nil)
        #expect(namedThread?.isMainThread == false)
        #expect(namedThread?.isCrashed == false)
        #expect(namedThread?.frames.count == 13) // UI event fetch thread
        
        // Check Thread 8 (NSURLConnectionLoader)
        let thread8 = result.first { $0.number == 8 }
        #expect(thread8 != nil)
        #expect(thread8?.frames.count == 11)
        #expect(thread8?.frames[7].processName == "CFNetwork")
        
        // Check Thread 10 (AudioSession)
        let thread10 = result.first { $0.number == 10 }
        #expect(thread10 != nil)
        #expect(thread10?.frames.count == 6)
        #expect(thread10?.frames[0].symbol.contains("semaphore_timedwait_trap") == true)
    }
    
    // MARK: - Thread Header Parsing Tests
    
    @Test("Parse thread with name")
    func parseThreadWithName() {
        let content = """
Thread 7 name:  com.apple.uikit.eventfetch-thread
Thread 7:
0   libsystem_kernel.dylib                 0x1e137bce4 mach_msg2_trap + 8
"""
        
        let result = parseThreadInfo(content: content)
        #expect(result.count == 1)
        
        let thread = result[0]
        #expect(thread.number == 7)
        #expect(thread.isMainThread == false)
        #expect(thread.isCrashed == false)
        #expect(thread.frames.count == 1)
    }
    
    @Test("Parse crashed thread")
    func parseCrashedThread() {
        let content = """
Thread 4 Crashed:
0   ContextApp                             0x104bb4d80 closure #1 in closure #1 + 1445248
1   ContextApp                             0x104bb6124 partial apply + 1450276
"""
        
        let result = parseThreadInfo(content: content)
        #expect(result.count == 1)
        
        let thread = result[0]
        #expect(thread.number == 4)
        #expect(thread.isMainThread == false)
        #expect(thread.isCrashed == true)
        #expect(thread.frames.count == 2)
    }
    
    @Test("Parse main thread variations")
    func parseMainThreadVariations() {
        let content1 = """
Thread 0 name:   Dispatch queue: com.apple.main-thread
Thread 0:
0   libswiftCore.dylib                     0x18ec05a0c test + 132
"""
        
        let content2 = """
Thread 0:
0   libswiftCore.dylib                     0x18ec05a0c test + 132
"""
        
        // Test with main-thread name
        let result1 = parseThreadInfo(content: content1)
        #expect(result1.count == 1)
        #expect(result1[0].isMainThread == true)
        
        // Test Thread 0 without explicit main-thread name
        let result2 = parseThreadInfo(content: content2)
        #expect(result2.count == 1)
        #expect(result2[0].isMainThread == true)
    }
    
    // MARK: - Stack Trace Parsing Tests
    
    @Test("Parse complex stack traces")
    func parseComplexStackTraces() {
        let content = """
Thread 0:
0   libswiftCore.dylib                     0x18ec05a0c swift::RefCounts<swift::RefCountBitsT<(swift::RefCountInlinedness)1>>::formWeakReference() + 132
1   SwiftUI                                0x194a2be60 closure #1 in PlatformViewChild.updateValue() + 1616
2   ContextApp                             0x104bb4d80 closure #1 in closure #1 in BackgroundTaskManager.add(id:operation:mapError:) (in ContextApp) (BackgroundTaskManagerProtocol.swift:76) + 1445248
"""
        
        let result = parseThreadInfo(content: content)
        #expect(result.count == 1)
        
        let thread = result[0]
        #expect(thread.frames.count == 3)
        #expect(thread.frames[0].processName == "libswiftCore.dylib")
        #expect(thread.frames[0].symbol.contains("swift::RefCounts"))
        #expect(thread.frames[1].processName == "SwiftUI")
        #expect(thread.frames[1].symbol.contains("PlatformViewChild"))
        #expect(thread.frames[2].processName == "ContextApp")
        #expect(thread.frames[2].symbol.contains("BackgroundTaskManagerProtocol.swift:76"))
    }
    
    @Test("Parse stack traces with special characters")
    func parseStackTracesWithSpecialCharacters() {
        let content = """
Thread 0:
0   Foundation                             0x18ee329b0 __NSXPCCONNECTION_IS_WAITING_FOR_A_SYNCHRONOUS_REPLY__ + 16
1   CoreFoundation                         0x19018b82c ___forwarding___ + 996
2   UIKitCore                              0x192ffc050 0x192a4c000 + 5963856
"""
        
        let result = parseThreadInfo(content: content)
        #expect(result.count == 1)
        
        let thread = result[0]
        #expect(thread.frames.count == 3)
        #expect(thread.frames[0].symbol.contains("__NSXPCCONNECTION_IS_WAITING_FOR_A_SYNCHRONOUS_REPLY__"))
        #expect(thread.frames[1].symbol.contains("___forwarding___"))
        #expect(thread.frames[2].symbol.contains("0x192a4c000 + 5963856"))
    }
    
    // MARK: - Edge Cases Tests
    
    @Test("Parse with thread state interruption")
    func parseWithThreadStateInterruption() {
        let content = """
Thread 4 Crashed:
0   ContextApp                             0x104bb4d80 test + 1445248
1   ContextApp                             0x104bb6124 test2 + 1450276

Thread 4 crashed with ARM Thread State (64-bit):
    x0: 0x0000000000000001   x1: 0x000000007fffffff

Thread 5:
0   libsystem_kernel.dylib                 0x1e137bce4 mach_msg2_trap + 8
"""
        
        let result = parseThreadInfo(content: content)
        #expect(result.count == 2) // Thread 4 and Thread 5
        
        let crashedThread = result.first { $0.number == 4 }
        #expect(crashedThread != nil)
        #expect(crashedThread?.isCrashed == true)
        #expect(crashedThread?.frames.count == 2)
        
        let normalThread = result.first { $0.number == 5 }
        #expect(normalThread != nil)
        #expect(normalThread?.isCrashed == false)
        #expect(normalThread?.frames.count == 1)
    }
    
    @Test("Parse malformed thread headers")
    func parseMalformedThreadHeaders() {
        let content = """
Thread:
0   libswiftCore.dylib                     0x18ec05a0c test + 132

Not a thread header
1   libswiftCore.dylib                     0x18ec05a0c test + 132

Thread 1:
0   libswiftCore.dylib                     0x18ec05a0c real_thread + 132
"""
        
        let result = parseThreadInfo(content: content)
        #expect(result.count == 1) // Only Thread 1 should be parsed
        
        let thread = result[0]
        #expect(thread.number == 1)
        #expect(thread.frames.count == 1)
        #expect(thread.frames[0].symbol.contains("real_thread"))
    }
    
    @Test("Parse threads with no stack traces")
    func parseThreadsWithNoStackTraces() {
        let content = """
Thread 1:

Thread 2:

Thread 3:
0   libsystem_pthread.dylib                0x21a7a8aa4 start_wqthread + 0
"""
        
        let result = parseThreadInfo(content: content)
        #expect(result.count == 3)
        
        // Threads 1 and 2 should have empty stacks
        let thread1 = result.first { $0.number == 1 }
        #expect(thread1?.frames.isEmpty == true)
        
        let thread2 = result.first { $0.number == 2 }
        #expect(thread2?.frames.isEmpty == true)
        
        // Thread 3 should have one stack entry
        let thread3 = result.first { $0.number == 3 }
        #expect(thread3?.frames.count == 1)
    }
    
    // MARK: - CrashLogThread Model Tests
    
    @Test("CrashLogThread sendable conformance")
    func crashLogThreadSendableConformance() {
        let thread = CrashLogThread(
            number: 0,
            isMainThread: true,
            isCrashed: false,
            frames: [CrashLogThread.Frame(processName: "TestApp", symbol: "test symbol")]
        )
        
        // This should compile without issues due to Sendable conformance
        Task {
            let _ = thread
        }
        
        #expect(thread.number == 0)
        #expect(thread.isMainThread == true)
        #expect(thread.isCrashed == false)
        #expect(thread.frames.count == 1)
    }
    
    @Test("CrashLogThread hashable conformance")
    func crashLogThreadHashableConformance() {
        let thread1 = CrashLogThread(
            number: 0,
            isMainThread: true,
            isCrashed: false,
            frames: [CrashLogThread.Frame(processName: "TestApp", symbol: "test")]
        )
        
        let thread2 = CrashLogThread(
            number: 0,
            isMainThread: true,
            isCrashed: false,
            frames: [CrashLogThread.Frame(processName: "TestApp", symbol: "test")]
        )
        
        let thread3 = CrashLogThread(
            number: 1,
            isMainThread: false,
            isCrashed: false,
            frames: [CrashLogThread.Frame(processName: "TestApp", symbol: "test")]
        )
        
        #expect(thread1 == thread2)
        #expect(thread1 != thread3)
        #expect(thread1.hashValue == thread2.hashValue)
    }
    
    @Test("CrashLogThread codable conformance")
    func crashLogThreadCodableConformance() throws {
        let originalThread = CrashLogThread(
            number: 4,
            isMainThread: false,
            isCrashed: true,
            frames: [
                CrashLogThread.Frame(processName: "ContextApp", symbol: "0x104bb4d80 test + 1445248"),
                CrashLogThread.Frame(processName: "ContextApp", symbol: "0x104bb6124 test2 + 1450276")
            ]
        )
        
        // Encode
        let encoder = JSONEncoder()
        let data = try encoder.encode(originalThread)
        
        // Decode
        let decoder = JSONDecoder()
        let decodedThread = try decoder.decode(CrashLogThread.self, from: data)
        
        #expect(decodedThread == originalThread)
        #expect(decodedThread.number == 4)
        #expect(decodedThread.isMainThread == false)
        #expect(decodedThread.isCrashed == true)
        #expect(decodedThread.frames.count == 2)
    }
    
    // MARK: - Performance Tests
    
    @Test("Parse large crash log performance")
    func parseLargeCrashLogPerformance() {
        // Create a large crash log with many threads and stack traces
        var largeCrashLog = ""
        for threadNum in 0..<50 {
            largeCrashLog += "Thread \(threadNum):\n"
            for stackNum in 0..<20 {
                largeCrashLog += "\(stackNum)   SomeFramework  0x1234567890abcdef someFunction + \(stackNum * 100)\n"
            }
            largeCrashLog += "\n"
        }
        
        let startTime = CFAbsoluteTimeGetCurrent()
        let result = parseThreadInfo(content: largeCrashLog)
        let endTime = CFAbsoluteTimeGetCurrent()
        
        let duration = endTime - startTime
        
        #expect(result.count == 50)
        #expect(duration < 1.0) // Should parse within 1 second
        
        // Verify first and last threads
        let firstThread = result.first { $0.number == 0 }
        #expect(firstThread?.frames.count == 20)
        
        let lastThread = result.first { $0.number == 49 }
        #expect(lastThread?.frames.count == 20)
    }
}
