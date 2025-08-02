import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// API credentials and endpoints
const String rapidApiKey = "7e93b0d6f3msh3136cade64bfd18p15c966jsn41d8d467b7e0";
const String rapidApiHost = "recipe-by-api-ninjas.p.rapidapi.com";
const String rapidApiBaseUrl = "https://recipe-by-api-ninjas.p.rapidapi.com/v1/recipe";

// Recipe Model
class Recipe {
  final String name;
  final String description;
  final List<String> ingredients;
  final String instructions;
  final String thumbnail;

  Recipe({
    required this.name,
    required this.description,
    required this.ingredients,
    required this.instructions,
    required this.thumbnail,
  });

  String get ingredientsPreview =>
      ingredients.length > 2 ? ingredients.take(2).join(', ') : ingredients.join(', ');

  factory Recipe.fromApiNinjasJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      ingredients: json['ingredients'] != null
          ? (json['ingredients'] as String)
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList()
          : [],
      instructions: json['instructions'] ?? '',
      thumbnail: json['thumbnail'] ?? '',
    );
  }
}

// Riverpod provider
final recipesProvider = ChangeNotifierProvider<RecipesProvider>((ref) => RecipesProvider());

class RecipesProvider extends ChangeNotifier {
  bool isLoading = false;
  List<Recipe> _recipes = [];
  String? selectedCuisine;
  Recipe? selectedRecipe;
  int lastOffset = 0;
  String lastQuery = "";

  List<Recipe> get filteredRecipes {
    if (selectedCuisine == null || selectedCuisine!.isEmpty) return _recipes;
    return _recipes
        .where((r) => r.name.toLowerCase().contains(selectedCuisine!.toLowerCase()))
        .toList();
  }

  // FIXED: Only one required query parameter, with optional offset.
  Future<void> fetchRecipes(String query, {int offset = 0}) async {
    isLoading = true;
    notifyListeners();

    final uri = Uri.parse(
        '$rapidApiBaseUrl?query=${Uri.encodeComponent(query)}&offset=$offset');
    final headers = {
      'x-rapidapi-key': rapidApiKey,
      'x-rapidapi-host': rapidApiHost,
    };

    try {
      final response = await http.get(uri, headers: headers);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data is List) {
          _recipes = data
              .map<Recipe>((item) => Recipe.fromApiNinjasJson(item))
              .toList();
        } else {
          _recipes = [];
        }
        lastOffset = offset;
        lastQuery = query;
      } else {
        _recipes = [];
      }
    } catch (e) {
      _recipes = [];
    }

    isLoading = false;
    notifyListeners();
  }

  // Convenience method to load the next set of recipes if implementing pagination
  Future<void> fetchNextPage() async {
    await fetchRecipes(lastQuery, offset: lastOffset + 10);
  }

  void setCuisine(String? cuisine) {
    selectedCuisine = cuisine;
    notifyListeners();
  }

  void setSelectedRecipe(Recipe recipe) {
    selectedRecipe = recipe;
    notifyListeners();
  }
}
