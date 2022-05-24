
// Map、Filter和Reduce
// 高阶函数

// 泛型
func increment(array: [Int]) -> [Int] {
    var result: [Int] = []
    for x in array {
        result.append(x + 1)
    }
    return result
}

func double(array: [Int]) -> [Int] {
    var result: [Int] = []
    for x in array {
        result.append(x * 2)
    }
    return result
}

func compute(array: [Int], transform: (Int) -> Int) -> [Int] {
    var result: [Int] = []
    for x in array {
        result.append(transform(x))
    }
    return result
}

func double2(array: [Int]) -> [Int] {
    return compute(array: array) { $0 * 2 }
}

func genericCompute<T>(array: [Int], transform: (Int) -> T) -> [T] {
    var result: [T] = []
    for x in array {
        result.append(transform(x))
    }
    return result
}

func map<Element, T>(_ array: [Element], transform: (Element) -> T) -> [T] {
    var result: [T] = []
    for x in array {
        result.append(transform(x))
    }
    return result
}

func genericCompute2<T>(array: [Int], transform: (Int) -> T) -> [T] {
    return map(array, transform: transform)
}

extension Array {
    func map<T>(_ transform: (Element) -> T) -> [T] {
        var result: [T] = []
        for x in self {
            result.append(transform(x))
        }
        return result
    }
}

func genericCompute3<T>(array: [Int], transform: (Int) -> T) -> [T] {
    return array.map(transform)
}

// 顶层函数和类型扩展

// Filter
let exampleFiles = ["README.md", "HelloWorld.swift", "FlappyBird.swift"]
func getSwiftFiles(in files: [String]) -> [String] {
    var result: [String] = []
    for file in files {
        if file.hasSuffix(".swift") {
            result.append(file)
        }
    }
    return result
}

getSwiftFiles(in: exampleFiles) // ["HelloWorld.swift", "FlappyBird.swift"]

extension Array {
    func filter(_ includeElement: (Element) -> Bool) -> [Element] {
        var result: [Element] = []
        for x in self where includeElement(x) {
            result.append(x)
        }
        return result
    }
}

func getSwiftFiles2(in files: [String]) -> [String] {
    return files.filter { file in file.hasSuffix(".swift") }
}

// Reduce

func sum(integers: [Int]) -> Int {
    var result: Int = 0
    for x in integers {
        result += x
    }
    return result
}

sum(integers: [1, 2, 3, 4]) // 10

func product(integers: [Int]) -> Int {
    var result: Int = 1
    for x in integers {
        result = x * result
    }
    return result
}

func concatenate(strings: [String]) -> String {
    var result: String = ""
    for string in strings {
        result += string
    }
    return result
}

func prettyPrint(strings: [String]) -> String {
    var result: String = "Entries in the array xs:\n"
    for string in strings {
        result = "  " + result + string + "\n"
    }
    return result
}

extension Array {
    func reduce<T>(_ initial: T, combine: (T, Element) -> T) -> T {
        var result = initial
        for x in self {
            result = combine(result, x)
        }
        return result
    }
}

func sumUsingReduce(integers: [Int]) -> Int {
    return integers.reduce(0) { result, x in result + x }
}

func productUsingReduce(integers: [Int]) -> Int {
    return integers.reduce(1, combine: *)
}

func concatUsingReduce(strings: [String]) -> String {
    return strings.reduce("", combine: +)
}

func flatten<T>(_ xss: [[T]]) -> [T] {
    var result: [T] = []
    for xs in xss {
        result += xs // [a,b] + [c, d] = [a, b, c, d]
    }
    return result
}

func flattenUsingReduce<T>(_ xss: [[T]]) -> [T] {
    return xss.reduce([]) { result, xs in result + xs }
}

extension Array {
    func mapUsingReduce<T>(_ transform: (Element) -> T) -> [T] {
        return reduce([]) { result, x in
            return result + [transform(x)]
        }
    }
    func filterUsingReduce(_ includeElement: (Element) -> Bool) -> [Element] {
        return reduce([]) { result, x in
            return includeElement(x) ? result + [x] : result
        }
    }
}

// 尽管通过 reduce 来定义一切是个很有趣的练习，但是在实践中这往往不是一个什么好主意。
// 原因在于，不出意外的话你的代码最终会在运行期间大量复制生成的数组，换句话说，它会反复分配内存，释放内存，以及复制大量内存中的内容。
// 比如说，用一个可变结果数组来编写 map 的效率显然会更高。理论上，编译器可以优化上述代码，使其速度与可变结果数组的版本一样快，但是 Swift (目前) 并没有那么做

struct City {
    let name: String
    let population: Int
}

let paris = City(name: "Paris", population: 2241)
let madrid = City(name: "Madrid", population: 3165)
let amsterdam = City(name: "Amsterdam", population: 827)
let berlin = City(name: "Berlin", population: 3562)
let cities = [paris, madrid, amsterdam, berlin]

extension City {
    func scalingPopulation() -> City {
        return City(name: name, population: population * 1000)
    }
}

cities.filter { $0.population > 1000 }
    .map { $0.scalingPopulation() }
    .reduce("City: Population") { result, c in
        return result + "\n" + "\(c.name): \(c.population)"
    }

// 泛型和 Any 类型
// 区别：泛型可以用于定义灵活的函数，类型检查仍然由编译器负责；而 Any 类型则可以避开 Swift 的类型系统 (所以应该尽可能避免使用)。
func noOp<T>(_ x: T) -> T {
return x
}

func noOpAny(_ x: Any) -> Any {
return x
}

// noOp 和 noOpAny 两者都将接受任意参数。关键的区别在于我们所知道的返回值。在 noOp 的定义中，我们可以清楚地看到返回值和输入值完全一样。而 noOpAny 的例子则不太一样，返回值是任意类型 — 甚至可以是和原来的输入值不同的类型。

func noOpAnyWrong(_ x: Any) -> Any {
    return 0
}

// 使用 Any 类型可以避开 Swift 的类型系统。
// 然而，尝试将使用泛型定义的 noOp 函数返回值设为 0 将会导致类型错误。
// 此外，任何调用 noOpAny 的函数都不知道返回值会被转换为何种类型。而结果就是可能导致各种各样的运行时错误。

infix operator >>>
func >>> <A, B, C>(f: @escaping (A) -> B, g: @escaping (B) -> C) -> (A) -> C {
    return { x in g(f(x)) }
}

func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { x in { y in f(x, y) } }
}




