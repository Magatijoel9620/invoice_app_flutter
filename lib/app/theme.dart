import 'package:flutter/material.dart';

class AppTheme {
  static const seed=Color(0xFF0F766E);
  static ThemeData light()=>_theme(Brightness.light);
  static ThemeData dark()=>_theme(Brightness.dark);
  static ThemeData _theme(Brightness b){
    final cs=ColorScheme.fromSeed(seedColor:seed,brightness:b);
    return ThemeData(useMaterial3:true,colorScheme:cs,brightness:b,scaffoldBackgroundColor:b==Brightness.light?const Color(0xFFF7F9F8):const Color(0xFF0B1210),
      cardTheme:CardThemeData(elevation:0,margin:EdgeInsets.zero,shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(20))),
      inputDecorationTheme:InputDecorationTheme(filled:true,fillColor:b==Brightness.light?Colors.white:const Color(0xFF111A17),border:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),enabledBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide.none),focusedBorder:OutlineInputBorder(borderRadius:BorderRadius.circular(14),borderSide:BorderSide(width:1.4,color:cs.primary))),
      elevatedButtonTheme:ElevatedButtonThemeData(style:ElevatedButton.styleFrom(minimumSize:const Size(0,52),shape:RoundedRectangleBorder(borderRadius:BorderRadius.circular(15)),padding:const EdgeInsets.symmetric(horizontal:20))),
    );
  }
}
