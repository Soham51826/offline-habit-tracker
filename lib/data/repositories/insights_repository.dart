import '../datasources/database_helper.dart';
import '../models/behavioral_insight.dart';

class InsightsRepository {
  final DatabaseHelper _dbHelper;

  InsightsRepository({DatabaseHelper? dbHelper})
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  Future<List<BehavioralInsight>> getActiveInsights() async {
    return await _dbHelper.getActiveInsights();
  }

  Future<void> saveInsights(List<BehavioralInsight> insights) async {
    await _dbHelper.saveInsights(insights);
  }

  Future<void> dismissInsight(String insightId) async {
    await _dbHelper.dismissInsight(insightId);
  }

  Future<void> clearAllInsights() async {
    await _dbHelper.clearAllInsights();
  }
}
