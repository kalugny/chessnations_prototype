--------------------------------------------------------------------------------------
---- CONSTS ---------------------------------------------------------------------------
--------------------------------------------------------------------------------------

DEBUG = true
RUN_FROM_SDCARD = false

CODE_PATH = ''
IMAGE_PATH = '../images/'
SOUND_PATH = '../sounds/'

DIR_SEP = '/'

RESOLUTION_X = 1280
RESOLUTION_Y = 800

FIT_TO_DEVICE = true

SERVER_ADDRESS = 'game.chessnations.com' --'54.247.56.24'

Env = {}

FACEBOOK_APP_ID = '235265483276879'

CRITTERCISM_APPID = '5182a54d97c8f20fe0000024'
CRITTERCISM_APIKEY = '6b3a51jiyy0fmvpso8qwdw9o4utxc7nr'

MAX_CSV_FILE_SIZE = 1024 ^ 2

----------------------
--- Debug values -----
----------------------

if not _print then
	_print = print
end

print = function(...) 
	if DEBUG then 
		_print(...) 
	end 
end

DEBUG_USERNAME = 'kalugny'
DEBUG_PASSWORD = 'y1u1v'

