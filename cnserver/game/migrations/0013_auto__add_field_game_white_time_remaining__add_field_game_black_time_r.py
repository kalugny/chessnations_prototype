# -*- coding: utf-8 -*-
import datetime
from south.db import db
from south.v2 import SchemaMigration
from django.db import models


class Migration(SchemaMigration):

    def forwards(self, orm):
        # Adding field 'Game.white_time_remaining'
        db.add_column('game_game', 'white_time_remaining',
                      self.gf('django.db.models.fields.IntegerField')(default=5400),
                      keep_default=False)

        # Adding field 'Game.black_time_remaining'
        db.add_column('game_game', 'black_time_remaining',
                      self.gf('django.db.models.fields.IntegerField')(default=5400),
                      keep_default=False)


    def backwards(self, orm):
        # Deleting field 'Game.white_time_remaining'
        db.delete_column('game_game', 'white_time_remaining')

        # Deleting field 'Game.black_time_remaining'
        db.delete_column('game_game', 'black_time_remaining')


    models = {
        'auth.group': {
            'Meta': {'object_name': 'Group'},
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'unique': 'True', 'max_length': '80'}),
            'permissions': ('django.db.models.fields.related.ManyToManyField', [], {'to': "orm['auth.Permission']", 'symmetrical': 'False', 'blank': 'True'})
        },
        'auth.permission': {
            'Meta': {'ordering': "('content_type__app_label', 'content_type__model', 'codename')", 'unique_together': "(('content_type', 'codename'),)", 'object_name': 'Permission'},
            'codename': ('django.db.models.fields.CharField', [], {'max_length': '100'}),
            'content_type': ('django.db.models.fields.related.ForeignKey', [], {'to': "orm['contenttypes.ContentType']"}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '50'})
        },
        'auth.user': {
            'Meta': {'object_name': 'User'},
            'date_joined': ('django.db.models.fields.DateTimeField', [], {'default': 'datetime.datetime.now'}),
            'email': ('django.db.models.fields.EmailField', [], {'max_length': '75', 'blank': 'True'}),
            'first_name': ('django.db.models.fields.CharField', [], {'max_length': '30', 'blank': 'True'}),
            'groups': ('django.db.models.fields.related.ManyToManyField', [], {'to': "orm['auth.Group']", 'symmetrical': 'False', 'blank': 'True'}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'is_active': ('django.db.models.fields.BooleanField', [], {'default': 'True'}),
            'is_staff': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'is_superuser': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'last_login': ('django.db.models.fields.DateTimeField', [], {'default': 'datetime.datetime.now'}),
            'last_name': ('django.db.models.fields.CharField', [], {'max_length': '30', 'blank': 'True'}),
            'password': ('django.db.models.fields.CharField', [], {'max_length': '128'}),
            'user_permissions': ('django.db.models.fields.related.ManyToManyField', [], {'to': "orm['auth.Permission']", 'symmetrical': 'False', 'blank': 'True'}),
            'username': ('django.db.models.fields.CharField', [], {'unique': 'True', 'max_length': '30'})
        },
        'contenttypes.contenttype': {
            'Meta': {'ordering': "('name',)", 'unique_together': "(('app_label', 'model'),)", 'object_name': 'ContentType', 'db_table': "'django_content_type'"},
            'app_label': ('django.db.models.fields.CharField', [], {'max_length': '100'}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'model': ('django.db.models.fields.CharField', [], {'max_length': '100'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '100'})
        },
        'game.capturepointaward': {
            'Meta': {'object_name': 'CapturePointAward', '_ormbases': ['game.PointAward']},
            'captured_piece': ('django.db.models.fields.CharField', [], {'max_length': '10'}),
            'pointaward_ptr': ('django.db.models.fields.related.OneToOneField', [], {'to': "orm['game.PointAward']", 'unique': 'True', 'primary_key': 'True'})
        },
        'game.endgameaward': {
            'Meta': {'object_name': 'EndGameAward', '_ormbases': ['game.PointAward']},
            'outcome': ('django.db.models.fields.CharField', [], {'max_length': '15'}),
            'pointaward_ptr': ('django.db.models.fields.related.OneToOneField', [], {'to': "orm['game.PointAward']", 'unique': 'True', 'primary_key': 'True'})
        },
        'game.game': {
            'Meta': {'object_name': 'Game'},
            'black_player': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'games_black_set'", 'to': "orm['game.Player']"}),
            'black_time_remaining': ('django.db.models.fields.IntegerField', [], {'default': '5400'}),
            'board': ('picklefield.fields.PickledObjectField', [], {}),
            'created_on': ('django.db.models.fields.DateTimeField', [], {'auto_now_add': 'True', 'blank': 'True'}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'moves': ('picklefield.fields.PickledObjectField', [], {}),
            'next_player': ('django.db.models.fields.CharField', [], {'default': "'white'", 'max_length': '5'}),
            'outcome': ('django.db.models.fields.CharField', [], {'default': "'undecided'", 'max_length': '15'}),
            'status': ('django.db.models.fields.CharField', [], {'default': "'not_started'", 'max_length': '15'}),
            'white_player': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'games_white_set'", 'to': "orm['game.Player']"}),
            'white_time_remaining': ('django.db.models.fields.IntegerField', [], {'default': '5400'})
        },
        'game.movelistpointaward': {
            'Meta': {'object_name': 'MoveListPointAward', '_ormbases': ['game.PointAward']},
            'is_rule_only_for_last_move': ('django.db.models.fields.BooleanField', [], {'default': 'True'}),
            'pointaward_ptr': ('django.db.models.fields.related.OneToOneField', [], {'to': "orm['game.PointAward']", 'unique': 'True', 'primary_key': 'True'}),
            'regexp': ('django.db.models.fields.CharField', [], {'max_length': '100'})
        },
        'game.player': {
            'Meta': {'object_name': 'Player'},
            'about_me': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'}),
            'access_token': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'}),
            'available_for_friend_play': ('django.db.models.fields.BooleanField', [], {'default': 'True'}),
            'available_for_random_play': ('django.db.models.fields.BooleanField', [], {'default': 'True'}),
            'blog_url': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'}),
            'date_of_birth': ('django.db.models.fields.DateField', [], {'null': 'True', 'blank': 'True'}),
            'facebook_id': ('django.db.models.fields.BigIntegerField', [], {'unique': 'True', 'null': 'True', 'blank': 'True'}),
            'facebook_name': ('django.db.models.fields.CharField', [], {'max_length': '255', 'null': 'True', 'blank': 'True'}),
            'facebook_open_graph': ('django.db.models.fields.BooleanField', [], {'default': 'True'}),
            'facebook_profile_url': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'}),
            'gender': ('django.db.models.fields.CharField', [], {'max_length': '1', 'null': 'True', 'blank': 'True'}),
            'image': ('django.db.models.fields.files.ImageField', [], {'max_length': '255', 'null': 'True', 'blank': 'True'}),
            'is_ai': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'is_guest': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'last_played_on': ('django.db.models.fields.DateTimeField', [], {'default': 'datetime.datetime(2013, 3, 17, 0, 0)'}),
            'logged_in': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'progress_points_bucket': ('django.db.models.fields.related.ForeignKey', [], {'default': '1', 'to': "orm['game.ProgressPointsBucket']"}),
            'progress_points_in_bucket': ('django.db.models.fields.IntegerField', [], {'default': '0'}),
            'raw_data': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'}),
            'total_progress_points': ('django.db.models.fields.IntegerField', [], {'default': '0'}),
            'user': ('django.db.models.fields.related.OneToOneField', [], {'to': "orm['auth.User']", 'unique': 'True', 'primary_key': 'True'}),
            'website_url': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'})
        },
        'game.pointaward': {
            'Meta': {'object_name': 'PointAward'},
            'has_location': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '30'}),
            'points': ('django.db.models.fields.IntegerField', [], {}),
            'points_color': ('django.db.models.fields.CharField', [], {'default': "'D4A017'", 'max_length': '6'}),
            'text_color': ('django.db.models.fields.CharField', [], {'default': "'8A4117'", 'max_length': '6'})
        },
        'game.progresspointsbucket': {
            'Meta': {'object_name': 'ProgressPointsBucket'},
            'number_of_points_in_bucket': ('django.db.models.fields.IntegerField', [], {}),
            'order': ('django.db.models.fields.IntegerField', [], {'primary_key': 'True'})
        }
    }

    complete_apps = ['game']