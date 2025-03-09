import 'package:flutter/material.dart';
import '../styles.dart';

class MessageInputBox extends StatefulWidget {
  final Function(String)? onSaved;
  final VoidCallback onNextPressed;

  const MessageInputBox({
    Key? key,
    this.onSaved,
    required this.onNextPressed,
  }) : super(key: key);

  @override
  _MessageInputBoxState createState() => _MessageInputBoxState();
}

class _MessageInputBoxState extends State<MessageInputBox> {
  String _inputValue = '';

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: ColorPalette.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Don’t know what to say?',
                style: AppTextStyles.bodyMedium.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w300,
                  color: ColorPalette.peach,
                ),
              ),
            ],
          ),
          TextFormField(
            decoration: const InputDecoration(
              hintText: 'Optional Message Here', 
              hintStyle: TextStyle(
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
              border: InputBorder.none, // Removes the bottom border
              enabledBorder: InputBorder.none, // Removes border when not focused
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 12, horizontal: 16), 
            ),
            style: const TextStyle(
              color: Colors.black, // Adjust text color
              fontSize: 16,
            ),
            onChanged: (value) {
              setState(() {
                _inputValue = value;
              });
            },
            onSaved: (value) {
              widget.onSaved?.call(value ?? '');
            },
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: widget.onNextPressed,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 20),
              minimumSize: Size.zero, // Ensures no default button size
              tapTargetSize: MaterialTapTargetSize.shrinkWrap, // Reduces extra padding
            ),
            child: const Text('Next'),
          ),
        ],
      ),
    );
  }
}
