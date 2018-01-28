import Metal

class Sphere {
    var vBuffer: MTLBuffer?
    var iBufferL: MTLBuffer?
    var iBufferT: MTLBuffer?
    var vData = Array<TVertex>()    // vertices
    var iDataL = Array<UInt16>()    // indices of line segments
    var iDataT = Array<UInt16>()    // indices of triangles
    var nLat:Int = 10
    var nLong:Int = 10
    var radius:Float = 1
    var center:float3 = float3(0,0,0)
    var color:float4 = float4(1,1,0,1)
    var drawStyle:UInt8 = 1

    func setPosition(_ pos:float3, _ recalc:Bool) {
        center = pos
        if recalc { generate() }
    }
    
    func setRadius(_ nradius:Float, _ recalc:Bool) {
        radius = nradius
        if recalc { generate() }
    }
    
    func setColor(_ ncolor:float4, _ recalc:Bool) {
        color = ncolor
        if recalc { generate() }
    }

    func setLatLong(_ nnLat:Int, _ nnLong:Int, _ recalc:Bool) {
        nLat = nnLat
        nLong = nnLong
        if recalc { generate() }
    }
    
    func generate() {
        let nPitch = nLong + 1
        let pitchInc = Float(Double.pi) / Float(nPitch)
        let rotInc   = Float(Double.pi * 2) / Float(nLat)
        
        vData.removeAll()
        iDataL.removeAll()
        iDataT.removeAll()

        for p in 1 ..< nPitch {
            let out = fabs(radius * sinf(Float(p) * pitchInc))
            let y = radius * cosf(Float(p) * pitchInc)
            var fs:Float = 0
            for i in 0 ..< nLat {
                let model:float3 = float3(out * cosf(fs),y,out * sin(fs))
                
                var v = TVertex(center + model,color)
                v.nrm = normalize(model)
                v.txt.x = Float(i) / Float(nLat-1)
                v.txt.y = Float(p) / Float(nPitch)
                v.drawStyle = drawStyle
                vData.append(v)
                fs += rotInc
            }
        }

        // top, bottom
        var v = TVertex(float3(center.x, center.y+radius, center.z),color)
        v.nrm = normalize(float3(0,radius,0))
        v.drawStyle = drawStyle
        vData.append(v)
        
        v = TVertex(float3(center.x, center.y-radius, center.z),color)
        v.nrm = normalize(float3(0,-radius,0))
        v.drawStyle = drawStyle
        vData.append(v)

        let topIndex = UInt16(vData.count - 2)

        // Line indices ------------------------------
        for p in 0 ..< nPitch-1 {
            let p2 = p * nLat
            for s in 0 ..< nLat {
                var s2 = s+1; if s2 == nLat { s2 = 0 }
                iDataL.append(UInt16(p2 + s))
                iDataL.append(UInt16(p2 + s2))
                
                if p < nPitch-2 {
                    iDataL.append(UInt16(p2 + s))
                    iDataL.append(UInt16(p2 + nLat + s))
                }
            }
        }
        
        for s in 0 ..< nLat {
            iDataL.append(UInt16(s))
            iDataL.append(topIndex)
            iDataL.append(UInt16((nPitch-2)*nLat + s ))
            iDataL.append(topIndex+1)
        }
        
        // Triangle indices ------------------------------
        for p in 0 ..< nPitch-2 {
            let p2 = p * nLat
            for s in 0 ..< nLat {
                var s2 = s+1; if s2 == nLat { s2 = 0 }
                let i1 = UInt16(p2 + s)
                let i2 = UInt16(p2 + s2)
                let i3 = i2 + UInt16(nLat)
                let i4 = i1 + UInt16(nLat)
                iDataT.append(i1);  iDataT.append(i2);  iDataT.append(i3)
                iDataT.append(i1);  iDataT.append(i3);  iDataT.append(i4)
            }
        }
        
        for s in 0 ..< nLat {
            var s2 = s+1; if s2 == nLat { s2 = 0 }
            iDataT.append(UInt16(s))
            iDataT.append(topIndex)
            iDataT.append(UInt16(s2))
            
            iDataT.append(UInt16(s + (nPitch-2)*nLat))
            iDataT.append(UInt16(s2 + (nPitch-2)*nLat))
            iDataT.append(topIndex+1)
        }

        vBuffer  = gDevice?.makeBuffer(bytes: vData,  length: vData.count  * MemoryLayout<TVertex>.size, options: MTLResourceOptions())
        iBufferL = gDevice?.makeBuffer(bytes: iDataL, length: iDataL.count * MemoryLayout<UInt16>.size,  options: MTLResourceOptions())
        iBufferT = gDevice?.makeBuffer(bytes: iDataT, length: iDataT.count * MemoryLayout<UInt16>.size,  options: MTLResourceOptions())
    }
    
    func render(_ renderEncoder:MTLRenderCommandEncoder) {
        if vData.count == 0 { return }

        renderEncoder.setVertexBuffer(vBuffer, offset: 0, index: 0)
        
        if drawStyle == 1  {
            renderEncoder.drawIndexedPrimitives(type: .triangle,  indexCount: iDataT.count, indexType: MTLIndexType.uint16, indexBuffer: iBufferT!, indexBufferOffset:0)
        }
        else {
            renderEncoder.drawIndexedPrimitives(type: .line,  indexCount: iDataL.count, indexType: MTLIndexType.uint16, indexBuffer: iBufferL!, indexBufferOffset:0)
        }
    }
}


