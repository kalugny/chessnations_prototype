import subprocess
import threading
import time
import re
import datetime
from httplib2 import Http
import urllib
import sys
import json
import math

class UCIWrapper(threading.Thread):

	OPTIONS_RE = '^option name (?P<name>.+) type (?P<type>\w+)(?: (?P<rest_of_options>.+))?'

	def __init__(self, bot_path):
		self.bot_process = subprocess.Popen(bot_path, stdin = subprocess.PIPE, stdout = subprocess.PIPE, stderr = subprocess.PIPE)
		self.lines = []
		super(UCIWrapper, self).__init__()
		self.start()

	def __del__(self):
		self.bot_process.kill()

	def run(self):
		while self.bot_process.poll() is None:
			self.lines.append(self.bot_process.stdout.readline())

	def command(self, command):
		self.bot_process.stdin.write(command + '\n')

	def parse_options(self, options_line):
		m = re.match(UCIWrapper.OPTIONS_RE, options_line)
		if not m:
			return
		gd = m.groupdict()
		name = gd['name']
		options = {'type': gd['type']}
		if gd['rest_of_options']:
			x = gd['rest_of_options'].strip().split(' ')
			options.update(dict([x[i:i+2] for i in range(0, len(x), 2)]))
		self.options[name] = options

	def uci(self):
		self.command('uci')
		while len(self.lines) == 0:
			time.sleep(0.1)
		while self.lines[-1].strip() != 'uciok':
			time.sleep(0.1)
		self.options = {}
##        for line in self.lines:
##            if line.startswith('option'):
##                self.parse_options(line)

	def newgame(self):
		self.command('ucinewgame')
		
	def setoption(self, option, value):
		self.command('setoption name ' + option + ' value ' + value);

	def go(self, position = 'startpos', time_to_think = 100):
		lines = self.lines
		if lines[-1].startswith('bestmove'):
			# this is from the last time this was run
			lines.append('')
		self.command('position ' + position)
		self.command('go movetime ' + str(time_to_think))
##        start_time = datetime.datetime.now()
##        while (not lines[-1].startswith('bestmove')) and datetime.datetime.now() - start_time < time_to_think:
##            time.sleep(1)
##        if not lines[-1].startswith('bestmove'):
##            self.command('stop')
		while not lines[-1].startswith('bestmove'):
			time.sleep(0.1)
		return lines[-1].split(' ')[1]

class BotServer(object):
	BASE_URL = 'http://game.chessnations.com/'
	LOGIN_URL = BASE_URL + 'login/ai/'
	GAME_URL = BASE_URL + 'game/'
	MY_GAMES_URL = GAME_URL + 'json/'
	STATUS_URL = GAME_URL + '{}/status/'
	MOVE_URL = GAME_URL + '{}/move/'

	def __init__(self, bot_path, username, password):
		self.bot = UCIWrapper(bot_path)
		self.bot.uci()
		if username == 'spike':
			self.bot.setoption('Skill Level', '1')
		self.bot.newgame()
		self.http = Http()
		self.username = username
		self.password = password
		self.login()

	def privileged_request(self, *args, **kwargs):
		headers = {'Cookie': self.cookie}
		kwargs['headers'] = headers
		return self.http.request(*args, **kwargs)

	def get_games(self):
		response, context = self.privileged_request(BotServer.MY_GAMES_URL)
		if response['status'] == '200':
			return [x['game_id'] for x in json.loads(context)['games_my_move']]
		raise Exception('Get games failed with code {}:\n{}'.format(response, context))

	def get_game_status(self, game_id):
		response, context = self.privileged_request(BotServer.STATUS_URL.format(game_id))
		if response['status'] == '200':
			return json.loads(context)
		raise Exception('Get status failed with code {}:\n{}'.format(respose, context))

	def is_my_turn(self, status):
		return (status['next'] == 'white' and status['white']['username'] == self.username) or (status['next'] == 'black' and status['black']['username'] == self.username)

	def make_move(self, game_id):
		start_time = time.time()

		status = bot_server.get_game_status(game_id)
		if not bot_server.is_my_turn(status):
			return
		
		fen = status['fen']
		res = self.bot.go('fen '+fen)
		start = res[:2]
		end = res[2:]

		elapsed_time = int(math.ceil(time.time() - start_time))
		response, content = self.privileged_request(BotServer.MOVE_URL.format(game_id) + '?' + urllib.urlencode({'start': start, 'end': end, 'time_elapsed': elapsed_time}))
		if response['status'] == '200':
			return json.loads(content)
		raise Exception('Make move failed with code {}\n:{}'.format(response, content))

	def login(self):
		response, context = self.http.request(BotServer.LOGIN_URL, 'POST', urllib.urlencode({'username': self.username, 'password': self.password}), headers = {"Content-type": "application/x-www-form-urlencoded","Accept": "text/plain"})
		if response['status'] == '200':
			self.cookie = response['set-cookie']
			return
		raise IOError("Can't login")
		


if __name__ == "__main__":
	if len(sys.argv) < 4:
		print 'Usage: {} bot_path username password'.format(sys.argv[0])
		exit(1)
		
	bot_server = BotServer(sys.argv[1], sys.argv[2], sys.argv[3])

	while True:
		time.sleep(30)
		try:
			my_games = bot_server.get_games()
			for game in my_games:
				bot_server.make_move(game)
		except Exception, e:
			print datetime.datetime.now().isoformat(), 'error'
			log = open('logs/' + sys.argv[2] + '_' + datetime.datetime.now().strftime("%Y-%m-%d %H;%M;%S;%f") + '.html', 'wt')
			log.write(unicode(e))
			log.close()
			
	
