import Foundation

#if canImport(FamilyControls)
import FamilyControls
#endif

#if canImport(DeviceActivity)
import DeviceActivity
#endif

#if canImport(ManagedSettings)
import ManagedSettings
#endif

#if canImport(DeviceActivity)
@available(iOS 16.0, *)
extension DeviceActivityName {
    static let dailyLimit = DeviceActivityName("com.aasoft.lockapp.dailyLimit")
}
@available(iOS 16.0, *)
extension DeviceActivityEvent.Name {
    static let limitReached = DeviceActivityEvent.Name("com.aasoft.lockapp.limitReached")
}
#endif

@available(iOS 15.0, *)
class AppLockService {
    static let shared = AppLockService()
    
    #if canImport(ManagedSettings)
    let store = ManagedSettingsStore()
    #endif
    
    #if canImport(FamilyControls)
    var selectionToShield = FamilyActivitySelection() {
        didSet {
            saveSelection()
        }
    }
    #endif
    
    private let suiteName = "group.com.aasoft.lockapp"
    private let selectionKey = "LockAppSelection"
    
    var sharedDefaults: UserDefaults? {
        return UserDefaults(suiteName: suiteName)
    }
    
    init() {
        loadSelection()
    }
    
    // Request Authorization for Family Controls (Screen Time API)
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        #if canImport(FamilyControls)
        Task { @MainActor in
            if #available(iOS 16.0, *) {
                do {
                    try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                    print("Family Controls Authorization Granted")
                    completion(true)
                } catch {
                    print("Failed to authorize Family Controls: \(error)")
                    completion(false)
                }
            } else {
                // Fallback for iOS 15.0 (completion handler version)
                AuthorizationCenter.shared.requestAuthorization { result in
                    switch result {
                    case .success:
                        print("Family Controls Authorization Granted (iOS 15)")
                        completion(true)
                    case .failure(let error):
                        print("Failed to authorize Family Controls (iOS 15): \(error)")
                        completion(false)
                    }
                }
            }
        }
        #else
        completion(false)
        #endif
    }

    // Set shielded applications based on selection tokens and start/stop device activity monitoring
    func setShieldedApps(isLimitReached: Bool, totalAllowedMinutes: Int, todaysTotalUsageMinutes: Int) {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            // Save to shared defaults so the extension can read it
            sharedDefaults?.set(isLimitReached, forKey: "isLimitReached")
            sharedDefaults?.set(totalAllowedMinutes, forKey: "totalAllowedMinutes")
            sharedDefaults?.set(todaysTotalUsageMinutes, forKey: "todaysTotalUsageMinutes")
            
            if isLimitReached {
                applyShields()
                stopMonitoring()
            } else {
                liftShields()
                startMonitoring(totalAllowedMinutes: totalAllowedMinutes, todaysTotalUsageMinutes: todaysTotalUsageMinutes)
            }
        } else {
            // Fallback for iOS 15
            setShieldedAppsLegacy(isLimitReached: isLimitReached)
        }
        #endif
    }
    
    private func applyShields() {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            if !selectionToShield.applicationTokens.isEmpty {
                store.shield.applications = selectionToShield.applicationTokens
                print("iOS Shield Restrictions applied to \(selectionToShield.applicationTokens.count) apps.")
            } else {
                store.shield.applications = nil
            }

            if !selectionToShield.categoryTokens.isEmpty {
                store.shield.applicationCategories = .specific(selectionToShield.categoryTokens, except: Set<ApplicationToken>())
                print("iOS Shield Restrictions applied to \(selectionToShield.categoryTokens.count) categories.")
            } else {
                store.shield.applicationCategories = nil
            }
        }
        #endif
    }
    
    private func liftShields() {
        #if canImport(ManagedSettings)
        if #available(iOS 16.0, *) {
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            print("Shields lifted.")
        }
        #endif
    }
    
    func setShieldedAppsLegacy(isLimitReached: Bool) {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        if #available(iOS 15.0, *) {
            if isLimitReached {
                if !selectionToShield.applicationTokens.isEmpty {
                    store.shield.applications = selectionToShield.applicationTokens
                } else {
                    store.shield.applications = nil
                }

                if !selectionToShield.categoryTokens.isEmpty {
                    store.shield.applicationCategories = .specific(selectionToShield.categoryTokens, except: Set<ApplicationToken>())
                } else {
                    store.shield.applicationCategories = nil
                }
            } else {
                store.shield.applications = nil
                store.shield.applicationCategories = nil
            }
        }
        #endif
    }
    
    func startMonitoring(totalAllowedMinutes: Int, todaysTotalUsageMinutes: Int) {
        #if canImport(DeviceActivity) && canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            let center = DeviceActivityCenter()
            
            guard !selectionToShield.applicationTokens.isEmpty || !selectionToShield.categoryTokens.isEmpty else {
                center.stopMonitoring([.dailyLimit])
                return
            }
            
            // Calculate REMAINING minutes so DeviceActivity only counts from NOW onwards.
            // The Dart side already tracks cumulative usage; we pass remaining time as the
            // threshold so we don't accidentally fire early due to includesPastActivity.
            let remainingMinutes = max(1, totalAllowedMinutes - todaysTotalUsageMinutes)
            
            // Define a static daily schedule from 00:00 to 23:59
            let startComponents = DateComponents(hour: 0, minute: 0, second: 0)
            let endComponents = DateComponents(hour: 23, minute: 59, second: 59)
            
            let schedule = DeviceActivitySchedule(
                intervalStart: startComponents,
                intervalEnd: endComponents,
                repeats: true
            )
            
            // Do NOT use includesPastActivity:true — that causes the threshold to count
            // all usage since midnight including time before monitoring started, which
            // makes the shield fire before the user's actual limit is reached.
            let event = DeviceActivityEvent(
                applications: selectionToShield.applicationTokens,
                categories: selectionToShield.categoryTokens,
                webDomains: selectionToShield.webDomainTokens,
                threshold: DateComponents(minute: remainingMinutes)
            )
            
            do {
                try center.startMonitoring(.dailyLimit, during: schedule, events: [.limitReached: event])
                print("AppLockService: Started DeviceActivity monitoring. Remaining threshold: \(remainingMinutes) mins (total: \(totalAllowedMinutes), used: \(todaysTotalUsageMinutes))")
            } catch {
                print("AppLockService: Failed to start DeviceActivity monitoring: \(error)")
            }
        }
        #endif
    }
    
    func stopMonitoring() {
        #if canImport(DeviceActivity)
        if #available(iOS 16.0, *) {
            let center = DeviceActivityCenter()
            center.stopMonitoring([.dailyLimit])
            print("AppLockService: Stopped DeviceActivity monitoring.")
        }
        #endif
    }
    
    func saveSelection() {
        #if canImport(FamilyControls)
        do {
            let data = try JSONEncoder().encode(selectionToShield)
            sharedDefaults?.set(data, forKey: selectionKey)
            print("Selection saved successfully to App Group.")
            
            // Re-trigger monitoring update since apps selection changed
            if let isLimitReached = sharedDefaults?.object(forKey: "isLimitReached") as? Bool,
               let totalAllowedMinutes = sharedDefaults?.object(forKey: "totalAllowedMinutes") as? Int,
               let todaysTotalUsageMinutes = sharedDefaults?.object(forKey: "todaysTotalUsageMinutes") as? Int {
                setShieldedApps(
                    isLimitReached: isLimitReached,
                    totalAllowedMinutes: totalAllowedMinutes,
                    todaysTotalUsageMinutes: todaysTotalUsageMinutes
                )
            } else if let totalAllowedMinutes = sharedDefaults?.object(forKey: "totalAllowedMinutes") as? Int,
                      let todaysTotalUsageMinutes = sharedDefaults?.object(forKey: "todaysTotalUsageMinutes") as? Int {
                // Selection changed but no explicit limit check yet — restart monitoring with updated remaining time
                if #available(iOS 16.0, *) {
                    liftShields()
                    startMonitoring(totalAllowedMinutes: totalAllowedMinutes, todaysTotalUsageMinutes: todaysTotalUsageMinutes)
                }
            }
        } catch {
            print("Failed to save selection: \(error)")
        }
        #endif
    }
    
    func loadSelection() {
        #if canImport(FamilyControls)
        guard let data = sharedDefaults?.data(forKey: selectionKey) else { return }
        do {
            selectionToShield = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            print("Selection loaded successfully from App Group: \(selectionToShield.applicationTokens.count) apps.")
        } catch {
            print("Failed to load selection: \(error)")
        }
        #endif
    }
}
