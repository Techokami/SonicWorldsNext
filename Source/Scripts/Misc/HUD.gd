extends CanvasLayer

export var focusPlayer = 0;

onready var scoreText = $Counters/Text/ScoreNumber;
onready var timeText = $Counters/Text/TimeNumbers;
onready var ringText = $Counters/Text/RingCount;

onready var lifeText = $LifeCounter/Icon/LifeText;


func _process(delta):
	scoreText.string = "%6d" % Global.score;
	timeText.string = "%2d" % floor(Global.levelTime/60) + ":" + str(fmod(floor(Global.levelTime),60)).pad_zeros(2);
	if (Global.players.size() > 0):
		ringText.string = "%3d" % Global.players[focusPlayer].rings;
	
	
	lifeText.string = "%2d" % Global.lives;
