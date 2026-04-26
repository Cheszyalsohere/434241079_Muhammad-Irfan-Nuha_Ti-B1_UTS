/// Remote datasource for notifications. Wraps PostgREST CRUD + the
/// `Supabase.from('notifications').stream(...)` realtime API.
///
/// `.stream()` emits the full current list whenever rows change for
/// the filtered set. We rely on RLS to restrict each user to their
/// own rows; the explicit `eq('user_id', ...)` is a belt-and-braces
/// filter so the client also shapes the subscription locally.
library;

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import '../../../../core/config/app_constants.dart';
import '../../../../core/errors/exceptions.dart';
import '../models/notification_model.dart';

class NotificationRemoteDataSource {
  NotificationRemoteDataSource(this._client);

  final sb.SupabaseClient _client;

  /// One-shot fetch — newest first.
  Future<List<NotificationModel>> fetchNotifications(String userId) async {
    try {
      final List<dynamic> rows = await _client
          .from(AppConstants.tblNotifications)
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);
      return rows
          .map((dynamic r) =>
              NotificationModel.fromJson(Map<String, dynamic>.from(r as Map)))
          .toList(growable: false);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal memuat notifikasi.', cause: e);
    }
  }

  /// Mark a single notification as read.
  Future<void> markAsRead(String notificationId) async {
    try {
      await _client
          .from(AppConstants.tblNotifications)
          .update(<String, dynamic>{'is_read': true})
          .eq('id', notificationId);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal menandai notifikasi.', cause: e);
    }
  }

  /// Mark every notification belonging to [userId] as read.
  Future<void> markAllAsRead(String userId) async {
    try {
      await _client
          .from(AppConstants.tblNotifications)
          .update(<String, dynamic>{'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } on sb.PostgrestException catch (e) {
      throw ServerException(e.message, cause: e);
    } catch (e) {
      throw ServerException('Gagal menandai notifikasi.', cause: e);
    }
  }

  /// Realtime subscription. Emits the full current list every time
  /// rows change for [userId]. Order is enforced client-side because
  /// `.stream()` returns rows in arbitrary order on each emission.
  Stream<List<NotificationModel>> subscribeToNotifications(String userId) {
    return _client
        .from(AppConstants.tblNotifications)
        .stream(primaryKey: <String>['id'])
        .eq('user_id', userId)
        .order('created_at', ascending: false)
        .map((List<Map<String, dynamic>> rows) => rows
            .map(NotificationModel.fromJson)
            .toList(growable: false));
  }
}
