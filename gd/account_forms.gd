extends Panel

# ---- UI ----
@onready var account_forms: Panel = $"."
@onready var sign_in_form: TextureRect = $sign_in
@onready var sign_up_form: TextureRect = $sign_up

@onready var in_username_input: LineEdit = $sign_in/form/username/input
@onready var in_password_input: LineEdit = $sign_in/form/password/input
@onready var in_error: Label = $sign_in/error
@onready var in_button: TextureButton = $sign_in/button

@onready var up_username_input: LineEdit = $sign_up/form/username/input
@onready var up_password_input: LineEdit = $sign_up/form/password/input
@onready var up_error: Label = $sign_up/error
@onready var up_button: TextureButton = $sign_up/button


# ---- Переменные ----
var db: SQLiteHelper
var api: Website_API = Website_API


func _ready():
	in_error.hide()
	up_error.hide()
	
	api.login_completed.connect(_on_login_completed)
	api.register_completed.connect(_on_register_completed)
	
	db = SQLiteHelper.new()
	
	if not db.create_client_table():
		push_error("Ошибка при создании таблицы client: " + db.db.error_message)
		return
	
	var client: Dictionary = exist_client_in_db()
	print('client {0}'.format([client['details']]))
	
	if client["status"] == 0:
		account_forms.hide()
	
	db.close_database()


# ------ Проверки -------
## Проверка на существование данных матча
func exist_client_in_db() -> Dictionary:
	var check_query = "SELECT name FROM sqlite_master WHERE type='table' AND name='client'"
	
	if not db.db.query(check_query):
		return {
			"status": -3,
			"details": "Ошибка проверки таблицы"
		}
	
	if db.db.query_result.is_empty():
		return {
			"status": -2,
			"details": "Таблица client не найдена"
		}
	
	var result = db.get_all_records("client")
	print('result.size(): ', result.size())
	
	if result.size() <= 0:
		return {
			"status": -1,
			"details": "client не авторизирован"
		}
	
	return {
		"status": 0,
		"details": "client авторизирован"
	}


# ----- Кнопки ------
## Запуск авторизации
func _on_in_button_pressed() -> void:
	# Сбрасываем override цвета
	in_error.add_theme_color_override("font_color", Color.RED)
	in_username_input.remove_theme_color_override("font_color")
	in_password_input.remove_theme_color_override("font_color")
	in_username_input.remove_theme_stylebox_override("normal")
	in_password_input.remove_theme_stylebox_override("normal")
	
	var has_error = false
	
	if in_username_input.text == '':
		# Создаем новый StyleBox для фона
		var error_stylebox = StyleBoxFlat.new()
		error_stylebox.bg_color = Color(255, 0, 37, 225)
		error_stylebox.content_margin_left = 5
		error_stylebox.content_margin_right = 5
		
		in_username_input.add_theme_stylebox_override("normal", error_stylebox)
		in_username_input.add_theme_color_override("font_color", Color.WHITE)  # Белый текст
		in_error.text = 'Ошибка: Введите ник.'
		has_error = true
	
	elif in_password_input.text == '':
		var error_stylebox = StyleBoxFlat.new()
		error_stylebox.bg_color = Color(255, 0, 37, 225)
		error_stylebox.content_margin_left = 5
		error_stylebox.content_margin_right = 5
		
		in_password_input.add_theme_stylebox_override("normal", error_stylebox)
		in_password_input.add_theme_color_override("font_color", Color.WHITE)  # Белый текст
		in_error.text = 'Ошибка: Введите Пароль.'
		has_error = true
	
	if has_error:
		in_error.show()
		return
	else:
		in_error.hide()
	
	if not api.login_user(in_username_input.text, in_password_input.text):
		in_error.text = 'Ошибка при отправке запроса'
		has_error = true
	
	in_error.show()
	
	if has_error:
		return
	else:
		in_error.add_theme_color_override("font_color", Color.YELLOW)
		in_error.text = 'Ожидайте...'
		in_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Запуск регистрации
func _on_up_button_pressed() -> void:
	# Сбрасываем override цвета
	up_error.add_theme_color_override("font_color", Color.RED)
	up_username_input.remove_theme_color_override("font_color")
	up_password_input.remove_theme_color_override("font_color")
	up_username_input.remove_theme_stylebox_override("normal")
	up_password_input.remove_theme_stylebox_override("normal")
	
	var has_error = false
	
	if up_username_input.text == '':
		# Создаем новый StyleBox для фона
		var error_stylebox = StyleBoxFlat.new()
		error_stylebox.bg_color = Color(255, 0, 37, 225)
		error_stylebox.content_margin_left = 5
		error_stylebox.content_margin_right = 5
		
		up_username_input.add_theme_stylebox_override("normal", error_stylebox)
		up_username_input.add_theme_color_override("font_color", Color.WHITE)  # Белый текст
		up_error.text = 'Ошибка: Введите ник.'
		has_error = true
	
	elif up_password_input.text == '':
		var error_stylebox = StyleBoxFlat.new()
		error_stylebox.bg_color = Color(255, 0, 37, 225)
		error_stylebox.content_margin_left = 5
		error_stylebox.content_margin_right = 5
		
		up_password_input.add_theme_stylebox_override("normal", error_stylebox)
		up_password_input.add_theme_color_override("font_color", Color.WHITE)  # Белый текст
		up_error.text = 'Ошибка: Введите Пароль.'
		has_error = true
	
		# Проверка длины пароля (минимум 8 символов)
	elif up_password_input.text.length() < 8:
		var error_stylebox = StyleBoxFlat.new()
		error_stylebox.bg_color = Color(255, 0, 37, 225)
		error_stylebox.content_margin_left = 5
		error_stylebox.content_margin_right = 5
		
		up_password_input.add_theme_stylebox_override("normal", error_stylebox)
		up_password_input.add_theme_color_override("font_color", Color.WHITE)  # Белый текст
		up_error.text = 'Пароль должен содержать минимум 8 символов.'
		has_error = true
	
	if has_error:
		up_error.show()
		return
	else:
		up_error.hide()
	
	if not api.register_user(up_username_input.text, up_password_input.text):
		up_error.text = 'Ошибка при отправке запроса'
		has_error = true
	
	up_error.show()
	
	if has_error:
		return
	else:
		up_error.add_theme_color_override("font_color", Color.YELLOW)
		up_error.text = 'Ожидайте...'
		up_button.mouse_filter = Control.MOUSE_FILTER_IGNORE

## Перейти в регистрацию
func _on_sign_up_open_pressed() -> void:
	sign_in_form.hide()
	sign_up_form.show()

## Перейти в авторизацию
func _on_sign_in_open_pressed() -> void:
	sign_up_form.hide()
	sign_in_form.show()

# ----- Обработчик -----
## Обработчик ответа входа в аккаунт
func _on_login_completed(response_data: Dictionary):
	if response_data["success"]:
		in_error.text = "Успешный вход в аккаунт!"
		in_error.add_theme_color_override("font_color", Color.GREEN)
		await get_tree().create_timer(0.01).timeout
		
		db = SQLiteHelper.new()
		var client = create_client(in_username_input.text, in_password_input.text)
		db.close_database()
		
		if client['status'] != 'go':
			return
		
		account_forms.hide()
	else:
		in_error.text = "Не правильный Username или Password"
		in_error.add_theme_color_override("font_color", Color.RED)
	in_error.show()
	in_button.mouse_filter = Control.MOUSE_FILTER_STOP

## Обработчик ответа регистрации
func _on_register_completed(response_data: Dictionary):
	if response_data["success"]:
		up_error.text = "Успешная регистрация!"
		up_error.add_theme_color_override("font_color", Color.GREEN)
		# Автоматически переключаем на форму входа после успешной регистрации
		await get_tree().create_timer(1.5).timeout
		sign_up_form.hide()
		sign_in_form.show()
		up_error.hide()
	else:
		if response_data["response_code"] == 400:
			up_error.text = "Пользователь с таким именем уже существует"
			await get_tree().create_timer(1.5).timeout
		else:
			up_error.text = "Ошибка при регистрации"
		up_error.add_theme_color_override("font_color", Color.RED)
	up_error.show()
	up_button.mouse_filter = Control.MOUSE_FILTER_STOP


# ---- Создание клиента -----
## Создает запись клиента
func create_client(username: String, password: String):
	var start = Time.get_ticks_usec()
	var client = {
		'username': username,
		'password': password
	}
	
	if not db.create_record('client', client):
		push_error("Ошибка при создании client {0}: {1}".format([ username, db.db.error_message ]))
		print("Время create_client: %d мкс" % (Time.get_ticks_usec() - start))
		return {'status': 'error'}
	else:
		#print('Бот успешно создан: ', username_bot)
		client['id'] = db.get_last_insert_id()
		print("Время create_client: %d мкс" % (Time.get_ticks_usec() - start))
		return {'status': 'go', 'record': client}
