import Combine
import Foundation
import IOKit.pwr_mgt

/// Holds two power assertions simultaneously to prevent system sleep on both AC and battery power.
///
/// - `kIOPMAssertionTypePreventSystemSleep` — strongest assertion; prevents all non-critical
///   system sleep. Effective on AC power (AC-only per Apple docs).
/// - `kIOPMAssertionTypePreventUserIdleSystemSleep` — prevents idle-timer sleep. Works on
///   both AC and battery, providing a fallback when the system ignores the first assertion
///   on battery power.
///
/// Holding both mirrors Apple's recommendation for Apple Silicon Macs.
final class SleepPreventer: ObservableObject {
    @Published private(set) var isActive = false

    private var systemSleepAssertionID: IOPMAssertionID = 0
    private var idleSleepAssertionID: IOPMAssertionID = 0

    func toggle() {
        setActive(!isActive)
    }

    func setActive(_ active: Bool) {
        if active {
            enable()
        } else {
            disable()
        }
    }

    private func enable() {
        guard systemSleepAssertionID == 0 && idleSleepAssertionID == 0 else { return }

        let reason = "BurnMyMac keeps system awake" as CFString

        // 1) PreventSystemSleep — the strongest user-space assertion (effective on AC).
        let sysResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &systemSleepAssertionID
        )

        // 2) PreventUserIdleSystemSleep — idle-sleep prevention (works on battery too).
        let idleResult = IOPMAssertionCreateWithName(
            kIOPMAssertionTypePreventUserIdleSystemSleep as CFString,
            IOPMAssertionLevel(kIOPMAssertionLevelOn),
            reason,
            &idleSleepAssertionID
        )

        if sysResult == kIOReturnSuccess || idleResult == kIOReturnSuccess {
            // At least one assertion succeeded — we are active.
            isActive = true

            // Clean up any assertion that failed so disable() stays correct.
            if sysResult != kIOReturnSuccess {
                systemSleepAssertionID = 0
            }
            if idleResult != kIOReturnSuccess {
                idleSleepAssertionID = 0
            }
        } else {
            // Both failed — something is wrong with the system.
            systemSleepAssertionID = 0
            idleSleepAssertionID = 0
            isActive = false
        }
    }

    private func disable() {
        if systemSleepAssertionID != 0 {
            IOPMAssertionRelease(systemSleepAssertionID)
            systemSleepAssertionID = 0
        }
        if idleSleepAssertionID != 0 {
            IOPMAssertionRelease(idleSleepAssertionID)
            idleSleepAssertionID = 0
        }
        isActive = false
    }

    deinit {
        if systemSleepAssertionID != 0 {
            IOPMAssertionRelease(systemSleepAssertionID)
        }
        if idleSleepAssertionID != 0 {
            IOPMAssertionRelease(idleSleepAssertionID)
        }
    }
}
