import 'package:flutter/material.dart';
import '../models/car_model.dart';
import '../services/audio_service.dart';
import '../services/game_store.dart';
import '../widgets/game_widgets.dart';

class GarageScreen extends StatefulWidget{const GarageScreen({super.key});@override State<GarageScreen> createState()=>_GarageScreenState();}
class _GarageScreenState extends State<GarageScreen>{final store=GameStore.instance;int index=0;@override void initState(){super.initState();index=carCatalog.indexWhere((c)=>c.id==store.selectedCarId);store.addListener(_r);}@override void dispose(){store.removeListener(_r);super.dispose();}void _r(){if(mounted)setState((){});} 
@override Widget build(BuildContext context){final car=carCatalog[index];final unlocked=store.unlockedCars.contains(car.id);return Scaffold(appBar:AppBar(title:const Text('GARAGE'),actions:[Padding(padding:const EdgeInsets.only(right:12),child:CoinBadge(coins:store.coins))]),body:Column(children:[
Expanded(child:PageView.builder(controller:PageController(initialPage:index,viewportFraction:.82),itemCount:carCatalog.length,onPageChanged:(i)=>setState(()=>index=i),itemBuilder:(_,i){final c=carCatalog[i];return AnimatedScale(scale:i==index?1:.86,duration:const Duration(milliseconds:220),child:Padding(padding:const EdgeInsets.all(12),child:NeonCard(child:Column(children:[Expanded(child:Image.asset(c.asset,fit:BoxFit.contain)),Text(c.name,style:const TextStyle(fontSize:22,fontWeight:FontWeight.w900)),Text(c.rarityLabel,style:const TextStyle(color:Color(0xFF93C5FD),fontWeight:FontWeight.bold)),const SizedBox(height:14),Row(mainAxisAlignment:MainAxisAlignment.spaceAround,children:[_stat('TOP SPEED','${c.topSpeed.toInt()} km/h'),_stat('ACCEL','${c.acceleration.toInt()}')])]))));})),
Padding(padding:const EdgeInsets.all(18),child:GradientButton(label:unlocked?(store.selectedCarId==car.id?'SELECTED':'SELECT CAR'):'UNLOCK • ${car.unlockPrice} COINS',onPressed:()async{if(unlocked){await store.selectCar(car.id);}else{final ok=await store.unlockCar(car.id,car.unlockPrice);if(ok){await AudioService.instance.play('unlock.wav');}else if(mounted){ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content:Text('Not enough coins')));}}}))
]));}
Widget _stat(String a,String b)=>Column(children:[Text(a,style:const TextStyle(fontSize:10,color:Colors.white54,fontWeight:FontWeight.bold)),Text(b,style:const TextStyle(fontWeight:FontWeight.w900))]);}
