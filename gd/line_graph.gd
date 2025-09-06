extends Control

@export var line_width := 700.0
@export var line_height := 10.0
@export var corner_radis = 5.0

var segments = [
	{"label": "work_market", "value": 400, "color": Color("#8B89B0")},
	{"label": "your_company", "value": 600, "color": Color("#B0B089")},
	{"label": "free_workers", "value": 30, "color": Color("#B0898A")},
	{"label": "active_workers", "value": 570, "color": Color("#89B091")}
]

func _draw():
	# Вычисляем общую сумму значений
	var total_segments_value = 0 
	for segment in segments:
		total_segments_value += segment['value']
	
	# Добавляем процент для каждого сегмента
	for i in range(segments.size()):
		segments[i]["percent"] = (segments[i]["value"] / float(total_segments_value)) * 100
	
	# Рисуем сегменты
	var current_x = 0.0
	for segment in segments:
		var segment_width = (segment["value"] / float(total_segments_value)) * line_width
		
		draw_rect(
			Rect2(current_x, 0, segment_width, line_height),
			segment["color"],
			true
		)
		current_x += segment_width

func _notification(what):
	if what == NOTIFICATION_RESIZED:
		queue_redraw()
