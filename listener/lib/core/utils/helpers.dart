class Helpers {
  static void showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  static Future<void> navigateAndReplace(BuildContext context, Widget screen) async {
    await Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }
}
