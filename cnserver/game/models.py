from django.db import models
from picklefield.fields import PickledObjectField
from model_utils.managers import InheritanceManager
from django.contrib.auth.models import User
from django_facebook.models import BaseFacebookProfileModel
from django.db.models.signals import post_save

from chesstools import Board, Move, List

from datetime import datetime
import os
import re


class Level(models.Model):
	number = models.IntegerField(primary_key = True)
	points = models.IntegerField(help_text = 'How many progress points are needed to reach this level')

	def __unicode__(self):
		return 'Level {}: {} points'.format(self.number, self.points)

	def serialize(self):
		return {'number': self.number,
				'points': self.points,
				'next_level_points': self.next_level_points()}
			
	@classmethod
	def get_level(cls, level_number):
		return cls.objects.get(number = level_number)
		
	def get_next_level(self):
		return Level.get_level(self.number + 1)
		
	def next_level_points(self):
		if self.has_next():
			return self.get_next_level().points
		return ''
		
	def has_next(self):
		return Level.objects.filter(number = self.number + 1).exists()
	
	def unlock_awards(self, player):
		for award in self.levelaward_set.exclude(pk__in = player.unlocked_awards.all()).select_subclasses():
			award.unlock(player)
			
class Age(models.Model):
	number = models.IntegerField(primary_key = True)
	awarded_on_level = models.ForeignKey(Level)

	def __unicode__(self):
		return u'Age {}, awarded on {}'.format(self.number, unicode(self.awarded_on_level))
	
	def serialize(self):
		return {'number': self.number,
				'awarded_on_level': self.awarded_on_level.serialize(),
				'next_age_points': self.next_age_points()}
				
	@classmethod
	def get_age(cls, age_number):
		return cls.objects.get(number = age_number)
		
	def get_next_age(self):
		return Age.get_age(self.number + 1)
		
	def next_age_points(self):
		if self.has_next():
			return self.get_next_age().awarded_on_level.points
		return ''
		
	def has_next(self):
		return Age.objects.filter(number = self.number + 1).exists()
		
class Nation(models.Model):
	name = models.CharField(max_length = 30, primary_key = True)
	leader_image = models.ImageField(upload_to = os.path.join('images', 'leaders'), max_length = 255, null = True)
	
	def __unicode__(self):
		return self.name
	
	def serialize(self):
		return {'name': self.name,
				'leader_img': self.leader_image.url if self.leader_image else '',}


class LevelAward(models.Model):
	unlocked_at = models.ForeignKey('Level')	
	
	objects = InheritanceManager()
	
	def serialize(self):
		return {'unlocked_at': self.unlocked_at.points}
	
	def unlock(self, player):
		player.unlocked_awards.add(self)
	
class BossBattle(LevelAward):
	boss = models.ForeignKey('Player')
	
	def __unicode__(self):
		return '{}: {}'.format(unicode(self.boss), self.unlocked_at)
		
	def serialize(self):
		ret = {'boss': self.boss.serialize()}
		ret.update(super(BossBattle, self).serialize())
		return ret
	
	def unlock(self, player):
		super(BossBattle, self).unlock(player)
		Game.start_new_game(player, self.boss)
	
class Player(BaseFacebookProfileModel):

	DEFAULT_IMG = '/media/pawn.png'

	user = models.OneToOneField(User, primary_key = True)
	image = models.ImageField(blank = True, null = True, upload_to = os.path.join('images', 'facebook_profiles/%Y/%m/%d'), max_length = 255)
	is_ai = models.BooleanField(default = False)
	logged_in = models.BooleanField(default = False)
	available_for_random_play = models.BooleanField(default = True)
	available_for_friend_play = models.BooleanField(default = True)
	last_played_on = models.DateTimeField(default = datetime.now())
	is_guest = models.BooleanField(default = False)
	progress_points = models.IntegerField(default = 0)
	nation = models.ForeignKey(Nation, null = True)
	age = models.ForeignKey(Age, default = 1)
	level = models.ForeignKey(Level, default  = 1)
	unlocked_awards = models.ManyToManyField(LevelAward, null = True, blank = True)

	@staticmethod
	def get_player_for_user(user):
		return Player.objects.get_or_create(user = user)[0]

	def login(self):
		self.logged_in = True
		self.save()
				 
	def logout(self):
		self.logged_in = False
		self.save()

	@staticmethod
	def get_longest_waiting_player(player):
		logged_in_players = Player.objects.filter(logged_in = True).exclude(pk = player.pk)
		if logged_in_players.count() > 0:
			return logged_in_players.order_by('last_played_on')[0]
		return None

	def __unicode__(self):
		return unicode(self.user.username)

	def update_play_time(self):
		self.last_played_on = datetime.now()
		self.save()

	def get_image_url(self):
		if self.image:
			return self.image.url
		return Player.DEFAULT_IMG
		
	def advance_level(self):
		if self.level.has_next():
			self.level = self.level.get_next_level()
			self.level.unlock_awards(self)
			
			if self.age.get_next_age().awarded_on_level == self.level:
				self.advacnce_age()
				
	def advacnce_age(self):
		if self.age.has_next():
			self.age = self.age.get_next_age()
	
	def award_progress_points(self, points):
	
		if self.is_ai:
			# No points for robots!
			return
	
		self.progress_points += points
		
		# need we advance a level or an age?
		if self.progress_points >= self.level.next_level_points():
			self.advance_level()
			
		self.save()
		
	def serialize(self):
		return {'username': self.user.username,
				'name': self.facebook_name or '',
				'image_path': self.image.url if self.image else '',
				'nation': unicode(self.nation),
				'progress_points': self.progress_points,
				'level': self.level.serialize(),
				'age': self.age.serialize(),}
				

def create_profile(sender, instance, created, **kwargs):
	if created:
		Player.objects.create(user = instance)

post_save.connect(create_profile, sender = User)
				 
class PointAward(models.Model):
	name = models.CharField(max_length = 30)
	points = models.IntegerField()
	has_location = models.BooleanField(default = False)
	points_color = models.CharField(max_length = 6, default = 'D4A017')
	text_color = models.CharField(max_length = 6, default = '8A4117')
	
	def worthy_of_award(self, *args, **kwargs):
		return True
	
	def award_points(self, *args, **kwargs):
		if self.worthy_of_award(*args, **kwargs):
			return self.points
			
	@classmethod
	def get_all_awards(klass, *args, **kwargs):
		return [x for x in klass.objects.all() if x.worthy_of_award(*args, **kwargs)]
		
	def __unicode__(self):
		return '{} ({} pts)'.format(self.name, self.points)

	def set_location(self, loc):
		self.location = loc
		
	def serialize(self):
		data = {'name': self.name, 'points': self.points, 'points_color': self.points_color, 'text_color': self.text_color}
		if 'location' in self.__dict__:
			data['location'] = self.location
		return data
		
class MoveListPointAward(PointAward):
	regexp = models.CharField(max_length = 100)
	is_rule_only_for_last_move = models.BooleanField(default = True)
	
	def get_last_move(self, move_list):
		return move_list.last_move
		
	def regexp_matches(self, s):
		unescaped_regexp = self.regexp.decode('string_escape')
		matches = re.match(unescaped_regexp, s, re.DOTALL) is not None
		print '{}: "{}" {} = {}'.format(self.name, self.regexp, repr(s), matches)
		return matches
	
	def worthy_of_award(self, move_list):
		if self.is_rule_only_for_last_move:
			move = str(self.get_last_move(move_list))
			return self.regexp_matches(move)
		return self.regexp_matches('\n'.join(sum([[str(x) for x in m if x is not None] for m in move_list.moves], [])))
	
class CapturePointAward(PointAward):
	captured_piece = models.CharField(max_length = 10)
	
	def worthy_of_award(self, captured_piece):
		return captured_piece == self.captured_piece

		
GAME_OUTCOME_CHOICES = (('undecided', 'The game is in progress'),
						('checkmate', 'Checkmate'),
						('stalemate', 'Draw (Stalemate)'),
						('repetition', 'Draw (Threefold repetition)'),
						('50-move rule', 'Draw (50 move rule)'),)			
			
class EndGameAward(PointAward):
	outcome = models.CharField(max_length = 15, choices = GAME_OUTCOME_CHOICES)
		
	def worthy_of_award(self, outcome):
		return outcome == self.outcome
		
class Game(models.Model):
	GAME_STATUS_CHOICES = (('not_started', 'The game has not yet started'),
						   ('in_progress', 'The game is in progress'),
						   ('ended', 'The game ended'),)

	NEXT_PLAYER_CHOICES = (('white', 'White is next to move'),
						   ('black', 'Black is next to move'),)

	status = models.CharField(max_length = 15, choices = GAME_STATUS_CHOICES, default = 'not_started')
	outcome = models.CharField(max_length = 15, choices = GAME_OUTCOME_CHOICES, default = 'undecided')
	white_player = models.ForeignKey(Player, related_name = 'games_white_set')
	black_player = models.ForeignKey(Player, related_name = 'games_black_set')
	white_time_remaining = models.IntegerField(default = 90 * 60)
	black_time_remaining = models.IntegerField(default = 90 * 60)
	created_on = models.DateTimeField(auto_now_add = True)
	last_move_on = models.DateTimeField(null = True)
	board = PickledObjectField()
	moves = PickledObjectField()
	next_player = models.CharField(max_length = 5, choices = NEXT_PLAYER_CHOICES, default = 'white')

	def __unicode__(self):
		return '{white_player} vs. {black_player}, started on {date}'.format(white_player = unicode(self.white_player), black_player = unicode(self.black_player), date = self.created_on.strftime('%d/%m/%Y %H:%M:%S'))

	def fen(self):
		return self.board.fen()
		
	def moves_list(self):
		return self.moves.all()
		
	def current_player(self):
		return self.white_player if self.next_player == 'white' else self.black_player
	
	def get_opponent(self, player):
		return self.black_player if player == self.white_player else self.white_player
	
	@staticmethod
	def start_new_game(white_player, black_player, turn_time = 90 * 60):
		game = Game(white_player = white_player,
					black_player = black_player,
					board = Board(),
					moves = List(),
					next_player = 'white',
					status = 'in_progress',
					white_time_remaining = turn_time,
					black_time_remaining = turn_time)
		game.save()

		return game

	def update_clock(self, time_elapsed):
		if self.next_player == 'white':
			self.white_time_remaining -= time_elapsed
		else:
			self.black_time_remaining -= time_elapsed
		self.save()
		
	def move(self, start, end, promotion = None):
		
		awards = []
		status = ''
		m = Move(start, end, promotion)
		if self.board.is_legal(m):
			self.last_move_on = datetime.now()
			self.board.move(m)
			self.moves.add(m)
			awards += MoveListPointAward.get_all_awards(self.moves)
			if self.board.captured:
				awards += CapturePointAward.get_all_awards(self.board.captured.name)
			outcome = self.board.check_position()
			if outcome:
				awards += EndGameAward.get_all_awards(outcome)
				self.outcome = outcome
				self.status = 'ended'
				self.save()
				status = 'Game ended'
			else:
				status = 'OK'
		else:
			status = 'Illegal move!'
		
		for a in awards:
			if a.has_location:
				a.set_location(end)
		self.current_player().award_progress_points(sum([a.points for a in awards]))
		if status == 'OK':
			self.switch_player()
		return status, awards

	def switch_player(self):
		self.next_player = 'white' if self.next_player == 'black' else 'black'
		self.save()

	def get_last_move_date(self):
		return self.last_move_on.strftime('%d %b %H:%M') if self.last_move_on else ''
		
	def state(self):
		return {'status': self.status,
				'white': self.white_player.serialize(), 
				'white_clock': self.white_time_remaining,
				'black': self.black_player.serialize(),
				'black_clock': self.black_time_remaining,
				'moves': self.moves_list(),
				'next': self.next_player,
				'fen': self.fen(),
				'created_on': self.created_on.isoformat(),
				'last_move_on': self.get_last_move_date()}
				