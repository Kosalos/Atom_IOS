import Metal

class Proton {
    var radius:Float = 1
    var angle = float2()
    var pos = float3()
    var color = float4(1,1,1,1)
    var shellIndex:Int = 0
    
    init(_ sIndex:Int) {
        shellIndex = sIndex
        radius = shell[shellIndex].radius
        color = shellColor[shellIndex]
        angle = randomAngle()
        calcPos()
    }
    
    func vertex() -> TVertex { return TVertex(pos,color) }

    func randomAngle() -> float2 {
        var angle = float2()
        angle.x = Float(arc4random() & 1023) / 1024
        angle.y = Float(arc4random() & 1023) / 1024
        return angle
    }

    func calcPos() {
        pos = float3(radius,0,0)
        
        var qt = pos.x  // X rotation
        pos.x = pos.x * cosf(angle.x) - pos.y * sinf(angle.x)
        pos.y = qt * sinf(angle.x) + pos.y * cosf(angle.x)
        
        qt = pos.y      // Y rotation
        pos.y = pos.y * cosf(angle.y) - pos.z * sinf(angle.y)
        pos.z = qt * sinf(angle.y) + pos.z * cosf(angle.y)
    }
}
