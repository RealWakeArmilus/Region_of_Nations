extends VBoxContainer

@onready var fps_label = $FPS
@onready var cpu_label = $CPU
@onready var gpu_label = $GPU
@onready var mem_label: Label = $MEM


func _process(_delta):
	# Обновляем FPS (округление до целого)
	fps_label.text = "FPS: %d" % Engine.get_frames_per_second()
	
	# Нагрузка CPU (в %)
	var cpu_usage = Performance.get_monitor(Performance.TIME_PROCESS) * 100.0
	cpu_label.text = "CPU: %.1f%%" % cpu_usage
	
	# Память (в МБ)
	var mem = OS.get_static_memory_usage() / 1024.0 / 1024.0
	mem_label.text = "Memory: %.2f МБ" % mem


# ----------------
# Для управления
# ----------------


func _on_close_Debugger_pressed() -> void:
	$".".queue_free()
