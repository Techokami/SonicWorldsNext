## A list of physics attributes. You generally need five of these for your character.
## You can either create resources for each of your needs or else reuse a resource and then
## tweak it in the PlayerAvatar. Be aware that the node inspector won't show values with
## full precision, though it will let you enter them at whatever precision you want.
class_name PlayerPhysics extends Resource

## Rate of acceleration while player is holding forward along floor
@export var acceleration: float = 0.046875
## Rate of deceleration while player is holding against direction of travel
@export var deceleration: float = 0.5
## Rate of deceleration if the player releases directional control on floor
@export var friction: float = 0.046875
## Friction effect while player is rolling (usually half the standard friction)
@export var rolling_friction: float = 0.046875 * 0.5
## Friction effect while player is rolling if player is holding against direction of travel
@export var rolling_deceleration: float = 0.125
## Top speed a player can achieve while moving normally
@export var top_speed: float = 6*60
## Top speed a player can achieve while rolling
@export var rolling_top_speed: float = 16*60

## Needs a better descriptor, but this is sort of like a multiplier for how much
## slope impacts the player's velocity
@export var slope_factor: float = 0.125
## As with slope_factor, but only applies to rolling on rises.
@export var slope_factor_rolling_upwards: float = 0.078125
## As with slope_factor, but only applies to rolling on falls
@export var slope_factor_rolling_downwards: float = 0.3125
## A minimum speed that the player must move at in order to not get disconnected
## from walls and ceilings.
@export var fall: float = 2.5*60

#Airborne Constants
@export var air_acceleration: float = 0.09375
@export var jump_strength: float = 6.5*60
@export var gravity: float = 0.21875
@export var release_jump: float = 4.0
