# -*- coding: utf-8 -*-
import datetime
from south.db import db
from south.v2 import SchemaMigration
from django.db import models


class Migration(SchemaMigration):

    def forwards(self, orm):
        # Deleting model 'ProgressPointsBucket'
        db.delete_table(u'game_progresspointsbucket')

        # Adding model 'Level'
        db.create_table(u'game_level', (
            ('number', self.gf('django.db.models.fields.IntegerField')(primary_key=True)),
            ('points', self.gf('django.db.models.fields.IntegerField')()),
            ('awards', self.gf('picklefield.fields.PickledObjectField')(null=True)),
        ))
        db.send_create_signal(u'game', ['Level'])

        # Adding model 'Age'
        db.create_table(u'game_age', (
            ('number', self.gf('django.db.models.fields.IntegerField')(primary_key=True)),
            ('awarded_on_level', self.gf('django.db.models.fields.related.ForeignKey')(to=orm['game.Level'])),
            ('portraits', self.gf('django.db.models.fields.files.ImageField')(max_length=255)),
            ('table', self.gf('django.db.models.fields.files.ImageField')(max_length=255)),
        ))
        db.send_create_signal(u'game', ['Age'])

        # Deleting field 'Player.progress_points_in_bucket'
        db.delete_column(u'game_player', 'progress_points_in_bucket')

        # Deleting field 'Player.progress_points_bucket'
        db.delete_column(u'game_player', 'progress_points_bucket_id')

        # Deleting field 'Player.total_progress_points'
        db.delete_column(u'game_player', 'total_progress_points')

        # Adding field 'Player.progress_points'
        db.add_column(u'game_player', 'progress_points',
                      self.gf('django.db.models.fields.IntegerField')(default=0),
                      keep_default=False)

        # Adding field 'Player.age'
        db.add_column(u'game_player', 'age',
                      self.gf('django.db.models.fields.related.ForeignKey')(default=1, to=orm['game.Age']),
                      keep_default=False)

        # Adding field 'Player.level'
        db.add_column(u'game_player', 'level',
                      self.gf('django.db.models.fields.related.ForeignKey')(default=1, to=orm['game.Level']),
                      keep_default=False)

        # Deleting field 'Nation.leader_img'
        db.delete_column(u'game_nation', 'leader_img')

        # Adding field 'Nation.leader_image'
        db.add_column(u'game_nation', 'leader_image',
                      self.gf('django.db.models.fields.files.ImageField')(max_length=255, null=True),
                      keep_default=False)


    def backwards(self, orm):
        # Adding model 'ProgressPointsBucket'
        db.create_table(u'game_progresspointsbucket', (
            ('number_of_points_in_bucket', self.gf('django.db.models.fields.IntegerField')()),
            ('order', self.gf('django.db.models.fields.IntegerField')(primary_key=True)),
        ))
        db.send_create_signal(u'game', ['ProgressPointsBucket'])

        # Deleting model 'Level'
        db.delete_table(u'game_level')

        # Deleting model 'Age'
        db.delete_table(u'game_age')

        # Adding field 'Player.progress_points_in_bucket'
        db.add_column(u'game_player', 'progress_points_in_bucket',
                      self.gf('django.db.models.fields.IntegerField')(default=0),
                      keep_default=False)

        # Adding field 'Player.progress_points_bucket'
        db.add_column(u'game_player', 'progress_points_bucket',
                      self.gf('django.db.models.fields.related.ForeignKey')(default=1, to=orm['game.ProgressPointsBucket']),
                      keep_default=False)

        # Adding field 'Player.total_progress_points'
        db.add_column(u'game_player', 'total_progress_points',
                      self.gf('django.db.models.fields.IntegerField')(default=0),
                      keep_default=False)

        # Deleting field 'Player.progress_points'
        db.delete_column(u'game_player', 'progress_points')

        # Deleting field 'Player.age'
        db.delete_column(u'game_player', 'age_id')

        # Deleting field 'Player.level'
        db.delete_column(u'game_player', 'level_id')


        # User chose to not deal with backwards NULL issues for 'Nation.leader_img'
        raise RuntimeError("Cannot reverse this migration. 'Nation.leader_img' and its values cannot be restored.")
        # Deleting field 'Nation.leader_image'
        db.delete_column(u'game_nation', 'leader_image')


    models = {
        u'auth.group': {
            'Meta': {'object_name': 'Group'},
            u'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'unique': 'True', 'max_length': '80'}),
            'permissions': ('django.db.models.fields.related.ManyToManyField', [], {'to': u"orm['auth.Permission']", 'symmetrical': 'False', 'blank': 'True'})
        },
        u'auth.permission': {
            'Meta': {'ordering': "(u'content_type__app_label', u'content_type__model', u'codename')", 'unique_together': "((u'content_type', u'codename'),)", 'object_name': 'Permission'},
            'codename': ('django.db.models.fields.CharField', [], {'max_length': '100'}),
            'content_type': ('django.db.models.fields.related.ForeignKey', [], {'to': u"orm['contenttypes.ContentType']"}),
            u'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '50'})
        },
        u'auth.user': {
            'Meta': {'object_name': 'User'},
            'date_joined': ('django.db.models.fields.DateTimeField', [], {'default': 'datetime.datetime.now'}),
            'email': ('django.db.models.fields.EmailField', [], {'max_length': '75', 'blank': 'True'}),
            'first_name': ('django.db.models.fields.CharField', [], {'max_length': '30', 'blank': 'True'}),
            'groups': ('django.db.models.fields.related.ManyToManyField', [], {'to': u"orm['auth.Group']", 'symmetrical': 'False', 'blank': 'True'}),
            u'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'is_active': ('django.db.models.fields.BooleanField', [], {'default': 'True'}),
            'is_staff': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'is_superuser': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'last_login': ('django.db.models.fields.DateTimeField', [], {'default': 'datetime.datetime.now'}),
            'last_name': ('django.db.models.fields.CharField', [], {'max_length': '30', 'blank': 'True'}),
            'password': ('django.db.models.fields.CharField', [], {'max_length': '128'}),
            'user_permissions': ('django.db.models.fields.related.ManyToManyField', [], {'to': u"orm['auth.Permission']", 'symmetrical': 'False', 'blank': 'True'}),
            'username': ('django.db.models.fields.CharField', [], {'unique': 'True', 'max_length': '30'})
        },
        u'contenttypes.contenttype': {
            'Meta': {'ordering': "('name',)", 'unique_together': "(('app_label', 'model'),)", 'object_name': 'ContentType', 'db_table': "'django_content_type'"},
            'app_label': ('django.db.models.fields.CharField', [], {'max_length': '100'}),
            u'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'model': ('django.db.models.fields.CharField', [], {'max_length': '100'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '100'})
        },
        u'game.age': {
            'Meta': {'object_name': 'Age'},
            'awarded_on_level': ('django.db.models.fields.related.ForeignKey', [], {'to': u"orm['game.Level']"}),
            'number': ('django.db.models.fields.IntegerField', [], {'primary_key': 'True'}),
            'portraits': ('django.db.models.fields.files.ImageField', [], {'max_length': '255'}),
            'table': ('django.db.models.fields.files.ImageField', [], {'max_length': '255'})
        },
        u'game.capturepointaward': {
            'Meta': {'object_name': 'CapturePointAward', '_ormbases': [u'game.PointAward']},
            'captured_piece': ('django.db.models.fields.CharField', [], {'max_length': '10'}),
            u'pointaward_ptr': ('django.db.models.fields.related.OneToOneField', [], {'to': u"orm['game.PointAward']", 'unique': 'True', 'primary_key': 'True'})
        },
        u'game.endgameaward': {
            'Meta': {'object_name': 'EndGameAward', '_ormbases': [u'game.PointAward']},
            'outcome': ('django.db.models.fields.CharField', [], {'max_length': '15'}),
            u'pointaward_ptr': ('django.db.models.fields.related.OneToOneField', [], {'to': u"orm['game.PointAward']", 'unique': 'True', 'primary_key': 'True'})
        },
        u'game.game': {
            'Meta': {'object_name': 'Game'},
            'black_player': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'games_black_set'", 'to': u"orm['game.Player']"}),
            'black_time_remaining': ('django.db.models.fields.IntegerField', [], {'default': '5400'}),
            'board': ('picklefield.fields.PickledObjectField', [], {}),
            'created_on': ('django.db.models.fields.DateTimeField', [], {'auto_now_add': 'True', 'blank': 'True'}),
            u'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'last_move_on': ('django.db.models.fields.DateTimeField', [], {'null': 'True'}),
            'moves': ('picklefield.fields.PickledObjectField', [], {}),
            'next_player': ('django.db.models.fields.CharField', [], {'default': "'white'", 'max_length': '5'}),
            'outcome': ('django.db.models.fields.CharField', [], {'default': "'undecided'", 'max_length': '15'}),
            'status': ('django.db.models.fields.CharField', [], {'default': "'not_started'", 'max_length': '15'}),
            'white_player': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'games_white_set'", 'to': u"orm['game.Player']"}),
            'white_time_remaining': ('django.db.models.fields.IntegerField', [], {'default': '5400'})
        },
        u'game.level': {
            'Meta': {'object_name': 'Level'},
            'awards': ('picklefield.fields.PickledObjectField', [], {'null': 'True'}),
            'number': ('django.db.models.fields.IntegerField', [], {'primary_key': 'True'}),
            'points': ('django.db.models.fields.IntegerField', [], {})
        },
        u'game.movelistpointaward': {
            'Meta': {'object_name': 'MoveListPointAward', '_ormbases': [u'game.PointAward']},
            'is_rule_only_for_last_move': ('django.db.models.fields.BooleanField', [], {'default': 'True'}),
            u'pointaward_ptr': ('django.db.models.fields.related.OneToOneField', [], {'to': u"orm['game.PointAward']", 'unique': 'True', 'primary_key': 'True'}),
            'regexp': ('django.db.models.fields.CharField', [], {'max_length': '100'})
        },
        u'game.nation': {
            'Meta': {'object_name': 'Nation'},
            'leader_image': ('django.db.models.fields.files.ImageField', [], {'max_length': '255', 'null': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '30', 'primary_key': 'True'})
        },
        u'game.player': {
            'Meta': {'object_name': 'Player'},
            'about_me': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'}),
            'access_token': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'}),
            'age': ('django.db.models.fields.related.ForeignKey', [], {'default': '1', 'to': u"orm['game.Age']"}),
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
            'last_played_on': ('django.db.models.fields.DateTimeField', [], {'default': 'datetime.datetime(2013, 4, 15, 0, 0)'}),
            'level': ('django.db.models.fields.related.ForeignKey', [], {'default': '1', 'to': u"orm['game.Level']"}),
            'logged_in': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'nation': ('django.db.models.fields.related.ForeignKey', [], {'to': u"orm['game.Nation']", 'null': 'True'}),
            'progress_points': ('django.db.models.fields.IntegerField', [], {'default': '0'}),
            'raw_data': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'}),
            'user': ('django.db.models.fields.related.OneToOneField', [], {'to': u"orm['auth.User']", 'unique': 'True', 'primary_key': 'True'}),
            'website_url': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'})
        },
        u'game.pointaward': {
            'Meta': {'object_name': 'PointAward'},
            'has_location': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            u'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'name': ('django.db.models.fields.CharField', [], {'max_length': '30'}),
            'points': ('django.db.models.fields.IntegerField', [], {}),
            'points_color': ('django.db.models.fields.CharField', [], {'default': "'D4A017'", 'max_length': '6'}),
            'text_color': ('django.db.models.fields.CharField', [], {'default': "'8A4117'", 'max_length': '6'})
        }
    }

    complete_apps = ['game']