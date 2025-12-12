import 'package:flutter/material.dart';

/// Widget de carte de statistique pour le dashboard admin
class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final String trend;
  final bool trendUp;
  final bool isClickable;
  final VoidCallback? onTap;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    required this.trend,
    required this.trendUp,
    this.isClickable = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isClickable 
              ? const Color.fromARGB(255, 44, 80, 164).withOpacity(0.3)
              : const Color(0xFFE2E8F0).withOpacity(0.4),
          width: isClickable ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête avec icône et flèche si cliquable
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icône
              Container(
                height: 40,
                width: 40,
                decoration: BoxDecoration(
                  color: const Color.fromARGB(255, 44, 80, 164).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color.fromARGB(255, 44, 80, 164),
                  size: 20,
                ),
              ),
              
              // Flèche pour indiquer que c'est cliquable
              if (isClickable)
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: const Color.fromARGB(255, 44, 80, 164).withOpacity(0.7),
                ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Titre
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          
          const SizedBox(height: 4),
          
          // Valeur
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0F172A),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Tendance
          Row(
            children: [
              Icon(
                trendUp ? Icons.trending_up : Icons.trending_down,
                size: 14,
                color: trendUp ? const Color(0xFF10B981) : const Color(0xFFEF4444),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 11,
                    color: trendUp ? const Color(0xFF10B981) : const Color(0xFFEF4444),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );

    // Si la carte est cliquable, l'envelopper dans un GestureDetector et MouseRegion
    if (isClickable && onTap != null) {
      return MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onTap,
          child: cardContent,
        ),
      );
    }
    
    return cardContent;
  }
}