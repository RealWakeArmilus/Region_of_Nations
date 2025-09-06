extends Node
class_name GenerationCompanyName


# Списки слогов для разных частей названия
var beginnings = ["Ar", "Ba", "Cu", "Du", "Esh", "Ga", "Ha", "Iri", "Ka", "Lu", 
				 "Ma", "Nu", "Pa", "Qu", "Ra", "Sa", "Ta", "Ur", "Za", "Sha",
				 "Tan", "Bur", "Kur", "Mar", "Nar"]
				 
var middles = ["tan", "kar", "mir", "nub", "shar", "til", "gur", "dur", "han", 
			  "mal", "pur", "qur", "sur", "tur", "ub", "ash", "esh", "ish",
			  "rum", "dub", "gash", "lub", "mish"]
			  
var endings = ["um", "ar", "esh", "ur", "al", "at", "on", "ir", "is", "ak", 
			  "uk", "ik", "ash", "esh", "ish", "ad", "ed", "ud"]

# Материалы и соответствующие профессии с названиями
var materials_by_profession = {
	2: {"_name": "Woodcutter", "materials": ["Oak", "Cedar", "Pine", "Yew", "Ash"]},
	3: {"_name": "Mason", "materials": ["Stone", "Marble", "Granite", "Limestone", "Sandstone"]},
	4: {"_name": "Planter", "materials": ["Grain", "Olive", "Grape", "Fig", "Date"]},
	5: {"_name": "Miner", "materials": ["Copper", "Tin", "Bronze", "Silver", "Gold"]},
	6: {"_name": "Processor", "materials": ["Flax", "Wool", "Hemp", "Leather", "Hide"]},
	7: {"_name": "Carpenter", "materials": ["Oak", "Cedar", "Walnut", "Maple", "Elm"]},
	8: {"_name": "Spinner", "materials": ["Flax", "Wool", "Cotton", "Hemp", "Linen"]},
	9: {"_name": "Caster", "materials": ["Bronze", "Copper", "Tin", "Gold", "Silver"]},
	10: {"_name": "Farmer", "materials": ["Grain", "Barley", "Wheat", "Rye", "Millet"]},
	11: {"_name": "Baker", "materials": ["Grain", "Barley", "Wheat", "Honey", "Salt"]},
	12: {"_name": "Tailor", "materials": ["Linen", "Wool", "Leather", "Silk", "Fleece"]},
	13: {"_name": "Smith", "materials": ["Iron", "Bronze", "Copper", "Steel", "Metal"]},
	14: {"_name": "Cartwright", "materials": ["Oak", "Ash", "Elm", "Wheel", "Axle"]}
}

var collective_terms = ["Brothers", "Sons", "Clan", "Tribe", "Kin", 
					   "Collective", "Guild", "House", "Lineage"]

# Генератор простых названий
func generate_simple_name():
	var _name = ""
	_name += beginnings.pick_random()
	_name += middles.pick_random()
	
	if randf() > 0.4:
		_name += endings.pick_random()
	
	return _name.capitalize()

# Генератор профессиональных названий
func generate_profession_name(profession_id):
	var data = materials_by_profession[profession_id]
	var material = data["materials"].pick_random()
	var profession_name = data["_name"]
	var company_name = generate_simple_name()
	
	var formats = [
		"{material} {profession}",
		"{company} {profession}",
		"{material} {profession} {collective}",
		"{profession} of {company}",
		"{company} & {collective}"
	]
	
	var chosen_format = formats.pick_random()
	
	return chosen_format.format({
		"material": material,
		"profession": profession_name,
		"company": company_name,
		"collective": collective_terms.pick_random()
	})

# Генератор семейных/коллективных названий
func generate_collective_name(profession_id):
	var data = materials_by_profession[profession_id]
	var profession_name = data["_name"]
	var company_name = generate_simple_name()
	var collective = collective_terms.pick_random()
	
	var formats = [
		"{company} & {collective}",
		"House of {company}",
		"{collective} of {profession}",
		"{company} {profession} {collective}"
	]
	
	return formats.pick_random().format({
		"company": company_name,
		"collective": collective,
		"profession": profession_name
	})

# Генератор описательных названий
func generate_descriptive_name(profession_id):
	var data = materials_by_profession[profession_id]
	var profession_name = data["_name"]
	
	var descriptors = {
		2: ["Mighty", "Sturdy", "Strong", "Iron", "Reliable"],
		3: ["Stonecut", "Precise", "Ancient", "Monumental", "Enduring"],
		4: ["Fertile", "Bountiful", "Golden", "Harvest", "Plentiful"],
		5: ["Deep", "Rich", "Prospector's", "Ore", "Tunnel"],
		6: ["Skilled", "Fine", "Artisan", "Master", "Expert"],
		7: ["Precise", "Smooth", "Joined", "Polished", "Master"],
		8: ["Fine", "Soft", "Silken", "Delicate", "Woven"],
		9: ["Molten", "Bronze", "Fire", "Forge", "Heated"],
		10: ["Bountiful", "Fertile", "Golden", "Harvest", "Plough"],
		11: ["Golden", "Crusty", "Warm", "Hearth", "Oven"],
		12: ["Fine", "Elegant", "Stitched", "Woven", "Tailored"],
		13: ["Iron", "Forged", "Anvil", "Hammers", "Fire"],
		14: ["Sturdy", "Reliable", "Wheeled", "Axle", "Greased"]
	}
	
	return "{descriptor} {profession}".format({
		"descriptor": descriptors[profession_id].pick_random(),
		"profession": profession_name
	})

# Основная функция генерации
func get_random_name(speciality_id):
	# 20% шанс на простое название без привязки к профессии
	if randf() > 0.8:
		return generate_simple_name()
	
	var generators = [
		func(): return generate_profession_name(speciality_id),
		func(): return generate_collective_name(speciality_id),
		func(): return generate_descriptive_name(speciality_id)
	]
	
	return generators.pick_random().call()
