//
//  FlightController.swift
//  Physicum
//
//  Created by Gustaf Kugelberg on 2017-07-14.
//  Copyright © 2017 Gustaf Kugelberg. All rights reserved.
//

import UIKit

typealias LogData = (name: String, min: Scalar, max: Scalar, value: Scalar)
typealias LogVectorData = (name: String, color: UIColor, pos: Vector, value: Vector)
typealias Parameter = (name: String, min: Scalar, max: Scalar, default: Scalar)

protocol FlightController: class {
    // Inputs
    var state: State { set get }
    var positionSetPoint: Vector? { set get }
    var attitudeSetPoint: Quaternion? { set get }

    // Parameters
    var parameters: [Parameter] { get }
    var parameterValues: [Scalar] { set get }

    // Outputs
    var thrusts: [Scalar] { get }

    // Debugging and logging
    var log: [LogData] { get }
    var vectorLog: [LogVectorData] { get }

    // Configurations
    var configs: [MotorConfig] { get }

    // Initialisation
    init(configs: [MotorConfig])
}

//class BaseFlightController: FlightController {
//
//}

class AttitudeFlightController: FlightController {
    // Inputs
    public var state: State = .id { didSet { stateChanged() } }
    public var positionSetPoint: Vector? = .zero
    public var attitudeSetPoint: Quaternion? = nil

    // Parameters
    public let parameters: [Parameter]
    public var parameterValues: [Scalar]

    // Output
    public var thrusts: [Scalar]

    // Debugging and logging
    public var log: [LogData]
    public var vectorLog: [LogVectorData]

    // Configuration
    public let configs: [MotorConfig]

    // Initialisation
    required init(configs: [MotorConfig]) {
        self.configs = configs
        self.thrusts = Array(repeating: 0, count: configs.count)

        let parameters: [Parameter] = [("rx", -1, 1, 0),
                                       ("ry", -1, 1, 0),
                                       ("rz", -1, 1, 0),
                                       ("P", 0, 100, 50),
                                       ("D", 0, 100, 50),
                                       ("Perr", -100, 100, 75),
                                       ("Prate", -2, 2, 1)]
        self.parameters = parameters
        self.parameterValues = parameters.map { $0.default }

        self.log = [("err x", -1, 1, 0),
                    ("err y", -1, 1, 0),
                    ("err z", -1, 1, 0),
                    ("err w", -1, 1, 0),
                    ("t x", -1, 1, 0),
                    ("t y", -1, 1, 0),
                    ("t z", -2, 2, 0),
                    ("adj z", -2, 2, 0)]

        self.vectorLog = [("t", .red, .zero, .zero),
                          ("t_z", .purple, .zero, .zero),
                          ("t_xy", .orange, .zero, .zero),
                          ("w", .green, .zero, .zero)]
    }

    // MARK: - Private

    private func stateChanged() {
        if let attitudeSetPoint = attitudeSetPoint {
            let err = attitudeSetPoint*state.q.conjugate

            let errBodyQ = state.q.conjugate*attitudeSetPoint
            let errBody = (errBodyQ.w > 0 ? 1 : -1)*errBodyQ.vector

            let rateBody = state.q.conjugate.apply(state.l)

            pid.kp = parameterValues[3]
            pid.kd = parameterValues[4]

            let zadj = -pid.step(measured: errBody.z, setPoint: 0)

            let pErr = parameterValues[5]
            let pRate = -parameterValues[6]

            let torque = -pErr*errBody - pRate*rateBody

//            let torqueXY = torque - torque.z

            let factor: Scalar = 4
            let overall: Scalar = 0.7

            thrusts = configs.map { config in
                let pitchAdjustment = (factor - (config.a.x > 0 ? +1 : -1)*torque.y)/factor
                let rollAdjustment = (factor + (config.a.y > 0 ? +1 : -1)*torque.x)/factor
                let yawAdjustment = (factor + (config.a.x*config.a.y > 0 ? +1 : -1)*zadj)/factor

                return min(1, max(0, overall*pitchAdjustment*rollAdjustment*yawAdjustment))
//                return min(1, max(0, overall*yawAdjustment))
            }

            log[0].value = errBody.x
            log[1].value = errBody.y
            log[2].value = errBody.z
            log[3].value = errBodyQ.w

            log[4].value = torque.x
            log[5].value = torque.y
            log[6].value = torque.z
            log[7].value = zadj

            // Red
            vectorLog[0].pos = state.r
            vectorLog[0].value = err.vector
            // Purple
            //            vectorLog[1].pos = x.r
            //            vectorLog[1].value = errZ
            // Orange
            //            vectorLog[2].pos = x.r
            //            vectorLog[2].value = err.vector - errZ
            vectorLog[2].pos = state.r
            vectorLog[2].value = torque

            // Green
            vectorLog[3].pos = state.r
            vectorLog[3].value = 1/25*state.l

        }
    }

    // MARK: - Helper Variablse

    private var pid = BasicPID<Scalar>()

    // MARK: - Helper Methods
}

//class HeightFlightController: FlightController {
//    // Inputs
//    public var params: [Parameter] = []
//    public var parameters: (Scalar, Scalar, Scalar, Scalar, Scalar) = (0, 0, 0, 0, 0) // z, P, I, D
//    public var positionSetPoint: Vector? = .zero
//    public var attitudeSetPoint: Quaternion? = nil
//
//    // Static Outputs
//    public let parameterLabels: (String?, String?, String?, String?, String?) = ("z", "Kd", "Ki", "Kp", "--")
//    public let parameterDefaults: (Scalar, Scalar, Scalar, Scalar, Scalar) = (0, -0.9, -1, -1, 0)
//
//    // Continuous Outputs
//    public var log: [LogData] = []
//    public var vectorLog: [LogVectorData] = []
//    public var thrusts: [Scalar]
//
//    // Configuration
//    public let configs: [MotorConfig]
//
//    // Initialisation
//    required init(configs: [MotorConfig]) {
//        self.configs = configs
//        self.thrusts = Array(repeating: 0, count: configs.count)
//    }
//
//    // State Input
//    public func updateState(x: State) {
//        guard let posSetPoint = positionSetPoint else { return }
//
//        pid.kd = (parameters.3 + 1)*2
//        pid.ki = (parameters.2 + 1)*2
//        pid.kp = (parameters.1 + 1)*2
//        positionSetPoint?.z = -40*(parameters.0 - 0.5)
//
//        let thrust = max(0, pid.step(measured: -x.r.z, setPoint: -posSetPoint.z))
//        thrusts = [thrust, thrust, thrust, thrust]
//    }
//
//    // MARK: - Helper Variablse
//
//    private var pid = BasicPID<Scalar>()
//
//    // MARK: - Helper Methods
//}

struct BasicPID<T: VectorType> {
    mutating func step(measured: T, setPoint: T) -> T {
        let error = setPoint - measured
        errorSum = errorSum + (1/10000)*error

        let p = kp*error
        let i = -ki*errorSum
        let d = kd*(error - previousError)

        previousError = error

        return p + i + d
    }

    var kp: Scalar = 0
    var ki: Scalar = 0
    var kd: Scalar = 0

    private var errorSum: T = .zero
    private var previousError: T = .zero
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




