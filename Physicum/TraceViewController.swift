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

    var xval: Scalar = 25
    var yval: Scalar = 0

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

//        let v = VectorDrawable(.red, at: .origin) { self.xval*e_x + self.yval*e_z }
//        let u = VectorDrawable(.blue, at: .origin) { 25*e_z }
//        let w = VectorDrawable(.green, at: .origin) { (1/25)*v.vector × u.vector }
//        traceView.add(v)
//        traceView.add(u)
//        traceView.add(w)
    }
    
    @IBAction func didPinch(_ sender: UIPinchGestureRecognizer) {
        traceView.zoom(by: 1 + 0.6*Scalar(sender.scale))
        sender.scale = 1
    }

    @IBAction func didPan(_ sender: UIPanGestureRecognizer) {
//        let delta = 1/500*sender.translation(in: view)
//        traceView.rotate(by: (Scalar(delta.x), Scalar(delta.y)))
//        sender.setTranslation(.zero, in: view)

        let delta = 1/20*sender.translation(in: view)
        xval -= Scalar(delta.y)
        yval += Scalar(delta.x)

        sender.setTranslation(.zero, in: view)
        print("changed val: (\(xval):\(yval))")

        traceView.rotate(by: (0, 0))
        traceView.setNeedsDisplay()
    }

    @IBAction func didDoublePan(_ sender: UIPanGestureRecognizer) {
        let delta = 1/500*sender.translation(in: view)
        xval += Scalar(delta.x)
        yval += Scalar(delta.y)

        sender.setTranslation(.zero, in: view)
        print("changed xval: \(xval)")

//        traceView.setNeedsDisplay()
    }
}

