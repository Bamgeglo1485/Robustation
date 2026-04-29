class_name PerkData extends Resource

@export var perk_id: StringName

var perk_name: String
var perk_description: String

@export var perk_rarity: rarity_classes = rarity_classes.COMMON
@export var icon_texture: Texture
@export var equipped_texture: Texture

@export var modifiers: Array[PerkModifier]

enum rarity_classes {
	SHITTY,
	COMMON,
	ROBUST,
	ADMINABUSE
}
