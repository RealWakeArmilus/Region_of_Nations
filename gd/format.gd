extends Node
class_name Format

## Преобразует целое число в компактный формат с k (тысячи) и kk (миллионы)
func compact_count(count: int) -> String:
	if count >= 1000000:
		var millions = float(count) / 1000000.0
		return _format_millions(millions) + "kk"
	elif count >= 1000:
		var thousands = float(count) / 1000.0
		return _format_thousands(thousands) + "k"
	else:
		return str(count)

## Преобразует дробное число в компактный формат с k (тысячи) и kk (миллионы)
func compact_float(number: float, decimal_places: int = 2) -> String:
	if abs(number) >= 1000000.0:
		var millions = number / 1000000.0
		return _format_millions(millions) + "kk"
	elif abs(number) >= 1000.0:
		var thousands = number / 1000.0
		return _format_thousands(thousands) + "k"
	else:
		return _format_with_precision(number, decimal_places)

## Форматирование для миллионов (округляет до целых если нет дробной части)
func _format_millions(number: float) -> String:
	if number == int(number):
		return str(int(number))  # 1.0 → "1"
	else:
		# Проверяем, есть ли значимая дробная часть
		var fractional = number - int(number)
		if fractional >= 0.005:  # Если есть хотя бы 0.005
			return "%.2f" % number  # 1.05 → "1.05"
		else:
			return str(int(number))  # 1.001 → "1"

## Форматирование для тысяч (округляет до целых если нет дробной части)
func _format_thousands(number: float) -> String:
	if number == int(number):
		return str(int(number))  # 1.0 → "1"
	else:
		# Проверяем, есть ли значимая дробная часть
		var fractional = number - int(number)
		if fractional >= 0.005:  # Если есть хотя бы 0.005
			return "%.2f" % number  # 1.05 → "1.05"
		else:
			return str(int(number))  # 1.001 → "1"

## Вспомогательная функция для форматирования с заданной точностью
func _format_with_precision(number: float, decimal_places: int) -> String:
	if decimal_places == 0:
		return str(int(round(number)))
	else:
		var format_string = "%.{0}f".format([decimal_places])
		return format_string % number
