import Metal

extension ConstantData {
    init() {
        mvp = float4x4()
        drawStyle = 0
        light = float3(10,10,0)
        unused1 = float4()
        unused2 = float4()
    }
}

extension TVertex {
    init(_ p:float3) {
        pos = p
        nrm = float3()
        txt = float2(0,0)
        color = float4(1,1,1,1)
        drawStyle = 0
    }
    
    init(_ p:float3, _ ncolor:float4) {
        pos = p
        nrm = float3()
        txt = float2(0,0)
        color = ncolor
        drawStyle = 0
    }
}

var constantData = ConstantData()
var shell:[Shell] = []
var atom:Atom!
var autoJiggle = false
var updateAtomicNumber = true
var showShells = true

class World {
    init() {
        shell.append(Shell(1))
        shell.append(Shell(2))
        shell.append(Shell(4))
        atom = Atom()
        
        vc.updateSliders()
    }
    
    func update(_ controller:ViewController) {
        atom.update()
        
        if updateAtomicNumber {
            updateAtomicNumber = false
            vc.instructions.text = elementList.atomicData(nProton[0] + nProton[1] + nProton[2])
        }
    }
    
    func render(_ renderEncoder:MTLRenderCommandEncoder) {
        if showShells { for s in shell { s.render(renderEncoder) }}
        atom.render(renderEncoder)
    }
    
    func changeRadius(_ index:Int, _ amt:Int) {
        let nr = shell[index].radius + Float(amt)/20
        if nr > 0.01 && nr < 40 {
            shell[index].setRadius(nr)
            atom.newConfiguration()
        }
    }
}

