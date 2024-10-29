class_name Hitbox
extends Area2D

signal hit(Hurtbox)

func _init() ->void:
	area_entered.connect(on_area_entered)

func on_area_entered(hurtbox:Hurtbox)->void:
	#print("[Hit] %s => %s" %[owner.name,hurtbox.owner.name])
	hit.emit(hurtbox)
	hurtbox.hurt.emit(self)
