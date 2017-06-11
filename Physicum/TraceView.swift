import AppKit
import SceneKit

public typealias Scalar = SCNFloat
public typealias Vector = SCNVector3
public typealias Quaternion = SCNQuaternion

public class TraceView: NSView {

    private let newton = Newton()

    private let tracer = Tracer()
    private var drawables: [Drawable] = [SphereDrawable(), BallDrawable()]

    // MARK: - Parameters

    public var phi: Scalar = 0
    public var theta: Scalar = 0
    public var sphereRadius: Scalar = 50

    override public func scrollWheel(with event: NSEvent) {
        phi += event.deltaX/20
        theta -= event.deltaY/20
        tracer.projectionAxis = Vector(phi: phi, theta: theta, r: 1)
        setNeedsDisplay(bounds)
    }

    override public func magnify(with event: NSEvent) {
        tracer.scaleFactor /= 1 + 0.6*event.magnification
        setNeedsDisplay(bounds)
    }

    override public func viewDidEndLiveResize() {
        super.viewDidEndLiveResize()
        tracer.bounds = bounds
        setNeedsDisplay(bounds)
    }

    override public func draw(_ dirtyRect: NSRect) {
        super.draw(bounds)

        newton.iterate()

        newton.objects.forEach { _, obj in
            drawables[0].position += e_x
            Swift.print(drawables[1].position.x)
        }

        NSColor.blue.setStroke()
        NSBezierPath(rect: bounds).stroke()

        drawables.forEach(draw)
    }

    // Methods

    public func add(_ drawable: Drawable) {
        drawables.append(drawable)
        setNeedsDisplay(bounds)
    }

    private var displayLink: CVDisplayLink?
    private var currentTime = 0.0

    public func start() {
        let b = newton.add(Object(m: 10, r: 100*e_x, v: .zero, a: .zero))
        newton.add(id: b, f: gravity)
    }

    // Drawing Helper Methods

    private func draw(_ drawable: Drawable) {
        drawable.color.set()

        let lines = drawable.lines
            .map { $0.rotated(drawable.orientation) }
            .map { $0.translated(drawable.position) }

        let occlusionPlane = Plane(center: .origin, normal: tracer.projectionAxis)

        linesPath(lines: drawable.occluded ? lines.flatMap(occlusionPlane.occlude) : lines).stroke()

        drawable.spheres
            .map { $0.translated(drawable.position) }
            .map(spherePath)
            .forEach { $0.fill() }
    }

    private func linesPath(lines: [Line]) -> NSBezierPath {
        let p = NSBezierPath()
        p.lineWidth = 2

        for line in lines {
            p.move(to: tracer.pointify(line.start))
            p.line(to: tracer.pointify(line.end))
        }

        return p
    }

    private func spherePath(sphere: Sphere) -> NSBezierPath {
        let rect = NSRect(center: tracer.pointify(sphere.center), size: NSSize(width: sphere.radius, height: sphere.radius))
        return NSBezierPath(ovalIn: rect)
    }
}

public protocol Drawable {
    var occluded: Bool { get }
    var color: NSColor { get }
    var lines: [Line] { get }
    var spheres: [Sphere] { get }

    var orientation: Quaternion { set get }
    var position: Vector { set get }
}

//protocol VectorLike {
//    var x: Scalar { get set }
//    var y: Scalar { get set }
//    var z: Scalar { get set }
//}

public struct VectorDrawable: Drawable {
    public var vector: Vector { return vectorClosure() }

    public let start: Vector
    public var end: Vector { return start + vector }
    private let vectorClosure: (Void) -> Vector

    public init(_ color: NSColor = .black, at start: Vector, vectorClosure: @escaping (Void) -> Vector) {
        self.color = color
        self.start = start
        self.vectorClosure = vectorClosure
    }

    // MARK - Drawable

    public let occluded = false
    public let color: NSColor

    public var lines: [Line] {
        return [Line(start: start, end: end)]
    }

    public let spheres: [Sphere] = []

    public var orientation: Quaternion = .id

    public var position: Vector = .origin
}

public struct KiteDrawable: Drawable {
    let span: Scalar = 20*1.2
    let length: Scalar = 20*1
    let height: Scalar = 20*0.6

    private let tailProportion: Scalar = 0.8
    private let stabiliserProportion: Scalar = 0.8
    private let stabiliserSize: Scalar = 0.4
    private let rudderSize: Scalar = 0.3

    private let sideWingPlacement: Scalar = 0.5

    // MARK: - Drawable

    public let occluded = false

    public let color = NSColor.black

    public var lines: [Line] {
        let halfSpan = span/2
        let wing = halfSpan*Line(start: -e_y, end: e_y)

        let verticalWing = 1/2*Line(start: -e_x, end: e_x)
        let basicSideWing = height*verticalWing
        let rightSideWing = basicSideWing + sideWingPlacement*halfSpan*e_y
        let leftSideWing = basicSideWing - sideWingPlacement*halfSpan*e_y

        let nose = -(1 - tailProportion)*length*e_z
        let tail = nose + length*e_z
        let body = Line(start: nose, end: tail)

        let stabiliser = stabiliserSize*wing + stabiliserProportion*tail

        let rudder = rudderSize*span*verticalWing + tail - 0.4*rudderSize*span*e_x

        return [wing, rightSideWing, leftSideWing, body, stabiliser, rudder]
    }

    public let spheres = [Sphere(center: .origin, radius: 5)]

    public var orientation: Quaternion = .id

    public var position: Vector = .origin
}

public struct SphereDrawable: Drawable {
    // Parameters

    var radius: Scalar = 50

    // MARK: - Drawable

    public var occluded = true

    public let color = NSColor.darkGray

    public var lines: [Line] {
        let longitudes = 20
        let latitudes = 10

        let longDelta = 2*π/Scalar(longitudes)
        let latDelta = (π/2)/Scalar(latitudes)

        var lines = [Line]()
        for i in 0...longitudes {
            let phi = -π/2 + Scalar(i)*longDelta

            for j in 0..<latitudes {
                let theta = π/2 + Scalar(j)*latDelta
                let start = Vector(phi: phi, theta: theta, r: radius)
                let end = Vector(phi: phi, theta: theta + latDelta, r: radius)
                lines.append(Line(start: start, end: end))
            }
        }

        for j in 0..<latitudes {
            let theta = π/2 + Scalar(j)*latDelta
            for i in 0...longitudes {
                let phi = -π/2 + Scalar(i)*longDelta
                let start = Vector(phi: phi, theta: theta, r: radius)
                let end = Vector(phi: phi + longDelta, theta: theta, r: radius)
                lines.append(Line(start: start, end: end))
            }
        }

        return lines
    }

    public let spheres: [Sphere] = []

    public var orientation: Quaternion = .id

    public var position: Vector = .origin

    // Helper methods
}

public struct BallDrawable: Drawable {
    public let occluded = false

    public let color = NSColor.blue

    public var lines: [Line] = []

    public let spheres: [Sphere] = [Sphere(center: .zero, radius: 20)]

    public var orientation: Quaternion = .id

    public var position: Vector = .origin
}

public struct CircleDrawable: Drawable {
    // MARK: - Parameters

    let radius: Scalar
    let plane: Plane

    // MARK: - Private Parameters

    private let points = 30

    // MARK: - Drawable

    public let occluded = true

    public let color = NSColor.red

    public var lines: [Line] {
        let vectors = (0...points)
            .map { 2*π*Scalar($0)/Scalar(points) }
            .map { phi -> Vector in plane.center + radius*(sin(phi)*plane.bases.0 + cos(phi)*plane.bases.1) }

        return zip(vectors.dropLast(), vectors.dropFirst()).map(Line.init)
    }

    public let spheres: [Sphere] = []

    public var orientation: Quaternion = .id

    public var position: Vector = .origin
    
    public func update() {
        
    }
}

public class Tracer {
    public var projectionAxis = -e_z
    public var scaleFactor: Scalar = 70
    public var bounds: NSRect = .unit

    public func pointify(_ vector: Vector) -> NSPoint {
        return vector
            .collapsed(along: projectionAxis)
            .scaled(by: 1/scaleFactor)
            .absolute(in: bounds)
    }

    public func vectorify(_ point: NSPoint) -> Vector {
        return point
            .relative(in: bounds)
            .scaled(by: scaleFactor)
            .deCollapsed(along: projectionAxis)
    }

}
