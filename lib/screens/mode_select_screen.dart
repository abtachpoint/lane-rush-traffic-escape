import 'package:flutter/material.dart';
import '../models/game_mode.dart';
import '../widgets/game_widgets.dart';
import 'game_screen.dart';

class ModeSelectScreen extends StatelessWidget { const ModeSelectScreen({super.key});
  @override Widget build(BuildContext context)=>Scaffold(appBar:AppBar(title:const Text('SELECT MODE')),body:Padding(padding:const EdgeInsets.all(18),child:Column(children:[
    const Text('Choose your traffic challenge',style:TextStyle(color:Colors.white60)),const SizedBox(height:20),
    for(final mode in TrafficMode.values) Padding(padding:const EdgeInsets.only(bottom:14),child:NeonCard(child:Row(children:[
      CircleAvatar(radius:28,backgroundColor:mode==TrafficMode.sameDirection?const Color(0xFF22C55E):mode==TrafficMode.oncoming?const Color(0xFFF59E0B):const Color(0xFFEF4444),child:Icon(mode==TrafficMode.sameDirection?Icons.arrow_upward_rounded:mode==TrafficMode.oncoming?Icons.arrow_downward_rounded:Icons.swap_vert_rounded,color:Colors.white)),
      const SizedBox(width:14),Expanded(child:Column(crossAxisAlignment:CrossAxisAlignment.start,children:[Text(mode.title,style:const TextStyle(fontSize:18,fontWeight:FontWeight.w900)),Text(mode.subtitle,style:const TextStyle(color:Colors.white60,fontSize:12)),const SizedBox(height:5),Text('${mode.difficulty} • ${mode.multiplier}× SCORE',style:const TextStyle(color:Color(0xFF93C5FD),fontWeight:FontWeight.bold,fontSize:12))])),
      IconButton(onPressed:()=>Navigator.pushReplacement(context,MaterialPageRoute(builder:(_)=>GameScreen(mode:mode))),icon:const Icon(Icons.play_circle_fill_rounded,size:42,color:Color(0xFF60A5FA)))
    ])))
  ])));
}
