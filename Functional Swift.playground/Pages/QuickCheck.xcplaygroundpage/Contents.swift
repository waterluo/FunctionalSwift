import Darwin
import CoreGraphics

protocol Smaller {
    func smaller() -> Self?
}

protocol Arbitrary: Smaller {
    static func arbitrary() -> Self
}

extension Int: Arbitrary {
    static func arbitrary() -> Int {
        return Int(arc4random())  // “这里只能生成正整数。事实上，一个完整实现的库也应能够生成负整数”
    }
    static func arbitrary(in range: CountableRange<Int>) -> Int {
        let diff = range.upperBound - range.lowerBound
        return range.lowerBound + (Int.arbitrary() % diff)
    }
}

Int.arbitrary()

extension UnicodeScalar: Arbitrary {
    func smaller() -> Unicode.Scalar? {
        .none
    }
    
    static func arbitrary() -> UnicodeScalar {
        return UnicodeScalar(Int.arbitrary(in: 65..<90))! // 生成随机字符
        // “注意，目前我们只随机生成大写字母：我们在这里限制了自身的原因是，是我们希望本书的输出内容可读性更高。在实际的生产库中，应该生成包含任意字符且更长的字符串：”
    }
}

extension String: Arbitrary {
    static func arbitrary() -> String {
        let randomLength = Int.arbitrary(in: 0..<40) // 随机生成0..<40的数
        let randomScalars = (0..<randomLength).map { _ in
            UnicodeScalar.arbitrary()
        } // “生成 randomLength 个随机字符，并将它们组合为一个字符串”
        return String(UnicodeScalarView(randomScalars))
    }
}

String.arbitrary()

let numberOfIterations = 10

func check1<A: Arbitrary>(_ message: String, _ property: (A) -> Bool) -> () {
    for _ in 0..<numberOfIterations {
        let value = A.arbitrary()
        guard property(value) else {
            print("\"\(message)\" doesn't hold: \(value)")
            return
        }
    }
    print("\"\(message)\" passed \(numberOfIterations) tests.")
}

extension CGSize {
    var area: CGFloat {
        return width * height
    }
}

extension CGSize: Arbitrary {
    func smaller() -> CGSize? {
        .zero
    }
    
    static func arbitrary() -> CGSize {
        return CGSize(width: .arbitrary(), height: .arbitrary())
    }
}

check1("Area should be at least 0") { (size: CGSize) in size.area >= 0 }

check1("Every string starts with Hello") { (s: String) in
    s.hasPrefix("Hello")
}



extension Int: Smaller {
    func smaller() -> Int? {
        self == 0 ? nil : self/2
    }
}

extension String: Smaller {
    var characters: [Character] {
        self.map { $0 }
    }
    
    func smaller() -> String? {
        isEmpty ? nil : String(characters.dropFirst())
    }
}

print(("hello".smaller())!)

func iterate<A>(while condition: (A) -> Bool, initial: A, next: (A) -> A?) -> A {
    guard let x = next(initial), condition(x) else {
        return initial
    }
    return iterate(while: condition, initial: x, next: next)
}

func check2<A: Arbitrary>(_ message: String, _ property: (A) -> Bool) -> () {
    for _ in 0..<numberOfIterations {
        let value = A.arbitrary()
        guard property(value) else {
            let smallerValue = iterate(while: { !property($0) }, initial: value) {
                $0.smaller()
            }
            print("\"\(message)\" doesn't hold: \(smallerValue)")
            return
        }
    }
    print("\"\(message)\" passed \(numberOfIterations) tests.")
}

// 快排
func qsort(_ input: [Int]) -> [Int] {
    var array = input
    if array.isEmpty { return [] }
    let pivot = array.removeFirst()
    let lesser = array.filter { $0 < pivot }
    let greater = array.filter { $0 >= pivot }
    let intermediate = qsort(lesser) + [pivot]
    return intermediate + qsort(greater)
}

extension Array: Smaller {
    func smaller() -> [Element]? {
        guard !isEmpty else { return nil }
        return Array(dropLast())
    }
}

extension Array where Element: Arbitrary {
    static func arbitrary() -> [Element] {
        let randomLength = Int.arbitrary(in: 0..<50)
        return (0..<randomLength).map { _ in .arbitrary() }
    }
}

//extension Array: Arbitrary where Element: Arbitrary {
//    static func arbitrary() -> [Element] {
//
//    }
//}

//
//check2("qsort should behave like sort") { (x: [Int]) in
//    return qsort(x) == x.sorted()
//}

struct ArbitraryInstance<T> {
    let arbitrary: () -> T
    let smaller: (T) -> T?
}

func checkHelper<A>(_ arbitraryInstance: ArbitraryInstance<A>,
                    _ property: (A) -> Bool, _ message: String) -> ()
{
    for _ in 0..<numberOfIterations {
    let value = arbitraryInstance.arbitrary()
    guard property(value) else {
        let smallerValue = iterate(while: { !property($0) },
                                   initial: value, next: arbitraryInstance.smaller)
        print("\"\(message)\" doesn't hold: \(smallerValue)")
        return
    }
}
    print("\"\(message)\" passed \(numberOfIterations) tests.")
}

func check<X: Arbitrary>(_ message: String, property: (X) -> Bool) -> () {
    let instance = ArbitraryInstance(arbitrary: X.arbitrary,
                                     smaller: { $0.smaller() })
    checkHelper(instance, property, message)
}

func check<X: Arbitrary>(_ message: String, _ property: ([X]) -> Bool) -> () {
    let instance = ArbitraryInstance(arbitrary: Array.arbitrary,
                                     smaller: { (x: [X]) in x.smaller() })
    checkHelper(instance, property, message)
}

check("qsort should behave like sort") { (x: [Int]) in
    return qsort(x) == x.sorted()
}


