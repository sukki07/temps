#whenever runs gives lunch breakfast dinner for today and tomorrow with ingredients needed
require 'date'
class Inventory 
	@food_ingredients = {}
	@food_ingredients["seviya"] = ["capsicum_green","carrot","onion","rai","seviya"]	
	@food_ingredients["upma"] = ["carrot","onion","rai","suji"]	
	@food_ingredients["daliya"] = ["carrot","matar","onion","tamatar"]
	@food_ingredients["paneer_capsicum_dry"] = ["panner","matar","onion","capsicum_green","kitchen_king","ketchup","haldi"]
	@food_ingredients["aloo_subji_dry"] = ["aloo","rai","sugar","haldi","red_chilli_powder"]
	@food_ingredients["rajma"] = ["rajma","onion","tamatar","rajam_masala"]
	@food_ingredients["chana"] = ["chana","onion","tamatar","chana_masala","garlic","haldi"]
	@food_ingredients["chole"] = ["chole","onion","tamatar","chole_masala","haldi"]
	@food_ingredients["aloo_beans"] = ["aloo","beans","rai","red_chilli_powder","haldi"]
	@food_ingredients["bhindi"] = ["bhindi","onion","amchur","red_chilli_powder","haldi","kitchen_king"]
	@food_ingredients["chana_dal_cheela"] = ["chana_dal","tamatar","carrot","onion"]
	@food_ingredients["moong_dal_cheela"] = ["moong_dal","tamatar","carrot","onion"]
	@food_ingredients["uttapam"] = ["dosa_batter","dhaniya","green_chill","onion"]
	@food_ingredients["mix_veg"] = ["carrot","gobhi","matar","panner","kitchen_king","sweet_corn"]
	@food_ingredients["pav_bhaji"] = ["capsicum","tamatar","aloo","pav_bhaji_masala","onion","matar","pav","neebu"]
	@food_ingredients["tur_dal"] = ["tur_dal","jeera","hing","dhaniya","haldi"]
	@food_ingredients["poha"] = ["poha","rai","onion","aloo","neebu","dhaniya","haldi"]
	@food_ingredients["paneer_sandwich"] = ["onion","paneer","capsicum_green","oregano","bread"]
	@food_ingredients["aloo_roll"] = ["aloo","onion","capsicum_green","oregano"]
	@food_ingredients["rajma_roll"] = ["rajma","onion","tamatar","rajam_masala"]


	@food_menu =  [] 
	def self.ingredients(dish)
		return @food_ingredients[dish]
	end

	def self.today
		current_day =  DateTime.now.strftime("%d")
		size = @food_ingredients.keys.size
		index =  current_day.to_i % size
		p current_day
		p index
		p @food_ingredients[index]
	end

	def self.menu
	menu_day = {"b"=>["boiled_egg_bread"],"l" =>["seviya"],"d" => ["rajma"]}
	@food_menu.push menu_day
	end
end
inv = Inventory.today
p Inventory.ingredients("rajma_roll")

