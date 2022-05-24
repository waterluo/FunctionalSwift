import Foundation
import CoreImage
import UIKit
import PlaygroundSupport

// 该函数接受一个图像作为参数并返回一个新的图像
typealias Filter = (CIImage)-> CIImage

// 高斯模糊滤镜
func blur(radius: Double) -> Filter {
    return { image in
        let parameters: [String: Any] = [
            kCIInputRadiusKey: radius,
            kCIInputImageKey: image
        ]
        guard let filter = CIFilter(name: "CIGaussianBlur",
                                    parameters: parameters)
        else { fatalError() }
        guard let outputImage = filter.outputImage
        else { fatalError() }
        return outputImage
    }
}
// “这个例子仅仅只是对 Core Image 中一个已经存在的滤镜进行的简单封装。我们可以反复使用相同的模式来创建自己的滤镜函数。”

// 颜色叠层
// “现在让我们来定义一个能够在图像上覆盖纯色叠层的滤镜。Core Image 默认不包含这样一个滤镜，但是我们完全可以用已经存在的滤镜来组成它。
// 我们将使用的两个基础组件：颜色生成滤镜 (CIConstantColorGenerator) 和图像覆盖合成滤镜 (CISourceOverCompositing)。
// 首先让我们来定义一个生成固定颜色的滤镜：
func generate(color: UIColor) -> Filter {
    return { _ in
        let parameters = [kCIInputColorKey: CIColor(cgColor: color.cgColor)]
        guard let filter = CIFilter(name: "CIConstantColorGenerator",
                                    parameters: parameters)
        else { fatalError() }
        guard let outputImage = filter.outputImage
        else { fatalError() }
        return outputImage
    }
}

// 我们将要定义合成滤镜
//
func compositeSourceOver(overlay: CIImage) -> Filter {
    return { image in
        let parameters = [
            kCIInputBackgroundImageKey: image,
            kCIInputImageKey: overlay
        ]
        guard let filter = CIFilter(name: "CISourceOverCompositing",
                                    parameters: parameters)
        else { fatalError() }
        guard let outputImage = filter.outputImage
        else { fatalError() }
        return outputImage.cropped(to: image.extent)
    }
}

// 我们通过结合两个滤镜来创建颜色叠层滤镜：
func overlay(color: UIColor) -> Filter {
    return { image in
        let overlay = generate(color: color)(image).cropped(to: image.extent) // “将输出图像剪裁为与输入图像一致的尺寸”
        return compositeSourceOver(overlay: overlay)(image) // image -> overlay
    }
}

// 组合滤镜
// 首先将图像模糊，然后再覆盖上一层红色叠层
let url = URL(string: "http://via.placeholder.com/500x500")
let image = CIImage(contentsOf: url!)!

let radius = 5.0
let color = UIColor.red.withAlphaComponent(0.2)
let blurredImage = blur(radius: radius)(image)

let overlaidImage = overlay(color: color)(image)

// 复合函数
// “我们可以将上面代码里两个调用滤镜的表达式简单合为一体”
let result = overlay(color: color)(blur(radius: radius)(image)) // blur(image) -> overlay(color)

// “由于括号错综复杂，这些代码很快失去了可读性。更好的解决方式是构建一个可以将滤镜合二为一的函数：”

func compose(filter filter1: @escaping Filter,
             with filter2: @escaping Filter) -> Filter
{
    return { image in filter2(filter1(image)) }
}

let blurAndOverlay = compose(filter: blur(radius: radius),
                             with: overlay(color: color))
let result1 = blurAndOverlay(image)

infix operator >>>
func >>>(filter1: @escaping Filter, filter2: @escaping Filter) -> Filter {
    return { image in filter2(filter1(image)) }
}

// “现在我们可以使用 >>> 运算符达到与之前使用 compose(filter:with:) 相同的目的：”
let blurAndOverlay2 = blur(radius: radius) >>> overlay(color: color)
let result2 = blurAndOverlay2(image)

// 柯里化
func add1(_ x: Int, _ y: Int) -> Int {
    return x + y
}

func add2(_ x: Int) -> ((Int) -> Int) {
    return { y in x + y }
}

func add3(_ x: Int) -> (Int) -> Int {
    return { y in x + y }
}
add1(1, 2)
add2(1)(2)
// add1 和 add2 的例子向我们展示了如何将一个接受多参数的函数变换为一系列只接受单个参数的函数，这个过程被称为柯里化 (Currying)，它得名于逻辑学家 Haskell Curry；
// 我们将 add2 称为 add1 的柯里化版本。


