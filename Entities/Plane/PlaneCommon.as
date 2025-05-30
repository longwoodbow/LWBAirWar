shared class PlaneInfo
{
	s8 bullet_time;
	s16 missile_time_0;
	s16 missile_time_1;
	s16 special_time_0;
	s16 special_time_1;
	s16 special_time_2;
	s16 special_time_3;

	s16 amount_missile;
	s16 amount_special;
	u8 amount_flare;

	bool use_special;
	u8 special_type;

	PlaneInfo()
	{
		bullet_time = 0;
		missile_time_0 = 0;
		missile_time_1 = 0;
		special_time_0 = 0;
		special_time_1 = 0;
		special_time_2 = 0;
		special_time_3 = 0;

		amount_missile = 16;
		amount_flare = 4;

		use_special = false;
		special_type = SpecialWeaponType::hcaa;
		amount_special = 16;// manual add
	}
};

const u8 bullet_cooldown = 3;
const u8 missile_cooldown = 150;

const u16 missile_range = 500;
const u16 missile_arc = 90;

namespace SpecialWeaponType
{
	enum type
	{
		hcaa = 0,
		hpaa,
		hvaa,
		laam,
		qaam,
		saam,
		sasm,
		lagm,
		gpb,
		//rkt,
		grkt,
		eml,
		mgp,
		plsl,
		tls,
		uav,
		mpbm,
		iews,
		mstm,
		count
	};
}

const string[] specialTypeNames = { "HCAA",
									"HPAA",
									"HVAA",
									"LAAM",
									"QAAM",
									"SAAM",
									"SASM",
									"LAGM",
									"GPB",
									"GRKT",
									"EML",
									"MGP",
									"PLSL",
									"TLS",
									"UAV",
									"MPBM",
									"IEWS",
									"MSTM"
                                };

const string[] specialDescriptions = { "High-Capacity Air-to-Air Missile",
                                  "High-Power Air-to-Air Missile",
                                  "Hyper-Velocity Air-to-Air Missile",
                                  "Long-Range Air-to-Air Missile",
                                  "Quick Maneuver Air-to-Air Missile",
                                  "Semi-Active Air-to-Air Missile\nNeed to keep target in radar",
                                  "Short-Range Aerial Suppression Air-to-Air Missile\nExplodes near target",
                                  "Long-Range Air-to-Ground Missile\nFor attacking the base",
                                  "Guided Penetration Bomb\nFor attacking the base",
                                  "Guided Rocket Launcher\nFor attacking the base",
                                  "Electromagnetic Launcher",
                                  "Machhine Gun Pod",
                                  "Pulse Laser\nNext generation of machine guns",
                                  "Tactical Laser System",
                                  "Unmanned Aerial Vehicle\nShoots PLSL to target",
                                  "Multi-Purpose Burst Missile\nIt works like high power SASM",
                                  "Integrated Electronic Warfare System\nJamming enemy missiles(ECM)\nand strengthen ally missiles(ESM)",
                                  "Multiple-Launch Standard Missile"
                                };

const u16[] specialCooldowns = {
									150,//hcaa
									150,//hpaa
									150,//hvaa
									150,//laam
									150,//qaam
									150,//saam
									150,//sasm
									150,//lagm
									150,//gpb
									150,//grkt
									150,//eml
									3,//mgp
									26,//plsl
									300,//tls
									300,//uav
									300,//mpbm
									450,//iews
									150//mstm
								};

const u16[] specialRanges = {
									500,//hcaa
									500,//hpaa
									750,//hvaa
									1000,//laam
									500,//qaam
									750,//saam
									500,//sasm
									1000,//lagm
									250,//gpb
									500,//grkt
									0,//eml
									0,//mgp
									0,//plsl
									0,//tls
									750,//uav
									500,//mpbm
									0,//iews
									500//mstm
								};

const u16[] specialArcs = {
									90,//hcaa
									90,//hpaa
									90,//hvaa
									90,//laam
									90,//qaam
									60,//saam
									90,//sasm
									90,//lagm
									90,//gpb
									90,//grkt
									90,//eml
									0,//mgp
									0,//plsl
									0,//tls
									180,//uav
									90,//mpbm
									0,//iews
									90//mstm
								};

const u16[] specialAmounts = {
									16,//hcaa
									8,//hpaa
									8,//hvaa
									8,//laam
									8,//qaam
									8,//saam
									8,//sasm
									8,//lagm
									16,//gpb
									4,//grkt
									8,//eml
									200,//mgp
									100,//plsl
									8,//tls
									4,//uav
									4,//mpbm
									2,//iews
									12//mstm
								};

const u16[] specialCharges = {
									2,//hcaa
									2,//hpaa
									2,//hvaa
									2,//laam
									2,//qaam
									2,//saam
									2,//sasm
									2,//lagm
									2,//gpb
									1,//grkt
									1,//eml
									1,//mgp
									2,//plsl
									1,//tls
									2,//uav
									1,//mpbm
									1,//iews
									4//mstm
								};

const bool[] specialIsMissile = {
									true,//hcaa
									true,//hpaa
									true,//hvaa
									true,//laam
									true,//qaam
									true,//saam
									true,//sasm
									true,//lagm
									false,//gpb
									false,//grkt
									false,//eml
									false,//mgp
									false,//plsl
									false,//tls
									false,//uav
									true,//mpbm
									false,//iews
									true//mstm
								};