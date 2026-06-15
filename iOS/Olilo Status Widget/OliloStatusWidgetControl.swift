import AppIntents
import SwiftUI
import WidgetKit

struct OliloStatusWidgetControl: ControlWidget {
    static let kind: String = "com.example.olilostatus.Olilo Status Widget"

    var body: some ControlWidgetConfiguration {
        AppIntentControlConfiguration(
            kind: Self.kind,
            provider: Provider()
        ) { value in
            ControlWidgetToggle(
                "Start Timer",
                isOn: value.isRunning,
                action: StartTimerIntent(value.name)
            ) { isRunning in
                Label(isRunning ? "On" : "Off", systemImage: "timer")
            }
        }
        .displayName("Timer")
        .description("A an example control that runs a timer.")
    }
}

extension OliloStatusWidgetControl {
    struct Value {
        var isRunning: Bool
        var name: String
    }

    struct Provider: AppIntentControlValueProvider {
        /// Provides static control state for previews and the widget gallery.
        func previewValue(configuration: TimerConfiguration) -> Value {
            OliloStatusWidgetControl.Value(isRunning: false, name: configuration.timerName)
        }

        /// Provides the current control value for the configured timer name.
        func currentValue(configuration: TimerConfiguration) async throws -> Value {
            let isRunning = true
            return OliloStatusWidgetControl.Value(isRunning: isRunning, name: configuration.timerName)
        }
    }
}

struct TimerConfiguration: ControlConfigurationIntent {
    static let title: LocalizedStringResource = "Timer Name Configuration"

    @Parameter(title: "Timer Name", default: "Timer")
    var timerName: String
}

struct StartTimerIntent: SetValueIntent {
    static let title: LocalizedStringResource = "Start a timer"

    @Parameter(title: "Timer Name")
    var name: String

    @Parameter(title: "Timer is running")
    var value: Bool

    /// Creates the intent with default App Intents initialization.
    init() {}

    /// Creates the intent for a specific timer name from the control widget.
    init(_ name: String) {
        self.name = name
    }

    /// Completes the control action without additional side effects.
    func perform() async throws -> some IntentResult {
        return .result()
    }
}
