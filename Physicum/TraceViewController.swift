//
//  ViewController.swift
//  Physicum
//
//  Created by Gustaf Kugelberg on 2017-06-07.
//  Copyright © 2017 Gustaf Kugelberg. All rights reserved.
//

import UIKit

class TraceViewController: UIViewController {
    @IBOutlet weak var traceView: TraceView!
    @IBOutlet weak var logView: LogView!
    @IBOutlet weak var xyControl: XYControlView!

    private let newton = Newton()
    private var displayLink: CADisplayLink?

    @IBOutlet weak var sliderStack: UIStackView!
    private var sliders: [UISlider] = []
    @IBOutlet weak var labelStack: UIStackView!
    private var labels: [UILabel] = []

    private var debugIds = [UUID]()

    private var kite: Kite!
    private var wind: Vector = .zero
    private var gravity: Vector = 9.8*e_z

    private var box = BoxDrawable(dx: 4, dy: 4, dz: 20)

    // typealias UnaryForce = (a: Vector, i: UUID, f: (State) -> Vector)

    private func dragForce() -> UnaryForce {
        fatalError()
    }

    private func gravityForce() -> UnaryForce {
        fatalError()
    }

    private func add(drawable: Drawable, m: Scalar, v: Vector = .zero, l: Vector = .zero) {
        traceView.add(drawable)
        let body = Body(id: drawable.id, m: m)
        let state = State(r: drawable.position, p: m*v, q: drawable.orientation, l: l)
        newton.add(body: body, state: state)
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // Set up world

        traceView.add(box)

//        let link1 = BoxDrawable(at: 0*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link2 = BoxDrawable(at: 5*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link3 = BoxDrawable(at: 10*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link4 = BoxDrawable(at: 15*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link5 = BoxDrawable(at: 20*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link6 = BoxDrawable(at: 25*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link7 = BoxDrawable(at: 30*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link8 = BoxDrawable(at: 35*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link9 = BoxDrawable(at: 40*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link10 = BoxDrawable(at: 45*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link11 = BoxDrawable(at: 50*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link12 = BoxDrawable(at: 55*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link13 = BoxDrawable(at: 60*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link14 = BoxDrawable(at: 65*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link15 = BoxDrawable(at: 70*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link16 = BoxDrawable(at: 75*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link17 = BoxDrawable(at: 80*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link18 = BoxDrawable(at: 85*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link19 = BoxDrawable(at: 90*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)
//        let link20 = BoxDrawable(at: 95*e_x - 30*e_z, dx: 5, dy: 1, dz: 1)

//        let wing = KiteDrawable(at: 97.5*e_x - 30*e_z)

//        let links: [Drawable] = [link1, link2, link3, link4, link5, link6, link7, link8, link9, link10, link11, link12, link13, link14, link15, link16, link17, link18, link19, link20, wing]
//
//        add(drawable: link1, m: 100000)
//        links.dropFirst().forEach { add(drawable: $0, m: 2) }

        let wing = KiteDrawable(at: .origin)

        add(drawable: wing, m: 50)

        let configs = wing.motorPoints.map { ($0, 20, 2*($0.x*$0.y > 0 ? +1 : -1)) as MotorConfig }
        let fc = AttitudeFlightController(configs: configs)
        kite = Kite(id: wing.id, fc: fc)
        kite.motorForces.forEach(newton.add)
        kite.motorTorques.forEach(newton.add)

        debugIds.append(wing.id)
        traceView.trackedId = wing.id

        let gravity: (State) -> Vector = { _ in 1*e_z }
        let gravityWing: (State) -> Vector = { _ in 50*e_z }

        func addUnary<S: Sequence>(to s: S, u: @escaping (State) -> Vector) where S.Element == Drawable {
            s.forEach { newton.add(force: (.zero, $0.id, u)) }
        }

//        addUnary(to: links.dropFirst().dropLast(), u: gravity)
        newton.add(force: (.origin, wing.id, gravityWing))

//        func addSpring(left: Drawable, right: Drawable, offset: (Scalar, Scalar) = (-0.5, 0.5)) {
//            let dr = left.position - right.position
//            newton.add(force: (offset.0*dr, left.id, right.id, spring(l: 0, plus: true)))
//            newton.add(force: (offset.1*dr, right.id, left.id, spring(l: 0, plus: false)))
//        }
//
//        addSpring(left: link1, right: link2)
//        addSpring(left: link2, right: link3)
//        addSpring(left: link3, right: link4)
//        addSpring(left: link4, right: link5)
//        addSpring(left: link5, right: link6)
//        addSpring(left: link6, right: link7)
//        addSpring(left: link7, right: link8)
//        addSpring(left: link8, right: link9)
//        addSpring(left: link9, right: link10)
//        addSpring(left: link10, right: link11)
//        addSpring(left: link11, right: link12)
//        addSpring(left: link12, right: link13)
//        addSpring(left: link13, right: link14)
//        addSpring(left: link14, right: link15)
//        addSpring(left: link15, right: link16)
//        addSpring(left: link16, right: link17)
//        addSpring(left: link17, right: link18)
//        addSpring(left: link18, right: link19)
//        addSpring(left: link19, right: link20)
//        addSpring(left: link20, right: wing)

        setupSliders()
        startDisplayLink()
    }

    // MARK: - Physics and Drawing

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

    private func setupSliders() {
        sliderStack.removeAll()
        labelStack.removeAll()

        sliders = kite.fc.parameters.map { parameter in
            let slider = UISlider()
            slider.minimumValue = parameter.min
            slider.maximumValue = parameter.max
            slider.value = parameter.default
            slider.addTarget(self, action: #selector(didSlide), for: .valueChanged)
            sliderStack.addArrangedSubview(slider)

            return slider
        }

        labels = kite.fc.parameters.map { parameter in
            let label = UILabel()
            label.textColor = .white
            label.font = UIFont.systemFont(ofSize: 12)
            label.text = parameter.name
            labelStack.addArrangedSubview(label)

            return label
        }

        didSlide()
    }

    private func resetSliders() {
        zip(sliders, kite.fc.parameters).forEach { splatMe in let (slider, parameter) = splatMe
            slider.value = parameter.default
        }
        didSlide()
    }

    @objc func step(link: CADisplayLink) {
        logView.data = kite.fc.log
        updatePhysics(1*(link.targetTimestamp - link.timestamp))
        kite.fc.state = newton.states[kite.id]!

        box.position = kite.fc.state.r
        box.orientation = kite.fc.attitudeSetPoint ?? .id
        debugDraw()

        traceView.setNeedsDisplay()
    }

    private func updatePhysics(_ elapsed: TimeInterval) {
        for _ in 0..<5 {
            newton.step(h: 2*Scalar(elapsed))
        }

        for (id, state) in newton.states {
            traceView.moveDrawable(id: id, pos: state.r, ori: state.q)
        }
    }

    private func debugDraw() {
        let forceDrawables: [ArrowDrawable] = newton.debugEvaluation(debugIds).map { data in
            let color = (data.isTorque ? UIColor.purple : UIColor.blue).withAlphaComponent(data.isAggregate ? 1 : 0.5)
            return ArrowDrawable(at: data.r, vector: 0.2*data.vec, color: color)
        }

        let fcDrawables = kite.fc.vectorLog.map { data in
            ArrowDrawable(at: data.pos, vector: 10*data.value, color: data.color)
        }

        traceView.debugDrawables = forceDrawables + fcDrawables
    }

    private func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

    // MARK: - User Actions

    @IBAction func didChangeXY(_ sender: XYControlView) {
        let axis = Vector(sender.value.x, sender.value.y, 0)
        let norm = axis.norm
        let orientation = norm > 0 ? Quaternion(axis: axis/norm, angle: norm) : .id
        kite.fc.attitudeSetPoint = orientation
    }

    @objc func didSlide() {
        kite.fc.parameterValues = sliders.map { $0.value }
//
//        let rotX = Quaternion(axis: e_x, angle: sliders[0].value)
//        let rotY = Quaternion(axis: e_y, angle: sliders[1].value)
//        let rotZ = Quaternion(axis: e_z, angle: sliders[2].value)
//        kite.fc.attitudeSetPoint = rotX*rotY*rotZ
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

    @IBAction func didTapButton(_ sender: UIButton) {
        switch sender.tag {
        case 0:
            newton.states[kite.id] = .id
        case 1:
            resetSliders()
        case 2:
            traceView.drawFloor = !traceView.drawFloor
        case 3:
            traceView.drawHeight = !traceView.drawHeight
        case 4:
            logView.isHidden = !logView.isHidden
        case 5:
            sliderStack.isHidden = !sliderStack.isHidden
            labelStack.isHidden = sliderStack.isHidden
        default:
            fatalError()
        }
    }

    // MARK: - Helpers

}

typealias MotorConfig = (a: Vector, maxThrust: Scalar, maxTorque: Scalar)

class Kite {
    // Public Variables
    public let id: UUID
    public let motorForces: [UnaryForce]
    public let motorTorques: [UnaryTorque]
    public let fc: FlightController

    // Initialisation

    init(id: UUID, fc: FlightController) {
        self.id = id

        self.motorForces = fc.configs.enumerated().map { splatMe in let (index, config) = splatMe
            return (config.a, id, { (-config.maxThrust*fc.thrusts[index]*e_z).rotated($0.q) } )
        }

        self.motorTorques = fc.configs.enumerated().map { splatMe in let (index, config) = splatMe
            return (id, { (config.maxTorque*fc.thrusts[index]*e_z).rotated($0.q) } )
        }

        self.fc = fc
    }
}

class XYControlView: UIControl {
    public var value: CGPoint = .zero

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        value = 2*touches.first!.location(in: self).relative(in: bounds)
        sendActions(for: .valueChanged)
        setNeedsDisplay()
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        value = .zero
        sendActions(for: [.valueChanged, .editingDidEnd])
        setNeedsDisplay()
    }

    override func draw(_ rect: CGRect) {
        UIColor.brown.setFill()
        UIBezierPath(ovalIn: CGRect(center: (0.5*value).absolute(in: bounds), size: CGSize(side: 50))).fill()
    }
}

extension UIStackView {
    public func removeAll() {
        let views = arrangedSubviews
        for view in views {
            removeArrangedSubview(view)
            view.removeFromSuperview()
        }
    }
}
