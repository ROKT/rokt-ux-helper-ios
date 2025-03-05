## Extension Components

Extension Components are modular UI components that can be dynamically loaded and rendered within the EscapeHatchComponent. They provide a flexible way to extend the UI capabilities of the SDK.

### Creating a New Extension Component

1. Create a new directory under `UI/Components/Extensions/` for your component:
```bash
mkdir -p UI/Components/Extensions/YourComponent
```

2. Create the following files:

#### YourComponentModel.swift
```swift
struct YourComponentModel: Codable {
    // Define your component's properties
    let property1: String
    let property2: Int
    // ... other properties
}
```

Create the following files:

#### YourComponentModel.swift
```swift
struct YourComponentModel: Codable {
    // Define your component's properties
    let property1: String
    let property2: Int
    // ... other properties
}
```

#### YourComponent.swift
```swift
@available(iOS 15, *)
struct YourComponent: ExtensionComponent {
    typealias Model = YourComponentModel
    
    let config: ComponentConfig
    @StateObject private var viewModel: YourComponentViewModel
    let data: ExtensionData
    let layoutState: (any LayoutStateRepresenting)?
    let eventService: EventDiagnosticServicing?
    let slot: SlotOfferModel?
    
    static func create(from data: ExtensionData, config: ComponentConfig, layoutState: (any LayoutStateRepresenting)?, eventService: EventDiagnosticServicing?, slot: SlotOfferModel?) -> YourComponent? {
        guard let modelData = try? JSONDecoder().decode(YourComponentModel.self, from: data.body.data(using: .utf8) ?? Data()) else {
            return nil
        }
        
        let viewModel = YourComponentViewModel(
            property1: modelData.property1,
            property2: modelData.property2,
            layoutState: layoutState,
            eventService: eventService,
            slot: slot
        )
        
        return YourComponent(
            config: config,
            viewModel: viewModel,
            data: data,
            layoutState: layoutState,
            eventService: eventService,
            slot: slot
        )
    }
    
    init(
        config: ComponentConfig,
        viewModel: YourComponentViewModel,
        data: ExtensionData,
        layoutState: (any LayoutStateRepresenting)?,
        eventService: EventDiagnosticServicing?,
        slot: SlotOfferModel?
    ) {
        self.config = config
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.data = data
        self.layoutState = layoutState
        self.eventService = eventService
        self.slot = slot
    }
    
    var body: some View {
        // Your component's view implementation
        Text("Your Component")
    }
}
```

### 2. Register Your Component

Register your component in `EscapeHatchComponent.swift`:

```swift
private let escapeHatchExtensionComponents: [String: (ExtensionData, ComponentConfig, (any LayoutStateRepresenting)?, EventDiagnosticServicing?, SlotOfferModel?) -> AnyExtensionComponent?] = [
    // ... existing components ...
    "your_component": { data, config, layoutState, eventService, slot in
        guard let component = YourComponent.create(from: data, config: config, layoutState: layoutState, eventService: eventService, slot: slot) else {
            return nil
        }
        return AnyExtensionComponent(component)
    }
]
```

## Accessing states and creatives
Extension components have access to various states and creative content through the provided parameters:

### Accessing Layout States

The `layoutState` parameter implements `LayoutStateRepresenting` and provides access to various UI states:

### Accessing Creative copy
Extension components can access creative content through the `slot` parameter, which contains the `SlotOfferModel`. This model provides access to:

- **Creative Text**: Access text content defined in the creative

## Events and Error reporting
Extension components can report events and diagnostic information using the `eventService` parameter. The `EventDiagnosticServicing` protocol provides methods for logging different types of events:


## Example: Countdown Timer Component

Here's a complete example of the Countdown Timer component from the codebase:

### JSON Configuration
```json
{
  "type": "EscapeHatch",
  "node": {
    "data": "{\"type\":\"Extension\",\"name\":\"count-down-timer\",\"body\":{\"duration\":10,\"backgroundColor\":\"#7f56d9\",\"textColor\":\"#7f56d9\",\"textSize\":16}}"
  }
}
```

### Model
```swift
struct CountdownTimerModel: Codable {
    let duration: Int
    let backgroundColor: String
    let textColor: String
    let textSize: Int
}
```

### Component
```swift
@available(iOS 15, *)
struct CountdownTimerComponent: ExtensionComponent {
    typealias Model = CountdownTimerModel
    
    let config: ComponentConfig
    @StateObject private var viewModel: CountdownTimerViewModel
    let data: ExtensionData
    let layoutState: (any LayoutStateRepresenting)?
    let eventService: EventDiagnosticServicing?
    let slot: SlotOfferModel?
    
    static func create(from data: ExtensionData, config: ComponentConfig, layoutState: (any LayoutStateRepresenting)?, eventService: EventDiagnosticServicing?, slot: SlotOfferModel?) -> CountdownTimerComponent? {
        guard let modelData = try? JSONDecoder().decode(CountdownTimerModel.self, from: data.body.data(using: .utf8) ?? Data()) else {
            return nil
        }
        
        let viewModel = CountdownTimerViewModel(
            duration: modelData.duration,
            backgroundColor: modelData.backgroundColor,
            textColor: modelData.textColor,
            textSize: modelData.textSize,
            layoutState: layoutState,
            eventService: eventService,
            slot: slot
        )
        
        return CountdownTimerComponent(
            config: config,
            viewModel: viewModel,
            data: data,
            layoutState: layoutState,
            eventService: eventService,
            slot: slot
        )
    }
    
    init(
        config: ComponentConfig,
        viewModel: CountdownTimerViewModel,
        data: ExtensionData,
        layoutState: (any LayoutStateRepresenting)?,
        eventService: EventDiagnosticServicing?,
        slot: SlotOfferModel?
    ) {
        self.config = config
        self._viewModel = StateObject(wrappedValue: viewModel)
        self.data = data
        self.layoutState = layoutState
        self.eventService = eventService
        self.slot = slot
    }
    
    var body: some View {
        TimerText(
            secondsLeft: viewModel.timeLeft,
            backgroundColor: Color(hex: viewModel.backgroundColor),
            textColor: Color(hex: viewModel.textColor),
            textSize: CGFloat(viewModel.textSize)
        )
        .onAppear {
            viewModel.startTimer()
        }
        .onDisappear {
            viewModel.stopTimer()
        }
    }
}

@available(iOS 15, *)
private struct TimerText: View {
    let secondsLeft: Int
    let backgroundColor: Color
    let textColor: Color
    let textSize: CGFloat
    
    var body: some View {
        HStack(spacing: 0) {
            Image(systemName: "timer")
                .foregroundColor(backgroundColor)
                .padding(4)
            
            Text(String(format: "%02d:%02d", secondsLeft / 60, secondsLeft % 60))
                .font(.system(size: textSize))
                .foregroundColor(textColor)
                .padding(4)
        }
        .background(Color(hex: "#f2f4f7"))
        .cornerRadius(30)
        .padding(2)
    }
}
```

## Best Practices

1. **Naming Conventions**:
   - Use snake_case for component type strings in JSON
   - Use PascalCase for Swift types and files
   - Use camelCase for properties and methods

2. **Error Handling**:
   - Always validate input data in the `create` method
   - Return `nil` if the component cannot be created
   - Log errors using the `eventService` when appropriate

3. **State Management**:
   - Use `@Published` for properties that should trigger UI updates
   - Use `@StateObject` for view models in components
   - Keep business logic in the ViewModel

4. **UI Guidelines**:
   - Use SF Symbols for icons when possible
   - Follow iOS design guidelines

## Testing

When creating a new component, ensure to:
1. Test the component with various input data
2. Verify error handling
3. Check memory management
4. Test UI updates and state changes
5. Validate accessibility features