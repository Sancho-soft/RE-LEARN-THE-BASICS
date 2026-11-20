# res://scripts/math/number_forge_question_generator.gd
# Activity 10: Number Forge — Buffed Base-10 Abacus & multi-step challenges across 8 tiers.
class_name NumberForgeQuestionGenerator
extends RefCounted

const FORGE_ICON: String = "res://assets/art/activity_forge.svg"

const TIER_NAMES: Dictionary = {
	1: "Level 1: Place-Value Forge",
	2: "Level 2: Chained Jumps",
	3: "Level 3: Triple-Step Combos",
	4: "Level 4: Bracket Multipliers",
	5: "Level 5: Percent & Fraction Mix",
	6: "Level 6: Double & Inverse Riddles",
	7: "Level 7: Grand Bracket Equations",
	8: "Level 8: Master Forge Finale",
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, GameState.MAX_ACTIVITY_TIER), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped: int = clampi(tier, 1, GameState.MAX_ACTIVITY_TIER)
	match clamped:
		1:
			return _gen_place_value()
		2:
			return _gen_chained_jumps()
		3:
			return _gen_triple_combos()
		4:
			return _gen_bracket_mult()
		5:
			return _gen_pct_frac_mix()
		6:
			return _gen_inverse_riddle()
		7:
			return _gen_grand_brackets()
		8:
			return _gen_master_finale()
	return _gen_place_value()


static func _gen_place_value() -> MathQuestion:
	var h: int = randi_range(1, 7)
	var t: int = randi_range(1, 9)
	var o: int = randi_range(1, 9)
	var q: MathQuestion = MathQuestion.new()
	q.operation = "forge"
	q.tier = 1
	q.group_count = 3
	q.visual_icon_path = FORGE_ICON
	q.visual_badge_text = "%d hundreds + %d tens + %d ones" % [h, t, o]
	q.correct_answer = h * 100 + t * 10 + o
	q.prompt = "Set the abacus beads to forge %d hundreds, %d tens, and %d ones!" % [h, t, o]
	q.expression_text = "%d00 + %d0 + %d  =  ?" % [h, t, o]
	q.hint_text = "Tip: Dial %d on 100s, %d on 10s, and %d on 1s!" % [h, t, o]
	return q


static func _gen_chained_jumps() -> MathQuestion:
	var a: int = randi_range(45, 180)
	var b: int = randi_range(35, 140)
	var c: int = randi_range(15, 65)
	var q: MathQuestion = MathQuestion.new()
	q.operation = "forge"
	q.tier = 2
	q.group_count = 3
	q.visual_icon_path = FORGE_ICON
	q.visual_badge_text = "Two-Step Chain"
	q.correct_answer = (a + b) - c
	q.prompt = "Add %d + %d first, then take away %d!" % [a, b, c]
	q.expression_text = "(%d + %d) - %d  =  ?" % [a, b, c]
	q.hint_text = "Tip: %d + %d = %d, then subtract %d!" % [a, b, a + b, c]
	return q


static func _gen_triple_combos() -> MathQuestion:
	var a: int = randi_range(6, 12)
	var b: int = randi_range(5, 11)
	var c: int = randi_range(4, 10)
	var d: int = randi_range(4, 10)
	var e: int = randi_range(12, 48)
	var q: MathQuestion = MathQuestion.new()
	q.operation = "order"
	q.tier = 3
	q.group_count = 4
	q.visual_icon_path = FORGE_ICON
	q.visual_badge_text = "Multiply, then Add All"
	q.correct_answer = (a * b) + (c * d) + e
	q.prompt = "Forge all three parts into one final bead total!"
	q.expression_text = "(%d × %d) + (%d × %d) + %d  =  ?" % [a, b, c, d, e]
	q.hint_text = "Tip: %d + %d = %d, plus %d!" % [a * b, c * d, a * b + c * d, e]
	return q


static func _gen_bracket_mult() -> MathQuestion:
	var mult: int = randi_range(7, 16)
	var a: int = randi_range(8, 22)
	var b: int = randi_range(6, 18)
	var q: MathQuestion = MathQuestion.new()
	q.operation = "order"
	q.tier = 4
	q.group_count = 3
	q.visual_icon_path = FORGE_ICON
	q.visual_badge_text = "Brackets First!"
	q.correct_answer = mult * (a + b)
	q.prompt = "Add inside the brackets first, then multiply by %d!" % mult
	q.expression_text = "%d × (%d + %d)  =  ?" % [mult, a, b]
	q.hint_text = "Tip: %d + %d = %d, then multiply %d × %d!" % [a, b, a + b, mult, a + b]
	return q


static func _gen_pct_frac_mix() -> MathQuestion:
	var pct_choices: Array[Dictionary] = [
		{"pct": 25, "base": 160, "val": 40},
		{"pct": 25, "base": 240, "val": 60},
		{"pct": 50, "base": 180, "val": 90},
		{"pct": 20, "base": 250, "val": 50},
		{"pct": 30, "base": 200, "val": 60},
	]
	var p: Dictionary = pct_choices[randi() % pct_choices.size()]
	var denom: int = [3, 4, 5, 6][randi() % 4]
	var unit: int = randi_range(15, 45)
	var whole: int = denom * unit
	var pct_val: int = int(p["val"])
	var q: MathQuestion = MathQuestion.new()
	q.operation = "pct"
	q.tier = 5
	q.group_count = 3
	q.visual_icon_path = FORGE_ICON
	q.visual_badge_text = "Percent + Fraction Mix!"
	q.correct_answer = pct_val + unit
	q.prompt = "Combine %d%% of %d with 1/%d of %d!" % [int(p["pct"]), int(p["base"]), denom, whole]
	q.expression_text = "(%d%% of %d) + (1/%d of %d)  =  ?" % [int(p["pct"]), int(p["base"]), denom, whole]
	q.hint_text = "Tip: %d%% of %d = %d, and 1/%d of %d = %d. Add them!" % [
		int(p["pct"]), int(p["base"]), pct_val, denom, whole, unit
	]
	return q


static func _gen_inverse_riddle() -> MathQuestion:
	var ans: int = randi_range(28, 165)
	var mult: int = randi_range(3, 5)
	var add_v: int = randi_range(18, 75)
	var result: int = ans * mult + add_v
	var q: MathQuestion = MathQuestion.new()
	q.operation = "algebra"
	q.tier = 6
	q.group_count = 4
	q.visual_icon_path = FORGE_ICON
	q.visual_badge_text = "Work Backwards Riddle"
	q.correct_answer = ans
	q.prompt = "Think of a number, multiply by %d, add %d, and get %d. What number?" % [mult, add_v, result]
	q.expression_text = "(? × %d) + %d  =  %d" % [mult, add_v, result]
	q.hint_text = "Tip: Undo +%d first (%d - %d = %d), then divide by %d!" % [
		add_v, result, add_v, result - add_v, mult
	]
	return q


static func _gen_grand_brackets() -> MathQuestion:
	var mult: int = randi_range(12, 22)
	var a: int = randi_range(12, 24)
	var b: int = randi_range(8, 16)
	var sub_v: int = randi_range(25, 95)
	var q: MathQuestion = MathQuestion.new()
	q.operation = "order"
	q.tier = 7
	q.group_count = 4
	q.visual_icon_path = FORGE_ICON
	q.visual_badge_text = "Grand Bracket Lock"
	q.correct_answer = mult * (a + b) - sub_v
	q.prompt = "Add inside the brackets, multiply by %d, then subtract %d!" % [mult, sub_v]
	q.expression_text = "%d × (%d + %d) - %d  =  ?" % [mult, a, b, sub_v]
	q.hint_text = "Tip: %d + %d = %d → ×%d = %d → -%d!" % [
		a, b, a + b, mult, mult * (a + b), sub_v
	]
	return q


static func _gen_master_finale() -> MathQuestion:
	var setups: Array[Dictionary] = [
		{"text": "2 × (45 + 35) + 50% of 240 = ?", "prompt": "Final Forge! Combine bracket doubles and 50% of 240.", "ans": 280, "tip": "2 × 80 = 160, plus half of 240 (120)!"},
		{"text": "(3/4 of 240) + (4 × 65) = ?", "prompt": "Final Forge! Add 3/4 of 240 and 4 × 65.", "ans": 440, "tip": "3/4 of 240 = 180, plus 260 = 440!"},
		{"text": "(600 - 25%) + (12 × 14) = ?", "prompt": "Final Forge! Take 25% off 600, then add 12 × 14.", "ans": 618, "tip": "600 - 150 = 450, plus 168 = 618!"},
		{"text": "Ratio 2:3:5 (first=64) + 1/2 of 320 = ?", "prompt": "Final Forge! Find the 3-basket total plus half of 320.", "ans": 480, "tip": "1 share = 32, total 10 shares = 320, plus 160 = 480!"},
		{"text": "Avg of (140, 180, 220, ?) = 200 → ?", "prompt": "Final Forge! Find the 4th day needed for an average of 200.", "ans": 260, "tip": "Total must be 4 × 200 = 800. Subtract 140+180+220 (540)!"},
		{"text": "(18 × 25) + (15% of 400) = ?", "prompt": "Final Forge! Multiply 18 × 25, then add 15% of 400.", "ans": 510, "tip": "18 × 25 = 450, and 15% of 400 = 60!"},
	]
	var pick: Dictionary = setups[randi() % setups.size()]
	var q: MathQuestion = MathQuestion.new()
	q.operation = "order"
	q.tier = 8
	q.group_count = 5
	q.visual_icon_path = FORGE_ICON
	q.visual_badge_text = "Master Architect Finale"
	q.correct_answer = int(pick["ans"])
	q.prompt = str(pick["prompt"])
	q.expression_text = str(pick["text"])
	q.hint_text = "Tip: " + str(pick["tip"])
	return q
