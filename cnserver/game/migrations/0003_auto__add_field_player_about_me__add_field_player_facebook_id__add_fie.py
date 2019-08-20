# -*- coding: utf-8 -*-
import datetime
from south.db import db
from south.v2 import SchemaMigration
from django.db import models


class Migration(SchemaMigration):

    def forwards(self, orm):
        # Adding field 'Player.about_me'
        db.add_column('game_player', 'about_me',
                      self.gf('django.db.models.fields.TextField')(null=True, blank=True),
                      keep_default=False)

        # Adding field 'Player.facebook_id'
        db.add_column('game_player', 'facebook_id',
                      self.gf('django.db.models.fields.BigIntegerField')(unique=True, null=True, blank=True),
                      keep_default=False)

        # Adding field 'Player.access_token'
        db.add_column('game_player', 'access_token',
                      self.gf('django.db.models.fields.TextField')(null=True, blank=True),
                      keep_default=False)

        # Adding field 'Player.facebook_name'
        db.add_column('game_player', 'facebook_name',
                      self.gf('django.db.models.fields.CharField')(max_length=255, null=True, blank=True),
                      keep_default=False)

        # Adding field 'Player.facebook_profile_url'
        db.add_column('game_player', 'facebook_profile_url',
                      self.gf('django.db.models.fields.TextField')(null=True, blank=True),
                      keep_default=False)

        # Adding field 'Player.website_url'
        db.add_column('game_player', 'website_url',
                      self.gf('django.db.models.fields.TextField')(null=True, blank=True),
                      keep_default=False)

        # Adding field 'Player.blog_url'
        db.add_column('game_player', 'blog_url',
                      self.gf('django.db.models.fields.TextField')(null=True, blank=True),
                      keep_default=False)

        # Adding field 'Player.date_of_birth'
        db.add_column('game_player', 'date_of_birth',
                      self.gf('django.db.models.fields.DateField')(null=True, blank=True),
                      keep_default=False)

        # Adding field 'Player.gender'
        db.add_column('game_player', 'gender',
                      self.gf('django.db.models.fields.CharField')(max_length=1, null=True, blank=True),
                      keep_default=False)

        # Adding field 'Player.raw_data'
        db.add_column('game_player', 'raw_data',
                      self.gf('django.db.models.fields.TextField')(null=True, blank=True),
                      keep_default=False)

        # Adding field 'Player.facebook_open_graph'
        db.add_column('game_player', 'facebook_open_graph',
                      self.gf('django.db.models.fields.BooleanField')(default=True),
                      keep_default=False)

        # Adding field 'Player.image'
        db.add_column('game_player', 'image',
                      self.gf('django.db.models.fields.files.ImageField')(max_length=255, null=True, blank=True),
                      keep_default=False)


    def backwards(self, orm):
        # Deleting field 'Player.about_me'
        db.delete_column('game_player', 'about_me')

        # Deleting field 'Player.facebook_id'
        db.delete_column('game_player', 'facebook_id')

        # Deleting field 'Player.access_token'
        db.delete_column('game_player', 'access_token')

        # Deleting field 'Player.facebook_name'
        db.delete_column('game_player', 'facebook_name')

        # Deleting field 'Player.facebook_profile_url'
        db.delete_column('game_player', 'facebook_profile_url')

        # Deleting field 'Player.website_url'
        db.delete_column('game_player', 'website_url')

        # Deleting field 'Player.blog_url'
        db.delete_column('game_player', 'blog_url')

        # Deleting field 'Player.date_of_birth'
        db.delete_column('game_player', 'date_of_birth')

        # Deleting field 'Player.gender'
        db.delete_column('game_player', 'gender')

        # Deleting field 'Player.raw_data'
        db.delete_column('game_player', 'raw_data')

        # Deleting field 'Player.facebook_open_graph'
        db.delete_column('game_player', 'facebook_open_graph')

        # Deleting field 'Player.image'
        db.delete_column('game_player', 'image')


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
        'game.game': {
            'Meta': {'object_name': 'Game'},
            'black_player': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'games_black_set'", 'to': "orm['game.Player']"}),
            'board': ('picklefield.fields.PickledObjectField', [], {}),
            'created_on': ('django.db.models.fields.DateTimeField', [], {'auto_now_add': 'True', 'blank': 'True'}),
            'id': ('django.db.models.fields.AutoField', [], {'primary_key': 'True'}),
            'moves': ('picklefield.fields.PickledObjectField', [], {}),
            'next_player': ('django.db.models.fields.CharField', [], {'default': "'white'", 'max_length': '5'}),
            'status': ('django.db.models.fields.CharField', [], {'default': "'not_started'", 'max_length': '15'}),
            'white_player': ('django.db.models.fields.related.ForeignKey', [], {'related_name': "'games_white_set'", 'to': "orm['game.Player']"})
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
            'last_played_on': ('django.db.models.fields.DateTimeField', [], {'default': 'datetime.datetime(2013, 2, 17, 0, 0)'}),
            'logged_in': ('django.db.models.fields.BooleanField', [], {'default': 'False'}),
            'raw_data': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'}),
            'user': ('django.db.models.fields.related.OneToOneField', [], {'to': "orm['auth.User']", 'unique': 'True', 'primary_key': 'True'}),
            'website_url': ('django.db.models.fields.TextField', [], {'null': 'True', 'blank': 'True'})
        }
    }

    complete_apps = ['game']