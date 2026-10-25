import Foundation
import IOKit
import IOKit.hid

@main
struct AuraCLI {
    static func printUsage() {
        print("""
rogauracore - Native macOS CLI for ASUS ROG Keyboards (GA401QM White Backlight Edition)
Target Hardware: ASUS ROG Zephyrus G14 GA401QM (White LED Backlight)

Usage:
    rogauracore COMMAND [ARGUMENTS...]

Commands:
    --status, -s                 Show detected ASUS Aura USB HID hardware telemetry
    --json                       Output device status and topology in JSON
    resync, -r                   Force hardware re-handshake & restore controller state
    initialize_keyboard, init    Initialize / wake keyboard controller
    brightness LEVEL             Set brightness (0 = Off, 1 = 33%, 2 = 66%, 3 = 100%)
    on                           Turn on backlight (White static, Brightness 3)
    off                          Turn off backlight completely
    breathing [SPD]              White breathing animation (speed: 1, 2, 3)
    strobing [SPD]               White strobing / flashing effect (speed: 1, 2, 3)
    presets                      List available backlight modes

Examples:
    rogauracore --status
    rogauracore brightness 2
    rogauracore breathing 2
    rogauracore on
    rogauracore off
""")
    }

    static func main() {
        let args = CommandLine.arguments

        if args.count < 2 || args.contains("-h") || args.contains("--help") {
            printUsage()
            exit(0)
        }

        let driver = AuraDriver.shared
        // Allow brief runloop run to enumerate devices reliably
        RunLoop.current.run(until: Date().addingTimeInterval(0.15))

        let cmd = args[1].lowercased()

        switch cmd {
        case "--status", "-s":
            if driver.isConnected, let info = driver.connectedDeviceInfo {
                print("✅ ASUS ROG Aura Keyboard Detected:")
                print("   Device Name: \(info.name)")
                print("   Vendor ID:   \(info.formattedVID) (ASUSTeK)")
                print("   Product ID:  \(info.formattedPID)")
                print("   Transport:   \(info.transport)")
                print("   Usage Page:  0x\(String(format: "%04X", info.usagePage)) (Usage: 0x\(String(format: "%04X", info.usage))")
                if let serial = info.serialNumber {
                    print("   Serial:      \(serial)")
                }
                print("   Topology:    White LED Backlit Keyboard (GA401QM)")
            } else {
                print("❌ No compatible ASUS ROG Aura USB HID keyboard detected.")
                exit(1)
            }
            exit(0)

        case "--json":
            if driver.isConnected, let info = driver.connectedDeviceInfo {
                let jsonDict: [String: Any] = [
                    "connected": true,
                    "name": info.name,
                    "vendor_id": info.formattedVID,
                    "product_id": info.formattedPID,
                    "transport": info.transport,
                    "serial": info.serialNumber ?? "",
                    "usage_page": "0x\(String(format: "%04X", info.usagePage))",
                    "usage": "0x\(String(format: "%04X", info.usage))"
                ]
                if let data = try? JSONSerialization.data(withJSONObject: jsonDict, options: .prettyPrinted),
                   let str = String(data: data, encoding: .utf8) {
                    print(str)
                }
            } else {
                print("{\"connected\": false}")
                exit(1)
            }
            exit(0)

        case "resync", "-r":
            let sema = DispatchSemaphore(value: 0)
            driver.initializeKeyboard { _ in
                driver.applyMode(.singleStatic(.white), brightness: 3) { _ in
                    sema.signal()
                }
            }
            _ = sema.wait(timeout: .now() + 1.0)
            print("✓ Forced hardware re-handshake and restored white backlight state.")

        case "initialize_keyboard", "init":
            let sema = DispatchSemaphore(value: 0)
            driver.initializeKeyboard { _ in sema.signal() }
            _ = sema.wait(timeout: .now() + 1.0)
            print("✓ Initialized keyboard controller.")

        case "brightness":
            guard args.count >= 3, let level = Int(args[2]), (0...3).contains(level) else {
                print("Error: brightness requires an integer from 0 to 3.")
                exit(1)
            }
            let sema = DispatchSemaphore(value: 0)
            driver.setBrightness(level) { _ in sema.signal() }
            _ = sema.wait(timeout: .now() + 1.0)
            print("✓ Set brightness level to \(level).")

        case "on":
            let sema = DispatchSemaphore(value: 0)
            driver.applyMode(.singleStatic(.white), brightness: 3) { _ in sema.signal() }
            _ = sema.wait(timeout: .now() + 1.0)
            print("✓ Turned backlight on (White, Brightness 3).")

        case "off":
            let sema = DispatchSemaphore(value: 0)
            driver.turnOff { _ in sema.signal() }
            _ = sema.wait(timeout: .now() + 1.0)
            print("✓ Turned backlight off.")

        case "breathing":
            var speed: AuraSpeed = .medium
            if args.count >= 3, let sp = Int(args[2]), let sEnum = AuraSpeed(rawValue: sp) {
                speed = sEnum
            }
            let sema = DispatchSemaphore(value: 0)
            driver.applyMode(.singleBreathing(.white, .white, speed), brightness: 3) { _ in sema.signal() }
            _ = sema.wait(timeout: .now() + 1.0)
            print("✓ Set white breathing effect (Speed: \(speed.displayName)).")

        case "strobing":
            var speed: AuraSpeed = .medium
            if args.count >= 3, let sp = Int(args[2]), let sEnum = AuraSpeed(rawValue: sp) {
                speed = sEnum
            }
            let sema = DispatchSemaphore(value: 0)
            driver.applyMode(.strobing(.white, speed), brightness: 3) { _ in sema.signal() }
            _ = sema.wait(timeout: .now() + 1.0)
            print("✓ Set white strobing effect (Speed: \(speed.displayName)).")

        case "presets":
            print("Available Backlight Modes for White Keyboard:")
            print("   on         : Full White Backlight")
            print("   off        : Turn Off Backlight")
            print("   breathing  : Pulsing White Breathing Effect")
            print("   strobing   : Flashing White Strobing Effect")

        default:
            print("Unknown command: \(cmd)")
            printUsage()
            exit(1)
        }

        exit(0)
    }
}
