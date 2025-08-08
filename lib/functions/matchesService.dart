import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../router/router.dart';
import 'dart:async';
import 'helpers/fetchData_service.dart';
import 'helpers/saveData_service.dart';
import 'userActionsService.dart';

enum DataSource { cache, firebase }

class MatchesService {

  /* = = = = = = = = =
  Refresh Matches Manually
  = = = = = = = = = */
  Future<void> refreshMatches(BuildContext context) async {
    try {
      final id = await UserActions.getCurrentUserId(context: context);
      if (id != null && id.isNotEmpty) {
        await UserActions.setStatus(id, {
          'needsUpdated': false,
        });
        print('✅ Set needsUpdated flag for refresh');
      }
      
      Navigator.pushNamed(
        context, 
        AppRoutes.matches,
        arguments: {'shouldUpdate': true}
      );
    } catch (e) {
      print('❌ Error in refreshMatches: $e');
    }
  }

  /* = = = = = = = = =
  Calculate + Filter Matches
  = = = = = = = = = */
  Future<List<Map<String, dynamic>>> calculateMatches({bool useCache = true}) async {
    try {
      return [];
    } catch (e) {
      print('Error in calculateMatches: $e');
      return [];
    }
  }
  Future<bool> unmatchUsers(
    BuildContext context,
    String targetUserId
  ) async {
    try {
      // Save local status
      // Get local data
      // Unmatch in Firestore
      // Recalculate matches
      // Update route - go back to matches screen
      /*_routeService.navigateReplace(context, '/matches');*/
      return true;
    } catch (e) {
      print('Error in unmatchUsers: $e');
      return false;
    }
  }
  Future<List<Map<String, dynamic>>> getUnmatchedFromUser(
    BuildContext context
  ) async {
    try {
      // Get user data
      // Save locally
      // Calculate matches (force refresh)
      // Update route status
      /*_routeService.updateRouteStatus('/discover');*/
      return [];
    } catch (e) {
      print('Error in getUnmatchedFromUser: $e');
      return [];
    }
  }

  /* = = = = = = = = =
  Fetch Matches
  = = = = = = = = = */
  Future<List<Map<String, dynamic>>> fetchMatches({
    DataSource source = DataSource.cache,
    bool onlyWithPhotos = false,
    bool forceFresh = false,
    Map<String, dynamic>? additionalFilters,
  }) async {
    try {
      List<Map<String, dynamic>> profiles = [];
      switch (source) {
        case DataSource.cache:
          profiles = await FetchDataService().fetchMatchesFromSharedPreferences();
          break;
        case DataSource.firebase:
          if (forceFresh) {
            await _clearUserCache();
          }
          profiles = await FetchDataService().fetchMatchesFromFirebase(
            onlyWithPhotos: onlyWithPhotos,
            additionalFilters: additionalFilters,
          );
          final cleanedUsers = profiles.map((user) => FetchDataService().cleanUserData(user)).toList();
          await SaveDataService().cacheFetchedProfilesToSharedPrefs(cleanedUsers);
          profiles = cleanedUsers;
          break;
      }
      print('📱 Discovered ${profiles.length} profiles from ${source.name}');
      return profiles;
    } catch (e) {
      print('❌ Error discovering profiles: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> fetchMatchesFromSharedPreferences() async {
    return await fetchMatches(source: DataSource.cache);
  }
  Future<List<Map<String, dynamic>>> fetchMatchesFromFirebase({
    bool onlyWithPhotos = true,
    bool forceFresh = false,
    Map<String, dynamic>? additionalFilters,
  }) async {
    return await fetchMatches(
      source: DataSource.firebase,
      onlyWithPhotos: onlyWithPhotos,
      forceFresh: forceFresh,
      additionalFilters: additionalFilters,
    );
  }

  Future<void> _clearUserCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Get current user ID to preserve their data
      final currentUserId = await UserActions.getCurrentUserId();
      
      final keys = prefs.getKeys().where((key) => 
        key.startsWith('user_data_') && 
        (currentUserId == null || key != 'user_data_$currentUserId') // Don't clear current user's data
      ).toList();
      
      for (var key in keys) {
        await prefs.remove(key);
      }
      print('🧹 Cleared ${keys.length} cached user profiles (preserved current user)');
    } catch (e) {
      print('❌ Error clearing cache: $e');
    }
  }
}