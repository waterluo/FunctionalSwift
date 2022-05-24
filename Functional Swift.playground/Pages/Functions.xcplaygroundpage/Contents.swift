import UIKit

typealias Distance = Double

struct Position {
    var x: Double
    var y: Double
}

extension Position {
    func within(range: Distance) -> Bool {
        return sqrt(x * x + y * y) <= range
    }
}

struct Ship {
    var position: Position
    var firingRange: Distance
    var unsafeRange: Distance
}

extension Ship {
    func canEngage(ship target: Ship) -> Bool {
        let dx = target.position.x - position.x
        let dy = target.position.y - position.y
        let targetDistance = sqrt(dx * dx + dy * dy)
        return targetDistance <= firingRange
    }
}

extension Ship {
    func canSafelyEngage(ship target: Ship) -> Bool {
        let dx = target.position.x - position.x
        let dy = target.position.y - position.y
        let targetDistance = sqrt(dx * dx + dy * dy)
        return targetDistance <= firingRange && targetDistance > unsafeRange
    }
}

extension Ship {
    func canSafelyEngage(ship target: Ship, friendly: Ship) -> Bool {
        let dx = target.position.x - position.x
        let dy = target.position.y - position.y
        let targetDistance = sqrt(dx * dx + dy * dy)
        let friendlyDx = friendly.position.x - target.position.x
        let friendlyDy = friendly.position.y - target.position.y
        let friendlyDistance = sqrt(friendlyDx * friendlyDx +
                                    friendlyDy * friendlyDy)
        return targetDistance <= firingRange
        && targetDistance > unsafeRange
        && (friendlyDistance > unsafeRange)
    }
}

extension Position {
    func minus(_ p: Position) -> Position {
        return Position(x: x - p.x, y: y - p.y)
    }
    var length: Double {
        return sqrt(x * x + y * y)
    }
}

extension Ship {
    func canSafelyEngage2(ship target: Ship, friendly: Ship) -> Bool {
        let targetDistance = target.position.minus(position).length
        let friendlyDistance = friendly.position.minus(target.position).length
        return targetDistance <= firingRange
        && targetDistance > unsafeRange
        && (friendlyDistance > unsafeRange)
    }
}
//
//func pointInRange(point: Position) -> Bool {
//    // 方法的具体实现
//}

typealias Region = (Position) -> Bool

// 在 Swift 中函数是一等值！我们有意识地选择了 Region 作为这个类型的名字，而非 CheckInRegion 或 RegionBlock 这种字里行间暗示着它们代表一种函数类型的名字。
// 函数式编程的核心理念就是函数是值，它和结构体、整型或是布尔型没有什么区别 —— 对函数使用另外一套命名规则会违背这一理念。

func circle(radius: Distance) -> Region {
    return { point in point.length <= radius }
}

func circle2(radius: Distance, center: Position) -> Region {
    return { point in point.minus(center).length <= radius }
}

func shift(_ region: @escaping Region, by offset: Position) -> Region {
    return { point in region(point.minus(offset)) }
}

// 一个圆心为 (5, 5) 半径为 10 的圆
let shifted = shift(circle(radius: 10), by: Position(x: 5, y: 5))

func invert(_ region: @escaping Region) -> Region {
    return { point in !region(point) }
}

// 交集和并集
func intersect(_ region: @escaping Region, with other: @escaping Region)
-> Region {
    return { point in region(point) && other(point) }
}
func union(_ region: @escaping Region, with other: @escaping Region)
-> Region {
    return { point in region(point) || other(point) }
}

func subtract(_ region: @escaping Region, from original: @escaping Region)
-> Region {
    return intersect(original, with: invert(region))
}

// 这个例子告诉我们，在 Swift 中计算和传递函数的方式与整型或布尔型没有任何不同。
// 这让我们能够写出一些基础的图形组件 (比如圆)，进而能以这些组件为基础，来构建一系列函数。每个函数都能修改或是合并区域，并以此创建新的区域。
// 比起写复杂的函数来解决某个具体的问题，现在我们完全可以通过将一些小型函数装配起来，广泛地解决各种各样的问题。

extension Ship {
    func canSafelyEngage1(ship target: Ship, friendly: Ship) -> Bool {
        let rangeRegion = subtract(circle(radius: unsafeRange),
                                   from: circle(radius: firingRange))
        let firingRegion = shift(rangeRegion, by: position)
        let friendlyRegion = shift(circle(radius: unsafeRange),
                                   by: friendly.position)
        let resultRegion = subtract(friendlyRegion, from: firingRegion)
        return resultRegion(target.position)
    }
}


