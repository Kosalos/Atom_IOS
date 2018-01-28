import Metal

let NUMSHELL = 3
let MAX_SHELL_PROTON = 40
let MAX_PROTON = MAX_SHELL_PROTON * NUMSHELL

var nProton:[Int] = [ 4,4,4 ]
let shellColor:[float4] = [  float4(0,1,1,1),float4(1,1,0,1), float4(1,0,1,1) ]
let aDiffStart:Float = 0.06

//MARK: -

class Atom {
    var sphere:[Sphere] = []
    var protonList:[Proton] = []
    var lData = Array<TVertex>()
    var lBuffer: MTLBuffer?
    var aDiff:Float = aDiffStart

    init() {
        newConfiguration()
        
        for i in 0 ..< MAX_PROTON {     // colored sphere at each proton point
            sphere.append(Sphere())
            sphere[i].drawStyle = 1
            sphere[i].setRadius(0.2,false)
            sphere[i].setLatLong(8,8,false)
            sphere[i].setColor(float4(1,1,0,1),true)
        }
    }
    
    func changeNumPoints(_ index:Int, _ amt:Int) {  // change #points for specified shell
        if nProton[index] + amt < 0 || nProton[index] + amt > MAX_SHELL_PROTON { return }
        nProton[index] += amt
        newConfiguration()
    }
    
    func setNumPoints(_ index:Int, _ value:Int) { // set #points for specified shell
        if value < 0 || value > MAX_SHELL_PROTON { return }
        nProton[index] = value
        newConfiguration()
    }
    
    func newConfiguration() {  // shell radius has changed. recalc proton positions
        var oldPosition:[float2] = []
        for i in 0 ..< protonList.count { oldPosition.append(protonList[i].angle) }
        
        protonList.removeAll()
        
        var oldIndex:Int = 0
        for s in 0 ..< NUMSHELL {
            for _ in 0 ..< nProton[s] {
                protonList.append(Proton(s))
                
                if oldPosition.count > 0 && oldIndex < oldPosition.count {
                    protonList[oldIndex].angle = oldPosition[oldIndex]
                    oldIndex += 1
                }
            }
        }
        
        aDiff = aDiffStart
    }
    
    //MARK: -

    func update() {
        func totalDistance(_ index:Int) -> Float {  // total distance of all protons vs each other
            var total:Float = 0
            
            for i in 0 ..< protonList.count {
                if i == index { continue }
                let diff = protonList[index].pos - protonList[i].pos
                total += sqrtf(diff.x*diff.x + diff.y*diff.y + diff.z*diff.z)
            }
            
            return total
        }
        
        if autoJiggle { jiggleAmt(300000) }
        
        for i in 0 ..< protonList.count {
            let old = protonList[i].angle       // current proton angle
            var distC = totalDistance(i)        // current distance
            
            protonList[i].angle.x -= aDiff      // distance if proton jogged -X
            protonList[i].calcPos()
            var distM = totalDistance(i)
            
            protonList[i].angle.x += aDiff * 2  // distance if proton jogged +X
            protonList[i].calcPos()
            var distP = totalDistance(i)
            
            // jog to position that reduces total distance
            if distM > distC && distM > distP { protonList[i].angle.x = old.x - aDiff } else
                if distP > distC && distP > distM { protonList[i].angle.x = old.x + aDiff } else
                { protonList[i].angle.x = old.x }
            
            protonList[i].calcPos()             // new current position
            
            //---------------------------------------------------------
            distC = totalDistance(i)            // same pattern for Y jog
            
            protonList[i].angle.y -= aDiff
            protonList[i].calcPos()
            distM = totalDistance(i)
            
            protonList[i].angle.y += aDiff * 2
            protonList[i].calcPos()
            distP = totalDistance(i)
            
            if distM > distC && distM > distP { protonList[i].angle.y = old.y - aDiff } else
                if distP > distC && distP > distM { protonList[i].angle.y = old.y + aDiff } else
                {  protonList[i].angle.y = old.y }
            
            protonList[i].calcPos()
            
            //--------------------------------------------------------
            let s = sphere[i]       // move sphere to new position
            s.drawStyle = 1
            s.setRadius(0.5 * shell[protonList[i].shellIndex].radius/5,false)
            s.setPosition(protonList[i].pos,false)
            s.setColor(protonList[i].color,true)
        }
        
        determineLines()
        
        aDiff *= 0.98
    }
    
    //MARK: - Chan's 3D hull determines which vertices form triangles
    func determineLines() {
        struct LGentry {
            var i:Int = 0
            var j:Int = 0
            init(_ i1:Int, _ i2:Int ) { i = i1; j = i2 }
        }
        
        var hullLineList:[LGentry] = []   // indices of two vertices to connect with a line
        
        func lineGroup(_ i1:Int, _ i2:Int, _ mult:Float) { // i1,i2 = range of protons indices in a single shell
            func addIfUnique(_ v:LGentry) {
                func isUnique(_ vi:Int, _ vj:Int) -> Bool { // already in the list?
                    var i = vi
                    var j = vj
                    if i > j { let t = i;  i = j; j = t }
                    
                    for c in 0 ..< hullLineList.count { if hullLineList[c].i == i && hullLineList[c].j == j { return false } }
                    return true
                }
                
                if isUnique(v.i,v.j) { hullLineList.append(v)  }
            }
            
            if i2 == i1+2 {  // 2 protons in this shell
                addIfUnique( LGentry( i1,i1+1) )
                return
            }
            
            // call Chan's 3D hull algorithm in C++
            var hk:[Float] = []     // input:  vertices
            var jk:[Int32] = []     // output: indices that form lower half 3D hull
            var jCount:Int32 = 0    // #indices returned
            
            for i in i1 ..< i2 {
                hk.append(protonList[i].pos.x)
                hk.append(protonList[i].pos.y)
                hk.append(protonList[i].pos.z * mult)    // 3D hull called twice to form 'lower' hull for both sides
            }
            
            for _ in 0 ..< 300 { jk.append(Int32()) }   // ensure enough storage for all triangle indices returned
            let hPtr:UnsafeMutablePointer = UnsafeMutablePointer(mutating:hk)
            let jPtr:UnsafeMutablePointer = UnsafeMutablePointer(mutating:jk)
            
            Objective_CPP().chan3DHull(hPtr,Int32(hk.count),jPtr,&jCount)
            
            var index:Int = 0   // store triangle as three lines into hullLineList
            while true {
                addIfUnique( LGentry( i1 + Int(jk[Int(index+0)]), i1 + Int(jk[Int(index+1)]) ))
                addIfUnique( LGentry( i1 + Int(jk[Int(index+1)]), i1 + Int(jk[Int(index+2)]) ))
                addIfUnique( LGentry( i1 + Int(jk[Int(index+2)]), i1 + Int(jk[Int(index+0)]) ))
                
                index += 3
                if index > jCount { break }
            }
        }
        
        func dl2(_ mult:Float) {    // separate line groups for each shell
            if nProton[0] > 1 { lineGroup(0,nProton[0],mult) }
            if nProton[1] > 1 { lineGroup(nProton[0],nProton[0]+nProton[1],mult) }
            if nProton[2] > 1 { lineGroup(nProton[0]+nProton[1],nProton[0]+nProton[1]+nProton[2],mult) }
        }
        
        // ------------------------------------------------------
        
        hullLineList.removeAll()    // array of unique line segment indices
        
        dl2(+1)     // Chan determines only lower Hull.  call with coords. flipped to force complete hull
        dl2(-1)
        
        lData.removeAll()           // array of vertices of line segments
        for i in 0 ..< hullLineList.count {
            let i1 = hullLineList[i].i
            let i2 = hullLineList[i].j
            if i1 >= protonList.count || i2 >= protonList.count { break }
            lData.append(protonList[hullLineList[i].i].vertex())
            lData.append(protonList[hullLineList[i].j].vertex())
        }
        
        if lData.count > 0 { lBuffer = gDevice?.makeBuffer(bytes: lData, length: lData.count * MemoryLayout<TVertex>.size, options: MTLResourceOptions()) }
    }
    
    //MARK: -
    
    func jiggle() { jiggleAmt(3000) }   // tweak protons to hopefully nudge them to lower energy positions
    
    func jiggleAmt(_ den:Int) {
        func random() -> Float { return Float(arc4random() & 1023) / Float(den) }
        
        for i in 0 ..< protonList.count {
            protonList[i].angle.x += random()
            protonList[i].angle.y += random()
        }
        
        aDiff = aDiffStart
    }
    
    //MARK: -
    
    func render(_ renderEncoder:MTLRenderCommandEncoder) {
        for i in 0 ..< protonList.count { sphere[i].render(renderEncoder) }
        
        if lData.count > 0 {
            renderEncoder.setVertexBuffer(lBuffer, offset: 0, index: 0)
            renderEncoder.drawPrimitives(type: .line, vertexStart: 0, vertexCount:lData.count)
        }
    }
}
