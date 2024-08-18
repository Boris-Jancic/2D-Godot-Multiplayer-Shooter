extends CharacterBody2D


const SPEED = 300.0
const JUMP_VELOCITY = -400.0
# Get the gravity from the project settings to be synced with RigidBody nodes.
var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")
var syncPos = Vector2(0,0)
var syncRot = 0

@export var Bullet:PackedScene
@onready var bullet_spawn: Node2D = $GunRotation/BulletSpawn

func _physics_process(delta):

	# Add the gravity.
	if not is_on_floor():
		velocity.y += gravity * delta
		
	$GunRotation.look_at(get_viewport().get_mouse_position())
	# Handle Jump.
	if Input.is_action_just_pressed("ui_accept") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	
	syncPos = global_position
	syncRot = rotation_degrees
	if Input.is_action_just_pressed("fire_weapon"):
		var b = Bullet.instantiate()
		b.global_position = bullet_spawn.global_position
		b.rotation_degrees = bullet_spawn.rotation_degrees
		get_tree().root.add_child(b)

	# Get the input direction and handle the movement/deceleration.
	# As good practice, you should replace UI actions with custom gameplay actions.
	var direction = Input.get_axis("move_left", "move_right")
	if direction == 0:
		$AnimatedSprite2D.play("Idle")
	
	if direction:
		velocity.x = direction * SPEED
	else:
		$AnimatedSprite2D.play("Run")
		velocity.x = move_toward(velocity.x, 0, SPEED)

	move_and_slide()
