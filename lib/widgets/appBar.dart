import 'package:flutter/material.dart';
import '../../controllers/data_object.dart';
import '../../controllers/data_functions.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic route;
  final Map<String, dynamic>? inputValues; 

  const CustomAppBar({
    Key? key,
    required this.route,
    this.inputValues,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          child: SafeArea(
            top: false,
            child: AppBar(
              title: ElevatedButton(
                onPressed: () {
                  if (inputValues != null) {
                    DynamicData data = DynamicData(inputValues: inputValues!);
                    dataService.handleSubmit(data);
                  }
                  Navigator.pushNamed(context, route);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                child: Text(
                  'CTA Text Var Here', // CTA button label
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
              actions: <Widget>[
                IconButton(
                  icon: Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openEndDrawer(),
                ),
              ],
            )
        ))]);
  }

  @override
  Size get preferredSize => const Size.fromHeight(60); 
}