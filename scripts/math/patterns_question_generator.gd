# res://scripts/math/patterns_question_generator.gd
# Generates skip-counting, doubling, and sequence pattern questions across 8 tiers.
class_name PatternsQuestionGenerator
extends RefCounted

const SPROUT_ICON: String = "res://assets/art/stickers/sticker_sprout.svg"

const TIER_NAMES: Dictionary = {
	1: "Level 1: Skip-Count (2s & 5s)",
	2: "Level 2: Skip-Count (3s, 4s & 10s)",
	3: "Level 3: Missing Middle Number",
	4: "Level 4: Countdown Steps",
	5: "Level 5: Doubling Chains",
	6: "Level 6: Growing Jumps",
	7: "Level 7: Two-Step Rules",
	8: "Level 8: Master Sequences",
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, GameState.MAX_ACTIVITY_TIER), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped: int = clampi(tier, 1, GameState.MAX_ACTIVITY_TIER)
	match clamped:
		1:
			return _gen_linear_next(1, [2, 5], 1, 10)
		2:
			return _gen_linear_next(2, [3, 4, 10], 2, 15)
		3:
			return _gen_missing_middle()
		4:
			return _gen_countdown()
		5:
			return _gen_doubling()
		6:
			return _gen_growing_jumps()
		7:
			return _gen_two_step_rule()
		8:
			return _gen_master_sequence()
	return _gen_linear_next(1, [2, 5], 1, 10)


static func _gen_linear_next(tier_num: int, steps: Array[int], min_start: int, max_start: int) -> MathQuestion:
	var step: int = steps[randi() % steps.size()]
	var start: int = randi_range(min_start, max_start)
	var nums: Array[int] = [start, start + step, start + step * 2, start + step * 3]
	var ans: int = start + step * 4

	var q: MathQuestion = MathQuestion.new()
	q.operation = "pattern"
	q.tier = tier_num
	q.group_count = 4
	q.visual_icon_path = SPROUT_ICON
	q.visual_badge_text = "Rule: +%d each step" % step
	q.correct_answer = ans
	q.prompt = "Follow the stepping-stone pattern! What number comes next?"
	q.expression_text = "%d,  %d,  %d,  %d,  ?" % [nums[0], nums[1], nums[2], nums[3]]
	q.hint_text = "Tip: Each jump adds %d! Do %d + %d." % [step, nums[3], step]
	return q


static func _gen_missing_middle() -> MathQuestion:
	var step: int = [3, 4, 5, 6, 8][randi() % 5]
	var start: int = randi_range(2, 18)
	var a: int = start
	var b: int = start + step
	var c: int = start + step * 2
	var d: int = start + step * 3

	var q: MathQuestion = MathQuestion.new()
	q.operation = "pattern"
	q.tier = 3
	q.group_count = 4
	q.visual_icon_path = SPROUT_ICON
	q.visual_badge_text = "Find the missing hop!"
	q.correct_answer = c
	q.prompt = "One stepping stone washed away! Which number fits in the gap?"
	q.expression_text = "%d,  %d,  ?,  %d" % [a, b, d]
	q.hint_text = "Tip: From %d to %d is +%d, so add %d to %d!" % [a, b, step, step, b]
	return q


static func _gen_countdown() -> MathQuestion:
	var step: int = [2, 3, 4, 5, 6, 10][randi() % 6]
	var ans: int = randi_range(4, 30)
	var n4: int = ans + step
	var n3: int = ans + step * 2
	var n2: int = ans + step * 3
	var n1: int = ans + step * 4

	var q: MathQuestion = MathQuestion.new()
	q.operation = "pattern"
	q.tier = 4
	q.group_count = 4
	q.visual_icon_path = SPROUT_ICON
	q.visual_badge_text = "Counting down by %d" % step
	q.correct_answer = ans
	q.prompt = "The numbers are shrinking steadily! What number comes next?"
	q.expression_text = "%d,  %d,  %d,  %d,  ?" % [n1, n2, n3, n4]
	q.hint_text = "Tip: Each step subtracts %d! Compute %d - %d." % [step, n4, step]
	return q


static func _gen_doubling() -> MathQuestion:
	var start: int = randi_range(2, 9)
	var n1: int = start
	var n2: int = n1 * 2
	var n3: int = n2 * 2
	var n4: int = n3 * 2
	var ans: int = n4 * 2

	var q: MathQuestion = MathQuestion.new()
	q.operation = "pattern"
	q.tier = 5
	q.group_count = 4
	q.visual_icon_path = SPROUT_ICON
	q.visual_badge_text = "Doubling rule (×2)"
	q.correct_answer = ans
	q.prompt = "Every sprout doubles in size! What number comes next?"
	q.expression_text = "%d,  %d,  %d,  %d,  ?" % [n1, n2, n3, n4]
	q.hint_text = "Tip: Multiply the last number by 2: %d × 2!" % n4
	return q


static func _gen_growing_jumps() -> MathQuestion:
	var start: int = randi_range(1, 12)
	var n1: int = start
	var n2: int = n1 + 1
	var n3: int = n2 + 2
	var n4: int = n3 + 3
	var n5: int = n4 + 4
	var ans: int = n5 + 5

	var q: MathQuestion = MathQuestion.new()
	q.operation = "pattern"
	q.tier = 6
	q.group_count = 5
	q.visual_icon_path = SPROUT_ICON
	q.visual_badge_text = "+1, +2, +3, +4..."
	q.correct_answer = ans
	q.prompt = "The jumps grow by 1 each time! Find the next number."
	q.expression_text = "%d,  %d,  %d,  %d,  %d,  ?" % [n1, n2, n3, n4, n5]
	q.hint_text = "Tip: The last jump was +4 (%d to %d), so the next jump is +5!" % [n4, n5]
	return q


static func _gen_two_step_rule() -> MathQuestion:
	var start: int = randi_range(2, 6)
	var bonus: int = randi_range(1, 3)
	var n1: int = start
	var n2: int = n1 * 2 + bonus
	var n3: int = n2 * 2 + bonus
	var n4: int = n3 * 2 + bonus
	var ans: int = n4 * 2 + bonus

	var q: MathQuestion = MathQuestion.new()
	q.operation = "pattern"
	q.tier = 7
	q.group_count = 4
	q.visual_icon_path = SPROUT_ICON
	q.visual_badge_text = "Rule: ×2, then +%d" % bonus
	q.correct_answer = ans
	q.prompt = "A secret two-step garden rule! Double the number, then add %d." % bonus
	q.expression_text = "%d,  %d,  %d,  %d,  ?" % [n1, n2, n3, n4]
	q.hint_text = "Tip: Compute (%d × 2) + %d!" % [n4, bonus]
	return q


static func _gen_master_sequence() -> MathQuestion:
	var q: MathQuestion = MathQuestion.new()
	q.operation = "pattern"
	q.tier = 8
	q.group_count = 5
	q.visual_icon_path = SPROUT_ICON

	if randi() % 2 == 0:
		var offset: int = randi_range(1, 5)
		var n1: int = offset * offset
		var n2: int = (offset + 1) * (offset + 1)
		var n3: int = (offset + 2) * (offset + 2)
		var n4: int = (offset + 3) * (offset + 3)
		var ans: int = (offset + 4) * (offset + 4)
		q.visual_badge_text = "Square numbers!"
		q.correct_answer = ans
		q.prompt = "Spot the square-number pattern! What square comes next?"
		q.expression_text = "%d,  %d,  %d,  %d,  ?" % [n1, n2, n3, n4]
		q.hint_text = "Tip: Those are %d×%d, %d×%d, %d×%d, %d×%d — next is %d×%d!" % [
			offset, offset, offset + 1, offset + 1, offset + 2, offset + 2,
			offset + 3, offset + 3, offset + 4, offset + 4
		]
	else:
		var a: int = randi_range(2, 6)
		var b: int = randi_range(4, 9)
		var c: int = a + b
		var d: int = b + c
		var e: int = c + d
		var ans: int = d + e
		q.visual_badge_text = "Add the last two!"
		q.correct_answer = ans
		q.prompt = "Each number is the sum of the two before it! What comes next?"
		q.expression_text = "%d,  %d,  %d,  %d,  %d,  ?" % [a, b, c, d, e]
		q.hint_text = "Tip: Add the last two numbers together: %d + %d!" % [d, e]
	return q
