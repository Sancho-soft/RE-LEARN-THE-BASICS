# res://scripts/math/question.gd
# Data class representing a single math question for any activity.
class_name MathQuestion
extends RefCounted

var prompt: String = ""
var expression_text: String = ""
var correct_answer: int = 0
var hint_text: String = ""
var operation: String = "add" # "add", "sub", "mul", "div", "order", "pct", "frac", "ratio"
var tier: int = 1

# Visual item slots used by shop-style activities
var left_label: String = ""
var left_price: int = 0
var left_icon_path: String = ""

var right_label: String = ""
var right_price: int = 0
var right_icon_path: String = ""

var paid_amount: int = 0

# Visual grouping fields used by Doors, Builder, and Sharing activities
var group_count: int = 0
var items_per_group: int = 0
var visual_icon_path: String = ""
var visual_badge_text: String = ""
