import 'package:flutter/material.dart';
import '../providers/recipes_provider.dart';

class RecipeTilePage extends StatelessWidget {
  final Recipe recipe;
  const RecipeTilePage({Key? key, required this.recipe}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (recipe.thumbnail.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  recipe.thumbnail,
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                ),
              ),
            const SizedBox(height: 20),
            if (recipe.description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Description:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(recipe.description),
                  const SizedBox(height: 16),
                ],
              ),
            const Text('Ingredients:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ...recipe.ingredients.map((ing) => Text('• $ing')).toList(),
            const SizedBox(height: 16),
            if (recipe.instructions.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Instructions:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text(recipe.instructions),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
