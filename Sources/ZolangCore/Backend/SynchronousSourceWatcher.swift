//
//  SynchronousSourceWatcher.swift
//  ZolangCore
//
//  Created by Thorvaldur Runarsson on 02/10/2018.
//

import Foundation

protocol FileWatchingDelegate {
    func didChangeFiles()
}

class SynchronousSourceWatcher {
    
    var lastModifiedCache: [String: Double] = [:]
    var isWatching = false
    var workItem: DispatchWorkItem?
    var timer: DispatchSourceTimer?
    
    let config: Config
    
    init(config: Config) {
        self.config = config
    }

    func didSourceChange() -> Bool {
        var sourceChanged = false
        
        for file in FileManager.default.listSourceFiles(config) {
            let attributes = (try? FileManager.default
                .attributesOfItem(atPath: file.path)) ?? [:]
            
            guard let lastModified = attributes[FileAttributeKey.modificationDate] as? Date else {
                continue
            }
            
            if lastModified.timeIntervalSince1970 > (lastModifiedCache[file.path] ?? 0) {
                lastModifiedCache[file.path] = lastModified.timeIntervalSince1970
                sourceChanged = true
            }
        }
        
        return sourceChanged
    }
    
    func startTimer() {
        
    }
    
    func watchForChangesSync(watcher: @escaping () -> Void) {
        guard workItem?.isCancelled ?? true == true else {
            assertionFailure()
            return
        }
        
        if workItem == nil {
            workItem = DispatchWorkItem(block: {})
        }

        timer = DispatchSource.makeTimerSource(queue: DispatchQueue(label: "com.Zolang.watcher"))
        timer?.schedule(deadline: .now(), repeating: .milliseconds(100))
        timer?.setEventHandler { [unowned self] in
            if self.didSourceChange() {
                watcher()
            }
        }
        timer!.resume()
        
        workItem?.wait()
    }
    
    func stop() {
        timer?.cancel()
        timer = nil
        workItem?.cancel()
    }
    
    deinit {
        stop()
    }
}
