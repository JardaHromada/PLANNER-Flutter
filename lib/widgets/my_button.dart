import 'package:flutter/material.dart';

class MyButton extends StatelessWidget {
  
  final Function()? onTap;
  final String text;
 
  const MyButton({super.key, required this.onTap, required this.text});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: ShapeDecoration(
                          color: const Color(0xFF2F4156),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(100),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            text,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Color(0xFFD7E2FF),
                              fontSize: 30,
                              fontFamily: 'Roboto',
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
      )
    );
  }


}