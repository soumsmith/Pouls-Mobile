---
name: login_page
description: Règles et spécifications pour la page de connexion (sélection profil, école, identification)
---
# Spécifications Fonctionnelles - Page de Connexion

## Contexte
Cette page permet à l'utilisateur de s'authentifier dans l'application mobile en sélectionnant son profil et son établissement, puis en saisissant ses identifiants.

## Éléments de l'Interface

### 1. Sélection du Profil (Rôle)
L'utilisateur doit pouvoir choisir son type de profil parmi les acteurs définis dans les spécifications (ex: Élève, Parent, Professeur, Administration...).

> [!IMPORTANT]
> **Contrainte Technique :** Ce champ de sélection **DOIT obligatoirement** utiliser le composant `SearchableDropdown` (comme décrit dans le skill `searchable_dropdown`).

### 2. Sélection de l'École
L'application étant multi-écoles (échelle nationale), l'utilisateur doit rechercher et sélectionner son établissement scolaire.

> [!IMPORTANT]
> **Contrainte Technique :** Ce champ de sélection **DOIT obligatoirement** utiliser le composant `SearchableDropdown` pour permettre une recherche intuitive parmi la longue liste d'écoles (comme décrit dans le skill `searchable_dropdown`).

### 3. Saisie des Identifiants
- **Nom d'utilisateur (User)** : Champ texte standard pour saisir l'identifiant, le matricule ou l'email.
- **Mot de passe** : Champ texte sécurisé (caractères masqués) pour saisir le mot de passe.
- **Bouton "Se connecter"** : Déclenche l'appel réseau vers l'API d'authentification en envoyant (Profil, École, User, Password).

---

## Implémentation de Référence (Exemple Dart)

Voici le code modèle de base pour cette page de connexion, à utiliser comme référence lors de son implémentation. Il intègre le composant `SearchableDropdown`.

```dart
import 'package:flutter/material.dart';
// Adapter les chemins d'import selon votre architecture
import '../widgets/searchable_dropdown.dart';
import '../widgets/components/custom_text_input.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  // État de visibilité du mot de passe
  bool _isPasswordVisible = false;
  
  // Données factices pour l'exemple (à remplacer par des données de l'API/Services)
  final List<String> profils = [
    'Élève', 
    'Parent', 
    'Professeur', 
    'Directeur des études', 
    'Administration'
  ];
  final List<String> ecoles = [
    'École Primaire A', 
    'Collège B', 
    'Lycée C', 
    'Groupe Scolaire D'
  ]; 

  String _selectedProfil = "Sélectionnez un profil";
  String _selectedEcole = "Sélectionnez une école";

  void _handleLogin() {
    // TODO: Implémenter la logique d'authentification via AuthService
    final String user = _userController.text;
    final String password = _passwordController.text;
    
    print('Tentative de connexion :');
    print('- Profil : $_selectedProfil');
    print('- École : $_selectedEcole');
    print('- Utilisateur : $user');
  }

  @override
  void dispose() {
    _userController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Détection du thème clair/sombre pour passer au SearchableDropdown
    final bool isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(title: const Text("Connexion")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              
              // 1. SÉLECTION DU PROFIL
              SearchableDropdown(
                label: "Profil utilisateur",
                value: _selectedProfil,
                items: profils,
                isDarkMode: isDarkMode,
                onChanged: (val) {
                  setState(() => _selectedProfil = val);
                },
              ),
              const SizedBox(height: 20),
              
              // 2. SÉLECTION DE L'ÉCOLE
              SearchableDropdown(
                label: "Établissement scolaire",
                value: _selectedEcole,
                items: ecoles,
                isDarkMode: isDarkMode,
                onChanged: (val) {
                  setState(() => _selectedEcole = val);
                },
              ),
              const SizedBox(height: 20),
              
              // 3. SAISIE DU USER
              CustomTextInput(
                label: "Nom d'utilisateur / Matricule",
                hint: "Entrez votre identifiant",
                icon: Icons.person_outline,
                controller: _userController,
                required: true,
              ),
              const SizedBox(height: 20),
              
              // 4. SAISIE DU MOT DE PASSE (AVEC TOGGLE)
              CustomTextInput(
                label: "Mot de passe",
                hint: "Entrez votre mot de passe",
                icon: Icons.lock_outline,
                controller: _passwordController,
                required: true,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      _isPasswordVisible = !_isPasswordVisible;
                    });
                  },
                ),
              ),
              const SizedBox(height: 40),
              
              // 5. BOUTON DE CONNEXION
              ElevatedButton(
                onPressed: _handleLogin,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                ),
                child: const Text("Se connecter", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```
