extends CharacterBody2D

const SPEED = 300.0
const JUMP_VELOCITY = -400.0
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var syncPos = Vector2(0,0)
var syncRot = 0
@export var bullet :PackedScene
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

func _ready():
	var multiplayer_id = multiplayer.get_unique_id()
	$MultiplayerSynchronizer.set_multiplayer_authority(str(name).to_int())
	for i in GameManager.Players:
		if GameManager.Players[i].id == multiplayer_id:
			$Nameplate.text = GameManager.Players[i].name
			
func _physics_process(delta):
	if $MultiplayerSynchronizer.get_multiplayer_authority() == multiplayer.get_unique_id():
		# Add the gravity.
		if not is_on_floor():
			velocity.y += gravity * delta
			
		$GunRotation.look_at(get_viewport().get_mouse_position())
		# Handle Jump.
		if Input.is_action_just_pressed("ui_accept") and is_on_floor():
			velocity.y = JUMP_VELOCITY
		
		syncPos = global_position
		syncRot = rotation_degrees
		if Input.is_action_just_released("Fire"):
			fire.rpc()
		# Get the input direction and handle the movement/deceleration.
		# As good practice, you should replace UI actions with custom gameplay actions.
		var direction = Input.get_axis("ui_left", "ui_right")
		if direction:
			velocity.x = direction * SPEED
			if velocity.x != 0:
				$AnimatedSprite2D.play("Run")
			if velocity.x == 0 and velocity.y ==0:
				$AnimatedSprite2D.play("Idle")
		else:
			velocity.x = move_toward(velocity.x, 0, SPEED)

		move_and_slide()
	else:
		global_position = global_position.lerp(syncPos, .5)
		rotation_degrees = lerpf(rotation_degrees, syncRot, .5)

@rpc("any_peer","call_local")
func fire():
	$GunRotation/AudioStreamPlayer2D.play()
	var b = bullet.instantiate()
	b.global_position = $GunRotation/BulletSpawn.global_position
	b.rotation_degrees = $GunRotation.rotation_degrees
	get_tree().root.add_child(b)
