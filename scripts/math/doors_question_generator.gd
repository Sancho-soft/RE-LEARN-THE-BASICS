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
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, 4), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped: int = clampi(tier, 1, 4)
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
