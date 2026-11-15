# res://scripts/math/coin_jar_question_generator.gd
# Generates coin counting, missing-number algebra, and average questions across 8 tiers.
class_name CoinJarQuestionGenerator
extends RefCounted

const COIN_ICON: String = "res://assets/ui/coin.svg"

const TIER_NAMES: Dictionary = {
	1: "Level 1: Coin Stacks",
	2: "Level 2: Mixed Coin Jars",
	3: "Level 3: Missing Addend (?)",
	4: "Level 4: Balance Equations",
	5: "Level 5: Weekly Savings",
	6: "Level 6: Two-Step Mystery",
	7: "Level 7: Fair Averages",
	8: "Level 8: Master Vault Riddles",
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, GameState.MAX_ACTIVITY_TIER), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped: int = clampi(tier, 1, GameState.MAX_ACTIVITY_TIER)
	match clamped:
		1:
			return _gen_coin_stacks()
		2:
			return _gen_mixed_coins()
		3:
			return _gen_missing_addend()
		4:
			return _gen_balance_equation()
		5:
			return _gen_weekly_savings()
		6:
			return _gen_two_step_mystery()
		7:
			return _gen_average(7, 3, 8, 28)
		8:
			if randi() % 2 == 0:
				return _gen_average(8, 4, 15, 60)
			return _gen_master_vault()
	return _gen_coin_stacks()


static func _gen_coin_stacks() -> MathQuestion:
	var value: int = [2, 5, 10][randi() % 3]
	var count: int = randi_range(3, 9)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "coin"
	q.tier = 1
	q.group_count = clampi(count, 1, 5)
	q.visual_icon_path = COIN_ICON
	q.visual_badge_text = "%d coins × ₱%d" % [count, value]
	q.correct_answer = count * value
	q.prompt = "You stacked %d coins worth ₱%d each. How much money is in the stack?" % [count, value]
	q.expression_text = "%d  ×  ₱%d  =  ?" % [count, value]
	q.hint_text = "Tip: Skip-count by %d, %d times!" % [value, count]
	return q


static func _gen_mixed_coins() -> MathQuestion:
	var fives: int = randi_range(2, 7)
	var tens: int = randi_range(1, 5)
	var ans: int = fives * 5 + tens * 10

	var q: MathQuestion = MathQuestion.new()
	q.operation = "coin"
	q.tier = 2
	q.group_count = 2
	q.visual_icon_path = COIN_ICON
	q.visual_badge_text = "%d × ₱10  +  %d × ₱5" % [tens, fives]
	q.correct_answer = ans
	q.prompt = "Your jar holds %d ten-peso coins and %d five-peso coins. What is the total?" % [tens, fives]
	q.expression_text = "(%d × ₱10) + (%d × ₱5)  =  ?" % [tens, fives]
	q.hint_text = "Tip: %d tens = ₱%d, and %d fives = ₱%d. Add them!" % [tens, tens * 10, fives, fives * 5]
	return q


static func _gen_missing_addend() -> MathQuestion:
	var mystery: int = randi_range(5, 25)
	var known: int = randi_range(6, 22)
	var total: int = mystery + known

	var q: MathQuestion = MathQuestion.new()
	q.operation = "algebra"
	q.tier = 3
	q.group_count = 2
	q.visual_icon_path = COIN_ICON
	q.visual_badge_text = "Find the hidden coins!"
	q.correct_answer = mystery
	q.prompt = "You had some coins, then added ₱%d to reach ₱%d. How much did you start with?" % [known, total]
	q.expression_text = "?  +  %d  =  %d" % [known, total]
	q.hint_text = "Tip: Undo + %d by subtracting: %d - %d!" % [known, total, known]
	return q


static func _gen_balance_equation() -> MathQuestion:
	var q: MathQuestion = MathQuestion.new()
	q.operation = "algebra"
	q.tier = 4
	q.group_count = 2
	q.visual_icon_path = COIN_ICON

	if randi() % 2 == 0:
		var mult: int = randi_range(3, 8)
		var mystery: int = randi_range(4, 15)
		var total: int = mult * mystery
		q.visual_badge_text = "Equal coin bags!"
		q.correct_answer = mystery
		q.prompt = "%d equal coin bags hold ₱%d total. How much is in 1 bag?" % [mult, total]
		q.expression_text = "%d  ×  ?  =  %d" % [mult, total]
		q.hint_text = "Tip: Divide %d ÷ %d!" % [total, mult]
	else:
		var spent: int = randi_range(8, 25)
		var left: int = randi_range(12, 35)
		q.visual_badge_text = "Before spending!"
		q.correct_answer = spent + left
		q.prompt = "After spending ₱%d, you have ₱%d left. How much did you have before?" % [spent, left]
		q.expression_text = "?  -  %d  =  %d" % [spent, left]
		q.hint_text = "Tip: Add the ₱%d spent back to ₱%d!" % [spent, left]
	return q


static func _gen_weekly_savings() -> MathQuestion:
	var daily: int = randi_range(5, 18)
	var days: int = randi_range(5, 12)
	var bonus: int = randi_range(10, 40)
	var ans: int = daily * days + bonus

	var q: MathQuestion = MathQuestion.new()
	q.operation = "coin"
	q.tier = 5
	q.group_count = 4
	q.visual_icon_path = COIN_ICON
	q.visual_badge_text = "₱%d/day × %d days + ₱%d" % [daily, days, bonus]
	q.correct_answer = ans
	q.prompt = "Save ₱%d a day for %d days, plus a ₱%d bonus. Total savings?" % [daily, days, bonus]
	q.expression_text = "%d × %d  +  %d  =  ?" % [daily, days, bonus]
	q.hint_text = "Tip: First multiply %d × %d = %d, then add %d!" % [daily, days, daily * days, bonus]
	return q


static func _gen_two_step_mystery() -> MathQuestion:
	var mult: int = randi_range(2, 6)
	var mystery: int = randi_range(4, 15)
	var extra: int = randi_range(3, 18)
	var total: int = mult * mystery + extra

	var q: MathQuestion = MathQuestion.new()
	q.operation = "algebra"
	q.tier = 6
	q.group_count = 3
	q.visual_icon_path = COIN_ICON
	q.visual_badge_text = "Work backwards!"
	q.correct_answer = mystery
	q.prompt = "%d equal jars plus ₱%d loose coins equal ₱%d. How much is in each jar?" % [mult, extra, total]
	q.expression_text = "%d × ?  +  %d  =  %d" % [mult, extra, total]
	q.hint_text = "Tip: Subtract the loose ₱%d first (%d - %d = %d), then divide by %d!" % [
		extra, total, extra, total - extra, mult
	]
	return q


static func _gen_average(tier_num: int, count: int, min_avg: int, max_avg: int) -> MathQuestion:
	var avg: int = randi_range(min_avg, max_avg)
	var d1: int = randi_range(2, 6)
	var d2: int = randi_range(1, 5)
	var nums: Array[int] = []
	if count == 3:
		nums = [avg - d1, avg, avg + d1]
	else:
		nums = [avg - d1, avg - d2, avg + d2, avg + d1]

	var sum_val: int = 0
	var parts: PackedStringArray = []
	for n: int in nums:
		sum_val += n
		parts.append(str(n))

	var q: MathQuestion = MathQuestion.new()
	q.operation = "avg"
	q.tier = tier_num
	q.group_count = count
	q.visual_icon_path = COIN_ICON
	q.visual_badge_text = "Average of %d jars" % count
	q.correct_answer = avg
	q.prompt = "Find the average (mean) of these %d coin jars!" % count
	q.expression_text = "(%s)  ÷  %d  =  ?" % [" + ".join(parts), count]
	q.hint_text = "Tip: Add all %d numbers (%d total), then divide by %d!" % [count, sum_val, count]
	return q


static func _gen_master_vault() -> MathQuestion:
	var mult: int = randi_range(4, 9)
	var mystery: int = randi_range(8, 25)
	var sub_amt: int = randi_range(5, 25)
	var total: int = mult * mystery - sub_amt

	var q: MathQuestion = MathQuestion.new()
	q.operation = "algebra"
	q.tier = 8
	q.group_count = 4
	q.visual_icon_path = COIN_ICON
	q.visual_badge_text = "Master Vault Riddle"
	q.correct_answer = mystery
	q.prompt = "Unlock the vault! Solve for the mystery number ?."
	q.expression_text = "%d × ?  -  %d  =  %d" % [mult, sub_amt, total]
	q.hint_text = "Tip: Work backwards! Add %d to %d (= %d), then divide by %d!" % [
		sub_amt, total, total + sub_amt, mult
	]
	return q
