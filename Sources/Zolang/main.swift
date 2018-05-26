import ZolangCore

let zolang = Zolang()

do {
    try zolang.run()
} catch {
    print("Whoops! An error occurred: \(error)")
}
