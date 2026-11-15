# res://scripts/math/shapes_question_generator.gd
# Generates geometry, angles, area, and volume questions across 8 tiers.
class_name ShapesQuestionGenerator
extends RefCounted

const ROCKET_ICON: String = "res://assets/art/stickers/sticker_rocket.svg"

const TIER_NAMES: Dictionary = {
	1: "Level 1: Counting Sides",
	2: "Level 2: Square Area & Sides",
	3: "Level 3: Triangle Angles (180°)",
	4: "Level 4: Straight & Full Turns",
	5: "Level 5: Right Triangle Area",
	6: "Level 6: Cube & Box Volume",
	7: "Level 7: Polygon Perimeters",
	8: "Level 8: Master Space Geometry",
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, GameState.MAX_ACTIVITY_TIER), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped: int = clampi(tier, 1, GameState.MAX_ACTIVITY_TIER)
	match clamped:
		1:
			return _gen_counting_sides()
		2:
			return _gen_square_area_or_perim()
		3:
			return _gen_triangle_angle()
		4:
			return _gen_turn_angles()
		5:
			return _gen_triangle_area()
		6:
			return _gen_box_volume(6, 2, 6)
		7:
			return _gen_polygon_perimeter()
		8:
			if randi() % 2 == 0:
				return _gen_box_volume(8, 4, 9)
			return _gen_triangle_area(8)
	return _gen_counting_sides()


static func _gen_counting_sides() -> MathQuestion:
	var shapes: Array[Dictionary] = [
		{"name": "triangle", "sides": 3},
		{"name": "square", "sides": 4},
		{"name": "pentagon", "sides": 5},
		{"name": "hexagon", "sides": 6},
		{"name": "octagon", "sides": 8},
	]
	var pick: Dictionary = shapes[randi() % shapes.size()]
	var sides: int = int(pick["sides"])
	var count: int = randi_range(2, 6)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "geom"
	q.tier = 1
	q.group_count = clampi(count, 1, 5)
	q.visual_icon_path = ROCKET_ICON
	q.visual_badge_text = "%d %ss (%d sides each)" % [count, str(pick["name"]), sides]
	q.correct_answer = count * sides
	q.prompt = "A %s has %d sides. How many sides do %d %ss have altogether?" % [
		str(pick["name"]), sides, count, str(pick["name"])
	]
	q.expression_text = "%d  ×  %d  =  ?" % [count, sides]
	q.hint_text = "Tip: Multiply %d shapes × %d sides each!" % [count, sides]
	return q


static func _gen_square_area_or_perim() -> MathQuestion:
	var side: int = randi_range(3, 12)
	var q: MathQuestion = MathQuestion.new()
	q.operation = "geom"
	q.tier = 2
	q.group_count = 4
	q.visual_icon_path = ROCKET_ICON

	if randi() % 2 == 0:
		q.visual_badge_text = "Square: %dm × %dm" % [side, side]
		q.correct_answer = side * side
		q.prompt = "A square launch pad is %dm on each side. What is its area (in sq m)?" % side
		q.expression_text = "%d  ×  %d  =  ?" % [side, side]
		q.hint_text = "Tip: Area of a square = side × side (%d × %d)!" % [side, side]
	else:
		q.visual_badge_text = "Square: 4 sides of %dm" % side
		q.correct_answer = side * 4
		q.prompt = "A square launch pad has %dm sides. What is its total perimeter?" % side
		q.expression_text = "4  ×  %d  =  ?" % side
		q.hint_text = "Tip: All 4 sides of a square are equal, so do 4 × %d!" % side
	return q


static func _gen_triangle_angle() -> MathQuestion:
	var a: int = randi_range(3, 8) * 10
	var b: int = randi_range(3, 12 - (a / 10)) * 10
	var ans: int = 180 - a - b

	var q: MathQuestion = MathQuestion.new()
	q.operation = "geom"
	q.tier = 3
	q.group_count = 3
	q.visual_icon_path = ROCKET_ICON
	q.visual_badge_text = "Triangle angles = 180°"
	q.correct_answer = ans
	q.prompt = "A triangle has angles of %d° and %d°. How many degrees is the third angle?" % [a, b]
	q.expression_text = "180  -  %d  -  %d  =  ?" % [a, b]
	q.hint_text = "Tip: All 3 angles in a triangle add up to 180°! First add %d + %d = %d, then 180 - %d." % [
		a, b, a + b, a + b
	]
	return q


static func _gen_turn_angles() -> MathQuestion:
	var q: MathQuestion = MathQuestion.new()
	q.operation = "geom"
	q.tier = 4
	q.group_count = 2
	q.visual_icon_path = ROCKET_ICON

	if randi() % 2 == 0:
		var a: int = randi_range(25, 145)
		q.visual_badge_text = "Straight line = 180°"
		q.correct_answer = 180 - a
		q.prompt = "Two angles form a straight line (180°). One is %d°. What is the other?" % a
		q.expression_text = "180  -  %d  =  ?" % a
		q.hint_text = "Tip: A straight line is 180°! Subtract %d from 180." % a
	else:
		var a: int = randi_range(60, 280)
		q.visual_badge_text = "Full circle = 360°"
		q.correct_answer = 360 - a
		q.prompt = "A rocket turns %d° out of a full 360° circle. How many degrees remain?" % a
		q.expression_text = "360  -  %d  =  ?" % a
		q.hint_text = "Tip: A full spin is 360°! Count up from %d to 360." % a
	return q


static func _gen_triangle_area(tier_num: int = 5) -> MathQuestion:
	var base: int = randi_range(2, 9) * 2
	var height: int = randi_range(3, 14) if tier_num == 5 else randi_range(8, 22)
	var ans: int = (base * height) / 2

	var q: MathQuestion = MathQuestion.new()
	q.operation = "geom"
	q.tier = tier_num
	q.group_count = 3
	q.visual_icon_path = ROCKET_ICON
	q.visual_badge_text = "Area = (base × height) ÷ 2"
	q.correct_answer = ans
	q.prompt = "A rocket fin is a triangle with base %dm and height %dm. What is its area?" % [base, height]
	q.expression_text = "(%d × %d)  ÷  2  =  ?" % [base, height]
	q.hint_text = "Tip: Half the base (%d ÷ 2 = %d), then multiply by height %d!" % [base, base / 2, height]
	return q


static func _gen_box_volume(tier_num: int, min_s: int, max_s: int) -> MathQuestion:
	var l: int = randi_range(min_s, max_s)
	var w: int = randi_range(min_s, max_s)
	var h: int = randi_range(min_s, max_s)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "geom"
	q.tier = tier_num
	q.group_count = 3
	q.visual_icon_path = ROCKET_ICON
	q.visual_badge_text = "Volume = L × W × H"
	q.correct_answer = l * w * h
	q.prompt = "A cargo box measures %d × %d × %d cubes. How many unit cubes fit inside?" % [l, w, h]
	q.expression_text = "%d  ×  %d  ×  %d  =  ?" % [l, w, h]
	q.hint_text = "Tip: Multiply %d × %d = %d first, then multiply by %d!" % [l, w, l * w, h]
	return q


static func _gen_polygon_perimeter() -> MathQuestion:
	var sides: int = [5, 6, 8, 10][randi() % 4]
	var names: Dictionary = {5: "pentagon", 6: "hexagon", 8: "octagon", 10: "decagon"}
	var length: int = randi_range(12, 45)
	var ans: int = sides * length

	var q: MathQuestion = MathQuestion.new()
	q.operation = "geom"
	q.tier = 7
	q.group_count = 5
	q.visual_icon_path = ROCKET_ICON
	q.visual_badge_text = "Regular %s (%d sides)" % [str(names[sides]), sides]
	q.correct_answer = ans
	q.prompt = "A regular %s has %d equal sides of %dm each. What is its perimeter?" % [
		str(names[sides]), sides, length
	]
	q.expression_text = "%d  ×  %d  =  ?" % [sides, length]
	q.hint_text = "Tip: Multiply %d sides × %dm!" % [sides, length]
	return q
