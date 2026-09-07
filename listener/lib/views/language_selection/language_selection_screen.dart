import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../view_models/language_selection_view_model.dart';
import '../../core/models/language_model.dart';
import '../auth/auth_choice_screen.dart';
import 'widgets/language_tile.dart';

class LanguageSelectionScreen extends StatelessWidget {
  const LanguageSelectionScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Consumer<LanguageSelectionViewModel>(
        builder: (context, viewModel, child) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.language,
                          color: Colors.blue,
                          size: 32,
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Text(
                        'Choose Your Language',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select your preferred language for the app experience',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),

                  if (viewModel.deviceLanguage != null) ...[
                    InkWell(
                      onTap: viewModel.setUseDeviceLanguage,
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: viewModel.selectedLanguage?.code ==
                                    viewModel.deviceLanguage?.code
                                ? Colors.blue
                                : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.devices,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Use Device Language',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'System: ${viewModel.deviceLanguage?.nativeName} (${viewModel.deviceLanguage?.code.toUpperCase()})',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey.shade600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (viewModel.selectedLanguage?.code ==
                                viewModel.deviceLanguage?.code)
                              const Icon(
                                Icons.check_circle,
                                color: Colors.blue,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Divider(),
                    const SizedBox(height: 16),
                  ],

                  Expanded(
                    child: ListView.separated(
                      itemCount: viewModel.supportedLanguages.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final language = viewModel.supportedLanguages[index];
                        return LanguageTile(
                          language: language,
                          isSelected:
                              viewModel.selectedLanguage?.code == language.code,
                          onTap: () => viewModel.selectLanguage(language),
                        );
                      },
                    ),
                  ),

                  if (viewModel.errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                viewModel.errorMessage!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 14),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: viewModel.isLoading
                          ? null
                          : () async {
                              await viewModel.saveLanguageSelection();
                              if (!viewModel.hasError && context.mounted) {
                                Navigator.pushReplacement(
                                  context,
                                  MaterialPageRoute(builder: (_) => const AuthChoiceScreen()),
                                );
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: viewModel.isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Continue',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
