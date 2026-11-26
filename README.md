# SoliqIDKit (iOS)

Prebuilt XCFramework for identity verification by face: looks the person up (PINFL or passport), opens a session, runs the [YuzIDKit](https://github.com/usmdroid/yuzidkit) face capture screen and compares the face on the server. Native replacement for the `soliq_id` Flutter package.

## Requirements
- iOS 15.5+, Swift 5
- `NSCameraUsageDescription` in `Info.plist`
- A real device: ML Kit (used by YuzIDKit) has no arm64 simulator slice, and this XCFramework ships the `ios-arm64` slice only

## Installation (CocoaPods)
YuzIDKit is not on CocoaPods trunk, so declare it next to SoliqIDKit:
```ruby
platform :ios, '15.5'
use_frameworks! :linkage => :static   # required by ML Kit

pod 'YuzIDKit',   :git => 'https://github.com/usmdroid/yuzidkit.git',    :tag => '1.0.3'
pod 'SoliqIDKit', :git => 'https://github.com/usmdroid/soliq_id_kit.git', :tag => '1.0.0'
```

## Usage
```swift
import SoliqIDKit

let config = SoliqIDConfig(
    infoType: .pinfl,                 // or .passport
    pinfl: "12345678901234",
    guid: token,                      // server token (Bearer)
    applicationGuid: "...",           // optional
    language: .uz,                    // .uz, .uzCyrillic, .ru, .en, .karakalpak
    showsResultScreen: true
)

SoliqID.present(config: config) { result in
    switch result {
    case .completed(let event): print(event.dictionary)   // same keys as the Flutter onEvent map
    case .cancelled:            break                     // user left before finishing
    case .failure(let error):   print(error)              // .invalidConfiguration, .securityCheckFailed, .server(...)
    }
}
```
For a passport: `infoType: .passport, passportSeries: "AA", passportNumber: "1234567", birthDate: "21.01.1999"`.

### Security checks
The SDK refuses to run on a jailbroken device, on the simulator, or with a debugger attached. For development use `allowDebugger: true` (when running from Xcode) and `allowSimulator: true`; keep both `false` in production.

## Example app
```bash
cd example && pod install && open Example.xcworkspace
```
Pick your signing team and run on a real iPhone. Enter the server token in the `guid` field.

## License
Apache-2.0
