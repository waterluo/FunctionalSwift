// 函子 (Functor)、适用函子 (Applicative Functor) 和单子 (Monad)

/// 函子 (Functor)
/*
extension Array {
    func map<R>(transform: (Element) -> R) -> [R]
}

extension Optional {
    func map<R>(transform: (Wrapped) -> R) -> R?
}

extension Parser {
    func map<T>(_ transform: @escaping (Result) -> T) -> Parser<T>
}
*/

// 支持 map 运算的类型构造体 —— 比如可选值或数组 —— 有时候也被称作函子 (Functor)。

struct Position {
var x: Double
var y: Double
}

//typealias Region = (Position) -> Bool”

struct Region<T> {
    let value: (Position) -> T
}

extension Region {
    func map<U>(transform: @escaping (T) -> U) -> Region<U> {
        return Region<U> { pos in transform(self.value(pos)) }
    }
}

/// 适用函子
//“如果能支持以下运算，该函子就是一个适用函子：
// func pure<A>(_ value: A) -> F<A>
// func <*><A, B>(f: F<A -> B>, x: F<A>) -> F<B>”


precedencegroup Apply { associativity: left }
infix operator <*>: Apply

func pure<A>(_ value: A) -> Region<A> {
    return Region { pos in value }
}

func <*><A, B>(regionF: Region<(A) -> B>, regionX: Region<A>) -> Region<B> {
    return Region { pos in regionF.value(pos)(regionX.value(pos)) }
}

func everywhere() -> Region<Bool> {
    return pure(true)
}

func invert(region: Region<Bool>) -> Region<Bool> {
    return pure(!) <*> region
}

func intersection(region1: Region<Bool>, region2: Region<Bool>)
-> Region<Bool>
{
    let and: (Bool, Bool) -> Bool = { $0 && $1 }
    return pure(curry(and)) <*> region1 <*> region2
}

// 单子

// 如果一个类型构造体 F 定义了下面两个函数，它就是一个单子 (Monad)：
// func pure<A>(_ value: A) -> F<A>
// func flatMap<A, B>(x: F<A>)(_ f: (A) -> F<B>) -> F<B>


