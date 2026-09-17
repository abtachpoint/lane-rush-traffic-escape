import 'package:flutter/material.dart';
import 'screens/home_screen.dart';
import 'services/ad_service.dart';
import 'services/audio_service.dart';
import 'services/game_store.dart';
import 'services/purchase_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await GameStore.instance.init();
  await AdService.instance.init();
  await PurchaseService.instance.init();
  runApp(const LaneRushApp());
  AudioService.instance.startMusic();
}

class LaneRushApp extends StatelessWidget {
  const LaneRushApp({super.key});
  @override Widget build(BuildContext context)=>MaterialApp(
    debugShowCheckedModeBanner:false,
    title:'Lane Rush: Traffic Escape',
    theme:ThemeData(
      brightness:Brightness.dark,
      scaffoldBackgroundColor:const Color(0xFF101827),
      colorScheme:ColorScheme.fromSeed(seedColor:const Color(0xFF3B82F6),brightness:Brightness.dark),
      appBarTheme:const AppBarTheme(backgroundColor:Color(0xFF101827),centerTitle:true,titleTextStyle:TextStyle(fontSize:18,fontWeight:FontWeight.w900,color:Colors.white,letterSpacing:1)),
      snackBarTheme:const SnackBarThemeData(behavior:SnackBarBehavior.floating),
      useMaterial3:true,
    ),
    home:const HomeScreen(),
  );
}
