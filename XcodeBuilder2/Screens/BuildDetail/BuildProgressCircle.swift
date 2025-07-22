//
//  BuildProgressCircle.swift
//  XcodeBuilder2
//
//  Created by Kai Shao on 2025/7/15.
//

import SwiftUI
import Core

struct BuildProgressCircle: View {
    let build: BuildModelValue
    let size: CGFloat
    
    var body: some View {
        ZStack {
            // Background circle
            Circle()
                .stroke(build.status.color.opacity(0.2), lineWidth: 3)
                .frame(width: size, height: size)
            
            // Progress circle
            Circle()
                .trim(from: 0, to: progressValue)
                .stroke(
                    build.status.color,
                    style: StrokeStyle(lineWidth: 3, lineCap: .round)
                )
                .frame(width: size, height: size)
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.3), value: progressValue)
            
            // Center content
            VStack(spacing: 2) {
                if build.status == .running {
                    Text("\(Int(build.progress * 100))%")
                        .font(.caption.bold())
                        .foregroundStyle(build.status.color)
                } else {
                    Image(systemName: statusIcon)
                        .font(.caption.bold())
                        .foregroundStyle(build.status.color)
                }
            }
        }
    }
    
    private var progressValue: Double {
        switch build.status {
        case .queued: return 0
        case .running: return build.progress
        case .completed: return 1
        case .failed, .cancelled: return 0
        }
    }
    
    private var statusIcon: String {
        switch build.status {
        case .queued: return "clock"
        case .running: return "gear"
        case .completed: return "checkmark"
        case .failed: return "xmark"
        case .cancelled: return "stop"
        }
    }
}

#Preview {
    BuildProgressCircle(build: BuildModelValue(status: .running, progress: 0.75), size: 100)
        .padding()
    
    BuildProgressCircle(build: BuildModelValue(status: .completed), size: 100)
    
    BuildProgressCircle(build: BuildModelValue(status: .failed), size: 100)
        
    BuildProgressCircle(build: BuildModelValue(status: .queued), size: 100)
}
