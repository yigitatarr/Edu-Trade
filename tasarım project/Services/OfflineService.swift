//
//  OfflineService.swift
//  EduTrade
//
//  Created by AI on 28.10.2025.
//

import Foundation
import Network

class OfflineService: ObservableObject {
    static let shared = OfflineService()
    
    @Published var isOnline = true
    
    private let monitor = NWPathMonitor()
    private let queue = DispatchQueue(label: "NetworkMonitor")
    
    private init() {
        startMonitoring()
    }
    
    func startMonitoring() {
        monitor.pathUpdateHandler = { [weak self] path in
            DispatchQueue.main.async {
                self?.isOnline = path.status == .satisfied
            }
        }
        monitor.start(queue: queue)
    }
    
    func stopMonitoring() {
        monitor.cancel()
    }
}



