//
//  File.swift
//  xcode-builder-2
//
//  Created by Kai Shao on 2025/7/14.
//


import Foundation

public func ensuredURL(_ url: URL) -> URL {
    var url = url
    let lastComponent = url.lastPathComponent
    let isDeletedLastComponent = !url.pathExtension.isEmpty

    if !url.pathExtension.isEmpty {
        url.deleteLastPathComponent()
    }

    if !FileManager.default.fileExists(atPath: url.path) {
        try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    if isDeletedLastComponent {
        url.appendPathComponent(lastComponent)
    }

    return url
}

public func ensuredPath(_ path: String) -> String {
    let url = URL(filePath: path)
    return ensuredURL(url).path()
}
