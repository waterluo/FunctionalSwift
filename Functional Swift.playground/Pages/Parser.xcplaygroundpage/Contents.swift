import Foundation
// 直接操作字符串的性能其实会很差。
// 所以在选择输入和剩余部分的类型时，我们会使用 String.CharacterView 而不是字符串。
// 别小看这点微不足道的改动，它会使性能得到大幅提升
// 现在swift建议直接使用string

struct Parser<Result> {
    
    let parse: (String) -> (Result, String)?
    
    func run(_ string: String) -> (Result, String)? {
        guard let (result, remainder) = parse(string) else { return nil }
        return (result, String(remainder))
    }
}

func character(matching condition: @escaping (Character) -> Bool) -> Parser<Character> {
    Parser { input in
        guard let char = input.first, condition(char) else { return nil }
        return (char, String(input.dropFirst()))
    }
    
}

let one = character{ $0 == "1" }

if let (result, string) = one.parse("123") {
    print(result, string)
}

one.run("123")

extension CharacterSet {
    func contains(_ c: Character) -> Bool {
        let scalars = String(c).unicodeScalars
        guard scalars.count == 1 else { return false }
        return contains(scalars.first!)
    }
}

let digit = character { CharacterSet.decimalDigits.contains($0) }
digit.run("456")

// 组合解析器

// “组合算子 many”

extension Parser {
    var many: Parser<[Result]> {
        return Parser<[Result]> { input in
            var result: [Result] = []
            var remainder = input
            while let (element, newRemainder) = self.parse(remainder) {
                result.append(element)
                remainder = newRemainder
            }
            return (result, remainder)
        }
    }
}

digit.many.run("123") // Optional((["1", "2", "3"], ""))
extension Parser {
    func map<T>(_ transform: @escaping (Result) -> T) -> Parser<T> {
        return Parser<T> { input in
            guard let (result, remainder) = self.parse(input) else { return nil }
            return (transform(result), remainder)
        }
    }
}

let integer = digit.many.map { Int(String($0))! }
integer.run("123")// Optional((123, ""))
integer.run("123abc") // Optional((123, "abc"))”

// 顺序解析
// “引入一个顺序组合算子 followed(by:)”

extension Parser {
    func followed<A>(by other: Parser<A>) -> Parser<(Result, A)> {
        return Parser<(Result, A)> { input in
            guard let (result1, remainder1) = self.parse(input) else { return nil }
            guard let (result2, remainder2) = other.parse(remainder1)
            else { return nil }
            return ((result1, result2), remainder2)
        }
    }
}

let multiplication = integer
.followed(by: character { $0 == "*" })
.followed(by: integer)
multiplication.run("2*3") // Optional((((2, "*"), 3), ""))

// “由于越多次的调用 followed(by:) 会导致越深层级的多元组嵌套，上述的解析结果看起来实在复杂了些。
// 我们会在稍后针对这种情况做一些改进，不过先让我们使用之前定义的 map 方法把这个乘法表达式的结果真正计算出来吧：
let multiplication2 = multiplication.map { $0.0 * $1 }
multiplication2.run("2*3") // Optional((6, ""))

// 改进顺序解析
func curriedMultiply(_ x: Int) -> (Character) -> (Int) -> Int {
    return { op in
        return { y in
            return x * y
        }
    }
}
curriedMultiply(2)("*")(3) // 6

// 用于将参数个数确定的非柯里化函数转化为柯里化版本。比如，对于双参函数来说，curry 可以这样定义：
func curry<A, B, C>(_ f: @escaping (A, B) -> C) -> (A) -> (B) -> C {
    return { a in { b in f(a, b) } }
}

let p1 = integer.map(curriedMultiply)

let p2 = p1.followed(by: character { $0 == "*" })

let p3 = p2.map { f, op in f(op) }

let p4 = p3.followed(by: integer)
let p5 = p4.map { f, y in f(y) }
// “p5 的解析结果类型是 Int 了”

p5.run("2*3") // Optional((6, ""))

let multiplication3 =
integer.map(curriedMultiply)
.followed(by: character { $0 == "*" }).map { f, op in f(op) }
.followed(by: integer).map { f, y in f(y) }

func <*><A, B>(lhs: Parser<(A) -> B>, rhs: Parser<A>) -> Parser<B> {
    return lhs.followed(by: rhs).map { f, x in f(x) }
}

// “为了使这个运算符能够投入使用，我们还需要将其指定为一个中缀运算符，并指定它的运算方向与优先级：
precedencegroup SequencePrecedence {
    associativity: left
    higherThan: AdditionPrecedence
}
infix operator <*>: SequencePrecedence

let multiplication4 =
integer.map(curriedMultiply) <*> character { $0 == "*" } <*> integer

infix operator <^>: SequencePrecedence
func <^><A, B>(lhs: @escaping (A) -> B, rhs: Parser<A>) -> Parser<B> {
    return rhs.map(lhs)
}
// “现在我们可以这样来编写一个乘法算式的解析器了：”
let multiplication5 = curriedMultiply <^> integer <*> character { $0 == "*" } <*> integer

// multiply(integer, character { $0 == "*" }, integer)

// 另一种版本的顺序解析

infix operator *>: SequencePrecedence
func *><A, B>(lhs: Parser<A>, rhs: Parser<B>) -> Parser<B> {
return curry({ _, y in y }) <^> lhs <*> rhs
}

infix operator <*: SequencePrecedence
func <*<A, B>(lhs: Parser<A>, rhs: Parser<B>) -> Parser<A> {
return curry({ x, _ in x }) <^> lhs <*> rhs
}

// 选择解析

extension Parser {
    func or(_ other: Parser<Result>) -> Parser<Result> {
        return Parser<Result> { input in
            return self.parse(input) ?? other.parse(input)
        }
    }
}
let star = character { $0 == "*" }
let plus = character { $0 == "+" }
let starOrPlus = star.or(plus)
starOrPlus.run("+") // Optional(("+", ""))

//
infix operator <|>
func <|><A>(lhs: Parser<A>, rhs: Parser<A>) -> Parser<A> {
    return lhs.or(rhs)
}

(star <|> plus).run("+") // Optional(("+", ""))

// “一次或更多次解析”
extension Parser {
    var many1: Parser<[Result]> {
        return { x in { manyX in [x] + manyX } } <^> self <*> self.many
    }
}

// “编写一版非柯里化的函数，然后使用 curry 将其转化为柯里化版本”
extension Parser {
    var many2: Parser<[Result]> {
        return curry({ [$0] + $1 }) <^> self <*> self.many
    }
}

// 可选
extension Parser {
    var optional: Parser<Result?> {
        return Parser<Result?> { input in
            guard let (result, remainder) = self.parse(input) else { return (nil, input) }
            return (result, remainder)
        }
    }
}

// 解析算术表达式

let multiplication6 = curry({ $0 * ($1 ?? 1) }) <^>
integer <*> (character { $0 == "*" } *> integer).optional

//let division = curry({ $0 / ($1 ?? 1) }) <^>
//multiplication <*> (character { $0 == "/" } *> multiplication).optional

//let addition = curry({ $0 + ($1 ?? 0) }) <^>
//division <*> (character { $0 == "+" } *> division).optional

//let minus = curry({ $0 - ($1 ?? 0) }) <^>
//addition <*> (character { $0 == "-" } *> addition).optional

//let expression = minus

//expression.run("2*3+4*6/2-10") // Optional((8, ""))

// “更 Swift 化的解析器类型”

struct Parser2<Result> {
    let parse: (inout String) -> Result?
}

extension Parser2 {
    var many: Parser2<[Result]> {
        return Parser2<[Result]> { input in
            var result: [Result] = []
            while let element = self.parse(&input) {
                result.append(element)
            }
            return result
        }
    }
}

extension Parser2 {
    func or(_ other: Parser2<Result>) -> Parser2<Result> {
        return Parser2<Result> { input in
            let original = input
            if let result = self.parse(&input) { return result }
            input = original // reset input
            return other.parse(&input)
        }
    }
}
