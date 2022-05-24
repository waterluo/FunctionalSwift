let cities = ["Paris": 2241, "Madrid": 3165, "Amsterdam": 827, "Berlin": 3562]
let madridPopulation: Int? = cities["Madrid"]
if madridPopulation != nil {
    print("The population of Madrid is \(madridPopulation! * 1000)")
} else {
    print("Unknown city: Madrid")
}

if let madridPopulation = cities["Madrid"] {
    print("The population of Madrid is \(madridPopulation * 1000)")
} else {
    print("Unknown city: Madrid")
}

//infix operator ??
//func ??<T>(optional: T?, defaultValue: () -> T) -> T {
//    if let x = optional {
//        return x
//    } else {
//        return defaultValue()
//    }
//}

// myOptional ?? { myDefaultValue }

// Swift 标准库中的定义通过使用 Swift 的 autoclosure 类型标签来避开创建显式闭包的需求。
// 它会在所需要的闭包中隐式地将参数封装到 ?? 运算符。这样一来，我们能够提供与最初相同的接口，但是用户无需再显式地创建闭包封装 defaultValue 参数
infix operator ??
func ??<T>(optional: T?, defaultValue: @autoclosure () throws -> T)
rethrows -> T
{
    if let x = optional {
        return x
    } else {
        return try defaultValue()
    }
}

// myOptional ?? myDefaultValue
print(madridPopulation ?? 1)

// 可选链
struct Order {
    let orderNumber: Int
    let person: Person?
}

struct Person {
    let name: String
    let address: Address?
}
struct Address {
    let streetName: String
    let city: String
    let state: String?
}

let order = Order(orderNumber: 42, person: nil)

// “我们使用了问号运算符来尝试对可选类型进行解包，而不是强制将它们解包。访问任意属性失败时，都将会导致整条语句链返回 nil。”
if let myState = order.person?.address?.state {
print("This order will be shipped to \(myState)")
} else {
print("Unknown person, address, or state.")
}

// 分支上的可选值
// “为了在一个 switch 语句中匹配可选值，我们简单地为 case 分支中的每个模式添加一个 ? 后缀”

switch madridPopulation {
case 0?: print("Nobody in Madrid")
case (1..<1000)?: print("Less than a million in Madrid")
case let x?: print("\(x) people in Madrid")
case nil: print("We don't know about Madrid")
}

// “guard 语句的设计旨在当一些条件不满足时，可以尽早退出当前作用域。”

func populationDescription(for city: String) -> String? {
    guard let population = cities[city] else { return nil }
    return "The population of Madrid is \(population)"
}
populationDescription(for: "Madrid")

// 可选映射
func increment(optional: Int?) -> Int? {
    guard let x = optional else { return nil }
    return x + 1
}
// 可选值的map函数
// Use the `map` method with a closure that returns a non-optional value.
// func map<U>(_ transform: (Wrapped) throws -> U) rethrows -> U?

// 可选值的flatMap 函数
// Use the `flatMap` method with a closure that returns an optional value.
//func flatMap<U>(_ transform: (Wrapped) throws -> U?) rethrows -> U?

func increment2(optional: Int?) -> Int? {
    return optional.map {
        $0 + 1
    }
}

// “为什么将这个函数命名为 map？它和运用于数组的 map 运算有什么共同点吗？我们有充分的理由将这两个函数都称为 map，但是现在我们暂时不会展开，之后在关于函子、适用函子与单子的章节中会再次讨论这个问题。”

// 再谈可选绑定
let x: Int? = 3
let y: Int? = nil
//let z: Int? = x + y
// “加法运算只支持 Int 值，而不支持我们这里的 Int? 值”
func add(_ optionalX: Int?, _ optionalY: Int?) -> Int? {
    if let x = optionalX {
        if let y = optionalY {
            return x + y
        }
    }
    return nil
}

// “除了层层嵌套，我们还可以同时绑定多个可选：”
func add2(_ optionalX: Int?, _ optionalY: Int?) -> Int? {
    if let x = optionalX, let y = optionalY {
        return x + y
    }
    return nil
}

// “若还想更简短，可以使用一个 guard 语句，当值缺失时提前退出”
func add3(_ optionalX: Int?, _ optionalY: Int?) -> Int? {
guard let x = optionalX, let y = optionalY else { return nil }
return x + y
}

let capitals = [
    "France": "Paris",
    "Spain": "Madrid",
    "The Netherlands": "Amsterdam",
    "Belgium": "Brussels"
]

func populationOfCapital(country: String) -> Int? {
    guard let capital = capitals[country], let population = cities[capital]
    else { return nil }
    return population * 1000
}


func add4(_ optionalX: Int?, _ optionalY: Int?) -> Int? {
    return optionalX.flatMap { x in
        optionalY.flatMap { y in
            return x + y
        }
    }
}

func populationOfCapital2(country: String) -> Int? {
    return capitals[country].flatMap { capital in
        cities[capital].flatMap { population in
            population * 1000
        }
    }
}
// “当前我们通过嵌套的方式调用 flatMap，取而代之，也可以通过链式调用来重写 populationOfCapital2，这样能使得代码结构更浅显易懂：”
func populationOfCapital3(country: String) -> Int? {
    return capitals[country].flatMap { capital in
        cities[capital]
    }.flatMap { population in
        population * 1000
    }
}

// “为什么使用可选值？”
// 安全
