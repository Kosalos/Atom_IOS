import Foundation

var elementList = ElementList()

struct Element {
    var number:Int = 0
    var legend:String = ""
    var name:String = ""
    init(_ c:Int, _ l:String, _ n:String) { number = c; legend = l; name = n }
}

class ElementList {
    var data:[Element] = []
    
    init() {
        let bundle = Bundle.main
        let path = bundle.path(forResource: "elements", ofType: "txt")
       
        do {
            let content = try String(contentsOfFile: path!)
            let rows:[String] = content.components(separatedBy:"\n")
            
            for i in 0 ..< rows.count-1 {
                var fields:[String] = rows[i].components(separatedBy:",")
                let n = Int(fields[0] as String)
                data.append(Element(n!,fields[1],fields[2]))

            }
        } catch {
            fatalError("\n\nload elements.txt failed\n\n")
        }
    }
    
    func atomicData(_ n:Int) -> String {
        if n < 1 || n > 118 { return "Unknown element" }
        let d = data[n-1]
        let s:String = "Atomic# " + d.number.description + "  " + d.legend + ",  " + d.name
        return s
    }
}


