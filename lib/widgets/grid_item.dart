import 'package:flutter/material.dart';
import '../../styles.dart';

class GridItem extends StatelessWidget {
  final String title;
  final String imagePath;
  final String routeName;

  const GridItem({
    Key? key,
    required this.title,
    required this.imagePath,
    required this.routeName,
    
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, routeName),
      child: Container(
        padding: EdgeInsets.all(8),
        decoration: AppStyles.boxDecoration,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(imagePath, fit: BoxFit.cover),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}