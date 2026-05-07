import UIKit

struct FontManager {
    static func registerFonts<T: FontRepresentable>(fontFamily: T.Type) {
        let bundle = Bundle.main

        for font in T.allCases {
            guard let fontURL = bundle.url(forResource: font.rawValue, withExtension: "ttf") else {
                print("⚠️ Cannot find font \(font.rawValue).ttf in bundle")
                continue
            }

            var error: Unmanaged<CFError>?
            if !CTFontManagerRegisterFontsForURL(fontURL as CFURL, .process, &error) {
                if let err = error?.takeRetainedValue() {
                    let errorDomain = CFErrorGetDomain(err) as String
                    let errorCode = CFErrorGetCode(err)
                    if errorDomain == kCTFontManagerErrorDomain as String && (errorCode == 105 || errorCode == 305) {
                        // Already registered, this is fine
                    } else {
                        print("❌ Cannot register font '\(font.rawValue)': \(err.localizedDescription)")
                    }
                }
            }
        }
    }
}

protocol FontRepresentable: RawRepresentable, CaseIterable where RawValue == String {}

protocol FontRegisterable: CaseIterable {
    static var allCases: [any StringConvertible] { get }
}

protocol StringConvertible {
    var stringValue: String { get }
}

extension RawRepresentable where RawValue == String, Self: CaseIterable, Self: FontRegisterable {
    static var allCases: [any StringConvertible] {
        return allCases.map { $0 as StringConvertible }
    }
}

extension RawRepresentable where RawValue == String, Self: StringConvertible {
    var stringValue: String {
        return self.rawValue
    }
}
