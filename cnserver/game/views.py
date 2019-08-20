from django.conf import settings
from django.http import HttpResponse, HttpResponseRedirect, HttpResponseForbidden
from django.shortcuts import render_to_response
from django.template import RequestContext
from django.contrib.auth import authenticate, login as django_login_method, logout as django_logout_method, REDIRECT_FIELD_NAME
from django.contrib.auth.decorators import login_required
from django.contrib.auth.views import login as django_login_view
from django.contrib.auth.forms import AuthenticationForm
from django.db.models import Q
from django.views.decorators.csrf import csrf_exempt
from django.utils.http import is_safe_url
from django.core.urlresolvers import reverse
from django.contrib.auth.models import User

from django_facebook.connect import connect_user

from models import Game, Player, Nation, BossBattle

import json
import time
import random
import string


def our_login_is_also_required(view_func):
	def new_view(request, *args, **kwargs):
		player = Player.get_player_for_user(request.user)
		player.login()
		request.player = player
		return view_func(request, *args, **kwargs)
	return new_view
		

@login_required
@our_login_is_also_required
def new_game(request):

	opponent = None
	if 'opponent' in request.GET:
		try:
			opponent = Player.objects.get(user__username = request.GET.get('opponent'))
		except:
			pass
	if opponent is None:
		opponent = random.choice(list(Player.objects.filter(logged_in = True).exclude(pk = request.player.pk)))
	if opponent is None:
		# no one is available to play, wait a while
		return HttpResponse(json.dumps({'status': 'Waiting for other players'}))
	sides = [request.player, opponent]
	#random.shuffle(sides)
	g = Game.start_new_game(*sides)
	for p in sides:
		p.update_play_time()
	return HttpResponseRedirect('/game/{}/'.format(g.id))


@login_required
@our_login_is_also_required
def interactive(request, game_id):
	return render_to_response('game.html', {'game': Game.objects.get(id = game_id)}, context_instance=RequestContext(request))

def my_games_impl(request):
	my_games = Game.objects.filter(Q(white_player = request.player) | Q(black_player = request.player))
	my_games_in_progress = my_games.filter(status = 'in_progress')
	games_my_move = my_games_in_progress.filter(Q(white_player = request.player, next_player = 'white') | Q(black_player = request.player, next_player = 'black')).order_by('-created_on')
	games_not_my_move = my_games_in_progress.filter(Q(white_player = request.player, next_player = 'black') | Q(black_player = request.player, next_player = 'white')).order_by('-created_on')
	my_games_ended = my_games.filter(status = 'ended')
	return games_my_move, games_not_my_move, my_games_ended, request.player.is_guest

@login_required
@our_login_is_also_required
def my_games(request):
	games_my_move, games_not_my_move, ended_games, is_guest = my_games_impl(request)
	return render_to_response('my_games.html', {'games_my_move': games_my_move, 'games_not_my_move': games_not_my_move, 'ended_games': ended_games}, context_instance=RequestContext(request))

def gamelist_repr(gamelist, player):
	return [{
			 'game_id': g.id, 
			 'game_repr': unicode(g),
			 'opponent': g.get_opponent(player).serialize(),
			 'last_move_on': g.get_last_move_date(),
			 } for g in gamelist]
	
@login_required
@our_login_is_also_required
def my_games_json(request):
	games_my_move, games_not_my_move, ended_games, is_guest = my_games_impl(request)
	return HttpResponse(json.dumps({'username': request.user.username, 
									'is_guest': is_guest,
									'player': request.player.serialize(),
									'games_my_move': gamelist_repr(games_my_move, request.player), 
									'games_not_my_move': gamelist_repr(games_not_my_move, request.player),
									'ended_games': gamelist_repr(ended_games, request.player)}))

@login_required
@our_login_is_also_required
def get_game(request, game_id):
	game = None
	error = None
	try:
		game = Game.objects.get(pk = game_id)
	except:
		error = json.dumps({'status': 'Game with id {} not started'.format(game_id)})
	if not getattr(game, game.next_player + '_player') == request.player:
		error = json.dumps({'status': 'Not your turn'})
	return game, error
	
@login_required
@our_login_is_also_required
def timeline(request):
	return HttpResponse(json.dumps({'player': request.player.serialize(),
									'battles': [bb.serialize() for bb in BossBattle.objects.all()], }))

@login_required
@our_login_is_also_required
def move(request, game_id):

	start = request.GET['start']
	end = request.GET['end']
	time_elapsed = int(request.GET['time_elapsed'])

	game, error = get_game(request, game_id)
	if error is not None:
		return HttpResponse(error)
	
	game.update_clock(time_elapsed)
	status, awards = game.move(start, end)
	print awards
	return HttpResponse(json.dumps({'status': status,
								    'awards': [x.serialize() for x in awards]}))

@login_required
@our_login_is_also_required
def update_clock(request, game_id, time_elapsed):
	game, error = get_game(request, game_id)
	if error is not None:
		return HttpResponse(error)
	
	game.update_clock(int(time_elapsed))
	
	return HttpResponse(json.dumps({'status': 'OK'}))
	
@login_required
@our_login_is_also_required
def game_state(request, game_id):
	game = None
	try:
		game = Game.objects.get(pk = game_id)
	except:
		return HttpResponse(json.dumps({'status': 'Game with id {} not started'.format(game_id)}))
	state = game.state()
	state['status'] = 'OK'
	
	return HttpResponse(json.dumps(state))

@csrf_exempt
def login(request):
	if request.method == 'GET':
		return django_login_view(request)

	redirect_to = request.REQUEST.get(REDIRECT_FIELD_NAME, '')
	form = AuthenticationForm(data=request.POST)
	if form.is_valid():
		# Ensure the user-originating redirection url is safe.
		if not is_safe_url(url=redirect_to, host=request.get_host()):
			redirect_to = settings.LOGIN_REDIRECT_URL

		# Okay, security check complete. Log the user in.
		django_login_method(request, form.get_user())

		return HttpResponseRedirect(redirect_to)
	else:
		return HttpResponseForbidden()

@csrf_exempt
def fb_connect(request):
	if request.method != 'POST':
		return HttpResponseRedirect(reverse('game-login'))
	
	if request.user and request.user.is_authenticated():
		player = Player.get_player_for_user(request.user)
		if player.is_guest:
			# let's upgrade the guest to fb user
			if not 'connect_facebook' in request.GET:
				return HttpResponseRedirect('?connect_facebook=1')
		else:
			django_logout_method(request)
	
	access_token = request.POST.get('access_token')

	action, user = connect_user(request, access_token)

	player = Player.get_player_for_user(user)
	player.is_guest = False
	player.save()
	user.username = json.loads(player.raw_data)['username']
	user.save()
	
	return HttpResponse(json.dumps({'status': 'OK', 'username': user.username, 'profile': player.serialize()}))

@csrf_exempt
def login_ai(request):
	username = request.POST['username']
	password = request.POST['password']
	user = authenticate(username = username, password = password)
	if user is not None:
		player = Player.get_player_for_user(user)
		if player.is_ai:
			django_login_method(request, user)
			return HttpResponse(json.dumps({'status': 'OK'}))
		else:
			return HttpResponse(json.dumps({'status': 'This page is for bots only!'}))
	else:
		return HttpResponse(json.dumps({'status': 'Login failed!'}))


@login_required
def logout(request):
	player = Player.get_player_for_user(request.user)
	player.logout()
	if player.is_guest:
		# a guest will never be able to log back in, so let's just delete it
		player.user.delete()
	django_logout_method(request)
	return HttpResponse(json.dumps({'status': 'OK'}))

@csrf_exempt
def guest(request):
	random.seed(time.time())
	while True:
		username = 'guest' + str(random.getrandbits(32))
		if not User.objects.filter(username = username).exists():
			break
	password = ''.join([random.choice(string.letters + string.digits) for i in xrange(10)])
	guest_user = User.objects.create_user(username, password = password)
	guest_user.save()
	player = Player.get_player_for_user(guest_user)
	player.is_guest = True
	player.save()
	user = authenticate(username = username, password = password)
	django_login_method(request, user)
	return HttpResponse(json.dumps({'status': 'OK', 'username': username, 'user_profile': player.serialize()}))

@login_required
@our_login_is_also_required
def set_nation(request, nation):
	player = Player.get_player_for_user(request.user)
	if player.nation is None:
		player.nation = Nation.objects.get(pk = nation)
		player.save()
		return HttpResponse(json.dumps({'status': 'OK'}))
	return HttpResponse(json.dumps({'status': 'Nation already set'}))