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

@available(iOS 15.0, *)
class AppLockService {
    static let shared = AppLockService()
    
    #if canImport(ManagedSettings)
    let store = ManagedSettingsStore()
    #endif
    
    // Request Authorization for Family Controls (Screen Time API)
    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        #if canImport(FamilyControls)
        Task {
            do {
                try await AuthorizationCenter.shared.requestAuthorization(for: .individual)
                DispatchQueue.main.async {
                    print("Family Controls Authorization Granted")
                    completion(true)
                }
            } catch {
                print("Failed to authorize Family Controls: \(error)")
                DispatchQueue.main.async { completion(false) }
            }
        }
        #else
        completion(false)
        #endif
    }

    // Set shielded applications based on token strings received from Flutter
    func setShieldedApps(isLimitReached: Bool) {
        #if canImport(ManagedSettings)
        if isLimitReached {
            print("Limit reached! Applying iOS Shield Restrictions (Mocked tokens)...")
        } else {
            // Remove shields
            store.shield.applications = nil
            store.shield.applicationCategories = nil
            print("Shields lifted.")
        }
        #endif
    }
}
