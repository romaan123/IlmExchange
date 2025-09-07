import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class SearchService {
  static const String _recentSearchesKey = 'recent_searches';
  static const int _maxRecentSearches = 10;
  
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Save search query to recent searches
  static Future<void> saveRecentSearch(String query) async {
    if (query.trim().isEmpty) return;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      List<String> recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
      
      // Remove if already exists
      recentSearches.remove(query);
      
      // Add to beginning
      recentSearches.insert(0, query);
      
      // Keep only max items
      if (recentSearches.length > _maxRecentSearches) {
        recentSearches = recentSearches.take(_maxRecentSearches).toList();
      }
      
      await prefs.setStringList(_recentSearchesKey, recentSearches);
    } catch (e) {
      debugPrint('Error saving recent search: $e');
    }
  }

  // Get recent searches
  static Future<List<String>> getRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getStringList(_recentSearchesKey) ?? [];
    } catch (e) {
      debugPrint('Error getting recent searches: $e');
      return [];
    }
  }

  // Clear recent searches
  static Future<void> clearRecentSearches() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_recentSearchesKey);
    } catch (e) {
      debugPrint('Error clearing recent searches: $e');
    }
  }

  // Get search suggestions based on existing skills
  static Future<List<String>> getSearchSuggestions(String query) async {
    if (query.trim().isEmpty) return [];
    
    try {
      final suggestions = <String>{};
      
      // Search in skill titles
      final titleQuery = await _firestore
          .collection('skills')
          .where('title', isGreaterThanOrEqualTo: query)
          .where('title', isLessThan: '${query}z')
          .limit(5)
          .get();
      
      for (final doc in titleQuery.docs) {
        final data = doc.data();
        final title = data['title'] as String?;
        if (title != null && title.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(title);
        }
      }
      
      // Search in categories
      final categoryQuery = await _firestore
          .collection('skills')
          .where('category', isGreaterThanOrEqualTo: query)
          .where('category', isLessThan: '${query}z')
          .limit(5)
          .get();
      
      for (final doc in categoryQuery.docs) {
        final data = doc.data();
        final category = data['category'] as String?;
        if (category != null && category.toLowerCase().contains(query.toLowerCase())) {
          suggestions.add(category);
        }
      }
      
      return suggestions.take(8).toList();
    } catch (e) {
      debugPrint('Error getting search suggestions: $e');
      return [];
    }
  }

  // Get popular skills (trending)
  static Future<List<String>> getPopularSkills() async {
    try {
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      
      final query = await _firestore
          .collection('skills')
          .where('timestamp', isGreaterThan: Timestamp.fromDate(lastWeek))
          .orderBy('timestamp', descending: true)
          .limit(20)
          .get();
      
      final skillCounts = <String, int>{};
      
      for (final doc in query.docs) {
        final data = doc.data();
        final title = data['title'] as String?;
        final category = data['category'] as String?;
        
        if (title != null) {
          skillCounts[title] = (skillCounts[title] ?? 0) + 1;
        }
        if (category != null) {
          skillCounts[category] = (skillCounts[category] ?? 0) + 1;
        }
      }
      
      final sortedSkills = skillCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return sortedSkills.take(10).map((e) => e.key).toList();
    } catch (e) {
      debugPrint('Error getting popular skills: $e');
      return [];
    }
  }

  // Search skills with advanced filtering
  static Future<List<Map<String, dynamic>>> searchSkills({
    required String query,
    String? category,
    String? mode,
    String? level,
    int limit = 20,
  }) async {
    try {
      Query skillsQuery = _firestore.collection('skills');
      
      // Apply filters
      if (category != null && category.isNotEmpty) {
        skillsQuery = skillsQuery.where('category', isEqualTo: category);
      }
      
      if (mode != null && mode.isNotEmpty) {
        skillsQuery = skillsQuery.where('mode', isEqualTo: mode);
      }
      
      if (level != null && level.isNotEmpty) {
        skillsQuery = skillsQuery.where('experienceLevel', isEqualTo: level);
      }
      
      // Order by timestamp for now (could be improved with search ranking)
      skillsQuery = skillsQuery.orderBy('timestamp', descending: true).limit(limit);
      
      final querySnapshot = await skillsQuery.get();
      final results = <Map<String, dynamic>>[];
      
      for (final doc in querySnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        
        // If there's a text query, filter by it
        if (query.isNotEmpty) {
          final title = (data['title'] as String? ?? '').toLowerCase();
          final description = (data['description'] as String? ?? '').toLowerCase();
          final userEmail = (data['userEmail'] as String? ?? '').toLowerCase();
          final searchQuery = query.toLowerCase();
          
          if (title.contains(searchQuery) || 
              description.contains(searchQuery) || 
              userEmail.contains(searchQuery)) {
            results.add(data);
          }
        } else {
          results.add(data);
        }
      }
      
      return results;
    } catch (e) {
      debugPrint('Error searching skills: $e');
      return [];
    }
  }

  // Get search analytics (for admin/insights)
  static Future<Map<String, int>> getSearchAnalytics() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final recentSearches = prefs.getStringList(_recentSearchesKey) ?? [];
      
      final analytics = <String, int>{};
      for (final search in recentSearches) {
        analytics[search] = (analytics[search] ?? 0) + 1;
      }
      
      return analytics;
    } catch (e) {
      debugPrint('Error getting search analytics: $e');
      return {};
    }
  }
}
