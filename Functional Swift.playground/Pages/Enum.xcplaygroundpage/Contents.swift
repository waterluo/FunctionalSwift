import Foundation

enum LookupError: Error {
    case capitalNotFound
    case populationNotFound
}

enum PopulationResult {
    case success(Int)
    case error(LookupError)
}
/*
func populationOfCapital(country: String) -> PopulationResult {
    guard let capital = capitals[country] else {
        return .error(.capitalNotFound)
    }
    guard let population = cities[capital] else {
        return .error(.populationNotFound)
    }
    return .success(population)
}
 
switch populationOfCapital(country: "France") {
case let .success(population):
    print("France's capital has \(population) thousand inhabitants")
case let .error(error):
    print("Error: \(error)")
}
*/

let mayors = [
"Paris": "Hidalgo",
"Madrid": "Carmena",
"Amsterdam": "van der Laan",
"Berlin": "Müller"
]

let capitals = [
    "France": "Paris",
    "Spain": "Madrid",
    "The Netherlands": "Amsterdam",
    "Belgium": "Brussels"
]

func mayorOfCapital(country: String) -> String? {
    return capitals[country].flatMap {
       mayors[$0]
    }
}

enum MayorResult {
    case success(String)
    case error(Error)
}
// 泛型
enum Result<T> {
    case success(T)
    case error(Error)
}

/*
 func populationOfCapital(country: String) -> Result<Int>
 func mayorOfCapital(country: String) -> Result<String>
 */

// Swift 中的错误处理
let cities = ["Paris": 2241, "Madrid": 3165, "Amsterdam": 827, "Berlin": 3562]
func populationOfCapital(country: String) throws -> Int {
    guard let capital = capitals[country] else {
        throw LookupError.capitalNotFound
    }
    
    guard let population = cities[capital] else {
        throw LookupError.populationNotFound
    }
    return population
}

do {
    let population = try populationOfCapital(country: "France")
    print("France's population is \(population)")
} catch {
    print("Lookup error: \(error)")
}

func ??<T>(result: Result<T>, handleError: (Error) -> T) -> T {
    switch result {
    case let .success(value):
        return value
    case let .error(error):
        return handleError(error)
    }
}

// 值得注意的是，我们并没有 (像在之前讨论可选值的相关章节中对 ?? 的定义那样) 使用 autoclosure 来标记第二个参数。
// 实际上，在这里我们会显式地要求传入一个以 Error 作为参数的函数，而该函数需要返回一个类型为 T 的值。

/// “数据类型中的代数学”

// 理解两个类型在什么时候是同构 (isomorphic) 的
// “比较直观的解释是，如果两个类型 A 和 B 在相互转换时不会丢失任何信息，那么它们就是同构的。”
// “我们可以随意地利用 f 和 g 来转换 A 和 B，而不会丢失信息 (也就是说我们可以利用 g 来撤销 f，反之亦然)。”

enum Add<T, U> {
    case inLeft(T)
    case inRight(U)
}

enum Zero {
    
}

// “在 Swift 3 中，标准库添加了一个类型 Never。Never 与 Zero 的定义十分相似：它可以作为一个不返回任何值的函数的返回类型。
// 在函数式语言中，该类型有时也被称作底层类型(bottom type)”

typealias Times<T, U> = (T, U)

typealias One = ()
/*
Times<One, T> 与 T 是同构的
Times<Zero, T> 与 Zero 是同构的
Times<T, U> 与 Times<U, T> 是同构的
*/

// 使用枚举和结构体定义的类型有时候也被称作代数数据类型 (algebraic data types)，因为它们就像自然数一样，具有代数学结构。

