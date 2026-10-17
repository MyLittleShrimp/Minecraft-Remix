class_name PlayerInputProvider
extends Node
## Each actor owns a provider. The default actor follows the chosen input device;
## explicit prefixes and overridden test / future player providers stay independent.

@export var action_prefix: String = ""
@onready var device_settings: Node = get_node_or_null("/root/ControlSettings")

func _action(action: String) -> String:
    return action_prefix+action if not action_prefix.is_empty() or device_settings==null else device_settings.action_name(action)
func _blocked() -> bool:
    return action_prefix.is_empty() and device_settings!=null and device_settings.gameplay_blocked()

func movement_axis() -> float:
    return 0.0 if _blocked() else Input.get_axis(_action("move_left"),_action("move_right"))

func jump_pressed() -> bool:
    return not _blocked() and Input.is_action_just_pressed(_action("jump"))

func jump_held() -> bool:
    return not _blocked() and Input.is_action_pressed(_action("jump"))

func down_held() -> bool:
    return not _blocked() and Input.is_action_pressed(_action("aim_down"))

func attack_pressed() -> bool:
    return not _blocked() and Input.is_action_just_pressed(_action("attack"))

func attack_held() -> bool:
    return not _blocked() and Input.is_action_pressed(_action("attack"))

func attack_released() -> bool:
    return not _blocked() and Input.is_action_just_released(_action("attack"))

func switch_pressed() -> bool:
    return not _blocked() and Input.is_action_just_pressed(_action("switch_weapon"))

func up_held() -> bool:
    return not _blocked() and Input.is_action_pressed(_action("aim_up"))

func ultimate_pressed() -> bool:
    return not _blocked() and Input.is_action_just_pressed(_action("ultimate"))
