import Foundation

typealias Constraint = (Object, Object) -> Vector
typealias Force = (Object) -> Vector

class Newton {
    let timestep: Scalar = 0.1

    var objects = [UUID : Object]()
    var forces = [(UUID, Force)]()

//    var constraints = [(UUID, UUID, Constraint)]()

    func add(_ object: Object) -> UUID {
        let id = UUID()
        objects[id] = object
        return id
    }

    func add(id: UUID, f: @escaping Force) {
        forces.append((id, f))
    }

    func iterate() {
        for (id, force) in forces {
            if let object = objects[id] {
                objects[id] = apply(force, to: object)
                print(object.r)
            }
        }
    }

    func apply(_ force: Force, to object: Object) -> Object {
        let f = force(object)
        let a = 1/object.m*f
        let v = object.v + timestep*a
        let r = object.r + timestep*v

        Swift.print("Applying \(f)")

        return Object(m: object.m, r: r, v: v, a: a)
    }
}

let gravity: Force = { obj in 10*obj.m*e_x }

struct Object {
    let m: Scalar
    var r: Vector
    var v: Vector = .zero
    var a: Vector = .zero
}

//struct Constraint {
//    let obj1: Object
//    let obj2: Object
//    let f: (Object, Object) -> Vector
//}
//
//struct Force {
//    let obj: Object
//    let f: (Object) -> Vector
//}
