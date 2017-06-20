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

    override func viewDidLoad() {
        super.viewDidLoad()

        let ball1 = BallDrawable(position: 0*e_x - 30*e_z)
        let ball2 = BallDrawable(position: 5*e_x - 30*e_z)
        let ball3 = BallDrawable(position: 10*e_x - 30*e_z)
        let ball4 = BallDrawable(position: 15*e_x - 30*e_z)
        let ball5 = BallDrawable(position: 20*e_x - 30*e_z)
        let ball6 = BallDrawable(position: 25*e_x - 30*e_z)
        let ball7 = BallDrawable(position: 30*e_x - 30*e_z)
        let ball8 = BallDrawable(position: 35*e_x - 30*e_z)
        let ball9 = BallDrawable(position: 40*e_x - 30*e_z)
        let ball10 = BallDrawable(position: 45*e_x - 30*e_z)

        traceView.add(ball1)
        traceView.add(ball2)
        traceView.add(ball3)
        traceView.add(ball4)
        traceView.add(ball5)
        traceView.add(ball6)
        traceView.add(ball7)
        traceView.add(ball8)
        traceView.add(ball9)
        traceView.add(ball10)

        let ballBody1 = Body(r: ball1.position)
        let ballBody2 = Body(m: 10, r: ball2.position)
        let ballBody3 = Body(m: 10, r: ball3.position)
        let ballBody4 = Body(m: 10, r: ball4.position)
        let ballBody5 = Body(m: 10, r: ball5.position)
        let ballBody6 = Body(m: 10, r: ball6.position)
        let ballBody7 = Body(m: 10, r: ball7.position)
        let ballBody8 = Body(m: 10, r: ball8.position)
        let ballBody9 = Body(m: 10, r: ball9.position)
        let ballBody10 = Body(m: 10, r: ball10.position) //, v: 0*e_x + 5*e_z)

        newton.add(body: ballBody1, id: ball1.id)
        newton.add(body: ballBody2, id: ball2.id)
        newton.add(body: ballBody3, id: ball3.id)
        newton.add(body: ballBody4, id: ball4.id)
        newton.add(body: ballBody5, id: ball5.id)
        newton.add(body: ballBody6, id: ball6.id)
        newton.add(body: ballBody7, id: ball7.id)
        newton.add(body: ballBody8, id: ball8.id)
        newton.add(body: ballBody9, id: ball9.id)
        newton.add(body: ballBody10, id: ball10.id)

        newton.add(force: spring, id0: ball1.id, id1: ball2.id)
        newton.add(force: spring, id0: ball2.id, id1: ball3.id)
        newton.add(force: spring, id0: ball3.id, id1: ball4.id)
        newton.add(force: spring, id0: ball4.id, id1: ball5.id)
        newton.add(force: spring, id0: ball5.id, id1: ball6.id)
        newton.add(force: spring, id0: ball6.id, id1: ball7.id)
        newton.add(force: spring, id0: ball7.id, id1: ball8.id)
        newton.add(force: spring, id0: ball8.id, id1: ball9.id)
        newton.add(force: spring, id0: ball9.id, id1: ball10.id)

        newton.add(force: gravity, id: ball1.id)
        newton.add(force: gravity, id: ball2.id)
        newton.add(force: gravity, id: ball3.id)
        newton.add(force: gravity, id: ball4.id)
        newton.add(force: gravity, id: ball5.id)
        newton.add(force: gravity, id: ball6.id)
        newton.add(force: gravity, id: ball7.id)
        newton.add(force: gravity, id: ball8.id)
        newton.add(force: gravity, id: ball9.id)
        newton.add(force: gravity, id: ball10.id)

//        newton.add(force: wind, id: ball.id)
//        newton.add(force: radial, id: ball1.id)

        traceView.add(SphereDrawable())
//        traceView.add(BallDrawable())

        startDisplayLink()
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
        stopDisplayLink()
        displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink?.add(to: .main, forMode: .commonModes)
    }

    @objc func step(link: CADisplayLink) {
        updatePhysics(6*(link.targetTimestamp - link.timestamp))
    }

    private func updatePhysics(_ elapsed: TimeInterval) {
//        newton.iterate(elapsed)
        for (id, body) in newton.bodies {
            traceView.moveDrawable(id: id, pos: body.r)
        }
        traceView.setNeedsDisplay()
    }

    // invalidate display link if it's non-nil, then set to nil
    func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

}

