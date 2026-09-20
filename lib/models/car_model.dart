import 'package:flutter/material.dart';

enum CarRarity { common, rare, epic, legendary }

class CarModel {
  const CarModel({
    required this.id,
    required this.name,
    required this.asset,
    required this.rarity,
    required this.unlockPrice,
    required this.topSpeed,
    required this.acceleration,
    required this.color,
  });

  final String id;
  final String name;
  final String asset;
  final CarRarity rarity;
  final int unlockPrice;
  final double topSpeed;
  final double acceleration;
  final Color color;

  String get rarityLabel => switch (rarity) {
        CarRarity.common => 'COMMON',
        CarRarity.rare => 'RARE',
        CarRarity.epic => 'EPIC',
        CarRarity.legendary => 'LEGENDARY',
      };
}

const carCatalog = <CarModel>[
  CarModel(id: 'red_hatch', name: 'Red Hatch', asset: 'assets/images/cars/red_hatch.png', rarity: CarRarity.common, unlockPrice: 0, topSpeed: 140, acceleration: 16, color: Color(0xFFE74C3C)),
  CarModel(id: 'blue_sedan', name: 'Blue Sedan', asset: 'assets/images/cars/blue_sedan.png', rarity: CarRarity.common, unlockPrice: 7500, topSpeed: 155, acceleration: 17, color: Color(0xFF3498DB)),
  CarModel(id: 'yellow_mini', name: 'Yellow Mini', asset: 'assets/images/cars/yellow_mini.png', rarity: CarRarity.common, unlockPrice: 12000, topSpeed: 165, acceleration: 19, color: Color(0xFFF6C432)),
  CarModel(id: 'green_sport', name: 'Green Sport', asset: 'assets/images/cars/green_sport.png', rarity: CarRarity.rare, unlockPrice: 25000, topSpeed: 185, acceleration: 21, color: Color(0xFF2ECC71)),
  CarModel(id: 'white_suv', name: 'White SUV', asset: 'assets/images/cars/white_suv.png', rarity: CarRarity.rare, unlockPrice: 35000, topSpeed: 175, acceleration: 18, color: Color(0xFFECF0F1)),
  CarModel(id: 'orange_muscle', name: 'Orange Muscle', asset: 'assets/images/cars/orange_muscle.png', rarity: CarRarity.rare, unlockPrice: 45000, topSpeed: 200, acceleration: 23, color: Color(0xFFE67E22)),
  CarModel(id: 'black_coupe', name: 'Black Coupe', asset: 'assets/images/cars/black_coupe.png', rarity: CarRarity.rare, unlockPrice: 55000, topSpeed: 210, acceleration: 24, color: Color(0xFF34495E)),
  CarModel(id: 'silver_luxury', name: 'Silver Luxury', asset: 'assets/images/cars/silver_luxury.png', rarity: CarRarity.epic, unlockPrice: 85000, topSpeed: 220, acceleration: 25, color: Color(0xFF95A5A6)),
  CarModel(id: 'neon_racer', name: 'Neon Racer', asset: 'assets/images/cars/neon_racer.png', rarity: CarRarity.epic, unlockPrice: 110000, topSpeed: 235, acceleration: 28, color: Color(0xFF9B59B6)),
  CarModel(id: 'pursuit_x', name: 'Pursuit X', asset: 'assets/images/cars/pursuit_x.png', rarity: CarRarity.epic, unlockPrice: 140000, topSpeed: 245, acceleration: 29, color: Color(0xFF2980B9)),
  CarModel(id: 'gold_supercar', name: 'Gold Supercar', asset: 'assets/images/cars/gold_supercar.png', rarity: CarRarity.legendary, unlockPrice: 220000, topSpeed: 265, acceleration: 32, color: Color(0xFFF1C40F)),
  CarModel(id: 'cyber_phantom', name: 'Cyber Phantom', asset: 'assets/images/cars/cyber_phantom.png', rarity: CarRarity.legendary, unlockPrice: 350000, topSpeed: 285, acceleration: 35, color: Color(0xFF58D68D)),
];

CarModel carById(String id) => carCatalog.firstWhere(
      (car) => car.id == id,
      orElse: () => carCatalog.first,
    );
