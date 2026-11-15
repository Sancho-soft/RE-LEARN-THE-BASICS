# res://scripts/math/shop_question_generator.gd
# Generates addition & subtraction shop questions across a 4-tier difficulty ladder.
class_name ShopQuestionGenerator
extends RefCounted

const ITEMS: Array[Dictionary] = [
	{"name": "Apple", "icon": "res://assets/art/items/apple.svg"},
	{"name": "Bread Bun", "icon": "res://assets/art/items/bread.svg"},
	{"name": "Milk", "icon": "res://assets/art/items/milk.svg"},
	{"name": "Pencil", "icon": "res://assets/art/items/pencil.svg"},
	{"name": "Notebook", "icon": "res://assets/art/items/notebook.svg"},
	{"name": "Juice", "icon": "res://assets/art/items/juice.svg"},
]

const TIER_NAMES: Dictionary = {
	1: "Level 1: Sums to 10",
	2: "Level 2: Sums to 20",
	3: "Level 3: Making Change",
	4: "Level 4: Big Shop (to 100)",
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, 4), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped_tier: int = clampi(tier, 1, 4)
	match clamped_tier:
		1:
			return _gen_addition_to_10()
		2:
			return _gen_addition_to_20()
		3:
			if randi() % 2 == 0:
				return _gen_subtraction_change(20)
			return _gen_addition_to_20(3)
		4:
			if randi() % 2 == 0:
				return _gen_addition_to_100()
			return _gen_subtraction_change(100)
	return _gen_addition_to_10()


static func _pick_two_items() -> Array[Dictionary]:
	var pool: Array[Dictionary] = ITEMS.duplicate()
	pool.shuffle()
	return [pool[0], pool[1]]


static func _gen_addition_to_10() -> MathQuestion:
	var pair: Array[Dictionary] = _pick_two_items()
	var a: int = randi_range(1, 7)
	var b: int = randi_range(1, 10 - a)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "add"
	q.tier = 1
	q.left_label = str(pair[0]["name"])
	q.left_price = a
	q.left_icon_path = str(pair[0]["icon"])
	q.right_label = str(pair[1]["name"])
	q.right_price = b
	q.right_icon_path = str(pair[1]["icon"])
	q.correct_answer = a + b
	q.prompt = "May I buy a %s and a %s, please?" % [q.left_label, q.right_label]
	q.expression_text = "₱%d  +  ₱%d  =  ?" % [a, b]

	var big: int = maxi(a, b)
	var small: int = mini(a, b)
	var steps: PackedStringArray = []
	for step: int in range(1, small + 1):
		steps.append(str(big + step))
	q.hint_text = "Tip: Start at %d and count up %d: %s!" % [big, small, ", ".join(steps)]
	return q


static func _gen_addition_to_20(tier_override: int = 2) -> MathQuestion:
	var pair: Array[Dictionary] = _pick_two_items()
	var a: int = randi_range(5, 13)
	var b: int = randi_range(3, mini(9, 20 - a))

	var q: MathQuestion = MathQuestion.new()
	q.operation = "add"
	q.tier = tier_override
	q.left_label = str(pair[0]["name"])
	q.left_price = a
	q.left_icon_path = str(pair[0]["icon"])
	q.right_label = str(pair[1]["name"])
	q.right_price = b
	q.right_icon_path = str(pair[1]["icon"])
	q.correct_answer = a + b
	q.prompt = "I'd love a %s and a %s! What's my total?" % [q.left_label, q.right_label]
	q.expression_text = "₱%d  +  ₱%d  =  ?" % [a, b]

	var big: int = maxi(a, b)
	var small: int = mini(a, b)
	if big < 10 and big + small > 10:
		var need_for_10: int = 10 - big
		var leftover: int = small - need_for_10
		q.hint_text = "Tip: Make 10 first! %d + %d = 10, then add %d more." % [big, need_for_10, leftover]
	else:
		q.hint_text = "Tip: Start at %d and count up %d steps." % [big, small]
	return q


static func _gen_addition_to_100() -> MathQuestion:
	var pair: Array[Dictionary] = _pick_two_items()
	var a: int = randi_range(14, 58)
	var b: int = randi_range(12, mini(39, 99 - a))

	var q: MathQuestion = MathQuestion.new()
	q.operation = "add"
	q.tier = 4
	q.left_label = str(pair[0]["name"])
	q.left_price = a
	q.left_icon_path = str(pair[0]["icon"])
	q.right_label = str(pair[1]["name"])
	q.right_price = b
	q.right_icon_path = str(pair[1]["icon"])
	q.correct_answer = a + b
	q.prompt = "Two big items today: %s and %s! How much altogether?" % [q.left_label, q.right_label]
	q.expression_text = "₱%d  +  ₱%d  =  ?" % [a, b]

	var tens_a: int = (a / 10) * 10
	var ones_a: int = a % 10
	var tens_b: int = (b / 10) * 10
	var ones_b: int = b % 10
	q.hint_text = "Tip: Add tens (%d + %d = %d), then add ones (%d + %d = %d)!" % [
		tens_a, tens_b, tens_a + tens_b, ones_a, ones_b, ones_a + ones_b
	]
	return q


static func _gen_subtraction_change(max_paid: int) -> MathQuestion:
	var pair: Array[Dictionary] = _pick_two_items()
	var paid: int = 10
	var price: int = 4

	if max_paid <= 20:
		var budgets: Array[int] = [10, 12, 15, 20]
		paid = budgets[randi() % budgets.size()]
		price = randi_range(2, paid - 1)
	else:
		var big_budgets: Array[int] = [30, 40, 50, 100]
		paid = big_budgets[randi() % big_budgets.size()]
		price = randi_range(11, paid - 5)

	var q: MathQuestion = MathQuestion.new()
	q.operation = "sub"
	q.tier = 3 if max_paid <= 20 else 4
	q.paid_amount = paid
	q.left_label = str(pair[0]["name"])
	q.left_price = price
	q.left_icon_path = str(pair[0]["icon"])
	q.correct_answer = paid - price
	q.prompt = "Here is ₱%d for the %s (₱%d). What's my change?" % [paid, q.left_label, price]
	q.expression_text = "₱%d  -  ₱%d  =  ?" % [paid, price]

	if paid <= 20:
		q.hint_text = "Tip: Start at %d and count up until you reach %d!" % [price, paid]
	else:
		var tens_diff: int = (paid / 10) * 10 - (price / 10) * 10
		q.hint_text = "Tip: Think %d take away %d — try counting up from %d to %d (about %d tens)." % [
			paid, price, price, paid, maxi(1, tens_diff / 10)
		]
	return q
