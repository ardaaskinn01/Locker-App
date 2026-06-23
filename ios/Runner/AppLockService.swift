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
    
    #if canImport(FamilyControls)
    var selectionToShield = FamilyActivitySelection() {
        didSet {
            saveSelection()
        }
    }
    #endif
    
    private let selectionKey = "LockAppSelection"
    
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

    // Set shielded applications based on selection tokens
    func setShieldedApps(isLimitReached: Bool) {
        #if canImport(ManagedSettings) && canImport(FamilyControls)
        if #available(iOS 16.0, *) {
            if isLimitReached {
                store.shield.applications = selectionToShield.applicationTokens
                store.shield.applicationCategories = selectionToShield.categoryTokens
                print("iOS Shield Restrictions applied to \(selectionToShield.applicationTokens.count) apps.")
            } else {
                // Remove shields
                store.shield.applications = nil
                store.shield.applicationCategories = nil
                print("Shields lifted.")
            }
        }
        #endif
    }
    
    func saveSelection() {
        #if canImport(FamilyControls)
        do {
            let data = try JSONEncoder().encode(selectionToShield)
            UserDefaults.standard.set(data, forKey: selectionKey)
            print("Selection saved successfully.")
        } catch {
            print("Failed to save selection: \(error)")
        }
        #endif
    }
    
    func loadSelection() {
        #if canImport(FamilyControls)
        guard let data = UserDefaults.standard.data(forKey: selectionKey) else { return }
        do {
            selectionToShield = try JSONDecoder().decode(FamilyActivitySelection.self, from: data)
            print("Selection loaded successfully: \(selectionToShield.applicationTokens.count) apps.")
        } catch {
            print("Failed to load selection: \(error)")
        }
        #endif
    }
}
