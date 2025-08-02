import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/recipes_provider.dart';
import 'recipe_tile.dart';
import 'add_recipe_page.dart';

class RecipesPage extends ConsumerStatefulWidget {
  const RecipesPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends ConsumerState<RecipesPage> {
  String query = "italian wedding soup";

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(recipesProvider).fetchRecipes(query);
    });
  }

  Future<void> _search(String newQuery) async {
    query = newQuery;
    await ref.read(recipesProvider).fetchRecipes(newQuery);
  }

  void _openAddRecipePage() {
    Navigator.push(context, MaterialPageRoute(builder: (_) => AddRecipePage()));
  }

  void _openRecipeDetails(Recipe recipe) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => RecipeTilePage(recipe: recipe)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = ref.watch(recipesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () async {
              final result = await showSearch(
                context: context,
                delegate: RecipeSearchDelegate(_search),
              );
              if (result != null && result.isNotEmpty) {
                _search(result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Recipe',
            onPressed: _openAddRecipePage,
          ),
        ],
      ),
      body: provider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : provider.filteredRecipes.isEmpty
          ? const Center(child: Text('No recipes found. Try searching!'))
          : ListView.builder(
        itemCount: provider.filteredRecipes.length,
        itemBuilder: (ctx, idx) {
          final recipe = provider.filteredRecipes[idx];
          return ListTile(
            leading: recipe.thumbnail.isNotEmpty
                ? Image.network(recipe.thumbnail, width: 60, height: 60, fit: BoxFit.cover)
                : const Icon(Icons.fastfood, size: 40),
            title: Text(recipe.name),
            subtitle: Text(recipe.ingredientsPreview),
            onTap: () => _openRecipeDetails(recipe),
          );
        },
      ),
    );
  }
}

class RecipeSearchDelegate extends SearchDelegate<String?> {
  final Future<void> Function(String) onSearch;

  RecipeSearchDelegate(this.onSearch);

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () => query = '',
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    icon: const Icon(Icons.arrow_back),
    onPressed: () => close(context, null),
  );

  @override
  Widget buildResults(BuildContext context) {
    close(context, query);
    return const SizedBox.shrink();
  }

  @override
  Widget buildSuggestions(BuildContext context) => const SizedBox.shrink();
}
