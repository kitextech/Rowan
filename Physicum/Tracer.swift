//
//  Tracer.swift
//  Physicum
//
//  Created by Gustaf Kugelberg on 2017-07-02.
//  Copyright © 2017 Gustaf Kugelberg. All rights reserved.
//

import UIKit

public class Tracer {
    public var projectionAxis = e_y
    public var scaleFactor: Scalar = 70
    public var bounds: CGRect = .unit

    public func project(_ vectorSize: CGSize) -> CGSize {
        return vectorSize
            .scaled(by: 1/scaleFactor)
            .absolute(in: bounds)
    }

    public func pointify(_ vector: Vector) -> CGPoint {
        return vector
            .collapsed(along: projectionAxis)
            .scaled(by: 1/scaleFactor)
            .absolute(in: bounds)
    }

    public func vectorify(_ point: CGPoint) -> Vector {
        return point
            .relative(in: bounds)
            .scaled(by: scaleFactor)
            .deCollapsed(along: projectionAxis)
    }
}

public protocol Drawable {
    var id: UUID { get }
    var occluded: Bool { get }
    var color: UIColor { get }
    var lines: [Line] { get }
    var spheres: [Sphere] { get }

    var orientation: Quaternion { set get }
    var position: Vector { set get }
}

public struct VectorDrawable: Drawable {
    public var vector: Vector { return vectorClosure() }

    public let start: Vector
    public var end: Vector { return start + vector }
    private let vectorClosure: () -> Vector

    public init(_ color: UIColor = .black, at start: Vector, vectorClosure: @escaping () -> Vector) {
        self.color = color
        self.start = start
        self.vectorClosure = vectorClosure
    }

    // MARK - Drawable

    public let id = UUID()

    public let occluded = false
    public let color: UIColor

    public var lines: [Line] {
        return [Line(start: start, end: end)]
    }

    public let spheres: [Sphere] = []

    public var orientation: Quaternion = .id

    public var position: Vector = .origin
}

public struct KiteDrawable: Drawable {
    private let span: Scalar = 20*1.2
    private let length: Scalar = 20*1
    private let height: Scalar = 20*0.6

    private let tailProportion: Scalar = 0.8
    private let stabiliserProportion: Scalar = 0.8
    private let stabiliserSize: Scalar = 0.4
    private let rudderSize: Scalar = 0.3

    private let sideWingPlacement: Scalar = 0.5

    // MARK: - Drawable

    public let id = UUID()

    public let occluded = false

    public let color = UIColor.white

    public let lines: [Line]

    public let spheres: [Sphere]

    public var orientation: Quaternion = .id

    public var position: Vector = .origin

    // Output
    public let motorPoints: (Vector, Vector, Vector, Vector)

    public init(at position: Vector = .origin) {
        self.position = position

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

        lines = [wing, rightSideWing, leftSideWing, body, stabiliser, rudder]
        motorPoints = (rightSideWing.start, rightSideWing.end, leftSideWing.start, leftSideWing.end)
        spheres = [rightSideWing.start, rightSideWing.end, leftSideWing.start, leftSideWing.end, .origin]
            .map { Sphere(center: $0, radius: 1) }
    }
}

public struct SphereDrawable: Drawable {
    // Parameters

    var radius: Scalar = 50

    // MARK: - Drawable

    public let id = UUID()

    public var occluded = true

    public let color = UIColor.lightGray

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
    public let id = UUID()

    public let occluded = false

    public let color: UIColor

    public var lines: [Line] = []

    public let spheres: [Sphere] = [Sphere(center: .zero, radius: 20)]

    public var orientation: Quaternion = .id

    public var position: Vector

    public init(position: Vector = .origin, color: UIColor = .white) {
        self.position = position
        self.color = color
    }
}

public class BoxDrawable: Drawable {
    public let id = UUID()

    public let occluded = false

    public let color: UIColor

    public let lineWidth: Scalar = 3

    public let lines: [Line]

    public let spheres: [Sphere] = []

    public var orientation: Quaternion = .id

    public var position: Vector

    public init(at position: Vector = .origin, dx: Scalar, dy: Scalar, dz: Scalar, color: UIColor = .white) {
        self.position = position
        self.color = color

        let corner = (0..<8).map { i in 0.5*Vector(i > 3 ? dx : -dx, i % 4 > 1 ? dy : -dy, i % 2 > 0 ? dz : -dz) }
        lines = [(0, 1), (1, 3), (3, 2), (2, 0), (4, 5), (5, 7), (7, 6), (6, 4), (0, 4), (1, 5), (2, 6), (3, 7)]
            .map { Line(start: corner[$0.0], end: corner[$0.1]) }
    }
}

public class ArrowDrawable: Drawable {
    // MARK: - Parameters

    public var vector: Vector

    public let id = UUID()

    public let occluded = false

    public let color: UIColor

    public var lines: [Line] { return [Line(start: .origin, end: vector)] }

    public var spheres: [Sphere] { return [Sphere(center: vector, radius: 1)] }

    public var orientation: Quaternion = .id

    public var position: Vector

    public init(at position: Vector = .origin, vector: Vector = .zero, color: UIColor = .black) {
        self.position = position
        self.vector = vector
        self.color = color
    }
}

public struct CircleDrawable: Drawable {
    // MARK: - Parameters

    let radius: Scalar
    let plane: Plane

    // MARK: - Private Parameters

    private let points = 30

    // MARK: - Drawable

    public let id = UUID()

    public let occluded = true

    public let color = UIColor.red

    public var lines: [Line] {
        func makeVector(phi: Scalar) -> Vector {
            return plane.center + radius*(sin(phi)*plane.bases.0 + cos(phi)*plane.bases.1)
        }

        let vectors = (0...points)
            .map { 2*π*Scalar($0)/Scalar(points) }
            .map(makeVector)
        
        // Why doesn't Line.init work anymore?
        return zip(vectors.dropLast(), vectors.dropFirst()).map(Line.create)
    }
    
    public let spheres: [Sphere] = []
    
    public var orientation: Quaternion = .id
    
    public var position: Vector = .origin
}
