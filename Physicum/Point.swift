import Foundation

let π = Scalar(Double.pi)

extension NSPoint {
    init(phi: Scalar, r: Scalar) {
        self = r*NSPoint(x: cos(phi), y: sin(phi))
    }

    static func *(left: Scalar, right: NSPoint) -> NSPoint {
        return NSPoint(x: left*right.x, y: left*right.y)
    }

    static func •(left: NSPoint, right: NSPoint) -> Scalar {
        return  left.x*right.x + left.y*right.y
    }

    static func +(left: NSPoint, right: NSPoint) -> NSPoint {
        return NSPoint(x: left.x + right.x, y: left.y + right.y)
    }

    static func -(left: NSPoint, right: NSPoint) -> NSPoint {
        return NSPoint(x: left.x - right.x, y: left.y - right.y)
    }

    static prefix func -(point: NSPoint) -> NSPoint {
        return NSPoint(x: -point.x, y: -point.y)
    }

    public var norm: Scalar {
        return sqrt(x*x + y*y)
    }

    public var phi: Scalar {
        return atan2(y, x)
    }

    public var r: Scalar {
        return norm
    }

    public var normSquared: Scalar {
        return x*x + y*y
    }

    public var unit: NSPoint {
        return (1/norm)*self
    }

    public func angle(to point: NSPoint) -> Scalar {
        return acos(unit•point.unit)
    }

    public func signedAngle(to point: NSPoint) -> Scalar {
        let p = point.unit
        let q = unit

        let signed = asin(p.y*q.x - p.x*q.y)

        if angle(to: point) > π/2 {
            if signed > 0 {
                return π - signed
            }
            else {
                return -π - signed
            }
        }
        else {
            return signed
        }
    }

    public func rotated(by angle: Scalar) -> NSPoint {
        return self.applying(CGAffineTransform(rotationAngle: angle))
    }

    public func deCollapsed(on plane: (x: Vector, y: Vector)) -> Vector {
        return x*plane.x + y*plane.y
    }

    public func deCollapsed(along axis: Vector) -> Vector {
        if axis || e_z {
            return Vector(y, x, 0)
        }

        let bases = Plane(center: .origin, normal: axis).bases

        return deCollapsed(on: bases)
    }

    public func scaled(by factor: Scalar) -> NSPoint {
        return NSPoint(x: factor*x, y: factor*y)
    }

    public func absolute(in rect: NSRect) -> NSPoint {
        return NSPoint(x: rect.minX + rect.width*(0.5 + x), y: rect.minY + rect.height*(0.5 + y))
    }

    public func relative(in rect: NSRect) -> NSPoint {
        return NSPoint(x: (x - rect.minX)/rect.width - 0.5, y: (y - rect.minY)/rect.height - 0.5)
    }
}

extension NSRect {
    init(center: NSPoint, size: NSSize) {
        self = NSRect(origin: center - NSPoint(x: size.width/2, y: size.height/2), size: size)
    }
    
    public static var unit: NSRect {
        return NSRect(x: 0, y: 0, width: 1, height: 1)
    }
}
