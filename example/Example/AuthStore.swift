import Foundation
import Security

/// Basic auth uchun login/parolni Keychain'da saqlaydi va token oladi (`GET auth/get-token`).
/// Faqat test ilovasi uchun: haqiqiy ilovada token host serveringiz orqali olinadi.
enum AuthStore {
    private static let service = "uz.soliqid.example.auth"

    static var login: String { read("login") ?? "" }
    static var password: String { read("password") ?? "" }
    static var hasCredentials: Bool { !login.isEmpty && !password.isEmpty }

    static func save(login: String, password: String) {
        write(login, for: "login")
        write(password, for: "password")
    }

    static func clear() {
        remove("login")
        remove("password")
    }

    struct TokenError: Error { let message: String }

    /// Har tekshiruvdan oldin yangi token olinadi.
    static func fetchToken() async throws -> String {
        guard hasCredentials else { throw TokenError(message: "Login/parol kiritilmagan") }
        var request = URLRequest(url: URL(string: "https://api.yuzid.uz/auth/get-token")!)
        request.httpMethod = "GET"
        request.timeoutInterval = 30
        let basic = Data("\(login.trimmingCharacters(in: .whitespacesAndNewlines)):\(password)".utf8).base64EncodedString()
        request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let (data, response) = try await URLSession.shared.data(for: request)
        let status = (response as? HTTPURLResponse)?.statusCode ?? 0
        let json = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        guard (200..<300).contains(status), let token = json?["token"] as? String, !token.isEmpty else {
            // Xato javobida token yo'q, shuning uchun matnini logga yozish xavfsiz.
            let serverMessage = (json?["message"] as? String) ?? String(data: data.prefix(200), encoding: .utf8) ?? ""
            throw TokenError(message: "Token olinmadi (HTTP \(status)) \(serverMessage)")
        }
        return token
    }

    // MARK: Keychain

    private static func query(_ account: String) -> [String: Any] {
        [kSecClass as String: kSecClassGenericPassword,
         kSecAttrService as String: service,
         kSecAttrAccount as String: account]
    }

    private static func read(_ account: String) -> String? {
        var q = query(account)
        q[kSecReturnData as String] = true
        q[kSecMatchLimit as String] = kSecMatchLimitOne
        var out: AnyObject?
        guard SecItemCopyMatching(q as CFDictionary, &out) == errSecSuccess, let data = out as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    private static func write(_ value: String, for account: String) {
        remove(account)
        var q = query(account)
        q[kSecValueData as String] = Data(value.utf8)
        SecItemAdd(q as CFDictionary, nil)
    }

    private static func remove(_ account: String) {
        SecItemDelete(query(account) as CFDictionary)
    }
}
