import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
//import '../config/routes.dart';

/// Page d'accueil de l'application Bibliothèque UFR SAT
/// Conversion fidèle du design React/Tailwind
class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Background gradient (from-primary via-primary/90 to-primary/80)
          _buildGradientBackground(),
          
          // Background pattern avec icônes de livres animées (opacity-10)
          _buildBackgroundPattern(),
          
          // Contenu principal (relative z-10)
          _buildMainContent(context),
          
          // Footer fixé en bas
          _buildFooter(),
        ],
      ),
    );
  }

  /// Dégradé de fond - bg-gradient-to-br from-primary via-primary/90 to-primary/80
  Widget _buildGradientBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.fromARGB(255, 44, 80, 164), // primary
            Color.fromARGB(255, 44, 80, 164).withOpacity(0.9), // primary/90
            Color.fromARGB(255, 44, 80, 164).withOpacity(0.8), // primary/80
          ],
        ),
      ),
    );
  }

  /// Pattern de fond avec icônes de livres flottantes
  Widget _buildBackgroundPattern() {
    return Positioned.fill(
      child: Opacity(
        opacity: 0.1, // opacity-10
        child: Stack(
          children: [
            // Top-left book (top-10 left-10, h-20 w-20)
            Positioned(
              top: 40,
              left: 40,
              child: _AnimatedFloatingBook(
                size: 80,
                delay: Duration.zero,
              ),
            ),
            // Top-right book (top-32 right-20, h-16 w-16)
            Positioned(
              top: 128,
              right: 80,
              child: _AnimatedFloatingBook(
                size: 64,
                delay: Duration(seconds: 1),
              ),
            ),
            // Bottom-left book (bottom-20 left-32, h-24 w-24)
            Positioned(
              bottom: 80,
              left: 128,
              child: _AnimatedFloatingBook(
                size: 96,
                delay: Duration(seconds: 2),
              ),
            ),
            // Bottom-right book (bottom-40 right-10, h-18 w-18)
            Positioned(
              bottom: 160,
              right: 40,
              child: _AnimatedFloatingBook(
                size: 72,
                delay: Duration(milliseconds: 500),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Contenu principal centré - flex flex-col items-center justify-center
  Widget _buildMainContent(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: MediaQuery.of(context).size.height - 
                       MediaQuery.of(context).padding.top - 
                       MediaQuery.of(context).padding.bottom,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 32), // px-4 py-8
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center, // justify-center
              crossAxisAlignment: CrossAxisAlignment.center, // items-center
              children: [
                // Logo/Nom avec avatar circulaire
                _buildLogoSection(),
                
                SizedBox(height: 32), // mb-8
                
                // Carte de bienvenue
                _buildWelcomeCard(context),
                
                // Espace supplémentaire pour le footer
                SizedBox(height: 60),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Section logo avec cercle et nom - mb-8
  Widget _buildLogoSection() {
    return Column(
      children: [
        // Avatar circulaire (h-20 w-20 rounded-full bg-accent shadow-lg mb-4)
        Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            color: Color.fromARGB(221, 248, 190, 45), // accent (orange)
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 1,
                blurRadius: 8,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: ClipOval(
              child: Image.asset(
                'assets/images/logo.jpeg',
                width: 80,
                height: 80,
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        
        SizedBox(height: 16), // mb-4
        
        // Titre UFR SAT (text-4xl font-display font-bold text-white)
        Text(
          'UFR SAT',
          style: TextStyle(
            fontSize: 36, // text-4xl
            fontWeight: FontWeight.bold,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  /// Carte de bienvenue - max-w-md w-full p-8 bg-white/95 backdrop-blur-sm shadow-2xl
  Widget _buildWelcomeCard(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxWidth: 448), // max-w-md (28rem = 448px)
      width: double.infinity, // w-full
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.95), // bg-white/95
        borderRadius: BorderRadius.circular(8), // rounded par défaut de Card
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            spreadRadius: 0,
            blurRadius: 25,
            offset: Offset(0, 10), // shadow-2xl
          ),
        ],
      ),
      padding: EdgeInsets.all(32), // p-8
      child: Column(
        children: [
          // Titre "Accueil" (text-2xl font-display font-bold text-primary mb-4)
          Text(
            'Accueil',
            style: TextStyle(
              fontSize: 24, // text-2xl
              fontWeight: FontWeight.bold,
              color: Color.fromARGB(255, 44, 80, 164), // text-primary
            ),
            textAlign: TextAlign.center,
          ),
          
          SizedBox(height: 16), // mb-4
          
          // Espace pour les paragraphes (space-y-4 mb-6)
          _buildWelcomeText(),
          
          SizedBox(height: 24), // mb-6
          
          // Bouton de connexion (w-full h-12 text-lg font-semibold)
          _buildLoginButton(context),
        ],
      ),
    );
  }

  /// Textes de bienvenue - space-y-4
  Widget _buildWelcomeText() {
    return Column(
      children: [
        // Premier paragraphe (text-center text-foreground)
        Text(
          'Bienvenue à la Bibliothèque UFR SAT',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF0F172A), // text-foreground
            fontWeight: FontWeight.w400,
          ),
          textAlign: TextAlign.center,
  
        ),
        
        SizedBox(height: 16), // space-y-4
        
        // Deuxième paragraphe (text-center text-muted-foreground text-sm)
        Text(
          'Cherchez un livre, réservez et empruntez facilement depuis votre smartphone. '
          'Accédez à des milliers d\'ouvrages académiques et scientifiques.',
          style: TextStyle(
            fontSize: 14, // text-sm
            color: Color(0xFF64748B), // text-muted-foreground
            height: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  /// Bouton de connexion
 Widget _buildLoginButton(BuildContext context) {
  return SizedBox(
    width: double.infinity,
    height: 48,
    child: ElevatedButton(
      onPressed: () {
        // Utilisation de GoRouter
        context.go('/login'); // Remplace Navigator.pushNamed
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: Color.fromARGB(255, 44, 80, 164), 
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(
        'Connexion',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
  );
}


  /// Footer avec copyright (mt-8 text-white/80 text-sm)
  Widget _buildFooter() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '© UFR SAT 2025',
              style: TextStyle(
                fontSize: 14, // text-sm
                color: Colors.white.withOpacity(0.8), // text-white/80
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Widget d'icône de livre flottante avec animation
class _AnimatedFloatingBook extends StatefulWidget {
  final double size;
  final Duration delay;

  const _AnimatedFloatingBook({
    super.key,
    required this.size,
    required this.delay,
  });

  @override
  State<_AnimatedFloatingBook> createState() => _AnimatedFloatingBookState();
}

class _AnimatedFloatingBookState extends State<_AnimatedFloatingBook>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    );

    _animation = Tween<double>(begin: -10, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    // Délai avant de démarrer l'animation
    Future.delayed(widget.delay, () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: Icon(
            Icons.menu_book, // Équivalent de BookOpen de lucide-react
            size: widget.size,
            color: Colors.white,
          ),
        );
      },
    );
  }
}