// 迭代器 Iterators
import Foundation

struct ReverseIndexIterator: IteratorProtocol {
    var index: Int
    
    init<T>(array: [T]) {
        index = array.endIndex - 1
    }
    
    mutating func next() -> Int? {
        guard index >= 0 else {
            return nil
        }
        defer {
            index -= 1
        }
        return index
    }
    
}

// “使用 ReverseIndexIterator 来倒序地遍历数组：”

let letters = ["A", "B", "C"]
print(letters.endIndex) // 3

var iterator = ReverseIndexIterator(array: letters)

while let i = iterator.next() {
    print("Element \(i) of the array is \(letters[i])")
}

struct PowerIterator: IteratorProtocol {
    var power: NSDecimalNumber = 1
    mutating func next() -> NSDecimalNumber? {
        power = power.multiplying(by: 2)
        return power
    }
}

extension PowerIterator {
    mutating func find(where predicate: (NSDecimalNumber) -> Bool)
    -> NSDecimalNumber? {
        while let x = next() {
            if predicate(x) {
                return x
            }
        }
        return nil
    }
}

// “我们可以使用 find 方法来计算二的幂值中大于 1000 的最小值：”
var powerIterator = PowerIterator()
powerIterator.find { $0.intValue > 1000 }

// “下面的迭代器会生成一组字符串，与某个文件中以行为单位的内容相对应”
struct FileLinesIterator: IteratorProtocol {
    let lines: [String]
    var currentLine: Int = 0
    init(filename: String) throws {
        let contents: String = try String(contentsOfFile: filename)
        lines = contents.components(separatedBy: .newlines)
    }
    mutating func next() -> String? {
        guard currentLine < lines.endIndex else { return nil }
        defer { currentLine += 1 }
        return lines[currentLine]
    }
}

extension IteratorProtocol {
    mutating func find(predicate: (Element) -> Bool) -> Element? {
        while let x = next() {
            if predicate(x) {
                return x
            }
        }
        return nil
    }
}

// “它可以用参数中的 limit 值来限制参数迭代器所生成的结果个数”
struct LimitIterator<I: IteratorProtocol>: IteratorProtocol {
    var limit = 0
    var iterator: I
    init(limit: Int, iterator: I) {
        self.limit = limit
        self.iterator = iterator
    }
    mutating func next() -> I.Element? {
        guard limit > 0 else { return nil }
        limit -= 1
        return iterator.next()
    }
}

extension Int {
    func countDown() -> AnyIterator<Int> {
        var i = self - 1
        return AnyIterator {
            guard i >= 0 else { return nil }
            defer { i -= 1 }
            return i
        }
    }
}

// “我们可以拼接两个基础元素类型相同的迭代器”

func +<I: IteratorProtocol, J: IteratorProtocol>(first: I, second: J)
-> AnyIterator<I.Element> where I.Element == J.Element
{
    var i = first
    var j = second
    return AnyIterator { i.next() ?? j.next() }
}
// “返回的迭代器会先读取 first 迭代器的所有元素；在该迭代器被耗尽之后，则会从 second 迭代器中生成元素。如果两个迭代器都返回 nil，该合成迭代器也会返回 nil。”

// “经过延迟化处理的版本会返回完全相同的结果，可如果只需要迭代器的部分结果，下面的版本会更高效：
func +<I: IteratorProtocol, J: IteratorProtocol>(
    first: I, second: @escaping @autoclosure () -> J)
-> AnyIterator<I.Element> where I.Element == J.Element
{
    var one = first
    var other: J? = nil
    return AnyIterator {
        if other != nil {
            return other!.next()
        } else if let result = one.next() {
            return result
        } else {
            other = second()
            return other!.next()
        }
    }
}

// 序列
// “迭代器为 Swift 另一个协议提供了基础类型，这个协议就是序列”
// “迭代器提供了一个“单次触发”的机制以反复地计算出下一个元素。
// 这种机制不支持返查或重新生成已经生成过的元素，我们想要做到这个的话就只能再创建一个新的迭代器。”

/*
protocol Sequence {
associatedtype Iterator: IteratorProtocol
func makeIterator() -> Iterator
// ...
}
*/

// “每一个序列都有一个关联的迭代器类型和一个创建新迭代器的方法。”

// “使用 ReverseIndexIterator 定义一个序列，用于生成某个数组的一系列倒序序列值”

struct ReverseArrayIndices<T>: Sequence {
    let array: [T]
    init(array: [T]) {
        self.array = array
    }
    
    func makeIterator() -> ReverseIndexIterator {
        return ReverseIndexIterator(array: array)
    }
}

var array = ["one", "two", "three"]

let reverseSequence = ReverseArrayIndices(array: array)

var reverseIterator = reverseSequence.makeIterator()

while let i = reverseIterator.next() {
    print("Index \(i) is \(array[i])")
}

for i in ReverseArrayIndices(array: array) {
    print("Index \(i) is \(array[i])")
}

// “不单单是数组，序列也具有标准的 map 和 filter 方法”
/*
public protocol Sequence {
    public func map<T>(
        _ transform: (Iterator.Element) throws -> T)
    rethrows -> [T]
    public func filter(
        _ isIncluded: (Iterator.Element) throws -> Bool)
    rethrows -> [Iterator.Element]
}
*/

// 想倒序生成数组中的元素，我们可以使用 map 来映射 ReverseArrayIndices：
let reverseElements = ReverseArrayIndices(array: array).map { array[$0] }
for x in reverseElements {
    print("Element is \(x)")
}

// “Sequence 协议中有一个内建的方法 reversed()，就会返回一个新的数组”

// 延迟化序列
(1...10).filter { $0 % 3 == 0 }.map { $0 * $0 }

var result: [Int] = []
for element in 1...10 {
    if element % 3 == 0 {
        result.append(element * element)
    }
}

// “利用 for 循环编写出的命令式版本会更为复杂。而我们一旦开始添加新的操作，代码会很快失控。”

// 函数式版本则非常浅显：给定一个数组，过滤，然后映射。'

// 不过命令式版本还是有一个好处的：执行起来更快。

// 这里我们还是可以进行一些优化。通过使用 LazySequence，我们可以在链式操作的同时，一次性计算出应用了所有操作之后的结果。
// 通过这种方法，每个元素的 filter 与 map 操作也可以被合并为一步：

let tmp = (1...10)

let lazyResult = tmp.lazy.filter { $0 % 3 == 0 }.map { $0 * $0 }

Array(lazyResult) // [9, 36, 81]

// “案例研究：遍历二叉树”
// “案例研究：优化 QuickCheck 的范围收缩”
protocol Smaller {
    func smaller() -> AnyIterator<Self>
}

extension Array {
    func smaller() -> AnyIterator<[Element]> {
        var i = 0
        return AnyIterator {
            guard i < self.endIndex else { return nil }
            var result = self
            result.remove(at: i)
            i += 1
            return result
        }
    }
}

Array([1, 2, 3].smaller())
