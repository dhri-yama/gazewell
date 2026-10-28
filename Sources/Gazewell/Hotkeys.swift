import Carbon.HIToolbox

/// Global shortcuts via Carbon's RegisterEventHotKey (works without Accessibility permission).
/// shortcut: bindings are fixed (ctrl+opt+B/S/P), no recorder UI; add one if the defaults clash.
final class Hotkeys {
    private var actions: [UInt32: () -> Void] = [:]
    private var refs: [EventHotKeyRef?] = []

    init() {
        var spec = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        InstallEventHandler(GetApplicationEventTarget(), { _, event, userData in
            var id = EventHotKeyID()
            GetEventParameter(event, EventParamName(kEventParamDirectObject), EventParamType(typeEventHotKeyID), nil,
                              MemoryLayout<EventHotKeyID>.size, nil, &id)
            let me = Unmanaged<Hotkeys>.fromOpaque(userData!).takeUnretainedValue()
            me.actions[id.id]?()
            return noErr
        }, 1, &spec, Unmanaged.passUnretained(self).toOpaque(), nil)
    }

    func register(key: Int, action: @escaping () -> Void) {
        let id = UInt32(actions.count + 1)
        actions[id] = action
        var ref: EventHotKeyRef?
        RegisterEventHotKey(UInt32(key), UInt32(controlKey | optionKey), EventHotKeyID(signature: 0x4C4B4157, id: id),
                            GetApplicationEventTarget(), 0, &ref)
        refs.append(ref)
    }
}
