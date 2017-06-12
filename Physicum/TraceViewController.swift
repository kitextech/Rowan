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

        let ball1 = BallDrawable(position: 20*e_z)
        let ball2 = BallDrawable(position: 15*e_z)
        let ball3 = BallDrawable(position: 10*e_z)
        let ball4 = BallDrawable(position: 5*e_z)
        let ball5 = BallDrawable(position: 0*e_z)
        let ball6 = BallDrawable(position: -5*e_z)
        let ball7 = BallDrawable(position: -10*e_z)
        let ball8 = BallDrawable(position: -15*e_z)
        let ball9 = BallDrawable(position: -20*e_z)
        let ball10 = BallDrawable(position: -25*e_z)

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

        let ballObject1 = Object(m: 1, r: ball1.position, v: -5*e_z, a: .zero)
        let ballObject2 = Object(m: 1, r: ball2.position, v: 0*e_z, a: .zero)
        let ballObject3 = Object(m: 1, r: ball3.position, v: 0*e_z, a: .zero)
        let ballObject4 = Object(m: 1, r: ball4.position, v: 0*e_z, a: .zero)
        let ballObject5 = Object(m: 1, r: ball5.position, v: 0*e_z, a: .zero)
        let ballObject6 = Object(m: 1, r: ball6.position, v: 0*e_z, a: .zero)
        let ballObject7 = Object(m: 1, r: ball7.position, v: 0*e_z, a: .zero)
        let ballObject8 = Object(m: 1, r: ball8.position, v: 0*e_z, a: .zero)
        let ballObject9 = Object(m: 1, r: ball9.position, v: 0*e_z, a: .zero)
        let ballObject10 = Object(m: 1, r: ball10.position, v: 0*e_z, a: .zero)

        newton.add(object: ballObject1, id: ball1.id)
        newton.add(object: ballObject2, id: ball2.id)
        newton.add(object: ballObject3, id: ball3.id)
        newton.add(object: ballObject4, id: ball4.id)
        newton.add(object: ballObject5, id: ball5.id)
        newton.add(object: ballObject6, id: ball6.id)
        newton.add(object: ballObject7, id: ball7.id)
        newton.add(object: ballObject8, id: ball8.id)
        newton.add(object: ballObject9, id: ball9.id)
        newton.add(object: ballObject10, id: ball10.id)

        newton.add(mutualForce: spring, id0: ball1.id, id1: ball2.id)
        newton.add(mutualForce: spring, id0: ball2.id, id1: ball3.id)
        newton.add(mutualForce: spring, id0: ball3.id, id1: ball4.id)
        newton.add(mutualForce: spring, id0: ball4.id, id1: ball5.id)
        newton.add(mutualForce: spring, id0: ball5.id, id1: ball6.id)
        newton.add(mutualForce: spring, id0: ball6.id, id1: ball7.id)
        newton.add(mutualForce: spring, id0: ball7.id, id1: ball8.id)
        newton.add(mutualForce: spring, id0: ball8.id, id1: ball9.id)
        newton.add(mutualForce: spring, id0: ball9.id, id1: ball10.id)

//        newton.add(force: wind, id: ball.id)
//        newton.add(force: radial, id: ball1.id)

        traceView.add(SphereDrawable())
//        traceView.add(BallDrawable())

        startDisplayLink()
    }
    
    @IBAction func didPinch(_ sender: UIPinchGestureRecognizer) {
        traceView.zoom(by: 1 + 0.6*Scalar(sender.scale))
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
        newton.iterate(elapsed)
        for (id, object) in newton.objects {
            traceView.moveDrawable(id: id, pos: object.r)
        }
        traceView.setNeedsDisplay()
    }

    // invalidate display link if it's non-nil, then set to nil
    func stopDisplayLink() {
        displayLink?.invalidate()
        displayLink = nil
    }

}

