import UIKit

@IBDesignable
class LevelView: UIView {

    @IBInspectable var batteryLevel: CGFloat = 0.0 {
        didSet {
            setNeedsDisplay()
        }
    }

    override func draw(_ rect: CGRect) {
        drawLevel(batteryLevel: batteryLevel)
    }

    func drawLevel(batteryLevel: CGFloat = 0.6) {
        //// General Declarations
        let context = UIGraphicsGetCurrentContext()!
        
        
        //// Variable Declarations
        let width: CGFloat = 80 * batteryLevel
        let batteryLabelText = "\(Int(batteryLevel * 100))" + "%"
        
        //// White Rectangle Drawing
        let whiteRectanglePath = UIBezierPath(roundedRect: CGRect(x: 2.5, y: 2.5, width: 80, height: 20), cornerRadius: 5)
        UIColor.white.setFill()
        whiteRectanglePath.fill()
        UIColor.black.setStroke()
        whiteRectanglePath.lineWidth = 2
        whiteRectanglePath.stroke()
        
        
        //// Green Rectangle Drawing
        let greenRectangleRect = CGRect(x: 2.5, y: 2.5, width: width, height: 20)
        let greenRectanglePath = UIBezierPath(roundedRect: greenRectangleRect, cornerRadius: 5)
        UIColor.systemGreen.setFill()
        greenRectanglePath.fill()
        UIColor.black.setStroke()
        greenRectanglePath.lineWidth = 1
        greenRectanglePath.stroke()
        let greenRectangleStyle = NSMutableParagraphStyle()
        greenRectangleStyle.alignment = .center
        let greenRectangleFontAttributes = [
            NSAttributedString.Key.font: UIFont(name: "HelveticaNeue-Bold", size: 8)!,
            NSAttributedString.Key.foregroundColor: UIColor.black,
            NSAttributedString.Key.paragraphStyle: greenRectangleStyle,
        ]
        
        let greenRectangleTextHeight: CGFloat = batteryLabelText.boundingRect(with: CGSize(width: greenRectangleRect.width, height: CGFloat.infinity), options: .usesLineFragmentOrigin, attributes: greenRectangleFontAttributes, context: nil).height
        context.saveGState()
        context.clip(to: greenRectangleRect)
        batteryLabelText.draw(in: CGRect(x: greenRectangleRect.minX, y: greenRectangleRect.minY + (greenRectangleRect.height - greenRectangleTextHeight) / 2, width: greenRectangleRect.width, height: greenRectangleTextHeight), withAttributes: greenRectangleFontAttributes)
        context.restoreGState()
        
    }


}
