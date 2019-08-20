from django.contrib import admin
from models import *

admin.site.register(Player)
admin.site.register(MoveListPointAward)
admin.site.register(CapturePointAward)
admin.site.register(EndGameAward)
admin.site.register(Level)
admin.site.register(Age)
admin.site.register(Nation)
admin.site.register(BossBattle)

class GameAdmin(admin.ModelAdmin):
	readonly_fields = ('fen', 'moves')

admin.site.register(Game, GameAdmin)
