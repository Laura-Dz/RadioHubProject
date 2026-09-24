import 'package:flutter/material.dart';
import '../programs/programs_screen.dart';

class ProgramsTab extends StatelessWidget {
  final String radioId;

  const ProgramsTab({Key? key, required this.radioId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const ProgramsScreen();
  }
}