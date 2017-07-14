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
    @IBOutlet weak var slider3: UISlider!

    private var debuIds = [UUID]()

    private var kite: Kite!

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

        let links: [Drawable] = [link1, link2, link3, link4, link5, link6, link7, link8, link9, link10, link11, link12, link13, link14, link15, link16, link17, link18, link19, link20, wing]

        add(drawable: link1, m: 100000)
        links.dropFirst().forEach { add(drawable: $0, m: 2) }
        add(drawable: wing, m: 50)

        kite = Kite(id: wing.id, configs: wing.motorPoints.map { ($0, 100, 10*($0.x*$0.y > 0 ? +1 : -1)) as MotorConfig })
        kite.motorForces.forEach(newton.add)
        kite.motorTorques.forEach(newton.add)

        debuIds.append(wing.id)

        let gravity: (State) -> Vector = { _ in 1*e_z }
        let gravityWing: (State) -> Vector = { _ in 50*e_z }

        func addUnary<S: Sequence>(to s: S, u: @escaping (State) -> Vector) where S.Element == Drawable {
            s.forEach { newton.add(force: (.zero, $0.id, u)) }
        }

        addUnary(to: links.dropFirst().dropLast(), u: gravity)
        newton.add(force: (2*e_z, wing.id, gravityWing))

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

    // MARK: - User Actions

    @IBAction func didSlide0(_ sender: UISlider) {
        kite.overallThrust = sender.value

        func str(_ index: Int) -> String {
            let confa = kite.configs[index].a
            return "(\(confa.x), \(confa.y)) -> \(kite.thrust(index))"
        }

        print("\(str(0)) : \(str(1)) : \(str(2)) : \(str(3))")
    }

    @IBAction func didSlide1(_ sender: UISlider) {
        kite.pitchThrustDelta = sender.value
    }

    @IBAction func didSlide2(_ sender: UISlider) {
        kite.rollThrustDelta = sender.value
    }

    @IBAction func didSlide3(_ sender: UISlider) {
        kite.yawThrustDelta = sender.value
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

typealias MotorConfig = (a: Vector, maxThrust: Scalar, maxTorque: Scalar)

class Kite {
    // Temporary Public Variables
    public var pitchThrustDelta: Scalar = 0
    public var rollThrustDelta: Scalar = 0
    public var yawThrustDelta: Scalar = 0
    public var overallThrust: Scalar = 0

    // Private Variables
    private let id: UUID
    public let configs: [MotorConfig]

    public var motorForces: [UnaryForce] {
        return configs.enumerated().map { splatMe in let (index, config) = splatMe
            return (config.a, id, { (-config.maxThrust*self.thrust(index)*e_z).rotated($0.q) } )
        }
    }

    public var motorTorques: [UnaryTorque] {
        return configs.enumerated().map { splatMe in let (index, config) = splatMe
            return (id, { (config.maxTorque*self.thrust(index)*e_z).rotated($0.q) } )
        }
    }

    init(id: UUID, configs: [MotorConfig]) {
        self.id = id
        self.configs = configs
    }

    public func thrust(_ index: Int) -> Scalar {
        let factor: Scalar = 4
        let a = configs[index].a
        let pitchAdjustment = (factor + (a.x > 0 ? +1 : -1)*pitchThrustDelta)/factor
        let rollAdjustment = (factor + (a.y > 0 ? +1 : -1)*rollThrustDelta)/factor
        let yawAdjustment = (factor + (a.x*a.y > 0 ? +1 : -1)*yawThrustDelta)/factor

        return overallThrust*pitchAdjustment*rollAdjustment*yawAdjustment
    }
}


