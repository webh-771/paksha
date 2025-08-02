import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/recipes_provider.dart';

class AddRecipePage extends StatefulWidget {
  @override
  _AddRecipePageState createState() => _AddRecipePageState();
}

class _AddRecipePageState extends State<AddRecipePage> {
  final _formKey = GlobalKey<FormState>();
  String name = '';
  String ingredients = '';
  String steps = '';
  String cuisine = '';

  @override
  Widget build(BuildContext context) {
    final recipesProvider = Provider.of<RecipesProvider>(context, listen: false);

    return Scaffold(
      appBar: AppBar(title: Text('Add Recipe')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                decoration: InputDecoration(labelText: 'Recipe Name'),
                validator: (val) =>
                val == null || val.isEmpty ? 'Enter a name' : null,
                onSaved: (val) => name = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Cuisine (optional)'),
                onSaved: (val) => cuisine = val ?? '',
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Ingredients'),
                minLines: 2,
                maxLines: 5,
                validator: (val) =>
                val == null || val.isEmpty ? 'Enter ingredients' : null,
                onSaved: (val) => ingredients = val!,
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Steps'),
                minLines: 3,
                maxLines: 8,
                validator: (val) =>
                val == null || val.isEmpty ? 'Enter steps' : null,
                onSaved: (val) => steps = val!,
              ),
              SizedBox(height: 20),

            ],
          ),
        ),
      ),
    );
  }
}
