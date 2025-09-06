extends Node
class_name GenerationUsername


# Списки слогов для разных частей имени
var beginnings = ["А", "Бе", "Ве", "Га", "Де", "Е", "Жо", "Зи", "И", "Ка", "Ле", "Ми", "Не", "О", "По", "Ру", "Си", "Ти", "У", "Фа", "Ха", "Че", "Ша", "Э", "Ю", "Я"]
var middles = ["ли", "мо", "на", "ро", "со", "та", "ру", "ве", "ди", "го", "пу", "ша", "чо", "ла", "фи", "хи", "цо", "бэ", "дэ", "кэ"]
var endings = ["н", "р", "т", "с", "к", "л", "в", "д", "г", "ш", "ч", "щ", "зь", "х", "м", "зь", "ф", "п", "б"]

# Генератор полных имён (начало + середина + конец)
func generate_full_name():
	var _name = ""
	_name += beginnings.pick_random()
	_name += middles.pick_random()
	
	# 50% шанс добавить третью часть
	if randf() > 0.5:
		_name += middles.pick_random()
	
	# 75% шанс добавить окончание
	if randf() > 0.25:
		_name += endings.pick_random()
	
	return _name.capitalize()

# Генератор коротких имён (начало + конец)
func generate_short_name():
	var _name = ""
	_name += beginnings.pick_random()
	
	# 80% шанс добавить окончание
	if randf() > 0.2:
		_name += endings.pick_random()
	
	return _name.capitalize()

# Генератор двойных имён (два полных имени через дефис)
func generate_double_name():
	return generate_full_name() + "-" + generate_full_name()

# Основная функция для получения случайного имени
func get_random_name():
	var generators = [
		generate_full_name,
		generate_short_name,
		generate_double_name
	]
	
	# Выбираем случайный генератор и вызываем его
	return generators.pick_random().call()
