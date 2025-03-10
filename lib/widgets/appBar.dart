import 'package:flutter/material.dart';
import '../../data/data_inputs.dart';
import 'package:provider/provider.dart';
import '../data/firestore_service.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic route;
  final Map<String, dynamic>? inputValues;
  final bool submitToFirestore;

  const CustomAppBar({
    Key? key,
    required this.route,
    this.inputValues,
    this.submitToFirestore = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFE5E5),
            borderRadius: BorderRadius.circular(32),
          ),
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SafeArea(
            top: false,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  color: Colors.black,
                  onPressed: () => Navigator.pop(context),
                ),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      final inputState = Provider.of<InputState>(context, listen: false);
                      if (inputValues != null) {
                        inputState.cacheInputs(inputValues!);
                        if (submitToFirestore) {
                          FirestoreService firestoreService = FirestoreService();
                          await firestoreService.handleSubmit(inputState.getCachedInputs());
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Data successfully saved!')),
                          );
                        }
                      }
                      Navigator.pushNamed(context, route, arguments: inputValues);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error saving data: $e')),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF5D5D), // Coral pink
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Continue',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.menu),
                  color: Colors.black,
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(88); // Adjusted height for padding
}
