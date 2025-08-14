//
//  NetworkReachabilityManager.swift
//  GrowthSDK
//
//  Created by arvin on 2025/1/16.
//

import Foundation
import Network

// MARK: -
internal class NetworkReachabilityManager {
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkReachabilityManager")
    private var statusHandler: ((Bool) -> Void)?
    
    internal func startListening(onUpdatePerforming listener: @escaping (Bool) -> Void) {
        statusHandler = listener
        monitor.pathUpdateHandler = { [weak self] path in
            let isReachable = path.status == .satisfied
            DispatchQueue.main.async {
                self?.statusHandler?(isReachable)
            }
        }
        monitor.start(queue: queue)
    }
    
    internal func stopListening() {
        monitor.cancel()
        statusHandler = nil
    }
    
}
