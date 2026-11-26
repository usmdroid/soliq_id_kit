import UIKit
import SoliqIDKit

/// SoliqIDKit ulanishini ko'rsatuvchi ilova. Butun integratsiya `startTapped` ichidagi bitta chaqiruv.
final class ViewController: UIViewController {
    private let languages: [(title: String, value: SoliqIDLanguage)] = [
        ("UZ", .uz), ("ЎЗ", .uzCyrillic), ("RU", .ru), ("EN", .en), ("QQ", .karakalpak),
    ]
    private let languageControl = UISegmentedControl(items: ["UZ", "ЎЗ", "RU", "EN", "QQ"])
    private let typeControl = UISegmentedControl(items: ["JSHSHIR", "Pasport"])
    private let pinflField = UITextField()
    private let seriesField = UITextField()
    private let numberField = UITextField()
    private let birthField = UITextField()
    private let guidField = UITextField()
    private let appGuidField = UITextField()
    private let resultSwitch = UISwitch()
    private let debugSwitch = UISwitch()
    private let startButton = UIButton(type: .system)
    private let outputView = UITextView()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        title = "SoliqID Example"

        // Appbar trailing: Auth (login/parol saqlangan bo'lsa yashil, bo'lmasa qizil).
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            title: "Auth", style: .plain, target: self, action: #selector(authTapped)
        )
        refreshAuthButton()

        languageControl.selectedSegmentIndex = 0
        typeControl.selectedSegmentIndex = 0
        typeControl.addTarget(self, action: #selector(typeChanged), for: .valueChanged)

        configure(pinflField, "JSHSHIR: 12345678901234", keyboard: .numberPad, mask: .pinfl)
        configure(seriesField, "Pasport seriyasi: AB", keyboard: .asciiCapable, mask: .series)
        configure(numberField, "Pasport raqami: 1234567", keyboard: .numberPad, mask: .number)
        configure(birthField, "Tug'ilgan sana: 01.01.2000", keyboard: .numberPad, mask: .birth)
        configure(guidField, "guid (Auth bo'lmasa shu ishlatiladi)")
        configure(appGuidField, "applicationGuid (ixtiyoriy)")
        typeChanged()

        resultSwitch.isOn = true
        debugSwitch.isOn = true

        var config = UIButton.Configuration.filled()
        config.title = "SoliqID ni boshlash"
        startButton.configuration = config
        startButton.addTarget(self, action: #selector(startTapped), for: .touchUpInside)

        outputView.isEditable = false
        outputView.font = .monospacedSystemFont(ofSize: 12, weight: .regular)
        outputView.backgroundColor = .secondarySystemBackground
        outputView.layer.cornerRadius = 12
        outputView.text = "Ma'lumotlarni kiriting va tugmani bosing"

        let stack = UIStackView(arrangedSubviews: [
            languageControl, typeControl, pinflField, seriesField, numberField, birthField,
            guidField, appGuidField,
            row("Natija ekrani", resultSwitch),
            row("Debugger'ga ruxsat (faqat Xcode)", debugSwitch),
            startButton, outputView,
        ])
        stack.axis = .vertical
        stack.spacing = 10
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stack.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -12),
        ])
        view.addGestureRecognizer(UITapGestureRecognizer(target: view, action: #selector(UIView.endEditing(_:))))
    }

    /// Kiritish maskalari: seriya 2 ta katta harf, raqam 7 ta raqam, sana dd.MM.yyyy, JSHSHIR 14 ta raqam.
    private enum Mask { case pinfl, series, number, birth }
    private var masks: [ObjectIdentifier: Mask] = [:]

    private func apply(_ mask: Mask, to raw: String) -> String {
        let digits = raw.filter { $0.isASCII && $0.isNumber }
        switch mask {
        case .pinfl: return String(digits.prefix(14))
        case .number: return String(digits.prefix(7))
        case .series:
            return String(raw.uppercased().filter { $0.isASCII && $0.isLetter }.prefix(2))
        case .birth:
            let d = Array(digits.prefix(8))
            var out = ""
            for (i, ch) in d.enumerated() {
                if i == 2 || i == 4 { out.append(".") }
                out.append(ch)
            }
            return out
        }
    }

    private func configure(_ field: UITextField, _ placeholder: String, keyboard: UIKeyboardType = .default, mask: Mask? = nil) {
        if let mask = mask {
            masks[ObjectIdentifier(field)] = mask
            field.delegate = self
        }
        field.placeholder = placeholder
        field.borderStyle = .roundedRect
        field.keyboardType = keyboard
        field.autocapitalizationType = .none
        field.autocorrectionType = .no
    }

    private func row(_ title: String, _ toggle: UISwitch) -> UIStackView {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 14)
        return UIStackView(arrangedSubviews: [label, toggle])
    }

    @objc private func typeChanged() {
        let isPinfl = typeControl.selectedSegmentIndex == 0
        pinflField.isHidden = !isPinfl
        seriesField.isHidden = isPinfl
        numberField.isHidden = isPinfl
        birthField.isHidden = isPinfl
    }

    // MARK: Auth

    private func refreshAuthButton() {
        navigationItem.rightBarButtonItem?.tintColor = AuthStore.hasCredentials ? .systemGreen : .systemRed
    }

    @objc private func authTapped() {
        let alert = UIAlertController(
            title: "Auth (Basic)",
            message: "Login va parol saqlanadi. Har tekshiruvdan oldin shular bilan token olinadi.",
            preferredStyle: .alert
        )
        alert.addTextField { $0.placeholder = "login"; $0.text = AuthStore.login; $0.autocapitalizationType = .none; $0.autocorrectionType = .no }
        alert.addTextField { $0.placeholder = "parol"; $0.text = AuthStore.password; $0.isSecureTextEntry = true }
        alert.addAction(UIAlertAction(title: "Saqlash", style: .default) { [weak self] _ in
            let login = alert.textFields?[0].text ?? ""
            let password = alert.textFields?[1].text ?? ""
            if login.isEmpty || password.isEmpty {
                AuthStore.clear()
            } else {
                AuthStore.save(login: login, password: password)
            }
            self?.refreshAuthButton()
        })
        alert.addAction(UIAlertAction(title: "O'chirish", style: .destructive) { [weak self] _ in
            AuthStore.clear()
            self?.refreshAuthButton()
        })
        alert.addAction(UIAlertAction(title: "Bekor", style: .cancel))
        present(alert, animated: true)
    }

    @objc private func startTapped() {
        view.endEditing(true)
        Task { @MainActor in
            // Auth (Basic) saqlangan bo'lsa shundan token olinadi, aks holda guid maydoni ishlatiladi.
            var guid = guidField.text ?? ""
            if AuthStore.hasCredentials {
                outputView.text = "Token olinmoqda..."
                do {
                    guid = try await AuthStore.fetchToken()
                } catch {
                    let message = (error as? AuthStore.TokenError)?.message ?? error.localizedDescription
                    outputView.text = "Token olishda xato: \(message)"
                    return
                }
            } else if guid.isEmpty {
                outputView.text = "Auth tugmasi (yuqori o'ngda) orqali login/parol kiriting yoki guid kiriting"
                return
            }
            start(guid: guid)
        }
    }

    private func start(guid: String) {
        let isPinfl = typeControl.selectedSegmentIndex == 0
        let config = SoliqIDConfig(
            infoType: isPinfl ? .pinfl : .passport,
            pinfl: pinflField.text ?? "",
            passportSeries: seriesField.text ?? "",
            passportNumber: numberField.text ?? "",
            birthDate: birthField.text ?? "",
            guid: guid,
            applicationGuid: appGuidField.text,
            language: languages[languageControl.selectedSegmentIndex].value,
            showsResultScreen: resultSwitch.isOn,
            allowDebugger: debugSwitch.isOn
        )

        // Butun integratsiya shu bitta chaqiruv.
        SoliqID.present(config: config) { [weak self] result in
            switch result {
            case .completed(let event):
                var info = event.dictionary
                if var data = info["data"] as? [String: Any] {
                    data["image"] = "<\(event.imageBase64.count / 1024) KB base64>"
                    info["data"] = data
                }
                self?.outputView.text = (info as NSDictionary).description
            case .cancelled:
                self?.outputView.text = "Bekor qilindi"
            case .failure(let error):
                self?.outputView.text = "Xato: \(error)"
            }
        }
    }
}

extension ViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        guard let mask = masks[ObjectIdentifier(textField)] else { return true }
        let proposed = ((textField.text ?? "") as NSString).replacingCharacters(in: range, with: string)
        textField.text = apply(mask, to: proposed)
        return false
    }
}
