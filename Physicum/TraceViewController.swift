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

        var ball = BallDrawable()
        ball.position = Vector(0, 0, -25)
        traceView.add(ball)

        let ballObject = Object(m: 10, r: ball.position, v: 10*e_y, a: .zero)
        newton.add(object: ballObject, id: ball.id)
//        newton.add(force: gravity, id: ball.id)
        newton.add(force: radial, id: ball.id)

        traceView.add(SphereDrawable())
        traceView.add(BallDrawable())

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

//        startTime = CACurrentMediaTime()

        displayLink = CADisplayLink(target: self, selector: #selector(step))
        displayLink?.add(to: .main, forMode: .commonModes)
    }

    @objc func step(link: CADisplayLink) {
//        let elapsed = CACurrentMediaTime() - startTime
//
//        guard elapsed < animLength else {
//            stopDisplayLink()
//            return
//        }
//

        updatePhysics(link.targetTimestamp - link.timestamp)
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

