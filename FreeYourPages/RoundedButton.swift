import UIKit
public class RoundedButton: UIButton {
    
    public var roundRectCornerRadius: CGFloat = 4 {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    
    @IBInspectable public var roundRectColor = UIColor.black {
        didSet {
            self.setNeedsLayout()
        }
    }
    
    
    
    override public func layoutSubviews() {
        super.layoutSubviews()
     
        layoutRoundRectLayer()
    }
    
    
    private var roundRectLayer: CAShapeLayer?
    
    private func layoutRoundRectLayer() {
        
        if let existingLayer = roundRectLayer {
            existingLayer.removeFromSuperlayer()
        }
        
        let shapeLayer = CAShapeLayer()
        
        shapeLayer.path = UIBezierPath(roundedRect: self.bounds, cornerRadius: roundRectCornerRadius).cgPath
        shapeLayer.fillColor = roundRectColor.cgColor
        
        self.layer.insertSublayer(shapeLayer, at: 0)
        self.backgroundColor = self.superview!.backgroundColor
        
        self.roundRectLayer = shapeLayer
    }
}
