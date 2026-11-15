# res://scripts/math/sharing_question_generator.gd
# Generates Division, Fractions & Ratio questions for Fair Sharing.
class_name SharingQuestionGenerator
extends RefCounted

const COOKIE_ICON: String = "res://assets/art/treat_cookie.svg"
const BERRY_ICON: String = "res://assets/art/treat_berry.svg"

const TIER_NAMES: Dictionary = {
	1: "Level 1: Equal Sharing (÷2 to ÷5)",
	2: "Level 2: Larger Division",
	3: "Level 3: Unit Fractions",
	4: "Level 4: Fractions & Ratios",
	5: "Level 5: Big Pack Division",
	6: "Level 6: Big Fractions",
	7: "Level 7: Banquet Ratios",
	8: "Level 8: Master Fairness",
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, GameState.MAX_ACTIVITY_TIER), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped: int = clampi(tier, 1, GameState.MAX_ACTIVITY_TIER)
	match clamped:
		1:
			return _gen_basic_division()
		2:
			return _gen_larger_division()
		3:
			return _gen_unit_fraction()
		4:
			if randi() % 2 == 0:
				return _gen_multi_fraction()
			return _gen_simple_ratio()
		5:
			return _gen_big_pack_division()
		6:
			return _gen_big_fractions()
		7:
			return _gen_banquet_ratio()
		8:
			if randi() % 2 == 0:
				return _gen_find_whole_from_fraction()
			return _gen_master_division()
	return _gen_basic_division()


static func _gen_basic_division() -> MathQuestion:
	var friends: int = randi_range(2, 5)
	var each: int = randi_range(2, 6)
	var total: int = friends * each

	var q: MathQuestion = MathQuestion.new()
	q.operation = "div"
	q.tier = 1
	q.group_count = friends
	q.items_per_group = each
	q.visual_icon_path = COOKIE_ICON
	q.visual_badge_text = "%d cookies ÷ %d friends" % [total, friends]
	q.correct_answer = each
	q.prompt = "Share %d cookies fairly among %d friends. How many does each friend get?" % [total, friends]
	q.expression_text = "%d  ÷  %d  =  ?" % [total, friends]
	q.hint_text = "Tip: Think %d × ? = %d — skip-count by %d up to %d!" % [friends, total, friends, total]
	return q


static func _gen_larger_division() -> MathQuestion:
	var baskets: int = randi_range(3, 9)
	var each: int = randi_range(3, 9)
	var total: int = baskets * each

	var q: MathQuestion = MathQuestion.new()
	q.operation = "div"
	q.tier = 2
	q.group_count = baskets
	q.items_per_group = each
	q.visual_icon_path = BERRY_ICON
	q.visual_badge_text = "%d berries ÷ %d baskets" % [total, baskets]
	q.correct_answer = each
	q.prompt = "Pack %d sweet berries equally into %d baskets. How many per basket?" % [total, baskets]
	q.expression_text = "%d  ÷  %d  =  ?" % [total, baskets]
	q.hint_text = "Tip: Ask yourself: what number times %d equals %d?" % [baskets, total]
	return q


static func _gen_unit_fraction() -> MathQuestion:
	var denom: int = [2, 3, 4, 5][randi() % 4]
	var part: int = randi_range(2, 7)
	var whole: int = denom * part

	var q: MathQuestion = MathQuestion.new()
	q.operation = "frac"
	q.tier = 3
	q.group_count = denom
	q.items_per_group = part
	q.visual_icon_path = COOKIE_ICON
	q.visual_badge_text = "1/%d of %d treats" % [denom, whole]
	q.correct_answer = part
	q.prompt = "What is 1/%d of a tray of %d treats?" % [denom, whole]
	q.expression_text = "1/%d  of  %d  =  ?" % [denom, whole]
	q.hint_text = "Tip: 1/%d means split %d into %d equal shares (%d ÷ %d)!" % [denom, whole, denom, whole, denom]
	return q


static func _gen_multi_fraction() -> MathQuestion:
	var denom: int = [3, 4, 5][randi() % 3]
	var numer: int = randi_range(2, denom - 1)
	var unit: int = randi_range(2, 6)
	var whole: int = denom * unit

	var q: MathQuestion = MathQuestion.new()
	q.operation = "frac"
	q.tier = 4
	q.group_count = denom
	q.items_per_group = unit
	q.visual_icon_path = BERRY_ICON
	q.visual_badge_text = "%d/%d of %d berries" % [numer, denom, whole]
	q.correct_answer = numer * unit
	q.prompt = "Bunny gets %d/%d of %d berries! How many berries is that?" % [numer, denom, whole]
	q.expression_text = "%d/%d  of  %d  =  ?" % [numer, denom, whole]
	q.hint_text = "Tip: First find 1/%d (%d ÷ %d = %d), then multiply by %d!" % [denom, whole, denom, unit, numer]
	return q


static func _gen_simple_ratio() -> MathQuestion:
	var cookies_per: int = randi_range(2, 4)
	var berries_per: int = randi_range(2, 5)
	if cookies_per == berries_per:
		berries_per += 1
	var scale: int = randi_range(2, 4)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "ratio"
	q.tier = 4
	q.group_count = scale
	q.items_per_group = berries_per
	q.visual_icon_path = BERRY_ICON
	q.visual_badge_text = "Ratio %d : %d" % [cookies_per, berries_per]
	q.correct_answer = berries_per * scale
	q.prompt = "For every %d cookies, a snack box has %d berries. With %d cookies, how many berries?" % [
		cookies_per, berries_per, cookies_per * scale
	]
	q.expression_text = "%d : %d  =  %d : ?" % [cookies_per, berries_per, cookies_per * scale]
	q.hint_text = "Tip: %d cookies is %d times %d, so multiply %d berries by %d!" % [
		cookies_per * scale, scale, cookies_per, berries_per, scale
	]
	return q


static func _gen_big_pack_division() -> MathQuestion:
	var baskets: int = randi_range(6, 12)
	var each: int = randi_range(6, 15)
	var total: int = baskets * each

	var q: MathQuestion = MathQuestion.new()
	q.operation = "div"
	q.tier = 5
	q.group_count = clampi(baskets, 1, 5)
	q.items_per_group = 0
	q.visual_icon_path = COOKIE_ICON
	q.visual_badge_text = "%d cookies ÷ %d boxes" % [total, baskets]
	q.correct_answer = each
	q.prompt = "Pack %d cookies evenly into %d gift boxes. How many cookies go in each box?" % [total, baskets]
	q.expression_text = "%d  ÷  %d  =  ?" % [total, baskets]
	q.hint_text = "Tip: Think %d × ? = %d — try %d × 10 = %d first!" % [baskets, total, baskets, baskets * 10]
	return q


static func _gen_big_fractions() -> MathQuestion:
	var denom: int = [4, 5, 6, 8, 10][randi() % 5]
	var numer: int = randi_range(2, denom - 1)
	var unit: int = randi_range(5, 16)
	var whole: int = denom * unit

	var q: MathQuestion = MathQuestion.new()
	q.operation = "frac"
	q.tier = 6
	q.group_count = clampi(denom, 1, 5)
	q.items_per_group = 0
	q.visual_icon_path = BERRY_ICON
	q.visual_badge_text = "%d/%d of %d berries" % [numer, denom, whole]
	q.correct_answer = numer * unit
	q.prompt = "Share %d/%d of %d berries for the pie! How many berries is that?" % [numer, denom, whole]
	q.expression_text = "%d/%d  of  %d  =  ?" % [numer, denom, whole]
	q.hint_text = "Tip: First find 1/%d (%d ÷ %d = %d), then multiply by %d!" % [denom, whole, denom, unit, numer]
	return q


static func _gen_banquet_ratio() -> MathQuestion:
	var cookies_per: int = randi_range(2, 6)
	var berries_per: int = randi_range(3, 8)
	if cookies_per == berries_per:
		berries_per += 1
	var scale: int = randi_range(5, 12)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "ratio"
	q.tier = 7
	q.group_count = 4
	q.items_per_group = 0
	q.visual_icon_path = BERRY_ICON
	q.visual_badge_text = "Ratio %d : %d" % [cookies_per, berries_per]
	q.correct_answer = berries_per * scale
	q.prompt = "A banquet tray pairs %d cookies with %d berries. With %d cookies, how many berries?" % [
		cookies_per, berries_per, cookies_per * scale
	]
	q.expression_text = "%d : %d  =  %d : ?" % [cookies_per, berries_per, cookies_per * scale]
	q.hint_text = "Tip: %d ÷ %d = %d batches, so multiply %d berries by %d!" % [
		cookies_per * scale, cookies_per, scale, berries_per, scale
	]
	return q


static func _gen_find_whole_from_fraction() -> MathQuestion:
	var denom: int = randi_range(3, 8)
	var part: int = randi_range(12, 45)
	var whole: int = denom * part

	var q: MathQuestion = MathQuestion.new()
	q.operation = "frac"
	q.tier = 8
	q.group_count = clampi(denom, 1, 5)
	q.items_per_group = 0
	q.visual_icon_path = COOKIE_ICON
	q.visual_badge_text = "1/%d = %d treats" % [denom, part]
	q.correct_answer = whole
	q.prompt = "1/%d of a giant cookie jar has %d treats. How many treats are in the whole jar?" % [denom, part]
	q.expression_text = "1/%d  of  ?  =  %d" % [denom, part]
	q.hint_text = "Tip: If 1 share out of %d is %d, multiply %d × %d!" % [denom, part, part, denom]
	return q


static func _gen_master_division() -> MathQuestion:
	var groups: int = randi_range(8, 15)
	var each: int = randi_range(12, 35)
	var total: int = groups * each

	var q: MathQuestion = MathQuestion.new()
	q.operation = "div"
	q.tier = 8
	q.group_count = 5
	q.items_per_group = 0
	q.visual_icon_path = BERRY_ICON
	q.visual_badge_text = "%d berries ÷ %d crates" % [total, groups]
	q.correct_answer = each
	q.prompt = "Divide %d harvest berries fairly into %d crates. How many in each crate?" % [total, groups]
	q.expression_text = "%d  ÷  %d  =  ?" % [total, groups]
	q.hint_text = "Tip: Check %d × 10 = %d, then see how many more groups of %d fit!" % [
		groups, groups * 10, groups
	]
	return q
