# res://scripts/math/balance_scale_question_generator.gd
# Activity 9: Balance Scale — Buffed two-sided balance & token-builder math across 8 tiers.
class_name BalanceScaleQuestionGenerator
extends RefCounted

const SCALE_ICON: String = "res://assets/art/activity_balance.svg"

const TIER_NAMES: Dictionary = {
	1: "Level 1: Light Pan Balance",
	2: "Level 2: Double Side Scales",
	3: "Level 3: Multiplied Pans",
	4: "Level 4: Weighted Groups (?)",
	5: "Level 5: Heavy Crate Scales",
	6: "Level 6: Twin Multiplier Pans",
	7: "Level 7: Master Scale Algebra",
	8: "Level 8: Grand Balance Lab",
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, GameState.MAX_ACTIVITY_TIER), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped: int = clampi(tier, 1, GameState.MAX_ACTIVITY_TIER)
	match clamped:
		1:
			return _gen_light_balance()
		2:
			return _gen_double_side()
		3:
			return _gen_multiplied_pan()
		4:
			return _gen_weighted_group()
		5:
			return _gen_heavy_crate()
		6:
			return _gen_twin_multipliers()
		7:
			return _gen_master_algebra()
		8:
			return _gen_grand_balance()
	return _gen_light_balance()


static func _gen_light_balance() -> MathQuestion:
	var a: int = randi_range(12, 35)
	var b: int = randi_range(9, 28)
	var q: MathQuestion = MathQuestion.new()
	q.operation = "balance"
	q.tier = 1
	q.group_count = 2
	q.visual_icon_path = SCALE_ICON
	q.visual_badge_text = "Left Pan = Right Pan"
	q.correct_answer = a + b
	q.prompt = "Stack weight tokens to balance %d + %d on the scale!" % [a, b]
	q.expression_text = "%d + %d  =  ?" % [a, b]
	q.hint_text = "Tip: Add the tens (%d + %d) and ones (%d + %d), then stack tokens!" % [
		(a / 10) * 10, (b / 10) * 10, a % 10, b % 10
	]
	return q


static func _gen_double_side() -> MathQuestion:
	var a: int = randi_range(18, 45)
	var b: int = randi_range(14, 38)
	var known: int = randi_range(10, a + b - 8)
	var ans: int = (a + b) - known
	var q: MathQuestion = MathQuestion.new()
	q.operation = "balance"
	q.tier = 2
	q.group_count = 2
	q.visual_icon_path = SCALE_ICON
	q.visual_badge_text = "Balance both sides!"
	q.correct_answer = ans
	q.prompt = "Left pan has %d + %d. Right pan already has %d. How much more to balance?" % [a, b, known]
	q.expression_text = "%d + %d  =  %d + ?" % [a, b, known]
	q.hint_text = "Tip: Left side = %d. Subtract %d from %d!" % [a + b, known, a + b]
	return q


static func _gen_multiplied_pan() -> MathQuestion:
	var count: int = randi_range(3, 7)
	var weight: int = randi_range(6, 14)
	var bonus: int = randi_range(5, 22)
	var q: MathQuestion = MathQuestion.new()
	q.operation = "balance"
	q.tier = 3
	q.group_count = 3
	q.visual_icon_path = SCALE_ICON
	q.visual_badge_text = "%d weights of %d + %d" % [count, weight, bonus]
	q.correct_answer = count * weight + bonus
	q.prompt = "Put %d blocks of %d plus %d bonus on the scale. Match the total!" % [count, weight, bonus]
	q.expression_text = "(%d × %d) + %d  =  ?" % [count, weight, bonus]
	q.hint_text = "Tip: Multiply %d × %d = %d first, then add %d!" % [count, weight, count * weight, bonus]
	return q


static func _gen_weighted_group() -> MathQuestion:
	var bags: int = randi_range(3, 7)
	var per_bag: int = randi_range(8, 24)
	var extra: int = randi_range(6, 25)
	var target: int = bags * per_bag + extra
	var q: MathQuestion = MathQuestion.new()
	q.operation = "algebra"
	q.tier = 4
	q.group_count = 3
	q.visual_icon_path = SCALE_ICON
	q.visual_badge_text = "Find mystery weight ?"
	q.correct_answer = per_bag
	q.prompt = "%d mystery bags plus %d balance %d on the right! Weight of 1 bag?" % [bags, extra, target]
	q.expression_text = "%d × ? + %d  =  %d" % [bags, extra, target]
	q.hint_text = "Tip: Take %d off both sides (%d - %d = %d), then divide by %d!" % [
		extra, target, extra, target - extra, bags
	]
	return q


static func _gen_heavy_crate() -> MathQuestion:
	var crates: int = randi_range(4, 9)
	var crate_w: int = randi_range(12, 28)
	var extra: int = randi_range(15, 45)
	var right_known: int = randi_range(20, 70)
	var ans: int = (crates * crate_w + extra) - right_known
	var q: MathQuestion = MathQuestion.new()
	q.operation = "balance"
	q.tier = 5
	q.group_count = 3
	q.visual_icon_path = SCALE_ICON
	q.visual_badge_text = "Heavy Crate Comparison"
	q.correct_answer = ans
	q.prompt = "Left: %d × %d + %d. Right already has %d. Build the missing weight!" % [
		crates, crate_w, extra, right_known
	]
	q.expression_text = "(%d × %d) + %d  =  %d + ?" % [crates, crate_w, extra, right_known]
	q.hint_text = "Tip: Left side = %d. Subtract %d to see what's missing!" % [
		crates * crate_w + extra, right_known
	]
	return q


static func _gen_twin_multipliers() -> MathQuestion:
	var a: int = randi_range(7, 15)
	var b: int = randi_range(6, 13)
	var c: int = randi_range(5, 12)
	var d: int = randi_range(5, 11)
	var q: MathQuestion = MathQuestion.new()
	q.operation = "order"
	q.tier = 6
	q.group_count = 4
	q.visual_icon_path = SCALE_ICON
	q.visual_badge_text = "Twin Weight Sets"
	q.correct_answer = (a * b) + (c * d)
	q.prompt = "Combine both sets of weights on the left pan and balance the scale!"
	q.expression_text = "(%d × %d) + (%d × %d)  =  ?" % [a, b, c, d]
	q.hint_text = "Tip: %d×%d = %d and %d×%d = %d — stack both together!" % [a, b, a * b, c, d, c * d]
	return q


static func _gen_master_algebra() -> MathQuestion:
	var mult: int = randi_range(4, 9)
	var mystery: int = randi_range(22, 68)
	var sub_amt: int = randi_range(12, 45)
	var rhs: int = mult * mystery - sub_amt
	var q: MathQuestion = MathQuestion.new()
	q.operation = "algebra"
	q.tier = 7
	q.group_count = 4
	q.visual_icon_path = SCALE_ICON
	q.visual_badge_text = "Master Scale Equation"
	q.correct_answer = mystery
	q.prompt = "Balance the master scale! Solve for the mystery weight ?."
	q.expression_text = "%d × ? - %d  =  %d" % [mult, sub_amt, rhs]
	q.hint_text = "Tip: Add %d back to %d (= %d), then divide by %d!" % [
		sub_amt, rhs, rhs + sub_amt, mult
	]
	return q


static func _gen_grand_balance() -> MathQuestion:
	var mult: int = randi_range(4, 8)
	var mystery: int = randi_range(28, 92)
	var lhs_bonus: int = randi_range(15, 55)
	var total: int = mult * mystery + lhs_bonus
	var rhs_a: int = randi_range(12, 22)
	var rhs_b: int = total / rhs_a
	var rhs_rem: int = total - (rhs_a * rhs_b)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "algebra"
	q.tier = 8
	q.group_count = 5
	q.visual_icon_path = SCALE_ICON
	q.visual_badge_text = "Grand Double-Sided Balance"
	q.correct_answer = mystery
	q.prompt = "Grand Balance Lab! Make both pans equal by finding ?."
	q.expression_text = "%d × ? + %d  =  (%d × %d) + %d" % [mult, lhs_bonus, rhs_a, rhs_b, rhs_rem]
	q.hint_text = "Tip: Right pan = %d + %d = %d. Subtract %d (= %d), then divide by %d!" % [
		rhs_a * rhs_b, rhs_rem, total, lhs_bonus, total - lhs_bonus, mult
	]
	return q
