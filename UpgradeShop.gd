# =====================================
# UpgradeShop.gd - WORKING VERSION
# =====================================
extends Control

var upgrades = {
	"GPS Navigation": {"cost": 150, "description": "Modern navigation (+$5/cruise)"},
	"Luxury Seats": {"cost": 200, "description": "Comfortable seating (+$5/cruise)"},
	"Sound System": {"cost": 100, "description": "Entertainment (+$5/cruise)"},
	"Solar Panels": {"cost": 300, "description": "Eco-friendly (+$5/cruise)"},
	"Fish Finder": {"cost": 250, "description": "Sonar technology (+$5/cruise)"},
	"LED Lights": {"cost": 80, "description": "Stylish lighting (+$5/cruise)"},
	"Safety Kit": {"cost": 90, "description": "Complete safety (+$5/cruise)"},
	"Premium Paint": {"cost": 120, "description": "Beautiful finish (+$5/cruise)"}
}

func show_shop():
	var dialog = AcceptDialog.new()
	dialog.title = "🛒 Upgrade Shop"
	dialog.size = Vector2(500, 400)
	
	var vbox = VBoxContainer.new()
	
	# Money display
	var money_label = Label.new()
	money_label.text = "Your Money: $%.2f" % GameManager.money
	money_label.add_theme_font_size_override("font_size", 18)
	vbox.add_child(money_label)
	
	vbox.add_child(HSeparator.new())
	
	# Scroll container for upgrades
	var scroll = ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(450, 250)
	var upgrade_list = VBoxContainer.new()
	
	for upgrade_name in upgrades.keys():
		var upgrade = upgrades[upgrade_name]
		var hbox = HBoxContainer.new()
		
		# Check if already owned
		var owned = upgrade_name in GameManager.boat_upgrades
		
		# Upgrade info
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var name_label = Label.new()
		name_label.text = upgrade_name
		name_label.add_theme_font_size_override("font_size", 14)
		if owned:
			name_label.modulate = Color.GREEN
			name_label.text += " ✓"
		info_vbox.add_child(name_label)
		
		var desc_label = Label.new()
		desc_label.text = upgrade.description
		desc_label.add_theme_font_size_override("font_size", 11)
		desc_label.modulate = Color(0.8, 0.8, 0.8)
		info_vbox.add_child(desc_label)
		
		hbox.add_child(info_vbox)
		
		# Buy button
		var buy_btn = Button.new()
		if owned:
			buy_btn.text = "Owned"
			buy_btn.disabled = true
		elif GameManager.money < upgrade.cost:
			buy_btn.text = "$%.0f" % upgrade.cost
			buy_btn.disabled = true
			buy_btn.modulate = Color.RED
		else:
			buy_btn.text = "Buy $%.0f" % upgrade.cost
			buy_btn.pressed.connect(_buy_upgrade.bind(upgrade_name, upgrade.cost, dialog))
		
		hbox.add_child(buy_btn)
		upgrade_list.add_child(hbox)
		upgrade_list.add_child(HSeparator.new())
	
	scroll.add_child(upgrade_list)
	vbox.add_child(scroll)
	
	dialog.add_child(vbox)
	get_parent().add_child(dialog)
	dialog.popup_centered()

func _buy_upgrade(upgrade_name: String, cost: float, dialog: AcceptDialog):
	if GameManager.buy_upgrade(upgrade_name, cost):
		print("Purchased: ", upgrade_name)
		dialog.queue_free()
		show_shop()  # Refresh the shop
		
		# Show purchase confirmation
		var confirm = AcceptDialog.new()
		confirm.title = "Purchase Successful!"
		confirm.dialog_text = "You bought %s!\nBoat improved!" % upgrade_name
		get_parent().add_child(confirm)
		confirm.popup_centered()
	else:
		print("Failed to buy: ", upgrade_name)
