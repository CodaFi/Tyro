//
//  EitherExt.swift
//  Tyro
//
//  Created by Matthew Purland on 11/17/15.
//  Copyright © 2015 TypeLift. All rights reserved.
//

import Foundation
import Swiftz

/// Left-to-right coalescing operator for Either<L, R> where if the either is left then
/// the operator maps to the value provided by `f` otherwise it returns the either right.
public func | <L, R>(either: Either<L, R>?, @autoclosure(escaping) f: () -> R?) -> R? {
    return either?.either(onLeft: { _ in f() }, onRight: identity)
}

/// Protocol for Either<L, R> type.
public protocol EitherType {
    typealias L
    typealias R
    
    var left: L? { get }
    var right: R? { get }
}

extension Either: EitherType {
    public var right: R? {
        switch self {
        case .Right(let r): return r
        default: return nil
        }
    }
    
    public var left: L? {
        switch self {
        case .Left(let l): return l
        default: return nil
        }
    }
    
    func fmap<L, RA, RB>(f : RA -> RB, e : Either<L, RA>) -> Either<L, RB> {
        return f <^> e
    }
}

extension Array where Element: EitherType {
    func lift() -> Either<[Element.L], [Element.R]> {
        let (lefties, righties) = splitFor { $0.left != nil }
        
        if lefties.count > 0 {
            return .Left(lefties.flatMap { $0.left })
        }
        else {
            let r = righties.flatMap { $0.right }
            return .Right(r)
        }
    }
    
    public func eitherMap(f: Element -> Either<Element, Element>) -> ([Either<Element, Element>], [Either<Element, Element>]) {
        let (lefties, righties) = splitFor { $0.left != nil }
        return (lefties.map { .Left($0) }, righties.map { .Right($0) })
    }
}

extension Array {
    /// Splits the array into a tuple with the first array being which elements hold for f and the second array for those elements that do not hold for f.
    public func splitFor(f: Element -> Bool) -> ([Element], [Element]) {
        return (takeWhile(f), dropWhile(f))
    }
}

extension Dictionary where Value: EitherType {
    func keyValuePairs() -> [(Key, Value)] {
        var p = [(Key, Value)]()
        for (k, v) in self {
            p.append((k ,v))
        }
        return p
    }
    
    func lift() -> Either<[Value.L], [Key: Value.R]> {
        let (lefties, righties) = keyValuePairs().splitFor { $1.left != nil }
        
        if lefties.count > 0 {
            return .Left(lefties.flatMap { $0.1.left })
        }
        else {
            return .Right(righties.mapAssociate { $0 }.flatMap { $0.right })
        }
    }
}