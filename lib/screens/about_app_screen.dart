import 'package:flutter/material.dart';

class AboutAppScreen extends StatelessWidget {
  const AboutAppScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        color: const Color(0xFF0E181E), 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 40), 
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).pop(); // Návrat na předchozí stránku
                },
              ),
            ),
            const SizedBox(height: 20), 
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'O aplikaci',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  '''
Tato aplikace slouží pro plánování úkolů, sledování cílů a organizaci skupinové spolupráce. 

Hlavní funkce aplikace:
- Správa úkolů s možností přidání poznámek.
- Vytváření skupin s kalendářem pro sdílené plánování.
- Sledování cílů a úkolů na denní bázi.

Aplikace je navržena pro snadné a intuitivní používání, aby vám pomohla zůstat organizovaný a produktivní.

Děkujeme, že používáte naši aplikaci!
                  ''',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
