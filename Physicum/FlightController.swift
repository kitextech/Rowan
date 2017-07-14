//
//  FlightController.swift
//  Physicum
//
//  Created by Gustaf Kugelberg on 2017-07-14.
//  Copyright © 2017 Gustaf Kugelberg. All rights reserved.
//

import Foundation

protocol FlightController: class {
    // Inputs
    var positionSetPoint: Vector? { set get }
    var attitudeSetPoint: Quaternion? { set get }
    var parameters: (Scalar, Scalar, Scalar, Scalar) { set get }

    // Outputs
    var thrusts: [Scalar] { get }

    // Configuration
    var configs: [MotorConfig] { get }

    // Initialisation
    init(configs: [MotorConfig])

    // State Input
    func updateState(x: State)
}

class ManualFlightController: FlightController {
    // Inputs
    public var parameters: (Scalar, Scalar, Scalar, Scalar) = (0, 0, 0, 0)
    public var positionSetPoint: Vector? = nil
    public var attitudeSetPoint: Quaternion? = nil

    // Outputs
    public var thrusts: [Scalar]

    // Configuration
    public let configs: [MotorConfig]

    // Initialisation
    required init(configs: [MotorConfig]) {
        self.configs = configs
        self.thrusts = Array(repeating: 0, count: configs.count)
    }

    // State Input
    public func updateState(x: State) {
        let factor: Scalar = 4

        let (thrust, pitchDelta, rollDelta, yawDelta) = parameters

        thrusts = configs.map { config in
            let pitchAdjustment = (factor + (config.a.x > 0 ? +1 : -1)*pitchDelta)/factor
            let rollAdjustment = (factor + (config.a.y > 0 ? +1 : -1)*rollDelta)/factor
            let yawAdjustment = (factor + (config.a.x*config.a.y > 0 ? +1 : -1)*yawDelta)/factor

            return thrust*pitchAdjustment*rollAdjustment*yawAdjustment
        }
    }

    // MARK: - Helper Methods
}

class HeightFlightController: FlightController {
    // Inputs
    public var parameters: (Scalar, Scalar, Scalar, Scalar) = (0, 0, 0, 0) // z, P, I, D
    public var positionSetPoint: Vector? = .zero
    public var attitudeSetPoint: Quaternion? = nil

    // Outputs
    public var thrusts: [Scalar]

    // Configuration
    public let configs: [MotorConfig]

    // Initialisation
    required init(configs: [MotorConfig]) {
        self.configs = configs
        self.thrusts = Array(repeating: 0, count: configs.count)
    }

    // State Input
    public func updateState(x: State) {
        guard let posSetPoint = positionSetPoint else { return }

        pid.kd = (parameters.3 + 1)*5
        pid.ki = (parameters.2 + 1)*5
        pid.kp = (parameters.1 + 1)*5
        positionSetPoint?.z = -40*(parameters.0 - 0.5)

        let thrust = max(0, pid.step(measured: -x.r.z, setPoint: -posSetPoint.z))
        thrusts = [thrust, thrust, thrust, thrust]
    }

    // MARK: - Helper Variablse

    private var pid = PID()

    // MARK: - Helper Methods
}

struct PID {
    var kp: Scalar = 0
    var ki: Scalar = 0
    var kd: Scalar = 0

    private var errorSum: Scalar = 0
    private var previousError: Scalar = 0

    mutating func step(measured: Scalar, setPoint: Scalar) -> Scalar {
        let error = setPoint - measured
//        errorSum = errorSum + error/10000

        let p = kp*error
        let i = ki*errorSum
        let d = kd*(error - previousError)

        previousError = error

//        print("E: \(error) (\(errorSum)), P: \(p), I: \(i), D: \(d)) -> \(max(p + i + d, 0))")

        return p + i + d
    }
}



