# res://scripts/math/doors_question_generator.gd
# Generates Multiplication & Order-of-Operations questions for Puzzle Doors.
class_name DoorsQuestionGenerator
extends RefCounted

const GEM_ICON: String = "res://assets/art/gem.svg"

const TIER_NAMES: Dictionary = {
	1: "Level 1: Equal Groups (×2 to ×5)",
	2: "Level 2: Times Tables (to 9×9)",
	3: "Level 3: Missing Key & Two-Step",
	4: "Level 4: Order of Operations",
	5: "Level 5: Double-Digit Multiply",
	6: "Level 6: Two-Product Locks",
	7: "Level 7: Big Rune Multipliers",
	8: "Level 8: Ancient Master Locks",
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, GameState.MAX_ACTIVITY_TIER), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped: int = clampi(tier, 1, GameState.MAX_ACTIVITY_TIER)
	match clamped:
		1:
			return _gen_basic_groups()
		2:
			return _gen_times_tables()
		3:
			if randi() % 2 == 0:
				return _gen_missing_factor()
			return _gen_two_step_mul_add(3)
		4:
			return _gen_order_of_operations()
		5:
			return _gen_double_digit_mul(5, 11, 19, 3, 9)
		6:
			return _gen_two_product_lock()
		7:
			return _gen_double_digit_mul(7, 12, 29, 6, 12)
		8:
			return _gen_ancient_master_lock()
	return _gen_basic_groups()


static func _gen_basic_groups() -> MathQuestion:
	var groups: int = randi_range(2, 5)
	var each: int = randi_range(2, 5)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "mul"
	q.tier = 1
	q.group_count = groups
	q.items_per_group = each
	q.visual_icon_path = GEM_ICON
	q.visual_badge_text = "%d rows × %d gems" % [groups, each]
	q.correct_answer = groups * each
	q.prompt = "The door needs %d rows of %d glowing gems. How many gems total?" % [groups, each]
	q.expression_text = "%d  ×  %d  =  ?" % [groups, each]

	var add_parts: PackedStringArray = []
	for _i: int in groups:
		add_parts.append(str(each))
	q.hint_text = "Tip: %d groups of %d is %s!" % [groups, each, " + ".join(add_parts)]
	return q


static func _gen_times_tables() -> MathQuestion:
	var a: int = randi_range(3, 9)
	var b: int = randi_range(3, 9)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "mul"
	q.tier = 2
	q.group_count = a
	q.items_per_group = b
	q.visual_icon_path = GEM_ICON
	q.visual_badge_text = "%d sets of %d" % [a, b]
	q.correct_answer = a * b
	q.prompt = "Match the rune lock: %d sets with %d gems in each set!" % [a, b]
	q.expression_text = "%d  ×  %d  =  ?" % [a, b]
	q.hint_text = "Tip: Try breaking %d into smaller jumps, or do %d × %d + %d!" % [a, a - 1, b, b]
	return q


static func _gen_missing_factor() -> MathQuestion:
	var a: int = randi_range(2, 8)
	var b: int = randi_range(2, 9)
	var product: int = a * b

	var q: MathQuestion = MathQuestion.new()
	q.operation = "mul"
	q.tier = 3
	q.group_count = a
	q.items_per_group = 0
	q.visual_icon_path = GEM_ICON
	q.visual_badge_text = "%d rows → %d total" % [a, product]
	q.correct_answer = b
	q.prompt = "We need %d gems in %d equal rows. How many gems go in each row?" % [product, a]
	q.expression_text = "%d  ×  ?  =  %d" % [a, product]
	q.hint_text = "Tip: Skip-count by %d until you reach %d — how many steps did you take?" % [a, product]
	return q


static func _gen_two_step_mul_add(tier_override: int = 3) -> MathQuestion:
	var a: int = randi_range(2, 5)
	var b: int = randi_range(2, 6)
	var extra: int = randi_range(2, 8)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "order"
	q.tier = tier_override
	q.group_count = a
	q.items_per_group = b
	q.visual_icon_path = GEM_ICON
	q.visual_badge_text = "(%d × %d) + %d extra" % [a, b, extra]
	q.correct_answer = a * b + extra
	q.prompt = "Solve the two-part lock: multiply first, then add the bonus gems!"
	q.expression_text = "%d  ×  %d  +  %d  =  ?" % [a, b, extra]
	q.hint_text = "Tip: Always multiply before adding! First %d × %d = %d, then add %d." % [a, b, a * b, extra]
	return q


static func _gen_order_of_operations() -> MathQuestion:
	var use_parens: bool = (randi() % 2 == 0)
	var q: MathQuestion = MathQuestion.new()
	q.operation = "order"
	q.tier = 4
	q.visual_icon_path = GEM_ICON

	if use_parens:
		var a: int = randi_range(2, 5)
		var b: int = randi_range(1, 5)
		var mult: int = randi_range(2, 6)
		q.group_count = mult
		q.items_per_group = a + b
		q.visual_badge_text = "Parentheses first!"
		q.correct_answer = (a + b) * mult
		q.prompt = "Unlock the ancient gate: do what's inside parentheses first!"
		q.expression_text = "(%d + %d)  ×  %d  =  ?" % [a, b, mult]
		q.hint_text = "Tip: Parentheses come first! %d + %d = %d, then multiply by %d." % [a, b, a + b, mult]
	else:
		var m1: int = randi_range(2, 5)
		var m2: int = randi_range(2, 5)
		var base: int = m1 * m2 + randi_range(4, 15)
		q.group_count = m1
		q.items_per_group = m2
		q.visual_badge_text = "Multiply before subtract!"
		q.correct_answer = base - (m1 * m2)
		q.prompt = "Careful with the order! Multiply before you subtract."
		q.expression_text = "%d  -  %d  ×  %d  =  ?" % [base, m1, m2]
		q.hint_text = "Tip: Multiply %d × %d = %d first, then do %d - %d!" % [m1, m2, m1 * m2, base, m1 * m2]
	return q


static func _gen_double_digit_mul(tier_num: int, min_a: int, max_a: int, min_b: int, max_b: int) -> MathQuestion:
	var a: int = randi_range(min_a, max_a)
	var b: int = randi_range(min_b, max_b)
	var tens: int = (a / 10) * 10
	var ones: int = a % 10

	var q: MathQuestion = MathQuestion.new()
	q.operation = "mul"
	q.tier = tier_num
	q.group_count = clampi(b, 1, 5)
	q.items_per_group = 0
	q.visual_icon_path = GEM_ICON
	q.visual_badge_text = "%d rows × %d gems" % [a, b]
	q.correct_answer = a * b
	q.prompt = "A grand gate holds %d rows with %d gems each. How many gems in all?" % [a, b]
	q.expression_text = "%d  ×  %d  =  ?" % [a, b]
	q.hint_text = "Tip: Split %d into %d + %d: (%d × %d) + (%d × %d) = %d + %d!" % [
		a, tens, ones, tens, b, ones, b, tens * b, ones * b
	]
	return q


static func _gen_two_product_lock() -> MathQuestion:
	var a: int = randi_range(3, 8)
	var b: int = randi_range(3, 8)
	var c: int = randi_range(2, 7)
	var d: int = randi_range(2, 7)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "order"
	q.tier = 6
	q.group_count = 2
	q.items_per_group = 0
	q.visual_icon_path = GEM_ICON
	q.visual_badge_text = "(%d×%d) + (%d×%d)" % [a, b, c, d]
	q.correct_answer = (a * b) + (c * d)
	q.prompt = "Solve both rune pairs first, then add their gem totals!"
	q.expression_text = "%d × %d  +  %d × %d  =  ?" % [a, b, c, d]
	q.hint_text = "Tip: Multiply before adding! (%d × %d = %d) + (%d × %d = %d)." % [
		a, b, a * b, c, d, c * d
	]
	return q


static func _gen_ancient_master_lock() -> MathQuestion:
	var q: MathQuestion = MathQuestion.new()
	q.operation = "order"
	q.tier = 8
	q.visual_icon_path = GEM_ICON
	if randi() % 2 == 0:
		var a: int = randi_range(4, 9)
		var b: int = randi_range(3, 8)
		var mult: int = randi_range(4, 9)
		var bonus: int = randi_range(5, 25)
		q.group_count = 3
		q.visual_badge_text = "(%d+%d) × %d + %d" % [a, b, mult, bonus]
		q.correct_answer = (a + b) * mult + bonus
		q.prompt = "Master lock! Parentheses first, then multiply, then add the bonus!"
		q.expression_text = "(%d + %d) × %d + %d  =  ?" % [a, b, mult, bonus]
		q.hint_text = "Tip: %d + %d = %d, then %d × %d = %d, then add %d!" % [
			a, b, a + b, a + b, mult, (a + b) * mult, bonus
		]
	else:
		var m1: int = randi_range(6, 12)
		var m2: int = randi_range(6, 12)
		var base: int = m1 * m2 + randi_range(12, 60)
		q.group_count = 4
		q.visual_badge_text = "Multiply before subtract!"
		q.correct_answer = base - (m1 * m2)
		q.prompt = "Final temple cipher! Multiply first, then subtract from %d." % base
		q.expression_text = "%d  -  %d × %d  =  ?" % [base, m1, m2]
		q.hint_text = "Tip: First %d × %d = %d, then %d - %d!" % [m1, m2, m1 * m2, base, m1 * m2]
	return q
