import SwiftUI
import Network

struct NMEAViewControllerRepresentable: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> NMEA_Client_ViewController {
        return NMEA_Client_ViewController()
    }

    func updateUIViewController(_ uiViewController: NMEA_Client_ViewController, context: Context) {}
}

class NMEA_Client_ViewController: UIViewController {

    enum ConnectionState { case disconnected, connecting, connected, error(String) }
    private var connectionState: ConnectionState = .disconnected {
        didSet { DispatchQueue.main.async { self.updateUIForState() } }
    }

    private lazy var tcpClient: TCPClient = { let c = TCPClient(); c.delegate = self; return c }()
    private let backgroundGradient = CAGradientLayer()
    private let titleLabel = UILabel()
    private let instructionsLabel = UILabel()
    private let helpButton = UIButton(type: .system)
    private let connectionStatusView = ConnectionStatusView(frame: .zero)
    private let ipInputView = LabeledTextFieldView(label: "SERVER IP", placeholder: "192.168.56.1")
    private let portInputView = LabeledTextFieldView(label: "PORT", placeholder: "50000")
    private let connectButton = UIButton()
    private let disconnectButton = UIButton()
    private let dataGrid = DataGridView(frame: .zero)
    private let rawOutputView = RawOutputView(frame: .zero)

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupLayout()
        loadSettings()
        connectionState = .disconnected
        handleFirstLaunch()
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    private func setupUI() -> Void {
        backgroundGradient.colors = [UIColor(red: 0.09, green: 0.11, blue: 0.13, alpha: 1.00).cgColor, UIColor(red: 0.05, green: 0.06, blue: 0.07, alpha: 1.00).cgColor]
        backgroundGradient.frame = view.bounds
        view.layer.insertSublayer(backgroundGradient, at: 0)

        titleLabel.text = "Perspective Racing"
        titleLabel.font = .systemFont(ofSize: 24, weight: .bold); titleLabel.textColor = .white; titleLabel.textAlignment = .center

        instructionsLabel.text = "Enter your NMEA server details below and press Connect."
        instructionsLabel.font = .systemFont(ofSize: 14, weight: .regular); instructionsLabel.textColor = .white; instructionsLabel.textAlignment = .center; instructionsLabel.numberOfLines = 0

        helpButton.setImage(UIImage(systemName: "questionmark.circle.fill"), for: .normal); helpButton.tintColor = .white
        helpButton.addTarget(self, action: #selector(helpButtonTapped), for: .touchUpInside)

        ipInputView.textField.keyboardType = .decimalPad
        portInputView.textField.keyboardType = .numberPad

        var connectConfig = UIButton.Configuration.filled(); connectConfig.title = "CONNECT"; connectConfig.baseBackgroundColor = UIColor(red: 0.15, green: 0.45, blue: 0.85, alpha: 1.00); connectConfig.baseForegroundColor = .white; connectConfig.cornerStyle = .capsule
        connectButton.configuration = connectConfig
        connectButton.addTarget(self, action: #selector(connectButtonTapped), for: .touchUpInside)

        var disconnectConfig = UIButton.Configuration.filled(); disconnectConfig.title = "DISCONNECT"; disconnectConfig.baseBackgroundColor = UIColor(red: 0.82, green: 0.25, blue: 0.25, alpha: 1.00); disconnectConfig.baseForegroundColor = .white; disconnectConfig.cornerStyle = .capsule
        disconnectButton.configuration = disconnectConfig
        disconnectButton.addTarget(self, action: #selector(disconnectButtonTapped), for: .touchUpInside)
    }

    private func setupLayout() -> Void {
        let scrollView = UIScrollView()
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.showsVerticalScrollIndicator = false
        view.addSubview(scrollView)

        let contentView = UIView()
        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)

        [titleLabel, instructionsLabel, helpButton, connectionStatusView, ipInputView, portInputView, connectButton, disconnectButton, dataGrid, rawOutputView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            contentView.addSubview($0)
        }

        let margin: CGFloat = 24

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),

            titleLabel.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 20),
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            helpButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            helpButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            instructionsLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            instructionsLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            instructionsLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            connectionStatusView.topAnchor.constraint(equalTo: instructionsLabel.bottomAnchor, constant: 20),
            connectionStatusView.centerXAnchor.constraint(equalTo: contentView.centerXAnchor),

            ipInputView.topAnchor.constraint(equalTo: connectionStatusView.bottomAnchor, constant: 20),
            ipInputView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            ipInputView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            portInputView.topAnchor.constraint(equalTo: ipInputView.bottomAnchor, constant: 16),
            portInputView.leadingAnchor.constraint(equalTo: ipInputView.leadingAnchor),
            portInputView.trailingAnchor.constraint(equalTo: ipInputView.trailingAnchor),

            connectButton.topAnchor.constraint(equalTo: portInputView.bottomAnchor, constant: 24),
            connectButton.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            connectButton.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            connectButton.heightAnchor.constraint(equalToConstant: 50),

            disconnectButton.topAnchor.constraint(equalTo: connectButton.topAnchor),
            disconnectButton.leadingAnchor.constraint(equalTo: connectButton.leadingAnchor),
            disconnectButton.trailingAnchor.constraint(equalTo: connectButton.trailingAnchor),
            disconnectButton.bottomAnchor.constraint(equalTo: connectButton.bottomAnchor),

            dataGrid.topAnchor.constraint(equalTo: connectButton.bottomAnchor, constant: 24),
            dataGrid.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            dataGrid.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),

            rawOutputView.topAnchor.constraint(equalTo: dataGrid.bottomAnchor, constant: 16),
            rawOutputView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: margin),
            rawOutputView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -margin),
            rawOutputView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -16),
            rawOutputView.heightAnchor.constraint(equalToConstant: 200)
        ])
    }

    // MARK: - UI Update Logic
    private func updateUIForState() -> Void {
        UIView.animate(withDuration: 0.35, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.connectButton.alpha = 0; self.disconnectButton.alpha = 0; self.instructionsLabel.alpha = 0
            self.connectButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95); self.disconnectButton.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            switch self.connectionState {
            case .disconnected: self.connectionStatusView.setState(.disconnected, text: "Offline"); self.connectButton.alpha = 1; self.connectButton.transform = .identity; self.instructionsLabel.alpha = 1; self.ipInputView.isEnabled = true; self.portInputView.isEnabled = true
            case .connecting: self.connectionStatusView.setState(.connecting, text: "Connecting..."); self.ipInputView.isEnabled = false; self.portInputView.isEnabled = false
            case .connected: self.connectionStatusView.setState(.connected, text: "Connected"); self.disconnectButton.alpha = 1; self.disconnectButton.transform = .identity; self.ipInputView.isEnabled = false; self.portInputView.isEnabled = false
            case .error(let message): self.connectionStatusView.setState(.error, text: "Error"); self.connectButton.alpha = 1; self.connectButton.transform = .identity; self.instructionsLabel.alpha = 1; self.ipInputView.isEnabled = true; self.portInputView.isEnabled = true; self.presentAlert(title: "Connection Error", message: message)
            }
        })
    }

    // MARK: - Actions & Helpers
    @objc private func connectButtonTapped() -> Void { view.endEditing(true); guard let ip = ipInputView.text, !ip.isEmpty, let portString = portInputView.text, let port = UInt16(portString) else { presentAlert(title: "Invalid Input", message: "Please enter a valid IP address and port number."); return }; connectionState = .connecting; tcpClient.connect(to: ip, port: port) }
    @objc private func disconnectButtonTapped() -> Void { tcpClient.disconnect() }
    @objc private func helpButtonTapped() -> Void { showInstructionsPopup() }
    private func handleFirstLaunch() -> Void { let key = "hasLaunchedBefore"; if !UserDefaults.standard.bool(forKey: key) { showInstructionsPopup(); UserDefaults.standard.set(true, forKey: key) } }
    private func showInstructionsPopup() -> Void { let t = "Welcome to Perspective Racing"; let m = "To get started:\n\n1. Connect your device to the same Wi-Fi network as your NMEA data source.\n\n2. Enter the IP Address and Port of your NMEA source.\n\n3. Tap Connect to begin receiving data."; let a = UIAlertController(title: t, message: m, preferredStyle: .alert); a.addAction(UIAlertAction(title: "Got it!", style: .default)); present(a, animated: true) }
    private func loadSettings() -> Void { let s = SettingsManager.load(); ipInputView.text = s.ip ?? "192.168.56.1"; portInputView.text = String(s.port ?? 50000) }
    private func presentAlert(title: String, message: String) -> Void { let a = UIAlertController(title: title, message: message, preferredStyle: .alert); a.addAction(UIAlertAction(title: "OK", style: .default)); present(a, animated: true) }
}

// MARK: - TCPClientDelegate Conformance
extension NMEA_Client_ViewController: TCPClientDelegate {
    func tcpClientDidConnect() -> Void { connectionState = .connected; if let ip = ipInputView.text, let port = portInputView.text { SettingsManager.save(ip: ip, port: port) } }
    func tcpClientDidDisconnect() -> Void { connectionState = .disconnected }
    func tcpClientEncountered(error: String) -> Void { connectionState = .error(error) }
    func tcpClientDidReceive(sentence: String) -> Void { DispatchQueue.main.async { self.rawOutputView.appendText(sentence); if let p = NMEAParser.parse(sentence) { self.dataGrid.update(with: p) } } }
}

// MARK: - Custom UI Components
class ConnectionStatusView: UIView {
    private let statusIndicator = UIView(); private let statusLabel = UILabel()
    enum State { case disconnected, connecting, connected, error }
    override init(frame: CGRect) { super.init(frame: frame); setupViews() }; required init?(coder: NSCoder) { fatalError() }
    private func setupViews() -> Void { [statusIndicator, statusLabel].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }; statusIndicator.layer.cornerRadius = 6; statusLabel.font = .systemFont(ofSize: 14, weight: .medium); statusLabel.textColor = .white; NSLayoutConstraint.activate([ statusIndicator.leadingAnchor.constraint(equalTo: leadingAnchor), statusIndicator.centerYAnchor.constraint(equalTo: centerYAnchor), statusIndicator.widthAnchor.constraint(equalToConstant: 12), statusIndicator.heightAnchor.constraint(equalToConstant: 12), statusLabel.leadingAnchor.constraint(equalTo: statusIndicator.trailingAnchor, constant: 8), statusLabel.trailingAnchor.constraint(equalTo: trailingAnchor), statusLabel.topAnchor.constraint(equalTo: topAnchor), statusLabel.bottomAnchor.constraint(equalTo: bottomAnchor) ]) }
    func setState(_ state: State, text: String) -> Void { statusLabel.text = text; var color = UIColor.gray; switch state { case .disconnected: color = .gray; case .connecting: color = .systemYellow; case .connected: color = .systemGreen; case .error: color = .systemRed }; UIView.animate(withDuration: 0.3) { self.statusIndicator.backgroundColor = color } }
}
class LabeledTextFieldView: UIView {
    let textField = UITextField(); var text: String? { get { textField.text } set { textField.text = newValue } }; var isEnabled: Bool { get { textField.isEnabled } set { textField.isEnabled = newValue; alpha = newValue ? 1.0 : 0.6 } }
    init(label: String, placeholder: String) { super.init(frame: .zero); let l = UILabel(); l.text = label; self.textField.placeholder = placeholder; setupViews(label: l) }; required init?(coder: NSCoder) { fatalError() }
    private func setupViews(label: UILabel) -> Void { [label, textField].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }; label.font = .systemFont(ofSize: 12, weight: .bold); label.textColor = .white; textField.borderStyle = .none; textField.backgroundColor = UIColor(white: 1.0, alpha: 0.1); textField.layer.cornerRadius = 8; textField.textColor = .white; textField.font = .monospacedSystemFont(ofSize: 16, weight: .regular); textField.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 12, height: 0)); textField.leftViewMode = .always; NSLayoutConstraint.activate([ label.topAnchor.constraint(equalTo: topAnchor), label.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4), textField.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 4), textField.leadingAnchor.constraint(equalTo: leadingAnchor), textField.trailingAnchor.constraint(equalTo: trailingAnchor), textField.bottomAnchor.constraint(equalTo: bottomAnchor), textField.heightAnchor.constraint(equalToConstant: 44) ]) }
}
class DataGridView: UIView {
    private let latLonView = DataGridItemView(title: "LAT / LON", iconName: "location.fill")
    private let sogView = DataGridItemView(title: "SPEED", iconName: "speedometer")
    private let cogView = DataGridItemView(title: "HEADING", iconName: "safari.fill")
    private let windView = DataGridItemView(title: "WIND (T)", iconName: "wind")
    private let depthView = DataGridItemView(title: "DEPTH", iconName: "ruler.fill")

    override init(frame: CGRect) { super.init(frame: frame); setupViews() }; required init?(coder: NSCoder) { fatalError() }

    private func setupViews() -> Void {
        let topStack = UIStackView(arrangedSubviews: [windView, sogView, depthView])
        topStack.distribution = .fillEqually
        topStack.spacing = 12

        let bottomStack = UIStackView(arrangedSubviews: [latLonView, cogView])
        bottomStack.distribution = .fillEqually
        bottomStack.spacing = 12

        let mainStack = UIStackView(arrangedSubviews: [topStack, bottomStack])
        mainStack.translatesAutoresizingMaskIntoConstraints = false
        mainStack.axis = .vertical
        mainStack.spacing = 12

        addSubview(mainStack)
        NSLayoutConstraint.activate([
            mainStack.topAnchor.constraint(equalTo: topAnchor),
            mainStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            mainStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            mainStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func update(with data: NMEAParser.NMEAData) -> Void {
        switch data {
        case .rmc(let d):
            if let lat = d.latitude, let lon = d.longitude { latLonView.setValue(String(format: "%.4f, %.4f", lat, lon)) }
            if let sog = d.speedOverGround { sogView.setValue(String(format: "%.1f kts", sog)) }
            if let cog = d.courseOverGround { cogView.setValue(String(format: "%.1f°", cog)) }
        case .gga(let d):
            if let lat = d.latitude, let lon = d.longitude { latLonView.setValue(String(format: "%.4f, %.4f", lat, lon)) }
        case .vtg(let d):
            if let cog = d.trueTrack { cogView.setValue(String(format: "%.1f°", cog)) }
            if let sog = d.speedKnots { sogView.setValue(String(format: "%.1f kts", sog)) }
        case .dbt(let d):
            if let depth = d.depthMeters { depthView.setValue(String(format: "%.1f m", depth)) }
        case .hdt(let d):
            if let heading = d.heading { cogView.setValue(String(format: "%.1f°", heading)) }
        case .mwv(let d):
            if let speed = d.windSpeed, let angle = d.windAngle, let reference = d.reference {
                let windType = reference == "T" ? "T" : "R"
                windView.setValue(String(format: "%.1fkt @ %.0f° (%@)", speed, angle, windType))
            }
        case .gll(_): // GLL does not have speed or course data
            break
        }
    }
}

class DataGridItemView: UIView {
    private let valueLabel = UILabel()
    init(title: String, iconName: String) { super.init(frame: .zero); let t = UILabel(); t.text = title; let i = UIImageView(image: UIImage(systemName: iconName)); setupViews(title: t, icon: i) }; required init?(coder: NSCoder) { fatalError() }
    private func setupViews(title: UILabel, icon: UIImageView) -> Void { backgroundColor = UIColor(white: 1.0, alpha: 0.1); layer.cornerRadius = 12; [title, valueLabel, icon].forEach { $0.translatesAutoresizingMaskIntoConstraints = false; addSubview($0) }; icon.tintColor = .lightGray; icon.contentMode = .scaleAspectFit; title.font = .systemFont(ofSize: 12, weight: .bold); title.textColor = .white; valueLabel.font = .systemFont(ofSize: 20, weight: .medium); valueLabel.textColor = .white; valueLabel.text = "--"; valueLabel.numberOfLines = 0; valueLabel.lineBreakMode = .byWordWrapping; valueLabel.textAlignment = .center; NSLayoutConstraint.activate([ heightAnchor.constraint(greaterThanOrEqualToConstant: 80), icon.topAnchor.constraint(equalTo: topAnchor, constant: 12), icon.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12), icon.widthAnchor.constraint(equalToConstant: 16), icon.heightAnchor.constraint(equalToConstant: 16), title.centerYAnchor.constraint(equalTo: icon.centerYAnchor), title.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 6), valueLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12), valueLabel.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12), valueLabel.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -12), valueLabel.topAnchor.constraint(equalTo: title.bottomAnchor, constant: 8) ]) }
    func setValue(_ text: String) -> Void { valueLabel.text = text }
}

class RawOutputView: UIView {
    private let textView = UITextView()
    override init(frame: CGRect) { super.init(frame: frame); setupViews() }; required init?(coder: NSCoder) { fatalError() }
    private func setupViews() -> Void { textView.translatesAutoresizingMaskIntoConstraints = false; addSubview(textView); textView.isEditable = false; textView.backgroundColor = UIColor(white: 0, alpha: 0.2); textView.layer.cornerRadius = 8; textView.textColor = .white; textView.font = .monospacedSystemFont(ofSize: 10, weight: .regular); textView.text = "RAW NMEA 0183 SENTENCES\n-----------------------\n"; NSLayoutConstraint.activate([textView.topAnchor.constraint(equalTo: topAnchor), textView.leadingAnchor.constraint(equalTo: leadingAnchor), textView.trailingAnchor.constraint(equalTo: trailingAnchor), textView.bottomAnchor.constraint(equalTo: bottomAnchor)]) }
    func appendText(_ text: String) -> Void { textView.text += text + "\n"; let range = NSRange(location: textView.text.count - 1, length: 1); textView.scrollRangeToVisible(range) }
}

private extension UIButton {
    func frame(in view: UIView) -> Void {
        self.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(self)
        NSLayoutConstraint.activate([
            self.topAnchor.constraint(equalTo: view.topAnchor),
            self.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            self.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            self.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
}