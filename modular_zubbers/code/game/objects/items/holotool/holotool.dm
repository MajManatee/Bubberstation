/obj/item/holotool
	name = "experimental holotool"
	desc = "A highly experimental holographic tool projector."
	icon = 'modular_zubbers/icons/obj/holotool.dmi'
	icon_state = "holotool"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	usesound = 'modular_zubbers/sound/holotool/pshoom.ogg'
	lefthand_file = 'modular_zubbers/icons/mob/inhands/holotool_lefthand.dmi'
	righthand_file = 'modular_zubbers/icons/mob/inhands/holotool_righthand.dmi'
	actions_types = list(/datum/action/item_action/change_tool, /datum/action/item_action/change_ht_color)
	resistance_flags = FIRE_PROOF | ACID_PROOF
	light_range = 3
	light_power = 2
	toolspeed = 3

	///Contains images of all radial icons
	var/static/list/radial_icons_cache = list()
	/// Buffer used by the multitool mode
	var/buffer
	/// The current mode
	var/datum/holotool_mode/current_tool
	// to be retained until we have the hubris to abstract all multitool functionality into some /datum/component, and break modularity in a hundred ways
	var/list/available_modes
	var/list/mode_names
	var/list/radial_modes
	var/current_color = "#48D1CC" //mediumturquoise

/obj/item/holotool/get_all_tool_behaviours()
	return list(TOOL_CROWBAR, TOOL_WIRECUTTER, TOOL_WELDER, TOOL_WRENCH, TOOL_SCREWDRIVER, TOOL_MULTITOOL)

/obj/item/holotool/examine(mob/user)
	. = ..()
	. += span_notice("Use <b>in hand</b> to switch configuration.\n")
	. += span_notice("It functions as a <b>[tool_behaviour]</b> tool.")
	. += span_notice("Ctrl+Click it to change its colour!")

/obj/item/holotool/update_icon_state()
	. = ..()
	switch(tool_behaviour)
		if(TOOL_SCREWDRIVER)
			icon_state = "[initial(icon_state)]-screwdriver"
		if(TOOL_WRENCH)
			icon_state = "[initial(icon_state)]-wrench"
		if(TOOL_WIRECUTTER)
			icon_state = "[initial(icon_state)]-wirecutters"
		if(TOOL_CROWBAR)
			icon_state = "[initial(icon_state)]-crowbar"
		if(TOOL_WELDER)
			icon_state = "[initial(icon_state)]-welder"
		if(TOOL_MULTITOOL)
			icon_state = "[initial(icon_state)]-multitool"
		else
			icon_state = "holotool"

/obj/item/holotool/attack_self(mob/user, modifiers)
	. = ..()
	if(!user)
		return
	var/list/tool_list = list(
		"Screwdriver" = image(icon = icon, icon_state = "holotool-screwdriver"),
		"Wrench" = image(icon = icon, icon_state = "holotool-wrench"),
		"Wirecutters" = image(icon = icon, icon_state = "holotool-wirecutters"),
		"Crowbar" = image(icon = icon, icon_state = "holotool-crowbar"),
		"Welder" = image(icon = icon, icon_state = "holotool-welder"),
		"Multitool" = image(icon = icon, icon_state = "holotool-multitool"),
		"Off" = image(icon = icon, icon_state = "holotool"),
	)
	var/tool_result = show_radial_menu(user, src, tool_list, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user) || !tool_result)
		return
	RemoveElement(/datum/element/cuffsnapping, snap_time_weak_handcuffs, snap_time_strong_handcuffs)
	switch(tool_result)
		if("Wrench")
			tool_behaviour = TOOL_WRENCH
			sharpness = NONE
		if("Wirecutters")
			tool_behaviour = TOOL_WIRECUTTER
			sharpness = NONE
			AddElement(/datum/element/cuffsnapping, snap_time_weak_handcuffs, snap_time_strong_handcuffs)
		if("Screwdriver")
			tool_behaviour = TOOL_SCREWDRIVER
			sharpness = NONE
		if("Crowbar")
			tool_behaviour = TOOL_CROWBAR
			sharpness = NONE
		if("Welder")
			tool_behaviour = TOOL_WELDER
			sharpness = NONE
		if("Multitool")
			tool_behaviour = TOOL_SCREWDRIVER
			sharpness = NONE
		if("Off")
			tool_behaviour = NONE
			sharpness = NONE
	playsound(src, 'modular_zubbers/sound/holotool/pshoom.ogg', 50, vary = TRUE)
	update_appearance(UPDATE_ICON)

/obj/item/holotool/proc/check_menu(mob/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated || !user.Adjacent(src))
		return FALSE
	return TRUE




/obj/item/holotool/use(used)
	return TRUE //it just always works, capiche!?

/obj/item/holotool/tool_use_check(mob/living/user, amount)
	return TRUE	//always has enough "fuel"

/obj/item/holotool/ui_action_click(mob/user, datum/action/action)
	if(istype(action, /datum/action/item_action/change_tool))
		update_listing()
		var/datum/holotool_mode/chosen = input("Choose tool settings", "Tool", null, null) as null|anything in available_modes
		switch_tool(user, chosen)
	else
		var/C = input(user, "Select Color", "Select color", "#48D1CC") as null|color
		if(!C || QDELETED(src))
			return
		current_color = C
		set_light_color(current_color)
	update_appearance(UPDATE_ICON)
	action.build_all_button_icons()
	user.regenerate_icons()

/obj/item/holotool/proc/switch_tool(mob/user, datum/holotool_mode/mode)
	if(!mode || !istype(mode))
		return
	if(current_tool)
		current_tool.on_unset(src)
	current_tool = mode
	current_tool.on_set(src)
	playsound(loc, 'yogstation/sound/items/holotool.ogg', get_clamped_volume(), 1, -1)
	update_appearance(UPDATE_ICON)
	user.regenerate_icons()


/obj/item/holotool/proc/update_listing()
	LAZYCLEARLIST(available_modes)
	LAZYCLEARLIST(radial_modes)
	LAZYCLEARLIST(mode_names)
	for(var/A in subtypesof(/datum/holotool_mode))
		var/datum/holotool_mode/M = new A
		if(M.can_be_used(src))
			LAZYADD(available_modes, M)
			LAZYSET(mode_names, M.name, M)
			var/image/holotool_img = image(icon = icon, icon_state = icon_state)
			var/image/tool_img = image(icon = icon, icon_state = M.name)
			tool_img.color = current_color
			holotool_img.overlays += tool_img
			LAZYSET(radial_modes, M.name, holotool_img)
		else
			qdel(M)

/obj/item/holotool/update_icon(updates=ALL)
	. = ..()
	cut_overlays()
	if(current_tool)
		var/mutable_appearance/holo_item = mutable_appearance(icon, current_tool.name)
		holo_item.color = current_color
		item_state = current_tool.name
		add_overlay(holo_item)
		if(current_tool.name == "off")
			set_light_on(FALSE)
		else
			set_light_on(TRUE)
	else
		item_state = "holotool"
		icon_state = "holotool"
		set_light_on(FALSE)

	for(var/datum/action/A as anything in actions)
		A.build_all_button_icons()

/obj/item/holotool/proc/check_menu(mob/living/user)
	if(!istype(user))
		return FALSE
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE

/obj/item/holotool/attack_self(mob/user)
	update_listing()
	var/chosen = show_radial_menu(user, src, radial_modes, custom_check = CALLBACK(src, PROC_REF(check_menu),user))
	if(!check_menu(user))
		return
	if(chosen)
		var/new_tool = LAZYACCESS(mode_names, chosen)
		if(new_tool)
			switch_tool(user, new_tool)

/obj/item/holotool/emag_act(mob/user, obj/item/card/emag/emag_card)
	if(obj_flags & EMAGGED)
		return FALSE
	to_chat(user, span_danger("ZZT- ILLEGAL BLUEPRINT UNLOCKED- CONTACT !#$@^%$# NANOTRASEN SUPPORT-@*%$^%!"))
	do_sparks(5, 0, src)
	obj_flags |= EMAGGED
	return TRUE

// Spawn in RD closet
/obj/structure/closet/secure_closet/RD/PopulateContents()
	. = ..()
	new /obj/item/holotool(src)
