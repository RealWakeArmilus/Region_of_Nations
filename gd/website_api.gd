extends Node

@onready var http := HTTPRequest.new()
var max_retries: int = 3  # Максимум 3 попытки при ошибке 500
var current_retry: int = 0
var last_request_data: Dictionary = {}

func _ready():
	add_child(http)
	http.request_completed.connect(_on_request_completed)

## Запрос Регистрация, на сайт
func register_user(username: String, password: String) -> void:
	request_template('register', username, password)

## Запрос Логин, на сайт
func login_user(username: String, password: String) -> void:
	request_template('login', username, password)

## Ответ сервера
func _on_request_completed(_result, response_code, _headers, body):
	var response_text = body.get_string_from_utf8()
	var result_request: String
	
	if response_code == 500 and current_retry < max_retries:
		current_retry += 1
		print("Повторная попытка... (", current_retry, "/", max_retries, ")")
		await get_tree().create_timer(1.0).timeout  # Ждём 1 секунду
		if last_request_data.has("type"):
			match last_request_data["type"]:
				"register":
					register_user(last_request_data["body"]["username"], last_request_data["body"]["password"])
				"login":
					login_user(last_request_data["body"]["username"], last_request_data["body"]["password"])
	else:
		current_retry = 0  # Сбрасываем счётчик
		
		match response_code:
			200:
				result_request = "[Код]: {0};\n[Статус]: Успешно;\n[Ответ]: {1}".format([response_code, response_text])
			400:
				result_request = "[Код]: {0};\n[Ошибка]: Пользователь уже существует;\n[Ответ]: {1}".format([response_code, response_text])
			401:
				result_request = "[Код]: {0};\n[Ошибка]: Неверный пароль;\n[Ответ]: {1}".format([response_code, response_text])
			500:
				result_request = "[Код]: {0};\n[Ошибка]: Серверная ошибка;\n[Ответ]: {1}".format([response_code, response_text])
			_:
				result_request = "[Код]: {0};\n[Ошибка]: Неизвестная ошибка;\n[Ответ]: {1}".format([response_code, response_text])
	
	print('\n-----------\n{0}-----------'.format([result_request]))


#
# Шаблоны
#

## Шаблон запроса
func request_template(name_request: String, username: String, password: String):
	var url = "https://wakeEmil.pythonanywhere.com/{0}".format([name_request])
	var headers = ["Content-Type: application/json"]
	var body = {"username": username, "password": password}
	var json_data = JSON.stringify(body)
	set_last_request_data(name_request, url, headers, body, json_data)
	var err = http.request(url, headers, HTTPClient.METHOD_POST, json_data)
	if err != OK:
		print("Ошибка при отправке запроса:", err)


#
# Установка данных
#

## Установка данных последнего запроса
func set_last_request_data(name_type: String, url: String, headers: Array, body: Dictionary, json_data: String):
	last_request_data = {
		"type": name_type,
		"url": url,
		"headers": headers,
		"body": body,
		"json_data": json_data
	}
