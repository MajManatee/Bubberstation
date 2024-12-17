/obj/item/holotool
	name = "experimental holotool"
	desc = "A highly experimental holographic tool projector."
	icon = 'modular_zubbers/icons/obj/holotool.dmi'
	icon_state = "holo"
	inhand_icon_state = "holo"
	slot_flags = ITEM_SLOT_BELT
	w_class = WEIGHT_CLASS_SMALL
	usesound = 'modular_zubbers/sound/holotool/pshoom.ogg'
	lefthand_file = 'modular_zubbers/icons/mob/inhands/holotool_lefthand.dmi'
	righthand_file = 'modular_zubbers/icons/mob/inhands/holotool_righthand.dmi'
	resistance_flags = FIRE_PROOF | ACID_PROOF
	light_range = 1
	light_power = 2
	toolspeed = 0.3
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
	var/chosen_color
	var/current_color = "#48D1CC" //mediumturquoise, for eventually being able to have its colour changed.
	light_color = "#48D1CC"

/obj/item/holotool/get_all_tool_behaviours()
	return list(TOOL_CROWBAR, TOOL_WIRECUTTER, TOOL_WELDER, TOOL_WRENCH, TOOL_SCREWDRIVER, TOOL_MULTITOOL)

/obj/item/holotool/examine(mob/user)
	. = ..()
	. += span_notice("Use <b>in hand</b> to switch configuration.\n")
	. += span_notice("It functions as a <b>[tool_behaviour]</b> tool.")
	. += span_notice("Alt+Click it to change its colour!")

/obj/item/holotool/update_icon_state()
	. = ..()
	switch(tool_behaviour)
		if(TOOL_SCREWDRIVER)
			icon_state = "[initial(icon_state)]-screwdriver"
			inhand_icon_state = "[initial(icon_state)]-screwdriver"
		if(TOOL_WRENCH)
			icon_state = "[initial(icon_state)]-wrench"
			inhand_icon_state = "[initial(icon_state)]-wrench"
		if(TOOL_WIRECUTTER)
			icon_state = "[initial(icon_state)]-wirecutters"
			inhand_icon_state = "[initial(icon_state)]-wirecutters"
		if(TOOL_CROWBAR)
			icon_state = "[initial(icon_state)]-crowbar"
			inhand_icon_state = "[initial(icon_state)]-crowbar"
		if(TOOL_WELDER)
			icon_state = "[initial(icon_state)]-welder"
			inhand_icon_state = "[initial(icon_state)]-welder"
		if(TOOL_MULTITOOL)
			icon_state = "[initial(icon_state)]-multitool"
			inhand_icon_state = "[initial(icon_state)]-multitool"
		else
			icon_state = "holo"
			inhand_icon_state = "holo"

/obj/item/holotool/attack_self(mob/user, modifiers)
	. = ..()
	if(!user)
		return
	var/list/tool_list = list(
		"Screwdriver" = image(icon_state = "holo-screwdriver"),
		"Wrench" = image(icon_state = "holo-wrench"),
		"Wirecutters" = image(icon_state = "holo-wirecutters"),
		"Crowbar" = image(icon_state = "holo-crowbar"),
		"Welder" = image(icon_state = "holo-welder"),
		"Multitool" = image(icon_state = "holo-multitool"),
		"Off" = image(icon_state = "holo"),
	)
	var/tool_result = show_radial_menu(user, src, tool_list, custom_check = CALLBACK(src, PROC_REF(check_menu), user), require_near = TRUE, tooltips = TRUE)
	if(!check_menu(user) || !tool_result)
		return
	switch(tool_result)
		if("Wrench")
			tool_behaviour = TOOL_WRENCH
		if("Wirecutters")
			tool_behaviour = TOOL_WIRECUTTER
		if("Screwdriver")
			tool_behaviour = TOOL_SCREWDRIVER
		if("Crowbar")
			tool_behaviour = TOOL_CROWBAR
		if("Welder")
			tool_behaviour = TOOL_WELDER
		if("Multitool")
			tool_behaviour = TOOL_MULTITOOL
		if("Off")
			tool_behaviour = NONE

	playsound(src, 'modular_zubbers/sound/holotool/pshoom.ogg', 35, vary = TRUE)
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

// Spawn in RD closet
/obj/structure/closet/secure_closet/research_director/PopulateContents()
	. = ..()
	new /obj/item/holotool(src)
