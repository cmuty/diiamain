import UIKit

class AnimatedGradientBackgroundView: UIView {
    private let gradientLayer = CAGradientLayer()
    private var colorIndex = 0
    private var timer: Timer?
    
    private let colorSets: [[UIColor]] = [
        [
            UIColor(hex: "6ea8ff"), // Синій
            UIColor(hex: "ffd966"), // Жовтий
            UIColor(hex: "ff99cc")  // Рожевий
        ],
        [
            UIColor(hex: "ffd966"), // Жовтий
            UIColor(hex: "ff99cc"), // Рожевий
            UIColor(hex: "c299ff")  // Бузковий
        ],
        [
            UIColor(hex: "ff99cc"), // Рожевий
            UIColor(hex: "c299ff"), // Бузковий
            UIColor(hex: "6ea8ff")  // Синій
        ],
        [
            UIColor(hex: "c299ff"), // Бузковий
            UIColor(hex: "6ea8ff"), // Синій
            UIColor(hex: "ffd966")  // Жовтий
        ]
    ]
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
        startAnimation()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupGradient()
        startAnimation()
    }
    
    private func setupGradient() {
        gradientLayer.frame = bounds
        gradientLayer.colors = colorSets[0].map { $0.cgColor }
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
    
    private func startAnimation() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.colorIndex = (self.colorIndex + 1) % self.colorSets.count
            
            CATransaction.begin()
            CATransaction.setAnimationDuration(2.5)
            CATransaction.setAnimationTimingFunction(CAMediaTimingFunction(name: .easeInEaseOut))
            self.gradientLayer.colors = self.colorSets[self.colorIndex].map { $0.cgColor }
            CATransaction.commit()
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}

extension UIColor {
    convenience init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            red: CGFloat(r) / 255,
            green: CGFloat(g) / 255,
            blue: CGFloat(b) / 255,
            alpha: CGFloat(a) / 255
        )
    }
}

