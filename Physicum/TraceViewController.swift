//
//  ViewController.swift
//  Physicum
//
//  Created by Gustaf Kugelberg on 2017-06-07.
//  Copyright © 2017 Gustaf Kugelberg. All rights reserved.
//

import UIKit

class TraceViewController: UIViewController {
    @IBOutlet var traceView: TraceView!
    private let newton = Newton()
    private var displayLink: CADisplayLink?

    @IBOutlet weak var label0: UILabel!
    @IBOutlet weak var slider0: UISlider!
    @IBOutlet weak var slider1: UISlider!
    @IBOutlet weak var slider2: UISlider!

    private var debuIds = [UUID]()

    override func viewDidLoad() {
        super.viewDidLoad()

        func add(drawable: Drawable, m: Scalar, v: Vector = .zero, l: Vector = .zero) {
            traceView.add(drawable)
            let body = Body(id: drawable.id, m: m)
            let state = State(r: drawable.position, p: m*v, q: drawable.orientation, l: l)
            newton.add(body: body, state: state)
        }

        traceView.add(SphereDrawable())

        let link1 = BoxDrawable(at: 0*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link2 = BoxDrawable(at: 5*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link3 = BoxDrawable(at: 10*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link4 = BoxDrawable(at: 15*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link5 = BoxDrawable(at: 20*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link6 = BoxDrawable(at: 25*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link7 = BoxDrawable(at: 30*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link8 = BoxDrawable(at: 35*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link9 = BoxDrawable(at: 40*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link10 = BoxDrawable(at: 45*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link11 = BoxDrawable(at: 50*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link12 = BoxDrawable(at: 55*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link13 = BoxDrawable(at: 60*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link14 = BoxDrawable(at: 65*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link15 = BoxDrawable(at: 70*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link16 = BoxDrawable(at: 75*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link17 = BoxDrawable(at: 80*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link18 = BoxDrawable(at: 85*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link19 = BoxDrawable(at: 90*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
        let link20 = BoxDrawable(at: 95*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)

        let wing = KiteDrawable(at: 97.5*e_x - 30*e_z)

        debuIds.append(wing.id)

        let links: [Drawable] = [link1, link2, link3, link4, link5, link6, link7, link8, link9, link10, link11, link12, link13, link14, link15, link16, link17, link18, link19, link20, wing]

        add(drawable: link1, m: 100000)
        links.dropFirst().forEach { add(drawable: $0, m: 2) }
        add(drawable: wing, m: 50)

        let gravity: (State) -> Vector = { _ in 1*e_z }
        let gravityWing: (State) -> Vector = { _ in 50*e_z }

        func addUnary<S: Sequence>(to s: S, u: @escaping (State) -> Vector) where S.Element == Drawable {
            s.forEach { newton.add(force: (.zero, $0.id, u)) }
        }

        addUnary(to: links.dropFirst().dropLast(), u: gravity)
        newton.add(force: (2*e_z, wing.id, gravityWing))

        newton.add(force: (wing.motorPoints.0, wing.id, motor0))
        newton.add(force: (wing.motorPoints.1, wing.id, motor1))
        newton.add(force: (wing.motorPoints.2, wing.id, motor2))
        newton.add(force: (wing.motorPoints.3, wing.id, motor3))

        func addSpring(left: Drawable, right: Drawable, offset: (Scalar, Scalar) = (-0.5, 0.5)) {
            let dr = left.position - right.position
            newton.add(force: (offset.0*dr, left.id, right.id, spring(l: 0, plus: true)))
            newton.add(force: (offset.1*dr, right.id, left.id, spring(l: 0, plus: false)))
        }

        addSpring(left: link1, right: link2)
        addSpring(left: link2, right: link3)
        addSpring(left: link3, right: link4)
        addSpring(left: link4, right: link5)
        addSpring(left: link5, right: link6)
        addSpring(left: link6, right: link7)
        addSpring(left: link7, right: link8)
        addSpring(left: link8, right: link9)
        addSpring(left: link9, right: link10)
        addSpring(left: link10, right: link11)
        addSpring(left: link11, right: link12)
        addSpring(left: link12, right: link13)
        addSpring(left: link13, right: link14)
        addSpring(left: link14, right: link15)
        addSpring(left: link15, right: link16)
        addSpring(left: link16, right: link17)
        addSpring(left: link17, right: link18)
        addSpring(left: link18, right: link19)
        addSpring(left: link19, right: link20)
        addSpring(left: link20, right: wing)

        startDisplayLink()
    }

    let rho: Float = -20

    func motor0(x: State) -> Vector {
        return (-100 + rho*self.slider1.value + rho*self.slider2.value)*self.slider0.value*(e_z.rotated(x.q))
    }

    func motor1(x: State) -> Vector {
        return (-100 + rho*self.slider1.value - rho*self.slider2.value)*self.slider0.value*(e_z.rotated(x.q))
    }

    func motor2(x: State) -> Vector {
        return (-100 - rho*self.slider1.value + rho*self.slider2.value)*self.slider0.value*(e_z.rotated(x.q))
    }

    func motor3(x: State) -> Vector {
        return (-100 - rho*self.slider1.value - rho*self.slider2.value)*self.slider0.value*(e_z.rotated(x.q))
    }

    @IBAction func didPinch(_ sender: UIPinchGestureRecognizer) {
        traceView.zoom(by: Scalar(sender.scale))
        sender.scale = 1
    }

    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
        let delta = 1/500*sender.translation(in: view)
        traceView.rotate(by: (Scalar(delta.x), Scalar(delta.y)))
        sender.setTranslation(.zero, in: view)
    }

    // MARK: - displayLink

    private func startDisplayLink() {
//        let before = Date()
//        for _ in 0...1000 {
//            newton.step(h: 0.01)
//        }
//
//        print("that took \(Date().timeIntervalSince(before)) sec")
//        updatePhysics(0.01)

        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink?.add(to: .main, forMode: .commonModes)
    }

    @objc func step(link: CADisplayLink) {
        updatePhysics(link.targetTimestamp - link.timestamp)
    }

    private func updatePhysics(_ elapsed: TimeInterval) {
        for _ in 0..<2 {
            newton.step(h: 10*Scalar(elapsed))
        }

        for (id, state) in newton.states {
            traceView.moveDrawable(id: id, pos: state.r, ori: state.q)
        }

        func color(_ isAggregate: Bool, _ isTorque: Bool) -> UIColor {
            let base: UIColor = isTorque ? .orange : .blue
            return isAggregate ? base : base.withAlphaComponent(0.5)
        }

        traceView.debugDrawables = newton.debugEvaluation(debuIds).map { data in
            ArrowDrawable(at: data.r, vector: data.vec, color: color(data.isAggregate, data.isTorque))
        }

        traceView.setNeedsDisplay()
    }

    // invalidate display link if it's non-nil, then set to nil
    func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

}

