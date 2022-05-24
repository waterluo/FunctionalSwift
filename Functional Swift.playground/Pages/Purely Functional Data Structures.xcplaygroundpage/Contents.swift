// “纯函数式数据结构”
// “二叉搜索树 (Binary Search Trees)”
// “利用树型结构编写一个高效的无序集合库”

indirect enum BinarySearchTree<Element: Comparable> {
    case leaf // 空的
    case node(BinarySearchTree<Element>,
              Element,
              BinarySearchTree<Element>)
    // “一个带有三个关联值的节点 node，关联值分别是左子树，储存在该节点的值和右子树。”
}

let leaf: BinarySearchTree<Int> = .leaf // leaf 树是空的
let five: BinarySearchTree<Int> = .node(leaf, 5, leaf) // five 树在节点上存了值 5，但两棵子树都为空

extension BinarySearchTree {
    init() {
        self = .leaf
    }
    init(_ value: Element) {
        self = .node(.leaf, value, .leaf)
    }
}

extension BinarySearchTree {
    var count: Int {
        switch self {
        case .leaf:
            return 0
        case let .node(left, _, right):
            return 1 + left.count + right.count
        }
    }
}

extension BinarySearchTree {
    var elements: [Element] {
        switch self {
        case .leaf:
            return []
        case let .node(left, x, right):
            return left.elements + [x] + right.elements
        }
    }
}

extension BinarySearchTree {
    func reduce<A>(leaf leafF: A, node nodeF: (A, Element, A) -> A) -> A {
        switch self {
        case .leaf:
            return leafF
        case let .node(left, x, right):
            return nodeF(left.reduce(leaf: leafF, node: nodeF),
                         x,
                         right.reduce(leaf: leafF, node: nodeF))
        }
    }
}

extension BinarySearchTree {
    var elementsR: [Element] {
        return reduce(leaf: []) { $0 + [$1] + $2 }
    }
    var countR: Int {
        return reduce(leaf: 0) { 1 + $0 + $2 }
    }
}

extension BinarySearchTree {
    var isEmpty: Bool {
        if case .leaf = self {
            return true
        }
        return false
    }
}

// “如果为这个结构加上一个二叉搜索树的限制，问题就会迎刃而解。
// 如果一棵 (非空) 树符合以下几点，就可以被视为一棵二叉搜索树：”
/*
 
 1. 所有储存在左子树的值都小于其根节点的值
 2. 所有储存在右子树的值都大于其根节点的值
 3. 其左右子树都是二叉搜索树
 */

extension BinarySearchTree {
    var isBST: Bool {
        switch self {
        case .leaf:
            return true
        case let .node(left, x, right):
            return left.elements.all { y in y < x }
            && right.elements.all { y in y > x }
            && left.isBST
            && right.isBST
        }
    }
}

extension Sequence{
    func all(predicate: (Iterator.Element) -> Bool) -> Bool {
        for x in self where !predicate(x) {
            return false
        }
        return true
    }
}
extension BinarySearchTree {
    func contains(_ x: Element) -> Bool {
        switch self {
        case .leaf:
            return false
        case let .node(_, y, _) where x == y:
            return true
        case let .node(left, y, _) where x < y:
            return left.contains(x)
        case let .node(_, y, right) where x > y:
            return right.contains(x)
        default:
            fatalError("The impossible occurred")
        }
    }
}

extension BinarySearchTree {
    mutating func insert(_ x: Element) {
        switch self {
        case .leaf:
            self = BinarySearchTree(x)
        case .node(var left, let y, var right):
            if x < y { left.insert(x) }
            if x > y { right.insert(x) }
            self = .node(left, y, right)
        }
    }
}

// 在执行插入操作的情况下，新的树是在旧树的分支之外构建的，分支本身并不会被修改。
// 可持久化的数据结构 (persistent data structures)
let myTree: BinarySearchTree<Int> = BinarySearchTree()
var copied = myTree
copied.insert(5)
myTree.elements // []
copied.elements // [5]


// 在最坏的情况下，二叉搜索树中的 insert 与 contains 仍然是线性的 —— 毕竟，总会出现像是所有的左子树都为空这种非常不平衡的树。
// 一些更为巧妙的实现方案，比如
// 2-3树
// AVL树
// 红黑树
// 可以通过使每棵树都保持合理平衡来避免这种情况
// 另外，我们并没有编写 delete 操作，这个操作也需要对树进行反复地平衡。关于这些内容，各种文献中有大量被充分论证过的经典方案 —— 所以重申一下，这里的例子只是为了说明如何利用递归枚举，而并不会构建一个完整的库。

/// “基于字典树的自动补全”
extension String {
    func complete(history: [String]) -> [String] {
        return history.filter { $0.hasPrefix(self) }
    }
}

// “遗憾地是，这个函数依旧不是很高效。在历史记录很多，或是前缀很长的情况下，运算会慢得离谱。”

// “按照之前的经验，我们可以将历史记录排序为一个数组，并对其使用某种二叉搜索来提高性能。”

// 字典树 (Tries)，也被称作数字搜索树 (digital search trees)，是一种特定类型的有序树，通常被用于搜索由一连串字符组成的字符串。
// 不同于将一组字符串储存在一棵二叉搜索树中，字典树把构成这些字符串的字符逐个分解开来，储存在了一个更高效的数据结构中，

struct Trie<Element: Hashable> {
    let isElement: Bool
    let children: [Element: Trie<Element>]
}
extension Trie {
    init() {
        isElement = false
        children = [:]
    }
}

extension Trie {
    var elements: [[Element]] {
        var result: [[Element]] = isElement ? [[]] : []
        for (key, value) in children {
            result += value.elements.map { [key] + $0 }
        }
        return result
    }
}

// 我们已经使用了数组来表示键组，虽然我们将字典树定义为了一个 (递归的) 结构体，但数组却并不能递归。
// 一个能够被遍历的数组还是很有用的，为数组添加下文中的拓展可以便捷的实现这个功能:
extension Array {
    var slice: ArraySlice<Element> {
        return ArraySlice(self)
    }
}
// “属性 decomposed 会检查一个数组切片是否为空。如果为空，就返回一个 nil；反之，则会返回一个多元组，这个多元组包含该切片的第一个元素，以及去掉第一个元素之后的切片。我们可以通过重复调用 decomposed 递归地遍历一个数组，直到返回 nil，而此时数组将为空。”
extension ArraySlice {
    var decomposed: (Element, ArraySlice<Element>)? {
        return isEmpty ? nil : (self[startIndex], self.dropFirst())
    }
}
// “我们之所以为 ArraySlice 而不是 Array 定义 decomposed，是因为性能上的原因。
// Array 中的 dropFirst 方法的复杂度是 O(n)，而 ArraySlice 中 dropFirst 的复杂度则为 O(1)。
// 因此，此处的 decomposed 也只具有 O(1) 的复杂度。”

// “比如，我们可以抛开 for 循环或是 reduce 函数，而使用 decompose 函数递归地对一个数组的元素求和：”
func sum(_ integers: ArraySlice<Int>) -> Int {
    guard let (head, tail) = integers.decomposed else { return 0 }
    return head + sum(tail)
}

sum([1,2,3,4,5].slice)

// “给定一个由一些 Element 组成的键组，遍历一棵字典树，来逐一确定对应的键是否储存在树中：”

extension Trie {
    func lookup(key: ArraySlice<Element>) -> Bool {
        guard let (head, tail) = key.decomposed else { return isElement }
        guard let subtrie = children[head] else { return false }
        return subtrie.lookup(key: tail)
    }
}

extension Trie {
    func lookup(key: ArraySlice<Element>) -> Trie<Element>? {
        guard let (head, tail) = key.decomposed else { return self }
        guard let remainder = children[head] else { return nil }
        return remainder.lookup(key: tail)
    }
}
// “该函数与 lookup 唯一的不同在于它不再返回一个 isElement 的布尔值，而是将整棵子树作为返回值，其中包含了所有以参数作为前缀的元素。”

extension Trie {
    func complete(key: ArraySlice<Element>) -> [[Element]] {
        return lookup(key: key)?.elements ?? []
    }
}

extension Trie {
    init(_ key: ArraySlice<Element>) {
        if let (head, tail) = key.decomposed {
            let children = [head: Trie(tail)]
            self = Trie(isElement: false, children: children)
        } else {
            self = Trie(isElement: true, children: [:])
        }
    }
}

extension Trie {
    func inserting(_ key: ArraySlice<Element>) -> Trie<Element> {
        guard let (head, tail) = key.decomposed else {
            return Trie(isElement: true, children: children)
        }
        var newChildren = children
        if let nextTrie = children[head] {
            newChildren[head] = nextTrie.inserting(tail)
        } else {
            newChildren[head] = Trie(tail)
        }
        return Trie(isElement: isElement, children: newChildren)
    }
}



/// “字符串字典树”

extension String {
    var characters: [Character] {
        self.map { $0 }
    }
}

extension Trie {
    static func build(words: [String]) -> Trie<Character> {
        let emptyTrie = Trie<Character>()
        return words.reduce(emptyTrie) { trie, word in
            trie.inserting(Array(word.characters).slice)
        }
    }
}

extension String {
    func complete(_ knownWords: Trie<Character>) -> [String] {
        let chars = Array(characters).slice
        let completed = knownWords.complete(key: chars)
        return completed.map { chars in
            self + String(chars)
        }
    }
}

let contents = ["cat", "car", "cart", "dog"]

let trieOfWords = Trie<Character>.build(words: contents)
"car".complete(trieOfWords)

// Sequence 协议

// “本章中列举了两个例子，使用枚举和结构体编写了高性能的不可变数据类型。”

// “案例研究：遍历二叉树”

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

extension BinarySearchTree: Sequence {
    func makeIterator() -> AnyIterator<Element> {
        switch self {
        case .leaf: return AnyIterator { return nil }
        case let .node(l, element, r):
            return l.makeIterator() + CollectionOfOne(element).makeIterator() +
            r.makeIterator()
        }
    }
}

// 如果树中没有元素,我们会返回一个空迭代器。
// 如果树有一个节点，则使用生成器的拼接运算符，将两个递归调用与该根节点储存的值拼接起来，作为结果返回。
// CollectionOfOne 是标准库中的一个类型。
// 注意我们使用了延迟化方式来定义 +。
// 如果我们用前一种 (非延迟的) 方式来定义 +，makeIterator 方法就需要先访问整棵树，再返回结果了。
