import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../services/game_store.dart';
import '../widgets/game_widgets.dart';
import 'daily_reward_screen.dart';
import 'garage_screen.dart';
import 'missions_screen.dart';
import 'mode_select_screen.dart';
import 'settings_screen.dart';
import 'shop_screen.dart';

class HomeScreen extends StatefulWidget { const HomeScreen({super.key}); @override State<HomeScreen> createState()=>_HomeScreenState(); }
class _HomeScreenState extends State<HomeScreen> {
  final store=GameStore.instance;
  @override void initState(){super.initState();store.addListener(_refresh);} @override void dispose(){store.removeListener(_refresh);super.dispose();}
  void _refresh(){if(mounted)setState((){});} 
  @override Widget build(BuildContext context){final car=carById(store.selectedCarId);return Scaffold(
    body: Container(
      decoration: const BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter,end: Alignment.bottomCenter,colors:[Color(0xFF0E1830),Color(0xFF172A4D),Color(0xFF101827)])),
      child: SafeArea(child: Padding(padding: const EdgeInsets.all(18),child: Column(children:[
        Row(children:[IconButton(onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const SettingsScreen())),icon:const Icon(Icons.settings_rounded)),const Spacer(),Column(children:[const Text('BEST',style:TextStyle(fontSize:11,color:Colors.white60,fontWeight:FontWeight.bold)),Text('${store.bestScore}',style:const TextStyle(fontWeight:FontWeight.w900,fontSize:20))]),const Spacer(),CoinBadge(coins:store.coins)]),
        const SizedBox(height:8),
        const Text('LANE RUSH',style:TextStyle(fontSize:34,fontWeight:FontWeight.w900,letterSpacing:2)),
        const Text('TRAFFIC ESCAPE',style:TextStyle(color:Color(0xFF93C5FD),letterSpacing:4,fontWeight:FontWeight.w700)),
        Expanded(child:Stack(alignment:Alignment.center,children:[
          Container(width:250,height:250,decoration:const BoxDecoration(shape:BoxShape.circle,gradient:RadialGradient(colors:[Color(0x553B82F6),Colors.transparent]))),
          Image.asset(car.asset,height:290,fit:BoxFit.contain),
        ])),
        Text(car.name,style:const TextStyle(fontSize:20,fontWeight:FontWeight.w800)),Text('${car.topSpeed.toInt()} km/h • ${car.rarityLabel}',style:const TextStyle(color:Colors.white60)),
        const SizedBox(height:14),GradientButton(label:'PLAY',icon:Icons.play_arrow_rounded,onPressed:()=>Navigator.push(context,MaterialPageRoute(builder:(_)=>const ModeSelectScreen()))),
        const SizedBox(height:18),Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[
          _nav(context,Icons.directions_car_filled_rounded,'Garage',const GarageScreen()),_nav(context,Icons.storefront_rounded,'Shop',const ShopScreen()),_nav(context,Icons.flag_rounded,'Missions',const MissionsScreen()),_nav(context,Icons.card_giftcard_rounded,'Daily',const DailyRewardScreen()),
        ]),
      ]))),
    ),
  );}
  Widget _nav(BuildContext c,IconData i,String l,Widget page)=>InkWell(onTap:()=>Navigator.push(c,MaterialPageRoute(builder:(_)=>page)),borderRadius:BorderRadius.circular(20),child:Padding(padding:const EdgeInsets.all(8),child:Column(children:[Container(width:54,height:54,decoration:BoxDecoration(color:const Color(0xFF202C42),borderRadius:BorderRadius.circular(18)),child:Icon(i,color:const Color(0xFF93C5FD))),const SizedBox(height:5),Text(l,style:const TextStyle(fontSize:12,fontWeight:FontWeight.w700))])));
}
