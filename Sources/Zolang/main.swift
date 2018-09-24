import Foundation
import ZolangCore

let zolang = Zolang()

do {
    try zolang.run()
} catch {
    
    if let zError = error as? ZolangError {
        zError.dump()
    } else {
        Log.error("Error: \(error.localizedDescription)")
    }
    
}
