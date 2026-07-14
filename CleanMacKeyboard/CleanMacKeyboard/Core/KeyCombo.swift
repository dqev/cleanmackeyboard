import Carbon
import AppKit

struct KeyCombo: Equatable {
    var key: Key
    var modifiers: NSEvent.ModifierFlags

    func matches(event: CGEvent) -> Bool {
        let flags = event.flags
        let keyCode = CGKeyCode(event.getIntegerValueField(.keyboardEventKeycode))

        let wantsCmd   = modifiers.contains(.command)
        let wantsShift = modifiers.contains(.shift)
        let wantsOpt   = modifiers.contains(.option)
        let wantsCtrl  = modifiers.contains(.control)

        // CGEventFlags maps to NSEvent.ModifierFlags
        let hasCmd   = flags.contains(.maskCommand)
        let hasShift = flags.contains(.maskShift)
        let hasOpt   = flags.contains(.maskAlternate)
        let hasCtrl  = flags.contains(.maskControl)

        return keyCode == key.keyCode
            && wantsCmd == hasCmd
            && wantsShift == hasShift
            && wantsOpt == hasOpt
            && wantsCtrl == hasCtrl
    }
}

enum Key: String, CaseIterable, Identifiable, Codable {
    case q, w, e, r, t, y, u, i, o, p
    case a, s, d, f, g, h, j, k, l
    case z, x, c, v, b, n, m
    case escape, space, `return`

    var id: String { rawValue }

    var keyCode: CGKeyCode {
        switch self {
        case .q: return 12
        case .w: return 13
        case .e: return 14
        case .r: return 15
        case .t: return 17
        case .y: return 16
        case .u: return 32
        case .i: return 34
        case .o: return 31
        case .p: return 35
        case .a: return 0
        case .s: return 1
        case .d: return 2
        case .f: return 3
        case .g: return 5
        case .h: return 4
        case .j: return 38
        case .k: return 40
        case .l: return 37
        case .z: return 6
        case .x: return 7
        case .c: return 8
        case .v: return 9
        case .b: return 11
        case .n: return 45
        case .m: return 46
        case .escape: return 53
        case .space: return 49
        case .return: return 36
        }
    }
}
