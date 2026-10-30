import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_profile.dart';

class AIPlannerService {

  static const String _endpoint =
      "https://api.groq.com/openai/v1/chat/completions";

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? "";
  // ================= COMMON GROQ CALL =================

  Future<String?> _callGroq(String prompt) async {

    if (_apiKey.isEmpty) {
      print("❌ API KEY NOT FOUND");
      return null;
    }

    try {

      final response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          "Authorization": "Bearer $_apiKey",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": [
            {"role": "user", "content": prompt}
          ],
          "temperature": 0.7
        }),
      );

      print("STATUS CODE: ${response.statusCode}");

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        return decoded["choices"][0]["message"]["content"];
      } else {
        print("Groq API error:");
        print(response.body);
        return null;
      }

    } catch (e) {
      print("Network error: $e");
      return null;
    }
  }

  // ================= DAILY INSIGHT =================

  Future<String> generateDailyInsight(
      UserProfile profile) async {

    final prefs = await SharedPreferences.getInstance();
    final today =
        DateTime.now().toIso8601String().split("T")[0];

    final savedDate =
        prefs.getString("insight_date");

    final savedInsight =
        prefs.getString("insight_text");

    if (savedDate == today &&
        savedInsight != null) {
      return savedInsight;
    }

    final prompt = """
Give a short motivational fitness insight (2-3 lines).

Goal: ${profile.goal}
Experience: ${profile.level}
Medical Conditions: ${profile.medicalConditions}
""";

    final raw = await _callGroq(prompt);
    final insight =
        raw ?? "Stay consistent today 💪";

    await prefs.setString(
        "insight_text", insight);

    await prefs.setString(
        "insight_date", today);

    return insight;
  }

  // ================= NORMAL CHAT =================

  Future<String> generateStructuredReply(
      String text,
      UserProfile profile) async {

    final prompt = """
You are a professional AI fitness coach.

Goal: ${profile.goal}
Experience: ${profile.level}
Medical Conditions: ${profile.medicalConditions}

Question:
$text
""";

    final raw = await _callGroq(prompt);

    return raw ?? "Something went wrong.";
  }

  // ================= CUSTOM DAY PLAN =================

  Future<Map<String, dynamic>?> generateCustomDayPlan(
      UserProfile profile,
      int numberOfDays) async {

    final prompt = """
Return STRICT JSON only.

Format:

{
  "days": [
    {
      "title": "Upper Body",
      "exercises": ["Push-ups"],
      "isRest": false
    }
  ]
}

Do NOT add explanations.
Do NOT add markdown.
Do NOT add text before or after JSON.

Generate full $numberOfDays day workout plan.

Goal: ${profile.goal}
Experience: ${profile.level}
Medical Conditions: ${profile.medicalConditions}
""";

    final raw = await _callGroq(prompt);

    if (raw == null) return null;

    try {

      final startIndex = raw.indexOf("{");
      final endIndex = raw.lastIndexOf("}");

      if (startIndex == -1 || endIndex == -1) {
        print("❌ No valid JSON found");
        return null;
      }

      final jsonString =
          raw.substring(startIndex, endIndex + 1);

      print("CLEANED JSON:");
      print(jsonString);

      return jsonDecode(jsonString);

    } catch (e) {
      print("JSON parse error: $e");
      return null;
    }
  }

  // ================= DIET PLAN =================

  Future<Map<String, dynamic>?> generateDietPlan(
      UserProfile profile, int numberOfDays) async {
    final prompt = """
Return STRICT JSON only.

Format:

{
  "days": [
    {
      "title": "Healthy Day 1",
      "meals": ["Oatmeal with berries", "Chicken Salad"],
      "isRest": false 
    }
  ]
}

- Meals: minimum 3 meals (Breakfast, Lunch, Dinner).
- Do NOT add explanations.
- Do NOT add markdown.
- Do NOT add text before or after JSON.

Generate full $numberOfDays day diet/meal plan.

Goal: ${profile.goal}
Dietary Preference: ${profile.level} (treat as diet style if applicable)
Medical Conditions: ${profile.medicalConditions}
""";

    final raw = await _callGroq(prompt);

    if (raw == null) return null;

    try {
      final startIndex = raw.indexOf("{");
      final endIndex = raw.lastIndexOf("}");

      if (startIndex == -1 || endIndex == -1) {
        print("❌ No valid JSON found");
        return null;
      }

      final jsonString = raw.substring(startIndex, endIndex + 1);

      print("CLEANED DIET JSON:");
      print(jsonString);

      return jsonDecode(jsonString);
    } catch (e) {
      print("JSON parse error: $e");
      return null;
    }
  }
}
