//
//  FlightController.swift
//  Physicum
//
//  Created by Gustaf Kugelberg on 2017-07-14.
//  Copyright © 2017 Gustaf Kugelberg. All rights reserved.
//

import UIKit

typealias LogData = (name: String, min: Scalar, max: Scalar, value: Scalar)
typealias LogVectorData = (name: String, color: UIColor, value: Vector)

protocol FlightController: class {
    // Inputs
    var positionSetPoint: Vector? { set get }
    var attitudeSetPoint: Quaternion? { set get }
    var parameters: (Scalar, Scalar, Scalar, Scalar) { set get }

    // Static Outputs
    var parameterLabels: (String?, String?, String?, String?) { get }
    var parameterDefaults: (Scalar, Scalar, Scalar, Scalar) { get }

    // Continuous Outputs
    var log: [LogData] { get }
    var vectorLog: [LogVectorData] { get }
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

    // Static Outputs
    public let parameterLabels: (String?, String?, String?, String?) = ("thr", "pch", "rll", "yaw")
    public let parameterDefaults: (Scalar, Scalar, Scalar, Scalar) = (0.64, 0, 0, 0)

    // Continuous Outputs
    public var log: [LogData] = [("pitch", -1, 1, 0), ("roll", -1, 1, 0), ("yaw", -1, 1, 0)]
    public var vectorLog: [LogVectorData] = []
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

        log[0].value = pitchDelta
        log[1].value = rollDelta
        log[2].value = yawDelta
    }

    // MARK: - Helper Methods
}

class AttitudeFlightController: FlightController {
    // Inputs
    public var parameters: (Scalar, Scalar, Scalar, Scalar) = (0, 0, 0, 0) // z, P, I, D
    public var positionSetPoint: Vector? = .zero
    public var attitudeSetPoint: Quaternion? = nil

    // Static Outputs
    public let parameterLabels: (String?, String?, String?, String?) = ("z", "Kd", "Ki", "Kp")
    public let parameterDefaults: (Scalar, Scalar, Scalar, Scalar) = (0, -0.9, -1, -1)

    // Continuous Outputs
    public var log: [LogData] = [("x", -1, 1, 0), ("y", -1, 1, 0), ("z", -1, 1, 0)]
    public var vectorLog: [LogVectorData] = [("t", .red, .zero), ("t_xy", .purple, .zero), ("t_z", .orange, .zero)]
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
        if let attitudeSetPoint = attitudeSetPoint {
            let e = attitudeSetPoint*x.q.conjugate
            let eBody = (e.w > 0 ? 1 : -1)*x.q.conjugate.apply(e.vector)

            log[0].value = eBody.x
            log[1].value = eBody.y
            log[2].value = eBody.z

            vectorLog[0].value = 10*eBody
            vectorLog[1].value = 10*eBody + e_x
            vectorLog[2].value = 10*eBody + e_y
        }

//        guard let posSetPoint = positionSetPoint else { return }
//
//        pid.kd = (parameters.3 + 1)*2
//        pid.ki = (parameters.2 + 1)*2
//        pid.kp = (parameters.1 + 1)*2
//        positionSetPoint?.z = -40*(parameters.0 - 0.5)
//
//        let overall = max(0, pid.step(measured: -x.r.z, setPoint: -posSetPoint.z))
//
//        let factor: Scalar = 4
//        let pitchDelta: Scalar = 0
//        let rollDelta: Scalar = 0
//        let yawDelta: Scalar = 0
//
//        thrusts = configs.map { config in
//            let pitchAdjustment = (factor + (config.a.x > 0 ? +1 : -1)*pitchDelta)/factor
//            let rollAdjustment = (factor + (config.a.y > 0 ? +1 : -1)*rollDelta)/factor
//            let yawAdjustment = (factor + (config.a.x*config.a.y > 0 ? +1 : -1)*yawDelta)/factor
//
//            return overall*pitchAdjustment*rollAdjustment*yawAdjustment
//        }
    }

    // MARK: - Helper Variablse

    private var pid: PID = BasicPID()

    // MARK: - Helper Methods
}

class HeightFlightController: FlightController {
    // Inputs
    public var parameters: (Scalar, Scalar, Scalar, Scalar) = (0, 0, 0, 0) // z, P, I, D
    public var positionSetPoint: Vector? = .zero
    public var attitudeSetPoint: Quaternion? = nil

    // Static Outputs
    public let parameterLabels: (String?, String?, String?, String?) = ("z", "Kd", "Ki", "Kp")
    public let parameterDefaults: (Scalar, Scalar, Scalar, Scalar) = (0, -0.9, -1, -1)

    // Continuous Outputs
    public var log: [LogData] = []
    public var vectorLog: [LogVectorData] = []
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

        pid.kd = (parameters.3 + 1)*2
        pid.ki = (parameters.2 + 1)*2
        pid.kp = (parameters.1 + 1)*2
        positionSetPoint?.z = -40*(parameters.0 - 0.5)

        let thrust = max(0, pid.step(measured: -x.r.z, setPoint: -posSetPoint.z))
        thrusts = [thrust, thrust, thrust, thrust]
    }

    // MARK: - Helper Variablse

    private var pid: PID = BasicPID()

    // MARK: - Helper Methods
}

protocol PID {
    associatedtype T: VectorType
    var kp: Scalar { get set }
    var ki: Scalar { get set }
    var kd: Scalar { get set }

    mutating func step(measured: T, setPoint: T) -> T
}

struct BasicPID: PID {
    var kp: Scalar = 0
    var ki: Scalar = 0
    var kd: Scalar = 0

    private var errorSum: Scalar = 0
    private var previousError: Scalar = 0

    mutating func step(measured: Scalar, setPoint: Scalar) -> Scalar {
        let error = setPoint - measured
        errorSum = errorSum + error/10000

        let p = kp*error
        let i = -ki*errorSum
        let d = kd*(error - previousError)

        previousError = error

//        print("E: \(error) (\(errorSum)), P: \(p), I: \(i), D: \(d)) -> \(max(p + i + d, 0))")

        return p + i + d
    }
}

protocol VectorType {
    static func *(lhs: Scalar, rhs: Self) -> Self
    static func +(lhs: Self, rhs: Self) -> Self
    static func -(lhs: Self, rhs: Self) -> Self
    static var zero: Self { get }
}

extension Scalar: VectorType {
    static let zero: Scalar = 0
}

extension Vector: VectorType { }




