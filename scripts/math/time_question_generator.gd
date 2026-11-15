# res://scripts/math/time_question_generator.gd
# Generates time conversion & elapsed duration questions across 8 tiers.
class_name TimeQuestionGenerator
extends RefCounted

const SUN_ICON: String = "res://assets/art/sun.svg"

const TIER_NAMES: Dictionary = {
	1: "Level 1: Hours to Minutes",
	2: "Level 2: Hours + Extra Minutes",
	3: "Level 3: Adding Minutes",
	4: "Level 4: Days & Weeks",
	5: "Level 5: Long Journeys",
	6: "Level 6: Minutes to Hours",
	7: "Level 7: Distance & Speed",
	8: "Level 8: Master Timekeeper",
}


static func get_tier_label(tier: int) -> String:
	return str(TIER_NAMES.get(clampi(tier, 1, GameState.MAX_ACTIVITY_TIER), "Level 1"))


static func generate(tier: int) -> MathQuestion:
	var clamped: int = clampi(tier, 1, GameState.MAX_ACTIVITY_TIER)
	match clamped:
		1:
			return _gen_hours_to_mins(1, 1, 4)
		2:
			return _gen_hours_plus_mins(2, 1, 3)
		3:
			return _gen_adding_minutes()
		4:
			return _gen_days_and_weeks()
		5:
			return _gen_hours_plus_mins(5, 4, 9)
		6:
			return _gen_mins_to_hours()
		7:
			return _gen_speed_distance()
		8:
			return _gen_master_time()
	return _gen_hours_to_mins(1, 1, 4)


static func _gen_hours_to_mins(tier_num: int, min_h: int, max_h: int) -> MathQuestion:
	var hrs: int = randi_range(min_h, max_h)
	var ans: int = hrs * 60

	var q: MathQuestion = MathQuestion.new()
	q.operation = "time"
	q.tier = tier_num
	q.group_count = clampi(hrs, 1, 5)
	q.visual_icon_path = SUN_ICON
	q.visual_badge_text = "1 hour = 60 minutes"
	q.correct_answer = ans
	q.prompt = "How many minutes are in %d hour%s?" % [hrs, "s" if hrs != 1 else ""]
	q.expression_text = "%d hr  ×  60  =  ? min" % hrs
	q.hint_text = "Tip: Every hour has 60 minutes, so multiply %d × 60!" % hrs
	return q


static func _gen_hours_plus_mins(tier_num: int, min_h: int, max_h: int) -> MathQuestion:
	var hrs: int = randi_range(min_h, max_h)
	var extra: int = [10, 15, 20, 30, 45][randi() % 5]
	var ans: int = hrs * 60 + extra

	var q: MathQuestion = MathQuestion.new()
	q.operation = "time"
	q.tier = tier_num
	q.group_count = clampi(hrs, 1, 5)
	q.visual_icon_path = SUN_ICON
	q.visual_badge_text = "%dh %dm → total mins" % [hrs, extra]
	q.correct_answer = ans
	q.prompt = "A sunny picnic lasts %d hour%s and %d minutes. How many minutes total?" % [
		hrs, "s" if hrs != 1 else "", extra
	]
	q.expression_text = "%d × 60  +  %d  =  ? min" % [hrs, extra]
	q.hint_text = "Tip: First %d × 60 = %d minutes, then add %d more!" % [hrs, hrs * 60, extra]
	return q


static func _gen_adding_minutes() -> MathQuestion:
	var m1: int = randi_range(15, 55)
	var m2: int = randi_range(15, 55)
	var ans: int = m1 + m2

	var q: MathQuestion = MathQuestion.new()
	q.operation = "time"
	q.tier = 3
	q.group_count = 2
	q.visual_icon_path = SUN_ICON
	q.visual_badge_text = "%d min + %d min" % [m1, m2]
	q.correct_answer = ans
	q.prompt = "Reading took %d minutes and drawing took %d minutes. How many minutes total?" % [m1, m2]
	q.expression_text = "%d  +  %d  =  ? min" % [m1, m2]
	q.hint_text = "Tip: Add the tens (%d + %d), then add the ones (%d + %d)!" % [
		(m1 / 10) * 10, (m2 / 10) * 10, m1 % 10, m2 % 10
	]
	return q


static func _gen_days_and_weeks() -> MathQuestion:
	var q: MathQuestion = MathQuestion.new()
	q.operation = "time"
	q.tier = 4
	q.visual_icon_path = SUN_ICON

	if randi() % 2 == 0:
		var weeks: int = randi_range(3, 12)
		var extra_days: int = randi_range(1, 6)
		q.group_count = clampi(weeks, 1, 5)
		q.visual_badge_text = "1 week = 7 days"
		q.correct_answer = weeks * 7 + extra_days
		q.prompt = "How many days are in %d weeks and %d days?" % [weeks, extra_days]
		q.expression_text = "%d × 7  +  %d  =  ? days" % [weeks, extra_days]
		q.hint_text = "Tip: 1 week is 7 days! Do %d × 7 = %d, then add %d." % [weeks, weeks * 7, extra_days]
	else:
		var days: int = randi_range(2, 6)
		q.group_count = days
		q.visual_badge_text = "1 day = 24 hours"
		q.correct_answer = days * 24
		q.prompt = "How many hours are in %d full days?" % days
		q.expression_text = "%d  ×  24  =  ? hrs" % days
		q.hint_text = "Tip: One day has 24 hours! Split 24 into 20 + 4: (%d × 20) + (%d × 4)." % [days, days]
	return q


static func _gen_mins_to_hours() -> MathQuestion:
	var hrs: int = randi_range(3, 14)
	var mins: int = hrs * 60

	var q: MathQuestion = MathQuestion.new()
	q.operation = "time"
	q.tier = 6
	q.group_count = 4
	q.visual_icon_path = SUN_ICON
	q.visual_badge_text = "60 minutes = 1 hour"
	q.correct_answer = hrs
	q.prompt = "Convert %d minutes into whole hours!" % mins
	q.expression_text = "%d  ÷  60  =  ? hrs" % mins
	q.hint_text = "Tip: Divide by 60 (or think %d ÷ 6)!" % [mins / 10]
	return q


static func _gen_speed_distance() -> MathQuestion:
	var speed: int = [12, 15, 20, 25, 30, 40][randi() % 6]
	var hours: int = randi_range(3, 8)
	var dist: int = speed * hours

	var q: MathQuestion = MathQuestion.new()
	q.operation = "time"
	q.tier = 7
	q.group_count = clampi(hours, 1, 5)
	q.visual_icon_path = SUN_ICON
	q.visual_badge_text = "%d km each hour" % speed
	q.correct_answer = dist
	q.prompt = "A cozy train travels %d km every hour. How far does it go in %d hours?" % [speed, hours]
	q.expression_text = "%d  ×  %d  =  ? km" % [speed, hours]
	q.hint_text = "Tip: Distance = speed × time! Multiply %d × %d." % [speed, hours]
	return q


static func _gen_master_time() -> MathQuestion:
	var q: MathQuestion = MathQuestion.new()
	q.operation = "time"
	q.tier = 8
	q.visual_icon_path = SUN_ICON

	if randi() % 2 == 0:
		var days: int = randi_range(4, 10)
		var extra_hrs: int = randi_range(2, 15)
		q.group_count = 4
		q.visual_badge_text = "%d days + %d hours" % [days, extra_hrs]
		q.correct_answer = days * 24 + extra_hrs
		q.prompt = "How many total hours are in %d days and %d hours?" % [days, extra_hrs]
		q.expression_text = "%d × 24  +  %d  =  ? hrs" % [days, extra_hrs]
		q.hint_text = "Tip: Multiply %d × 24 = %d hours, then add %d!" % [days, days * 24, extra_hrs]
	else:
		var speed: int = [35, 45, 50, 60, 75][randi() % 5]
		var hours: int = randi_range(4, 9)
		q.group_count = 5
		q.visual_badge_text = "%d km/h for %d hrs" % [speed, hours]
		q.correct_answer = speed * hours
		q.prompt = "An express train glides at %d km per hour for %d hours. Total km?" % [speed, hours]
		q.expression_text = "%d  ×  %d  =  ? km" % [speed, hours]
		q.hint_text = "Tip: Break %d into %d + %d and multiply each part by %d!" % [
			speed, (speed / 10) * 10, speed % 10, hours
		]
	return q
