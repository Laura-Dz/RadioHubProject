import 'package:flutter/material.dart';
import '../../../core/models/language_model.dart';

class LanguageTile extends StatelessWidget {
  final LanguageModel language;
  final bool isSelected;
  final VoidCallback onTap;

  const LanguageTile({
    Key? key,
    required this.language,
    required this.isSelected,
    required this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Text(language.flag, style: const TextStyle(fontSize: 32)),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    language.nativeName,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    language.name,
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.blue, size: 28),
          ],
        ),
      ),
    );
  }
}
