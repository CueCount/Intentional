import 'package:flutter/material.dart';
import '/router/router.dart';
import '../../controllers/airtable.dart';
import '../../widgets/appBar.dart';
import '../../widgets/custom_drawer.dart';
import '../../widgets/input_checkbox.dart';  

class MateAttributes extends StatefulWidget {
  const MateAttributes({super.key, required this.title});

  final String title;

  @override
  State<MateAttributes> createState() => _MateAttributes();
}

class _MateAttributes extends State<MateAttributes> {
  List<MateAttribute> attributes = [
    MateAttribute(title: 'Physically Strong', description: 'Have your specific needs and expectations met'),
    MateAttribute(title: 'Mature and Thoughtful', description: 'Have your specific needs and expectations met'),
    MateAttribute(title: 'Assertive and Leading', description: 'Have your specific needs and expectations met'),
    MateAttribute(title: 'Intelligent and Nerdy', description: 'Have your specific needs and expectations met'),
    MateAttribute(title: 'Spontaneous and Romantic', description: 'Have your specific needs and expectations met'),
    MateAttribute(title: 'High Earning High Status', description: 'Have your specific needs and expectations met'),
  ];

  @override
  Widget build(BuildContext context) { 

    return Scaffold( 
      appBar: CustomAppBar(
        title: widget.title,
        isLoggedIn: true,
        hasSubmittedForm: true,
      ),
      endDrawer: CustomDrawer(), 

      body: GridView.builder(
        padding: EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.0,
        ),
        itemCount: attributes.length,
        itemBuilder: (context, index) {
          return CustomCheckbox(
            attribute: attributes[index],
            onChanged: (isSelected) {
              setState(() {
                attributes[index].isSelected = isSelected;
              });
            },
          );
        },
      ),
      bottomNavigationBar: Container(
        color: Colors.white,
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        child: MaterialButton(
          onPressed: () {
            
            Navigator.pushNamed(context, AppRoutes.logistics);
          },
          child: Text('Begin'),
          color: Color.fromARGB(255, 226, 33, 243),
          height: 50,
          minWidth: double.infinity,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      /*body: ListView(
        children: <Widget>[
          CustomCheckbox(
            title: 'Physically Strong and Bruiting',
            initialValue: true,
            onChanged: (value) {
              // Handle change
              print("Physically Strong and Bruiting: $value");
            },
          ),
          CustomCheckbox(
            title: 'Mature and Thoughtful',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Mature and Thoughtful: $value");
            },
          ),
          CustomCheckbox(
            title: 'Assertive and Leading',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Assertive and Leading: $value");
            },
          ),
          CustomCheckbox(
            title: 'Intelligent and Nerdy',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Intelligent and Nerdy: $value");
            },
          ),
          CustomCheckbox(
            title: 'Spontaneous and Romantic',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("Spontaneous and Romantic: $value");
            },
          ),
          CustomCheckbox(
            title: 'High Earning High Status',
            initialValue: false,
            onChanged: (value) {
              // Handle change
              print("High Earning High Status: $value");
            },
          ),
          MaterialButton(
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.logistics);
            },
            child: const Text('Begin'),
            color: const Color.fromARGB(255, 226, 33, 243),
          ),
        ],
      ),*/

    );

  }
}
