extends Control

@onready var sceneName = CurrentData.loading_map
@onready var loading_text: Label = $MarginContainer/Loading/loading_text
@onready var loading_tip: Label = $MarginContainer/Loading/loading_tip
@onready var progress_bar: ProgressBar = $MarginContainer/Loading/ProgressBar

var load_percentage: float = 0.0
var fake_load_speed: float = 50.0  # % в секунду
var min_loading_time: float = 2.0  # Минимум 2 секунды загрузки
var loading_start_time: float = 0.0
var has_real_loading_finished: bool = false

func _ready():
	loading_tip.text = 'Совет: 1 игровой месяц = 1 реальная минута'
	loading_start_time = Time.get_ticks_msec() / 1000.0
	ResourceLoader.load_threaded_request(sceneName[1])

func _process(delta):
	var progress = []
	var load_status = ResourceLoader.load_threaded_get_status(sceneName[1], progress)
	
	# Если загрузка завершена, отмечаем это
	if load_status == ResourceLoader.THREAD_LOAD_LOADED:
		has_real_loading_finished = true
	
	# Искусственная загрузка (но не больше 97%)
	if load_percentage < 97.0:
		load_percentage += fake_load_speed * delta
		load_percentage = min(load_percentage, 97.0)
		loading_text.text = 'LOADING ' + str(int(load_percentage)) + '%'
		progress_bar.value = load_percentage
	
	# Если реальная загрузка завершена И прошло минимум времени
	var current_time = Time.get_ticks_msec() / 1000.0
	if has_real_loading_finished and (current_time - loading_start_time >= min_loading_time):
		get_node("/root/handler").queue_free()
		MyButtons.open_page(sceneName)
