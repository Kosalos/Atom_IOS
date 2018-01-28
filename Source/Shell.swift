import Metal

class Shell {
    var radius:Float = 1
    let sphere = Sphere()

    init(_ nradius:Float) {
        radius = nradius
        sphere.drawStyle = 0
        
        let gray:Float = 0.03
        sphere.setColor(float4(gray,gray,gray,0.3),false)
        
        sphere.setLatLong(16,16,false)
        sphere.setRadius(nradius,true)
    }

    init(_ nradius:Float, _ color:float4, _ nLat:Int, _ nLong:Int) {
        radius = nradius
        sphere.setColor(color,false)
        sphere.setLatLong(nLat,nLong,false)
        sphere.setRadius(nradius,true)
    }
    
    func setRadius(_ nradius:Float) {
        radius = nradius
        sphere.setRadius(nradius,true)
    }

    func render(_ renderEncoder:MTLRenderCommandEncoder) {
        sphere.render(renderEncoder)
    }
}
