tool
extends Sprite

var surfacePattern = [];
var polygon = [];

var image;

export var activate = false;

export var currentOffset = Vector2.ZERO;
export var grid = Vector2(16,16);
export var snapRange = 2;
export var checkCenters = false;

export var generateMasks = false;
export var showMetaTiles = false;
export var createTileLookUpTable = false;

export var saveTileSetData = false;
export var saveGlobalTileData = false;

# orientation breaks the current tile grid up and flips the calculations around
# then when the "get pixel" script is called it takes the orientation and does
# some math to determing the direction to trace the surface
# this is basically so we can code our tracing algorithm to only go in one direction
# but turn it and flip it to work in any direction, tho we're only interested
# in tracing surfaces and ceilings

# orientation 1 = slope going right, -1 = slope going left, 2 = ceiling going right, -2 = ceiling going left
var orientation = 1;


# Collission Generators

# TileMetaData Generator (prefill it with data just to save time)
var metaTiles = {
	# 0 = empty
	0: {"Angle": 0, "HeightMap": [0,0,0,0,0,0,0,0]},
	# 1 = filled
	1: {"Angle": 0, "HeightMap": [8,8,8,8,8,8,8,8]},
	2:{"Angle":0,"HeightMap":[1,1,1,1,1,1,1,1]},
	3:{"Angle":0,"HeightMap":[2,2,2,2,2,2,2,2]},
	4:{"Angle":0,"HeightMap":[3,3,3,3,3,3,3,3]},
	5:{"Angle":0,"HeightMap":[4,4,4,4,4,4,4,4]},
	6:{"Angle":0,"HeightMap":[5,5,5,5,5,5,5,5]},
	7:{"Angle":0,"HeightMap":[6,6,6,6,6,6,6,6]},
	8:{"Angle":0,"HeightMap":[7,7,7,7,7,7,7,7]},
	9:{"Angle":-0.141372,"HeightMap":[1,1,1,1,2,2,2,2]},
	10:{"Angle":-0.141372,"HeightMap":[3,3,3,3,4,4,4,4]},
	11:{"Angle":-0.141372,"HeightMap":[5,5,5,5,6,6,6,6]},
	12:{"Angle":-0.141372,"HeightMap":[7,7,7,7,8,8,8,8]},
	13:{"Angle":-0.404916,"HeightMap":[1,1,2,2,3,3,4,4]},
	14:{"Angle":-0.404916,"HeightMap":[5,5,6,6,7,7,8,8]},
	15:{"Angle":-0.785398,"HeightMap":[1,2,3,4,5,6,7,8]},
	16:{"Angle":-1.106539,"HeightMap":[0,0,0,0,2,4,6,8]},
	17:{"Angle":-0.708604,"HeightMap":[2,4,6,8,8,8,8,8]},
	18:{"Angle":-1.32645,"HeightMap":[0,0,0,0,0,0,4,8]},
	19:{"Angle":-0.92677,"HeightMap":[0,0,4,8,8,8,8,8]},
	20:{"Angle":-1.446878,"HeightMap":[0,0,0,0,0,0,0,8]},
	21:{"Angle":-0.92677,"HeightMap":[0,0,2,5,8,8,8,8]},
	22:{"Angle":-0.851721,"HeightMap":[0,2,3,5,6,8,8,8]},
	23:{"Angle":-0.785398,"HeightMap":[0,0,0,1,2,3,4,5]},
	24:{"Angle":-0.277507,"HeightMap":[6,8,8,8,8,8,8,8]},
	25:{"Angle":-0.518363,"HeightMap":[0,1,1,2,2,3,3,4]},
	26:{"Angle":-0.518363,"HeightMap":[4,5,5,5,6,7,7,8]},
	27:{"Angle":-1.106539,"HeightMap":[0,0,0,0,4,8,8,8]},
	28:{"Angle":-0.518363,"HeightMap":[4,8,8,8,8,8,8,8]},
	29:{"Angle":-1.106539,"HeightMap":[0,0,0,0,1,4,8,8]},
	30:{"Angle":-1.106539,"HeightMap":[0,0,0,0,0,0,2,4]},
	31:{"Angle":-0.862193,"HeightMap":[0,0,1,2,3,4,5,7]},
	32:{"Angle":-0.619592,"HeightMap":[1,1,2,3,4,5,5,6]},
	33:{"Angle":-0.141372,"HeightMap":[7,8,8,8,8,8,8,8]},
	34:{"Angle":-0.141372,"HeightMap":[1,2,2,2,2,2,2,2]},
	35:{"Angle":-0.277507,"HeightMap":[2,3,3,3,3,4,4,4]},
	36:{"Angle":-0.404916,"HeightMap":[5,5,6,6,6,7,7,8]},
	37:{"Angle":-0.464258,"HeightMap":[0,0,0,0,1,1,1,2]},
	38:{"Angle":-0.404916,"HeightMap":[1,1,1,2,2,3,3,4]},
	39:{"Angle":-0.518363,"HeightMap":[4,5,5,6,6,7,8,8]},
	40:{"Angle":-0.277507,"HeightMap":[0,1,1,1,1,2,2,2]},
	41:{"Angle":-0.277507,"HeightMap":[2,3,3,3,4,4,4,4]},
	42:{"Angle":-0.277507,"HeightMap":[5,5,5,6,6,6,7,7]},
	43:{"Angle":-0.785398,"HeightMap":[0,0,0,0,0,0,0,1]},
	44:{"Angle":-0.141372,"HeightMap":[3,3,3,3,3,3,4,4]},
	45:{"Angle":-0.141372,"HeightMap":[4,4,4,5,5,5,5,5]},
	46:{"Angle":-0.141372,"HeightMap":[5,5,6,6,6,6,6,6]},
	47:{"Angle":-0.141372,"HeightMap":[6,6,6,7,7,7,7,7]},
	48:{"Angle":-0.141372,"HeightMap":[7,7,7,7,7,7,7,8]},
	49:{"Angle":-0.404916,"HeightMap":[1,1,2,2,3,3,3,4]},
	50:{"Angle":-0.404916,"HeightMap":[4,5,5,5,6,6,7,7]},
	51:{"Angle":-0.851721,"HeightMap":[0,1,2,3,4,6,7,8]},
	52:{"Angle":-0.404916,"HeightMap":[2,2,3,3,4,4,4,5]},
	53:{"Angle":-0.404916,"HeightMap":[5,6,6,6,7,7,8,8]},
	54:{"Angle":-0.141372,"HeightMap":[2,2,2,2,2,3,3,3]},
	55:{"Angle":-0.141372,"HeightMap":[4,4,4,4,4,5,5,5]},
	56:{"Angle":-0.277507,"HeightMap":[2,2,3,3,3,4,4,4]},
	57:{"Angle":-0.277507,"HeightMap":[5,5,5,5,6,6,6,7]},
	58:{"Angle":-0.141372,"HeightMap":[7,7,7,8,8,8,8,8]},
	59:{"Angle":-0.518363,"HeightMap":[1,1,2,3,3,4,4,5]},
	60:{"Angle":-0.404916,"HeightMap":[5,6,6,7,7,8,8,8]},
	61:{"Angle":-0.785398,"HeightMap":[0,0,1,2,3,4,5,6]},
	62:{"Angle":-0.644026,"HeightMap":[0,0,0,0,1,2,2,3]},
	63:{"Angle":-0.619592,"HeightMap":[3,4,5,6,6,7,8,8]},
	64:{"Angle":-0.404916,"HeightMap":[0,1,1,1,2,2,2,3]},
	65:{"Angle":-0.404916,"HeightMap":[3,4,4,4,5,5,6,6]},
	66:{"Angle":-0.277507,"HeightMap":[6,7,7,8,8,8,8,8]},
	67:{"Angle":-0.277507,"HeightMap":[1,1,2,2,2,2,3,3]},
	68:{"Angle":-0.277507,"HeightMap":[3,3,4,4,4,4,5,5]},
	69:{"Angle":-0.141372,"HeightMap":[5,5,5,6,6,6,6,6]},
	70:{"Angle":-0.141372,"HeightMap":[6,6,7,7,7,7,7,7]},
	71:{"Angle":-0.464258,"HeightMap":[0,0,0,0,1,1,2,2]},
	72:{"Angle":-0.518363,"HeightMap":[3,4,4,5,5,6,6,7]},
	73:{"Angle":-0.708604,"HeightMap":[1,2,3,3,4,5,6,7]},
	74:{"Angle":-0.588176,"HeightMap":[0,0,0,0,0,1,1,2]},
	75:{"Angle":-0.518363,"HeightMap":[2,3,3,4,4,5,5,6]},
	76:{"Angle":-0.141372,"HeightMap":[7,7,8,8,8,8,8,8]},
	77:{"Angle":-0.141372,"HeightMap":[1,1,1,1,1,2,2,2]},
	78:{"Angle":-0.141372,"HeightMap":[2,2,2,2,2,2,3,3]},
	79:{"Angle":-0.141372,"HeightMap":[3,3,3,3,3,4,4,4]},
	80:{"Angle":-0.277507,"HeightMap":[4,4,5,5,5,5,6,6]},
	81:{"Angle":-0.277507,"HeightMap":[6,6,7,7,7,7,8,8]},
	82:{"Angle":-0.541052,"HeightMap":[0,0,0,1,1,2,2,3]},
	83:{"Angle":-0.404916,"HeightMap":[3,3,4,4,5,5,5,6]},
	84:{"Angle":-0.277507,"HeightMap":[6,7,7,7,8,8,8,8]},
	85:{"Angle":-0.619592,"HeightMap":[1,1,2,3,3,4,5,6]},
	86:{"Angle":-0.785398,"HeightMap":[0,0,0,0,0,0,1,2]},
	87:{"Angle":-0.464258,"HeightMap":[0,0,0,0,0,0,1,1]},
	88:{"Angle":-0.708604,"HeightMap":[2,3,4,5,6,6,7,8]},
	89:{"Angle":-1.106539,"HeightMap":[0,0,0,0,0,0,0,2]},
	90:{"Angle":-0.619592,"HeightMap":[3,4,5,6,7,8,8,8]},
	91:{"Angle":-0.277507,"HeightMap":[2,2,3,3,3,3,4,4]},
	92:{"Angle":-0.141372,"HeightMap":[6,6,6,6,7,7,7,7]},
	93:{"Angle":-0.619592,"HeightMap":[2,3,4,4,5,6,6,7]},
	94:{"Angle":-0.277507,"HeightMap":[6,7,8,8,8,8,8,8]},
	95:{"Angle":-0.518363,"HeightMap":[4,5,6,8,8,8,8,8]},
	96:{"Angle":-1.029744,"HeightMap":[0,0,0,0,0,2,4,5]},
	97:{"Angle":-1.106539,"HeightMap":[0,0,0,0,0,0,1,4]},
	98:{"Angle":-0.92677,"HeightMap":[0,0,2,6,8,8,8,8]},
	99:{"Angle":-0.464258,"HeightMap":[0,0,1,1,2,2,3,3]},
	100:{"Angle":-0.277507,"HeightMap":[4,4,4,5,5,5,6,6]},
	101:{"Angle":-0.785398,"HeightMap":[1,2,4,5,6,7,8,8]},
	102:{"Angle":-0.541052,"HeightMap":[0,0,0,1,2,2,3,3]},
	103:{"Angle":-0.404916,"HeightMap":[4,4,4,5,5,6,6,7]},
	104:{"Angle":-0.785398,"HeightMap":[0,0,0,0,1,2,3,4]},
	105:{"Angle":-0.404916,"HeightMap":[5,5,6,7,8,8,8,8]},
	106:{"Angle":-0.851721,"HeightMap":[0,1,3,4,6,7,8,8]},
	107:{"Angle":-0.851721,"HeightMap":[0,1,3,5,8,8,8,8]},
	108:{"Angle":-1.106539,"HeightMap":[0,0,0,0,2,6,8,8]},
	109:{"Angle":-0.851721,"HeightMap":[0,4,8,8,8,8,8,8]},
	110:{"Angle":-0.518363,"HeightMap":[3,3,4,5,5,6,7,7]},
	111:{"Angle":-1.106539,"HeightMap":[0,0,0,0,0,2,4,6]},
	112:{"Angle":-0.851721,"HeightMap":[0,6,8,8,8,8,8,8]},
	113:{"Angle":-1.012291,"HeightMap":[0,0,0,3,6,8,8,8]},
	114:{"Angle":-0.92677,"HeightMap":[0,0,2,3,5,6,8,8]},
	115:{"Angle":-0.518363,"HeightMap":[2,2,3,4,4,5,6,6]},
	116:{"Angle":0.404916,"HeightMap":[8,8,7,7,6,6,6,5]},
	117:{"Angle":0.277507,"HeightMap":[5,5,4,4,4,3,3,3]},
	118:{"Angle":0.277507,"HeightMap":[3,2,2,2,2,1,1,1]},
	119:{"Angle":0.244346,"HeightMap":[1,1,1,1,0,0,0,0]},
	120:{"Angle":-1.211259,"HeightMap":[0,0,0,0,0,2,8,8]},
	121:{"Angle":-0.518363,"HeightMap":[4,6,8,8,8,8,8,8]},
	122:{"Angle":-0.277507,"HeightMap":[3,3,4,4,4,5,5,5]},
	123:{"Angle":-0.277507,"HeightMap":[6,6,7,7,8,8,8,8]},
	124:{"Angle":0.404916,"HeightMap":[8,8,8,7,6,6,5,5]},
	125:{"Angle":0.404916,"HeightMap":[4,4,3,3,2,2,1,1]},
	126:{"Angle":0.708604,"HeightMap":[8,7,6,5,4,3,3,2]},
	127:{"Angle":0.785398,"HeightMap":[1,0,0,0,0,0,0,0]},
	128:{"Angle":-0.851721,"HeightMap":[0,8,8,8,8,8,8,8]},
	129:{"Angle":0.785398,"HeightMap":[8,8,7,5,4,3,2,1]},
	130:{"Angle":-0.277507,"HeightMap":[3,4,4,4,5,5,5,5]},
	131:{"Angle":0.141372,"HeightMap":[8,8,8,8,8,8,7,7]},
	132:{"Angle":0.404916,"HeightMap":[7,7,6,6,6,5,5,4]},
	133:{"Angle":0.675442,"HeightMap":[4,3,2,2,1,0,0,0]},
	134:{"Angle":0.851721,"HeightMap":[8,8,8,8,7,5,2,0]},
	135:{"Angle":0.785398,"HeightMap":[8,7,6,5,4,3,2,1]},
	136:{"Angle":0.277507,"HeightMap":[8,8,8,8,8,8,7,6]},
	137:{"Angle":0.895354,"HeightMap":[5,4,2,1,0,0,0,0]},
	138:{"Angle":0.277507,"HeightMap":[8,8,8,8,8,8,8,6]},
	139:{"Angle":0.404916,"HeightMap":[8,8,8,8,8,8,8,5]},
	140:{"Angle":1.012291,"HeightMap":[8,8,6,4,2,0,0,0]},
	141:{"Angle":0.518363,"HeightMap":[8,8,8,7,7,6,5,4]},
	142:{"Angle":0.785398,"HeightMap":[3,2,1,0,0,0,0,0]},
	143:{"Angle":-1.029744,"HeightMap":[0,0,0,0,0,1,3,5]},
	144:{"Angle":0.277507,"HeightMap":[8,8,8,8,7,7,6,6]},
	145:{"Angle":0.404916,"HeightMap":[5,5,4,4,3,3,2,2]},
	146:{"Angle":0.464258,"HeightMap":[1,1,0,0,0,0,0,0]},
	147:{"Angle":-0.862193,"HeightMap":[0,0,1,3,4,5,6,7]},
	148:{"Angle":-0.92677,"HeightMap":[0,0,4,7,8,8,8,8]},
	149:{"Angle":-0.619592,"HeightMap":[3,4,5,7,8,8,8,8]},
	150:{"Angle":0.851721,"HeightMap":[8,8,8,8,8,7,3,0]},
	151:{"Angle":0.619592,"HeightMap":[8,8,8,8,7,6,5,3]},
	152:{"Angle":1.106539,"HeightMap":[2,0,0,0,0,0,0,0]},
	153:{"Angle":-0.851721,"HeightMap":[0,1,4,7,8,8,8,8]},
	154:{"Angle":0.277507,"HeightMap":[8,8,8,8,7,7,7,6]},
	155:{"Angle":0.518363,"HeightMap":[6,5,5,4,4,3,3,2]},
	156:{"Angle":-0.785398,"HeightMap":[1,2,4,5,7,8,8,8]},
	157:{"Angle":0.619592,"HeightMap":[7,6,5,5,4,4,3,2]},
	158:{"Angle":0.588176,"HeightMap":[2,1,1,0,0,0,0,0]},
	159:{"Angle":-0.708604,"HeightMap":[0,1,2,3,3,4,5,6]},
	160:{"Angle":-1.106539,"HeightMap":[0,0,0,0,2,5,7,8]},
	161:{"Angle":-0.92677,"HeightMap":[0,0,0,0,0,2,3,4]},
	162:{"Angle":-0.404916,"HeightMap":[5,6,7,8,8,8,8,8]},
	163:{"Angle":-1.249656,"HeightMap":[0,0,0,0,0,0,0,3]},
	164:{"Angle":-0.785398,"HeightMap":[0,0,0,0,0,1,2,3]},
	165:{"Angle":-0.380482,"HeightMap":[0,0,0,1,1,1,2,2]},
	166:{"Angle":-0.277507,"HeightMap":[4,5,5,5,5,6,6,6]},
	167:{"Angle":-0.321141,"HeightMap":[0,0,0,0,0,1,1,1]},
	168:{"Angle":-0.404916,"HeightMap":[2,2,2,3,3,4,4,5]},
	169:{"Angle":-0.277507,"HeightMap":[1,1,2,2,2,3,3,3]},
	170:{"Angle":-0.277507,"HeightMap":[6,6,7,7,7,7,7,8]},
	171:{"Angle":-1.106539,"HeightMap":[0,0,0,0,2,4,7,8]},
	172:{"Angle":-0.141372,"HeightMap":[1,1,1,1,1,1,2,2]},
	173:{"Angle":-0.404916,"HeightMap":[2,2,3,3,3,4,4,5]},
	174:{"Angle":-0.404916,"HeightMap":[5,6,6,7,8,8,8,8]},
	175:{"Angle":-0.404916,"HeightMap":[4,5,5,6,6,7,7,7]},
	176:{"Angle":-0.277507,"HeightMap":[3,3,3,4,4,4,4,5]},
	177:{"Angle":-0.277507,"HeightMap":[5,5,5,6,6,6,6,7]},
	178:{"Angle":-0.518363,"HeightMap":[1,1,2,3,3,4,5,5]},
	179:{"Angle":-0.708604,"HeightMap":[2,3,4,5,5,6,7,8]},
	180:{"Angle":-0.851721,"HeightMap":[0,1,2,3,5,6,7,8]},
	181:{"Angle":-0.518363,"HeightMap":[4,4,5,6,6,7,8,8]},
	182:{"Angle":-1.012291,"HeightMap":[0,0,0,2,3,5,6,8]},
	183:{"Angle":-1.106539,"HeightMap":[0,0,0,0,3,6,8,8]},
	184:{"Angle":-0.785398,"HeightMap":[1,8,8,8,8,8,8,8]},
	185:{"Angle":1.446878,"HeightMap":[8,0,0,0,0,0,0,0]},
	186:{"Angle":1.211259,"HeightMap":[8,8,1,0,0,0,0,0]},
	187:{"Angle":0.92677,"HeightMap":[8,8,8,8,6,3,0,0]},
	188:{"Angle":1.106539,"HeightMap":[8,6,4,2,0,0,0,0]},
	189:{"Angle":-0.785398,"HeightMap":[1,2,3,5,6,7,8,8]},
	190:{"Angle":-0.708604,"HeightMap":[1,2,3,4,4,5,6,7]},
	191:{"Angle":-1.32645,"HeightMap":[0,0,0,0,0,0,7,8]},
	192:{"Angle":-0.851721,"HeightMap":[0,2,5,8,8,8,8,8]},
	193:{"Angle":-0.708604,"HeightMap":[2,3,5,6,8,8,8,8]},
	194:{"Angle":1.32645,"HeightMap":[8,3,0,0,0,0,0,0]},
	195:{"Angle":1.106539,"HeightMap":[8,8,8,2,0,0,0,0]},
	196:{"Angle":0.518363,"HeightMap":[8,8,8,8,8,8,7,4]},
	197:{"Angle":0.708604,"HeightMap":[8,8,8,8,8,6,4,2]},
	198:{"Angle":1.16588,"HeightMap":[7,4,1,0,0,0,0,0]},
	199:{"Angle":0.92677,"HeightMap":[8,8,8,8,8,6,0,0]},
	200:{"Angle":0.851721,"HeightMap":[8,8,7,5,4,2,1,0]},
	201:{"Angle":0.619592,"HeightMap":[8,8,8,8,8,6,5,3]},
	202:{"Angle":0.141372,"HeightMap":[8,8,8,8,8,8,8,7]},
	203:{"Angle":0.98262,"HeightMap":[6,4,3,1,0,0,0,0]},
	204:{"Angle":-0.619592,"HeightMap":[3,5,6,8,8,8,8,8]},
	205:{"Angle":-0.851721,"HeightMap":[0,1,2,4,5,7,8,8]},
	206:{"Angle":-0.98262,"HeightMap":[0,0,0,0,1,3,4,6]},
	207:{"Angle":0.277507,"HeightMap":[8,8,8,8,8,7,7,6]},
	208:{"Angle":1.012291,"HeightMap":[8,8,8,5,2,0,0,0]},
	209:{"Angle":0.851721,"HeightMap":[8,8,8,8,8,8,7,0]},
	210:{"Angle":0.277507,"HeightMap":[6,6,6,5,5,5,4,4]},
	211:{"Angle":0.141372,"HeightMap":[4,4,3,3,3,3,3,3]},
	212:{"Angle":0.141372,"HeightMap":[3,2,2,2,2,2,2,2]},
	213:{"Angle":0.619592,"HeightMap":[8,8,7,6,5,4,3,3]},
	214:{"Angle":0.785398,"HeightMap":[2,1,0,0,0,0,0,0]},
	215:{"Angle":0.518363,"HeightMap":[8,8,8,8,8,8,8,4]},
	216:{"Angle":1.012291,"HeightMap":[8,8,8,7,1,0,0,0]},
	217:{"Angle":1.32645,"HeightMap":[8,4,0,0,0,0,0,0]},
	218:{"Angle":0.708604,"HeightMap":[8,8,7,6,5,4,3,2]},
	219:{"Angle":0.92677,"HeightMap":[8,8,8,8,8,4,0,0]},
	220:{"Angle":1.211259,"HeightMap":[8,8,5,0,0,0,0,0]},
	221:{"Angle":0.785398,"HeightMap":[8,8,7,6,5,4,3,1]},
	222:{"Angle":0.619592,"HeightMap":[8,8,7,6,5,4,4,3]},
	223:{"Angle":0.464258,"HeightMap":[2,2,1,1,0,0,0,0]},
	224:{"Angle":0.277507,"HeightMap":[7,7,7,6,6,6,6,5]},
	225:{"Angle":0.141372,"HeightMap":[5,5,5,5,4,4,4,4]},
	226:{"Angle":0.141372,"HeightMap":[4,4,4,3,3,3,3,3]},
	227:{"Angle":0.141372,"HeightMap":[3,3,3,3,3,3,2,2]},
	228:{"Angle":0.141372,"HeightMap":[2,2,2,2,2,2,1,1]},
	229:{"Angle":1.012291,"HeightMap":[8,8,8,6,3,0,0,0]},
	230:{"Angle":-0.141372,"HeightMap":[2,2,2,2,3,3,3,3]},
	231:{"Angle":-0.141372,"HeightMap":[6,7,7,7,7,7,7,7]},
	232:{"Angle":-0.518363,"HeightMap":[4,5,5,6,6,7,7,8]},
	233:{"Angle":0.518363,"HeightMap":[8,8,8,8,8,8,6,4]},
	234:{"Angle":-0.141372,"HeightMap":[0,1,1,1,1,1,1,1]},
	235:{"Angle":-0.277507,"HeightMap":[6,6,7,7,7,8,8,8]}
};
var tile = {
	#0:
	# 0 empty tile
#	{
#		"TileData": [0,0,0,0],
#		"Dir": [[0,0],[0,0],[0,0],[0,0]]
#		"Angle": 0
#	},
};

var tileMap = {
#	0:[0,0,0],1:[0,0,0]]
}

func _ready():
	update();

func _process(delta):
	if Engine.editor_hint:
		if (activate):
			activate = false;
			image = texture.get_data();
			image.lock();
			for y in texture.get_height()/grid.y:
				for x in texture.get_width()/grid.x:
					if (generate_polygon(Vector2(x*grid.x,y*grid.y))):
						
						var shape = ConvexPolygonShape2D.new();
						shape.set_point_cloud(PoolVector2Array(polygon));
						$TileMap.tile_set.tile_add_shape(0,shape,transform,false,Vector2(x,y));
		
		if (generateMasks):
			generateMasks = false;
			image = texture.get_data();
			image.lock();
			var newMaskCount = 0;
			#generate_masks(currentOffset);
			for y in texture.get_height()/grid.y*2:
				for x in texture.get_width()/grid.x*2:
					if (generate_masks(Vector2(x*grid.x/2,y*grid.y/2))):
						newMaskCount += 1;
			if (newMaskCount > 0):
				#print(metaTiles);
				print(newMaskCount," meta tiles generated");
		
		if (createTileLookUpTable):
			image = texture.get_data();
			image.lock();
			createTileLookUpTable = false;
			for y in texture.get_height()/grid.y:
				for x in texture.get_width()/grid.x:
					generate_tile_lookup(Vector2(x*grid.x,y*grid.y));
		
		if (saveGlobalTileData):
			saveGlobalTileData = false;
			var file = File.new();
			file.open("res://Debug/TileMetaData.json", File.WRITE);
			file.store_var(to_json(metaTiles));
			file.close();
		
		if (saveTileSetData):
			saveTileSetData = false;
			var data = {"Tile": tile, "TileMap": tileMap};
			var file = File.new();
			file.open("res://Debug/TilesetData.json", File.WRITE);
			file.store_var(to_json(data));
			file.close();

		
		update();


func generate_polygon(getoffset = currentOffset):
	orientation = 1;
	polygon.clear();

	surfacePattern.clear();
	surfacePattern.append(Vector2.RIGHT);
	var curPat = 0;
	
	
	
	var pose = Vector2.ZERO;
	
	# ceiling orientation check
	while (pose.x < grid.x && abs(orientation) < 2):
		#shift down, if a blank pixel is found below then set orientation to 2
		while (round(get_pixel(image,getoffset+pose).a) == 1 && pose.y < grid.y-1):
			pose.y += 1;
			if (round(get_pixel(image,getoffset+pose).a) == 0):
				orientation = 2;
				#print("New Orientation");
		pose.y = 0;
		pose.x += 1;
	pose = Vector2.ZERO;
	
	
	# find top left corner
	while (polygon.size() == 0 && (pose.x < grid.x || pose.y < grid.y)):
		if (round(get_pixel(image,getoffset+pose).a) == 0):
			if (pose.y < grid.y-1):
				pose.y += 1;
			elif (pose.x < grid.x-1):
				pose.x += 1;
				pose.y = 0;
			else:
				# cancel out if a first polygon couldn't be found
				print("No pixels found at: ",getoffset);
				return false;
		else:
			
			# check heighest
			var highestLeft = pose;
			# check highest right
			pose.x = grid.x-1;
			pose.y = 0;
			while (round(get_pixel(image,getoffset+pose).a) == 0):
				if (pose.y < grid.y-1):
					pose.y += 1;
				elif (pose.x > 0):
					pose.x -= 1;
					pose.y = 0;
			# check that right most isn't heigher
			if (highestLeft.y <= pose.y):
				pose = highestLeft;
			else:
				orientation = -abs(orientation);
				#flip x positions
				pose.x -= (grid.x-1)/2;
				pose.x *= -1;
				pose.x += (grid.x-1)/2;
			
			
			
			# set top left corner
			polygon.append(pose);
	


	# find end of shape
	if (polygon.size() > 0):
		pose.x = grid.x-1;
		while (round(get_pixel(image,getoffset+pose).a) == 0):
			if (pose.y < grid.y-1):
				pose.y += 1;
			else:
				pose.x -= 1;
				pose.y = 0;
	
	surfacePattern[curPat] = (pose-polygon[0]).normalized();
	
	while (round(get_pixel(image,getoffset+pose).a) == 1 && pose.x < grid.x-1 && pose.y < grid.y-1):
		pose += surfacePattern[curPat].normalized().round();
	
	#if (surfacePattern[curPat].y >= 0.5 || pose.x < (grid.x-1)):
	#	while (round(get_pixel(image,getoffset+pose).a) == 1 && pose.y < 16):
	#		pose.y += 1;
	
	#edge cases
	if (pose.x >= grid.x-1):
		pose.x = grid.x;
	
	
	polygon.append(pose);
	
	# check in terrain
	var get = getoffset+polygon[0].linear_interpolate(polygon[1],0.5)
	+(polygon[0]-polygon[1]).rotated(deg2rad(90)).normalized();
	# Timeout is used to prevent the tool getting stuck
	var timeOut = max(grid.x,grid.y)*2;
	
	if (round(get_pixel(image,Vector2(clamp(get.x,0,texture.get_width()),clamp(get.y,0,texture.get_height()))).a) == 1):
		polygon.append(polygon[1]);
		polygon[1] = polygon[0];
		# check edge
		if (polygon[1].y == 0):
			while (round(get_pixel(image,getoffset+polygon[1].linear_interpolate(polygon[2],0.5)
			+(polygon[0]-polygon[2]).rotated(deg2rad(90)).normalized()*0.5).a) == 1 && timeOut >= 0):
				polygon[1].x += 1;
				timeOut -= 1;
		elif (checkCenters):
			polygon[1] = polygon[0].linear_interpolate(polygon[2],0.5);
			while (round(get_pixel(image,getoffset+polygon[1]).a) == 1
			&& polygon[1].y > 0 && polygon[1].y < grid.y-1
			&& polygon[1].x > 0 && polygon[1].x < grid.x-1 && timeOut >= 0):
				polygon[1] += (polygon[0]-polygon[2]).rotated(deg2rad(90)).normalized()*0.3;
				timeOut -= 1;
		if (timeOut >= 0):
			polygon[1].x = clamp(polygon[1].x,0,grid.x-1);
			polygon[1].y = clamp(polygon[1].y,0,grid.y-1);
		else:
			# Revert polygon, if timed out
			polygon[1] = polygon[2];
			polygon.remove(2);
				
		
	# check if not touching terrain midway
	elif (round(get_pixel(image,getoffset+polygon[0].linear_interpolate(polygon[1],0.5 && checkCenters)
	+(polygon[0]-polygon[1]).rotated(deg2rad(-90)).normalized()).a) == 0):
	#+polygon[0].linear_interpolate(polygon[1],0.5).rotated(deg2rad(90)).normalized()*0.5).a) == 0):
		polygon.append(polygon[1]);
		polygon[1] = polygon[0].linear_interpolate(polygon[2],0.5);

		while (round(get_pixel(image,getoffset+polygon[1]).a) == 0
		&& polygon[1].y > 0 && polygon[1].y < grid.y-1
		&& polygon[1].x > 0 && polygon[1].x < grid.x-1 && timeOut >= 0):
			polygon[1] += (polygon[0]-polygon[2]).rotated(deg2rad(-90)).normalized()*0.3;
			timeOut -= 1;
		if (timeOut >= 0):
			polygon[1].x = clamp(polygon[1].x,0,grid.x-1);
			polygon[1].y = clamp(polygon[1].y,0,grid.y-1);
		else:
			# Revert polygon, if timed out
			polygon[1] = polygon[2];
			polygon.remove(2);
	
	# bottom edge case
	if (pose.y >= grid.y-1):
		var dir = (polygon[polygon.size()-1]-polygon[polygon.size()-2]).normalized();
		#print(dir);
		if (round(get_pixel(image,getoffset+polygon[polygon.size()-1]-Vector2(1,round(dir.normalized().y*2))).a) == 0 || polygon[polygon.size()-1].x < grid.x-1):
			polygon[polygon.size()-1].y = grid.y;
		while (round(get_pixel(image,getoffset+polygon[polygon.size()-1]-Vector2(0,1)).a) == 1 && polygon[polygon.size()-1].x < 15):
			polygon[polygon.size()-1].x += 1;
	
	
	
	#print(polygon);

	# Create ceiling polygon
	polygon.append(Vector2(polygon[polygon.size()-1].x,16));
	polygon.append(Vector2(polygon[0].x,16));


	# check for unnesessary polygons
	if (polygon.size() > 0):
		for i in polygon.size():
			# check normal pathing, or occupying the same space
			if (i < polygon.size()-1 && i > 0):
				if ((polygon[i]-polygon[i-1]).normalized().is_equal_approx((polygon[i+1]-polygon[i]).normalized())
				|| polygon[i].is_equal_approx(polygon[i+1])
				|| polygon[i-1].distance_to(polygon[i]) < snapRange):
					polygon.remove(i);
					i -= 1;
		# handle orientation
		if (orientation < 0):
			for i in polygon.size():
				polygon[i].x -= (grid.x)/2;
				polygon[i].x *= -1;
				polygon[i].x += (grid.x)/2;
		# vertical flip
		if (abs(orientation) == 2):
			for i in polygon.size():
				polygon[i].y -= (grid.y)/2;
				polygon[i].y *= -1;
				polygon[i].y += (grid.y)/2;
	
	return true;

func generate_masks(getPos = Vector2.ZERO):
	var heightMap = [8,8,8,8,8,8,8,8];
	var angle = 0;
	
	# make a list of height maps to get ids
	var metaHeights = [];
	for i in range(metaTiles.size()):
		metaHeights.append(metaTiles[i]["HeightMap"]);
	
	# check the heights
	heightMap = calculate_height_map(getPos);
	
	# check that heightmap doesn't already exist
	if (metaHeights.find(heightMap) == -1):
		# calculate angle
		var points = [Vector2(0,8-heightMap[0]),Vector2(7,8-heightMap[7])];
		var check = heightMap.size()-1;
		
		while (heightMap[check] == 0 && check > 0):
			points[1] = Vector2(check,8-heightMap[check]);
			check -= 1;
		
		check = 0;
		
		while (heightMap[check] == 0 && check < heightMap.size()-1):
			points[0] = Vector2(check,8-heightMap[check]);
			check += 1;
		
		angle = deg2rad(round(rad2deg(points[0].direction_to(points[1]).angle())*10)/10);
	
		metaTiles[metaTiles.size()] = {"Angle": angle, "HeightMap": heightMap};
		
		# return true
		return true;
	# return false (indicating no new tile was generated)
	return false;

func generate_tile_lookup(getPos = Vector2.ZERO):
	# make a list of height maps to get ids
	var metaHeights = [];
	for i in range(metaTiles.size()):
		metaHeights.append(metaTiles[i]["HeightMap"]);
		
	var setTile = [0,0,0,0];
	var setFlip = [[0,0],[0,0],[0,0],[0,0]];
	var heightMap = [[],[],[],[]];
	var offsets = [Vector2.ZERO,Vector2(8,0),Vector2(0,8),Vector2(8,8)];
	heightMap[0] = calculate_height_map(getPos+offsets[0]);
	heightMap[1] = calculate_height_map(getPos+offsets[1]);
	heightMap[2] = calculate_height_map(getPos+offsets[2]);
	heightMap[3] = calculate_height_map(getPos+offsets[3]);
	
	# Determin if to flip tile
	for i in range(heightMap.size()):
		if (metaHeights.has(heightMap[i])):
			setTile[i] = metaHeights.find(heightMap[i]);
			var checkHeight = 0;
			
			while (checkHeight < heightMap[i].size()-1 &&
			(heightMap[i][checkHeight] == 8 || heightMap[i][checkHeight] == 0)):
				checkHeight += 1;
			if (heightMap[i][checkHeight] != 8 && heightMap[i][checkHeight] != 0):
				setFlip[i][1] = int(round(get_pixel(image,getPos+offsets[i]+Vector2(checkHeight,0)).a) == 1);
	
	var duplicateID = -1;
	var tileDic = {"TileData": setTile,"Dir": setFlip,};
	for i in range(tile.size()):
		var getData = tile[i].hash();
		if (tileDic.hash() == getData):
			duplicateID = i;
	
	if (duplicateID == -1):
		tile[tile.size()] = tileDic;
		tileMap[tileMap.size()] = [tile.size()-1,0,0];
	else:
		tileMap[tileMap.size()] = [duplicateID,0,0];

func calculate_height_map(getPos = Vector2.ZERO):
	var heightMap = [8,8,8,8,8,8,8,8];
	var heightID = 0;
	var curHeight = -8;
	var checkDir = 1; # 1 = check up, 0 = check down
	while (heightID < heightMap.size()):
		# reset cur height
		curHeight = -8;
		checkDir = 1;
		# if bottom and top are filled then just set mask to 8
		if (round(get_pixel(image,getPos+Vector2(heightID,0)).a) == 1
		&& round(get_pixel(image,getPos+Vector2(heightID,7)).a) == 1):
			curHeight = 8;
		# else calculate heights of collumn
		else:
			# if bottom empty then start from bottom and look up
			if (round(get_pixel(image,getPos+Vector2(heightID,7)).a) == 0):
				checkDir = 0;
				curHeight = 8;
			while (round(get_pixel(image,getPos+Vector2(heightID,(7*checkDir)+curHeight-sign(curHeight))).a) == 0 && round(curHeight) != 0):
				curHeight -= sign(curHeight);
		
		heightMap[heightID] = abs(curHeight);
		heightID += 1;
	return heightMap;

func get_pixel(image,getOffset):
	
	var getY = getOffset.y;
	
	if (abs(orientation) == 2):
		var getOff = grid.y+(floor(getOffset.y/grid.y)*grid.y);
		var calc = getOffset.y-getOff+grid.y;
		getY = getOff-0.5-calc;
		#getY = (floor(getOffset.y/grid.y)*grid.y)+(grid.y-1)-fmod(getOffset.y,grid.y);
	
	if (sign(orientation) == 1):
		return image.get_pixel(getOffset.x,getY);
	else:
		return image.get_pixel((floor(getOffset.x/grid.x)*grid.x)+(grid.x-1)-fmod(getOffset.x-0.9,grid.x),getY);

func _draw():
	if Engine.editor_hint:
		draw_rect(Rect2(currentOffset,grid),Color(0,0,0.5,0.25));
		if (polygon.size() > 0):
			for i in polygon.size():
				if (i < polygon.size()):
					var getNext = fmod(i+1,polygon.size());
					draw_line(currentOffset+polygon[i],currentOffset+polygon[getNext],Color.orangered);
					draw_circle(currentOffset+polygon[i].linear_interpolate(polygon[getNext],0.5),0.5,Color.blue);
					
					draw_line(currentOffset+polygon[i].linear_interpolate(polygon[getNext],0.5)+(polygon[i]-polygon[getNext]).rotated(deg2rad(-90)).clamped(4),
					currentOffset+polygon[i].linear_interpolate(polygon[getNext],0.5)+(polygon[i]-polygon[getNext]).rotated(deg2rad(90)).clamped(4),Color.green);
					
				draw_circle(currentOffset+polygon[i],0.5,Color.red);
		if (showMetaTiles):
			var offset = Vector2(0,-64);
			for i in range(metaTiles.size()):
				for x in range(metaTiles[i]["HeightMap"].size()):
					#draw_line(offset+Vector2.DOWN*8,offset+Vector2.DOWN*metaTiles[i]["HeightMap"][x],Color.black,1.1);
					draw_line(offset+Vector2(x,8),offset+Vector2(x,8-metaTiles[i]["HeightMap"][x]),Color.black,1.1);
				offset.x += 9;
			offset = Vector2(0,0);
			for i in range(tileMap.size()):
				var id = tileMap[i][0];
				for x in range(metaTiles[tile[id]["TileData"][0]]["HeightMap"].size()):
					var flip = tile[id]["Dir"][0];
					draw_line(offset+Vector2(x+0.5,8-flip[1]*8),
					offset+Vector2(x+0.5,8-flip[1]*8-(metaTiles[tile[id]["TileData"][0]]["HeightMap"][x])*(1+flip[1]*-2)),
					Color(0.55,0,0,0.9),1.1);
					
					flip = tile[id]["Dir"][1];
					draw_line(offset+Vector2(x+0.5+8,8-(flip[1]*8)),
					offset+Vector2(x+0.5+8,8-flip[1]*8-(metaTiles[tile[id]["TileData"][1]]["HeightMap"][x])*(1+flip[1]*-2)),
					Color(0,0.55,0,0.9),1.1);

					flip = tile[id]["Dir"][2];
					draw_line(offset+Vector2(x+0.5,8+8-(flip[1]*8)),
					offset+Vector2(x+0.5,8+8-flip[1]*8-(metaTiles[tile[id]["TileData"][2]]["HeightMap"][x])*(1+flip[1]*-2)),
					Color(0,0,0.55,0.9),1.1);

					flip = tile[id]["Dir"][3];
					draw_line(offset+Vector2(x+0.5+8,8+8-(flip[1]*8)),
					offset+Vector2(x+0.5+8,8+8-flip[1]*8-(metaTiles[tile[id]["TileData"][3]]["HeightMap"][x])*(1+flip[1]*-2)),
					Color(0.55,0.55,0,0.9),1.1);

				offset += Vector2(16,0);
				if (offset.x >= texture.get_width()):
					offset = Vector2(0,offset.y+16);

#var metaTiles = [
#	# 0 = empty
#	{"Angle": 0, "HeightMap": [0,0,0,0,0,0,0,0]},
#	# 1 = filled
#	{"Angle": 0, "HeightMap": [8,8,8,8,8,8,8,8]},
#];
#var tile = [
#	# 0 empty tile
##	{
##		"TileData": [0,0,0,0],
##		"Dir": [[0,0],[0,0],[0,0],[0,0]]
##		"AnglePriority": [null,null,null,null]
##	},
#];
#
#var tileMap = [
##	[[0,0,0],[0,0,0]]
#]
