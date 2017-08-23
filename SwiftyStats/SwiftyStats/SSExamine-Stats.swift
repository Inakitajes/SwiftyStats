//
//  SSExamine-Stats.swift
//  SwiftyStats
//
//  Created by volker on 23.08.17.
//  Copyright © 2017 VTSoftware. All rights reserved.
//

import Foundation
import os.log

extension SSExamine {
    
    // MARK: Totals
    
    /// Sum over all squared elements. Returns Double.nan iff data are non-numeric.
    public var squareTotal: Double {
        if isNumeric && !isEmpty {
            var s: Double = 0.0
            var temp: Double?
            for (item, freq) in self.elements {
                temp = castValueToDouble(item)
                guard temp != nil else {
                    assert(false, "internal error")
                }
                s = s + pow(temp! ,2.0) * Double(freq)
            }
            return s
        }
        else {
            return Double.nan
        }
    }
    /// Sum of all elements raised to power p
    /// - Parameter p: Power
    public func poweredTotal(power p: Double) -> Double {
        if isNumeric && !isEmpty {
            var s: Double = 0.0
            var temp: Double?
            for (item, freq) in self.elements {
                temp = castValueToDouble(item)
                guard temp != nil else {
                    assert(false, "internal error")
                }
                s = s + pow(temp!, p) * Double(freq)
            }
            return s
        }
        else {
            return Double.nan
        }
    }
    
    /// Total of all elements. Returns Double.nan iff data are non-numeric.
    public var total: Double {
        if isNumeric && !isEmpty {
            var s: Double = 0.0
            var temp: Double?
            for (item, freq) in self.elements {
                temp = castValueToDouble(item)
                guard temp != nil else {
                    assert(false, "internal error")
                }
                s = s + temp! * Double(freq)
            }
            return s
        }
        else {
            return Double.nan
        }
    }
    
    /// Returns the sum of all inversed elements
    public var inverseTotal: Double {
        if isNumeric && !isEmpty {
            var s = 0.0
            var temp: Double?
            for (item, freq) in self.elements {
                temp = castValueToDouble(item)
                guard temp != nil else {
                    assert(false, "internal error")
                }
                if !temp!.isZero {
                    s = s + (1.0 / temp!) * Double(freq)
                }
                else {
                    return Double.infinity
                }
            }
            return s
        }
        else {
            return Double.nan
        }
    }
    
    // MARK: Location
    
    /// Arithemtic mean. Will be Double.nan for non-numeric data.
    public var arithmeticMean: Double? {
        if isNumeric && !isEmpty {
            return total / Double(sampleSize)
        }
        else {
            return nil
        }
    }
    
    /// The mode. Can contain more than one item. Can be nil for empty tables.
    public var mode: Array<SSElement>? {
        if !isEmpty {
            var result: Array<SSElement> = Array<SSElement>()
            let ft = self.frequencyTable(sortOrder: .frequencyDescending)
            let freq = ft.first?.frequency
            for tableItem in ft {
                if tableItem.frequency >= freq! {
                    result.append(tableItem.item)
                }
                else {
                    break
                }
            }
            return result
        }
        else {
            return nil
        }
    }
    
    /// The most common value. Same as mode. Can contain more than one item. Can be nil for empty tables.
    public var commonest: Array<SSElement>? {
        return mode
    }
    
    
    /// The scarcest elements. Can be nil for empty tables.
    public var scarcest: Array<SSElement>? {
        if !isEmpty {
            var result: Array<SSElement> = Array<SSElement>()
            let ft = self.frequencyTable(sortOrder: .frequencyAscending)
            let freq = ft.first?.frequency
            for tableItem in ft {
                if tableItem.frequency <= freq! {
                    result.append(tableItem.item)
                }
                else {
                    break
                }
            }
            return result
        }
        else {
            return nil
        }
    }
    
    /// Returns the q-quantile.
    /// Throws: SSSwiftyStatsError.invalidArgument if data are non-numeric.
    public func quantile(q: Double) throws -> Double? {
        if q.isZero || q < 0.0 || q >= 1.0 {
            os_log("p has to be > 0.0 and < 1.0", log: log_stat, type: .error)
            throw SSSwiftyStatsError(type: .invalidArgument, file: #file, line: #line, function: #function)
        }
        if !isNumeric {
            os_log("Quantile is not defined for non-numeric data.", log: log_stat, type: .error)
            throw SSSwiftyStatsError(type: .invalidArgument, file: #file, line: #line, function: #function)
        }
        var result: Double
        if !isEmpty && self.sampleSize >= 2 {
            let k = Double(self.sampleSize) * q
            var a = self.elementsAsArray(sortOrder: .ascending)!
            var temp1: Double?
            var temp2: Double?
            var temp3: SSElement
            if k.truncatingRemainder(dividingBy: 1).isZero {
                temp3 = a[a.startIndex.advanced(by: Int(k - 1))]
                temp1 = castValueToDouble(temp3)
                guard temp1 != nil else {
                    assert(false, "internal error")
                }
                temp3 = a[a.startIndex.advanced(by: Int(k))]
                temp2 = castValueToDouble(temp3)
                guard temp2 != nil else {
                    assert(false, "internal error")
                }
                result = (temp1! + temp2!) / 2.0
            }
            else {
                temp3 = a[a.startIndex.advanced(by: Int(ceil(k - 1)))]
                temp1 = castValueToDouble(temp3)
                guard temp1 != nil else {
                    assert(false, "internal error")
                }
                result = temp1!
            }
            return result
        }
        else {
            return nil
        }
    }
    
    /// Returns a SSQuartile struct or nil for empty or non-numeric tables.
    public var quartile: SSQuartile? {
        get {
            if !isEmpty && isNumeric {
                var res = SSQuartile()
                do {
                    res.q25 = try self.quantile(q: 0.25)!
                    res.q75 = try self.quantile(q: 0.75)!
                    res.q50 = try self.quantile(q: 0.5)!
                }
                catch {
                    return nil
                }
                return res
            }
            else {
                return nil
            }
        }
    }
    
    /// Returns the geometric mean.
    public var geometricMean: Double? {
        get {
            if !isEmpty && isNumeric {
                let a = self.logProduct
                let b = Double(self.sampleSize)
                let c = exp(a / b)
                return c
            }
            else {
                return nil
            }
        }
    }
    
    /// Harmonic mean. Can be nil for non-numeric data.
    public var harmonicMean: Double? {
        get {
            if !isEmpty && isNumeric {
                return Double(self.sampleSize) / self.inverseTotal
            }
            else {
                return nil
            }
        }
    }
    
    
    /// Returns the contraharmonic mean (== (mean of squared elements) / (arithmetic mean))
    public var contraHarmonicMean: Double? {
        if !isEmpty && isNumeric {
            let sqM = self.squareTotal / Double(self.sampleSize)
            let m = self.arithmeticMean!
            if !m.isZero {
                return sqM / m
            }
            else {
                return Double.infinity * (-1.0)
            }
        }
        else {
            return nil
        }
    }
    
    /// Returns the powered mean of order n
    /// - Parameter n: The order of the powered mean
    /// - Returns: The powered mean, nil if the receiver contains non-numerical data.
    public func poweredMean(order: Double) -> Double? {
        if order <= 0.0 || !isNumeric {
            return nil
        }
        if !isEmpty {
            let sum = self.poweredTotal(power: order)
            return pow(sum / Double(self.sampleSize), 1.0 / order)
        }
        else {
            return nil
        }
    }
    
    /// Returns the trimmed mean of all elements after dropping a fraction of alpha of the smallest and largest elements.
    /// - Parameter alpha: Fraction to drop
    /// - Throws: Throws an error if alpha <= 0 or alpha >= 0.5
    public func trimmedMean(alpha: Double) throws -> Double? {
        if alpha <= 0.0 || alpha >= 0.5 {
            os_log("alpha has to be greater than zero and smaller than 0.5", log: log_stat, type: .error)
            throw SSSwiftyStatsError(type: .invalidArgument, file: #file, line: #line, function: #function)
        }
        if !isEmpty {
            if isNumeric {
                if let a = self.elementsAsArray(sortOrder: .ascending) {
                    let l = a.count
                    let v = floor(Double(l) * alpha)
                    var s = 0.0
                    var k = 0.0
                    var temp: Double?
                    for i in Int(v)...l - Int(v) - 1  {
                        temp = castValueToDouble(a[i])
                        guard temp != nil else {
                            assert(false, "internal error")
                        }
                        s = s + temp!
                        k = k + 1
                    }
                    return s / k
                }
                else {
                    return nil
                }
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    /// Returns the mean after replacing a given fraction (alpha) at the high and low end with the most extreme remaining values.
    /// - Parameter alpha: Fraction
    /// - Throws: Throws an error if alpha <= 0 or alpha >= 0.5
    public func winsorizedMean(alpha: Double) throws -> Double? {
        if alpha <= 0.0 || alpha >= 0.5 {
            os_log("alpha has to be greater than zero and smaller than 0.5", log: log_stat, type: .error)
            throw SSSwiftyStatsError(type: .invalidArgument, file: #file, line: #line, function: #function)
        }
        if !isEmpty && isNumeric {
            if let a = self.elementsAsArray(sortOrder: .ascending) {
                let l = a.count
                let v = floor(Double(l) * alpha)
                var s = 0.0
                var temp: Double?
                for i in Int(v)...l - Int(v) - 1  {
                    temp = castValueToDouble(a[i])
                    guard temp != nil else {
                        assert(false, "internal error")
                    }
                    s = s + temp!
                }
                temp = castValueToDouble(a[Int(v)])
                guard temp != nil else {
                    assert(false, "internal error")
                }
                var temp1: Double?
                temp1 = castValueToDouble(a[Int(l - Int(v) - 1)])
                guard temp1 != nil else {
                    assert(false, "internal error")
                }
                s = s + v * (temp! + temp1!)
                return s / Double(self.sampleSize)
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    /// The median. Can be nil for non-numeric data.
    public var median: Double? {
        get {
            var res: Double
            if !isEmpty && isNumeric {
                do {
                    res = try self.quantile(q: 0.5)!
                }
                catch {
                    return nil
                }
                return res
            }
            else {
                return nil
            }
        }
    }
    
    // MARK: Products
    
    /// Product of all elements. Will be Double.nan for non-numeric data.
    public var product: Double {
        if isNumeric && !isEmpty {
            var p: Double = 1.0
            var temp: Double?
            for (item, freq) in self.elements {
                temp = castValueToDouble(item)
                guard temp != nil else {
                    assert(false, "internal error")
                }
                if temp!.isZero {
                    return 0.0
                }
                else {
                    p = p * pow(temp!, Double(freq))
                }
            }
            return p
        }
        else {
            if isEmpty {
                return Double.nan
            }
            else {
                return 0.0
            }
        }
    }
    
    /// The log-Product. Will be Double.nan for non-numeric data or if there is at least one item lower than zero. Returns -inf if there is at least one item equals to zero.
    public var logProduct: Double {
        var sp : Double = 0.0
        var temp: Double?
        if isNumeric && !isEmpty {
            if isEmpty {
                return 0.0
            }
            else {
                for (item, freq) in self.elements {
                    temp = castValueToDouble(item)
                    guard temp != nil else {
                        assert(false, "internal error")
                    }
                    if temp! > 0 {
                        sp = sp + log(temp!) * Double(freq)
                    }
                    else if temp!.isZero {
                        return -Double.infinity
                    }
                    else {
                        return Double.nan
                    }
                }
                return sp
            }
        }
        else {
            return Double.nan
        }
    }
    
    
    
    // MARK: Dispersion
    
    /// The largest item. Can be nil for empty tables.
    public var maximum: SSElement? {
        get {
            if !isEmpty {
                if let a = self.elementsAsArray(sortOrder: .ascending) {
                    return a.last
                }
                else {
                    return nil
                }
            }
            else {
                return nil
            }
        }
    }
    
    /// The smallest item. Can be nil for empty tables.
    public var minimum: SSElement? {
        get {
            if !isEmpty {
                if let a = self.elementsAsArray(sortOrder: .ascending) {
                    return a.first
                }
                else {
                    return nil
                }
            }
            else {
                return nil
            }
        }
    }
    
    /// The difference between maximum and minimum. Can be nil for empty tables.
    public var range: Double? {
        get {
            var tempMax: Double?
            var tempMin: Double?
            if !isEmpty && isNumeric {
                tempMax = castValueToDouble(self.maximum)
                guard tempMax != nil else {
                    assert(false, "internal error")
                }
                tempMin = castValueToDouble(self.minimum)
                guard tempMin != nil else {
                    assert(false, "internal error")
                }
                return Double(tempMax! - tempMin!)
            }
            else {
                return nil
            }
        }
    }
    
    
    /// Returns the quartile devation (interquartile range / 2.0)
    public var quartileDeviation: Double? {
        if let _ = self.interquartileRange {
            return self.interquartileRange! / 2.0
        }
        else {
            return nil
        }
    }
    
    /// Returns the relative quartile distance
    public var relativeQuartileDistance: Double? {
        if let q: SSQuartile = self.quartile {
            return (q.q75 - q.q25) / q.q50
        }
        else {
            return nil
        }
    }
    
    /// Returns the mid-range
    public var midRange: Double? {
        if !isEmpty {
            if isNumeric {
                let tempMax = castValueToDouble(self.maximum)
                guard tempMax != nil else {
                    assert(false, "internal error")
                }
                let tempMin = castValueToDouble(self.minimum)
                guard tempMin != nil else {
                    assert(false, "internal error")
                }
                return (tempMax! + tempMin!) / 2.0
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    
    /// Returns the interquartile range
    public var interquartileRange: Double? {
        get {
            if !isEmpty && isNumeric {
                do {
                    return try interquantileRange(lowerQuantile: 0.25, upperQuantile: 0.75)!
                }
                catch {
                    return nil
                }
            }
            else {
                return nil
            }
        }
    }
    
    /// Returns the interquartile range between two quantiles
    /// - Parameter lower: Lower quantile
    /// - Parameter upper: Upper quantile
    /// - Throws: SSSwiftyStatsError.invalidArgument if upper.isZero || upper < 0.0 || upper >= 1.0 || lower.isZero || lower < 0.0 || lower >= 1.0 || upper < lower
    public func interquantileRange(lowerQuantile upper: Double!, upperQuantile lower: Double!) throws -> Double? {
        if upper.isZero || upper < 0.0 || upper >= 1.0 || lower.isZero || lower < 0.0 || lower >= 1.0 {
            os_log("lower and upper quantile has to be > 0.0 and < 1.0", log: log_stat, type: .error)
            throw SSSwiftyStatsError(type: .invalidArgument, file: #file, line: #line, function: #function)
        }
        if upper < lower {
            os_log("lower quantile has to be less than upper quantile", log: log_stat, type: .error)
            throw SSSwiftyStatsError(type: .invalidArgument, file: #file, line: #line, function: #function)
        }
        if !isNumeric {
            return nil
        }
        if lower.isEqual(to: upper) {
            return 0.0
        }
        do {
            let q1 = try quantile(q: upper)
            let q2 = try quantile(q: lower)
            return q1! - q2!
        }
        catch {
            return nil
        }
    }
    
    /// Returns the sample variance.
    /// - Parameter type: Can be .sample and .unbiased
    public func variance(type: SSVarianceType) -> Double? {
        switch type {
        case .biased:
            return moment(r: 2, type: .central)
        case .unbiased:
            if !isEmpty && isNumeric && self.sampleSize >= 2 {
                let m = self.arithmeticMean
                var diff = 0.0
                var sum = 0.0
                var temp: Double?
                for (item, freq) in self.elements {
                    temp = castValueToDouble(item)
                    guard temp != nil, m != nil else {
                        assert(false, "internal error")
                    }
                    diff = temp! - m!
                    sum = sum + diff * diff * Double(freq)
                }
                return sum / Double(self.sampleSize - 1)
            }
            else {
                return nil
            }
        }
    }
    
    /// Returns the sample standard deviation.
    /// - Parameter type: .biased or .unbiased
    public func standardDeviation(type: SSStandardDeviationType) -> Double? {
        if let v = variance(type: SSVarianceType(rawValue: type.rawValue)!) {
            return sqrt(v)
        }
        else {
            return nil
        }
    }
    
    /// Returns the standard error of the sample
    public var standardError: Double? {
        if !isEmpty && isNumeric {
            let sd = self.standardDeviation(type: .unbiased)!
            return sd / Double(self.sampleSize)
        }
        else {
            return nil
        }
    }
    
    
    /// Returns the entropy of the sample. Defined only for nominal or ordinal data
    public var entropy: Double? {
        if !isEmpty && isNumeric {
            if self.levelOfMeasurement == .ordinal || self.levelOfMeasurement == .nominal {
                var s: Double = 0.0
                for item in self.uniqueElements(sortOrder: .none)! {
                    s += self.relativeFrequency(item) * log2(self.relativeFrequency(item))
                }
                return -s
            }
            else {
                // entropy is not defined for levels other than .nominal or .ordinal
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    
    /// Returns the relative entropy of the sample. Defined only for nominal or ordinal data
    public var relativeEntropy: Double? {
        if let e = self.entropy {
            return e / log2(Double(self.sampleSize))
        }
        else {
            return nil
        }
    }
    
    // Returns the Herfindahl index
    public var herfindahlIndex: Double? {
        if !isEmpty && isNumeric {
            if self.levelOfMeasurement == .ordinal || self.levelOfMeasurement == .nominal {
                var s: Double = 0.0
                var p: Double = 0.0
                for item in self.uniqueElements(sortOrder: .none)! {
                    p = self.relativeFrequency(item)
                    s += p * p
                }
                return 1.0 - p
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    // Returns the normalized Herfindahl index
    public var herfindahlIndexNormalized: Double? {
        if let hi = self.herfindahlIndex {
            return hi * Double(self.length) / Double(self.length - 1)
        }
        else {
            return nil
        }
    }
    
    /// Returns the Gini coefficient
    public var giniCoeff: Double? {
        if let md = meanDifference {
            return md / (2.0 * arithmeticMean!)
        }
        else {
            return nil
        }
    }
    
    /// Returns the alpha-confidence interval of the mean when the population variance is known
    /// - Parameter a: Alpha
    /// - Parameter sd: Standard deviation of the population
    public func normalCI(alpha a: Double!, populationSD sd: Double!) -> SSConfIntv? {
        if alpha <= 0.0 || alpha >= 1.0 {
            return nil
        }
        if !isEmpty && isNumeric {
            var upper: Double
            var lower: Double
            var width: Double
            var t1: Double
            var u: Double
            do {
                let m = self.arithmeticMean
                u = try SSProbabilityDistributions.quantileStandardNormalDist(p: 1.0 - alpha / 2.0)
                t1 = sd / sqrt(Double(self.sampleSize))
                width = u * t1
                upper = m! + width
                lower = m! - width
                var result = SSConfIntv()
                result.lowerBound = lower
                result.upperBound = upper
                result.intervalWidth = width
                return result
            }
            catch {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    /// Returns the alpha-confidence interval of the mean when the population variance is unknown
    /// - Parameter a: Alpha
    public func studentTCI(alpha a: Double!) -> SSConfIntv? {
        if alpha <= 0.0 || alpha >= 1.0 {
            return nil
        }
        if !isEmpty && isNumeric {
            var upper: Double
            var lower: Double
            var width: Double
            var m: Double
            var u: Double
            m = arithmeticMean!
            if let s = self.standardDeviation(type: .unbiased) {
                do {
                    u = try SSProbabilityDistributions.quantileStudentTDist(p: 1.0 - alpha / 2.0 , degreesOfFreedom: Double(self.sampleSize) - 1.0)
                }
                catch {
                    return nil
                }
                lower = m - u * s / sqrt(Double(self.sampleSize))
                upper = m + u * s / sqrt(Double(self.sampleSize))
                width = u * s / sqrt(Double(self.sampleSize))
                var result = SSConfIntv()
                result.lowerBound = lower
                result.upperBound = upper
                result.intervalWidth = width
                return result
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    /// Returns the 0.95-confidence interval of the mean using Student's T distribution.
    public var meanCI: SSConfIntv? {
        get {
            return self.studentTCI(alpha: 0.05)
        }
    }
    
    /// Returns the coefficient of variation. A shorctut for coefficientOfVariation:
    public var cv: Double? {
        return coefficientOfVariation
    }
    
    
    /// Returns the coefficient of variation
    public var coefficientOfVariation: Double? {
        if !isEmpty && isNumeric {
            if let s = self.standardDeviation(type: .unbiased) {
                return s / arithmeticMean!
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    /// Returns the mean absolute difference
    public var meanDifference: Double? {
        if !isEmpty && isNumeric {
            if self.sampleSize < 2 {
                return nil
            }
            var s1: Double = 0.0
            var s2: Double = 0.0
            let c: Double = Double(self.sampleSize)
            let a = elementsAsArray(sortOrder: .ascending)!
            var v: Int = 1
            var k: Int
            var t1: Double?
            var t2: Double?
            while v <= (self.sampleSize - 1) {
                k = v + 1
                while k <= self.sampleSize {
                    t1 = castValueToDouble(a[v - 1])
                    t2 = castValueToDouble(a[k - 1])
                    guard t1 != nil, t2 != nil else {
                        assert(false, "internal error")
                    }
                    s1 = s1 + fabs(t1! - t2!)
                    k = k + 1
                }
                s2 = s2 + s1
                s1 = 0.0
                v = v + 1
            }
            return (s2 * 2.0 / (c * (c - 1.0)))
        }
        else {
            return nil
        }
    }
    
    /// Returns the median absolute deviation around the reference point given. If you would like to know the median absoulute deviation from the median, you can do so by setting the reference point to the median
    /// - Parameter rp: Reference point
    public func medianAbsoluteDeviation(aroundReferencePoint rp: Double!) -> Double? {
        if isEmpty && !isNumeric && !rp.isNaN {
            return nil
        }
        var diffArray:Array<Double> = Array<Double>()
        let values = self.elementsAsArray(sortOrder: .ascending)!
        var t1: Double?
        let result: Double
        for item in values  {
            t1 = castValueToDouble(item)
            guard t1 != nil else {
                assert(false, "internal error")
            }
            diffArray.append(fabs(t1! - rp))
        }
        let sortedDifferences = diffArray.sorted(by: {$0 < $1})
        let k = Double(sortedDifferences.count) * 0.5
        if k.truncatingRemainder(dividingBy: 1).isZero {
            result = (sortedDifferences[sortedDifferences.startIndex.advanced(by: Int(k - 1))] + sortedDifferences[sortedDifferences.startIndex.advanced(by: Int(k))]) / 2.0
        }
        else {
            result = sortedDifferences[sortedDifferences.startIndex.advanced(by: Int(ceil(k - 1)))]
        }
        return result
    }
    
    /// Returns the mean absolute deviation around the reference point given. If you would like to know the mean absoulute deviation from the median, you can do so by setting the reference point to the median
    /// - Parameter rp: Reference point
    public func meanAbsoluteDeviation(aroundReferencePoint rp: Double!) -> Double? {
        if isEmpty && !isNumeric && !rp.isNaN {
            return nil
        }
        var sum: Double = 0.0
        var t1: Double?
        var f1: Double
        var c: Int = 0
        for (item, freq) in self.elements {
            t1 = castValueToDouble(item)
            guard t1 != nil else {
                assert(false, "internal error")
            }
            f1 = Double(freq)
            sum = sum + fabs(t1! - rp) * f1
            c = c + freq
        }
        return sum / Double(c)
    }
    
    
    /// Returns the relative mean absolute difference
    public var meanRelativeDifference: Double? {
        if let md = meanDifference {
            return md / arithmeticMean!
        }
        else {
            return nil
        }
    }
    
    /// Returns the semi-variance
    /// - Parameter type: SSSemiVariance.lower or SSSemiVariance.upper
    public func semiVariance(type: SSSemiVariance) -> Double? {
        if !isEmpty && isNumeric {
            switch type {
            case .lower:
                if let a = self.elementsAsArray(sortOrder: .ascending) {
                    let m = self.arithmeticMean!
                    var t: Double?
                    var s = 0.0
                    var k: Double = 0
                    for itm in a {
                        t = castValueToDouble(itm)
                        guard t != nil else {
                            assert(false, "internal error")
                        }
                        if t! < m {
                            s = s + pow(t! - m, 2.0)
                            k = k + 1.0
                        }
                        else {
                            break
                        }
                    }
                    return s / k
                }
                else {
                    return nil
                }
            case .upper:
                if let a = self.elementsAsArray(sortOrder: .descending) {
                    let m = self.arithmeticMean!
                    var t: Double?
                    var s = 0.0
                    var k: Double = 0
                    for itm in a {
                        t = castValueToDouble(itm)
                        guard t != nil else {
                            assert(false, "internal error")
                        }
                        if t! > m {
                            s = s + pow(t! - m, 2.0)
                            k = k + 1.0
                        }
                        else {
                            break
                        }
                    }
                    return s / k
                }
                else {
                    return nil
                }
            }
        }
        else {
            return nil
        }
    }
    
    
    // MARK: Empirical Moments
    
    /// Returns the r_th moment of the given type.
    /// If .central is specified, the r_th central moment of all elements with respect to their mean will be returned.
    /// If .origin is specified, the r_th moment about the origin will be returned.
    /// If .standardized is specified, the r_th standardized moment will be returned.
    /// - Parameter r: r
    public func moment(r: Int!, type: SSMomentType) -> Double? {
        switch type {
        case .central:
            return centralMoment(r: r)
        case .origin:
            return originMoment(r: r)
        case .standardized:
            return standardizedMoment(r: r)
        }
    }
    
    /// Returns the r_th central moment of all elements with respect to their mean. Will be Double.nan if isEmpty == true and data are not numerical
    /// - Parameter r: r
    fileprivate func centralMoment(r: Int!) -> Double? {
        if !isEmpty && isNumeric {
            let m = self.arithmeticMean!
            var diff = 0.0
            var sum = 0.0
            var t: Double?
            for (item, freq) in self.elements {
                t = castValueToDouble(item)
                guard t != nil else {
                    assert(false, "internal error")
                }
                diff = t! - m
                sum = sum + pow(diff, Double(r)) * Double(freq)
            }
            return sum / Double(self.sampleSize)
        }
        else {
            return nil
        }
    }
    
    
    /// Returns the r_th moment about the origin of all elements. Will be Double.nan if isEmpty == true and data are not numerical
    /// - Parameter r: r
    fileprivate func originMoment(r: Int!) -> Double? {
        if !isEmpty && isNumeric {
            var sum = 0.0
            var t: Double?
            for (item, freq) in self.elements {
                t = castValueToDouble(item)
                guard t != nil else {
                    assert(false, "internal error")
                }
                sum = sum + pow(t!, Double(r)) * Double(freq)
            }
            return sum / Double(self.sampleSize)
        }
        else {
            return nil
        }
    }
    
    /// Returns then r_th standardized moment.
    fileprivate func standardizedMoment(r: Int!) -> Double? {
        if !isEmpty && isNumeric {
            var sum = 0.0
            let m = self.arithmeticMean
            if let sd = self.standardDeviation(type: .biased) {
                if !sd.isZero {
                    var t: Double?
                    for (item, freq) in self.elements {
                        t = castValueToDouble(item)
                        guard t != nil else {
                            assert(false, "internal error")
                        }
                        sum = sum + pow( ( t! - m! ) / sd, Double(r)) * Double(freq)
                    }
                    return sum / Double(self.sampleSize)
                }
                else {
                    return nil
                }
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    // MARK: Empirical distribution parameters
    
    /// Returns the kurtosis excess
    public var kurtosisExcess: Double? {
        if !isEmpty && isNumeric {
            if let m4 = moment(r: 4, type: .central), let m2 = moment(r: 2, type: .central) {
                return m4 / pow(m2, 2) - 3.0
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    /// Returns the kurtosis.
    public var kurtosis: Double? {
        if let k = kurtosisExcess {
            return k + 3.0
        }
        else {
            return nil
        }
    }
    
    /// Returns the type of kurtosis.
    public var kurtosisType: SSKurtosisType? {
        get {
            if let ke = kurtosisExcess {
                if ke < 0 {
                    return .platykurtic
                }
                else if ke.isZero {
                    return .mesokurtic
                }
                else {
                    return .leptokurtic
                }
            }
            else {
                return nil
            }
        }
    }
    
    
    
    /// Returns the skewness.
    public var skewness: Double? {
        if !isEmpty && isNumeric {
            if let m3 = moment(r: 3, type: .central), let s3 = standardDeviation(type: .biased) {
                return m3 / pow(s3, 3)
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    /// Returns the type of skewness
    public var skewnessType: SSSkewness? {
        get {
            if let sk = skewness {
                if sk < 0 {
                    return .leftSkewed
                }
                else if sk.isZero {
                    return .symmetric
                }
                else {
                    return .rightSkewed
                }
            }
            else {
                return nil
            }
        }
    }
    
    
    /// Returns true, if there are outliers.
    /// - Parameter testType: SSOutlierTest.grubbs or SSOutlierTest.esd (Rosner Test)
    public func hasOutliers(testType: SSOutlierTest) -> Bool? {
        if !isEmpty && isNumeric {
            switch testType {
            case .grubbs:
                do {
                    let res = try SSHypothesisTesting.grubbsTest(data:self, alpha: 0.05)
                    return res.hasOutliers
                }
                catch {
                    return nil
                }
            case .esd:
                var tempArray = Array<Double>()
                let a:Array<SSElement> = self.elementsAsArray(sortOrder: .original)!
                var t:Double?
                for itm in a {
                    t = castValueToDouble(itm)
                    guard t != nil else {
                        assert(false, "internal error")
                    }
                    tempArray.append(t!)
                }
                if let res = SSHypothesisTesting.esdOutlierTest(array: tempArray, alpha: 0.05, maxOutliers: self.sampleSize / 2, testType: .bothTails) {
                    if res.countOfOutliers! > 0 {
                        return true
                    }
                    else {
                        return false
                    }
                }
                else {
                    return nil
                }
            }
        }
        else {
            return nil
        }
    }
    
    /// Returns an Array containing outliers if those exist. Uses the ESD statistics,
    /// - Parameter alpha: Alpha
    /// - Parameter max: Maximum number of outliers to return
    /// - Parameter testType: SSOutlierTest.grubbs or SSOutlierTest.esd (Rosner Test)
    public func outliers(alpha: Double!, max: Int!, testType t: SSESDTestType) -> Array<SSElement>? {
        if !isEmpty && isNumeric {
            var tempArray = Array<Double>()
            let a:Array<SSElement> = self.elementsAsArray(sortOrder: .original)!
            var temp: Double?
            for itm in a {
                temp = castValueToDouble(itm)
                guard temp != nil else {
                    assert(false, "internal error")
                }
                tempArray.append(temp!)
            }
            if let res = SSHypothesisTesting.esdOutlierTest(array: tempArray, alpha: alpha, maxOutliers: max, testType: t) {
                if res.countOfOutliers! > 0 {
                    return res.outliers as? Array<SSElement>
                }
                else {
                    return nil
                }
            }
            else {
                return nil
            }
        }
        else {
            return nil
        }
    }
    
    /// Returns true, if the sammple seems to be drawn from a normally distributed population with mean = mean(sample) and sd = sd(sample)
    public var isGaussian: Bool? {
        if isEmpty || !isNumeric {
            return nil
        }
        else {
            do {
                if let r = try SSHypothesisTesting.ksGoFTest(array: self.elementsAsArray(sortOrder: .ascending)! as! Array<Double>, targetDistribution: .gaussian) {
                    return r.pValue! > self.alpha
                }
                else {
                    return nil
                }
            }
            catch {
                return nil
            }
        }
    }
    
    /// Tests, if the sample was drawn from population with a particular distribution function
    // - Parameter target: Distribution to test
    public func testForDistribution(targetDistribution target: SSGoFTarget) throws -> SSKSTestResult? {
        if isEmpty || !isNumeric {
            return nil
        }
        else {
            do {
                return try SSHypothesisTesting.ksGoFTest(array: self.elementsAsArray(sortOrder: .ascending)! as! Array<Double>, targetDistribution: target)
            }
            catch {
                throw error
            }
        }
    }
    
    
}
