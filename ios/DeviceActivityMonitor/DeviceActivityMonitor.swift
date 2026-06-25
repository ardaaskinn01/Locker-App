import DeviceActivity
import ManagedSettings
import Foundation
import FamilyControls

@available(iOS 16.0, *)
class DeviceActivityMonitorExtension: DeviceActivityMonitor {
    let store = ManagedSettingsStore()
    private let suiteName = "group.com.aasoft.lockapp"
    private let selectionKey = "LockAppSelection"
    
    override func intervalDidStart(for activity: DeviceActivityName) {
        super.intervalDidStart(for: activity)
        print("DeviceActivityMonitorExtension: intervalDidStart - New monitoring window started")
        
        // At the start of a new day, lift all shields and reset daily usage
        let sharedDefaults = UserDefaults(suiteName: suiteName)
        sharedDefaults?.set(0, forKey: "todaysTotalUsageMinutes")
        sharedDefaults?.set(false, forKey: "isLimitReached")
        
        store.shield.applications = nil
        store.shield.applicationCategories = nil
        print("DeviceActivityMonitorExtension: Shields lifted for a new day")
    }
    
    override func intervalDidEnd(for activity: DeviceActivityName) {
        super.intervalDidEnd(for: activity)
        print("DeviceActivityMonitorExtension: intervalDidEnd - Monitoring window ended")
        
        // Lift shields when monitoring ends
        store.shield.applications = nil
        store.shield.applicationCategories = nil
    }
    
    override func eventDidReachThreshold(_ event: DeviceActivityEvent.Name, activity: DeviceActivityName) {
        super.eventDidReachThreshold(event, activity: activity)
        print("DeviceActivityMonitorExtension: eventDidReachThreshold - Limit has been reached")
        
        let sharedDefaults = UserDefaults(suiteName: suiteName)
        sharedDefaults?.set(true, forKey: "isLimitReached")
        
        // Load selected application tokens from the shared App Group UserDefaults
        if let data = sharedDefaults?.data(forKey: selectionKey) {
            do {
                let selection = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
                
                // Shield applications
                if !selection.applicationTokens.isEmpty {
                    store.shield.applications = selection.applicationTokens
                    print("DeviceActivityMonitorExtension: Shield applied to \(selection.applicationTokens.count) applications")
                } else {
                    store.shield.applications = nil
                }
                
                // Shield categories
                if !selection.categoryTokens.isEmpty {
                    store.shield.applicationCategories = .specific(selection.categoryTokens)
                    print("DeviceActivityMonitorExtension: Shield applied to \(selection.categoryTokens.count) categories")
                } else {
                    store.shield.applicationCategories = nil
                }
            } catch {
                print("DeviceActivityMonitorExtension: Failed to decode FamilyActivitySelection: \(error)")
            }
        } else {
            print("DeviceActivityMonitorExtension: No saved activity selection found in shared UserDefaults")
        }
    }
}
