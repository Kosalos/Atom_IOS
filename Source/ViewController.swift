import UIKit
import MetalKit

var timer = Timer()
var vc:ViewController!

class ViewController: UIViewController{
    var renderer: Renderer!
    
    override var prefersStatusBarHidden: Bool { return true }

    @IBOutlet var metalView: MetalView!
    @IBOutlet var instructions: UITextView!
    @IBOutlet var nPoints0: UISlider!
    @IBOutlet var nPoints1: UISlider!
    @IBOutlet var nPoints2: UISlider!
    @IBOutlet var nPoints0Legend: UILabel!
    @IBOutlet var nPoints1Legend: UILabel!
    @IBOutlet var nPoints2Legend: UILabel!
    @IBOutlet var shellSize1: UISlider!
    @IBOutlet var shellSize2: UISlider!
    
    @IBAction func minus0(_ sender: Any) { atom.changeNumPoints(0,-1);  updateSliders() }
    @IBAction func plus0(_ sender: Any) { atom.changeNumPoints(0,+1);  updateSliders()   }
    @IBAction func minus1(_ sender: Any) { atom.changeNumPoints(1,-1);  updateSliders()  }
    @IBAction func plus1(_ sender: Any) { atom.changeNumPoints(1,+1);  updateSliders()  }
    @IBAction func minus2(_ sender: Any) { atom.changeNumPoints(2,-1);  updateSliders() }
    @IBAction func plus2(_ sender: Any) { atom.changeNumPoints(2,+1);  updateSliders() }
    
    @IBAction func showShellsToggled(_ sender: UIButton) { showShells = !showShells }
    @IBAction func jiggleButtonPressed(_ sender: Any) { atom.jiggle() }
    @IBAction func autoJiggleToggled(_ sender: UISwitch) { autoJiggle = sender.isOn }
    
    @IBAction func nPointsChanged(_ sender: UISlider) {
        var index = 0
        if sender == nPoints1 { index = 1 }
        if sender == nPoints2 { index = 2 }
        
        atom.setNumPoints(index,Int(sender.value))
        updateAtomicNumber = true
        updateLegends()
    }
    
    @IBAction func shellSizeChanged(_ sender: UISlider) {
        let radius = 1.0 + sender.value * Float(40)
        if sender == shellSize1 { shell[1].setRadius(radius) }
        if sender == shellSize2 { shell[2].setRadius(radius) }
        atom.newConfiguration()
        updateAtomicNumber = true
    }
    
    func updateLegends() {
        nPoints0Legend!.text = String(format:"%2d",nProton[0])
        nPoints1Legend!.text = String(format:"%2d",nProton[1])
        nPoints2Legend!.text = String(format:"%2d",nProton[2])
    }
    
    func updateSliders() {
        nPoints0!.value = Float(nProton[0])
        nPoints1!.value = Float(nProton[1])
        nPoints2!.value = Float(nProton[2])
        shellSize1.value = shell[1].radius / Float(40)
        shellSize2.value = shell[2].radius / Float(40)
        updateAtomicNumber = true
        updateLegends()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        vc = self
        
        //Swift.print("TVertex = ", MemoryLayout<TVertex>.stride)
        
        guard let metalView = metalView else {
            print("View of Gameview controller is not an MTKView")
            return
        }
        
        guard let defaultDevice = MTLCreateSystemDefaultDevice() else {
            print("Metal is not supported")
            return
        }
        
        metalView.device = defaultDevice
        metalView.backgroundColor = UIColor.clear
        
        guard let newRenderer = Renderer(metalKitView: metalView) else {
            print("Renderer cannot be initialized")
            return
        }
        
        renderer = newRenderer
        renderer.mtkView(metalView, drawableSizeWillChange: metalView.drawableSize)
        metalView.delegate = renderer
    }

    // ===================================================

    var okayGestureArea = false
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            let pt = t.location(in: self.view)
          
            //Swift.print("Touched ",pt.x,pt.y)
            
            okayGestureArea = pt.y < CGFloat(1100)
        }
    }

    @IBAction func panGesture(_ sender: UIPanGestureRecognizer) {
        if !okayGestureArea { return }
        
        var t = sender.translation(in: self.view)
        let scale:CGFloat = 0.05
        t.x *= scale
        t.y *= scale
        arcBall.mouseDown(CGPoint(x: 500, y: 500))
        arcBall.mouseMove(CGPoint(x: 500 - t.x, y: 500 - t.y ))
    }
    
    @IBAction func pinchGesture(_ sender: UIPinchGestureRecognizer) {
        let min:Float = 1
        let max:Float = 100
        translationAmount *= Float(1 + (1-sender.scale) / 10 )
        if translationAmount < min { translationAmount = min }
        if translationAmount > max { translationAmount = max }
    }
}
