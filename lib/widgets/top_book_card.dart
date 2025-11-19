import 'package:flutter/material.dart';

/// Widget représentant un livre populaire avec son nombre d'emprunts
class TopBookCard extends StatelessWidget {
  final String title;
  final String author;
  final int loans;

  const TopBookCard({
    Key? key,
    required this.title,
    required this.author,
    required this.loans,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Icône de livre
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 44, 80, 164).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.menu_book,
              color: Color.fromARGB(255, 44, 80, 164),
              size: 24,
            ),
          ),
          
          SizedBox(width: 12),
          
          // Informations du livre
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0F172A),
                    height: 1.3,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4),
                Text(
                  author,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          
          SizedBox(width: 8),
          
          // Badge du nombre d'emprunts
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 44, 80, 164),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$loans',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}