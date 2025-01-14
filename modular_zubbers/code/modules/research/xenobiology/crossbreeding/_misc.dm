/obj/item/cerulean_slime_crystal
	name = "Cerulean slime poly-crystal"
	desc = "Translucent and irregular, it can duplicate matter on a whim."
	icon = 'icons/obj/slimecrossing.dmi'
	icon_state = "cerulean_item_crystal"
	var/amt = 0

/obj/item/cerulean_slime_crystal/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	. = ..()
	if(!istype(target,/obj/item/stack) || !istype(user,/mob/living/carbon) || !proximity_flag)
		return
	var/obj/item/stack/stack_item = target

	if(istype(stack_item,/obj/item/stack/telecrystal) || istype(stack_item,/obj/item/stack/ore/bluespace_crystal/refined/nt))
		var/mob/living/carbon/carbie = user
		visible_message(span_userdanger("\The [src] reacts violently with the unstable nature of \the [stack_item]!"))
		for(var/obj/machinery/light/L in get_area(src))
			L.on = TRUE
			L.break_light_tube()
			L.on = FALSE
			CHECK_TICK
		electrocute_mob(carbie, get_area(src), src)
		qdel(src)
		return

	stack_item.add(amt)
	qdel(src)
