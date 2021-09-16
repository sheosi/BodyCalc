/***** Public interface *******************************************************/
public func base_calories(weight: Weight, height: Float32, age: UInt8, sex: Sex ) -> (Float32, Array<CaloriesSpecialCases>) {
    if let fat = weight.fat_percent() {
        return (katch_mcardle(weight: weight.total, fat_percent: fat), [])
    }
    else { return (mifflin_st_jeor(weight: weight.total, height: height, age: age, sex: sex), [CaloriesSpecialCases.mifflin_formula])}
}

public func target_calories(base_cals: Float32, activity: Activity) -> (Float32, Float32) {
    let (min, max) = activity_adj(act: activity)
    return (min * base_cals, max * base_cals)
}

public func carbs(
    total_cals: Float32,
    proteins: (Float32, Float32),
    fat: (Float32, Float32),
    weight_total: Float32,
    athlete_kind: AthleteKind? ) -> (Float32, Float32) {
    if let kind = athlete_kind {
        return carbs_athlete(weight_total: weight_total, kind: kind)
    }
    else {
        return carbs_normal(total_cals: total_cals, proteins: proteins, fat: fat)
    }
}

public func proteins(
    weight: Weight,
    age: UInt8,
    training: MuscleTrainingKind,
    goal: Goal,
    sex: Sex,
    activity: Activity,
    is_bodybuilder: Bool
    ) -> (Float32, Float32, Array<ProteinSpecialCases>) {
    func isTeen(age: UInt8) -> Bool {
        return age < 19
    }

    func isGoalVeryLowCarbs(goal: Goal) -> Bool {
        func isIntensityModerate(intensity: GoalIntensity) -> Bool {
            switch intensity {
            case .extreme: return true
            case .high: return true
            default: return false
            }

        }
        
        if case let Goal.weight_loss(intensity) = goal {return isIntensityModerate(intensity: intensity)}
        else {return false}
    }

    func isReallyLean(weight:Weight, sex: Sex) -> Bool {
        let min_fat: Float32 = {switch sex {
            case .male: return 0.1 // TODO: This should be asked with Carlos
            case .female: return 0.15 // TODO: This should be asked with Carlos
        }}()

        return weight.is_fat_percent_higher(percent: min_fat)
    }

    func isActivityHigh(activity: Activity) -> Bool {
        switch activity {
            case .extreme: return true
            case .vigorous: return true
            default: return false
        }
    }

    func isSedentary(activity: Activity) -> Bool {
        if case activity = Activity.sedentary {return true}
        else {return false}

    }

    func isHighFat(weight: Weight, sex: Sex) -> Bool {
        if let fat = weight.fat_percent() {
            let fat_thresh: Float32 = 0.3 // TODO: This should be asked with Carlos
            return fat >= fat_thresh 
        }
        else {return false}
    }

    func calcForWeight(weight: Weight, forTotal: Float32, forLean: Float32) -> Float32 {
        if let lean = weight.lean {
            return forLean * lean
        }
        else {return forTotal * weight.total}
    }

    if is_bodybuilder {
        let (min, max) = proteins_bodybuilder(weight: weight)
        return (min, max, [])
    }

    else if isTeen(age: age) {
        return (weight.total * 1.8, weight.total * 2.0, [ProteinSpecialCases.teen])
    }

    else if isGoalVeryLowCarbs(goal: goal) || isActivityHigh(activity: activity) {
        if isReallyLean(weight: weight, sex: sex) {
            let lean = weight.lean!
            return (lean * 2.5, lean * 4, [ProteinSpecialCases.really_lean])
        }
        else {
            let special_case: ProteinSpecialCases = {
                if isGoalVeryLowCarbs(goal: goal) {return ProteinSpecialCases.low_carbs}
                else {return ProteinSpecialCases.high_activity}
            }()
            return (weight.total * 2.5, weight.total * 3.0, [special_case])
        }
    }

    else if isSedentary(activity: activity) {
        return (
            calcForWeight(weight: weight, forTotal: 1.5, forLean: 2),
            calcForWeight(weight: weight, forTotal: 2.0, forLean: 2),
            [ProteinSpecialCases.sedentary]
        )
    }
    else if isHighFat(weight: weight, sex: sex) {
        return (
            calcForWeight(weight: weight, forTotal: 1.5, forLean: 2),
            calcForWeight(weight: weight, forTotal: 2.0, forLean: 2),
            [ProteinSpecialCases.high_fat]
        )
    }

    else {
        switch(training) {
            case .strength: return (weight.total * 1.4, weight.total * 2.0, [])
            case .resistance: return (weight.total * 1.2, weight.total * 1.8, [])
        }
    }
}

/***** Enums ******************************************************************/

public struct Weight {
    let total: Float32
    let lean: Float32?

    func fat_percent() -> Float32? {
        if let lean = self.lean {
            return (self.total - lean)/self.total
        }
        else {return .none}
    }

    func is_fat_percent_higher(percent: Float32) -> Bool {
        if let fat = self.fat_percent() {
            return fat >= percent
        }
        else {return false}
    }

    func is_fat_percent_lower(percent: Float32) -> Bool {
        if let fat = self.fat_percent() {return fat <= percent}
        else {return false}
    }
}


public enum Sex {
    case male
    case female
}

public enum Activity {
    case sedentary  // No activity, office work
    case light      // Little daily activity, exercise 1-3 times/week
    case moderate   // Moderate daily activity, exercise 3-5 times/week
    case vigorous   // Vigorous daily activity, exercise 6-7 times/week
    case extreme    // Intense daily worjour, tiring physical job
}

public enum GoalIntensity {
    case light    // 10%
    case moderate // 15%
    case high     // 20%
    case extreme  // 30%
}

public enum Goal {
    case weight_loss(GoalIntensity)
    case weight_gain(GoalIntensity)
}

public enum MuscleTrainingKind {
    case strength
    case resistance   
}

public enum AthleteKind {
    case kinda_active
    case very_active
    case intense_activity
}

/***** Calories ***************************************************************/

public enum CaloriesSpecialCases {
    case mifflin_formula
}

func mifflin_st_jeor(weight: Float32, height: Float32, age: UInt8, sex: Sex) -> Float32 {
    let sex_adj: Float32 = {
        switch sex {
        case .male: return 5
        case .female: return -161
        
    }}()
    return (9.99 * weight) + (6.25 * height) - (4.92*Float32(age)) + sex_adj
}

func katch_mcardle(weight: Float32, fat_percent: Float32) -> Float32 {
    let imcm = (weight * (100 - fat_percent)) / 100
    return 370 + (21.6 * imcm)
}


func activity_adj(act: Activity) -> (Float32, Float32) {
    switch act {
    case .sedentary: return (1.2, 1.2)
    case .light: return (1.3, 1.4) 
    case .moderate: return (1.5, 1.6)
    case .vigorous: return (1.7, 1.8)
    case .extreme: return (1.9, 2.0)
    }
}

func goal_adj(goal: Goal) -> Float32 {
    func intensity_adj(intensity: GoalIntensity) -> Float32 {
        switch intensity {
            case .light: return 0.1
            case .moderate: return 0.15
            case .high: return 0.2
            case .extreme: return 0.3
        }
    }

    switch goal {
        case .weight_loss(let intensity): return 1.0 - intensity_adj(intensity: intensity)
        case .weight_gain(let intensity): return 1.0 + intensity_adj(intensity: intensity)
    }

}

/***** Proteins ***************************************************************/

public enum ProteinSpecialCases {
    case teen
    case low_carbs
    case high_activity
    case really_lean // So lean, needs extra protein
    case sedentary // Can ingest low volume of protein
    case high_fat // Can ingest low volume of protein
}

func proteins_bodybuilder(weight: Weight) -> (Float32, Float32) {
    if let lean = weight.lean {
        return (lean * 2, lean * 3)
    }
    else {
        return (weight.total * 2, weight.total * 2.5)
    }
}

/***** Fat ********************************************************************/

public enum FatSpecialCases {
    case low_carbs_diet
}

func fat(weight: Weight, goal: Goal ) -> (Float32, Float32, Array<FatSpecialCases>) {
    func isGoalLowCarbs(goal: Goal) -> Bool {
        func isIntensityModerate(intensity: GoalIntensity) -> Bool {
            switch intensity {
            case .moderate: return true
            case .high: return true
            case .extreme: return true
            default: return false
            }

        }
        
        if case let Goal.weight_loss(intensity) = goal {return isIntensityModerate(intensity: intensity)}
        else {return false}
    }
    let cases: Array<FatSpecialCases> = {
        if isGoalLowCarbs(goal: goal) {
            return [FatSpecialCases.low_carbs_diet]
        }
        else {return []}
    }()
    let high_fat_threshold: Float32 = 0.2
    if weight.is_fat_percent_higher(percent: high_fat_threshold) {
        let lean = weight.lean!
        return (lean * 1, lean * 2, cases)
    }
    else {
        return (weight.total * 1.0, weight.total * 2.0, cases)
    }
}


/***** Carbs ******************************************************************/

func carbs_normal(total_cals: Float32, proteins: (Float32, Float32), fat: (Float32, Float32)) -> (Float32, Float32) {
    func to_g(c: Float32) -> Float32 {
        return c / 4
    }


    // We calculate the carbohidrates as the remnant towards our calories,
    // so we get calories and transform that to grams.
    let (min_pro, max_pro) = proteins
    let (min_fat, max_fat) = fat

    return (
        to_g(c: total_cals - (min_pro * 4 + min_fat * 9)),
        to_g(c: total_cals - (max_pro * 4 + max_fat * 9))
    )
    
}

func carbs_athlete(weight_total: Float32, kind: AthleteKind) -> (Float32, Float32) {
    switch kind {
        case .kinda_active: return (weight_total * 4.5, weight_total * 6.5)
        case .very_active: return (weight_total * 6.5, weight_total * 8.5)
        case .intense_activity: return (weight_total * 8.5, 0)
    }
}
