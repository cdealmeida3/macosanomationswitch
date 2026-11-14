import AnimationSwitchCore
import SwiftUI

/// The menu (plan Q13): the Master Switch, the toggles grouped by area, the
/// Reduce Motion row, then "Launch at login", "Restore all and quit" and "Quit".
struct MenuView: View {
    let model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            masterSwitch
            ForEach(model.warnings, id: \.self) { WarningText($0) }
            Divider()
            ForEach(AnimationGroup.allCases, id: \.self) { group in
                VStack(alignment: .leading, spacing: 4) {
                    Text(group.title)
                        .font(.caption.weight(.semibold))
                        .foregroundStyle(.secondary)
                    ForEach(model.animations(in: group)) { animation in
                        row(animation)
                    }
                }
            }
            .disabled(!model.isWorking)
            Divider()
            reduceMotionRow
            Divider()
            launchAtLoginRow
            Divider()
            HStack {
                Button("Restore all and quit") { model.restoreAllAndQuit() }
                Spacer()
                Button("Quit") { model.quit() }
                    .keyboardShortcut("q")
            }
        }
        .padding(14)
        .frame(width: 340)
        .onAppear { model.refresh() }
    }

    private var masterSwitch: some View {
        Toggle(isOn: Binding(
            get: { !model.animationsDisabled },
            set: { model.setAnimationsEnabled($0) }
        )) {
            VStack(alignment: .leading, spacing: 2) {
                Text("Animations").font(.headline)
                Text(model.animationsDisabled ? "Off: the checked animations are disabled" : "On: macOS animates as usual")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .toggleStyle(.switch)
        .disabled(!model.isWorking)
    }

    private func row(_ animation: Animation) -> some View {
        VStack(alignment: .leading, spacing: 1) {
            Toggle(animation.label, isOn: Binding(
                get: { model.managed.contains(animation.id) },
                set: { model.setToggle(animation.id, checked: $0) }
            ))
            .toggleStyle(.checkbox)
            Group {
                ForEach(model.notes[animation.id] ?? [], id: \.self) { note in
                    Text(note.text)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                if let failure = model.failures[animation.id] {
                    WarningText(failure)
                }
            }
            .padding(.leading, 20)
        }
    }

    private var reduceMotionRow: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Reduce Motion: \(model.reduceMotion ? "On" : "Off")")
                Text("Set by macOS. Animation Switch never changes it.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Button("Open Settings") { model.openMotionSettings() }
        }
    }

    private var launchAtLoginRow: some View {
        VStack(alignment: .leading, spacing: 1) {
            Toggle("Launch at login", isOn: Binding(
                get: { model.launchAtLogin.isEnabled },
                set: { model.launchAtLogin.set($0) }
            ))
            .toggleStyle(.checkbox)
            if let warning = model.launchAtLogin.warning {
                Button {
                    model.launchAtLogin.openLoginItemsSettings()
                } label: {
                    WarningText(warning)
                }
                .buttonStyle(.plain)
                .padding(.leading, 20)
            }
        }
    }
}

/// A one-line inline warning (plan Q16). Never a pop-up.
struct WarningText: View {
    let text: String
    init(_ text: String) { self.text = text }

    var body: some View {
        Label(text, systemImage: "exclamationmark.triangle.fill")
            .font(.caption)
            .foregroundStyle(.orange)
            .fixedSize(horizontal: false, vertical: true)
    }
}
