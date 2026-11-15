# res://scripts/math/builder_question_generator.gd
# Generates Counting, Area Rows, Perimeter & Builder Discount (%) questions.
class_name BuilderQuestionGenerator
extends RefCounted

const BRICK_ICON: String = "res://assets/art/block_brick.svg"

const TIER_NAMES: Dictionary = {
	1: "Level 1: Stacking Bricks",
	2: "Level 2: Wall Rows (Area)",
	3: "Level 3: Garden Fence (Perimeter)",
	4: "Level 4: Workshop Sales (%)",
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, 4), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped: int = clampi(tier, 1, 4)
	match clamped:
		1:
			return _gen_stack_bricks()
		2:
			return _gen_wall_rows()
		3:
			return _gen_perimeter()
		4:
			return _gen_workshop_percent()
	return _gen_stack_bricks()


static func _gen_stack_bricks() -> MathQuestion:
	var a: int = randi_range(4, 14)
	var b: int = randi_range(3, 12)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "add"
	q.tier = 1
	q.group_count = 2
	q.items_per_group = 0
	q.visual_icon_path = BRICK_ICON
	q.visual_badge_text = "%d red + %d more bricks" % [a, b]
	q.correct_answer = a + b
	q.prompt = "We stacked %d bricks and brought %d more. How many bricks total?" % [a, b]
	q.expression_text = "%d  +  %d  =  ?" % [a, b]
	q.hint_text = "Tip: Start at %d and count up %d more bricks!" % [maxi(a, b), mini(a, b)]
	return q


static func _gen_wall_rows() -> MathQuestion:
	var rows: int = randi_range(2, 6)
	var cols: int = randi_range(3, 7)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "mul"
	q.tier = 2
	q.group_count = rows
	q.items_per_group = cols
	q.visual_icon_path = BRICK_ICON
	q.visual_badge_text = "%d rows × %d bricks wide" % [rows, cols]
	q.correct_answer = rows * cols
	q.prompt = "Build a sturdy cottage wall %d rows tall and %d bricks wide. How many bricks?" % [rows, cols]
	q.expression_text = "%d  ×  %d  =  ?" % [rows, cols]
	q.hint_text = "Tip: Each of the %d rows has %d bricks. Count by %d!" % [rows, cols, cols]
	return q


static func _gen_perimeter() -> MathQuestion:
	var length: int = randi_range(4, 12)
	var width: int = randi_range(3, 9)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "add"
	q.tier = 3
	q.group_count = 4
	q.items_per_group = 0
	q.visual_icon_path = BRICK_ICON
	q.visual_badge_text = "4 sides: %dm × %dm" % [length, width]
	q.correct_answer = 2 * (length + width)
	q.prompt = "A garden is %dm long and %dm wide. How many meters of fence go all the way around?" % [length, width]
	q.expression_text = "%d + %d + %d + %d  =  ?" % [length, width, length, width]
	q.hint_text = "Tip: Add one long side and one short side (%d + %d = %d), then double it!" % [
		length, width, length + width
	]
	return q


static func _gen_workshop_percent() -> MathQuestion:
	var choices: Array[Dictionary] = [
		{"pct": 50, "base": 20, "ans": 10, "tip": "50% means half! Half of 20 is 10."},
		{"pct": 50, "base": 30, "ans": 15, "tip": "50% means half! Half of 30 is 15."},
		{"pct": 50, "base": 40, "ans": 20, "tip": "50% means half! Half of 40 is 20."},
		{"pct": 50, "base": 60, "ans": 30, "tip": "50% means half! Half of 60 is 30."},
		{"pct": 25, "base": 20, "ans": 5, "tip": "25% is 1 quarter (÷ 4)! 20 ÷ 4 = 5."},
		{"pct": 25, "base": 40, "ans": 10, "tip": "25% is 1 quarter (÷ 4)! 40 ÷ 4 = 10."},
		{"pct": 10, "base": 50, "ans": 5, "tip": "To find 10%, divide by 10!"},
		{"pct": 10, "base": 80, "ans": 8, "tip": "To find 10%, divide by 10!"},
	]
	var pick: Dictionary = choices[randi() % choices.size()]
	var pct: int = int(pick["pct"])
	var base: int = int(pick["base"])
	var ans: int = int(pick["ans"])

	var q: MathQuestion = MathQuestion.new()
	q.operation = "pct"
	q.tier = 4
	q.group_count = 1
	q.visual_icon_path = BRICK_ICON
	q.visual_badge_text = "%d%% of ₱%d" % [pct, base]
	q.correct_answer = ans
	q.prompt = "Workshop Sale! How much is %d%% off a ₱%d bundle of bricks?" % [pct, base]
	q.expression_text = "%d%%  of  ₱%d  =  ?" % [pct, base]
	q.hint_text = "Tip: " + str(pick["tip"])
	return q
