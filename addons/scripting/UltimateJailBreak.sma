/*
	AMX Mod X script.

	This plugin is free software; you can redistribute it and/or modify it
	under the terms of the GNU General Public License as published by the
	Free Software Foundation; either version 2 of the License, or (at
	your option) any later version. 
	
	This plugin is distributed in the hope that it will be useful, but
	WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
	General Public License for more details.
	
	You should have received a copy of the GNU General Public License
	along with this plugin; if not, write to the Free Software Foundation,
	Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA.
*/
#define PLUGIN_VERSION		"0.1.2b"

/* Includes */
#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < fun >
#include < xs >
#include < nvault >
#include < hamsandwich >
#include < fakemeta >
#include < engine >

#pragma semicolon 1

/* Defines */
#define SetBit(%1,%2)      		(%1 |= (1<<(%2&31)))
#define ClearBit(%1,%2)    		(%1 &= ~(1 <<(%2&31)))
#define CheckBit(%1,%2)    		(%1 & (1<<(%2&31)))

#if !defined Ham_CS_Player_ResetMaxSpeed
    #define Ham_CS_Player_ResetMaxSpeed Ham_Item_PreFrame
#endif

#define is_user(%1)			(1 <= %1 <= MAX_PLAYERS)

#define XO_PLAYER 5
#define m_iTeam 114
#define m_iDeaths 444

#define OFFSET_TEAM			114
#define OFFSET_MODELINDEX		491
#define PDATA_SAFE			2
#define fm_get_user_team(%1)		get_pdata_int(%1,OFFSET_TEAM)
#define fm_set_user_team(%1,%2)		set_pdata_int(%1,OFFSET_TEAM,%2)

#define vec_copy(%1,%2)			(%2[0] = %1[0], %2[1] = %1[1],%2[2] = %1[2])
#define vec_sub(%1, %2, %3)		(%1[0] = %2[0] - %3[0], %1[1] = %2[1] - %3[1], %1[2] = %2[2] - %3[2])

#define PISTOL_WEAPONS_BIT		(1<<CSW_GLOCK18|1<<CSW_USP|1<<CSW_DEAGLE|1<<CSW_P228|1<<CSW_FIVESEVEN|1<<CSW_ELITE)
#define SHOTGUN_WEAPONS_BIT		(1<<CSW_M3|1<<CSW_XM1014)
#define SUBMACHINE_WEAPONS_BIT		(1<<CSW_TMP|1<<CSW_MAC10|1<<CSW_MP5NAVY|1<<CSW_UMP45|1<<CSW_P90)
#define RIFLE_WEAPONS_BIT		(1<<CSW_FAMAS|1<<CSW_GALIL|1<<CSW_AK47|1<<CSW_SCOUT|1<<CSW_M4A1|1<<CSW_SG550|1<<CSW_SG552|1<<CSW_AUG|1<<CSW_AWP|1<<CSW_G3SG1)
#define MACHINE_WEAPONS_BIT		(1<<CSW_M249)
#define PRIMARY_WEAPONS_BIT		(SHOTGUN_WEAPONS_BIT|SUBMACHINE_WEAPONS_BIT|RIFLE_WEAPONS_BIT|MACHINE_WEAPONS_BIT)
#define SECONDARY_WEAPONS_BIT		(PISTOL_WEAPONS_BIT)

#define IsPrimaryWeapon(%1)		((1<<%1) & PRIMARY_WEAPONS_BIT)
#define IsSecondaryWeapon(%1)		((1<<%1) & PISTOL_WEAPONS_BIT)

#define LMS_WPN_NBR			13
#define PAGE_OPTIONS			7
#define m_iNumSpawns			365
#define m_flNextDecalTime		486

#define MAX_PRIMARY			16
#define MAX_SECONDARY			6
#define MAX_KNIFE_HEALTH		4
#define MAX_WEAPONTOSS_WEAPONS		3
#define MAX_S4S_WEAPONS			6
#define MAX_DUEL_WEAPONS		5
#define MAX_COLORS			30
#define MAX_GROUPS			5

#define CHANNEL_TOPINFO			1
#define CHANNEL_OTHER			2
#define CHANNEL_COUNTDOWN		3
#define CHANNEL_HEALTH			4

/*
	Below is the section where normal people can safely edit
	its values.
	Please if you don't know how to code, refrain from editing
	anything outside the safety zone.
	
	Experienced coders are free to edit what they want, but I
	will not reply to any private messages nor emails about hel-
	ping you with it.
	
	SAFETY ZONE STARTS HERE
*/
// #define MAX_PLAYERS			32

#define NOCLIP_SPEED			Float:10.0
#define TIME_HOTPOTATO			Float:30.0
#define KAMIKAZE_CT_COUNT		3
#define PROXIMITY_DISTANCE		Float:300.0

#define NC_HEALTH1_CT			30
#define NC_ARMOR1_CT			150
#define NC_ARMOR1_T			100
#define NC_HEALTH2_CT			45
#define NC_ARMOR2_CT			150
#define NC_ARMOR2_T			100

#define ZOMBIE_HEALTH1_T		600
#define ZOMBIE_ARMOR1_T			100
#define ZOMBIE_ARMOR1_CT		100
#define ZOMBIE_HEALTH2_CT		900
#define ZOMBIE_ARMOR2_CT		100
#define ZOMBIE_ARMOR2_T			100

#define PRESIDENT_USP_BP		100
#define PRESIDENT_HEALTH		125
#define PRESIDENT_ARMOR			300
#define PRESIDENT_GUARD_HEALTH		75
#define PRESIDENT_GUARD_ARMOR		150

#define USP_NINJA_HEALTH_CT		25
#define USP_NINJA_BP_CT			112
#define USP_NINJA_BP_T			24
#define USP_NINJA_GRAVITY		600

#define HULK_AMMO_P90_CT		100
#define HULK_AMMO_FIVESEVEN_CT		100
#define HULK_ARMOR_CT			100
#define HULK_HEALTH_T			100
#define HULK_ARMOR_T			100
#define HULK_SMASH_INTERVAL		Float:20.0

#define SPACE_ARMOR_CT			100
#define SPACE_ARMOR_T			100
#define SPACE_GRAVITY			250
#define SPACE_HEALTH_T			100
#define SPACE_HEALTH_CT			200

#define SHARK_HEALTH_CT			300
#define SHARK_HEALTH1_CT		300
#define COWBOY_HEALTH_CT		175

#define KNIFE_HEALTH_CT			65
#define KNIFE_HEALTH_T			35

#define LMS_HEALTH_T			250
#define LMS_ARMOR_T			100
#define LMS_WEAPON_INTERVAL		Float:45.0

#define MARIO_GRAVITY			250
#define HNS_DANGER_METER		Float:0.5
#define NADEWAR_GIVENADES		Float:150.0

#define KAMIKAZE_HEALTH_T		200
#define KAMIKAZE_ARMOR_T		200
#define KAMIKAZE_HEALTH_CT		100
#define KAMIKAZE_ARMOR_CT		100

#define DEAGLE_MANIAC_ARMOR_CT		100
#define DEAGLE_MANIAC_ARMOR_T		100
#define DEAGLE_MANIAC_CT_COUNT		3
#define DEAGLE_MANIAC_HEALTH_CT		100
#define DEAGLE_MANIAC_HEALTH_T		1
#define DEAGLE_MANIAC_INV_T		10

#define UBER_GLOCKER_HEALTH_T		500
#define UBER_GLOCKER_ARMOR_T		200
#define UBER_GLOCKER_HEALTH_CT		100
#define UBER_GLOCKER_ARMOR_CT		100
#define UBER_GLOCKER_CT_COUNT		3

#define VOTE_PRIM_MIN			10
#define VOTE_PRIM_MAX			30
#define VOTE_SEC_MIN			5
#define VOTE_SEC_MAX			15

#define TIME_COUNTDOWN_NC		16
#define TIME_COUNTDOWN_SHARK		16
#define TIME_COUNTDOWN_MARIO		31
#define TIME_COUNTDOWN_SAMURAI		61
#define TIME_COUNTDOWN_HNS		61
#define TIME_COUNTDOWN_RACE		11
#define TIME_COUNTDOWN_HOTPOTATO	11
#define TIME_COUNTDOWN_COMMANDER	11

#define BEAM_LIFE			40
#define BEAM_WIDTH			10
#define BEAM_BRIGHT			195

#define POINTS_KILL			3
#define POINTS_KILL_HS			5
#define POINTS_LR			5
#define POINTS_ROUND_START		1
#define POINTS_ROUND_END		2
#define POINTS_MIN_PLAYERS		7

#define RANDOM_PLAYER_GLOW		Float:3.0
#define TEAMJOIN_TEAM			"1"
#define TEAMJOIN_CLASS			"2"

#define FUN_ROULETTE_CHANCE		10
#define FUN_ROULETTE_POINTS		100
#define FUN_LOTTERY_POINTS		750000
#define FUN_LOTTERY_NUMBERS		6

#define RAFFLE_TICKET_COST		50
#define TEAM_RATIO			3
#define MINIMUM_TIME_TO_CT		10
/*
	This is where you stop. Editing anything below this point
	might lead to some serious errors, and you will not get any
	support if you do.
	
	SAFETY ZONE ENDS HERE
*/

/* Enumerations */
enum _:MAX_DAYS( ) {
	DAY_FREE		= 0,	DAY_CAGE,
	DAY_NIGHTCRAWLER,		DAY_ZOMBIE,
	DAY_RIOT,			DAY_PRESIDENT,
	DAY_USP_NINJA,			DAY_NADEWAR,
	DAY_HULK,			DAY_SPACE,
	DAY_COWBOY,			DAY_SHARK,
	DAY_LMS,			DAY_SAMURAI,
	DAY_KNIFE,			DAY_JUDGEMENT,
	DAY_HNS,			DAY_MARIO,
	DAY_CUSTOM
};

enum _:MAX_LR( ) {
	LR_KNIFE		= 0,	LR_WEAPONTOSS,
	LR_DUEL,			LR_S4S,
	LR_SHOWDOWN,			LR_GRENADETOSS,
	LR_HOTPOTATO,			LR_RACE,
	LR_SPRAY,			LR_KAMIKAZE,
	LR_SUICIDE,			LR_DEAGLE_MANIAC,
	LR_GLOCKER
};

enum _:MAX_ITEMS( ) {
	ITEM_GRENADE_HE		= 0,	ITEM_GRENADE_FLASH,
	ITEM_GRENADE_SMOKE,		ITEM_HEALTH_KIT,
	ITEM_AD_HEALTH_KIT,		ITEM_ARMOR_JACKET,
	ITEM_PRISON_KNIFE,		ITEM_DEAGLE,
	ITEM_SCOUT, 			ITEM_SILENT_FOOTSTEPS
};

enum _:MAX_SOUNDS( ) {
	SOUND_COWBOY		= 0,	SOUND_NADEWAR,
	SOUND_HULK,			SOUND_SPACE,
	SOUND_SAMURAI,			SOUND_SAMURAI2,
	SOUND_ZOMBIE,			SOUND_NIGHTCRAWLER,
	SOUND_HNS,			SOUND_MARIO,
	SOUND_MARIO_DOWN
};

enum _:MAX_TASKS( += 100 ) {
	TASK_COUNTDOWN_HNS	= 0,	TASK_COUNTDOWN_MARIO,
	TASK_COUNTDOWN_SAMURAI, 	TASK_COUNTDOWN_SHARK,
	TASK_COUNTDOWN_NC,		TASK_UNGLOW_PLAYER,
	TASK_COUNTDOWN_RACE,		TASK_COUNTDOWN_HOTPOTATO,
	TASK_COUNTDOWN_COMMANDER,	TASK_SLAYLOOSER,
	TASK_MENU_DAY,			TASK_MENU_NC,
	TASK_MENU_SHARK,		TASK_MENU_ZOMBIE,
	TASK_MENU_FREE,			TASK_GIVENADES,
	TASK_ROUNDENDED,		TASK_PRESIDENT_GIVEWEAPONS,
	TASK_LMS_GIVEWEAPONS,		TASK_LMS_GIVEWORDEREDEAPONS,
	TASK_NADEWAR_GIVEGRENADE,	TASK_HULK_SMASH,
	TASK_SHOWTOPINFO,		TASK_SHOWDOWN,
	TASK_HNS_ALLOW_WEAPONS,		TASK_HNS_DANGER_METER,
	TASK_COUNTDOWN_COMMANDERMATH,	TASK_TEAMJOIN,
	TASK_ID_SOUND,			TASK_GIVEDODGEBALLNADES,
	TASK_DODGEBALL_NADES,		TASK_DISABLESHOP,
	TASK_START_DUEL
};

enum _:MAX_OPTIONS_FREEDAY( ) {
	UNRESTRICTED,			RESTRICTED
};

enum _:MAX_OPTIONS( ) {
	REGULAR,			REVERSED
};

enum _:MAX_PLAYER_TYPE( ) {
	PLAYER_PRISONER,		PLAYER_OFFICER
};

enum _:MAX_COMMANDER_OPTIONS( ) {
	COMMANDER_OPEN 		= 0,	COMMANDER_SPLIT,
	COMMANDER_TIMER,		COMMANDER_GAMEBOOK,
	COMMANDER_RANDOM_PRISONER,	COMMANDER_EMPTY_DEAGLE,
	COMMANDER_MIC,			COMMANDER_HEAL,
	COMMANDER_GLOW,			COMMANDER_MATH,
	COMMANDER_FFA,			COMMANDER_DODGEBALL,
	COMMANDER_SPRAY
};

enum _:MAX_VIP_KNIVES( ) {
	KNIFE_FIST		= 0,	KNIFE_LIGHT_SABER,
	KNIFE_DAEDRIC,			KNIFE_MACHETE,
	KNIFE_KATANA
}

/* Constantes */
new const g_strPluginName[ ]		= "UltimateJailBreak";
new const g_strPluginVersion[ ]		= PLUGIN_VERSION;
new const g_strPluginAuthor[ ]		= "tonykaram1993";
new const g_strPluginPrefix[ ]		= "[UJ]";

new const g_strPluginSponsor[ ]		= "tonykaram1993";
// new const g_strPluginIP[ ]		= "IP GOES HERE :P";

new const FIRST_JOIN_MSG[ ] 		= "#Team_Select";
new const FIRST_JOIN_MSG_SPEC[ ] 	= "#Team_Select_Spect";
new const INGAME_JOIN_MSG[ ] 		= "#IG_Team_Select";
new const INGAME_JOIN_MSG_SPEC[ ]	= "#IG_Team_Select_Spect";
const g_iJoinMsgLen			= sizeof( INGAME_JOIN_MSG_SPEC );

/*
	These are the names of the days that are shown on the voting menu.
*/
new const g_strOptionsDayMenu[ MAX_DAYS ][ ] = {
	"Free Day",			"Cage Day",
	"NightCrawler Day",		"Zombie Day",
	"Riot Day",			"President Day",
	"USP Ninjas Day",		"Nade War Day",
	"Hulk Day",			"Space Day",
	"Cowboy Day",			"Shark Day",
	"Last Man Standing Day",	"Samurai N Seek Day",
	"Knife Day",			"Judgement Day",
	"Hide N Seek Day",		"Mario Day",
	"Custom Day"
};

/*
	This is the objective of each day that is printed in chat when a day starts.
*/
new const g_strObjectivesDayMenu[ MAX_DAYS ][ ] = {
	"Nothing is restricted except the Gunroom.^nGuards can only order Prisoners^nto drop their weapons.",
	"Prisoners have to follow the commands^ngiven by the Guards.^nAny disobedience might lead to death .",
	"Guards are invisible and have more HP.^nPrisoners automatically get weapons.^nGuards must chase the Prisoners with knives.",
	"Prisoners are Zombies.^nGuards automatically get weapons.^nPrisoners must try to infect the Guards.",
	"Treated as a Cage Day.^nOne random Prisoner will get an^nAK47 and a Deagle.^nGuards must try and find out who.",
	"One random Guard is picked as the President.^nPresident get more HP and a USP.^nGuards protect him at all costs.",
	"All players get a silenced USP.^nGuards get 112 extra bullets and Prisoners get 24.^nUSP must always be silenced.",
	"Guards lead the Prisoners to a specified area.^nA Guard types /nadewar and everyone gets^nunlimited grenades.^nFollow the commands of the Guards.",
	"Prisoners are Hulks.^nGuards get a P90 and Elites.^nGuards chase the Prisoners.^nHulk smashes hit every 20 seconds.",
	"Guards are given AWPs.^nPrisoners are given SCOUTs.^nGravity is reduced.^nKill the opposing team!",
	"Guards get Deagles and more HP.^nPrisoners get Elites.^nKill the opposing team!",
	"Guards get more HP with noclip.^nPrisoners automatically get weapons.^nGuards must chase the Prisoners with knives.",
	"Guards get godmode.^nFriendly fire is turned ON and Prisoners get 250 HP.^nPrisoners get a gun every 45 seconds.",
	"Guards have a powerful knife.^nPrisoners are given 60 seconds to hide.^nGuards must look for the Prisoners.",
	"Both teams knife it out to the death.^nHealing is blocked!",
	"Treated as a normal Cage Day.^nAll Guards get powerful Deagles.^nBullets are limited.",
	"Prisoners are given 60 seconds to hide,^nwhile Guards wait in the gunroom.^nGuards chase the Prisoners and kill them.",
	"Prisoners must kill their teammates by,^njumping on their heads.",
	"Guards are allowed to make up their own day.^nThey are allowed to get help from an^nonline admin."
};

/*
	Same as above, but this is for reversed days. If a day does not have any reverse,
	then the field is left empty.
*/
new const g_strObjectivesDayMenuReversed[ MAX_DAYS ][ ] = {
	"Guards can only restrict one area^nor a particular action.",
	"",
	"Prisoners are invisible and have more HP.^nGuards automatically get deagles.^nPrisoners must chase the Guards with knives.",
	"Guards get 6000 HP.^nPrisoners automatically get weapons.^nGuards must chase the Prisoners with knives.",
	"",
	"",
	"",
	"",
	"",
	"",
	"",
	"Prisoners get noclip.^nGuards automatically get weapons.^nPrisoners must chase the Guards with knives.",
	"",
	"",
	"",
	"",
	"",
	"",
	""
};

/*
	The names of the last requests that is shown on the menu for the prisoner.
*/
new const g_strOptionsLastRequest[ MAX_LR ][ ] = {
	"Knife Fight",
	"Weapon Toss",
	"Duel",
	"Shot For Shot",
	"Showdown",
	"Grenade Toss",
	"Hot Potato",
	"Race",
	"Spray Contest",
	"Kamikaze",
	"Suicide Bomber",
	"Deagle Maniac",
	"Uber Glocker"
};

/*
	The objective of each last request option.
*/
new const g_strObjectivesLastRequest[ MAX_LR ][ ] = {
	"Both Players knife it^nout to the death.",
	"The player who throws^ntheir weapon the farthest^nis the winner.",
	"Both players battle it out with^nthe given weapons.",
	"Both players take turns^nshooting their weapon.",
	"Stand back to back^nand get ready for a^nshowdown.",
	"The player who throws^ntheir grenade the farthest^nis the winner.",
	"The last player who^npickes up the scout after 30 seconds^ndies.",
	"Complete a race^nanywhere in the map^nto determine the winner.",
	"Spray as low/high as you can to determine^nthe winner.",
	"Kamikaze mode initiated.^nKill The Enemy!",
	"Prisoner commited suicide using^nhimself as a bomb.",
	"Prisoner has a deagle, is invisible^n and has only 1 hp.^nKill Him!",
	"Prisoner has a glock, and 500 HP.^nKill him if you can!"
};

/*
	The models for the knives.
*/
new const g_strKnifeModels[ 10 ][ ] = {
	"models/v_bknuckles.mdl",
	"models/p_bknuckles.mdl",
	"models/v_light_saber_blu.mdl",
	"models/p_light_saber_blu.mdl",
	"models/v_daedric.mdl",
	"models/p_daedric.mdl",
	"models/v_machete.mdl",
	"models/p_machete.mdl",
	"models/v_katana.mdl",
	"models/p_katana.mdl"
};

/*
	The sounds for the knives.
*/
new const g_strKnifeSounds[ 20 ][ ] = {
	"bknuckles/knife_hit1.wav",	"bknuckles/knife_hit2.wav",
	"bknuckles/knife_hit3.wav",	"bknuckles/knife_hit4.wav",
	"bknuckles/knife_stab.wav",	"saber/knife_hit1.wav",
	"saber/knife_hit2.wav",		"saber/knife_hit3.wav",
	"saber/knife_hit4.wav",		"saber/knife_stab.wav",
	"machete/knife_hit1.wav",	"machete/knife_hit2.wav",
	"machete/knife_hit3.wav",	"machete/knife_hit4.wav",
	"machete/knife_stab.wav",	"katana/knife_hit1.wav",
	"katana/knife_hit2.wav",	"katana/knife_hit3.wav",
	"katana/knife_hit3.wav",	"katana/knife_stab.wav"
};

/*
	Sounds used in this plugin.
*/
new const g_strSounds[ MAX_SOUNDS ][ ] = {
	"jailbreak/cowboy_day.wav",	"jailbreak/dodgeball_day2.wav",
	"jailbreak/hulk_day2.wav",	"jailbreak/space_day.wav",
	"jailbreak/samurai_day.wav",	"jailbreak/samurai_2.wav",
	"jailbreak/zombie_day.wav",	"jailbreak/nightcrawler.wav",
	"jailbreak/hideandseek.wav",	"jailbreak/super_mario.wav",
	"jailbreak/powerdown.wav"
};

/*
	The order of the weapons in last man standing day.
*/
new const g_strLMSWeaponOrder[ LMS_WPN_NBR ][ ] = {
	"weapon_glock18",
	"weapon_usp",
	"weapon_deagle",
	"weapon_m3",
	"weapon_xm1014",
	"weapon_scout",
	"weapon_mp5navy",
	"weapon_famas",
	"weapon_galil",
	"weapon_awp",
	"weapon_ak47",
	"weapon_m4a1",
	"weapon_knife"
};

/*
	Weapon toss weapon names that are given to the last request players.
*/
new const g_strWTWeapons[ MAX_WEAPONTOSS_WEAPONS ][ ] = {
	"weapon_deagle",
	"weapon_scout",
	"weapon_awp"
};

/*
	Shot for shot weapon names that are given to the last request players.
*/
new const g_strS4SWeapons[ MAX_S4S_WEAPONS ][ ] = {
	"weapon_usp",
	"weapon_deagle",
	"weapon_scout",
	"weapon_fiveseven",
	"weapon_awp",
	"weapon_elite"
};

/*
	Duel weapon names that are given to the last request players.
*/
new const g_strDuelWeapons[ MAX_DUEL_WEAPONS ][ ] = {
	"weapon_m3",
	"weapon_m4a1",
	"weapon_ak47",
	"weapon_scout",
	"weapon_awp"
};

/*
	This is the number of days the player have to wait in order to pick that 
	day again. For example, president day cannot be picked twice unless 12 days
	have already passed in between them.
*/
new const g_iDaysLeftOriginal[ MAX_DAYS ] = {
	0, 			// Free Day
	0, 			// Cage Day
	10, 			// NightCrawler Day
	12,			// Zombie Day
	4, 			// Riot Day
	12, 			// President Day
	8, 			// USP Ninjas Day
	8, 			// Nade War Day
	6, 			// Hulk Day
	4, 			// Space Day
	4, 			// Cowboy Day
	8, 			// Shark Day
	12, 			// LMS Day
	8, 			// Samurai Day
	2, 			// Knife Day
	5, 			// Judgement Day
	2, 			// HNS Day
	10, 			// Mario Day
	0 			// Custom Day
};

/*
	Options for the knife fight where the numbers is how much health both
	last request players get.
*/
new const g_iOptionsKFHealths[ MAX_KNIFE_HEALTH ] = {
	1, 35, 100, 200
};

/*
	This is the price of each item that is available in the shop.
*/
new const g_iOptionsPoints[ ] = {
	60,	// HE Grenade
	60,	// FLASH Grenade
	60,	// SMOKE Grenade
	250,	// Health Kit
	450,	// Ad Health Kit
	180,	// Armor Jacket
	750,	// Prison Knife
	1500,	// Deagle
	2000,	// Scout
	1000	// Assassin Steps
};

/*
	Put the shop items in groups, this way a player cannot buy two items from the
	same group. For example, if a player buys a smoke grenade, he is not allowed to 
	buy another item from the same group (in this case, he is not allowed to but nor
	a flash grenade, nor a he grenade).
*/
new const g_iOptionsShopGroup[ ] = {
	1,	// HE Grenade
	1,	// FLASH Grenade
	1,	// SMOKE Grenade
	2,	// Health Kit
	2,	// Ad Health Kit
	2,	// Armor Jacket
	3,	// Prison Knife
	3,	// Deagle
	3,	// Scout
	4	// Assassin Steps
};

/*
	How many times the specific item is available during a round.
	For example, if a player buys the scout with one bullet, no 
	ohter prisoners can buy that option anymore since the stock is
	limited.
*/
new const g_iOptionsCount[ ] = {
	2,	// HE Grenade
	2,	// FLASH Grenade
	2, 	// SMOKE Grenade
	2,	// Health Kit
	2,	// Ad Health Kit
	2,	// Armor Jacket
	1,	// Prison Knife
	1,	// Dealge
	1,	// Scout
	1	// Assassin Steps
};

/* Integers */
new g_iOpenAuto;
new g_iOpenCommand;
new g_iTypeNightCrawler = -1;
new g_iTypeShark = -1;
new g_iTypeZombie = -1;
new g_iTypeFreeDay = -1;
new g_iShootButtons;
new g_iWallClimb;
new g_iCurrentDay;
new g_iCurrentLR;
new g_iPresident;
new g_iChosenForceDay;
new g_iLastTerrorist;
new g_iLRMic;
new g_iLMSCurrentWeapon;
new g_iCountDays;
new g_iTimeLeft;
new g_iVotePlayers;
new g_iDisplayName;
new g_iWeaponTrail;
new g_iLastPickup;
new g_iChosenWT;
new g_iChosenHP;
new g_iChosenWE;
new g_iChosenWD;
new g_iCommander;
new g_iCommanderMenuOption;
new g_iSpriteSmoke;
new g_iSpriteWhite;
new g_iLaserSprite;
new g_iVaultPoints;
new g_iMathQuestionResult;
new g_iVoteDayMenu;
new g_iTicketCount;
new g_iRelation;
new g_iRed;
new g_iBlue;
new g_iGreen;

/* Arrays */
new g_iCurrentPage[ MAX_PLAYERS + 1 ];
new g_iPlayerTime[ MAX_PLAYERS + 1 ];
new g_iButton;
new g_iDaysLeft[ MAX_DAYS ];
new g_iItemCout[ MAX_ITEMS ];
new g_iPlayerPrimaryWeapon[ MAX_PLAYERS + 1 ];
new g_iPlayerSpentPoints[ MAX_PLAYERS + 1 ];
new g_iPlayerKnife[ MAX_PLAYERS + 1 ];
new g_iVotesDayMenu[ MAX_DAYS ];
new g_iVotesFreeDay[ MAX_OPTIONS_FREEDAY ];
new g_iVotesNightCrawlerDay[ MAX_OPTIONS ];
new g_iVotesSharkDay[ MAX_OPTIONS ];
new g_iVotesZombieDay[ MAX_OPTIONS ];
new g_iLastRequest[ MAX_PLAYER_TYPE ];
new g_iPlayerPoints[ MAX_PLAYERS + 1 ];
new g_iPageVotes[ 3 ];
new g_iCommanderColor[ 3 ];
new g_strButtonModel[ 32 ];

/* Booleans */
new bool:g_bFFA;
new bool:g_bLMSWeaponsOver;
new bool:g_bForceDay;
new bool:g_bHulkSmash;
new bool:g_bOppositeVote;
new bool:g_bLRInProgress;
new bool:g_bAllowLastRequest;
new bool:g_bAllowStartRace;
new bool:g_bAllowStartShowdown;
new bool:g_bAllowStartHotPotato;
new bool:g_bAllowNadeWar;
new bool:g_bHotPotatoStarted;
new bool:g_bDayInProgress;
new bool:g_bAllowHNSWeapons;
new bool:g_bCatchAnswer;
new bool:g_bDodgeBall;
new bool:g_bGivePoints;
new bool:g_bAllowShop;
new bool:g_bShowSprayMeter;
new bool:g_bPluginCommand;

/* Floats */
new Float:g_fWallOrigin[ MAX_PLAYERS + 1 ][ 3 ];
new Float:g_fLastTouch[ MAX_PLAYERS + 1 ];

/* Bitsums */
new g_bitIsHeadShot[ MAX_PLAYERS + 1 ];
new g_bitHasBought[ MAX_GROUPS ];
new g_bitIsAlive;
new g_bitIsConnected;
new g_bitHasMicPower;
new g_bitHasVoted;
new g_bitHasFreeDay;
new g_bitHasUnAmmo;
new g_bitIsFirstConnect;
new g_bitHasUsedRoulette;
new g_bitHasPrisonKnife;
new g_bitHasTicket;
new g_bitIsCTBanned;
new g_bitIsPlayerVIP;

/* Pcvars */
new g_pcvarVoteDayMenu;
new g_pcvarVotePlayers;
new g_pcvarVoteOpposite;
new g_pcvarVoteMinGuards;
new g_pcvarVoteMinPrisoners;
new g_pcvarVotePrimary;
new g_pcvarVoteSecondary;
new g_pcvarVoteDisplayName;
new g_pcvarCellsOpen;
new g_pcvarCellsOpenCommand;
new g_pcvarNCWallClimb;
new g_pcvarShootButtons;
new g_pcvarLastTerroristTalks;
new g_pcvarAutoLR;
new g_pcvarBlockFlashlight;

/* Cvars */
new g_cvarGravity;
new g_cvarFriendlyFire;

/* Message IDs */
new g_msgRadar;
new g_msgScreenShake;
new g_msgStatusText;

/* Free For Fall */
new HamHook:g_hFFATraceAttack;
new HamHook:g_hFFATakeDamage;
new HamHook:g_hFFAKilled;
new g_mRadarHook;

/* Magic Marker */
new Float:origin[MAX_PLAYERS+1][3];
new prethink_counter[MAX_PLAYERS+1];
new bool:is_drawing[MAX_PLAYERS+1];
new bool:is_holding[MAX_PLAYERS+1];
new g_iSpriteLightning;

/* Plugin Natives */
public plugin_init( ) {
	/* Plugin Registration */
	register_plugin( g_strPluginName, g_strPluginVersion, g_strPluginAuthor );
	register_cvar( g_strPluginName, g_strPluginVersion, FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_UNLOGGED | FCVAR_SPONLY );
	
	/* Pcvars */
	g_pcvarVoteDayMenu		= register_cvar( "uj_vote",			"1" );
	g_pcvarVotePlayers		= register_cvar( "uj_vote_players",		"2" );
	g_pcvarVoteOpposite		= register_cvar( "uj_vote_opposite",		"7" );
	g_pcvarVoteMinGuards		= register_cvar( "uj_vote_min_guards",		"1" );
	g_pcvarVoteMinPrisoners		= register_cvar( "uj_vote_min_prisoners",	"2" );
	g_pcvarVotePrimary		= register_cvar( "uj_vote_primary",		"15" );
	g_pcvarVoteSecondary		= register_cvar( "uj_vote_secondary",		"7" );
	g_pcvarVoteDisplayName		= register_cvar( "uj_vote_display_name",	"1" );
	g_pcvarCellsOpen		= register_cvar( "uj_open_auto",		"1" );
	g_pcvarCellsOpenCommand		= register_cvar( "uj_open_command",		"0" );
	g_pcvarNCWallClimb		= register_cvar( "uj_wallclimb",		"1" );
	g_pcvarShootButtons		= register_cvar( "uj_shootbuttons",		"1" );
	g_pcvarLastTerroristTalks	= register_cvar( "uj_lr_mic",			"1" );
	g_pcvarAutoLR			= register_cvar( "uj_lr_auto",			"1" );
	g_pcvarBlockFlashlight		= register_cvar( "uj_block_flashlight",		"1" );
	
	/* Cvars */
	g_cvarGravity			= get_cvar_pointer( "sv_gravity" );
	g_cvarFriendlyFire		= get_cvar_pointer( "mp_friendlyfire" );
	
	/* Messade IDs */
	g_msgRadar			= get_user_msgid( "Radar" );
	g_msgScreenShake		= get_user_msgid( "ScreenShake" );
	g_msgStatusText 		= get_user_msgid( "StatusText" );
	
	/* Exec Config */
	ExecConfig( );
	
	/* Reload Cvars */
	ReloadCvars( );
	
	/* Check Server IP */
	// CheckServerIP( );
	
	/* Block Mortar */
	CheckMap( );
	
	/* Block Regular HUD Text Arguments */
	set_msg_block( get_user_msgid( "HudTextArgs" ), BLOCK_SET );
	
	/* Events */
	register_event( "HLTV",		"Event_HLTV",			"a", "1=0", "2=0" );
	register_event( "Health",	"Event_Health",			"be", "1>0" );
	register_event( "TextMsg",	"Event_TextMsg_RestartRound",	"a", "2&#Game_C", "2&#Game_w" );
	register_event( "CurWeapon",	"Event_CurWeapon",		"be", "1=1" );
	register_event( "23",		"Event_Spray",			"a", "1=112" );
	register_event( "Money",	"Event_Money",			"b" );
	register_event( "StatusValue", 	"Event_StatusValue_Relation", 	"b", "1=1" );
	register_event( "StatusValue", 	"Event_StatusValue_PlayerID", 	"b", "1=2", "2>0" );
	
	/* LogEvents */
	register_logevent( "LogEvent_RoundStart",			2, "1=Round_Start" );
	register_logevent( "LogEvent_RoundEnd",				2, "1=Round_End" );
	
	/* ClCmds */
	register_clcmd( "say /health",					"ClCmd_ShowHealth" );
	register_clcmd( "say /credits",					"ClCmd_DisplayCredits" );
	register_clcmd( "say /freeday",					"ClCmd_Freeday" );
	register_clcmd( "say /lr",					"ClCmd_LastRequest" );
	register_clcmd( "say /race",					"ClCmd_StartRace" );
	register_clcmd( "say /showdown",				"ClCmd_StartShowdown" );
	register_clcmd( "say /hotpotato",				"ClCmd_StartHotPotato" );
	register_clcmd( "say /commander",				"ClCmd_Commander" );
	register_clcmd( "say /nadewar",					"ClCmd_NadeWar" );
	register_clcmd( "say /commandermenu",				"ClCmd_CommanderMenu" );
	register_clcmd( "say /guns",					"ClCmd_GunMenu" );
	register_clcmd( "say /rules",					"ClCmd_Rules" );
	register_clcmd( "say /help",					"ClCmd_Rules" );
	register_clcmd( "say /day",					"ClCmd_StartDay" );
	register_clcmd( "say /jbmenu",					"ClCmd_MainMenu" );
	register_clcmd( "say /ffa",					"ClCmd_FreeForAll" );
	register_clcmd( "say /shop",					"ClCmd_OpenShop" );
	register_clcmd( "say /points",					"ClCmd_DisplayPoints" );
	register_clcmd( "say /fun",					"ClCmd_FunMenu" );
	// register_clcmd( "say /servers",					"ClCmd_DisplayServers" );
	// register_clcmd( "say /server",					"ClCmd_DisplayServers" );
	register_clcmd( "say /time",					"ClCmd_DisplayTime" );
	register_clcmd( "say /vip",					"ClCmd_DisplayVip" );
	register_clcmd( "say /voteday",					"ClCmd_VoteDay" );
	register_clcmd( "say /book",					"ClCmd_GameBook" );
	register_clcmd( "say /pot",					"ClCmd_ShowPot" );
	
	register_clcmd( "say_team /health",				"ClCmd_ShowHealth" );
	register_clcmd( "say_team /credits",				"ClCmd_DisplayCredits" );
	register_clcmd( "say_team /freeday",				"ClCmd_Freeday" );
	register_clcmd( "say_team /lr",					"ClCmd_LastRequest" );
	register_clcmd( "say_team /race",				"ClCmd_StartRace" );
	register_clcmd( "say_team /showdown",				"ClCmd_StartShowdown" );
	register_clcmd( "say_team /hotpotato",				"ClCmd_StartHotPotato" );
	register_clcmd( "say_team /commander",				"ClCmd_Commander" );
	register_clcmd( "say_team /nadewar",				"ClCmd_NadeWar" );
	register_clcmd( "say_team /commandermenu",			"ClCmd_CommanderMenu" );
	register_clcmd( "say_team /guns",				"ClCmd_GunMenu" );
	register_clcmd( "say_team /rules",				"ClCmd_Rules" );
	register_clcmd( "say_team /help",				"ClCmd_Rules" );
	register_clcmd( "say_team /day",				"ClCmd_StartDay" );
	register_clcmd( "say_team /jbmenu",				"ClCmd_MainMenu" );
	register_clcmd( "say_team /ffa",				"ClCmd_FreeForAll" );
	register_clcmd( "say_team /shop",				"ClCmd_OpenShop" );
	register_clcmd( "say_team /points",				"ClCmd_DisplayPoints" );
	register_clcmd( "say_team /fun",				"ClCmd_FunMenu" );
	// register_clcmd( "say_team /servers",				"ClCmd_DisplayServers" );
	// register_clcmd( "say_team /server",				"ClCmd_DisplayServers" );
	register_clcmd( "say_team /time",				"ClCmd_DisplayTime" );
	register_clcmd( "say_team /vip",				"ClCmd_DisplayVip" );
	register_clcmd( "say_team /voteday",				"ClCmd_VoteDay" );
	register_clcmd( "say_team /book",				"ClCmd_GameBook" );
	register_clcmd( "say_team /pot",				"ClCmd_ShowPot" );
	
	register_clcmd( "drop",						"ClCmd_WeaponDrop" );
	register_clcmd( "drawradar",					"ClCmd_DrawRadar" );
	register_clcmd( "jointeam",					"ClCmd_ChooseTeam" );
	register_clcmd( "chooseteam",					"ClCmd_ChooseTeam" );
	register_clcmd( "say",						"ClCmd_Say" );
	register_clcmd( "say_team",					"ClCmd_Say" );
	register_clcmd(	"+paint", 					"ClCmd_PaintHandler");
	register_clcmd(	"-paint", 					"ClCmd_PaintHandler");
	register_clcmd( "set_paint",					"ClCmd_SetPaintColor" );
	register_clcmd( "raffle",					"ClCmd_Raffle" );
	
	/* ConCmd */
	register_concmd( "say /open",					"ConCmd_OpenCells",		ADMIN_KICK,	" - Opens the cell doors" );
	register_concmd( "amx_allowmic",				"ConCmd_AllowMic",		ADMIN_KICK,	" <name | authid | userid> <1 | 0> - Set a player's talk power." );
	register_concmd( "amx_give_points",				"ConCmd_GivePoints",		ADMIN_RCON,	" <name | authid | userid> #points - Give a player points." );
	register_concmd( "amx_remove_points",				"ConCmd_RemovePoints",		ADMIN_RCON,	" <name | authid | userid> #points - Remove a player's points." );
	register_concmd( "amx_reset_points",				"ConCmd_ResetPoints",		ADMIN_RCON,	" <name | authid | userid> - Reset a player's points." );
	register_concmd( "amx_get_points",				"ConCmd_GetPoints",		ADMIN_RCON,	" <name | authid | userid> - Get a player's points." );
	register_concmd( "amx_banct",					"ConCmd_BanCT",			ADMIN_BAN,	" <name | authid | userid> <0 | 1> - Ban a player from joiing CT." );
	register_concmd( "amx_give_vip",				"ConCmd_GiveVIP",		ADMIN_RCON,	" <name | authid | userid> - Add a player to the VIP list." );
	register_concmd( "amx_remove_vip",				"ConCmd_RemoveVIP",		ADMIN_RCON,	" <name | authid | userid> - Remove a player from the VIP list." );
	register_concmd( "amx_playedtime",				"ConCmd_GetPlayedTime",		ADMIN_KICK,	" <name | authid | userid> - Get the ammount of time user has played." );
	register_concmd( "amx_set_button",				"ConCmd_SetButton",		ADMIN_RCON,	" - Set the button for the cell doors" );
	register_concmd( "amx_donate",					"ConCmd_DonatePoints",		ADMIN_ALL,	" <name | authid | userid> <#> - Donate points to other users." );
	register_concmd( "amx_donate_points",				"ConCmd_DonatePoints",		ADMIN_ALL,	" <name | authid | userid> <#> - Donate points to other users." );
	
	/* Forwards */
	register_forward( FM_AddToFullPack,				"Forward_AddToFullPack_Post",	1 );
	register_forward( FM_PlayerPreThink,				"Forward_PlayerPreThink",	0 );
	register_forward( FM_Voice_SetClientListening,			"Forward_SetClientListening",	0 );
	register_forward( FM_CmdStart,					"Forward_CmdStart",		0 );
	register_forward( FM_Touch,					"Forward_Touch",		0 );
	register_forward( FM_SetModel,					"Forward_SetModel",		0 );
	register_forward( FM_GetGameDescription,			"Forward_GetGameDescription",	0 );
	register_forward( FM_EmitSound, 				"Forward_EmitSound",		0 );
	
	/* Messages */
	register_message( get_user_msgid( "ShowMenu" ),			"Message_ShowMenu" );
	register_message( get_user_msgid( "VGUIMenu" ),			"Message_VGUIMenu" );
	register_message( get_user_msgid( "StatusIcon" ),		"Message_StatusIcon" );
	
	/* HamHooks */
	RegisterHam( Ham_Spawn,			"player",		"Ham_Spawn_Player_Post",	true );
	RegisterHam( Ham_Killed,		"player",		"Ham_Killed_Player_Pre",	false );
	RegisterHam( Ham_TakeDamage,		"player",		"Ham_TakeDamage_Player_Pre",	false );
	RegisterHam( Ham_Weapon_SecondaryAttack,"weapon_usp",		"Ham_SecondaryAttack_USP_Post",	true );
	RegisterHam( Ham_Touch,			"armoury_entity",	"Ham_Touch_Weapon_Pre",		false );
	RegisterHam( Ham_Touch,			"weaponbox",		"Ham_Touch_Weapon_Pre",		false );
	RegisterHam( Ham_Touch,			"worldspawn",		"Ham_Touch_Wall_Pre",		false );
	RegisterHam( Ham_Touch,			"func_wall",		"Ham_Touch_Wall_Pre",		false );
	RegisterHam( Ham_Touch,			"func_breakable",	"Ham_Touch_Wall_Pre",		false );
	RegisterHam( Ham_Touch,			"grenade",		"Ham_Touch_Grenade_Pre",	false );
	RegisterHam( Ham_Use,			"func_healthcharger",	"Ham_Use_Recharger_Pre",	false );
	RegisterHam( Ham_Use,			"func_recharge",	"Ham_Use_Recharger_Pre",	false );
	RegisterHam( Ham_TraceAttack,		"func_button",		"Ham_TraceAttack_Button_Pre",	false );
	RegisterHam( Ham_TraceAttack,		"player",		"Ham_TraceAttack_Player_Post",	true );
	RegisterHam( Ham_AddPlayerItem,		"player",		"Ham_AddPlayerItem_Player_Pre",	false );
	RegisterHam( Ham_CS_Player_ResetMaxSpeed,"player",		"Ham_ResetMaxSpeed_Player_Post",true );
	RegisterHam( Ham_Think,			"grenade",		"Ham_Think_Grenade_Pre",	false );
	RegisterHam( Ham_Weapon_PrimaryAttack,	"weapon_deagle",	"Ham_PrimaryAttack_Weapon_Post",true );
	RegisterHam( Ham_Weapon_PrimaryAttack,	"weapon_usp",		"Ham_PrimaryAttack_Weapon_Post",true );
	RegisterHam( Ham_Weapon_PrimaryAttack,	"weapon_scout",		"Ham_PrimaryAttack_Weapon_Post",true );
	RegisterHam( Ham_Weapon_PrimaryAttack,	"weapon_fiveseven",	"Ham_PrimaryAttack_Weapon_Post",true );
	RegisterHam( Ham_Weapon_PrimaryAttack,	"weapon_awp",		"Ham_PrimaryAttack_Weapon_Post",true );
	RegisterHam( Ham_Weapon_PrimaryAttack,	"weapon_elite",		"Ham_PrimaryAttack_Weapon_Post",true );
	RegisterHam( Ham_TakeHealth,		"player",		"Ham_TakeHealth_Player_Pre",	false );
	RegisterHam( Ham_Spawn,			"armoury_entity",	"Ham_Spawn_Armoury_Entity_Post",true );
	
	/* Menus */
	new iKeys = MENU_KEY_1 | MENU_KEY_2;
	
	register_menu( "Day Menu",		1023,			"Handle_DayMenu" );
	register_menu( "Freeday Menu",		iKeys,			"Handle_FreedayMenu" );
	register_menu( "NightCrawler Menu",	iKeys,			"Handle_NightCrawlerMenu" );
	register_menu( "Zombie Menu",		iKeys,			"Handle_ZombieMenu" );
	register_menu( "Shark Menu",		iKeys,			"Handle_SharkMenu" );
	
	/* Set Initial Paint Color */
	SetPaintColor( );
	
	/* Save button of the cells */
	GetButton( );
	SearchForButton( );
}

public plugin_precache( ) {
	/*
		Precache all the neccessary models, sounds and sprites for the plugin.
	*/
	for( new iLoop = 0; iLoop < MAX_SOUNDS; iLoop++ ) {
		precache_sound( g_strSounds[ iLoop ] );
	}
	
	/*
		No idea why precaching does not work when all strings are put in an array
		like the sounds above. Just leave it like this for now.
	*/
	precache_sound( "bknuckles/knife_hit1.wav" );
	precache_sound( "bknuckles/knife_hit1.wav" );
	precache_sound( "bknuckles/knife_hit2.wav" );
	precache_sound( "bknuckles/knife_hit3.wav" );
	precache_sound( "bknuckles/knife_hit4.wav" );
	precache_sound( "bknuckles/knife_stab.wav" );
	precache_sound( "saber/knife_hit1.wav" );
	precache_sound( "saber/knife_hit2.wav" );
	precache_sound( "saber/knife_hit3.wav" );
	precache_sound( "saber/knife_hit4.wav" );
	precache_sound( "saber/knife_stab.wav" );
	precache_sound( "machete/knife_hit1.wav" );
	precache_sound( "machete/knife_hit2.wav" );
	precache_sound( "machete/knife_hit3.wav" );
	precache_sound( "machete/knife_hit4.wav" );
	precache_sound( "machete/knife_stab.wav" );
	precache_sound( "katana/knife_hit1.wav" );
	precache_sound( "katana/knife_hit2.wav" );
	precache_sound( "katana/knife_hit3.wav" );
	precache_sound( "katana/knife_stab.wav" );
	
	precache_model( "models/p_bknuckles.mdl" );
	precache_model( "models/v_bknuckles.mdl" );
	precache_model( "models/p_light_saber_blu.mdl" );
	precache_model( "models/v_light_saber_blu.mdl" );
	precache_model( "models/p_daedric.mdl" );
	precache_model( "models/v_daedric.mdl" );
	precache_model( "models/p_machete.mdl" );
	precache_model( "models/v_machete.mdl" );
	precache_model( "models/p_katana.mdl" );
	precache_model( "models/v_katana.mdl" );
	
	g_iWeaponTrail 		= precache_model( "sprites/arrow1.spr" );
	g_iSpriteSmoke 		= precache_model( "sprites/steam1.spr" );
	g_iSpriteWhite 		= precache_model( "sprites/white.spr" );
	g_iLaserSprite 		= precache_model( "sprites/zbeam4.spr" );
	g_iSpriteLightning 	= precache_model("sprites/lgtning.spr");
	
	/*
		In here, we are opening the vault that is going to be used in the plugin.
		We opened it in plugin_precache because we need to get the model name of the 
		cell doors button. After we get that, we hook the spawn of all buttons on the 
		map and subsequently check if the model name is that same that is saved. 
		That way when we get a match, we then have the entity id and we store it for
		use with /open and automatic cell door opening.
	*/
	OpenVault( );
}

public plugin_end( ) {
	/*
		Save the time of each player so we don't loose anything.
	*/
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		SaveTime( iPlayers[ iLoop ] );
	}
	
	/*
		Close nvault as we are not gonna be able to use it anymore.
	*/
	nvault_close( g_iVaultPoints );
}

public plugin_natives( ) {
	/*
		This is mainly done because I wanted that the blackjack plugin would 
		be able to communicate with this plugin to set each player's points 
		the correct way. In the future, this can be used to easily edit other
		plugins to communicate effectively with this plugin.
	*/
	register_library( "API_UltimateJailBreak" );
	
	register_native( "uj_get_user_points",		"API_GetUserPoints" );
	register_native( "uj_set_user_points",		"API_SetUserPoints" );
	register_native( "uj_is_user_vip",		"API_IsUserVIP" );
}

public API_GetUserPoints( iPlugin, iParams ) {
	new iPlayerID = get_param( 1 );
	
	if( !CheckBit( g_bitIsConnected, iPlayerID ) ) {
		return -1;
	}
	
	return g_iPlayerPoints[ iPlayerID ];
}

public API_SetUserPoints( iPlugin, iParams ) {
	new iPlayerID = get_param( 1 );
	
	if( !CheckBit( g_bitIsConnected, iPlayerID ) ) {
		return 0;
	}
	
	g_iPlayerPoints[ iPlayerID ] = get_param( 2 );
	Event_Money( iPlayerID );
	
	return 1;
}

public API_IsUserVIP( iPlugin, iParams ) {
	new iPlayerID = get_param( 1 );
	
	if( CheckBit( g_bitIsPlayerVIP, iPlayerID ) && CheckBit( g_bitIsConnected, iPlayerID ) ) {
		return 1;
	}
	
	return 0;
}

/* Client Natives */
public client_putinserver( iPlayerID ) {
	/*
		Reset all the silly stuff that will be used later on in the plugin.
	*/
	ClearBit( g_bitHasMicPower,	iPlayerID );
	ClearBit( g_bitIsAlive,		iPlayerID );
	ClearBit( g_bitHasVoted,	iPlayerID );
	ClearBit( g_bitHasFreeDay,	iPlayerID );
	ClearBit( g_bitHasUnAmmo,	iPlayerID );
	ClearBit( g_bitHasUsedRoulette, iPlayerID );
	ClearBit( g_bitHasPrisonKnife, 	iPlayerID );
	
	static iLoop;
	for( iLoop = 0; iLoop < MAX_GROUPS; iLoop++ ) {
		g_bitHasBought[ iLoop ] = 0;
	}
	
	SetBit( g_bitIsConnected,	iPlayerID );
	SetBit( g_bitIsFirstConnect,	iPlayerID );
	
	g_iCurrentPage[ iPlayerID ] 		= 0;
	g_iPlayerSpentPoints[ iPlayerID ] 	= 0;
	g_iPlayerKnife[ iPlayerID ]		= KNIFE_FIST;
}

public client_authorized( iPlayerID ) {
	/*
		We got the steam id of the player, this means get all information needed 
		from nvault (ct banned; points; time; vip status)
	*/
	GetCTBan( iPlayerID );
	GetPoints( iPlayerID );
	GetTime( iPlayerID );
	GetVIP( iPlayerID );
}

public client_disconnect( iPlayerID ) {
	/*
		Client disconnected, reset neccessary bitsums and save player points 
		and time.
	*/
	ClearBit( g_bitIsConnected,	iPlayerID );
	ClearBit( g_bitIsAlive,		iPlayerID );
	
	SavePoints( iPlayerID );
	SaveTime( iPlayerID );
	
	/*
		Check if disconnected player in active in a last request and act
		accordingly. If not then check if he is commander and do the neccessary
		stuff.
	*/
	if( g_bLRInProgress ) {
		if( iPlayerID == g_iLastRequest[ PLAYER_OFFICER ] ) {
			EndLastRequest( iPlayerID, g_iLastRequest[ PLAYER_PRISONER ] );
		} else if( iPlayerID == g_iLastRequest[ PLAYER_PRISONER ] ) {
			EndLastRequest( iPlayerID, g_iLastRequest[ PLAYER_OFFICER ] );
		}
	} else {
		if( iPlayerID == g_iCommander ) {
			g_iCommander = -1;
			
			client_print_color( 0, print_team_red, "^4%s^1 Current Commander ^3disconnected^1 from the server. Guards type ^4/commander^1 to become the Commander.", g_strPluginPrefix );
		}
	}
}

public client_impulse( iPlayerID, iImpulse ) {
	/*
		This is mainly to block flashlights for a certain team. According 
		to the cvar of course. Impulse 100 = flashlight
		Teams:
		1: T
		2: CT
		3: BOTH
	*/
	if( iImpulse != 100 ) {
		return PLUGIN_CONTINUE;
	}
	
	switch( get_pcvar_num( g_pcvarBlockFlashlight ) ) {
		case 1: {
			if( cs_get_user_team( iPlayerID ) == CS_TEAM_T ) {
				return PLUGIN_HANDLED;
			}
		}
		
		case 2: {
			if( cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
				return PLUGIN_HANDLED;
			}
		}
		
		case 3: {
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

/* Events */
public Event_HLTV( ) {
	/*
		HLTV is being delayed because players would not have totally spawned
		at this exact time. So players who were dead the round before, will
		still be counted as dead and not alive. This would screw a lot of s-
		tuff up.
	*/
	set_task( 0.1, "Event_DelayedHLTV" );
	
	/*
		Do other stuff not related to counting alive prisoners.
	*/
	ReloadCvars( );
	g_bAllowLastRequest = false;
	
	/*
		Resetting all buttons on round start. This helps in many situations
		where the map maker did not think of this situation. Very common on 
		jailbreak maps.
	*/
	new iEntity;
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_button" ) ) > 0 ) {
		call_think( iEntity );
	}
	
	/*
		Loop through all players and save their time and points.
	*/
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		SaveTime( iTempID );
		SavePoints( iTempID );
	}
}

public Event_DelayedHLTV( ) {
	g_iVoteDayMenu = get_pcvar_num( g_pcvarVoteDayMenu );
	g_iCountDays++;
	
	set_task( 1.0, "CheckLastPlayer" );
	
	/*
		Set the very first round as an Unrestricted FreeDay.
		Since this function is only called once at the beginning of the map.
	*/
	if( g_iCountDays == 1 ) {
		client_print_color( 0, print_team_default, "^4%s^1 The first day is always an ^4Unrestricted FreeDay^1. Have Fun!", g_strPluginPrefix );
		
		g_iTypeFreeDay = UNRESTRICTED;
		StartFreeDay( );
		
		return;
	}
	
	/*
		Check if day was forced to start it anyway. If not, then check for the
		cvar value and act accordingly.
		This no longer any meanging since I changed the way /day works. It currently
		resets everything and starts the day in question. Let's just keep it there 
		for future purposes if I want to revert to the old way.
	*/
	if( g_bForceDay ) {
		StartDayVote( );
	} else {
		/*
			Check whether to make the vote appear at round start or not.
			0: never make the vote, always cage day (admins must force days)
			1: always make the vote
			#: make the vote if there is less than # minutes remaining of the map.
		*/
		switch( g_iVoteDayMenu ) {
			case 0:	{
				client_print_color( 0, print_team_blue, "^4%s^1 Day has been set to ^4Cage Day^1.", g_strPluginPrefix );
				
				g_iCurrentDay = DAY_CAGE;
				StartDay( );
			}
			
			case 1:	{
				StartDayVote( );
			}
			
			default: {
				if( get_timeleft( ) <= ( 60 * g_iVoteDayMenu ) ) {
					StartDayVote( );
				} else {
					g_iCurrentDay = DAY_CAGE;
					StartDay( );
				}
			}
		}
	}
}

public Event_Health( iPlayerID ) {
	/*
		Whenever health changes, call the show health function to display
		correct value to the user.
	*/
	ShowHealth( iPlayerID );
}

public Event_TextMsg_RestartRound( ) {
	/*
		Reset everything and end last request if it in progress when admin restarts
		the round.
	*/
	if( g_bLRInProgress ) {
		ForceEndLastRequest( );
	}
	
	ResetAll( );
}

public Event_CurWeapon( iPlayerID ) {
	/*
		Not alive? Then we do not care.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return PLUGIN_CONTINUE;
	}
	
	/*
		Get weapon id and show fist models instead of knife if the player
		does not have prison knife from the shop.
	*/
	static iWeaponID;
	iWeaponID = read_data( 2 );
	
	static iCurrentKnife;
	iCurrentKnife = g_iPlayerKnife[ iPlayerID ];
	
	if( iWeaponID == CSW_KNIFE && !CheckBit( g_bitHasPrisonKnife, iPlayerID ) ) {
		entity_set_string( iPlayerID, EV_SZ_viewmodel, g_strKnifeModels[ GetKnifeModel( iCurrentKnife, 0 ) ] );
		entity_set_string( iPlayerID, EV_SZ_weaponmodel, g_strKnifeModels[ GetKnifeModel( iCurrentKnife, 1 ) ] );
	}
	
	/*
		Unlimited ammo stuff. Basically it maxes your backpack ammo if it sees that its not 
		the max value for each weapon.
	*/
	if( CheckBit( g_bitHasUnAmmo, iPlayerID ) ) {
		switch( iWeaponID ) {
			case CSW_C4, CSW_KNIFE, CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE: {
				return PLUGIN_CONTINUE;
			}
		}
		
		static const iWeaponBackPack[ 32 ] = {
			0, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90,
			100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100
		};
		
		if( cs_get_user_bpammo( iPlayerID, iWeaponID ) != iWeaponBackPack[ iWeaponID ] ) {
			cs_set_user_bpammo( iPlayerID, iWeaponID, iWeaponBackPack[ iWeaponID ] );
		}
	}
	
	return PLUGIN_CONTINUE;
}

public Event_Spray( ) {
	/*
		Player sprayed, that means post how high the spray was from the ground.
		All wizardry done here are not by me, got it straight from alliedmods 
		requests section.
	*/
	static iPlayerID;
	iPlayerID = read_data( 2 );
	
	if( !( !g_bLRInProgress || g_iCurrentLR != LR_SPRAY || ( iPlayerID != g_iLastRequest[ PLAYER_OFFICER ] && iPlayerID != g_iLastRequest[ PLAYER_PRISONER ] ) ) || g_bShowSprayMeter ) {
		static iOrigin[ 3 ];
		iOrigin[ 0 ] = read_data( 3 );
		iOrigin[ 1 ] = read_data( 4 );
		iOrigin[ 2 ] = read_data( 5 );
		
		static Float:vecOrigin[ 3 ];
		IVecFVec( iOrigin, vecOrigin );
		
		static Float:vecDirection[ 3 ];
		velocity_by_aim( iPlayerID, 5, vecDirection );
		
		static Float:vecStop[ 3 ];
		xs_vec_add( vecOrigin, vecDirection, vecStop );
		xs_vec_mul_scalar( vecDirection, -1.0, vecDirection );
		
		static Float:vecStart[ 3 ];
		xs_vec_add( vecOrigin, vecDirection, vecStart );
		engfunc( EngFunc_TraceLine, vecStart, vecStop, IGNORE_MONSTERS, -1, 0 );
		get_tr2( 0, TR_vecPlaneNormal, vecDirection );
		vecDirection[ 2 ] = 0.0;
		
		xs_vec_normalize( vecDirection, vecDirection );
		xs_vec_mul_scalar( vecDirection, 5.0, vecDirection );
		xs_vec_add( vecOrigin, vecDirection, vecStart );
		xs_vec_copy( vecStart, vecStop );
		vecStop[ 2 ] -= 9999.0;
		
		engfunc( EngFunc_TraceLine, vecStart, vecStop, IGNORE_MONSTERS, -1, 0 );
		get_tr2( 0, TR_vecEndPos, vecStop );
		
		new strPlayerName[ 32 ];
		get_user_name( iPlayerID, strPlayerName, 31 );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 sprayed ^4%i unites^1 above the ground.", g_strPluginPrefix, strPlayerName, floatround( ( vecStart[ 2 ] - vecStop[ 2 ] ) ) );
	}
}

public Event_Money( iPlayerID ) {
	/*
		When money is changed, reset value to the user's ammount of points.
		Don't ask me why i checked for is_user and if he is connected. If both
		were not there, I would get error messages. I don't know why but it works :D
	*/
	if( is_user( iPlayerID ) && CheckBit( g_bitIsConnected, iPlayerID ) ) {
		cs_set_user_money( iPlayerID, g_iPlayerPoints[ iPlayerID ], 0 );
	}
}

public Event_StatusValue_Relation( iPlayer ) {
	g_iRelation = read_data( 2 );
}

public Event_StatusValue_PlayerID( iID ) {
	if( !g_iRelation ) {
		return;
	}
	
	new iPlayerID = read_data( 2 );
	
	static MESSAGE_TEAMMATE[ ] 	= "1 %%c1: %%p2 - Points: %i - %%h: %%i3%%%%";
	static MESSAGE_TEAMMATE_VIP[ ] 	= "1 VIP %%c1: %%p2 - Points: %i - %%h: %%i3%%%%";
	static MESSAGE_ENEMY[ ] 	= "1 %%c1: %%p2 - Points: %i";
	static MESSAGE_ENEMY_VIP[ ] 	= "1 VIP %%c1: %%p2 - Points: %i";
	
	new strMessage[ 80 ];
	if( CheckBit( g_bitIsPlayerVIP, iPlayerID ) ) {
		formatex( strMessage, 79, g_iRelation == 1 ? MESSAGE_TEAMMATE_VIP : MESSAGE_ENEMY_VIP, g_iPlayerPoints[ iPlayerID ] );
	} else {
		formatex( strMessage, 79, g_iRelation == 1 ? MESSAGE_TEAMMATE : MESSAGE_ENEMY, g_iPlayerPoints[ iPlayerID ] );
	}
	
	g_iRelation = 0;
	
	message_begin( MSG_ONE, g_msgStatusText, _, iID );
	write_byte( 0 );
	write_string( strMessage );
	message_end( );
}

/* LogEvents */
public LogEvent_RoundStart( ) {
	/*
		End round when timer hits 0:00. Commented as I was too lazy to make a cvar for it.
	*/
	// set_task( get_pcvar_float( g_cvarRoundTime ) * 60.0, "Task_RoundEnded", TASK_ROUNDENDED );
	
	/*
		Alright, then here we are checking the minimum number of allowed players on the server,
		in order to awward points for the players. This helps by not allowing a group of 
		friends coming to the server and abuse the shit out of the system.
		Then give points to prisoners for starting a new round (yes I am generous).
		Also don't forget that allow user to use roulette again as its a new round.
	*/
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum );
	
	if( iNum < POINTS_MIN_PLAYERS ) {
		g_bGivePoints = false;
	} else {
		g_bGivePoints = true;
	}
	
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		if( g_bGivePoints ) {
			g_iPlayerPoints[ iTempID ] += POINTS_ROUND_START;
			
			client_print_color( iTempID, print_team_red, "^4%s^1 Thank you for playing another round! Here take ^4%i point(s)^1.", g_strPluginPrefix, POINTS_ROUND_START );
			Event_Money( iTempID );
		}
		
		ClearBit( g_bitHasUsedRoulette, iTempID );
	}
	
	g_bAllowShop = true;
}

public LogEvent_RoundEnd( ) {
	ResetAll( );
	
	if( g_bLRInProgress ) ForceEndLastRequest( );
	
	/*
		Give points for players who survived the round.
	*/
	if( g_bGivePoints ) {
		new iPlayers[ 32 ], iNum, iTempID;
		get_players( iPlayers, iNum, "ae", "TERRORIST" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			g_iPlayerPoints[ iTempID ] += POINTS_ROUND_END;
			
			client_print_color( iTempID, print_team_red, "^4%s^1 Way to survive the round! Here take ^4%i point(s)^1.", g_strPluginPrefix, POINTS_ROUND_END );
			Event_Money( iTempID );
		}
	}
	
	/*
		Check if there are tickets sold (from the raffle system) and pick a random winner.
		
	*/
	if( g_bitHasTicket > 0 ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "e", "TERRORIST" );
		
		new iRandomNumber;
		
		do {
			iRandomNumber = random( iNum );
		} while( !CheckBit( g_bitHasTicket, iPlayers[ iRandomNumber ] ) );
		
		iRandomNumber = iPlayers[ iRandomNumber ];
		
		new strPlayerName[ 32 ];
		get_user_name( iRandomNumber, strPlayerName, 31 );
		
		new iTicketsCost = g_iTicketCount * RAFFLE_TICKET_COST;
		g_iPlayerPoints[ iRandomNumber ] += iTicketsCost;
		Event_Money( iRandomNumber );
		
		client_print_color( 0, print_team_red, "^4%s^3 %s^1 just won the ticket raffle. ^3%i^1 points has been added to his bank.", g_strPluginPrefix, strPlayerName, iTicketsCost );
		
		g_bitHasTicket = 0;
		g_iTicketCount = 0;
	}
	
	for( new iLoop = 0; iLoop < MAX_GROUPS; iLoop++ ) {
		g_bitHasBought[ iLoop ] = 0;
	}
	
	g_bitHasPrisonKnife = 0;
}

/* ClCmds */
public ClCmd_ShowHealth( iPlayerID ) {
	/*
		Do I need to explain this?
	*/
	if( CheckBit( g_bitIsAlive, iPlayerID ) ) {
		ShowHealth( iPlayerID );
	}
}

public ClCmd_DisplayCredits( iPlayerID ) {
	/*
		Display the name of the almighty scripter who made this plugin.
		He is the best, we all love him and worship him.
		
		T O N Y   K A R A M   1 9 9 3
	*/
	client_print_color( iPlayerID, print_team_default, "^4%s^1 This mod is scripted by ^4%s^1. Contact: ^4tonykaram1993@gmail.com^1.", g_strPluginPrefix, g_strPluginAuthor );
}

public ClCmd_Freeday( iPlayerID ) {
	/*
		Command to give a player a personal freeday, check if CT and admin.
	*/
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT && !is_user_admin( iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You must be a ^3Guard^1 or an ^4Admin^1 to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	ShowGlowPlayerMenu( iPlayerID );
	
	return PLUGIN_HANDLED;
}

public ClCmd_LastRequest( iPlayerID ) {
	/*
		Command for last request menu. Make the neccessary checks and show player the menu
		while at the same time notify guards that he is picking something from the menu.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_T ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3Prisoner^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_bLRInProgress ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 Last Request already ^3in progress^1. Finish your Last Request first.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bAllowLastRequest && !CheckLastPlayer( ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be the only alive ^3Prisoner^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_bDayInProgress ) {
		ResetAll( );
	}
	
	ShowLastRequestMenu( iPlayerID, 0 );
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, 31 );
	
	client_print_color( 0, iPlayerID, "^4%s^3 %s^1 is now picking a ^4Last Request^1. Get Ready!", g_strPluginPrefix, strPlayerName );
	
	return PLUGIN_HANDLED;
}

public ClCmd_StartRace( iPlayerID ) {
	/*
		This command is to start the race when the prisoner already picked race 
		as his last request option.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_T ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3Prisoner^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bLRInProgress ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You must have picked ^4Race^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bAllowStartRace ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You cannot use this command right now.", g_strPluginPrefix );
	} else {
		g_bAllowStartRace = false;
		
		g_iTimeLeft = TIME_COUNTDOWN_RACE;
		set_task( 1.0, "Task_CountDown_Race", TASK_COUNTDOWN_RACE, _, _, "a", g_iTimeLeft );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_StartShowdown( iPlayerID ) {
	/*
		This command is to start the showdown when the prisoner already picked showdown 
		as his last request option.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_T ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3Prisoner^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bLRInProgress ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You must have picked ^4Showdown^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bAllowStartShowdown ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You cannot use this command right now.", g_strPluginPrefix );
	} else {
		g_bAllowStartShowdown = false;
		
		client_print( iPlayerID, print_center, "Get ready for a showdown. Only shoot when you are allowed to!" );
		client_print( g_iLastRequest[ PLAYER_OFFICER ], print_center, "Get ready for a showdown. Only shoot when you are allowed to!" );
		
		set_task( random_float( 3.0, 5.0 ), "Task_Showdown", TASK_SHOWDOWN );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_StartHotPotato( iPlayerID ) {
	/*
		This command is to start the hotpotato when the prisoner already picked hotpotato 
		as his last request option.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_T ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3Prisoner^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bLRInProgress ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You must have picked ^4Hot Potato^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bAllowStartHotPotato ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You cannot use this command right now.", g_strPluginPrefix );
	} else {
		g_bAllowStartHotPotato = false;
		
		g_iTimeLeft = TIME_COUNTDOWN_HOTPOTATO;
		set_task( 1.0, "Task_CountDown_HotPotato", TASK_COUNTDOWN_HOTPOTATO, _, _, "a", g_iTimeLeft );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_Commander( iPlayerID ) {
	/*
		Player wants to be the commander, make the checks and act accordingly.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be a ^3Guard^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iCurrentDay != DAY_CAGE ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You can only be Commander when it is a ^4Cage Day^1.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iCommander != -1 && g_iCommander != iPlayerID ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 Someone else is currently commanding.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, 31 );
	
	if( g_iCommander == iPlayerID ) {
		g_iCommander = -1;
		set_user_rendering( iPlayerID );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 does not want to be the ^3Commander^1 anymore. Guards type ^4/commander^1 if you want to be the ^3Commander^1.", g_strPluginPrefix, strPlayerName );
	} else {
		g_iCommander = iPlayerID;
		
		set_user_rendering( iPlayerID, kRenderFxGlowShell, 220, 220, 0, kRenderNormal, 5 );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s ^1is now the ^3Commander^1. He has control of the current ^4Cage Day^1.", g_strPluginPrefix, strPlayerName );
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 If you do not want to be the ^3Commander^1 anymore, type ^4/commander^1 again.", g_strPluginPrefix );
	}
	
	ShowTopInfo( );
	
	return PLUGIN_HANDLED;
}

public ClCmd_NadeWar( iPlayerID ) {
	/*
		Prisoners are in position, so start nade war. BOOM BOOM BOOM!
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be a ^3Guard^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iCurrentDay != DAY_NADEWAR ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You can only use this command on a NadeWar Day.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bAllowNadeWar ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You cannot use this command right now.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	} else {
		g_bAllowNadeWar = false;
		
		client_print_color( 0, print_team_default, "^4%s^1 Get ready! NadeWar will start in^4 5 seconds^1.", g_strPluginPrefix );
		
		set_task( 5.0, "Task_GiveNades", TASK_GIVENADES );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_CommanderMenu( iPlayerID ) {
	/*
		Open the commander menu that allows the commander to do magic things.
	*/
	if( iPlayerID != g_iCommander ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be the ^3Commander^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	ShowCommanderMenu( iPlayerID );
	
	return PLUGIN_HANDLED;
}

public ClCmd_GunMenu( iPlayerID ) {
	/*
		Menu for the guns? Allow or don't whether the conditions meat.
		For example, this is blocked in some days so you cannot abuse it and get 
		reloaded guns without reloading at all.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	switch( g_iCurrentDay ) {
		case DAY_FREE, DAY_CAGE, DAY_RIOT: {
			if( cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
				ShowWeaponMenu( iPlayerID );
			}
		}
		
		default: {
			client_print_color( iPlayerID, print_team_default, "^4%s^1 You are not allowed to use this command right now.", g_strPluginPrefix );
		}
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_Rules( iPlayerID ) {
	/*
		Show the famous webpage of the rules.
	*/
	show_motd( iPlayerID, "http://www.ambrosia-servers.eu/JailbreakHelp.html" );
}

public ClCmd_StartDay( iPlayerID ) {
	/*
		This is for the admin to force a day that he desires. This will cancel any 
		day in progress and force the one the admin selected.
	*/
	if( is_user_admin( iPlayerID ) ) {
		StartForceDayMenu( iPlayerID );
		
		client_cmd( iPlayerID, "spk ^"buttons/button9^"" );
	} else {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 Only ^4admins^1 are allowed to use this command.", g_strPluginPrefix );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_MainMenu( iPlayerID ) {
	/*
		Main menu that has all the cool stuff.
	*/
	ShowMainMenu( iPlayerID );
	
	return PLUGIN_HANDLED;
}

public ClCmd_FreeForAll( iPlayerID ) {
	/*
		Enable free for all command that enables teammates to make equal damage
		as if they are shooting the enemy. You also get frags normally, and hides 
		the radar so you cannot cheat >:)
	*/
	if( !is_user_admin( iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You are not allowed to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	switch( g_iCurrentDay ) {
		case DAY_CAGE, DAY_FREE, DAY_RIOT, DAY_CUSTOM, DAY_JUDGEMENT: {}
		default: {
			client_print_color( iPlayerID, print_team_default, "^4%s^1 You cannot use this command today.", g_strPluginPrefix );
			
			return PLUGIN_HANDLED;
		}
	}
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, 31 );
	
	if( !g_bFFA ) {
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 turned on ^4Free For All^1!", g_strPluginPrefix, strPlayerName );
		
		SetFreeForAll( 1 );
	} else {
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 turned off ^4Free For All^1!", g_strPluginPrefix, strPlayerName );
		
		SetFreeForAll( 0 );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_DisplayPoints( iPlayerID ) {
	/*
		Maybe the user is so blind that he cannot see his points where his money 
		should be at, let him get the number of points he has by a simple command.
	*/
	client_print_color( iPlayerID, print_team_red, "^4%s^1 You currently have ^4%i^1 points to use in the ^3Shop^1.", g_strPluginPrefix, g_iPlayerPoints[ iPlayerID ] );
	
	return PLUGIN_HANDLED;
}

public ClCmd_OpenShop( iPlayerID ) {
	/*
		Open the shop menu if he is T, alive and its actually allowed.
	*/
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_T ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3Prisoner^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be ^3alive^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	switch( g_iCurrentDay ) {
		case DAY_CAGE, DAY_RIOT, DAY_JUDGEMENT: {
			if( !g_bAllowShop ) {
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You are too late! You may only buy items from the shop at the beginning of the round.", g_strPluginPrefix );
			} else {
				ShowShopMenu( iPlayerID );
			}
		}
		
		default: {
			client_print_color( iPlayerID, print_team_red, "^4%s^1 You cannot use this command on this day.", g_strPluginPrefix );
		}
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_FunMenu( iPlayerID ) {
	/*
		This contains everything you can have fund with while dead.
	*/
	/*if( CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be ^3dead^1 in order to use the ^4Fun Menu^1.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}*/
	
	ShowFunMenu( iPlayerID );
	
	return PLUGIN_HANDLED;
}

public ClCmd_DisplayServers( iPlayerID ) {
	/*
		Show the list of the servers by the same community/owner
	*/
	show_motd( iPlayerID, "http://www.ambrosia-servers.eu/servers.html" );
}

public ClCmd_DisplayTime( iPlayerID ) {
	/*
		Show the time the player has spent on the server and his current session.
	*/
	client_print_color( iPlayerID, iPlayerID, "^4%s^1 Our database says that you have played for ^3%d minute(s)^1.", g_strPluginPrefix, ( get_user_time( iPlayerID, 1 ) / 60 ) + g_iPlayerTime[ iPlayerID ] );
	client_print_color( iPlayerID, iPlayerID, "^4%s^1 Current session time: ^3%d minute(s)^1.", g_strPluginPrefix, get_user_time( iPlayerID ) / 60 );
}

public ClCmd_DisplayVip( iPlayerID ) {
	/*
		Show vip menu for the vips but don't for normal members.
	*/
	/*if( cs_get_user_team( iPlayerID ) != CS_TEAM_T ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3Prisoner^1 in order to access this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}*/
	
	if( !CheckBit( g_bitIsPlayerVIP, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3VIP^1 in order to access this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be ^3alive^1 in order to access this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	ShowVIPMenu( iPlayerID );
	
	return PLUGIN_HANDLED;
}

public ClCmd_VoteDay( iPlayerID ) {
	/*
		An admin can start a vote for a day by this command if he wishes.
	*/
	if( !g_iTimeLeft && is_user_admin( iPlayerID ) ) {
		StartDayVote( );
	} else {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You are ^3not allowed^1 to use this command right now.", g_strPluginPrefix );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_GameBook( iPlayerID ) {
	/*
		Noob CTs are everywhere, this will help them by providing possible
		games for them to do with the Ts.
	*/
	if( g_iCommander != iPlayerID ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be the ^3Commander^1 in order to use this command.", g_strPluginPrefix );
	} else {
		ShowGameBookMenu( iPlayerID );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_ShowPot( iPlayerID ) {
	new iPot = g_iTicketCount * RAFFLE_TICKET_COST;
	
	if( iPot ) {
		client_print_color( 0, print_team_red, "^4%s^1 The pot is currently %i with %i participants.", g_strPluginPrefix, iPot, g_iTicketCount );
	} else {
		client_print_color( 0, print_team_red, "^4%s^1 No one has participated in this round's ^3raffle^1 game.", g_strPluginPrefix );
	}
	
	return PLUGIN_HANDLED;
}


public ClCmd_WeaponDrop( iPlayerID ) {
	/*
		Block weapon drop on certain days. Why? Cause on those certain days
		you are not allowed to pickup any weapons, that means if he drops it
		by mistake he won't be able to get a gun anymore.
	*/
	if( g_bDayInProgress ) {
		switch( g_iCurrentDay ) {
			/*
				Block for President.
			 */
			case DAY_PRESIDENT: {
				if( iPlayerID == g_iPresident ) {
					return PLUGIN_HANDLED;
				}
			}
			
			/*
				Block for Counter-Terrorists.
			 */
			case DAY_HULK, DAY_JUDGEMENT: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
					return PLUGIN_HANDLED;
				}
			}
			
			/*
				Block for Terrorists conditionally.
			 */
			case DAY_LMS: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_T && !g_bLMSWeaponsOver ) {
					return PLUGIN_HANDLED;
				}
			}
			
			/*
				Block for both teams.
			 */
			case DAY_COWBOY, DAY_SPACE, DAY_USP_NINJA: {
				return PLUGIN_HANDLED;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public ClCmd_DrawRadar( iPlayerID ) {
	/*
		Block or show radar according to the FFA status.
	*/
	return _:g_bFFA;
}

public ClCmd_ChooseTeam( iPlayerID ) {
	/*
		Show main menu when user pressed the change team command.
		Or let it pass if its issued by the plugin.
	*/
	ShowMainMenu( iPlayerID );
	
	if( g_bPluginCommand ) {
		return PLUGIN_CONTINUE;
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_Say( iPlayerID ) {
	/*
		This is to determine the player who answered the math question
		correctly the first. This will help CTs not to open the console 
		and check for the first correct answer.
	*/
	if( g_bCatchAnswer ) {
		new strTemp[ 8 ];
		read_argv( 1, strTemp, 7 );
		
		new strPlayerName[ 32 ];
		get_user_name( iPlayerID, strPlayerName, 31 );
		
		set_user_rendering( iPlayerID, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
		set_task( RANDOM_PLAYER_GLOW, "Task_UnglowRandomPlayer", TASK_UNGLOW_PLAYER + iPlayerID );
		
		if( str_to_num( strTemp ) == g_iMathQuestionResult ) {
			set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
			show_hudmessage( 0, "%s answered first", strPlayerName );
		}
		
		g_bCatchAnswer = false;
	}
}

public ClCmd_Raffle( iPlayerID ) {
	/*
		Raffle command. Block if he already bought a ticket and do other checks too.
	*/
	/*if( CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be ^3dead^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}*/
	
	/*if( cs_get_user_team( iPlayerID ) != CS_TEAM_T ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3Prisoner^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}*/
	
	if( CheckBit( g_bitHasTicket, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You can only buy one ticket per round.", g_strPluginPrefix );
	} else {
		if( g_iPlayerPoints[ iPlayerID ] < RAFFLE_TICKET_COST ) {
			client_print_color( iPlayerID, print_team_red, "^4%s^1 You don't have enough points to participate in the raffle.", g_strPluginPrefix ); 
		} else {
			SetBit( g_bitHasTicket, iPlayerID );
			
			new strPlayerName[ 32 ];
			get_user_name( iPlayerID, strPlayerName, 31 );
			
			g_iTicketCount++;
			
			client_print_color( 0, iPlayerID, "^4%s^3 %s^1 just bought a raffle ticket. The pot is now ^4%i^1 points.", g_strPluginPrefix, strPlayerName, ( g_iTicketCount * RAFFLE_TICKET_COST ) );
			
			g_iPlayerPoints[ iPlayerID ] -= RAFFLE_TICKET_COST;
			Event_Money( iPlayerID );
		}
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_SetPaintColor( iPlayerID ) {
	/*
		Allows the commander to set the color of the paint he desires.
		RGB values, that means 3 numbers must be given.
	*/
	if( read_argc( ) != 4 ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to specify 3 numbers for the RGB value.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iCommander != iPlayerID ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be the ^3Commander^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	new strRed[ 8 ], strGreen[ 8 ], strBlue[ 8 ];
	read_argv( 1, strRed, 7 );
	read_argv( 2, strGreen, 7 );
	read_argv( 3, strBlue, 7 );
	
	g_iRed 		= clamp( str_to_num( strRed ), 		0, 255 );
	g_iGreen 	= clamp( str_to_num( strGreen ), 	0, 255 );
	g_iBlue 	= clamp( str_to_num( strBlue ), 	0, 255 );
	
	return PLUGIN_HANDLED;
}

/* ConCmd */
public ConCmd_OpenCells( iPlayerID, iLevel, iCid ) {
	/*
		Open cells command, that will trigger the button that will open the cells
		and tell all players about the action.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 1 ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^3 Access denied.^1 Only ^4admins^1 can use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_iOpenCommand ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 Command has been ^3disabled^1.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	PushButton( );
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, 31 );
	
	client_print_color( 0, iPlayerID, "^4%s^3 %s^1 has opened the cells remotely.", g_strPluginPrefix, strPlayerName );
	
	return PLUGIN_HANDLED;
}

public ConCmd_AllowMic( iPlayerID, iLevel, iCid ) {
	/*
		This will enable the admins to provid certain players with microphone access. 
		That means they will be able to talk on the mic normally. It also allows to 
		take the access away for abusive players.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, 31 );
	
	new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
	
	if( !iTarget ) {
		return PLUGIN_HANDLED;
	}
	
	new strStatus[ 2 ];
	read_argv( 2, strStatus, 1 );
	
	if( str_to_num( strStatus ) ) {
		SetBit( g_bitHasMicPower, iTarget );
		
		get_user_name( iTarget, strTarget, 31 );
		console_print( iPlayerID, "Talk power has been granted to %s.", strTarget );
		
		get_user_name( iPlayerID, strTarget, 31 );
		client_print_color( iTarget, iPlayerID, "^4%s^1 Admin ^3%s^1 gave you talking power.", g_strPluginPrefix, strTarget );
		
		client_cmd( iTarget, "spk ^"vox/communication acquired^"" );
	} else {
		ClearBit( g_bitHasMicPower, iTarget );
		
		get_user_name( iTarget, strTarget, 31 );
		console_print( iPlayerID, "Talk power has been revoked from %s.", strTarget );
		
		get_user_name( iPlayerID, strTarget, 31 );
		client_print_color( iTarget, iPlayerID, "^4%s^1 Admin ^3%s^1 removed your talking power.", g_strPluginPrefix, strTarget );
		
		client_cmd( iTarget, "spk ^"vox/communication deactivated^"" );
	}
	
	return PLUGIN_HANDLED;
}

public ConCmd_GivePoints( iPlayerID, iLevel, iCid ) {
	/*
		Give points to a player.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, 31 );
	
	new strPoints[ 8 ];
	read_argv( 2, strPoints, 7 );
	
	new iPoints = clamp( str_to_num( strPoints ), 1, 16000 );
	
	new strAdminName[ 32 ], strAdminAuthID[ 36 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	get_user_authid( iPlayerID, strAdminAuthID, 35 );
	
	if( strTarget[ 0 ] == '@' ) {
		new iPlayers[ 32 ], iNum, iTempID;
		new strTeam[ 32 ];
		
		switch( strTarget[ 1 ] ) {
			case 't', 'T': {
				formatex( strTeam, 31, "TERRORIST" );
				get_players( iPlayers, iNum, "e", "TERRORIST" );
			}
			
			case 's', 'S': {
				formatex( strTeam, 31, "SPECTATOR" );
				get_players( iPlayers, iNum, "e", "SPECTATOR" );
			}
			
			case 'c', 'C': {
				formatex( strTeam, 31, "COUNTER-TERRORIST" );
				get_players( iPlayers, iNum, "e", "CT" );
			}
			
			case 'a', 'A': {
				formatex( strTeam, 31, "ALL" );
				get_players( iPlayers, iNum );
			}
			
			default: {
				console_print( iPlayerID, "Valid arguments: @T, @CT, @SPEC, and @ALL" );
				
				return PLUGIN_HANDLED;
			}
		}
		
		if( !iNum ) {
			console_print( iPlayerID, "No players found in such team" );
		}
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			if( access( iTempID, ADMIN_IMMUNITY ) ) {
				continue;
			}
			
			g_iPlayerPoints[ iTempID ] += iPoints;
			cs_set_user_money( iTempID, g_iPlayerPoints[ iTempID ] );
			
			SavePoints( iTempID );
		}
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 gave ^4%s^1 players ^4%i^1 points.", g_strPluginPrefix, strAdminName, strTeam, iPoints );
		log_amx( "Admin %s (%s) gave %s players %i points.", strAdminName, strAdminAuthID, strTeam, iPoints );
	} else {
		new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
		
		if( !iTarget ) {
			return PLUGIN_HANDLED;
		}
		
		new strTargetName[ 32 ], strTargetAuthID[ 36 ];
		get_user_name( iTarget, strTargetName, 31 );
		get_user_authid( iTarget, strTargetAuthID, 35 );
		
		g_iPlayerPoints[ iTarget ] += iPoints;
		cs_set_user_money( iTarget, g_iPlayerPoints[ iTarget ] );
		
		SavePoints( iTarget );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 gave %s ^4%i^1 points.", g_strPluginPrefix, strAdminName, strTargetName, iPoints );
		log_amx( "Admin %s (%s) gave %s (%s) %i points.", strAdminName, strAdminAuthID, strTargetName, strTargetAuthID, iPoints );
	}
	
	return PLUGIN_HANDLED;
}

public ConCmd_RemovePoints( iPlayerID, iLevel, iCid ) {
	/*
		Remove points from certain player.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, charsmax( strTarget ) );
	
	new strPoints[ 8 ];
	read_argv( 2, strPoints, charsmax( strPoints ) );
	
	new iPoints = clamp( str_to_num( strPoints ), 1, 16000 );
	
	new strAdminName[ 32 ], strAdminAuthID[ 36 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	get_user_authid( iPlayerID, strAdminAuthID, 35 );
	
	if( strTarget[ 0 ] == '@' ) {
		new iPlayers[ 32 ], iNum, iTempID;
		new strTeam[ 32 ];
		
		switch( strTarget[ 1 ] ) {
			case 't', 'T': {
				formatex( strTeam, charsmax( strTeam ), "TERRORIST" );
				get_players( iPlayers, iNum, "e", "TERRORIST" );
			}
			
			case 's', 'S': {
				formatex( strTeam, charsmax( strTeam ), "SPECTATOR" );
				get_players( iPlayers, iNum, "e", "SPECTATOR" );
			}
			
			case 'c', 'C': {
				formatex( strTeam, charsmax( strTeam ), "COUNTER-TERRORIST" );
				get_players( iPlayers, iNum, "e", "CT" );
			}
			
			case 'a', 'A': {
				formatex( strTeam, charsmax( strTeam ), "ALL" );
				get_players( iPlayers, iNum );
			}
			
			default: {
				console_print( iPlayerID, "Valid arguments: @T, @CT, @SPEC, and @ALL" );
				
				return PLUGIN_HANDLED;
			}
		}
		
		if( !iNum ) {
			console_print( iPlayerID, "No players found in such team" );
		}
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			if( access( iTempID, ADMIN_IMMUNITY ) ) {
				continue;
			}
			
			g_iPlayerPoints[ iTempID ] -= iPoints;
			cs_set_user_money( iTempID, g_iPlayerPoints[ iTempID ] );
			
			SavePoints( iTempID );
		}
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 took away ^4%i^1 points from ^4%s^1 players.", g_strPluginPrefix, strAdminName, iPoints, strTeam );
		log_amx( "Admin %s (%s) took away %i points from %s players.", strAdminName, strAdminAuthID, iPoints, strTeam );
	} else {
		new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
		
		if( !iTarget ) {
			return PLUGIN_HANDLED;
		}
		
		g_iPlayerPoints[ iTarget ] -= iPoints;
		cs_set_user_money( iTarget, g_iPlayerPoints[ iTarget ] );
		
		SavePoints( iTarget );
		
		new strTargetName[ 32 ], strTargetAuthID[ 36 ];
		get_user_name( iTarget, strTargetName, 31 );
		get_user_authid( iTarget, strTargetAuthID, 35 );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 took away ^4%i^1 points from ^4%s^1.", g_strPluginPrefix, strAdminName, iPoints, strTargetName );
		log_amx( "Admin %s (%s) took away %i points from %s (%s).", strAdminName, strAdminAuthID, iPoints, strTargetName, strTargetAuthID );
	}
	
	return PLUGIN_HANDLED;
}

public ConCmd_ResetPoints( iPlayerID, iLevel, iCid ) {
	/*
		Reset a player's points to 0.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 1 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, 31 );
	
	new strAdminName[ 32 ], strAdminAuthID[ 36 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	get_user_authid( iPlayerID, strAdminAuthID, 35 );
	
	if( strTarget[ 0 ] == '@' ) {
		new iPlayers[ 32 ], iNum, iTempID;
		new strTeam[ 32 ];
		
		switch( strTarget[ 1 ] ) {
			case 't', 'T': {
				formatex( strTeam, 31, "TERRORIST" );
				get_players( iPlayers, iNum, "e", "TERRORIST" );
			}
			
			case 's', 'S': {
				formatex( strTeam, 31, "SPECTATOR" );
				get_players( iPlayers, iNum, "e", "SPECTATOR" );
			}
			
			case 'c', 'C': {
				formatex( strTeam, 31, "COUNTER-TERRORIST" );
				get_players( iPlayers, iNum, "e", "CT" );
			}
			
			case 'a', 'A': {
				formatex( strTeam, 31, "ALL" );
				get_players( iPlayers, iNum );
			}
			
			default: {
				console_print( iPlayerID, "Valid arguments: @T, @CT, @SPEC, and @ALL" );
				
				return PLUGIN_HANDLED;
			}
		}
		
		if( !iNum ) {
			console_print( iPlayerID, "No players found in such team" );
		}
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			if( access( iTempID, ADMIN_IMMUNITY ) ) {
				continue;
			}
			
			g_iPlayerPoints[ iTempID ] = 0;
			cs_set_user_money( iTempID, 0 );
			
			SavePoints( iTempID );
		}
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 reset ^4%s^1 players' points.", g_strPluginPrefix, strAdminName, strTeam );
		log_amx( "Admin %s (%s) reset %s players' points.", strAdminName, strAdminAuthID, strTeam );
	} else {
		new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
		
		if( !iTarget ) {
			return PLUGIN_HANDLED;
		}
		
		new strTargetName[ 32 ], strTargetAuthID[ 36 ];
		get_user_name( iTarget, strTargetName, 31 );
		get_user_authid( iTarget, strTargetAuthID, 35 );
		
		g_iPlayerPoints[ iTarget ] = 0;
		cs_set_user_money( iTarget, 0 );
		
		SavePoints( iTarget );
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 reset %s's points.", g_strPluginPrefix, strAdminName, strTargetName );
		
		log_amx( "Admin %s (%s) reset %s (%s)'s points.", strAdminName, strAdminAuthID, strTargetName, strTargetAuthID );
	}
	
	return PLUGIN_HANDLED;
}

public ConCmd_GetPoints( iPlayerID, iLevel, iCid ) {
	/*
		Check how much points the player has.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 1 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, 31 );
	
	new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
	
	if( !iTarget ) {
		return PLUGIN_HANDLED;
	}
	
	new iPoints = g_iPlayerPoints[ iTarget ];
	
	new strAdminName[ 32 ], strTargetName[ 32 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	get_user_name( iTarget, strTargetName, 31 );
	
	console_print( iPlayerID, "%s has %i points.", strTargetName, iPoints );
	
	new strAdminAuthID[ 36 ], strTargetAuthID[ 36 ];
	get_user_authid( iPlayerID, strAdminAuthID, 35 );
	get_user_authid( iTarget, strTargetAuthID, 35 );
	
	log_amx( "Admin %s (%s) saw %s (%s)'s points.", strAdminName, strAdminAuthID, strTargetName, strTargetAuthID );
	
	return PLUGIN_HANDLED;
}

public ConCmd_BanCT( iPlayerID, iLevel, iCid ) {
	/*
		Ban or unban a player from CT team.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 36 ];
	read_argv( 1, strTarget, 35 );
	
	new strStatus[ 8 ];
	read_argv( 2, strStatus, 7 );
	
	new iStatus = clamp( str_to_num( strStatus ), 0, 1 );
	
	new strAdminName[ 32 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	
	/*if( contain( strTarget, "STEAM:" ) ) {
		new strFormatex[ 64 ];
		formatex( strFormatex, 63, "%s-CTBAN", strTarget );
		
		if( iStatus ) {
			nvault_set( g_iVaultPoints, strFormatex, "1" );
			client_print_color( 0, print_team_red, "^4%s %s^1 banned ^3%s^1 from the CT team.", g_strPluginPrefix, strAdminName, strTarget );
		} else {
			nvault_set( g_iVaultPoints, strFormatex, "0" );
			client_print_color( 0, print_team_red, "^4%s %s^1 unbanned ^3%s^1 from the CT team.", g_strPluginPrefix, strAdminName, strTarget );
		}
		
		return PLUGIN_HANDLED;
	}*/
	
	new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
	
	if( !iTarget ) {
		return PLUGIN_HANDLED;
	}
	
	BanPlayerCT( iTarget, iStatus );
	
	new strPlayerName[ 32 ];
	get_user_name( iTarget, strPlayerName, 31 );
	
	if( iStatus ) {
		client_print_color( 0, print_team_red, "^4%s %s^1 banned ^3%s^1 from the CT team.", g_strPluginPrefix, strAdminName, strPlayerName );
	} else {
		if( get_user_flags( iPlayerID ) & ADMIN_RCON ) {
			client_print_color( 0, print_team_red, "^4%s %s^1 unbanned ^3%s^1 from the CT team.", g_strPluginPrefix, strAdminName, strPlayerName );
		}
	}
	
	return PLUGIN_HANDLED;
}

public ConCmd_GiveVIP( iPlayerID, iLevel, iCid ) {
	/*
		Give player vip status.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 36 ];
	read_argv( 1, strTarget, 35 );
	
	new strAdminName[ 32 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	
	new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );
	
	if( !iTarget ) {
		return PLUGIN_HANDLED;
	}
	
	new strTargetAuthID[ 36 ];
	get_user_authid( iTarget, strTargetAuthID, 35 );
	
	new strFormatex[ 64 ];
	formatex( strFormatex, 63, "%s-VIP", strTargetAuthID );
	
	nvault_set( g_iVaultPoints, strFormatex, "1" );
	
	SetBit( g_bitIsPlayerVIP, iTarget );
	
	new strTargetName[ 32 ];
	get_user_name( iTarget, strTargetName, 31 );
	
	client_print_color( 0, print_team_red, "^4%s %s^1 added ^3%s^1 to the VIP list.", g_strPluginPrefix, strAdminName, strTargetName );
	
	return PLUGIN_HANDLED;
}

public ConCmd_RemoveVIP( iPlayerID, iLevel, iCid ) {
	/*
		Remove's a player's vip status.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 1 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 36 ];
	read_argv( 1, strTarget, 35 );
	
	new strAdminName[ 32 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	
	new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );
	
	if( !iTarget ) {
		return PLUGIN_HANDLED;
	}
	
	new strTargetAuthID[ 36 ];
	get_user_authid( iTarget, strTargetAuthID, 35 );
	
	new strFormatex[ 64 ];
	formatex( strFormatex, 63, "%s-VIP", strTargetAuthID );
	
	nvault_set( g_iVaultPoints, strFormatex, "0" );
	
	ClearBit( g_bitIsPlayerVIP, iTarget );
	
	new strTargetName[ 32 ];
	get_user_name( iTarget, strTargetName, 31 );
	
	client_print_color( 0, print_team_red, "^4%s %s^1 removed ^3%s^1 from the VIP list.", g_strPluginPrefix, strAdminName, strTargetName );
	
	return PLUGIN_HANDLED;
}

public ConCmd_GetPlayedTime( iPlayerID, iLevel, iCid ) {
	/*
		Get how much the player has been playing on the server.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 1 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, 31 );
	
	new iTarget = cmd_target( iPlayerID, strTarget );
	
	if( !iTarget ) {
		return PLUGIN_HANDLED;
	}
	
	get_user_name( iTarget, strTarget, 31 );
	
	console_print( iPlayerID, "%s have been playing on the server for %d minute(s)", strTarget, ( get_user_time( iTarget ) / 60 ) + g_iPlayerTime[ iTarget ] );
	console_print( iPlayerID, "%s's current session time: %d minute(s).", strTarget, get_user_time( iTarget ) / 60 );
	
	client_print_color( iPlayerID, iTarget, "^4%s^3 %s^1 have been playing on the server for ^4%d minute(s)^1.", g_strPluginPrefix, strTarget, ( get_user_time( iTarget ) / 60 ) + g_iPlayerTime[ iTarget ] );
	client_print_color( iPlayerID, iTarget, "^4%s^3 %s^1's current session time: ^4%d minute(s)^1.", g_strPluginPrefix, strTarget, get_user_time( iTarget ) / 60 );
	
	return PLUGIN_HANDLED;
}

public ConCmd_SetButton( iPlayerID, iLevel, iCid ) {
	/*
		Set the button that is used to open the cells so it can be used by /open and 
		others.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 1 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new iEntity = GetAimingEnt( iPlayerID );
	
	if( !is_valid_ent( iEntity ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You are not aiming at a button.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	new strModelName[ 32 ];
	pev( iEntity, pev_model, strModelName, 31 );
	
	new strMapName[ 32 ];
	get_mapname( strMapName, 31 );
	
	nvault_set( g_iVaultPoints, strMapName, strModelName );
	
	if( !g_iButton ) {
		g_iButton = iEntity;
	}
	
	client_print_color( iPlayerID, print_team_blue, "^4%s^1 The cells button has been saved. Thank you!", g_strPluginPrefix );
	
	return PLUGIN_HANDLED;
}

public ConCmd_DonatePoints( iPlayerID, iLevel, iCid ) {
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, 31 );
	
	new iTarget = cmd_target( iPlayerID, strTarget, 0 );
	
	if( !iTarget || iTarget == iPlayerID ) {
		return PLUGIN_HANDLED;
	}
	
	new strPoints[ 8 ];
	read_argv( 2, strPoints, 7 );
	
	new iPoints = str_to_num( strPoints );
	
	if( iPoints <= 49 || g_iPlayerPoints[ iPlayerID ] < iPoints ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 Make sure you have that many points and that the value is ^3above 50^1.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	g_iPlayerPoints[ iPlayerID ] -= iPoints;
	g_iPlayerPoints[ iTarget ] += ( iPoints - iPoints / 10 );
	
	SavePoints( iPlayerID );
	SavePoints( iTarget );
	
	cs_set_user_money( iPlayerID, g_iPlayerPoints[ iPlayerID ] );
	cs_set_user_money( iTarget, g_iPlayerPoints[ iTarget ] );
	
	new strAdminName[ 32 ], strTargetName[ 32 ];
	get_user_name( iPlayerID, strAdminName, 31 );
	get_user_name( iTarget, strTargetName, 31 );
	
	client_print_color( 0, iPlayerID, "^4%s^3 %s^1 donated ^4%i^1 points to ^4%s^1.", g_strPluginPrefix, strAdminName, ( iPoints - iPoints / 10 ), strTargetName );
	client_print_color( iPlayerID, print_team_red, "^4%s^1 A 1/10 donate fee has been removed, and the rest has been donated to ^4%s^1.", g_strPluginPrefix, strTargetName );
	
	return PLUGIN_HANDLED;
}

/* Forwards */
public Forward_AddToFullPack_Post( ES_Handle, e, iEnt, iHost, iHostFlags, iID, pSet ) {
	/*
		This is used to make a team invisible to the enemy but visible to their teammates
		on some days like nightcrawler and samurai n seek.
	*/
	if( iID ) {
		if( g_iCurrentDay == DAY_SAMURAI && task_exists( TASK_COUNTDOWN_SAMURAI ) ||
		g_iCurrentDay == DAY_SHARK && task_exists( TASK_COUNTDOWN_SHARK ) ||
		g_iCurrentDay == DAY_NIGHTCRAWLER ) {
			if( cs_get_user_team( iHost ) == cs_get_user_team( iEnt ) ) {
				set_es( ES_Handle, ES_RenderMode, kRenderTransTexture );
				set_es( ES_Handle, ES_RenderAmt, 125 );
			}
		}
	}
}

public Forward_PlayerPreThink( iPlayerID ) {
	/*
		Wall climbing action. When players pressed 'E' (use key) on a wall he will climb that thing
		just like spiderman :P.
	*/
	if( g_iCurrentDay == DAY_NIGHTCRAWLER ) {
		static CsTeams:iTeam;
		iTeam = cs_get_user_team( iPlayerID );
		
		if( g_iWallClimb ) {
			if( iTeam == CS_TEAM_T && g_iTypeNightCrawler == REVERSED ||
			iTeam == CS_TEAM_CT && g_iTypeNightCrawler == REGULAR ) {
				static iButton;
				iButton = get_user_button( iPlayerID );
				
				if( iButton & IN_USE ) {
					static Float:fOrigin[ 3 ];
					pev( iPlayerID, pev_origin, fOrigin );
					
					if( get_distance_f( fOrigin, g_fWallOrigin[ iPlayerID ] ) > 10.0 ||
					get_entity_flags( iPlayerID ) & FL_ONGROUND ) {
						return FMRES_IGNORED;
					}
					
					if( iButton & IN_FORWARD ) {
						static Float:fVelocity[ 3 ];
						velocity_by_aim( iPlayerID, 240, fVelocity );
						
						set_user_velocity( iPlayerID, fVelocity );
					} else if( iButton & IN_BACK ) {
						static Float:fVelocity[ 3 ];
						velocity_by_aim( iPlayerID, -240, fVelocity );
						
						set_user_velocity( iPlayerID, fVelocity );
					}
				}
			}
		}
		
		if( iTeam == CS_TEAM_T && g_iTypeNightCrawler == REGULAR ||
		iTeam == CS_TEAM_CT && g_iTypeNightCrawler == REVERSED ) {
			if( CheckBit( g_bitIsAlive, iPlayerID ) ) {
				static iTarget, iBody, iRed, iGreen, iBlue, iWeapon;
				get_user_aiming( iPlayerID, iTarget, iBody );
				iWeapon = get_user_weapon( iPlayerID );
				
				if( IsPrimaryWeapon( iWeapon ) || IsSecondaryWeapon( iWeapon ) ) {
					if( is_user( iTarget ) && CheckBit( g_bitIsAlive, iTarget ) && iTeam != cs_get_user_team( iTarget ) ) {
						iRed = 255;
						iGreen = 0;
						iBlue = 0;
					} else {
						iRed = 0;
						iGreen = 255;
						iBlue = 0;
					}
					
					static iOrigin[ 3 ];
					get_user_origin( iPlayerID, iOrigin, 3 );
					
					message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
					write_byte( TE_BEAMENTPOINT );
					write_short( iPlayerID | 0x1000 );
					write_coord( iOrigin[ 0 ] );
					write_coord( iOrigin[ 1 ] );
					write_coord( iOrigin[ 2 ] );
					write_short( g_iLaserSprite );
					write_byte( 1 );
					write_byte( 10 );
					write_byte( 1 );
					write_byte( 5 );
					write_byte( 0 );
					write_byte( iRed );
					write_byte( iGreen );
					write_byte( iBlue );
					write_byte( 150 );
					write_byte( 25 );
					message_end( );
				}
			}
		}
	} else if( iPlayerID == g_iCommander ) {
		if( prethink_counter[ iPlayerID ]++ > 5 ) {
			if( is_drawing[ iPlayerID ] && !is_aiming_at_sky( iPlayerID ) ) {
				static Float:cur_origin[3], Float:distance;
				
				cur_origin = origin[iPlayerID];
				
				if(!is_holding[iPlayerID]){
					fm_get_aim_origin(iPlayerID, origin[iPlayerID]);
					move_toward_client(iPlayerID, origin[iPlayerID]);
					is_holding[iPlayerID] = true;
					return FMRES_IGNORED;
				}
				
				fm_get_aim_origin(iPlayerID, origin[iPlayerID]);
				move_toward_client(iPlayerID, origin[iPlayerID]);
				
				distance = get_distance_f(origin[iPlayerID], cur_origin);
				
				if(distance > 2) {
					draw_line(origin[iPlayerID], cur_origin);
				}
			} else {
				is_holding[iPlayerID] = false;
			}
			prethink_counter[ iPlayerID ] = 0;
		}
	}
	
	return FMRES_IGNORED;
}

public Forward_SetClientListening( iReceiverID, iSenderID, bool:bListen ) {
	/*
		Block or allow user from using his mic according to many many conditions.
	*/
	if( !is_user( iReceiverID ) || !is_user( iSenderID ) ||
	!CheckBit( g_bitIsConnected, iReceiverID ) || !CheckBit( g_bitIsConnected, iSenderID ) ||
	CheckBit( g_bitHasMicPower, iSenderID ) || is_user_admin( iSenderID ) || CheckBit( g_bitIsPlayerVIP, iSenderID ) ) {
		return FMRES_IGNORED;
	}
	
	if( g_iLRMic && g_iLastTerrorist == iSenderID ) {
		return FMRES_IGNORED;
	}
	
	if( cs_get_user_team( iSenderID ) != CS_TEAM_CT || !CheckBit( g_bitIsAlive, iSenderID ) ) {
		engfunc( EngFunc_SetClientListening, iReceiverID, iSenderID, 0 );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public Forward_CmdStart( iPlayerID, UC_Handle ) {
	/*
		This allows players to move way faster when they are in noclip mode 
		and they press 'SHIFT' (walk key).
		This is not done by me, pulled it from somewhere in alliedmods forums.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) || 
	pev( iPlayerID, pev_movetype ) != MOVETYPE_NOCLIP ||
	!( pev( iPlayerID, pev_button ) & IN_FORWARD ) ) {
		return FMRES_IGNORED;
	}
	
	static Float:fForward, Float:fSide;
	get_uc( UC_Handle, UC_ForwardMove, fForward );
	get_uc( UC_Handle, UC_SideMove, fSide );
	
	if( fForward == 0.0 && fSide == 0.0 ) {
		return FMRES_IGNORED;
	}
	
	static Float:fMaxSpeed, Float:fWalkSpeed;
	pev( iPlayerID, pev_maxspeed, fMaxSpeed );
	fWalkSpeed = fMaxSpeed * 0.52;
	
	if( floatabs( fForward ) <= fWalkSpeed && floatabs( fSide ) <= fWalkSpeed ) {
		static Float:vOrigin[ 3 ], Float:vAngle[ 3 ];
		pev( iPlayerID, pev_origin, vOrigin );
		pev( iPlayerID, pev_v_angle, vAngle );
		
		engfunc( EngFunc_MakeVectors, vAngle );
		global_get( glb_v_forward, vAngle );
		
		vOrigin[ 0 ] += ( vAngle[ 0 ] * NOCLIP_SPEED );
		vOrigin[ 1 ] += ( vAngle[ 1 ] * NOCLIP_SPEED );
		vOrigin[ 2 ] += ( vAngle[ 2 ] * NOCLIP_SPEED );
		
		engfunc( EngFunc_SetOrigin, iPlayerID, vOrigin );
	}
	
	return FMRES_IGNORED;
}

public Forward_Touch( iToucher, iTouched ) {
	/*
		All this magic is basically for the mario day. Where it checks if a user
		has landed on top of the other player and kills the one on the bottom.
	*/
	if( g_iCurrentDay != DAY_MARIO || task_exists( TASK_COUNTDOWN_MARIO ) ) {
		return FMRES_IGNORED;
	}
	
	if( !CheckBit( g_bitIsAlive, iToucher ) || !CheckBit( g_bitIsAlive, iTouched ) ) {
		return FMRES_IGNORED;
	}
	
	if( !is_user( iToucher ) || !is_user( iTouched ) ) {
		return FMRES_IGNORED;
	}
	
	if( cs_get_user_team( iToucher ) != cs_get_user_team( iTouched ) ) {
		return FMRES_IGNORED;
	}
	
	static iOriginToucher[ 3 ], iOriginTouched[ 3 ];
	get_user_origin( iToucher, iOriginToucher );
	get_user_origin( iTouched, iOriginTouched );
	
	static Float:fMinSizeToucher[ 3 ], Float:fMinSizeTouched[ 3 ];
	pev( iToucher, pev_mins, fMinSizeToucher );
	pev( iTouched, pev_mins, fMinSizeTouched );
	
	if( fMinSizeTouched[ 2 ] != -18.0 ) {
		if( !( iOriginToucher[ 2 ] == iOriginTouched[ 2 ] + 72 && fMinSizeToucher[ 2 ] != -18.0 ) &&
	!( iOriginToucher[ 2 ] == iOriginTouched[ 2 ] + 54 && fMinSizeToucher[ 2 ] == -18.0 ) ) {
		return FMRES_IGNORED;
	}
	} else {
		if( !( iOriginToucher[ 2 ] == iOriginTouched[ 2 ] + 68 && fMinSizeToucher[ 2 ] != -18.0 ) && 
		!( iOriginToucher[ 2 ] == iOriginTouched[ 2 ] + 50 && fMinSizeToucher[ 2 ] == -18.0 ) ) {
			return FMRES_IGNORED;
		}
	}
	
	user_kill( iTouched, 1 );
	set_pev( iToucher, pev_frags, pev( iToucher, pev_frags ) + 1.0 );
	
	client_cmd( 0, "spk %s", g_strSounds[ SOUND_MARIO_DOWN ] );
	
	return FMRES_IGNORED;
}

public Forward_SetModel( iEnt ) {
	/*
		Set color on weapons when a weapon is thrown in weapon toss last request.
	*/
	if( !g_bLRInProgress || !pev_valid( iEnt ) ) {
		return FMRES_IGNORED;
	}
	
	static iPlayerID;
	iPlayerID = pev( iEnt, pev_owner );
	
	if( !is_user( iPlayerID ) || g_iCurrentLR != LR_WEAPONTOSS ) {
		return FMRES_IGNORED;
	}
	
	static iWeaponID;
	iWeaponID = GetWeaponBoxType( iEnt );
	
	if( !iWeaponID ) {
		return FMRES_IGNORED;
	}
	
	static strWeaponName[ 32 ];
	get_weaponname( iWeaponID, strWeaponName, 31 );
	
	static bool:bIsWeapon;
	
	if( equal( strWeaponName, g_strWTWeapons[ g_iChosenWT ] ) ) {
		bIsWeapon = true;
	} else {
		bIsWeapon = false;
	}
	
	if( iPlayerID == g_iLastRequest[ PLAYER_OFFICER ] && bIsWeapon ) {
		set_pev( iEnt, pev_renderfx, kRenderFxGlowShell );
		set_pev( iEnt, pev_rendercolor, { 0.0, 0.0, 255.0 } );
		set_pev( iEnt, pev_rendermode, kRenderNormal );
		set_pev( iEnt, pev_renderamt, 16.0 );
		
		SetBeamFollow( iEnt, BEAM_LIFE, BEAM_WIDTH, 0, 0, 255, BEAM_BRIGHT );
	} else if( iPlayerID == g_iLastRequest[ PLAYER_PRISONER ] && bIsWeapon ) {
		set_pev( iEnt, pev_renderfx, kRenderFxGlowShell );
		set_pev( iEnt, pev_rendercolor, { 255.0, 0.0, 0.0 } );
		set_pev( iEnt, pev_rendermode, kRenderNormal );
		set_pev( iEnt, pev_renderamt, 16.0 );
		
		SetBeamFollow( iEnt, BEAM_LIFE, BEAM_WIDTH, 255, 0, 0, BEAM_BRIGHT );
	}
	
	return FMRES_IGNORED;
}

public Forward_GetGameDescription( ) {
	/*
		Change game description when the server's info are showing.
	*/
	forward_return( FMV_STRING, g_strPluginName );
	
	return FMRES_SUPERCEDE;
}

public Forward_EmitSound( iPlayerID, iChannel, strSound[ ] ) {
	/*
		If user does not have prison knife, emit stabbing sounds else do nothing. Doing
		nothing means that normal knife sounds are being emitted.
	*/
	if( !( 1 <= iPlayerID <= MAX_PLAYERS ) || !CheckBit( g_bitIsAlive, iPlayerID ) || CheckBit( g_bitHasPrisonKnife, iPlayerID ) || g_iPlayerKnife[ iPlayerID ] == KNIFE_DAEDRIC ) {
		return FMRES_IGNORED;
	}
	
	if( get_user_weapon( iPlayerID ) == CSW_KNIFE ) {
		if( strSound[ 8 ] == 'k' && strSound[ 13 ] == '_' ) {
			if( strSound[ 14 ] == 's' ) {
				emit_sound( iPlayerID, CHAN_WEAPON, g_strKnifeSounds[ GetKnifeSound( iPlayerID, 1 ) ], 1.0, ATTN_NORM, 0, PITCH_NORM );
			} else {
				emit_sound( iPlayerID, CHAN_WEAPON, g_strKnifeSounds[ GetKnifeSound( iPlayerID, 0 ) ], 1.0, ATTN_NORM, 0, PITCH_NORM );
			}
			
			return FMRES_SUPERCEDE;
		}
	}
	
	return FMRES_IGNORED;
}

/* Messages */
public Message_ShowMenu( iMessageID, iDestination, iPlayerID ) {
	/*
		When menu to join a team is shown old style.
		Block it and show main menu instead.
		Also set the player to T if it's his first time joining.
	*/
	static strMenuCode[ g_iJoinMsgLen ];
	get_msg_arg_string( 4, strMenuCode, g_iJoinMsgLen - 1 );
	
	/* Allows multiple team changes */
	set_pdata_int( iPlayerID, 125, get_pdata_int( iPlayerID, 125, 5 ) & ~ ( 1<<8 ), 5 );
	
	if( equal( strMenuCode, FIRST_JOIN_MSG ) || equal( strMenuCode, FIRST_JOIN_MSG_SPEC ) ) {
		if( CheckBit( g_bitIsConnected, iPlayerID ) && !task_exists( TASK_TEAMJOIN + iPlayerID ) ) {
			static iParameters[ 2 ];
			iParameters[ 0 ] = iMessageID;
			
			ClearBit( g_bitIsFirstConnect, iPlayerID );
			
			set_task( 0.1, "Task_TeamJoin", TASK_TEAMJOIN + iPlayerID, iParameters, 1 );
			
			iParameters[ 0 ] = iPlayerID;
			set_task( 2.5, "Task_NotifyMenu", _, iParameters, 1 );
			
			return PLUGIN_HANDLED;
		}
	} else if( equal( strMenuCode, INGAME_JOIN_MSG ) || equal( strMenuCode, INGAME_JOIN_MSG_SPEC ) ) {
		set_task( 0.1, "ShowMainMenu", iPlayerID );
		
		return PLUGIN_HANDLED;
	}
	
	return PLUGIN_CONTINUE;
}

public Message_VGUIMenu( iMessageID, iDestination, iPlayerID ) {
	/*
		When menu to join a team is shown vgui style.
		Block it and show main menu instead.
		Also set the player to T if it's his first time joining.
	*/
	
	/* Allows multiple team changes */
	set_pdata_int( iPlayerID, 125, get_pdata_int( iPlayerID, 125, 5 ) & ~ ( 1<<8 ), 5 );
	
	if( get_msg_arg_int( 1 ) != 2 ) {
		return PLUGIN_CONTINUE;
	}
	
	if( CheckBit( g_bitIsConnected, iPlayerID ) && !task_exists( TASK_TEAMJOIN + iPlayerID ) ) {
		if( CheckBit( g_bitIsFirstConnect, iPlayerID ) ) {
			ClearBit( g_bitIsFirstConnect, iPlayerID );
			
			static iParameters[ 2 ];
			iParameters[ 0 ] = iMessageID;
			
			set_task( 0.1, "Task_TeamJoin", TASK_TEAMJOIN + iPlayerID, iParameters, 1 );
			
			iParameters[ 0 ] = iPlayerID;
			set_task( 2.5, "Task_NotifyMenu", _, iParameters, 1 );
			
			return PLUGIN_HANDLED;	
		} else {
			set_task( 0.1, "ShowMainMenu", iPlayerID );
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
}

public Message_StatusIcon( msg_id, MSG_DEST, iPlayerID ) {
	/*
		Block buy zones if the map maker did not think of that.
	*/
	new strIcon[ 5 ];
	get_msg_arg_string( 2, strIcon, 4 );
	
	if( strIcon[ 0 ] == 'b' && strIcon[ 2 ] == 'y' && strIcon[ 3 ] == 'z' ) {
		if( get_msg_arg_int( 1 ) ) {
			set_pdata_int( iPlayerID, 235, get_pdata_int( iPlayerID, 235, 5 ) & ~( 1<<0 ), 5 );
			
			return PLUGIN_HANDLED;
		}
	}
	
	return PLUGIN_CONTINUE;
} 

/* HamHooks */
public Ham_Spawn_Player_Post( iPlayerID ) {
	if( !is_user_alive( iPlayerID ) ) {
		return HAM_IGNORED;
	}
	
	/*
		He is alive, strip his weapons and show the health.
	*/
	SetBit( g_bitIsAlive, iPlayerID );
	
	StripPlayerWeapons( iPlayerID );
	
	ShowHealth( iPlayerID );
	
	/*
		Last request in progres. Kill user as he is certainly a reconnecter.
	*/
	if( g_bLRInProgress ) {
		user_kill( iPlayerID );
		
		client_print_color( iPlayerID, print_team_red, "^4%s^1 Sorry but another ^3Prisoner^1 already has ^4Last Request^1.", g_strPluginPrefix );
	}
	
	return HAM_IGNORED;
}

public Ham_Killed_Player_Pre( iVictim, iKiller, iShouldGIB ) {
	/*
		Check if health is being shown the player and remove it.
	*/
	if( task_exists( iVictim ) ) {
		remove_task( iVictim );
		
		set_hudmessage( .channel = CHANNEL_HEALTH );
		show_hudmessage( iVictim, "" );
	}
	
	set_user_rendering( iVictim );
	
	new iPlayers[ 32 ], iNum;
	
	/*
		Check if dead player is President and slay all Guards.
	*/
	if( g_iCurrentDay == DAY_PRESIDENT && iVictim == g_iPresident ) {
		new iTempID;
		get_players( iPlayers, iNum, "ae", "CT" );
		
		for( new iLoop = 0 ;iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			if( iTempID != g_iPresident && CheckBit( g_bitIsAlive, iTempID ) ) {
				user_kill( iTempID, 1 );
			}
			
			new strPresidentName[ 32 ];
			get_user_name( iVictim, strPresidentName, 31 );
			
			client_print_color( 0, iVictim, "^4%s^1 President ^4[^3%s^4]^1 is now dead. All ^3Officers^1 have been automatically slayed.", g_strPluginPrefix, strPresidentName );
		}
	}
	
	new CsTeams:iVictimTeam = cs_get_user_team( iVictim );
	
	if( CheckBit( g_bitHasFreeDay, iVictim ) ) {
		ClearBit( g_bitHasFreeDay, iVictim );
	}
	
	/*
		Prisoner died? Check if its time for last request.
	*/
	if( iVictimTeam == CS_TEAM_T ) {
		switch( g_iCurrentDay ) {
			case DAY_CAGE, DAY_HNS, DAY_FREE: {
				CheckLastPlayer( );
			}
		}
	} else {
		/*
			Commander died. OH NO! Do some stuff.
		*/
		if( iVictim == g_iCommander ) {
			g_iCommander = -1;
			
			client_print_color( 0, iVictim, "^4%s^1 Current ^3Commander^1 has died. ^3Guards^1 type ^4/commander^1 to become the ^3Commander^1.", g_strPluginPrefix );
		}
	}
	
	ClearBit( g_bitIsAlive, iVictim );
	
	client_print_color( iVictim, print_team_default, "^4%s^1 You can now open the ^4Fun Menu^1 and have some fun while you are dead.", g_strPluginPrefix );
	
	/*
		Check if last request and do some stuff, else remove prisoner's name from the deathmsg as the killer.
	*/
	if( g_bLRInProgress ) {
		switch( g_iCurrentLR ) {
			case LR_KAMIKAZE, LR_DEAGLE_MANIAC, LR_GLOCKER: return HAM_IGNORED;
		}
		
		if( iVictim == g_iLastRequest[ PLAYER_OFFICER ] ) {
			EndLastRequest( iVictim, g_iLastRequest[ PLAYER_PRISONER ] );
		} else if( iVictim == g_iLastRequest[ PLAYER_PRISONER ] ) {
			EndLastRequest( iVictim, g_iLastRequest[ PLAYER_OFFICER ] );
		}
	} else if( g_iCurrentDay == DAY_CAGE || g_iCurrentDay == DAY_FREE || g_iCurrentDay == DAY_CUSTOM || g_iCurrentDay == DAY_JUDGEMENT || g_iCurrentDay == DAY_RIOT ) {
		if( is_user( iKiller ) && iVictimTeam == CS_TEAM_CT && cs_get_user_team( iKiller ) == CS_TEAM_T ) {
			SetHamParamEntity( 2, 0 );
			
			set_user_frags( iKiller, get_user_frags( iKiller ) + 1 );
			/*
				T killed a CT, award points for that. Extra for headshot.
			*/
			if( g_bGivePoints ) {
				if( CheckBit( g_bitIsHeadShot[ iKiller ], iVictim ) ) {
					g_iPlayerPoints[ iKiller ] += POINTS_KILL_HS;
					
					client_print_color( iKiller, print_team_red, "^4%s^1 Damn, did you see his head? That shot is worth ^4%i^1 points.", g_strPluginPrefix, POINTS_KILL_HS );
				} else {
					g_iPlayerPoints[ iKiller ] += POINTS_KILL;
					
					client_print_color( iKiller, print_team_blue, "^4%s^1 You got ^4%i point^1 for killing a ^3Guard^1.", g_strPluginPrefix, POINTS_KILL );
				}
				
				Event_Money( iKiller );
			}
			
			if( CheckBit( g_bitIsPlayerVIP, iKiller ) && get_user_weapon( iKiller ) == CSW_KNIFE ) {
				new strKillerName[ 32 ], strVictimName[ 32 ];
				get_user_name( iKiller, strKillerName, 31 );
				get_user_name( iVictim, strVictimName, 31 );
				
				switch( g_iPlayerKnife[ iKiller ] ) {
					case KNIFE_FIST: {
						static strOptions[ ][ ] = {
							"^3%s^1 has just dealt a deadly blow to ^4%s^1 with his bare fists.",
							"^3%s^1 has just fisted ^4%s^1, literally.",
							"^3%s^1 has just rekt ^4%s^1.",
							"^3%s^1: I'm not gonna use my weapons for somebody like you ^4%s^1."
						};
						
						client_print_color( 0, iKiller, strOptions[ random( 3 ) ], strKillerName, strVictimName );
					}
					
					case KNIFE_LIGHT_SABER: {
						static strOptions1[ ][ ] = {
							"^3%s^1: The force was not with you ^4%s^1.",
							"^1Jedi ^3%s^1 just taught ^4%s^1 a lesson.",
							"^3%s^1 showed ^4%s^1 the dark side.",
							"^3%s^1: I am your father ^4%s^1."
						};
						
						client_print_color( 0, iKiller, strOptions1[ random( 3 ) ], strKillerName, strVictimName );
					}
					
					case KNIFE_DAEDRIC: {
						static strOptions2[ ][ ] = {
							"^3%s^1: Your head will adore my wall ^4%s^1.",
							"^1Mythical blade of ^3%s^1 has just torn ^4%s^1 apart.",
							"^3%s^1: The hell is waiting for you ^4%s^1.",
							"^3%s^1 gave ^4%s^1 no chance at all."
						};
						
						client_print_color( 0, iKiller, strOptions2[ random( 3 ) ], strKillerName, strVictimName );
					}
					
					case KNIFE_MACHETE: {
						static strOptions3[ ][ ] = {
							"^3%s^1 has just made a lasagna out of ^4%s^1.",
							"^3%s^1 has just cut ^4%s^1 to pieces.",
							"^3%s^1 Feel my wrath ^4%s^1.",
							"^1Reporting error log to ^3%s^1: ERROR 404  HEAD OF ^4%s^1 NOT FOUND"
						};
						
						client_print_color( 0, iKiller, strOptions3[ random( 3 ) ], strKillerName, strVictimName );
					}
					
					case KNIFE_KATANA: {
						static strOptions4[ ][ ] = {
							"^3%s^1 has just played a game of 'Fruit Ninja' with the body of ^4%s^1.",
							"^3%s^1 has just made sushi out of ^4%s^1.",
							"^3%s^1 just showcased the skill of a true samurai to ^4%s^1.",
							"^3%s^1: How does my blade feel ^4%s^1?"
						};
						
						client_print_color( 0, iKiller, strOptions4[ random( 3 ) ], strKillerName, strVictimName );
					}
				}
			}
			
			ShowTopInfo( );
			
			return HAM_HANDLED;
		}
	}
	
	return HAM_IGNORED;
}

public Ham_TakeDamage_Player_Pre( iVictim, iInflictor, iAttacker, Float:fDamage, iDamageBits ) {
	/*
		Remove fall damage. And then block damage on certain days.
	*/
	if( !is_user( iAttacker ) ) {
		if( g_bDayInProgress && g_iCurrentDay == DAY_NIGHTCRAWLER && iDamageBits == DMG_FALL ) {
			if( g_iTypeNightCrawler == REGULAR ) {
				if( cs_get_user_team( iVictim ) == CS_TEAM_CT ) {
					SetHamReturnInteger( 0 );
					
					return HAM_SUPERCEDE;
				}
			} else {
				if( cs_get_user_team( iVictim ) == CS_TEAM_T ) {
					SetHamReturnInteger( 0 );
					
					return HAM_SUPERCEDE;
				}
			}
		} else {
			return HAM_IGNORED;
		}
	}
	
	if( g_bDayInProgress ) {
		switch( g_iCurrentDay ) {
			case DAY_SAMURAI: {
				if( task_exists( TASK_COUNTDOWN_SAMURAI ) ) {
					return HAM_SUPERCEDE;
				}
				
				if( cs_get_user_team( iAttacker ) == CS_TEAM_CT ) {
					SetHamParamFloat( 4, 200.0 );
					
					return HAM_HANDLED;
				}
			}
			
			case DAY_HNS: {
				if( task_exists( TASK_COUNTDOWN_HNS ) && cs_get_user_team( iVictim ) == CS_TEAM_CT ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_NIGHTCRAWLER: {
				if( task_exists( TASK_COUNTDOWN_NC ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_SHARK: {
				if( task_exists( TASK_COUNTDOWN_SHARK ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_JUDGEMENT: {
				new iWeaponID = get_user_weapon( iAttacker );
				new strWeaponName[ 32 ];
				get_weaponname( iWeaponID, strWeaponName, 31 );
				
				if( cs_get_user_team( iAttacker ) == CS_TEAM_CT && equal( strWeaponName, "weapon_deagle" ) ) {
					SetHamParamFloat( 4, 200.0 );
					
					return HAM_HANDLED;
				}
			}
			
			case DAY_MARIO: {
				return HAM_SUPERCEDE;
			}
			
			case DAY_CAGE: {
				if( CheckBit( g_bitHasPrisonKnife, iAttacker ) ) {
					new iWeaponID = get_user_weapon( iAttacker );
					new strWeaponName[ 32 ];
					get_weaponname( iWeaponID, strWeaponName, 31 );
					
					if( equal( strWeaponName, "weapon_knife" ) ) {
						SetHamParamFloat( 4, ( fDamage * 2.0 ) );
						
						return HAM_HANDLED;
					}
					
					return HAM_IGNORED;
				}
			}
		}
	}
	
	return HAM_IGNORED;
}

public Ham_SecondaryAttack_USP_Post( iEnt ) {
	/*
		Don't allow the removal of the silencer on usp ninjas day.
	*/
	if( g_iCurrentDay == DAY_USP_NINJA && !cs_get_weapon_silen( iEnt ) ) {
		cs_set_weapon_silen( iEnt, 1 );
	}
}

public Ham_Touch_Weapon_Pre( iEnt, iPlayerID ) {
	/*
		Block weapon pickup on certain days and certain last requests.
	*/
	if( !( 1 <= iPlayerID <= MAX_PLAYERS ) || !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return HAM_IGNORED;
	}
	
	static CsTeams:iTeam;
	iTeam = cs_get_user_team( iPlayerID );
	
	if( g_bLRInProgress ) {
		static iWeaponID;
		iWeaponID = GetWeaponBoxType( iEnt );
		if( !iWeaponID ) {
			return HAM_IGNORED;
		}
		
		static strWeaponName[ 32 ];
		get_weaponname( iWeaponID, strWeaponName, 31 );
		
		if( iPlayerID != g_iLastRequest[ PLAYER_OFFICER ] && iPlayerID != g_iLastRequest[ PLAYER_PRISONER ] ) {
			return HAM_IGNORED;
		}
		
		switch( g_iCurrentLR ) {
			case LR_KNIFE, LR_RACE: {
				return HAM_SUPERCEDE;
			}
			
			case LR_WEAPONTOSS: {
				if( !equal( strWeaponName, g_strWTWeapons[ g_iChosenWT ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_S4S: {
				if( !equal( strWeaponName, g_strS4SWeapons[ g_iChosenWE ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_GRENADETOSS: {
				if( !equal( strWeaponName, "weapon_smokegrenade" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_DUEL: {
				if( !equal( strWeaponName, g_strDuelWeapons[ g_iChosenWD ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_GLOCKER: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_T && !equal( strWeaponName, "weapon_glock18" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_DEAGLE_MANIAC: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_T && !equal( strWeaponName, "weapon_deagle" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_KAMIKAZE: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_T && !equal( strWeaponName, "weapon_m249" ) ) {
					return HAM_SUPERCEDE;
				}
			}
		}
	} 
	
	if( g_bDayInProgress ) {
		switch( g_iCurrentDay ) {
			case DAY_NIGHTCRAWLER: {
				if( iTeam == CS_TEAM_CT && g_iTypeNightCrawler == REGULAR ||
				iTeam == CS_TEAM_T && g_iTypeNightCrawler == REVERSED ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_ZOMBIE: {
				if( iTeam == CS_TEAM_CT && g_iTypeZombie == REVERSED ||
				iTeam == CS_TEAM_T && g_iTypeZombie == REGULAR ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_SHARK: {
				if( iTeam == CS_TEAM_CT && g_iTypeShark == REGULAR ||
				iTeam == CS_TEAM_T && g_iTypeShark == REVERSED ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_PRESIDENT: {
				if( iTeam == CS_TEAM_CT ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_JUDGEMENT: {
				if( iTeam == CS_TEAM_CT ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_LMS: {
				if( iTeam == CS_TEAM_T && !g_bLMSWeaponsOver ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_NADEWAR: {
				if( iTeam == CS_TEAM_T && task_exists( TASK_NADEWAR_GIVEGRENADE ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_SAMURAI, DAY_KNIFE, DAY_SPACE, DAY_USP_NINJA, DAY_COWBOY, DAY_HULK: {
				return HAM_SUPERCEDE;
			}
			
			case DAY_MARIO: {
				if( iTeam == CS_TEAM_T ) {
					return HAM_SUPERCEDE;
				}
			}
		}
	}
	
	return HAM_IGNORED;
}

public Ham_Touch_Wall_Pre( iEnt, iPlayerID ) {
	/*
		This sorcery is for climbing wall on nightcrawler. Get location and other stuff.
	*/
	if( g_iCurrentDay == DAY_NIGHTCRAWLER && CheckBit( g_bitIsAlive, iPlayerID ) && is_user( iPlayerID ) ) {
		pev( iPlayerID, pev_origin, g_fWallOrigin[ iPlayerID ] );
	}
}

public Ham_Touch_Grenade_Pre( iEntity, iTouched ) {
	/*
		This is basically for dodgeball, when the grenade hits a teammate,
		it directly kills him.
	*/
	if( !g_bDodgeBall || !is_user( iTouched ) ) {
		return HAM_IGNORED;
	}
	
	static Float:fGameTime;
	fGameTime = get_gametime( );
	
	if( g_fLastTouch[ iTouched ] < fGameTime ) {
		new iOwner = pev( iEntity, pev_owner );
		
		if( iOwner == iTouched ) {
			return HAM_IGNORED;
		}
		
		if( CheckBit( g_bitHasFreeDay, iTouched ) ) {
			return HAM_IGNORED;
		}
		
		if( pev( iTouched, pev_takedamage ) == DAMAGE_NO ) {
			return HAM_IGNORED;
		}
		
		if( CheckBit( g_bitIsConnected, iOwner ) && !CheckBit( g_bitHasFreeDay, iOwner ) ) {
			if( cs_get_user_team( iTouched ) != cs_get_user_team( iOwner ) ) {
				return HAM_IGNORED;
			}
			
			ExecuteHamB( Ham_Killed, iTouched, iOwner, 0 );
			set_user_frags( iOwner, get_user_frags( iOwner ) + 2 );
			
			/*
				Server crashing as soon as grenade hits the player. Therefore,
				I think its cause of removing the entity. Let's try it out shall we?
			*/
			// remove_entity( iEntity );
		}
		
		g_fLastTouch[ iTouched ] = fGameTime + 0.4;
	}
	
	return HAM_IGNORED;
}

public Ham_Use_Recharger_Pre( iEnt, iPlayerID ) {
	static iJuice = 75;
	
	if( get_pdata_ent( iEnt, iJuice, 5 ) <= 1 ) {
		set_pdata_int( iEnt, iJuice, 500 );
	}
	
	switch( g_iCurrentDay ) {
		case DAY_NIGHTCRAWLER, DAY_ZOMBIE, DAY_USP_NINJA, DAY_NADEWAR,
		DAY_HULK, DAY_SPACE, DAY_COWBOY, DAY_SHARK, DAY_SAMURAI, DAY_KNIFE,
		DAY_HNS, DAY_MARIO, DAY_PRESIDENT, DAY_LMS: {
			return HAM_SUPERCEDE;
		}
	}
	
	if( g_bLRInProgress && ( g_iLastRequest[ PLAYER_OFFICER ] == iPlayerID || g_iLastRequest[ PLAYER_PRISONER ] == iPlayerID ) ) {
		return HAM_SUPERCEDE;
	} else if( g_iCurrentLR == LR_KAMIKAZE || g_iCurrentLR == LR_DEAGLE_MANIAC || g_iCurrentLR == LR_GLOCKER ) {
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public Ham_TraceAttack_Button_Pre( iButton, iPlayerID, Float:fDamage, Float:fDirection[ 3 ], iHandle, iDamageBits ) {
	if( is_user( iPlayerID ) && is_valid_ent( iButton ) ) {
		switch( g_iShootButtons ) {
			case 1: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_T ) {
					ExecuteHamB( Ham_Use, iButton, iPlayerID, 0, 1, 1.0 );
				}
			}
			
			case 2: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
					ExecuteHamB( Ham_Use, iButton, iPlayerID, 0, 1, 1.0 );
				}
			}
			
			case 3: {
				ExecuteHamB( Ham_Use, iButton, iPlayerID, 0, 1, 1.0 );
			}
		}
	}
}

public Ham_TraceAttack_Player_Post( iVictim, iAttacker, Float:fDamage, Float:fDirection[ 3 ], iPointer, iDamageBits ) {
	if( is_user( iAttacker ) ) {
		if( bool:( get_tr2( iPointer, TR_iHitgroup ) == 1 /* HITGROUP_HEAD = 1 */ ) ) {
			SetBit( g_bitIsHeadShot[ iAttacker ], iVictim );
		} else {
			ClearBit( g_bitIsHeadShot[ iAttacker ], iVictim );
		}
	}
}

public Ham_AddPlayerItem_Player_Pre( iPlayerID, iEnt ) {
	if( !is_user( iPlayerID ) && CheckBit( g_bitIsConnected, iPlayerID ) ) {
		return HAM_IGNORED;
	}
	
	static strWeaponName[ 32 ];
	pev( iEnt, pev_classname, strWeaponName, 31 );
	
	if( equal( strWeaponName, "weapon_knife" ) ) {
		return HAM_IGNORED;
	}
	
	static CsTeams:iTeam;
	iTeam = cs_get_user_team( iPlayerID );
	
	if( g_bDayInProgress ) {
		switch( g_iCurrentDay ) {
			case DAY_COWBOY: {
				if( iTeam == CS_TEAM_CT && !equal( strWeaponName, "weapon_deagle" ) ||
				iTeam == CS_TEAM_T && !equal( strWeaponName, "weapon_elite" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_HULK: {
				if( iTeam == CS_TEAM_T ) {
					return HAM_SUPERCEDE;
				} else if( iTeam == CS_TEAM_CT && 
				!equal( strWeaponName, "weapon_fiveseven" ) && 
				!equal( strWeaponName, "weapon_p90" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_PRESIDENT: {
				if( iPlayerID == g_iPresident && 
				!equal( strWeaponName, "weapon_usp" ) &&
				!equal( strWeaponName, "weapon_hegrenade" ) &&
				!equal( strWeaponName, "weapon_flashbang" ) &&
				!equal( strWeaponName, "weapon_smokegrenade" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_SHARK: {
				if( !task_exists( TASK_MENU_SHARK ) &&
				( ( iTeam == CS_TEAM_CT && g_iTypeShark == REGULAR ) ||
				( iTeam == CS_TEAM_T && g_iTypeShark == REVERSED ) ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_ZOMBIE: {
				if( !task_exists( TASK_MENU_ZOMBIE ) &&
				( ( iTeam == CS_TEAM_CT && g_iTypeZombie == REVERSED ) ||
				( iTeam == CS_TEAM_T && g_iTypeZombie == REGULAR ) ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_NIGHTCRAWLER: {
				if( !task_exists( TASK_MENU_NC ) &&
				( ( iTeam == CS_TEAM_CT && g_iTypeNightCrawler == REGULAR ) ||
				( iTeam == CS_TEAM_T && g_iTypeNightCrawler == REVERSED ) ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_SPACE: {
				if( iTeam == CS_TEAM_CT && !equal( strWeaponName, "weapon_awp" ) ||
				iTeam == CS_TEAM_T && !equal( strWeaponName, "weapon_scout" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_USP_NINJA: {
				if( !equal( strWeaponName, "weapon_usp" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_JUDGEMENT: {
				if( iTeam == CS_TEAM_CT ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_SAMURAI, DAY_KNIFE: {
				return HAM_SUPERCEDE;
			}
			
			case DAY_NADEWAR: {
				if( iTeam == CS_TEAM_T && !task_exists( TASK_NADEWAR_GIVEGRENADE ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_LMS: {
				if( iTeam == CS_TEAM_T  &&
				!equal( strWeaponName, g_strLMSWeaponOrder[ g_iLMSCurrentWeapon ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_MARIO: {
				if( iTeam == CS_TEAM_T ) {
					return HAM_SUPERCEDE;
				}
			}
		}
	}
	
	if( g_bLRInProgress ) {
		switch( g_iCurrentLR ) {
			case LR_KNIFE: {
				return HAM_SUPERCEDE;
			}
			
			case LR_WEAPONTOSS: {
				if( !equal( strWeaponName, g_strWTWeapons[ g_iChosenWT ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_S4S: {
				if( !equal( strWeaponName, g_strS4SWeapons[ g_iChosenWE ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_GRENADETOSS: {
				if( !equal( strWeaponName, "weapon_smokegrenade" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_HOTPOTATO: {
				if( g_bHotPotatoStarted ) {
					if( !equal( strWeaponName, "weapon_scout" ) ) {
						return HAM_SUPERCEDE;
					} else {
						g_iLastPickup = iPlayerID;
					}
				}
			}
			
			case LR_DUEL: {
				if( !equal( strWeaponName, g_strDuelWeapons[ g_iChosenWD ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_GLOCKER: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_T && !equal( strWeaponName, "weapon_glock18" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_DEAGLE_MANIAC: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_T && !equal( strWeaponName, "weapon_deagle" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_KAMIKAZE: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_T && !equal( strWeaponName, "weapon_m249" ) ) {
					return HAM_SUPERCEDE;
				}
			}
		}
	}
	
	return HAM_IGNORED;
}

public Ham_ResetMaxSpeed_Player_Post( iPlayerID ) {
	if( g_bHulkSmash && CheckBit( g_bitIsAlive, iPlayerID ) && is_user( iPlayerID ) && cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
		set_pev( iPlayerID, pev_maxspeed, 1.0 );
	}
}

public Ham_Think_Grenade_Pre( iEnt ) {
	if( g_bLRInProgress && g_iCurrentLR == LR_GRENADETOSS || 
	g_bDayInProgress && g_iCurrentDay == DAY_NADEWAR ) {
		if( pev_valid( iEnt ) ) {
			static iPlayerID;
			iPlayerID = pev( iEnt, pev_owner );
			
			if( !g_bDayInProgress ) {
				if( iPlayerID != g_iLastRequest[ PLAYER_OFFICER ] && iPlayerID != g_iLastRequest[ PLAYER_PRISONER ] ) {
					return HAM_IGNORED;
				}	
			}
			
			static strGrenadeModel[ 32 ];
			pev( iEnt, pev_model, strGrenadeModel, 31 );
			
			if( g_bDayInProgress ) {
				if( !equal( strGrenadeModel, "models/w_hegrenade.mdl" ) ) {
					return HAM_IGNORED;
				}
			} else {
				if( !equal( strGrenadeModel, "models/w_smokegrenade.mdl" ) ) {
					return HAM_IGNORED;
				}
			}
			
			set_pev( iEnt, pev_renderfx, kRenderFxGlowShell );
			set_pev( iEnt, pev_rendermode, kRenderNormal );
			set_pev( iEnt, pev_renderamt, 16.0 );
			
			switch( cs_get_user_team( iPlayerID ) ) {
				case CS_TEAM_CT: {
					set_pev( iEnt, pev_rendercolor, { 0.0, 0.0, 255.0 } );
					
					SetBeamFollow( iEnt, BEAM_LIFE, BEAM_WIDTH, 0, 0, 255, BEAM_BRIGHT );
				}
				
				case CS_TEAM_T: {
					set_pev( iEnt, pev_rendercolor, { 255.0, 0.0, 0.0 } );
					
					SetBeamFollow( iEnt, BEAM_LIFE, BEAM_WIDTH, 255, 0, 0, BEAM_BRIGHT );
				}
			}
			
			if( g_iCurrentDay == DAY_NADEWAR ) {
				return HAM_IGNORED;
			} else {
				return HAM_SUPERCEDE;
			}
		}
	}
	
	return HAM_IGNORED;
}

public Ham_PrimaryAttack_Weapon_Post( iEnt ) {
	if( !g_bLRInProgress || g_iCurrentLR != LR_S4S ) {
		return HAM_IGNORED;
	}
	
	new iPlayerID = pev( iEnt, pev_owner );
	new iOpponentEnt;
	
	if( cs_get_weapon_ammo( iEnt ) == 0 ) {
		if( iPlayerID == g_iLastRequest[ PLAYER_PRISONER ] ) {
			iOpponentEnt = find_ent_by_owner( -1, g_strS4SWeapons[ g_iChosenWE ], g_iLastRequest[ PLAYER_OFFICER ] );
			
			if( pev_valid( iOpponentEnt ) ) {
				cs_set_weapon_ammo( iOpponentEnt, 1 );
			}
		} else if( iPlayerID == g_iLastRequest[ PLAYER_OFFICER ] ) {
			iOpponentEnt = find_ent_by_owner( -1, g_strS4SWeapons[ g_iChosenWE ], g_iLastRequest[ PLAYER_PRISONER ] );
			
			if( pev_valid( iOpponentEnt ) ) {
				cs_set_weapon_ammo( iOpponentEnt, 1 );
			}
		}
	}
	
	return HAM_IGNORED;
}

public Ham_TakeHealth_Player_Pre( iPlayerID, Float:fHealth, iDamageBits ) {
	switch( g_iCurrentDay ) {
		case DAY_NIGHTCRAWLER, DAY_ZOMBIE, DAY_USP_NINJA, DAY_NADEWAR,
		DAY_HULK, DAY_SPACE, DAY_COWBOY, DAY_SHARK, DAY_SAMURAI, DAY_KNIFE,
		DAY_HNS, DAY_MARIO, DAY_PRESIDENT, DAY_LMS: {
			return HAM_SUPERCEDE;
		}
		
		case DAY_CAGE, DAY_RIOT, DAY_JUDGEMENT: {
			return HAM_IGNORED;
		}
	}
	
	if( g_bLRInProgress && ( g_iLastRequest[ PLAYER_OFFICER ] == iPlayerID || g_iLastRequest[ PLAYER_PRISONER ] == iPlayerID ) ) {
		return HAM_SUPERCEDE;
	} else if( g_iCurrentLR == LR_KAMIKAZE || g_iCurrentLR == LR_DEAGLE_MANIAC || g_iCurrentLR == LR_GLOCKER ) {
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public Ham_Use_Button_TankMortar( iEnt, iCaller, iActivator, iUseType, Float:fValue ) {
	new strModelName[ 4 ];
	pev( iEnt, pev_model, strModelName, 3 );
	
	if( strModelName[ 0 ] == '*' && ( strModelName[ 1 ] == '6' || strModelName[ 1 ] == '8' )
	&& ( strModelName[ 2 ] == '0' || strModelName[ 2 ] == '1' || strModelName[ 2 ] == '4' ) ) {
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public Ham_Spawn_Armoury_Entity_Post( iEntity ) {
	engfunc( EngFunc_DropToFloor, iEntity );
	set_pev( iEntity, pev_movetype, MOVETYPE_NONE );
}

/* Menus */
StartDayVote( ) {
	g_iTimeLeft = clamp( get_pcvar_num( g_pcvarVotePrimary ), VOTE_PRIM_MIN, VOTE_PRIM_MAX );
	
	/*
		Check if minimum number of Prisoners and Guards is satisfied.
	*/
	new bool:bBlockVote = false;
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	new iMinimumPrisoners = get_pcvar_num( g_pcvarVoteMinPrisoners );
	
	if( iNum < iMinimumPrisoners ) {
		client_print_color( 0, print_team_red, "^4%s^1 There must be at least ^4%i ^3Prisoners^1 to start the vote.", g_strPluginPrefix, iMinimumPrisoners );
		
		bBlockVote = true;
	}
	
	get_players( iPlayers, iNum, "ae", "CT" );
	new iMinimGuards = get_pcvar_num( g_pcvarVoteMinGuards );
	
	if( iNum < iMinimGuards ) {
		client_print_color( 0, print_team_blue, "^4%s^1 There must be at least ^4%i ^3Guards^1 to start the vote.", g_strPluginPrefix, iMinimGuards );
		
		bBlockVote = true;
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			ShowWeaponMenu( iPlayers[ iLoop ] );
		}
	}
	
	/*
		Check if it's the opposite team's chance to vote.
	*/
	if( !bBlockVote ) {
		if( g_iVotePlayers == 1 || g_iVotePlayers == 2 ) {
			new iDaysToVote = clamp( get_pcvar_num( g_pcvarVoteOpposite ), 0, 10 );
			
			if( iDaysToVote && ( g_iCountDays % iDaysToVote ) == 0 ) {
				g_bOppositeVote = true;
				
				client_print_color( 0, ( g_iVotePlayers == 1 ) ? print_team_blue : print_team_red, "^4%s ^3%s ^1are able to vote this round.", g_strPluginPrefix, ( g_iVotePlayers == 1 ) ? "Guards" : "Prisoners" );
			} else {
				g_bOppositeVote = false;
			}
		}
	}
	
	/*
		All previous checks have passed, and now it's time to show the vote.
	*/
	if( !bBlockVote ) {
		/*
			Randomize each player's starting page
		*/
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "a" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			g_iCurrentPage[ iPlayers[ iLoop ] ] = random( 2 );
		}
		
		ShowDayMenu( );
		set_task( 1.0, "Task_Menu_DayMenu", TASK_MENU_DAY, _, _, "a", g_iTimeLeft );
	} else {
		client_print_color( 0, print_team_blue, "^4%s^1 Day has been set to ^4Cage Day^1.", g_strPluginPrefix );
		
		g_iCurrentDay = DAY_CAGE;
		StartDay( );
	}
}

ShowDayMenu( ) {
	if( g_iTimeLeft < 1 ) {
		return;
	}
	
	static strMenu[ 2048 ];
	static iLen, iLoop, iInnerLoop;
	
	static iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		iLen = formatex( strMenu, 2047, "\rPowered by %s!", g_strPluginSponsor );
		
		switch( g_iVotePlayers ) {
			case 1: iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\y[%s] Choose A Day: [%i]^n", g_bOppositeVote ? "CT" : "T", g_iTimeLeft );
			case 2:	iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\y[%s] Choose A Day: [%i]^n", g_bOppositeVote ? "T" : "CT", g_iTimeLeft );
			case 3: iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\y[ALL] Choose A Day: [%i]^n", g_iTimeLeft );
		}
		
		switch( g_iCurrentPage[ iTempID ] ) {
			case 0: {
				for( iInnerLoop = 0; iInnerLoop < PAGE_OPTIONS; iInnerLoop++ ) {
					if( g_iDaysLeft[ iInnerLoop ] > 0 ) {
						iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\d%i. \d%s [Days Left: %i]", iInnerLoop + 1, g_strOptionsDayMenu[ iInnerLoop ], g_iDaysLeft[ iInnerLoop ] );
					} else {
						iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iInnerLoop + 1, g_strOptionsDayMenu[ iInnerLoop ], g_iVotesDayMenu[ iInnerLoop ] );
					}
				}
				
				iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n^n\d8. \dBack" );
				iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\y9. \wNext \y[\rVotes: %i\y]", g_iPageVotes[ 1 ] + g_iPageVotes[ 2 ] );
				formatex( strMenu[ iLen ], 2047 - iLen, "^n\rPage 1/3" );
			}
			
			case 1: {
				for( iInnerLoop = PAGE_OPTIONS; iInnerLoop < 2 * PAGE_OPTIONS; iInnerLoop++ ) {
					if( g_iDaysLeft[ iInnerLoop ] > 0 ) {
						iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\d%i. \d%s [Days Left: %i]", iInnerLoop - ( PAGE_OPTIONS - 1 ), g_strOptionsDayMenu[ iInnerLoop ], g_iDaysLeft[ iInnerLoop ] );
					} else {
						iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iInnerLoop - ( PAGE_OPTIONS - 1 ), g_strOptionsDayMenu[ iInnerLoop ], g_iVotesDayMenu[ iInnerLoop ] );
					}
				}
				
				iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n^n\y8. \wBack \y[\rVotes: %i\y]", g_iPageVotes[ 0 ] );
				iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\y9. \wNext \y[\rVotes: %i\y]", g_iPageVotes[ 2 ] );
				formatex( strMenu[ iLen ], 2047 - iLen, "^n\rPage 2/3" );
			}
			
			case 2: {
				for( iInnerLoop = 2 * PAGE_OPTIONS; iInnerLoop < /* ( 3 * PAGE_OPTIONS )*/ MAX_DAYS; iInnerLoop++ ) {
					if( g_iDaysLeft[ iInnerLoop ] > 0 ) {
						iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\d%i. \d%s [Days Left: %i]", iInnerLoop - ( 2 * PAGE_OPTIONS - 1 ), g_strOptionsDayMenu[ iInnerLoop ], g_iDaysLeft[ iInnerLoop ] );
					} else {
						iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iInnerLoop - ( 2 * PAGE_OPTIONS - 1 ), g_strOptionsDayMenu[ iInnerLoop ], g_iVotesDayMenu[ iInnerLoop ] );
					}
				}
				
				iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n^n\y8. \wBack \y[\rVotes: %i\y]", g_iPageVotes[ 0 ] + g_iPageVotes[ 1 ] );
				iLen += formatex( strMenu[ iLen ], 2047 - iLen, "^n\d9. \dNext" );
				formatex( strMenu[ iLen ], 2047 - iLen, "^n\rPage 3/3" );
			}
		}
		
		show_menu( iTempID, 1023, strMenu, -1, "Day Menu" );
	}
}

public Handle_DayMenu( iPlayerID, iKey ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		ShowDayMenu( );
		
		return;
	}
	
	static CsTeams:iTeam;
	new bool:bBlockVote = false;
	iTeam = cs_get_user_team( iPlayerID );
	
	switch( g_iCurrentPage[ iPlayerID ] ) {
		case 0: {
			if( ( iKey == 1 || iKey == 0 ) && g_iVoteDayMenu != 1 ) {
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You cannot vote for that day. Please choose another.", g_strPluginPrefix );
				ShowDayMenu( );
				
				return;
			}
			
			switch( iKey ) {
				case 7: ShowDayMenu( );
				case 8: g_iCurrentPage[ iPlayerID ]++;
				case 9: ShowDayMenu( );
				default: {
					if( CheckBit( g_bitHasVoted, iPlayerID ) ) {
						client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have already voted.", g_strPluginPrefix );
					} else {
						switch( g_iVotePlayers ) {
							case 1: {
								if( g_bOppositeVote && iTeam == CS_TEAM_T ||
								!g_bOppositeVote && iTeam == CS_TEAM_CT ) {
									bBlockVote = true;
									
									client_print_color( iPlayerID, g_bOppositeVote ? print_team_blue : print_team_red, "^4%s^1 Today it's the ^3%s'^1 turn to vote.", g_strPluginPrefix, g_bOppositeVote ? "Guards" : "Prisoners" );
								}
							}
							
							case 2: {
								if( g_bOppositeVote && iTeam == CS_TEAM_CT ||
								!g_bOppositeVote && iTeam == CS_TEAM_T ) {
									bBlockVote = true;
									
									client_print_color( iPlayerID, g_bOppositeVote ? print_team_red : print_team_blue, "^4%s^1 Today it's the ^3%s'^1 turn to vote.", g_strPluginPrefix, g_bOppositeVote ? "Prisoners" : "Guards" );
								}
							}
						}
						
						if( !bBlockVote ) {
							if( g_iDaysLeft[ iKey ] > 0 ) {
								client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to wait ^4%i more days^1 to vote to vote for that day.", g_strPluginPrefix, g_iDaysLeft[ iKey ] );
							} else {
								if( g_iDisplayName ) {
									new strPlayerName[ 32 ];
									get_user_name( iPlayerID, strPlayerName, 31 );
									
									client_print_color( 0, iPlayerID, "^4%s ^3%s ^1voted for ^4%s^1.", g_strPluginPrefix, strPlayerName, g_strOptionsDayMenu[ iKey ] );
								}
								
								SetBit( g_bitHasVoted, iPlayerID );
								
								if( g_iVotePlayers == 3 && cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
									g_iVotesDayMenu[ iKey ] += 2;
									g_iPageVotes[ 0 ] += 2;
								} else {
									g_iVotesDayMenu[ iKey ]++;
									g_iPageVotes[ 0 ]++;
								}
							}
						}
					}
				}
			}
		}
		
		case 1: {
			switch( iKey ) {
				case 7: g_iCurrentPage[ iPlayerID ]--;
				case 8: g_iCurrentPage[ iPlayerID ]++;
				case 9: ShowDayMenu( );
				default: {
					if( CheckBit( g_bitHasVoted, iPlayerID ) ) {
						client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have already voted.", g_strPluginPrefix );
					} else {
						switch( g_iVotePlayers ) {
							case 1: {
								if( g_bOppositeVote && iTeam == CS_TEAM_T ||
								!g_bOppositeVote && iTeam == CS_TEAM_CT ) {
									bBlockVote = true;
									
									client_print_color( iPlayerID, g_bOppositeVote ? print_team_blue : print_team_red, "^4%s^1 Today it's the ^3%s'^1 turn to vote.", g_strPluginPrefix, g_bOppositeVote ? "Guards" : "Prisoners" );
								}
							}
							
							case 2: {
								if( g_bOppositeVote && iTeam == CS_TEAM_CT ||
								!g_bOppositeVote && iTeam == CS_TEAM_T ) {
									bBlockVote = true;
									
									client_print_color( iPlayerID, g_bOppositeVote ? print_team_red : print_team_blue, "^4%s^1 Today it's the ^3%s'^1 turn to vote.", g_strPluginPrefix, g_bOppositeVote ? "Prisoners" : "Guards" );
								}
							}
						}
						
						if( !bBlockVote ) {
							if( g_iDaysLeft[ PAGE_OPTIONS + iKey ] > 0 ) {
								client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to wait ^4%i more days^1 to vote to vote for that day.", g_strPluginPrefix, g_iDaysLeft[ iKey ] );
							} else {
								if( g_iDisplayName ) {
									new strPlayerName[ 32 ];
									get_user_name( iPlayerID, strPlayerName, 31 );
									
									client_print_color( 0, iPlayerID, "^4%s ^3%s ^1voted for ^4%s^1.", g_strPluginPrefix, strPlayerName, g_strOptionsDayMenu[ PAGE_OPTIONS + iKey ] );
								}
								
								SetBit( g_bitHasVoted, iPlayerID );
								
								if( g_iVotePlayers == 3 && cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
									g_iVotesDayMenu[ PAGE_OPTIONS + iKey ] += 2;
									g_iPageVotes[ 1 ] += 2;
								} else {
									g_iVotesDayMenu[ PAGE_OPTIONS + iKey ]++;
									g_iPageVotes[ 1 ]++;
								}
							}
						}
					}
				}
			}
		}
		
		case 2: {
			switch( iKey ) {
				case 5: ShowDayMenu( );
				case 6: ShowDayMenu( );
				case 7: g_iCurrentPage[ iPlayerID ]--;
				case 8: ShowDayMenu( );
				case 9: ShowDayMenu( );
				default: {
					if( CheckBit( g_bitHasVoted, iPlayerID ) ) {
						client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have already voted.", g_strPluginPrefix );
					} else {
						switch( g_iVotePlayers ) {
							case 1: {
								if( g_bOppositeVote && iTeam == CS_TEAM_T ||
								!g_bOppositeVote && iTeam == CS_TEAM_CT ) {
									bBlockVote = true;
									
									client_print_color( iPlayerID, g_bOppositeVote ? print_team_blue : print_team_red, "^4%s^1 Today it's the ^3%s'^1 turn to vote.", g_strPluginPrefix, g_bOppositeVote ? "Guards" : "Prisoners" );
								}
							}
							
							case 2: {
								if( g_bOppositeVote && iTeam == CS_TEAM_CT ||
								!g_bOppositeVote && iTeam == CS_TEAM_T ) {
									bBlockVote = true;
									
									client_print_color( iPlayerID, g_bOppositeVote ? print_team_red : print_team_blue, "^4%s^1 Today it's the ^3%s'^1 turn to vote.", g_strPluginPrefix, g_bOppositeVote ? "Prisoners" : "Guards" );
								}
							}
						}
						
						if( !bBlockVote ) {
							if( g_iDaysLeft[ 2 * PAGE_OPTIONS + iKey ] > 0 ) {
								client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to wait ^4%i more days^1 to vote to vote for that day.", g_strPluginPrefix, g_iDaysLeft[ iKey ] );
							} else {
								if( g_iDisplayName ) {
									new strPlayerName[ 32 ];
									get_user_name( iPlayerID, strPlayerName, 31 );
									
									client_print_color( 0, iPlayerID, "^4%s ^3%s ^1voted for ^4%s^1.", g_strPluginPrefix, strPlayerName, g_strOptionsDayMenu[ 2 * PAGE_OPTIONS + iKey ] );
								}
								
								SetBit( g_bitHasVoted, iPlayerID );
								
								if( g_iVotePlayers == 3 && cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
									g_iVotesDayMenu[ 2 *PAGE_OPTIONS + iKey ] += 2;
									g_iPageVotes[ 2 ] += 2;
								} else {
									g_iVotesDayMenu[ 2 *PAGE_OPTIONS + iKey ]++;
									g_iPageVotes[ 2 ]++;
								}
							}
						}
					}
				}
			}
		}
	}
	
	ShowDayMenu( );
	
	return;
}
 
EndDayMenu( ) {
	show_menu( 0, 0, "^n", 1 );
	
	g_iCurrentDay = GetHighest( g_iVotesDayMenu, MAX_DAYS );
	
	if( g_iCurrentDay < 0 ) {
		client_print_color( 0, print_team_red, "^4%s^3 Voting failed. ^4FreeDay ^1loaded.", g_strPluginPrefix );
		g_iCurrentDay = DAY_FREE;
	} else {
		switch( g_iVotePlayers ) {
			case 1: client_print_color( 0, g_bOppositeVote ? print_team_blue : print_team_red, "^4%s^1 The ^3%s^1 voted for a ^4%s^1.", g_strPluginPrefix, g_bOppositeVote ? "Guards" : "Prisoners", g_strOptionsDayMenu[ g_iCurrentDay ] );
			case 2: client_print_color( 0, g_bOppositeVote ? print_team_red : print_team_blue, "^4%s^1 The ^3s ^1voted for a ^4%s^1.", g_strPluginPrefix, g_bOppositeVote ? "Prisoners" : "Guards", g_strOptionsDayMenu[ g_iCurrentDay ] );
			case 3: client_print_color( 0, print_team_red, "^4%s^1 Players voted for a ^4%s^1.", g_strPluginPrefix, g_strOptionsDayMenu[ g_iCurrentDay ] );
		}
	}
	
	ResetDayMenu( );
	StartDay( );
}

ResetDayMenu( ) {
	g_bitHasVoted = 0;
	new iLoop;
	
	for( iLoop = 0; iLoop < MAX_DAYS; iLoop++ ) {
		g_iVotesDayMenu[ iLoop ] = 0;
	}
	
	for( iLoop = 0; iLoop <= MAX_PLAYERS; iLoop++ ) {
		g_iCurrentPage[ iLoop ] = 0;
	}
	
	for( iLoop = 0; iLoop < 3; iLoop++ ) {
		g_iPageVotes[ iLoop ] = 0;
	}
}

StartFreeDayVote( ) {
	g_iTimeLeft = clamp( get_pcvar_num( g_pcvarVoteSecondary ), VOTE_SEC_MIN, VOTE_SEC_MAX );
	
	ShowFreeDayMenu( );
	set_task( 1.0, "Task_Menu_FreeDay", TASK_MENU_FREE, _, _, "a", g_iTimeLeft );
}

ShowFreeDayMenu( ) {
	if( g_iTimeLeft < 1 ) {
		return;
	}
	
	static strMenu[ 1024 ];
	static iLen, iLoop, iKeys = MENU_KEY_1 | MENU_KEY_2;
	
	static strOptionsFreeDay[ MAX_OPTIONS_FREEDAY ][ ] = {
		"Unrestricted Freeday",
		"Restricted Freeday"
	};
	
	iLen = formatex( strMenu, 1023, "\rPowered by %s!", g_strPluginSponsor );
	
	switch( g_iVotePlayers ) {
		case 1: iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[%s] Choose FreeDay Type: [%i]^n", g_bOppositeVote ? "CT" : "T", g_iTimeLeft );
		case 2:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[%s] Choose FreeDay Type: [%i]^n", g_bOppositeVote ? "T" : "CT", g_iTimeLeft );
		case 3:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[ALL] Choose FreeDay Type: [%i]^n", g_iTimeLeft );
	}
	
	for( iLoop = 0; iLoop < MAX_OPTIONS_FREEDAY; iLoop++ ) {
		iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iLoop + 1, strOptionsFreeDay[ iLoop ], g_iVotesFreeDay[ iLoop ] );
	}
	
	static iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "a" );
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		show_menu( iPlayers[ iLoop ], iKeys, strMenu, -1, "Freeday Menu" );
	}
}

public Handle_FreedayMenu( iPlayerID, iKey ) {
	if( !CheckBit( g_bitHasVoted, iPlayerID ) ) {
		switch( g_iVotePlayers ) {
			case 1: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: if( !g_bOppositeVote ) return;
					case CS_TEAM_T:  if( g_bOppositeVote ) return;
				}
			}
			
			case 2: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: if( g_bOppositeVote ) return;
					case CS_TEAM_T:  if( !g_bOppositeVote ) return;
				}
			}
		}
		
		if( g_iVotePlayers == 3 && cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
			SetBit( g_bitHasVoted, iPlayerID );
			g_iVotesFreeDay[ iKey ] += 2;
		} else {
			SetBit( g_bitHasVoted, iPlayerID );
			g_iVotesFreeDay[ iKey ]++;
		}
	} else {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have already voted.", g_strPluginPrefix );
	}
	
	ShowFreeDayMenu( );
}

EndFreeDayMenu( ) {
	show_menu( 0, 0, "^n", 1 );
	
	g_iTypeFreeDay = GetHighest( g_iVotesFreeDay, MAX_OPTIONS_FREEDAY );
	
	if( g_iTypeFreeDay < 0 ) {
		g_iTypeFreeDay = UNRESTRICTED;
	}
	
	switch( g_iVotePlayers ) {
		case 1: client_print_color( 0, g_bOppositeVote ? print_team_blue : print_team_red, "^4%s^1 The ^3%s^1 voted for a^4%s Free Day^1.", g_strPluginPrefix, g_bOppositeVote ? "Guards" : "Prisoners", g_iTypeFreeDay == UNRESTRICTED ? "n UnRestricted" : " Restricted" );
		case 2: client_print_color( 0, g_bOppositeVote ? print_team_red : print_team_blue, "^4%s^1 The ^3%s^1 voted for a^4%s Free Day^1.", g_strPluginPrefix, g_bOppositeVote ? "Prisoners" : "Guards", g_iTypeFreeDay == UNRESTRICTED ? "n UnRestricted" : " Restricted" );
		case 3: client_print_color( 0, print_team_blue, "^4%s^1 Players voted for a^4%s Free Day^1.", g_strPluginPrefix, g_iTypeFreeDay == UNRESTRICTED ? "n UnRestricted" : " Restricted" );
	}
	
	ResetFreeDayMenu( );
	StartFreeDay( );
}

ResetFreeDayMenu( ) {
	g_bitHasVoted = 0;
	
	for( new iLoop = 0; iLoop < MAX_OPTIONS_FREEDAY; iLoop++ ) {
		g_iVotesFreeDay[ iLoop ] = 0;
	}
}

StartNightCrawlerVote( ) {
	g_iTimeLeft = clamp( get_pcvar_num( g_pcvarVoteSecondary ), VOTE_SEC_MIN, VOTE_SEC_MAX );
	
	ShowNightCrawlerMenu( );
	set_task( 1.0, "Task_Menu_NC", TASK_MENU_NC, _, _, "a", g_iTimeLeft );
}

ShowNightCrawlerMenu( ) {
	if( g_iTimeLeft < 1 ) {
		return;
	}
	
	static strMenu[ 1024 ];
	static iLen, iLoop, iKeys = MENU_KEY_1 | MENU_KEY_2;
	
	static strOptionsNightCrawlerDay[ MAX_OPTIONS ][ ] = {
		"Regular NightCrawler Day [Officers = NightCrawlers]",
		"Reverse NightCrawler Day [Prisoners = NightCrawlers]"
	};
	
	iLen = formatex( strMenu, 1023, "\rPowered by %s!", g_strPluginSponsor );
	
	switch( g_iVotePlayers ) {
		case 1:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[%s] Choose NightCrawler Type: [%i]^n", g_bOppositeVote ? "CT" : "T", g_iTimeLeft );
		case 2:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[%s] Choose NightCrawler Type: [%i]^n", g_bOppositeVote ? "T" : "CT", g_iTimeLeft );
		case 3:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[ALL] Choose NightCrawler Type: [%i]^n", g_iTimeLeft );
	}
	
	for( iLoop = 0; iLoop < MAX_OPTIONS; iLoop++ ) {
		iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iLoop + 1, strOptionsNightCrawlerDay[ iLoop ], g_iVotesNightCrawlerDay[ iLoop ] );
	}
	
	static iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		show_menu( iTempID, 0, "^n", 1 );
		show_menu( iTempID, iKeys, strMenu, -1, "NightCrawler Menu" );
	}
}

public Handle_NightCrawlerMenu( iPlayerID, iKey ) {
	if( !CheckBit( g_bitHasVoted, iPlayerID ) ) {
		switch( g_iVotePlayers ) {
			case 1: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: if( !g_bOppositeVote ) return;
					case CS_TEAM_T:  if( g_bOppositeVote ) return;
				}
			}
			
			case 2: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: if( g_bOppositeVote ) return;
					case CS_TEAM_T:  if( !g_bOppositeVote ) return;
				}
			}
			
			case 3: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: {
						SetBit( g_bitHasVoted, iPlayerID );
						g_iVotesNightCrawlerDay[ iKey ] += 2;
					}
					
					case CS_TEAM_T: {
						SetBit( g_bitHasVoted, iPlayerID );
						g_iVotesNightCrawlerDay[ iKey ]++;
					}
				}
			}
		}
	} else {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have already voted.", g_strPluginPrefix );
	}
	
	ShowNightCrawlerMenu( );
}

EndNightCrawlerMenu( ) {
	show_menu( 0, 0, "^n", 1 );
	g_iTypeNightCrawler = GetHighest( g_iVotesNightCrawlerDay, MAX_OPTIONS );
	
	if( g_iTypeNightCrawler < 0 ) {
		g_iTypeNightCrawler = REGULAR;
	}
	
	switch( g_iVotePlayers ) {
		case 1:	client_print_color( 0, g_bOppositeVote ? print_team_blue : print_team_red, "^4%s^1 The ^3%s^1 voted for a ^4%s NightCrawler Day^1.", g_strPluginPrefix, g_bOppositeVote ? "Guards" : "Prisoners", g_iTypeNightCrawler == REGULAR ? "Regular" : "Reverse" );
		case 2:	client_print_color( 0, g_bOppositeVote ? print_team_red : print_team_blue, "^4%s^1 The ^3%s^1 voted for a ^4%s NightCrawler Day^1.", g_strPluginPrefix, g_bOppositeVote ? "Prisoners" : "Guards", g_iTypeNightCrawler == REGULAR ? "Regular" : "Reverse" );
		case 3:	client_print_color( 0, print_team_blue, "^4%s^1 Players voted for a ^4%s NightCrawler Day^1.", g_strPluginPrefix, g_iTypeNightCrawler == REGULAR ? "Regular" : "Reverse" );
	}
	
	ResetNightCrawlerMenu( );
	StartNightCrawlerDay( );
}

ResetNightCrawlerMenu( ) {
	g_bitHasVoted = 0;
	
	for( new iLoop = 0; iLoop < MAX_OPTIONS; iLoop++ ) {
		g_iVotesNightCrawlerDay[ iLoop ] = 0;
	}
}

StartZombieVote( ) {
	g_iTimeLeft = clamp( get_pcvar_num( g_pcvarVoteSecondary ), VOTE_SEC_MIN, VOTE_SEC_MAX );
	
	ShowZombieMenu( );
	set_task( 1.0, "Task_Menu_Zombie", TASK_MENU_ZOMBIE, _, _, "a", g_iTimeLeft );
}

ShowZombieMenu( ) {
	if( g_iTimeLeft < 1 ) {
		return;
	}
	
	static strMenu[ 1024 ];
	static iLen, iLoop, iKeys = MENU_KEY_1 | MENU_KEY_2;
	
	static strOptionsZombieDay[ MAX_OPTIONS ][ ] = {
		"Regular Zombie Day [Prisoners = Zombies]",
		"Reverse Zombie Day [Officers = Zombies]"
	};
	
	iLen = formatex( strMenu, 1023, "\rPowered by %s!", g_strPluginSponsor );
	
	switch( g_iVotePlayers ) {
		case 1:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[%s] Choose Zombie Type: [%i]^n", g_bOppositeVote ? "CT" : "T", g_iTimeLeft );
		case 2:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[%s] Choose Zombie Type: [%i]^n", g_bOppositeVote ? "T" : "CT", g_iTimeLeft );
		case 3:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[ALL] Choose Zombie Type: [%i]^n", g_iTimeLeft );
	}
	
	for( iLoop = 0; iLoop < MAX_OPTIONS; iLoop++ ) {
		iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iLoop + 1, strOptionsZombieDay[ iLoop ], g_iVotesZombieDay[ iLoop ] );
	}
	
	static iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		show_menu( iTempID, 0, "^n", 1 );
		show_menu( iTempID, iKeys, strMenu, -1, "Zombie Menu" );
	}
}

public Handle_ZombieMenu( iPlayerID, iKey ) {
	if( !CheckBit( g_bitHasVoted, iPlayerID ) ) {
		switch( g_iVotePlayers ) {
			case 1: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: if( !g_bOppositeVote ) return;
					case CS_TEAM_T:  if( g_bOppositeVote ) return;
				}
			}
			
			case 2: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: if( g_bOppositeVote ) return;
					case CS_TEAM_T:  if( !g_bOppositeVote ) return;
				}
			}
			
			case 3: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: {
						SetBit( g_bitHasVoted, iPlayerID );
						g_iVotesZombieDay[ iKey ] += 2;
					}
					
					case CS_TEAM_T: {
						SetBit( g_bitHasVoted, iPlayerID );
						g_iVotesZombieDay[ iKey ]++;
					}
				}
			}
		}
	} else {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have already voted.", g_strPluginPrefix );
	}
	
	ShowZombieMenu( );
}

EndZombieMenu( ) {
	show_menu( 0, 0, "^n", 1 );
	
	g_iTypeZombie = GetHighest( g_iVotesZombieDay, MAX_OPTIONS );
	
	if( g_iTypeZombie < 0 ) {
		g_iTypeZombie = REGULAR;
	}
	
	switch( g_iVotePlayers ) {
		case 1:	client_print_color( 0, g_bOppositeVote ? print_team_blue : print_team_red, "^4%s^1 The ^3%s^1 voted for a ^4%s Zombie Day^1.", g_strPluginPrefix, g_bOppositeVote ? "Guards" : "Prisoners", g_iTypeZombie == REGULAR ? "Regular" : "Reverse" );
		case 2:	client_print_color( 0, g_bOppositeVote ? print_team_red : print_team_blue, "^4%s^1 The ^3%s^1 voted for a ^4%s Zombie Day^1.", g_strPluginPrefix, g_bOppositeVote ? "Prisoners" : "Guards", g_iTypeZombie == REGULAR ? "Regular" : "Reverse" );
		case 3:	client_print_color( 0, print_team_blue, "^4%s^1 Players voted for a ^4%s Zombie Day^1.", g_strPluginPrefix, g_iTypeNightCrawler == REGULAR ? "Regular" : "Reverse" );
	}
	
	ResetZombieMenu( );
	StartZombieDay( );
}

ResetZombieMenu( ) {
	g_bitHasVoted = 0;
	
	for( new iLoop = 0; iLoop < MAX_OPTIONS; iLoop++ ) {
		g_iVotesZombieDay[ iLoop ] = 0;
	}
}

StartSharkVote( ) {
	g_iTimeLeft = clamp( get_pcvar_num( g_pcvarVoteSecondary ), VOTE_SEC_MIN, VOTE_SEC_MAX );
	
	ShowSharkMenu( );
	set_task( 1.0, "Task_Menu_Shark", TASK_MENU_SHARK, _, _, "a", g_iTimeLeft );
}

ShowSharkMenu( ) {
	if( g_iTimeLeft < 1 ) {
		return;
	}
	
	static strMenu[ 1024 ];
	static iLen, iLoop, iKeys = MENU_KEY_1 | MENU_KEY_2;
	
	static strOptionsSharkDay[ MAX_OPTIONS ][ ] = {
		"Regular Shark Day [Officers = Sharks]",
		"Reverse Shark Day [Prisoners = Sharks]"
	};
	
	iLen = formatex( strMenu, 1023, "\rPowered by %s!", g_strPluginSponsor );
	
	switch( g_iVotePlayers ) {
		case 1:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[%s] Choose Shark Type: [%i]^n", g_bOppositeVote ? "CT" : "T", g_iTimeLeft );
		case 2:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[%s] Choose Shark Type: [%i]^n", g_bOppositeVote ? "T" : "CT", g_iTimeLeft );
		case 3:	iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y[ALL] Choose Shark Type: [%i]^n", g_iTimeLeft );
	}
	
	for( iLoop = 0; iLoop < MAX_OPTIONS; iLoop++ ) {
		iLen += formatex( strMenu[ iLen ], 1023 - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iLoop + 1, strOptionsSharkDay[ iLoop ], g_iVotesSharkDay[ iLoop ] );
	}
	
	static iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		show_menu( iTempID, 0, "^n", 1 );
		show_menu( iTempID, iKeys, strMenu, -1, "Shark Menu" );
	}
}

public Handle_SharkMenu( iPlayerID, iKey ) {
	if( !CheckBit( g_bitHasVoted, iPlayerID ) ) {
		switch( g_iVotePlayers ) {
			case 1: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: if( !g_bOppositeVote ) return;
					case CS_TEAM_T:  if( g_bOppositeVote ) return;
				}
			}
			
			case 2: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: if( g_bOppositeVote ) return;
					case CS_TEAM_T:  if( !g_bOppositeVote ) return;
				}
			}
			
			case 3: {
				switch( cs_get_user_team( iPlayerID ) ) {
					case CS_TEAM_CT: {
						SetBit( g_bitHasVoted, iPlayerID );
						g_iVotesSharkDay[ iKey ] += 2;
					}
					
					case CS_TEAM_T: {
						SetBit( g_bitHasVoted, iPlayerID );
						g_iVotesSharkDay[ iKey ]++;
					}
				}
			}
		}
	} else {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have already voted.", g_strPluginPrefix );
	}
	
	ShowSharkMenu( );
}

EndSharkMenu( ) {
	show_menu( 0, 0, "^n", 1 );
	
	g_iTypeShark = GetHighest( g_iVotesSharkDay, MAX_OPTIONS );
	
	if( g_iTypeShark < 0 ) {
		g_iTypeShark = REGULAR;
	}
	
	switch( g_iVotePlayers ) {
		case 1:	client_print_color( 0, g_bOppositeVote ? print_team_blue : print_team_red, "^4%s^1 The ^3%s^1 voted for a ^4%s Shark Day^1.", g_strPluginPrefix, g_bOppositeVote ? "Guards" : "Prisoners", g_iTypeShark == REGULAR ? "Regular" : "Reverse" );
		case 2:	client_print_color( 0, g_bOppositeVote ? print_team_red : print_team_blue, "^4%s^1 The ^3%s^1 voted for a ^4%s Shark Day^1.", g_strPluginPrefix, g_bOppositeVote ? "Prisoners" : "Guards", g_iTypeShark == REGULAR ? "Regular" : "Reverse" );
		case 3:	client_print_color( 0, print_team_blue, "^4%s^1 Players voted for a ^4%s Shark Day^1.", g_strPluginPrefix, g_iTypeNightCrawler == REGULAR ? "Regular" : "Reverse" );
	}
	
	ResetSharkMenu( );
	StartSharkDay( );
}

ResetSharkMenu( ) {
	g_bitHasVoted = 0;
	
	for( new iLoop = 0; iLoop < MAX_OPTIONS; iLoop++ ) {
		g_iVotesSharkDay[ iLoop ] = 0;
	}
}

StartForceDayMenu( iPlayerID ) {
	if( task_exists( TASK_MENU_SHARK ) ||
	task_exists( TASK_MENU_NC ) || 
	task_exists( TASK_MENU_DAY ) ||
	task_exists( TASK_MENU_ZOMBIE ) ||
	task_exists( TASK_MENU_FREE ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You cannot use the menu while another one is being displayed.", g_strPluginPrefix );
	} else {
		ShowForceDayMenu( iPlayerID );
	}
	
	return PLUGIN_HANDLED;
}

ShowForceDayMenu( iPlayerID ) {
	static menuForceDay;
	
	if( !menuForceDay ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose A Day:^n", g_strPluginSponsor );
		
		menuForceDay = menu_create( strMenuTitle, "Handle_ForceDayMenu" );
		
		new strDayNumber[ 8 ];
		
		for( new iLoop = 0; iLoop < MAX_DAYS; iLoop++ ) {
			num_to_str( iLoop, strDayNumber, 7 );
			
			menu_additem( menuForceDay, g_strOptionsDayMenu[ iLoop ], strDayNumber );
		}
		
		menu_setprop( menuForceDay, MPROP_NUMBER_COLOR, "\y" );
		menu_setprop( menuForceDay, MPROP_EXITNAME, "Exit" );
		menu_setprop( menuForceDay, MPROP_BACKNAME, "Back" );
		menu_setprop( menuForceDay, MPROP_NEXTNAME, "Next" );
	}
	
	menu_display( iPlayerID, menuForceDay, 0 );
}

public Handle_ForceDayMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	new strDayNumber[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strDayNumber, 7, _, _, iCallBack );
	
	new iDayNumber = str_to_num( strDayNumber );
	g_iCurrentDay = iDayNumber;
	g_iChosenForceDay = iDayNumber;
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, 31 );
	
	switch( g_iCurrentDay ) {
		case DAY_NIGHTCRAWLER:		ShowNightCrawlerForceMenu( iPlayerID );
		case DAY_ZOMBIE:		ShowZombieForceMenu( iPlayerID );
		case DAY_SHARK:			ShowSharkForceMenu( iPlayerID );
		case DAY_FREE:			ShowFreeDayForceMenu( iPlayerID );
		default: {
			RefundShopItems( );
			
			ResetAll( );
			g_iCurrentDay = iDayNumber;
			StartDay( );
			
			client_print_color( 0, iPlayerID, "^4%s^1 Admin ^3%s^1 started a ^4%s^1.", g_strPluginPrefix, strPlayerName, g_strOptionsDayMenu[ iDayNumber ] );
		}
	}
}

ShowNightCrawlerForceMenu( iPlayerID ) {
	static menuNightCrawlerForceMenu;
	
	if( !menuNightCrawlerForceMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose A Type:^n", g_strPluginSponsor );
		
		menuNightCrawlerForceMenu = menu_create( strMenuTitle, "Handle_ExtraVoteForceMenu" );
		
		new strOptionsNightCrawlerDay[ MAX_OPTIONS ][ ] = {
			"Regular NightCrawler Day [Officers = NightCrawlers]",
			"Reverse NightCrawler Day [Prisoners = NightCrawlers]"
		};
		
		for( new iLoop = 0; iLoop < MAX_OPTIONS; iLoop++ ) {
			menu_additem( menuNightCrawlerForceMenu, strOptionsNightCrawlerDay[ iLoop ] );
		}
		
		menu_setprop( menuNightCrawlerForceMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuNightCrawlerForceMenu, 0 );
}

ShowZombieForceMenu( iPlayerID ) {
	static menuZombieForceMenu;
	
	if( !menuZombieForceMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose A Type:^n", g_strPluginSponsor );
		
		menuZombieForceMenu = menu_create( strMenuTitle, "Handle_ExtraVoteForceMenu" );
		
		new strOptionsZombieDay[ MAX_OPTIONS ][ ] = {
			"Regular Zombie Day [Prisoners = Zombies]",
			"Reverse Zombie Day [Officers = Zombies]"
		};
		
		for( new iLoop = 0; iLoop < MAX_OPTIONS; iLoop++ ) {
			menu_additem( menuZombieForceMenu, strOptionsZombieDay[ iLoop ] );
		}
		
		menu_setprop( menuZombieForceMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuZombieForceMenu, 0 );
}

ShowSharkForceMenu( iPlayerID ) {
	static menuSharkForceMenu;
	
	if( !menuSharkForceMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose A Type:^n", g_strPluginSponsor );
		
		menuSharkForceMenu = menu_create( strMenuTitle, "Handle_ExtraVoteForceMenu" );
		
		new strOptionsSharkDay[ MAX_OPTIONS ][ ] = {
			"Regular Shark Day [Officers = Sharks]",
			"Reverse Shark Day [Prisoners = Sharks]"
		};
		
		for( new iLoop = 0; iLoop < MAX_OPTIONS; iLoop++ ) {
			menu_additem( menuSharkForceMenu, strOptionsSharkDay[ iLoop ] );
		}
		
		menu_setprop( menuSharkForceMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuSharkForceMenu, 0 );
}

ShowFreeDayForceMenu( iPlayerID ) {
	static menuFreeDayForceMenu;
	
	if( !menuFreeDayForceMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose A Type:^n", g_strPluginSponsor );
		
		menuFreeDayForceMenu = menu_create( strMenuTitle, "Handle_ExtraVoteForceMenu" );
		
		new strOptionsFreeDay[ MAX_OPTIONS_FREEDAY ][ ] = {
			"Unrestricted Freeday",
			"Restricted Freeday"
		};
		
		for( new iLoop = 0; iLoop < MAX_OPTIONS_FREEDAY; iLoop++ ) {
			menu_additem( menuFreeDayForceMenu, strOptionsFreeDay[ iLoop ] );
		}
		
		menu_setprop( menuFreeDayForceMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuFreeDayForceMenu, 0 );
}

public Handle_ExtraVoteForceMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, 31 );
	
	client_print_color( 0, iPlayerID, "^4%s^1 Admin ^3%s^1 started a ^4%s^1.", g_strPluginPrefix, strPlayerName, g_strOptionsDayMenu[ g_iChosenForceDay ] );
	
	RefundShopItems( );
	
	ResetAll( );
	g_iCurrentDay = g_iChosenForceDay;
	
	switch( g_iChosenForceDay ) {
		case DAY_NIGHTCRAWLER: {
			( iKey ) ? ( g_iTypeNightCrawler = REVERSED ) : ( g_iTypeNightCrawler = REGULAR );
			StartNightCrawlerDay( );
		}
		
		case DAY_ZOMBIE: {
			( iKey ) ? ( g_iTypeZombie = REVERSED ) : ( g_iTypeZombie = REGULAR );
			StartZombieDay( );
		}
		
		case DAY_SHARK: {
			( iKey ) ? ( g_iTypeShark = REVERSED ) : ( g_iTypeShark = REGULAR );
			StartSharkDay( );
		}
		
		case DAY_FREE: {
			( iKey ) ? ( g_iTypeFreeDay = RESTRICTED ) : ( g_iTypeFreeDay = UNRESTRICTED );
			StartFreeDay( );
		}

		default: {
			StartDay( );
		}
	}
}

ShowWeaponMenu( iPlayerID ) {
	ShowPrimaryMenu( iPlayerID );
}

ShowPrimaryMenu( iPlayerID ) {
	static menuPrimary;
	
	if( !menuPrimary ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose A Primary Weapon:^n", g_strPluginSponsor );
		
		menuPrimary = menu_create( strMenuTitle, "Handle_PrimaryMenu" );
		
		new strNum[ 8 ];
		new strPrimaryWeapons[ MAX_PRIMARY ][ ] = {
			"M4A1",
			"AK47",
			"AUG",
			"SG552",
			"Galil",
			"Famas",
			"Scout",
			"AWP",
			"M249",
			"UMP 45",
			"MP5 Navy",
			"M3",
			"XM1014",
			"TMP",
			"Mac 10",
			"P90"
		};
		
		for( new iLoop = 0; iLoop < MAX_PRIMARY; iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuPrimary, strPrimaryWeapons[ iLoop ], strNum );
		}
		
		menu_setprop( menuPrimary, MPROP_NUMBER_COLOR, "\y" );
		menu_setprop( menuPrimary, MPROP_EXITNAME, "Exit" );
		menu_setprop( menuPrimary, MPROP_BACKNAME, "Back" );
		menu_setprop( menuPrimary, MPROP_NEXTNAME, "Next" );
	}
	
	menu_display( iPlayerID, menuPrimary, 0 );
}

public Handle_PrimaryMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	new strWeaponNumber[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strWeaponNumber, 7, _, _, iCallBack );
	
	new iWeaponNumber = str_to_num( strWeaponNumber );
	
	g_iPlayerPrimaryWeapon[ iPlayerID ] = iWeaponNumber;
	
	ShowSecondaryMenu( iPlayerID );
}

ShowSecondaryMenu( iPlayerID ) {
	static menuSecondary;
	
	if( !menuSecondary ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose A Secondary Weapon:", g_strPluginSponsor );
		
		menuSecondary = menu_create( strMenuTitle, "Handle_SecondaryMenu" );
		
		new strNum[ 8 ];
		new strSecondaryWeapons[ MAX_SECONDARY ][ ] = {
			"USP",
			"Glock",
			"Deagle",
			"P228",
			"Elite",
			"Five Seven"
		};
		
		for( new iLoop = 0; iLoop < MAX_SECONDARY; iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuSecondary, strSecondaryWeapons[ iLoop ], strNum );
		}
		
		menu_setprop( menuSecondary, MPROP_NUMBER_COLOR, "\y" );
		menu_setprop( menuSecondary, MPROP_EXITNAME, "Exit" );
		menu_setprop( menuSecondary, MPROP_BACKNAME, "Back" );
		menu_setprop( menuSecondary, MPROP_NEXTNAME, "Next" );
	}
	
	menu_display( iPlayerID, menuSecondary, 0 );
}

public Handle_SecondaryMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	if( g_bLRInProgress && g_iCurrentLR != LR_KAMIKAZE && g_iCurrentLR != LR_DEAGLE_MANIAC && g_iCurrentLR != LR_GLOCKER ) {
		return;
	}
	
	switch( g_iCurrentDay ) {
		case DAY_CAGE, DAY_FREE, DAY_RIOT, DAY_JUDGEMENT, DAY_CUSTOM, DAY_HNS: {
			if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
				return;
			}
		}
	}
	
	new strWeaponNumber[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strWeaponNumber, 7, _, _, iCallBack );
	
	new iWeaponNumber = str_to_num( strWeaponNumber );
	
	static strPrimaryWeapons[ MAX_PRIMARY ][ ] = {
		"weapon_m4a1",
		"weapon_ak47",
		"weapon_aug",
		"weapon_sg552",
		"weapon_galil",
		"weapon_famas",
		"weapon_scout",
		"weapon_awp",
		"weapon_m249",
		"weapon_ump45",
		"weapon_mp5navy",
		"weapon_m3",
		"weapon_xm1014",
		"weapon_tmp",
		"weapon_mac10",
		"weapon_p90"
	};
	
	static iPrimaryWeaponsAmmo[ MAX_PRIMARY ] = {
		CSW_M4A1,
		CSW_AK47,
		CSW_AUG,
		CSW_SG552,
		CSW_GALIL,
		CSW_FAMAS,
		CSW_SCOUT,
		CSW_AWP,
		CSW_M249,
		CSW_UMP45,
		CSW_MP5NAVY,
		CSW_M3,
		CSW_XM1014,
		CSW_TMP,
		CSW_MAC10,
		CSW_P90
	};
	
	static iPrimaryWeaponsMaxAmmo[ MAX_PRIMARY ] = {
		90,		// CSW_M4A1
		90,		// CSW_AK47
		100,		// CSW_AUG
		90,		// CSW_SG552
		90,		// CSW_GALIL
		90,		// CSW_FAMAS
		90,		// CSW_SCOUT
		30,		// CSW_AWP
		200,		// CSW_M249
		100,		// CSW_UMP45
		120,		// CSW_MP5NAVY
		32,		// CSW_M3
		32,		// CSW_XM1014
		120,		// CSW_TMP
		100,		// CSW_MAC10
		100		// CSW_P90
	};
	
	static strSecondaryWeapons[ MAX_SECONDARY ][ ] = {
		"weapon_usp",
		"weapon_glock18",
		"weapon_deagle",
		"weapon_p228",
		"weapon_elite",
		"weapon_fiveseven"
	};
	
	static iSecondaryWeaponsAmmos[ MAX_SECONDARY ] = {
		CSW_USP,
		CSW_GLOCK18,
		CSW_DEAGLE,
		CSW_P228,
		CSW_ELITE,
		CSW_FIVESEVEN
	};
	
	static iSecondaryWeaponsMaxAmmos[ MAX_SECONDARY ] = {
		100,		// CSW_USP
		120,		// CSW_GLOCK18
		35,		// CSW_DEAGLE
		52,		// CSW_P228
		120,		// CSW_ELITE
		1000		// CSW_FIVESEVEN
	};
	
	StripPlayerWeapons( iPlayerID );
	
	give_item( iPlayerID, strPrimaryWeapons[ g_iPlayerPrimaryWeapon[ iPlayerID ] ] );
	cs_set_user_bpammo( iPlayerID, iPrimaryWeaponsAmmo[ iWeaponNumber ], iPrimaryWeaponsMaxAmmo[ g_iPlayerPrimaryWeapon[ iPlayerID ] ] );
	
	give_item( iPlayerID, strSecondaryWeapons[ iWeaponNumber ] );
	cs_set_user_bpammo( iPlayerID, iSecondaryWeaponsAmmos[ iWeaponNumber ], iSecondaryWeaponsMaxAmmos[ iWeaponNumber ] );
	
	SetBit( g_bitHasUnAmmo, iPlayerID );
}

ShowGlowPlayerMenu( iPlayerID ) {
	new strMenuTitle[ 64 ];
	formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose A Player:^n", g_strPluginSponsor );
	
	static menuPlayerMenu[ MAX_PLAYERS + 1 ];
	menuPlayerMenu[ iPlayerID ] = menu_create( strMenuTitle, "Handle_GlowPlayerMenu" );
	
	new strPlayerName[ 32 ], iPlayers[ 32 ], strID[ 8 ];
	new iNum, iTempID, iCount = 0;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	if( iNum <= 1 ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 There are less than^3 2 Prisoners^1 alive.", g_strPluginPrefix );
		
		return;
	}
	
	new strFormatex[ 64 ];
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		num_to_str( get_user_userid( iTempID ), strID, 7 );
		get_user_name( iTempID, strPlayerName, 31 );
		
		if( CheckBit( g_bitHasFreeDay, iTempID ) ) {
			formatex( strFormatex, 63, "\rREMOVE: \w%s", strPlayerName );
		} else {
			formatex( strFormatex, 63, "\rGIVE: \w%s", strPlayerName );
		}
		
		menu_additem( menuPlayerMenu[ iPlayerID ], strFormatex, strID );
		
		iCount++;
	}
	
	if( !iCount ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 There are no ^3Prisoners^1 suitable for the menu.", g_strPluginPrefix );
		
		menu_destroy( menuPlayerMenu[ iPlayerID ] );
		
		return;
	}
	
	menu_setprop( menuPlayerMenu[ iPlayerID ], MPROP_NUMBER_COLOR, "\y" );
	menu_setprop( menuPlayerMenu[ iPlayerID ], MPROP_EXITNAME, "Exit" );
	menu_setprop( menuPlayerMenu[ iPlayerID ], MPROP_BACKNAME, "Back" );
	menu_setprop( menuPlayerMenu[ iPlayerID ], MPROP_NEXTNAME, "Next" );
	
	menu_display( iPlayerID, menuPlayerMenu[ iPlayerID ], 0 );
}

public Handle_GlowPlayerMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT || !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		menu_destroy( iMenu );
		
		return;
	}
	
	new strPlayerID[ 32 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strPlayerID, 31, _, _, iCallBack );
	
	new iUserID = str_to_num( strPlayerID );
	new iTarget = find_player( "k", iUserID );
	
	if( !is_user( iTarget ) ) {
		menu_destroy( iMenu );
		ShowGlowPlayerMenu( iPlayerID );
		
		return;
	}
	
	new strPlayerName[ 32 ];
	get_user_name( iTarget, strPlayerName, 31 );
	
	if( !CheckBit( g_bitIsAlive, iTarget ) ) {
		client_print_color( iPlayerID, iTarget, "^4%s^3 %s^1 is no longer alive.", g_strPluginPrefix, strPlayerName );
	} else {
		if( CheckBit( g_bitHasFreeDay, iTarget ) ) {
			set_user_rendering( iTarget );
		
			ClearBit( g_bitHasFreeDay, iTarget );
			
			new strAdminName[ 32 ];
			get_user_name( iPlayerID, strAdminName, 31 );
			
			client_print_color( 0, iPlayerID, "^4%s^3 %s ^1removed ^4%s^1's personal ^4freeday^1.", g_strPluginPrefix, strAdminName, strPlayerName );
		} else {
			set_user_rendering( iTarget, kRenderFxGlowShell, 220, 220, 0, kRenderNormal, 5 );
			
			SetBit( g_bitHasFreeDay, iTarget );
			
			UTIL_ScreenFade( iTarget, { 220, 220, 0 }, 2.0, 0.5, 100, 0x0001 );
			
			new strAdminName[ 32 ];
			get_user_name( iPlayerID, strAdminName, 31 );
			
			client_print_color( 0, iPlayerID, "^4%s ^3%s ^1gave ^4%s^1 a personal ^4freeday^1.", g_strPluginPrefix, strAdminName, strPlayerName );
		}
	}
	
	menu_destroy( iMenu );
	ShowGlowPlayerMenu( iPlayerID );
}

ShowLastRequestMenu( iPlayerID, iPage = 0 ) {
	static menuLastRequest;
	
	if( !menuLastRequest ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yLast Request Menu:^n", g_strPluginSponsor );
		
		menuLastRequest = menu_create( strMenuTitle, "Handle_LastRequestMenu" );
		
		static strOptionsLastRequestExtra[ MAX_LR ][ ] = {
			"\y[\rsharpen your knife and get ready \y]",
			"\y[\rthrow that heavy thing\y]",
			"\y[\rshoot that bastard\y]",
			"\y[\rcan you get that headshot?\y]",
			"\y[\rgo back in time cowboy\y]",
			"\y[\rno the nade does not explode\y]",
			"\y[\rthat scout is hot, get rid of it\y]",
			"\y[\rstrafe running is what I do\y]",
			"\y[\ryou a graffity artist?\y]",
			"\y[\rAHHH!\y]",
			"\y[\rKABOOOOM!\y]",
			"\y[\rlet's get sneaky\y]",
			"\y[\rburst fire his head off\y]"
		};
		
		new strNum[ 8 ];
		new strFormatex[ 128 ];
		
		for( new iLoop = 0; iLoop < MAX_LR; iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			switch( iLoop ) {
				case LR_KAMIKAZE: {
					formatex( strFormatex, 127, "\rREBELL: \w%s %s \d[Guards >= %i]", g_strOptionsLastRequest[ iLoop ], strOptionsLastRequestExtra[ iLoop ], KAMIKAZE_CT_COUNT );
					
				}
				
				case LR_SUICIDE: {
					formatex( strFormatex, 127, "\rREBELL: \w%s %s", g_strOptionsLastRequest[ iLoop ], strOptionsLastRequestExtra[ iLoop ] );
				}
				
				case LR_DEAGLE_MANIAC: {
					formatex( strFormatex, 127, "\rREBELL: \w%s %s \d[Guards >= %i]", g_strOptionsLastRequest[ iLoop ], strOptionsLastRequestExtra[ iLoop ], DEAGLE_MANIAC_CT_COUNT );
				}
				
				case LR_GLOCKER: {
					formatex( strFormatex, 127, "\rREBELL: \w%s %s \d[Guards >= %i]", g_strOptionsLastRequest[ iLoop ], strOptionsLastRequestExtra[ iLoop ], UBER_GLOCKER_CT_COUNT );
				}
				
				default: {
					formatex( strFormatex, 127, "\w%s %s", g_strOptionsLastRequest[ iLoop ], strOptionsLastRequestExtra[ iLoop ] );
				}
			}
			
			menu_additem( menuLastRequest, strFormatex, strNum );
		}
		
		menu_setprop( menuLastRequest, MPROP_NUMBER_COLOR, "\y" );
		menu_setprop( menuLastRequest, MPROP_EXITNAME, "Exit" );
		menu_setprop( menuLastRequest, MPROP_BACKNAME, "Back" );
		menu_setprop( menuLastRequest, MPROP_NEXTNAME, "Next" );
	}
	
	menu_display( iPlayerID, menuLastRequest, iPage );
}

public Handle_LastRequestMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT || !CheckBit( g_bitIsAlive, iPlayerID ) || g_bDayInProgress ) {
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
	
	g_iCurrentLR = str_to_num( strOption );
	
	switch( g_iCurrentLR ) {
		case LR_KNIFE:		ShowKnifeFightHealthMenu( iPlayerID );
		case LR_WEAPONTOSS:	ShowWeaponTossWeaponMenu( iPlayerID );
		case LR_DUEL:		ShowDuelWeaponMenu( iPlayerID );
		case LR_S4S:		ShowS4SWeaponMenu( iPlayerID );
		case LR_SHOWDOWN:	ShowLRPlayerMenu( iPlayerID );
		case LR_GRENADETOSS:	ShowLRPlayerMenu( iPlayerID );
		case LR_HOTPOTATO:	ShowLRPlayerMenu( iPlayerID );
		case LR_RACE:		ShowLRPlayerMenu( iPlayerID );
		case LR_SPRAY:		ShowLRPlayerMenu( iPlayerID );
		case LR_KAMIKAZE: {
			new iPlayers[ 32 ], iNum;
			get_players( iPlayers, iNum, "ae", "CT" );
			
			if( iNum < KAMIKAZE_CT_COUNT ) {
				ShowLastRequestMenu( iPlayerID, 1 );
				client_print_color( iPlayerID, print_team_blue, "^4%s^1 There must be at least ^3%i Guads^1 to use this command.", g_strPluginPrefix, KAMIKAZE_CT_COUNT );
			} else {
				StartKamikaze( iPlayerID );
			}
		}
		case LR_SUICIDE: {
			ExplodePlayer( iPlayerID );
			
			new strPlayerName[ 32 ];
			get_user_name( iPlayerID, strPlayerName, 31 );
			
			client_print_color( 0, iPlayerID, "^4%s^3 %s^1 just committed suicide. All near by players are now dead.", g_strPluginPrefix, strPlayerName );
		}
		case LR_DEAGLE_MANIAC: {
			new iPlayers[ 32 ], iNum;
			get_players( iPlayers, iNum, "ae", "CT" );
			
			if( iNum < DEAGLE_MANIAC_CT_COUNT ) {
				ShowLastRequestMenu( iPlayerID, 1 );
				client_print_color( iPlayerID, print_team_blue, "^4%s^1 There must be at least ^3%i Guards^4 to use this command.", g_strPluginPrefix, DEAGLE_MANIAC_CT_COUNT );
			} else {
				StartDeagleManiac( iPlayerID );
			}
		}
		case LR_GLOCKER: {
			new iPlayers[ 32 ], iNum;
			get_players( iPlayers, iNum, "ae", "CT" );
			
			if( iNum < UBER_GLOCKER_CT_COUNT ) {
				ShowLastRequestMenu( iPlayerID, 1 );
				client_print_color( iPlayerID, print_team_blue, "^4%s^1 There must be at least ^3%i Guards^4 to use this command.", g_strPluginPrefix, UBER_GLOCKER_CT_COUNT );
			} else {
				StartUberGlocker( iPlayerID );
			}
		}
		default:		ShowLastRequestMenu( iPlayerID, 1 );
	}
	
	ShowTopInfo( );
}

ShowKnifeFightHealthMenu( iPlayerID ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	static menuKnifeFightHealth;
	
	if( !menuKnifeFightHealth ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yKnife Fight Health Menu:^n", g_strPluginSponsor );
		
		menuKnifeFightHealth = menu_create( strMenuTitle, "Handle_KnifeFightHealthMenu" );
		
		new strHealth[ 8 ];
		
		for( new iLoop = 0; iLoop < MAX_KNIFE_HEALTH; iLoop++ ) {
			num_to_str( g_iOptionsKFHealths[ iLoop ], strHealth, 7 );
			
			menu_additem( menuKnifeFightHealth, strHealth );
		}
		
		menu_setprop( menuKnifeFightHealth, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuKnifeFightHealth, 0 );
}

public Handle_KnifeFightHealthMenu( iPlayerID, iMenu, iKey ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		ShowLastRequestMenu( iPlayerID, 1 );
		
		return;
	}
	
	g_iChosenHP = iKey;
	ShowLRPlayerMenu( iPlayerID );
}

ShowWeaponTossWeaponMenu( iPlayerID ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	static menuWeaponTossWeaponMenu;
	
	if( !menuWeaponTossWeaponMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yWeapon Toss Weapon Menu:^n", g_strPluginSponsor );
		
		menuWeaponTossWeaponMenu = menu_create( strMenuTitle, "Handle_WeaponTossWeaponMenu" );
		
		new strWeapons[ ][ ] = {
			"Deagle \y[\rnormal weapon\y]",
			"Scout \y[\rlightest weapon\y]",
			"AWP \y[\rheaviest weapon\y]"
		};
		
		for( new iLoop = 0; iLoop < sizeof( strWeapons ); iLoop++ ) {
			menu_additem( menuWeaponTossWeaponMenu, strWeapons[ iLoop ] );
		}
		
		menu_setprop( menuWeaponTossWeaponMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuWeaponTossWeaponMenu, 0 );
}

public Handle_WeaponTossWeaponMenu( iPlayerID, iMenu, iKey ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		ShowLastRequestMenu( iPlayerID, 1 );
		
		return;
	}
	
	g_iChosenWT = iKey;
	ShowLRPlayerMenu( iPlayerID );
}

ShowDuelWeaponMenu( iPlayerID ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	static menuDuelWeaponMenu;
	
	if( !menuDuelWeaponMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yDuel Weapon Menu:", g_strPluginSponsor );
		
		menuDuelWeaponMenu = menu_create( strMenuTitle, "Handle_DuelWeaponMenu" );
		
		new strWeapons[ ][ ] = {
			"Shotgun ",
			"M4A1",
			"AK47",
			"Scout",
			"AWP"
		};
		
		for( new iLoop = 0; iLoop < sizeof( strWeapons ); iLoop++ ) {
			menu_additem( menuDuelWeaponMenu, strWeapons[ iLoop ] );
		}
		
		menu_setprop( menuDuelWeaponMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuDuelWeaponMenu, 0 );
}

public Handle_DuelWeaponMenu( iPlayerID, iMenu, iKey ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		ShowLastRequestMenu( iPlayerID, 1 );
		
		return;
	}
	
	g_iChosenWD = iKey;
	ShowLRPlayerMenu( iPlayerID );
}

ShowS4SWeaponMenu( iPlayerID ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	static menuS4SWeaponMenu;
	
	if( !menuS4SWeaponMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yS4S Weapon Menu:", g_strPluginSponsor );
		
		menuS4SWeaponMenu = menu_create( strMenuTitle, "Handle_S4SWeaponMenu" );
		
		new strWeapons[ ][ ] = {
			"USP", "Deagle", "Scout", "FiveSeven", "AWP", "Elites"
		};
		
		for( new iLoop = 0; iLoop < sizeof( strWeapons ); iLoop++ ) {
			menu_additem( menuS4SWeaponMenu, strWeapons[ iLoop ] );
		}
		
		menu_setprop( menuS4SWeaponMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuS4SWeaponMenu, 0 );
}

public Handle_S4SWeaponMenu( iPlayerID, iMenu, iKey ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		ShowLastRequestMenu( iPlayerID, 1 );
		
		return;
	}
	
	g_iChosenWE = iKey;
	ShowLRPlayerMenu( iPlayerID );
}

ShowLRPlayerMenu( iPlayerID ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	if( !iNum ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 There are no more alive ^3Guards^1.", g_strPluginPrefix );
		
		return;
	}
	
	new strMenuTitle[ 64 ];
	formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose A Player:^n", g_strPluginSponsor );
	
	new menuLRPlayerMenu = menu_create( strMenuTitle, "Handle_LRPlayerMenu" );
	
	new strPlayerName[ 32 ], strID[ 8 ];
	new iTempID;
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		get_user_name( iTempID, strPlayerName, 31 );
		num_to_str( get_user_userid( iTempID ), strID, 7 );
		
		menu_additem( menuLRPlayerMenu, strPlayerName, strID );
	}
	
	menu_setprop( menuLRPlayerMenu, MPROP_NUMBER_COLOR, "\y" );
	
	menu_display( iPlayerID, menuLRPlayerMenu, 0 );
}

public Handle_LRPlayerMenu( iPlayerID, iMenu, iKey ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		menu_destroy( iMenu );
		
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		menu_destroy( iMenu );
		ShowLastRequestMenu( iPlayerID, 0 );
		
		return;
	}
	
	new strPlayerID[ 32 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strPlayerID, 31, _, _, iCallBack );
	
	new iUserID = str_to_num( strPlayerID );
	new iTarget = find_player( "k", iUserID );
	
	if( !is_user( iTarget ) ) {
		menu_destroy( iMenu );
		ShowLRPlayerMenu( iPlayerID );
		
		return;
	}
	
	new strPlayerName[ 32 ];
	get_user_name( iTarget, strPlayerName, 31 );
	
	if( !CheckBit( g_bitIsAlive, iTarget ) || cs_get_user_team( iTarget ) != CS_TEAM_CT ) {
		client_print_color( iPlayerID, iTarget, "^4%s ^3%s^1 is no longer available for ^4Last Request^1.", g_strPluginPrefix, strPlayerName );
		
		return;
	}
	
	if( g_iCurrentLR == LR_SHOWDOWN || g_iCurrentLR == LR_HOTPOTATO ) {
		if( !CheckProximity( iPlayerID, iTarget ) ) {
			client_print_color( iPlayerID, iTarget, "^4%s^3 %s^1 is not close enough to start ^4Last Request^1.", g_strPluginPrefix, strPlayerName );
			
			menu_destroy( iMenu );
			
			ShowLRPlayerMenu( iPlayerID );
			
			return;
		}
	}
	
	g_iLastRequest[ PLAYER_OFFICER ] = iTarget;
	g_iLastRequest[ PLAYER_PRISONER ] = iPlayerID;
	
	StartLastRequest( );
	
	menu_destroy( iMenu );
}

ShowCommanderMenu( iPlayerID, iPage = 0 ) {
	static menuCommanderMenu;
	
	if( !menuCommanderMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose An Option:^n", g_strPluginSponsor );
		
		menuCommanderMenu = menu_create( strMenuTitle, "Handle_CommanderMenu" );
		
		new strOptions[ ][ ] = {
			"Open Cells",
			"Split Prisoners in two teams \y[\rnb. Prisoners pair\y]",
			"Start a timer \y[\r10 seconds\y]",
			"Open the game book \y[\rNOOB CT? not anymore\y]",
			"Pick a random Prisoner \y[\rwe'll pick for you\y]",
			"Give a Prisoner an empty Deagle",
			"Give/Remove a Prisoner's mic access \y[\rone round\y]",
			"Heal all Prisoners \y[\r100 HP\y]",
			"Glow a Prisoner \y[\rchoose color\y]",
			"Ask a random math question \y[\rwe already have the answers\y]",
			"Enable/Disable Free For All \y[\rlet them kill each others\y]",
			"Enable/Disable Dodgeball \y[\rhit to kill\y]",
			"Enable/Disable Spray Meter \y[\rhow high can you spray?\y]"
		};
		
		new strNum[ 8 ];
		
		for( new iLoop = 0; iLoop < sizeof( strOptions ); iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuCommanderMenu, strOptions[ iLoop ], strNum );
		}
		
		menu_setprop( menuCommanderMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuCommanderMenu, iPage );
}

public Handle_CommanderMenu( iPlayerID, iMenu, iKey ) {
	if( g_iCommander != iPlayerID ) {
		return;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT || !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		g_iCommander = -1;
		
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	new strID[ 32 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strID, 31, _, _, iCallBack );
	
	iKey = str_to_num( strID );
	
	switch( iKey ) {
		case COMMANDER_OPEN: {
			PushButton( );
			
			client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander^1 has remotely opened the cells.", g_strPluginPrefix );
		}
		
		case COMMANDER_SPLIT: {
			new iPlayers[ 32 ], iNum, iCount = 0;
			get_players( iPlayers, iNum, "ae", "TERRORIST" );
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				if( !CheckBit( g_bitHasFreeDay, iPlayers[ iLoop ] ) ) {
					iCount++;
				}
			}
			
			if( iCount % 2 != 0 ) {
				client_print_color( iPlayerID, print_team_red, "^4%s^1 There must be an even number of ^3Prisoners^1 to use this feature.", g_strPluginPrefix );
				
				ShowCommanderMenu( iPlayerID );
			} else {
				new iTempID;
				new iFirstTeam = 0, iSecondTeam = 0;
				
				for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
					iTempID = iPlayers[ iLoop ];
					
					if( CheckBit( g_bitHasFreeDay, iTempID ) ) {
						continue;
					}
					
					if( random_num( 0, 1 ) ) {
						if( iFirstTeam - iSecondTeam >= 1 ) {
							PlayerTeam( iTempID, 1 );
							
							iSecondTeam++;
						} else {
							PlayerTeam( iTempID, 0 );
							
							iFirstTeam++;
						}
					} else {
						if( iSecondTeam - iFirstTeam >= 1 ) {
							PlayerTeam( iTempID, 0 );
							
							iFirstTeam++;
						} else {
							PlayerTeam( iTempID, 1 );
							
							iSecondTeam++;
						}
					}
				}
				
				client_print_color( 0, print_team_blue, "^4%s^1 The^3 Commander^1 has split the ^4Prisoners^1 into^4 two teams^1.", g_strPluginPrefix );
			}
		}
		
		case COMMANDER_TIMER: {
			if( task_exists( TASK_COUNTDOWN_COMMANDER ) ) {
				client_print_color( iPlayerID, print_team_default, "^4%s^1 There is already another timer going on.", g_strPluginPrefix );
				
				return;
			}
			
			g_iTimeLeft = TIME_COUNTDOWN_COMMANDER;
			
			Task_CountDown_Commander( );
			set_task( 1.0, "Task_CountDown_Commander", TASK_COUNTDOWN_COMMANDER, _, _, "a", g_iTimeLeft );
		}
		
		case COMMANDER_RANDOM_PRISONER: {
			new iPlayers[ 32 ], iNum;
			get_players( iPlayers, iNum, "ae", "TERRORIST" );
			
			new iRandomNumber;
			
			do {
				iRandomNumber = random( iNum );
			} while( CheckBit( g_bitHasFreeDay, iPlayers[ iRandomNumber ] ) );
			
			iRandomNumber = iPlayers[ iRandomNumber ];
			
			new strPlayerName[ 32 ];
			get_user_name( iRandomNumber, strPlayerName, 31 );
			
			set_user_rendering( iRandomNumber, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
			set_task( RANDOM_PLAYER_GLOW, "Task_UnglowRandomPlayer", TASK_UNGLOW_PLAYER + iRandomNumber );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 The random ^3Prisoner^1 you requested is ^3%s^1. The player is now glowed for %i seconds.", g_strPluginPrefix, strPlayerName, floatround( RANDOM_PLAYER_GLOW ) );
			client_print_color( 0, iRandomNumber, "^4%s^1 Commander wanted a random ^3Prisoner^1, and he got ^3%s^1.", g_strPluginPrefix, strPlayerName );
		}
		
		case COMMANDER_MIC, COMMANDER_EMPTY_DEAGLE: {
			g_iCommanderMenuOption = iKey;
			
			ShowCommanderPlayerMenu( iPlayerID );
			
			return;
		}
		
		case COMMANDER_HEAL: {
			new iPlayers[ 32 ], iNum, iTempID;
			get_players( iPlayers, iNum, "ae", "TERRORIST" );
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				if( !CheckBit( g_bitHasFreeDay, iTempID ) ) {
					set_user_health( iTempID, 100 );
				}
			}
			
			client_print_color( 0, print_team_red, "^4%s^1 The Commander healed all ^3Prisoners^1 to full health.", g_strPluginPrefix );
		}
		
		case COMMANDER_GLOW: {
			ShowCommanderGlowMenu( iPlayerID );
			
			return;
		}
		
		case COMMANDER_MATH: {
			new iNumbers[ 3 ];
			iNumbers[ 0 ] = random( 10 );
			iNumbers[ 1 ] = random( 10 );
			iNumbers[ 2 ] = random( 10 );
			
			new iOperations[ 2 ];
			iOperations[ 0 ] = random_num( 0, 1 );
			iOperations[ 1 ] = random_num( 0, 1 );
			
			new iResult;
			
			if( iOperations[ 0 ] ) {
				if( iOperations[ 1 ] ) {
					iResult = iNumbers[ 0 ] + iNumbers[ 1 ] + iNumbers[ 2 ];
				} else {
					iResult = iNumbers[ 0 ] + iNumbers[ 1 ] - iNumbers[ 2 ];
				}
			} else {
				if( iOperations[ 1 ] ) {
					iResult = iNumbers[ 0 ] - iNumbers[ 1 ] + iNumbers[ 2 ];
				} else {
					iResult = iNumbers[ 0 ] - iNumbers[ 1 ] - iNumbers[ 2 ];
				}
			}
			
			g_iTimeLeft = TIME_COUNTDOWN_COMMANDER;
			
			new strEquation[ 32 ];
			formatex( strEquation, 31, "Equation: %i %s %i %s %i = ?", iNumbers[ 0 ], iOperations[ 0 ] ? "+" : "-", iNumbers[ 1 ], iOperations[ 1 ] ? "+" : "-", iNumbers[ 2 ] );
			client_print_color( iPlayerID, print_team_default, "^4%s^1 The result to the math question is ^4%i^1.", g_strPluginPrefix, iResult );
			
			g_iMathQuestionResult = iResult;
			
			Task_CountDown_CommanderMath( strEquation, TASK_COUNTDOWN_COMMANDERMATH );
			set_task( 1.0, "Task_CountDown_CommanderMath", TASK_COUNTDOWN_COMMANDERMATH, strEquation, 31, "a", g_iTimeLeft );
			
			ShowCommanderMenu( iPlayerID, 1 );
			
			return;
		}
		
		case COMMANDER_FFA : {
			if( g_bFFA ) {
				SetFreeForAll( 0 );
				
				client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander^1 has disabled ^4Free For All^1.", g_strPluginPrefix );
			} else {
				SetFreeForAll( 1 );
				
				client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander^1 has enabled ^4Free For All^1.", g_strPluginPrefix );
			}
			
			ShowCommanderMenu( iPlayerID, 1 );
			
			return;
		}
		
		case COMMANDER_DODGEBALL: {
			/*if( g_bDodgeBall ) {
				g_bDodgeBall = false;
				
				client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander^1 has disabled ^4DodgeBall^1.", g_strPluginPrefix );
			} else {
				g_bDodgeBall = true;
				
				client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander^1 has enabled ^4DodgeBall^1.", g_strPluginPrefix );
				client_print_color( 0, print_team_default, "^4%s^1 Get ready! DodgeBal; will start in^4 5 seconds^1.", g_strPluginPrefix );
				
				set_task( 5.0, "Task_GiveDodgeBall", TASK_GIVEDODGEBALLNADES );
			}*/
			
			client_print_color( iPlayerID, print_team_blue, "^4%s^1 Dodgeball is ^3under construction^1. Thank you for understanding!", g_strPluginPrefix );
			
			ShowCommanderMenu( iPlayerID, 1 );
			
			return;
		}
		
		case COMMANDER_SPRAY: {
			if( g_bShowSprayMeter ) {
				g_bShowSprayMeter = false;
				
				client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander^1 has disabled ^4Spary Meter^1.", g_strPluginPrefix );
			} else {
				g_bShowSprayMeter = true;
				
				client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander^1 has enabled ^4Spray Meter^1.", g_strPluginPrefix );
			}
			
			ShowCommanderMenu( iPlayerID, 1 );
			
			return;
		}
		
		case COMMANDER_GAMEBOOK: {
			ShowGameBookMenu( iPlayerID );
			
			return;
		}
	}
	
	ShowCommanderMenu( iPlayerID, 0 );
}

ShowCommanderPlayerMenu( iPlayerID ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	if( !iNum ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 There are no more alive ^3Prisoners^1.", g_strPluginPrefix );
		ShowCommanderMenu( iPlayerID, 0 );
		
		return;
	}
	
	new strMenuTitle[ 64 ];
	formatex( strMenuTitle, 63, "\rPowered by %s!^n\yChoose A Player:^n", g_strPluginSponsor );
	
	new menuCommanderPlayerMenu = menu_create( strMenuTitle, "Handle_CommanderPlayerMenu" );
	
	new iCount = 0, iTempID;
	new strPlayerName[ 32 ], strID[ 8 ];
	
	menu_additem( menuCommanderPlayerMenu, "\rAll Players", "-2" );
	menu_additem( menuCommanderPlayerMenu, "\rPick Player by AIM^n", "-1" );
	
	new strFormatex[ 64 ];
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		if( g_iCommanderMenuOption == COMMANDER_MIC ) {
			if( !CheckBit( g_bitHasFreeDay, iTempID ) ) {
				get_user_name( iTempID, strFormatex, 63 );
				num_to_str( get_user_userid( iTempID ), strID, 7 );
				
				if( CheckBit( g_bitHasMicPower, iTempID ) ) {
					format( strFormatex, 63, "\rREMOVE: \w%s", strFormatex );
				} else {
					format( strFormatex, 63, "\rGIVE: \w%s", strFormatex );
				}
				
				menu_additem( menuCommanderPlayerMenu, strFormatex, strID );
				
				iCount++;
			}
		} else {
			if( !CheckBit( g_bitHasFreeDay, iTempID ) ) {
				get_user_name( iTempID, strPlayerName, 31 );
				num_to_str( get_user_userid( iTempID ), strID, 7 );
				
				menu_additem( menuCommanderPlayerMenu, strPlayerName, strID );
				
				iCount++;
			}
		}
	}
	
	if( !iCount ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 There are no more available ^3Prisoners^1.", g_strPluginPrefix );
		
		menu_destroy( menuCommanderPlayerMenu );
		ShowCommanderMenu( iPlayerID );
		
		return;
	}
	
	menu_setprop( menuCommanderPlayerMenu, MPROP_NUMBER_COLOR, "\y" );
	
	menu_display( iPlayerID, menuCommanderPlayerMenu,  0 );
}

public Handle_CommanderPlayerMenu( iPlayerID, iMenu, iKey ) {
	if( g_iCommander != iPlayerID ) {
		menu_destroy( iMenu );
		
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		menu_destroy( iMenu );
		ShowCommanderMenu( iPlayerID, 0 );
		
		return;
	}
	
	new strPlayerID[ 32 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strPlayerID, 31, _, _, iCallBack );
	
	new iUserID = str_to_num( strPlayerID );
	new iTarget, strPlayerName[ 32];
	
	if( iUserID != -2 ) {
		if( iUserID == -1 ) {
			new iBody;
			get_user_aiming( iPlayerID, iTarget, iBody );
			
			if( !is_user( iTarget ) || !CheckBit( g_bitIsConnected, iTarget ) ) {
				menu_destroy( iMenu );
				ShowCommanderPlayerMenu( iPlayerID );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 No valid target found. Please try again.", g_strPluginPrefix );
				
				return;
			}
		} else {
			iTarget = find_player( "k", iUserID );
			
			if( !is_user( iTarget ) ) {
				menu_destroy( iMenu );
				ShowCommanderPlayerMenu( iPlayerID );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 The player you have chosen is not available anymore.", g_strPluginPrefix );
				
				return;
			}
			
			get_user_name( iTarget, strPlayerName, 31 );
			
			if( !CheckBit( g_bitIsAlive, iTarget ) || CheckBit( g_bitHasFreeDay, iTarget ) ) {
				client_print_color( iPlayerID, iTarget, "^4%s ^3%s^1 is no longer available.", g_strPluginPrefix, strPlayerName );
				
				return;
			}
		}
	}
	
	new strCommanderName[ 32 ];
	get_user_name( iPlayerID, strCommanderName, 31 );
	
	switch( g_iCommanderMenuOption ) {
		case COMMANDER_MIC: {
			if( iUserID == -2 ) {
				new iPlayers[ 32 ], iNum, iTempID;
				get_players( iPlayers, iNum, "ae", "TERRORIST" );
				
				for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
					iTempID = iPlayers[ iLoop ];
					
					if( !CheckBit( g_bitHasFreeDay, iTempID ) ) {
						ClearBit( g_bitHasFreeDay, iTempID );
					}
				}
				
				client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander %s^1 removed ALL players' microphone access.", g_strPluginPrefix, strCommanderName );
			} else {
				new strPlayerName[ 32 ];
				get_user_name( iTarget, strPlayerName, 31 );
				
				if( CheckBit( g_bitHasMicPower, iTarget ) ) {
					ClearBit( g_bitHasMicPower, iTarget );
					
					client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander %s^1 removed ^4%s^1's microphone access.", g_strPluginPrefix, strCommanderName, strPlayerName );
				} else {
					SetBit( g_bitHasMicPower, iTarget );
					
					client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander %s^1 gave ^4%s^1 microphone access.", g_strPluginPrefix, strCommanderName, strPlayerName );
				}
			}
		}
		
		case COMMANDER_EMPTY_DEAGLE: {
			if( iUserID == -2 ) {
				new iPlayers[ 32 ], iNum, iTempID;
				get_players( iPlayers, iNum, "ae", "TERRORIST" );
				
				for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
					iTempID = iPlayers[ iLoop ];
					
					if( !CheckBit( g_bitHasFreeDay, iTempID ) ) {
						ham_strip_user_weapon( iTempID, CSW_DEAGLE, 0, true );
						
						cs_set_weapon_ammo( give_item( iTempID, "weapon_deagle" ), 0 );
						cs_set_user_bpammo( iTempID, CSW_DEAGLE, 0 );
					}
				}
				
				client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander %s^1 gave ALL players an empty deagle.", g_strPluginPrefix, strCommanderName );
			} else {
				ham_strip_user_weapon( iTarget, CSW_DEAGLE, 0, true );
				
				cs_set_weapon_ammo( give_item( iTarget, "weapon_deagle" ), 0 );
				cs_set_user_bpammo( iTarget, CSW_DEAGLE, 0 );
				
				new strPlayerName[ 32 ];
				get_user_name( iTarget, strPlayerName, 31 );
				
				client_print_color( 0, print_team_red, "^4%s^1 The Commander %s gave ^3%s^1 an empty deagle.", g_strPluginPrefix, strCommanderName, strPlayerName );
			}
		}
		
		case COMMANDER_GLOW: {
			if( iUserID == -2 ) {
				new iPlayers[ 32 ], iNum, iTempID;
				get_players( iPlayers, iNum, "ae", "TERRORIST" );
				
				for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
					iTempID = iPlayers[ iLoop ];
					
					if( !CheckBit( g_bitHasFreeDay, iTempID ) ) {
						set_user_rendering( iTempID, kRenderFxGlowShell, g_iCommanderColor[ 0 ], g_iCommanderColor[ 1 ], g_iCommanderColor[ 2 ], kRenderNormal, 5 );
					}
				}
				
				client_print_color( 0, print_team_blue, "^4%s^1 The ^3Commander %s^1 just glowed ALL players.", g_strPluginPrefix, strCommanderName );
			} else {
				set_user_rendering( iTarget, kRenderFxGlowShell, g_iCommanderColor[ 0 ], g_iCommanderColor[ 1 ], g_iCommanderColor[ 2 ], kRenderNormal, 5 );
				
				new strPlayerName[ 32 ];
				get_user_name( iTarget, strPlayerName, 31 );
				
				client_print_color( 0, print_team_red, "^4%s^1 The Commander %s just glowed ^3%s^1.", g_strPluginPrefix, strCommanderName, strPlayerName );
			}
		}
	}
	
	menu_destroy( iMenu );
	ShowCommanderPlayerMenu( iPlayerID );
}

ShowCommanderGlowMenu( iPlayerID ) {
	static menuCommanderGlowMenu;
	
	if( !menuCommanderGlowMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yCommander Glow Menu:", g_strPluginSponsor );
		
		menuCommanderGlowMenu = menu_create( strMenuTitle, "Handle_CommanderGlowMenu" );
		
		new strNum[ 8 ];
		new strGlowColors[ MAX_COLORS ][ ] = {
			"Off",
			"Red",
			"Pink",
			"Dark Red",
			"Light Red",
			"Blue",
			"Dark Blue",
			"Light Blue",
			"Aqua",
			"Green",
			"Light Green",
			"Dark Green",
			"Brown",
			"Light Brown",
			"White",
			"Yellow",
			"Dark Yellow",
			"Light Yellow",
			"Orange",
			"Light Orange",
			"Dark Orange",
			"Light Purple",
			"Purple",
			"Dark Purple",
			"Violet",
			"Maroon",
			"Gold",
			"Silver",
			"Bronze",
			"Grey"
		};
		
		for( new iLoop = 0; iLoop < sizeof( strGlowColors ); iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuCommanderGlowMenu, strGlowColors[ iLoop ], strNum );
		}
		
		menu_setprop( menuCommanderGlowMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuCommanderGlowMenu, 0 );
}

public Handle_CommanderGlowMenu( iPlayerID, iMenu, iKey ) {
	if( g_iCommander != iPlayerID ) {
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		ShowCommanderMenu( iPlayerID, 1 );
		
		return;
	}
	
	new strID[ 32 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strID, 31, _, _, iCallBack );
	
	iKey = str_to_num( strID );
	
	static iColorArray[ MAX_COLORS ][ 3 ] = {
		{0, 	0, 	0},		// off
		{255, 	0, 	0},		// red
		{255, 	190, 	190},		// pink
		{165, 	0, 	0},		// darkred
		{255, 	100, 	100},		// lightred
		{0, 	0, 	255},		// blue
		{0, 	0, 	136},		// darkblue
		{95, 	200, 	255},		// lightblue
		{0, 	150, 	255},		// aqua
		{0, 	255, 	0},		// green
		{180, 	255, 	175},		// lightgreen
		{0, 	155, 	0},		// darkgreen
		{150, 	63, 	0},		// brown
		{205, 	123, 	64},		// lightbrown
		{255, 	255, 	255},		// white
		{255, 	255, 	0},		// yellow
		{189, 	182, 	0},		// darkyellow
		{255, 	255, 	109},		// lightyellow
		{255, 	150, 	0},		// orange
		{255, 	190, 	90},		// lightorange
		{222, 	110, 	0},		// darkorange
		{243, 	138, 	255},		// lightpurple
		{255, 	0, 	255},		// purple
		{150, 	0, 	150},		// darkpurple
		{100, 	0, 	100},		// violet
		{200, 	0, 	0},		// maroon
		{220, 	220, 	0},		// gold
		{192, 	192, 	192},		// silver
		{190, 	100, 	10},		// bronze
		{114, 	114, 	114}		// grey
	};
	
	g_iCommanderColor[ 0 ] = iColorArray[ iKey ][ 0 ];
	g_iCommanderColor[ 1 ] = iColorArray[ iKey ][ 1 ];
	g_iCommanderColor[ 2 ] = iColorArray[ iKey ][ 2 ];
	
	g_iCommanderMenuOption = COMMANDER_GLOW;
	ShowCommanderPlayerMenu( iPlayerID );
}

public ShowMainMenu( iPlayerID ) {
	static menuMainMenu;
	
	if( !menuMainMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yJailBreak Main Menu:", g_strPluginSponsor );
		
		menuMainMenu = menu_create( strMenuTitle, "Handle_MainMenu" );
		
		new strOptionsMainMenu[ ][ ] = {
			"\rChange Team^n",
			
			"\wShop Menu",
			"\wLast Request Menu",
			"\wFun Menu^n",
			
			"\wFreeDay Menu",
			"\wCommander Toggle",
			"\wCommander Menu",
			
			"\rAdmin: \wSpecial Day Menu",
			"\rVIP: \wVIP Menu^n",
			
			"\wOpen Guns Menu",
			"\wJailBreak Rules",
			"\wCredits"
		};
		
		new strNum[ 8 ];
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsMainMenu ); iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuMainMenu, strOptionsMainMenu[ iLoop ], strNum );
		}
		
		menu_setprop( menuMainMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuMainMenu, 0 );
}

public Handle_MainMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	switch( iOption ) {
		case 0: {
			if( CheckBit( g_bitIsCTBanned, iPlayerID ) ) {
				client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have been banned from joining the ^3Counter-Terrorist^1 team. Appeal your ban on our forums.", g_strPluginPrefix );
			} else {
				new iPlayers[ 32 ], iNumCT, iNumT;
				get_players( iPlayers, iNumCT, "e", "CT" );
				get_players( iPlayers, iNumT, "e", "TERRORIST" );
				
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_T && ( ( ++iNumT / ++iNumCT ) < TEAM_RATIO ) && iNumCT > 1 ) {
					client_print_color( iPlayerID, print_team_blue, "^4%s^1 You cannot change teams since the ratio does not support that ^4(T:%i | CT:%i)^1.", g_strPluginPrefix, iNumT, iNumCT );
				} else {
					static iMinimumTime = MINIMUM_TIME_TO_CT * 60;
					
					switch( cs_get_user_team( iPlayerID ) ) {
						case CS_TEAM_T: {
							if( g_iPlayerTime[ iPlayerID ] < iMinimumTime && !is_user_admin( iPlayerID ) ) {
								client_print_color( iPlayerID, print_team_red, "^4%s^1 You need at least ^3%d minutes^1 of played time to go to the CT team.", g_strPluginPrefix, iMinimumTime );
								
								return;
							} else {
								client_print_color( iPlayerID, print_team_blue, "^4%s^1 By playing as a ^3Guard^1 you automatically agree to the rules of this server. You have been warned!", g_strPluginPrefix );
								
								if( CheckBit( g_bitIsPlayerVIP, iPlayerID ) ) {
									cs_set_user_team( iPlayerID, CS_TEAM_CT, CS_CT_GIGN );
								} else {
									cs_set_user_team( iPlayerID, CS_TEAM_CT, CS_CT_GSG9 );
								}
							}
						}
						
						case CS_TEAM_CT, CS_TEAM_SPECTATOR, CS_TEAM_UNASSIGNED: {
							cs_set_user_team( iPlayerID, CS_TEAM_T, CS_T_LEET );
						}
					}
					
					if( CheckBit( g_bitIsAlive, iPlayerID ) ) {
						user_kill( iPlayerID );
					}
				}
			}
		}
		
		case 1:		ClCmd_OpenShop( iPlayerID );
		case 2:		ClCmd_LastRequest( iPlayerID );
		case 3:		ClCmd_FunMenu( iPlayerID );
		case 4:		ClCmd_Freeday( iPlayerID );
		case 5:		ClCmd_Commander( iPlayerID );
		case 6:		ClCmd_CommanderMenu( iPlayerID );
		case 7:		ClCmd_StartDay( iPlayerID );
		case 8:		ClCmd_DisplayVip( iPlayerID );
		case 9:		ClCmd_GunMenu( iPlayerID );
		case 10:	ClCmd_Rules( iPlayerID );
		case 11:	ClCmd_DisplayCredits( iPlayerID );
	}
}

ShowShopMenu( iPlayerID, iPage = 0 ) {
	if( !g_bAllowShop ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You are too late! You may only buy items from the shop at the beginning of the round.", g_strPluginPrefix );
	}
	
	static menuShopMenu;
	
	if( !menuShopMenu ) {
		new strMenuTitle[ 128 ];
		formatex( strMenuTitle, 127, "\rPowered by %s!^n\yJailBreak Shop Menu:^n", g_strPluginSponsor );
		
		menuShopMenu = menu_create( strMenuTitle, "Handle_ShopMenu" );
		
		new strOptionsShopMenu[ ][ ] = {
			"\wHE Grenade \y[\rexplosive\y]",
			"\wFLASH Grenade \y[\rblinding shit\y]",
			"\wSMOKE Grenade \y[\rfoggy atmosphere\y]",
			"\wHealth Kit \y[\rhere take 50 HP\y]",
			"\wAdvanced Health Kit \y[\rhere take 100 HP\y]",
			"\wArmor Jacket \y[\rhere take 100 AP\y]",
			"\wPrison Knife \y[\rprison made knife\y]",
			"\wOne Bullet Deagle \y[\rget that headshot\y]",
			"\wOne Bullet Scout \y[\rget that headshot\y]",
			"\wAssassin Steps \y[\rsound reducing choose\y]"
		};
		
		new strNum[ 8 ], strFormatex[ 256 ];
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsShopMenu ); iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			formatex( strFormatex, 255, "\y%i pts: %s", g_iOptionsPoints[ iLoop ], strOptionsShopMenu[ iLoop ] );
			menu_additem( menuShopMenu, strFormatex, strNum );
		}
		
		menu_setprop( menuShopMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuShopMenu, iPage );
}

public Handle_ShopMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT || !CheckBit( g_bitIsAlive, iPlayerID ) || cs_get_user_team( iPlayerID ) != CS_TEAM_T || !g_bAllowShop ) {
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	if( g_iPlayerPoints[ iPlayerID ] < g_iOptionsPoints[ iOption ] ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You do not have enough points to purchase this item.", g_strPluginPrefix );
	} else if( CheckBit( g_bitHasBought[ g_iOptionsShopGroup[ iOption ] ], iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have already bought an item from this group.", g_strPluginPrefix );
	} else if( g_iItemCout[ iOption ] >= g_iOptionsCount[ iOption ] ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 The item you are requesting is out of stock. Please try again next round.", g_strPluginPrefix );
	} else {
		g_iPlayerPoints[ iPlayerID ] -= g_iOptionsPoints[ iOption ];
		g_iPlayerSpentPoints[ iPlayerID ] += g_iOptionsPoints[ iOption ];
		SetBit( g_bitHasBought[ g_iOptionsShopGroup[ iOption ] ], iPlayerID );
		g_iItemCout[ iOption ]++;
		
		Event_Money( iPlayerID );
		
		switch( iOption ) {
			case ITEM_GRENADE_HE: {
				give_item( iPlayerID, "weapon_hegrenade" );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You now have a ^3HE Grenade^1. Use it wisely!", g_strPluginPrefix );
			}
			
			case ITEM_GRENADE_FLASH: {
				give_item( iPlayerID, "weapon_flashbang" );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You now have a ^3FLASH Grenade^1. Use it wisely!", g_strPluginPrefix );
			}
			
			case ITEM_GRENADE_SMOKE: {
				give_item( iPlayerID, "weapon_smokegrenade" );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You now have a ^3SMOKE Grenade^1. Use it wisely!", g_strPluginPrefix );
			}
			
			case ITEM_HEALTH_KIT: {
				set_user_health( iPlayerID, 150 );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You now have^3 50 extra HP^1!", g_strPluginPrefix );
			}
			
			case ITEM_AD_HEALTH_KIT: {
				set_user_health( iPlayerID, 200 );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You now have^3 100 extra HP^1!", g_strPluginPrefix );
			}
			
			case ITEM_ARMOR_JACKET: {
				cs_set_user_armor( iPlayerID, 100, CS_ARMOR_VESTHELM );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You now have^3 100 AP^1!", g_strPluginPrefix );
			}
			
			case ITEM_PRISON_KNIFE: {
				SetBit( g_bitHasPrisonKnife, iPlayerID );
				
				ham_strip_user_weapon( iPlayerID, CSW_KNIFE, 3, true );
				give_item( iPlayerID, "weapon_knife" );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You just forked a ^3prison knife^1. With that you get double damage!", g_strPluginPrefix );
			}
			
			case ITEM_DEAGLE: {
				StripPlayerWeapons( iPlayerID );
				
				cs_set_weapon_ammo( give_item( iPlayerID, "weapon_deagle" ), 1 );
				cs_set_user_bpammo( iPlayerID, CSW_DEAGLE, 0 );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You found a ^3DEAGLE with 1 bullet^1 under your bed, what are you going to do?", g_strPluginPrefix );
			}
			
			case ITEM_SCOUT: {
				StripPlayerWeapons( iPlayerID );
				
				cs_set_weapon_ammo( give_item( iPlayerID, "weapon_scout" ), 1 );
				cs_set_user_bpammo( iPlayerID, CSW_SCOUT, 0 );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You found a ^4SCOUT with 1 bullet^1 under your bed, what are you going to do?", g_strPluginPrefix );
			}
			
			case ITEM_SILENT_FOOTSTEPS: {
				set_user_footsteps( iPlayerID, 1 );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 'Run like the wind Bullseye'. Note: you will not make any sound.", g_strPluginPrefix );
			}
		}
	}
	
	ShowShopMenu( iPlayerID );
}

ShowFunMenu( iPlayerID ) {
	static menuFunMenu;
	
	if( !menuFunMenu ) {
		new strMenuTitle[ 64 ];
		formatex( strMenuTitle, 63, "\rPowered by %s!^n\yJailBreak Fun Menu:", g_strPluginSponsor );
		
		menuFunMenu = menu_create( strMenuTitle, "Handle_FunMenu" );
		
		new strOptionsFunMenu[ ][ ] = {
			"Roulette",
			"BlackJack",
			"Raffle",
			"Lottery"
		};
		
		new strNum[ 8 ];
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsFunMenu ); iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuFunMenu, strOptionsFunMenu[ iLoop ], strNum );
		}
		
		menu_setprop( menuFunMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuFunMenu, 0 );
}

public Handle_FunMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	switch( iOption ) {
		/* Roulette */
		case 0: {
			if( !CheckBit( g_bitHasUsedRoulette, iPlayerID ) ) {
				if( g_iPlayerPoints[ iPlayerID ] < FUN_ROULETTE_POINTS ) {
					client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to have at least ^4%i^1 points to play the ^3Roulette^1.", g_strPluginPrefix, FUN_ROULETTE_POINTS );
				} else {
					ShowRouletteMenu( iPlayerID );
				}
			} else {
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You have already used the ^4Roulette^1 this round.", g_strPluginPrefix );
				ShowFunMenu( iPlayerID );
				
				return;
			}
		}
		
		/* BlackJack */
		case 1: {
			client_cmd( iPlayerID, "blackjack" );
		}
		
		/* Raffle */
		case 2: {
			ClCmd_Raffle( iPlayerID );
		}
		
		/* Lottery */
		case 3: {
			// ShowLotteryMenu( iPlayerID );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Lottery is currently ^3under construction^1. Thank you for understanding!", g_strPluginPrefix );
		}
	}
}

ShowRouletteMenu( iPlayerID ) {
	static menuRouletteMenu;
	
	if( !menuRouletteMenu ) {
		new strMenuTitle[ 128 ];
		formatex( strMenuTitle, 127, "\rPowered by %s!^n\yJailBreak Roulette Menu:^n^n\rNote: win %i or loose %i points.", g_strPluginSponsor, FUN_ROULETTE_POINTS * 5, FUN_ROULETTE_POINTS );
		
		menuRouletteMenu = menu_create( strMenuTitle, "Handle_RouletteMenu" );
		
		new strNum[ 8 ];
		
		for( new iLoop = 1; iLoop <= FUN_ROULETTE_CHANCE; iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuRouletteMenu, strNum, strNum );
		}
		
		menu_setprop( menuRouletteMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuRouletteMenu, 0 );
}

public Handle_RouletteMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		ShowFunMenu( iPlayerID );
		
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, 31 );
	
	if( iOption == random_num( 1, FUN_ROULETTE_CHANCE ) ) {
		g_iPlayerPoints[ iPlayerID ] += ( 5 * FUN_ROULETTE_POINTS );
		Event_Money( iPlayerID );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 just won %i points in ^4Roulette^1. Open the ^4Fun Menu^1 and try your luck.", g_strPluginPrefix, strPlayerName, FUN_ROULETTE_POINTS );
	} else {
		g_iPlayerPoints[ iPlayerID ] -= FUN_ROULETTE_POINTS;
		Event_Money( iPlayerID );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 just lost %i points in ^4Roulette^1. What a tough luck!", g_strPluginPrefix, strPlayerName, FUN_ROULETTE_POINTS );
	}
	
	SetBit( g_bitHasUsedRoulette, iPlayerID );
}

/*ShowLotteryMenu( iPlayerID ) {
	static menuLotteryMenu[ MAX_PLAYERS + 1 ];
	
	new strMenuTitle[ 128 ];
	formatex( strMenuTitle, 127, "\rPowered by %s!^n\yJailBreak Lottery Menu:^n^n\rNote: pick 6 numbers, and if they get lucky you win %i points.", g_strPluginSponsor, FUN_LOTTERY_POINTS );
	
	menuLotteryMenu[ iPlayerID ] = menu_create( strMenuTitle, "Handle_LotteryMenu" );
	
	new strNum[ 8 ], strRandomNum[ 8 ];
	
	for( new iLoop = 1; iLoop <= FUN_LOTTERY_NUMBERS + 1; iLoop++ ) {
		num_to_str( iLoop, strNum, 7 );
		num_to_str( random_num( 1, 9 ), strRandomNum, 7 );
		
		if( iLoop > FUN_LOTTERY_NUMBERS ) {
			menu_additem( menuLotteryMenu[ iPlayerID ], "Submit", strNum );
		} else {
			menu_additem( menuLotteryMenu[ iPlayerID ], strRandomNum, strNum );
		}
	}
	
	menu_display( iPlayerID, menuLotteryMenu[ iPlayerID ], 0 );
}*/

/*public Handle_LotteryMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		ShowFunMenu( iPlayerID );
		
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	switch( iOption ) {
		case 1..6:	RotateRight( g_iPlayerLotteryNumbers[ iOption ] );
		case 7:		// to continue
	}
}*/

ShowVIPMenu( iPlayerID ) {
	static menuVIPMenu;
	
	if( !menuVIPMenu ) {
		new strMenuTitle[ 128 ];
		formatex( strMenuTitle, 127, "\rPowered by %s!^n\yJailBreak VIP Menu:^n", g_strPluginSponsor );
		
		menuVIPMenu = menu_create( strMenuTitle, "Handle_VIPMenu" );
		
		new strNum[ 8 ];
		
		new strOptionsVIPMenu[ ][ ] = {
			"\wVIP Knives",
			"\wT Models",
			"\wCT Models"
		};
		
		/*new strOptionsVIPMenu[ ][ ] = {
			"\rKNIFE: \wFists",
			"\rKNIFE: \wBlue Light Saber",
			"\rKNIFE: \wDaedric",
			"\rKNIFE: \wMachete",
			"\rKNIFE: \wKatana^n",
			"\rSKIN: \wNormal",
			"\rSKIN: \wHitman",
			"\rSKIN: \wLara Croft",
			"\rSKIN: \wPayday2"
		};*/
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsVIPMenu ); iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuVIPMenu, strOptionsVIPMenu[ iLoop ], strNum );
		}
		
		menu_setprop( menuVIPMenu, MPROP_NUMBER_COLOR, "\y" );
		menu_setprop( menuVIPMenu, MPROP_PERPAGE, 0 );
	}
	
	menu_display( iPlayerID, menuVIPMenu, 0 );
}

public Handle_VIPMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT || !CheckBit( g_bitIsAlive, iPlayerID ) || !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	switch( iOption ) {
		case 0: {
			ShowVIPKnifeMenu( iPlayerID );
		}
		
		case 1: {
			ShowVIPTModelMenu( iPlayerID );
		}
		
		case 2: {
			ShowVIPCTModelMenu( iPlayerID );
		}
	}
	
	/*if( iOption > 4 && cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3Prisoner^1 in order to choose that option.", g_strPluginPrefix );
		
		ShowVIPMenu( iPlayerID );
		return;
	}
	
	switch( iOption ) {
		case 0, 1, 2, 3, 4: {
			g_iPlayerKnife[ iPlayerID ] = iOption;
			
			ham_strip_user_weapon( iPlayerID, CSW_KNIFE, 3, true );
			give_item( iPlayerID, "weapon_knife" );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now have a unique ^3VIP knife^1.", g_strPluginPrefix );
		}
		
		case 5:	{
			cs_set_user_team( iPlayerID, CS_TEAM_T, CS_T_LEET );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3Normal Prisoner^1.", g_strPluginPrefix );
		}
		
		case 6: {
			cs_set_user_team( iPlayerID, CS_TEAM_T, CS_T_ARCTIC );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3Hitman^1.", g_strPluginPrefix );
		}
		
		case 7: {
			cs_set_user_team( iPlayerID, CS_TEAM_T, CS_T_GUERILLA );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3HLara Croft^1.", g_strPluginPrefix );
		}
		
		case 8: {
			cs_set_user_team( iPlayerID, CS_TEAM_T, CS_T_TERROR );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3Payday2 Bank Robber^1.", g_strPluginPrefix );
		}
	}*/
}

ShowVIPKnifeMenu( iPlayerID ) {
	static menuVIPKnife;
	
	if( !menuVIPKnife ) {
		new strMenuTitle[ 128 ];
		formatex( strMenuTitle, 127, "\rPowered by %s!^n\yJailBreak Knife VIP Menu:^n", g_strPluginSponsor );
		
		menuVIPKnife = menu_create( strMenuTitle, "Handle_VIPKnifeMenu" );
		
		new strNum[ 8 ];
		
		new strOptionsVIPKnifeMenu[ ][ ] = {
			"\rKNIFE: \wFists",
			"\rKNIFE: \wBlue Light Saber",
			"\rKNIFE: \wDaedric",
			"\rKNIFE: \wMachete",
			"\rKNIFE: \wKatana^n"
		};
		
		/*new strOptionsVIPMenu[ ][ ] = {
			"\rKNIFE: \wFists",
			"\rKNIFE: \wBlue Light Saber",
			"\rKNIFE: \wDaedric",
			"\rKNIFE: \wMachete",
			"\rKNIFE: \wKatana^n",
			"\rSKIN: \wNormal",
			"\rSKIN: \wHitman",
			"\rSKIN: \wLara Croft",
			"\rSKIN: \wPayday2"
		};*/
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsVIPKnifeMenu ); iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuVIPKnife, strOptionsVIPKnifeMenu[ iLoop ], strNum );
		}
		
		menu_setprop( menuVIPKnife, MPROP_NUMBER_COLOR, "\y" );
		menu_setprop( menuVIPKnife, MPROP_PERPAGE, 0 );
	}
	
	menu_display( iPlayerID, menuVIPKnife, 0 );
}

public Handle_VIPKnifeMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT || !CheckBit( g_bitIsAlive, iPlayerID ) || !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	g_iPlayerKnife[ iPlayerID ] = iOption;
	
	ham_strip_user_weapon( iPlayerID, CSW_KNIFE, 3, true );
	give_item( iPlayerID, "weapon_knife" );
	
	if( iOption ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now have a unique ^3VIP knife^1.", g_strPluginPrefix );
	}
}

ShowVIPTModelMenu( iPlayerID ) {
	static menuVIPTModel;
	
	if( !menuVIPTModel ) {
		new strMenuTitle[ 128 ];
		formatex( strMenuTitle, 127, "\rPowered by %s!^n\yJailBreak T Model VIP Menu:^n", g_strPluginSponsor );
		
		menuVIPTModel = menu_create( strMenuTitle, "Handle_VIPTModelMenu" );
		
		new strNum[ 8 ];
		
		new strOptionsVIPTModelMenu[ ][ ] = {
			"\rSKIN: \wNormal",
			"\rSKIN: \wHitman",
			"\rSKIN: \wLara Croft",
			"\rSKIN: \wPayday2"
		};
		
		/*new strOptionsVIPMenu[ ][ ] = {
			"\rKNIFE: \wFists",
			"\rKNIFE: \wBlue Light Saber",
			"\rKNIFE: \wDaedric",
			"\rKNIFE: \wMachete",
			"\rKNIFE: \wKatana^n",
			"\rSKIN: \wNormal",
			"\rSKIN: \wHitman",
			"\rSKIN: \wLara Croft",
			"\rSKIN: \wPayday2"
		};*/
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsVIPTModelMenu ); iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuVIPTModel, strOptionsVIPTModelMenu[ iLoop ], strNum );
		}
		
		menu_setprop( menuVIPTModel, MPROP_NUMBER_COLOR, "\y" );
		menu_setprop( menuVIPTModel, MPROP_PERPAGE, 0 );
	}
	
	menu_display( iPlayerID, menuVIPTModel, 0 );
}

public Handle_VIPTModelMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT || !CheckBit( g_bitIsAlive, iPlayerID ) || !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_T ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3Prisoners^1 in order to access this menu.", g_strPluginPrefix );
		
		return;
	}
	
	switch( iOption ) {
		case 0:	{
			cs_set_user_team( iPlayerID, CS_TEAM_T, CS_T_LEET );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3Normal Prisoner^1.", g_strPluginPrefix );
		}
		
		case 1: {
			cs_set_user_team( iPlayerID, CS_TEAM_T, CS_T_ARCTIC );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3Hitman^1.", g_strPluginPrefix );
		}
		
		case 2: {
			cs_set_user_team( iPlayerID, CS_TEAM_T, CS_T_GUERILLA );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3HLara Croft^1.", g_strPluginPrefix );
		}
		
		case 3: {
			cs_set_user_team( iPlayerID, CS_TEAM_T, CS_T_TERROR );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3Payday2 Bank Robber^1.", g_strPluginPrefix );
		}
	}
}

ShowVIPCTModelMenu( iPlayerID ) {
	static menuVIPCTModel;
	
	if( !menuVIPCTModel ) {
		new strMenuTitle[ 128 ];
		formatex( strMenuTitle, 127, "\rPowered by %s!^n\yJailBreak CT Model VIP Menu:^n", g_strPluginSponsor );
		
		menuVIPCTModel = menu_create( strMenuTitle, "Handle_VIPCTModelMenu" );
		
		new strNum[ 8 ];
		
		new strOptionsVIPCTModelMenu[ ][ ] = {
			"\rSKIN: \wNormal",
			"\rSKIN: \wModel 1",
			"\rSKIN: \wModel 2",
			"\rSKIN: \wModel 3"
		};
		
		/*new strOptionsVIPMenu[ ][ ] = {
			"\rKNIFE: \wFists",
			"\rKNIFE: \wBlue Light Saber",
			"\rKNIFE: \wDaedric",
			"\rKNIFE: \wMachete",
			"\rKNIFE: \wKatana^n",
			"\rSKIN: \wNormal",
			"\rSKIN: \wHitman",
			"\rSKIN: \wLara Croft",
			"\rSKIN: \wPayday2"
		};*/
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsVIPCTModelMenu ); iLoop++ ) {
			num_to_str( iLoop, strNum, 7 );
			
			menu_additem( menuVIPCTModel, strOptionsVIPCTModelMenu[ iLoop ], strNum );
		}
		
		menu_setprop( menuVIPCTModel, MPROP_NUMBER_COLOR, "\y" );
		menu_setprop( menuVIPCTModel, MPROP_PERPAGE, 0 );
	}
	
	menu_display( iPlayerID, menuVIPCTModel, 0 );
}

public Handle_VIPCTModelMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT || !CheckBit( g_bitIsAlive, iPlayerID ) || !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, 7, _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be a ^3Guard^1 in order to access this menu.", g_strPluginPrefix );
		
		return;
	}
	
	switch( iOption ) {
		case 0:	{
			cs_set_user_team( iPlayerID, CS_TEAM_CT, CS_CT_GIGN );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3Normal Guard^1.", g_strPluginPrefix );
		}
		
		case 1: {
			cs_set_user_team( iPlayerID, CS_TEAM_CT, CS_CT_URBAN );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3Model 1^1.", g_strPluginPrefix );
		}
		
		case 2: {
			cs_set_user_team( iPlayerID, CS_TEAM_CT, CS_CT_SAS );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3Model 2^1.", g_strPluginPrefix );
		}
		
		case 3: {
			cs_set_user_team( iPlayerID, CS_TEAM_CT, CS_CT_GSG9 );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Enjoy, you now look like ^3Model 3^1.", g_strPluginPrefix );
		}
	}
}

ShowGameBookMenu( iPlayerID ) {
	new strMenuTitle[ 128 ];
	formatex( strMenuTitle, 127, "\rPowered by %s!^n\yJailBreak Game Book:^n^n\rNote: \ypress any number to exit.", g_strPluginSponsor );
	
	new menuGameBook = menu_create( strMenuTitle, "Handle_GameBookMenu" );
	
	new strOptionsGameBook[ ][ ] = {
		"\rWeapon Toss: \wwhoever throws the deagle the^nfurthest/closest wins.",
		"\rClosest Weapon Toss: \wwhoever throws as close^nto your deagle as possible wins.",
		"\rSpray Contest: \wwhoever sprays the highest/lowest^nwins.",
		"\rClosest Spray: \wwhoever sprays as close to your^nspray as possible wins.",
		"\rFind The Weapon: \wwhoever finds the hidden weapon^nwins.",
		"\rTeam Race: \wthe team that finishes first wins.",
		"\rTower Race: \wthe team (tower) that finishes^nfirst wins.",
		"\rSuccessive Commands: \wyou give commands and^nthe prisoners follow them in line (a prisoner^ncan do only one command).",
		"\rOdd Man Out: \wall prisoners can either crouch or^nstand up. If one guy is doing the specific^ncommand and others the opposite, he dies.",
		"\rCopy Cat: \wall prisoners copy everything the copy^ncat does (you pick him).",
		"\rMemory Game: \wthey have to the previous^ncommands with the new one with no mistakes.",
		"\rOlympic Race: \wrace with several parts.",
		"\rWhere is the line: \wyou make a line on the^nfloor and the prisoners have to go^nbackwards while looking up and estimate its positon.",
		"\rWave: \wprisoners do a wave, the one who^nbreaks the wave dies.",
		"\rParkour: \wthe prisoners make a race with^nseveral jumps and obsticales.",
		"\rGuess The Shape: \wyou draw something on^nthe wall, whoever guess it wins.",
		"\rTalent: \wthe prisoner with the most impressive^ntalent wins last request.",
		"\rQuestions Game: \wSpelling Bee; Trivia; School;^nAnagram; True or False;^nSaw Game; Fill In The Blanks."
	};
	
	new strNum[ 8 ], strFormatex[ 512 ];
	
	for( new iLoop = 0; iLoop < sizeof( strOptionsGameBook ); iLoop++ ) {
		num_to_str( iLoop, strNum, 7 );
		
		formatex( strFormatex, 511, strOptionsGameBook[ iLoop ] );
		menu_additem( menuGameBook, strFormatex, strNum );
	}
	
	menu_setprop( menuGameBook, MPROP_NUMBER_COLOR, "\y" );
	menu_setprop( menuGameBook, MPROP_PERPAGE, 3 );
	
	menu_display( iPlayerID, menuGameBook, 0 );
}

public Handle_GameBookMenu( iPlayerID, iMenu, iKey ) {
	menu_destroy( iMenu );
}

/* Tasks */
public Task_Menu_DayMenu( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 0 ) {
		ShowDayMenu( );
	} else {
		EndDayMenu( );
	}
}

public Task_Menu_FreeDay( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 0 ) {
		ShowFreeDayMenu( );
	} else {
		EndFreeDayMenu( );
	}
}

public Task_Menu_NC( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 0 ) {
		ShowNightCrawlerMenu( );
	} else {
		EndNightCrawlerMenu( );
	}
}

public Task_Menu_Zombie( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 0 ) {
		ShowZombieMenu( );
	} else {
		EndZombieMenu( );
	}
}

public Task_Menu_Shark( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 0 ) {
		ShowSharkMenu( );
	} else {
		EndSharkMenu( );
	}
}

public Task_RoundEnded( ) {
	ResetAll( );
	
	g_iTypeFreeDay = UNRESTRICTED;
	StartFreeDay( );
	
	client_print_color( 0, print_team_red, "^4%s^1 Round timer is now ^30:00^1. Day changed to ^4Unrestricted FreeDay^1.", g_strPluginPrefix );
}

public Task_CountDown_NC( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 5 ) {
		set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time is over! %s eliminate the opposing team!", g_iTypeNightCrawler == REGULAR ? "Guards" : "Prisoners" );
		
		new iPlayers[ 32 ], iNum, iTempID;
		get_players( iPlayers, iNum, "ae", g_iTypeNightCrawler == REGULAR ? "TERRORIST" : "CT" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			set_user_rendering( iTempID );
			set_user_footsteps( iTempID, 0 );
		}
		
		if( task_exists( TASK_COUNTDOWN_NC ) ) remove_task( TASK_COUNTDOWN_NC );
		
		client_print_color( 0, g_iTypeNightCrawler == REGULAR ? print_team_red : print_team_blue, "^4%s^1 The ^3%s^1 are now visible. FIND THEM!", g_strPluginPrefix, g_iTypeNightCrawler == REGULAR ? "Prisoners" : "Guards" );
		PlaySound( 0, SOUND_NIGHTCRAWLER );
		
		if( g_iTypeNightCrawler == REVERSED ) OpenCells( );
	}
}

public Task_CountDown_Shark( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 5 ) {
		set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft > 0 ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else if( !g_iTimeLeft ) {
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time is over! %s eliminate the opposing team!", g_iTypeShark == REGULAR ? "Guards" : "Prisoners" );
		
		new iPlayers[ 32 ], iNum, iTempID;
		get_players( iPlayers, iNum, "ae", g_iTypeShark == REGULAR ? "TERRORIST" : "CT" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			set_user_rendering( iTempID );
			set_user_footsteps( iTempID, 0 );
		}
		
		client_print_color( 0, g_iTypeNightCrawler == REGULAR ? print_team_red : print_team_blue, "%s The %s are now visible. FIND THEM!", g_strPluginPrefix, g_iTypeNightCrawler == REGULAR ? "Prisoners" : "Guards" );
		PlaySound( 0, SOUND_NIGHTCRAWLER );
	}
}

public Task_CountDown_Samurai( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 10 ) {
		set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time Left: %i Seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft > 0 ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time Left: %i Seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time is Over! Officers eliminate the opposing team!" );
		
		new iPlayers[ 32 ], iNum, iTempID;
		get_players( iPlayers, iNum, "ae", "TERRORIST" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			set_user_rendering( iTempID );
			set_user_footsteps( iTempID, 0 );
		}
		
		PlaySound( 0, SOUND_SAMURAI2 );
	}
}

public Task_CountDown_HNS( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 10 ) {
		set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time Left: %i Seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft > 0 ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time Left: %i Seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time is Over! Officers eliminate the opposing team!" );
		
		new iPlayers[ 32 ], iNum, iTempID;
		get_players( iPlayers, iNum, "ae", "TERRORIST" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			set_user_rendering( iTempID );
			set_user_footsteps( iTempID, 0 );
		}
		
		/*
			Multiple calls so the sound becomes louder.
		*/
		PlaySound( 0, SOUND_HNS );
		PlaySound( 0, SOUND_HNS );
		PlaySound( 0, SOUND_HNS );
		PlaySound( 0, SOUND_HNS );
	}
}

public Task_CountDown_Mario( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 10 ) {
		set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time Left: %i Seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft > 0 ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time Left: %i Seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Time is Over! Prisoners start killing!" );
	}
}

public Task_CountDown_Race( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 3 ) {
		set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Race will start in: %i seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft > 0 ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Race will start in: %i seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Go Go Go!", g_iTimeLeft );
		
		client_cmd( 0, "spk ^"radio/com_go^"" );
	}
}

public Task_CountDown_HotPotato( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 3 ) {
		set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Hot Potato will start in: %i seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft > 0 ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Hot Potato will start in: %i seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Hot Potato has now started!", g_iTimeLeft );
		
		g_bHotPotatoStarted = true;
		g_iLastPickup = g_iLastRequest[ PLAYER_OFFICER ];
		
		set_task( TIME_HOTPOTATO, "Task_SlayLooser", TASK_SLAYLOOSER );
	}
}

public Task_CountDown_Commander( ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 3 ) {
		set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Commander countdown: %i seconds left!", g_iTimeLeft );
	} else if( g_iTimeLeft > 0 ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Commander countdown: %i seconds left!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Go Go Go!", g_iTimeLeft );
		
		client_cmd( 0, "spk ^"radio/com_go.wav^"" );
	}
}

public Task_CountDown_CommanderMath( strEquation[ ], iTaskID ) {
	g_iTimeLeft--;
	
	if( g_iTimeLeft > 3 ) {
		static strFunnyMathSituation[ ][ ] = {
			"I will ask you a math question",
			"I'm the king of math, hit me :)",
			"What is 1+1 equal to?",
			"Pffft, thats obviously 22",
			"Wrong! It's 2 you idiot...",
			"OMG fuck my keyboard",
			"Always blame the keyoard :D"
		};
		
		static iCount;
		if( iCount == 7 ) {
			iCount = 0;
		}
		
		if( iCount % 2 == 0 ) {
			set_hudmessage( 170, 0, 150, .channel = CHANNEL_COUNTDOWN );
		} else {
			set_hudmessage( 75, 75, 255, .channel = CHANNEL_COUNTDOWN );
		}
		
		show_hudmessage( 0, strFunnyMathSituation[ iCount ] );
		console_print( 0, strFunnyMathSituation[ iCount++ ] );
		
		if( g_iTimeLeft > 3 ) {
			set_hudmessage( 0, 255, 0, _, _, _, 1.0, 1.0, _, _, CHANNEL_OTHER );
			show_hudmessage( 0, "^nMath question in %i...", g_iTimeLeft );
			console_print( 0, "Math question in %i...", g_iTimeLeft );
		}
	} else if( g_iTimeLeft > 0 ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Math question in %i...", g_iTimeLeft );
		console_print( 0, "Math question in %i...", g_iTimeLeft );
	} else {
		g_bCatchAnswer = true;
		
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, strEquation );
		console_print( 0, strEquation );
	}
}

public Task_President_GiveWeapons( ) {
	if( g_iCurrentDay != DAY_PRESIDENT ) {
		return;
	}
	
	client_print_color( 0, print_team_red, "^4%s^1 The ^3Prisoners^1 now have guns.", g_strPluginPrefix );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		ShowWeaponMenu( iTempID );
	}
	
	OpenCells( );
}

public Task_AllowWeaponUsage( ) {
	if( g_bDayInProgress && g_iCurrentDay == DAY_HNS ) {
		g_bAllowHNSWeapons = true;
		
		client_print_color( 0, print_team_red, "^4%s^3 Prisoners ^1can now use guns. Be careful!", g_strPluginPrefix );
	}
}

public Task_GiveNades( ) {
	if( g_iCurrentDay != DAY_NADEWAR ) {
		return;
	}
	
	SetFreeForAll( 1 );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		StripPlayerWeapons( iPlayers[ iLoop ] );
	}
	
	set_task( 0.1, "Task_NadeWar", TASK_NADEWAR_GIVEGRENADE, _, _, "b" );
	
	PlaySound( 0, SOUND_NADEWAR );
}

public Task_NadeWar( ) {
	static iPlayers[ 32 ], iNum, iTempID, iLoop;
	get_players( iPlayers, iNum, "a" );
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		if( !user_has_weapon( iTempID, CSW_HEGRENADE ) ) {
			give_item( iTempID, "weapon_hegrenade" );
		}
	}
}

public Task_SmashOfficers( ) {
	static iPlayers[ 32 ], iNum, iTempID, iLoop;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	g_bHulkSmash = true;
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		message_begin( MSG_ONE, g_msgScreenShake, { 0, 0, 0 }, iTempID );
		write_short( 255 << 14 );
		write_short( 10 << 14 );
		write_short( 255 << 14 );
		message_end( );
		
		set_pev( iTempID, pev_maxspeed, 1.0 );
	}
	
	PlaySound( 0, SOUND_HULK );
	
	set_task( 5.0, "Task_RemoveSmash" );
}

public Task_RemoveSmash( ) {
	static iPlayers[ 32 ], iNum, iLoop;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	g_bHulkSmash = false;
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		ExecuteHamB( Ham_CS_Player_ResetMaxSpeed, iPlayers[ iLoop ] );
	}
}

public Task_LMS_GiveWeapons( ) {
	if( g_iCurrentDay != DAY_LMS ) {
		return;
	}
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	set_pcvar_num( g_cvarFriendlyFire, 1 );
	SetFreeForAll( 1 );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		set_user_health( iTempID, LMS_HEALTH_T );
		cs_set_user_armor( iTempID, LMS_ARMOR_T, CS_ARMOR_VESTHELM );
		
		SetBit( g_bitHasUnAmmo, iTempID );
	}
	
	Task_LMS_GiveOrderedWeapons( );
	set_task( LMS_WEAPON_INTERVAL, "Task_LMS_GiveOrderedWeapons", TASK_LMS_GIVEWORDEREDEAPONS, _, _, "b" );
}

public Task_LMS_GiveOrderedWeapons( ) {
	if( g_iLMSCurrentWeapon == LMS_WPN_NBR ) {
		if( task_exists( TASK_LMS_GIVEWORDEREDEAPONS ) ) remove_task( TASK_LMS_GIVEWORDEREDEAPONS );
		
		client_print_color( 0, print_team_red, "^4%s ^3Prisoners ^1can now use any weapons they can find!", g_strPluginPrefix );
		
		g_iLMSCurrentWeapon = 0;
		g_bLMSWeaponsOver = true;
		
		return;
	}
	
	static iLMSWeaponAmmo[ LMS_WPN_NBR ] = {
		CSW_GLOCK18,
		CSW_USP,
		CSW_DEAGLE,
		CSW_M3,
		CSW_XM1014,
		CSW_SCOUT,
		CSW_MP5NAVY,
		CSW_FAMAS,
		CSW_GALIL,
		CSW_AWP,
		CSW_AK47,
		CSW_M4A1,
		CSW_KNIFE
	};
	
	static iLMSWeaponMaxAmmo[ LMS_WPN_NBR ] = {
		120,		// CSW_GLOCK18
		100,		// CSW_USP
		35,		// CSW_DEAGLE
		32,		// CSW_M3
		32,		// CSW_XM1014
		90,		// CSW_SCOUT
		120,		// CSW_MP5NAVY
		90,		// CSW_FAMAS
		90,		// CSW_GALIL
		30,		// CSW_AWP
		90,		// CSW_AK47
		90,		// CSW_M4A1
		-1		// CSW_KNIFE
	};
	
	static iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		give_item( iTempID, g_strLMSWeaponOrder[ g_iLMSCurrentWeapon ] );
		
		if( g_iLMSCurrentWeapon != ( LMS_WPN_NBR - 1 ) ) {
			cs_set_user_bpammo( iTempID, iLMSWeaponAmmo[ g_iLMSCurrentWeapon ], iLMSWeaponMaxAmmo[ g_iLMSCurrentWeapon ] );
		}
	}
	
	g_iLMSCurrentWeapon++;
}

public Task_Showdown( ) {
	static iShowdownCount = 0;
	
	switch( ++iShowdownCount ) {
		case 1: {
			client_print( g_iLastRequest[ PLAYER_OFFICER ], print_center, "Walk!" );
			client_print( g_iLastRequest[ PLAYER_PRISONER ], print_center, "Walk!" );
		}
		
		case 2: {
			client_print( g_iLastRequest[ PLAYER_OFFICER ], print_center, "Draw!" );
			client_print( g_iLastRequest[ PLAYER_PRISONER ], print_center, "Draw!" );
		}
		
		case 3: {
			client_print( g_iLastRequest[ PLAYER_OFFICER ], print_center, "Shoot!" );
			client_print( g_iLastRequest[ PLAYER_PRISONER ], print_center, "Shoot!" );
			
			iShowdownCount = 0;
			
			return;
		}
	}
	
	set_task( random_float( 3.0, 5.0 ), "Task_Showdown", TASK_SHOWDOWN );
}

public Task_SlayLooser( ) {
	if( !g_bLRInProgress ) {
		return;
	}
	
	new iOfficer = g_iLastRequest[ PLAYER_OFFICER ];
	
	if( g_iLastPickup == iOfficer ) {
		ExecuteHamB( Ham_Killed, g_iLastPickup, g_iLastRequest[ PLAYER_PRISONER ], 0 );
	} else {
		ExecuteHamB( Ham_Killed, g_iLastPickup, iOfficer, 0 );
	}
}

public Task_UnglowRandomPlayer( iTaskID ) {
	new iPlayerID = iTaskID - TASK_UNGLOW_PLAYER;
	
	if( CheckBit( g_bitIsConnected, iPlayerID ) ) {
		set_user_rendering( iPlayerID );
	}
}

/*public Task_HNDDangerMeter( ) {
	static iPlayers[ 32 ], iNum, iTempID, iLoop;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	static Float:fPercent, strDirection[ 32 ], iColor[ 3 ];
	static Float:fFrom[ 3 ], Float:fOrigin[ 3 ], Float:fAngles[ 3 ];
	static iCloser, iFlags;
	iCloser = 0;
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		fPercent = CheckPlayerDanger( iTempID, MAX_DANGER_RANGE, iCloser );
		
		if( !iCloser ) {
			return;
		}
		
		strDirection[ 0 ] = '^0';
		
		pev( iCloser, pev_origin, fFrom );
		pev( iTempID, pev_origin, fOrigin );
		pev( iTempID, pev_angles, fAngles );
		
		iFlags = DamageDirection( fOrigin, fAngles, fFrom );
		
		if( !iFlags ) {
			strDirection = "UNKNOWN";
		} else {
			if( iFlags & ATTACK_FRONT ) 		add( strDirection, 31, "FRONT " );
			else if( iFlags & ATTACK_BACK ) 	add( strDirection, 31, "BACK " );
			if(  iFlags & ATTACK_LEFT  ) 		add( strDirection, 31, "LEFT" );
			else if(  iFlags & ATTACK_RIGHT  ) 	add( strDirection, 31, "RIGHT" );
		}
		
		GetPercentColor( floatround( fPercent ), iColor );
		
		set_hudmessage( iColor[ 0 ], iColor[ 1 ], iColor[ 2 ], -1.0, 0.8, 0, 0.1, HNS_DANGER_METER, 0.1, 0.1, CHANNEL_HEALTH );
		show_hudmessage( iTempID, "Danger Meter: %.1f%%^nDirection: %s", fPercent, strDirection );
	}
}*/

public Task_TeamJoin( iParameters[ ], iTaskID ) {
	new iPlayerID = iTaskID - TASK_TEAMJOIN;
	
	new iMessageID = iParameters[ 0 ];
	new iMessageBlock = get_msg_block( iMessageID );
	set_msg_block( iMessageID, BLOCK_SET );
	
	static strTeam[ 2 ];
	
	switch( cs_get_user_team( iPlayerID ) ) {
		case CS_TEAM_T:		strTeam = "2";
		case CS_TEAM_CT:	strTeam = "1";
		case CS_TEAM_SPECTATOR:	strTeam = TEAMJOIN_TEAM;
		case CS_TEAM_UNASSIGNED:strTeam = TEAMJOIN_TEAM;
	}
	
	g_bPluginCommand = true;
	
	engclient_cmd( iPlayerID, "jointeam", strTeam );
	engclient_cmd( iPlayerID, "joinclass", TEAMJOIN_CLASS );
	
	g_bPluginCommand = false;
	
	set_msg_block( iMessageID, iMessageBlock );
}

public Task_NotifyMenu( iParameters[ ] ) {
	client_print_color( iParameters[ 0 ], print_team_red, "^4%s^1 Press the ^3team menu^1 button ^4(default M)^1 to open the ^4Main Menu^1.", g_strPluginPrefix );
}

public Task_GiveDodgeBall( iTaskID ) {
	if( !g_bDodgeBall ) {
		return;
	}
	
	set_task( 0.1, "Task_Dodgeball", TASK_DODGEBALL_NADES, _, _, "b" );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		StripPlayerWeapons( iPlayers[ iLoop ] );
	}
	
	PlaySound( 0, SOUND_NADEWAR );
}

public Task_Dodgeball( iTaskID ) {
	if( !g_bDodgeBall ) {
		remove_task( iTaskID );
	}
	
	static iPlayers[ 32 ], iNum, iTempID, iLoop;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	if( iNum < 2 ) {
		g_bDodgeBall = false;
	}
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		if( !user_has_weapon( iTempID, CSW_SMOKEGRENADE ) ) {
			give_item( iTempID, "weapon_hegrenade" );
		}
	}
}

public Task_DisableShopBuying( ) {
	if( g_bAllowShop ) {
		g_bAllowShop = false;
	}
}

/* Days */
public StartDay( ) {
	switch( g_iCurrentDay ) {
		case DAY_CAGE:		StartCageDay( );
		case DAY_RIOT:		StartRiotDay( );
		case DAY_PRESIDENT:	StartPresidentDay( );
		case DAY_USP_NINJA:	StartUSPNinjaDay( );
		case DAY_NADEWAR:	StartNadeWarDay( );
		case DAY_HULK:		StartHulkDay( );
		case DAY_SPACE:		StartSpaceDay( );
		case DAY_COWBOY:	StartCowboyDay( );
		case DAY_LMS:		StartLMSDay( );
		case DAY_SAMURAI:	StartSamuraiDay( );
		case DAY_KNIFE:		StartKnifeDay( );
		case DAY_JUDGEMENT:	StartJudgementDay( );
		case DAY_HNS:		StartHNSDay( );
		case DAY_MARIO:		StartMarioDay( );
		case DAY_CUSTOM:	StartCustomDay( );
		
		case DAY_FREE: {
			StartFreeDayVote( );
			
			return;
		}
		
		case DAY_NIGHTCRAWLER: {
			StartNightCrawlerVote( );
			
			return;
		}
		
		case DAY_ZOMBIE: {
			StartZombieVote( );
			
			return;
		}
		
		case DAY_SHARK: {
			StartSharkVote( );
			
			return;
		}
		
		default: return;
	}
	
	ShowDHUDMessage( g_strObjectivesDayMenu[ g_iCurrentDay ] );
	g_bDayInProgress = true;
}

StartFreeDay( ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		ShowWeaponMenu( iPlayers[ iLoop ] );
	}

	if( g_iTypeFreeDay == RESTRICTED ) {
		ShowDHUDMessage( g_strObjectivesDayMenu[ DAY_FREE ] );
	} else {
		ShowDHUDMessage( g_strObjectivesDayMenuReversed[ DAY_FREE ] );
	}
	
	ShowTopInfo( );
}

StartCageDay( ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		ShowWeaponMenu( iPlayers[ iLoop ] );
	}
	
	set_task( 45.0, "Task_DisableShopBuying", TASK_DISABLESHOP );
	
	ShowTopInfo( );
}

StartNightCrawlerDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	switch( g_iTypeNightCrawler ) {
		case REGULAR: {
			new iPlayersT[ 32 ], iNumT;
			get_players( iPlayersT, iNumT, "ae", "TERRORIST" );
			
			new iHealth = NC_HEALTH1_CT * iNumT;
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				StripPlayerWeapons( iTempID );
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_T: {
						ShowWeaponMenu( iTempID );
						
						cs_set_user_armor( iTempID, 100, CS_ARMOR_VESTHELM );
						SetBit( g_bitHasUnAmmo, iTempID );
					}
					
					case CS_TEAM_CT: {
						set_user_health( iTempID, iHealth );
						cs_set_user_armor( iTempID, 100, CS_ARMOR_VESTHELM );
					}
				}
				
				set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
				set_user_footsteps( iTempID, 1 );
			}
			
			ShowDHUDMessage( g_strObjectivesDayMenu[ DAY_NIGHTCRAWLER ] );
			OpenCells( );
		}
		
		case REVERSED: {
			new iPlayersT[ 32 ], iNumT;
			get_players( iPlayersT, iNumT, "ae", "TERRORIST" );
			
			new iHealth = NC_HEALTH2_CT * iNumT;
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
				set_user_footsteps( iTempID, 1 );
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_CT: {
						ShowWeaponMenu( iTempID );
						
						set_user_health( iTempID, iHealth );
						cs_set_user_armor( iTempID, NC_ARMOR2_CT, CS_ARMOR_VESTHELM );
						SetBit( g_bitHasUnAmmo, iTempID );
					}
					
					case CS_TEAM_T: {
						StripPlayerWeapons( iTempID );
						
						cs_set_user_armor( iTempID, NC_ARMOR2_T, CS_ARMOR_VESTHELM );
						
						set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesDayMenuReversed[ DAY_NIGHTCRAWLER ] );
		}
	}
	
	ShowTopInfo( );
	g_bDayInProgress = true;
	set_lights( "b" );
	
	g_iTimeLeft = TIME_COUNTDOWN_NC;
	set_task( 1.0, "Task_CountDown_NC", TASK_COUNTDOWN_NC, _, _, "a", g_iTimeLeft );
}

StartZombieDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	switch( g_iTypeZombie ) {
		case REGULAR: {
			new iPlayersCT[ 32 ], iNumCT;
			get_players( iPlayersCT, iNumCT, "ae", "CT" );
			
			new iHealth = ZOMBIE_HEALTH1_T * iNumCT;
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_T: {
						StripPlayerWeapons( iTempID );
						
						set_user_rendering( iTempID, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
						
						set_user_health( iTempID, iHealth );
						cs_set_user_armor( iTempID, ZOMBIE_ARMOR1_T, CS_ARMOR_VESTHELM );
					}
					
					case CS_TEAM_CT: {
						ShowWeaponMenu( iTempID );
						
						cs_set_user_armor( iTempID, ZOMBIE_ARMOR1_CT, CS_ARMOR_VESTHELM );
						SetBit( g_bitHasUnAmmo, iTempID );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesDayMenu[ g_iCurrentDay ] );
		}
		
		case REVERSED: {
			new iPlayersT[ 32 ], iNumT;
			get_players( iPlayersT, iNumT, "ae", "TERRORIST" );
			
			new iHealth = ZOMBIE_HEALTH2_CT * iNumT;
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_T: {
						ShowWeaponMenu( iTempID );
						
						cs_set_user_armor( iTempID, ZOMBIE_ARMOR2_T, CS_ARMOR_VESTHELM );
						
						SetBit( g_bitHasUnAmmo, iTempID );
					}
					
					case CS_TEAM_CT: {
						StripPlayerWeapons( iTempID );
						
						set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 5 );
						
						set_user_health( iTempID, iHealth );
						cs_set_user_armor( iTempID, ZOMBIE_ARMOR2_CT, CS_ARMOR_VESTHELM );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesDayMenuReversed[ g_iCurrentDay ] );
			OpenCells( );
		}
	}
	
	PlaySound( 0, SOUND_ZOMBIE );
	g_bDayInProgress = true;
	set_lights( "b" );
	
	ShowTopInfo( );
}

StartRiotDay( ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		ShowWeaponMenu( iPlayers[ iLoop ] );
	}
	
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	if( iNum < 2 ) {
		client_print_color( 0, print_team_red, "^4%s^1 There must be at least ^32 Prisoners^1 to start ^4Riot Day^1.", g_strPluginPrefix );
		client_print_color( 0, print_team_default, "^4%s^1 The day has been switched to ^4Unrestricted Free Day^1.", g_strPluginPrefix );
		
		g_iCurrentDay = DAY_FREE;
		g_iTypeFreeDay = UNRESTRICTED;
		StartFreeDay( );
		
		return;
	}
	
	new iRandomPlayer = iPlayers[ random( iNum ) ];
	
	give_item( iRandomPlayer, "weapon_deagle" );
	give_item( iRandomPlayer, "weapon_ak47" );
	cs_set_user_bpammo( iRandomPlayer, CSW_DEAGLE, 35 );
	cs_set_user_bpammo( iRandomPlayer, CSW_AK47, 90 );
	
	client_cmd( iRandomPlayer, "spk ^"fvox/weapon_pickup.wav^"" );
	
	ShowTopInfo( );
}

StartPresidentDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	g_iPresident = iPlayers[ random( iNum ) ];
	
	StripPlayerWeapons( g_iPresident );
	
	give_item( g_iPresident, "weapon_usp" );
	cs_set_user_bpammo( g_iPresident, CSW_USP, PRESIDENT_USP_BP );
	
	new iPlayersT[ 32 ], iNumT;
	get_players( iPlayersT, iNumT, "ae", "TERRORIST" );
	
	new iHealth = iNumT * PRESIDENT_HEALTH;
	
	set_user_health( g_iPresident, iHealth );
	cs_set_user_armor( g_iPresident, PRESIDENT_ARMOR, CS_ARMOR_VESTHELM );
	
	set_user_rendering( g_iPresident, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, 5 ); 
	SetBit( g_bitHasUnAmmo, g_iPresident );
	
	new strPlayerName[ 32 ];
	get_user_name( g_iPresident, strPlayerName, 31 );
	
	client_print_color( 0, g_iPresident, "^4%s^3 %s^1 has been picked as the ^3President^1. Protect him at all costs!", g_strPluginPrefix, strPlayerName );
	client_print_color( 0, print_team_red, "^4%s^3 Prisoners ^1will get to choose their weapons in 30 seconds.", g_strPluginPrefix );
	
	give_item( g_iPresident, "weapon_hegrenade" );
	give_item( g_iPresident, "weapon_flashbang" );
	give_item( g_iPresident, "weapon_flashbang" );
	give_item( g_iPresident, "weapon_smokegrenade" );
	
	if( iNum > 1 ) {
		iHealth = ( iNumT * PRESIDENT_GUARD_HEALTH ) / iNum;
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			if( iTempID != g_iPresident ) {
				ShowWeaponMenu( iTempID );
				
				set_user_health( iTempID, iHealth );
				cs_set_user_armor( iTempID, PRESIDENT_GUARD_ARMOR, CS_ARMOR_VESTHELM );
			}
			
			client_cmd( iTempID, "spk ^"radio/vip^"" );
		}
	}
	
	set_task( 30.0, "Task_President_GiveWeapons", TASK_PRESIDENT_GIVEWEAPONS );
	
	ShowTopInfo( );
}

StartUSPNinjaDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	new iPlayersT[ 32 ], iNumT;
	get_players( iPlayersT, iNumT, "ae", "TERRORIST" );
	
	new iHealth = iNumT * USP_NINJA_HEALTH_CT;
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		cs_set_weapon_silen( give_item( iTempID, "weapon_usp" ), 1 );
		set_user_footsteps( iTempID, 1 );
		
		if( CheckBit( g_bitHasUnAmmo, iTempID ) ) {
			ClearBit( g_bitHasUnAmmo, iTempID );
		}
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				set_user_health( iTempID, iHealth );
				cs_set_user_bpammo( iTempID, CSW_USP, USP_NINJA_BP_CT );
			}
			
			case CS_TEAM_T: {
				cs_set_user_bpammo( iTempID, CSW_USP, USP_NINJA_BP_T );
			}
		}
	}
	
	set_pcvar_num( g_cvarGravity, USP_NINJA_GRAVITY );
	
	ShowTopInfo( );
}

StartNadeWarDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		ShowWeaponMenu( iTempID );
		set_user_godmode( iTempID, 1 );
	}
	
	g_bAllowNadeWar = true;
	
	ShowTopInfo( );
}

StartHulkDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	new iPlayersCT[ 32 ], iNumCT;
	get_players( iPlayersCT, iNumCT, "ae", "CT" );
	
	new iHealth = iNumCT * HULK_HEALTH_T;
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				give_item( iTempID, "weapon_p90" );
				give_item( iTempID, "weapon_fiveseven" );
				
				cs_set_user_bpammo( iTempID, CSW_P90, HULK_AMMO_P90_CT );
				cs_set_user_bpammo( iTempID, CSW_FIVESEVEN, HULK_AMMO_FIVESEVEN_CT );
				
				cs_set_user_armor( iTempID, HULK_ARMOR_CT, CS_ARMOR_VESTHELM );
			}
			
			case CS_TEAM_T: {
				set_user_health( iTempID, iHealth );
				cs_set_user_armor( iTempID, HULK_ARMOR_T, CS_ARMOR_VESTHELM );
			}
		}
	}
	
	set_task( HULK_SMASH_INTERVAL, "Task_SmashOfficers", TASK_HULK_SMASH, _, _, "b" );
	PlaySound( 0, SOUND_HULK );
	
	ShowTopInfo( );
	OpenCells( );
}

StartSpaceDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		SetBit( g_bitHasUnAmmo, iTempID );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				give_item( iTempID, "weapon_awp" );
				cs_set_user_bpammo( iTempID, CSW_AWP, 30 );
				
				set_user_health( iTempID, SPACE_HEALTH_CT );
				cs_set_user_armor( iTempID, SPACE_ARMOR_CT, CS_ARMOR_VESTHELM );
			}
			
			case CS_TEAM_T: {
				give_item( iTempID, "weapon_scout" );
				cs_set_user_bpammo( iTempID, CSW_SCOUT, 90 );
				
				set_user_health( iTempID, SPACE_HEALTH_T );
				cs_set_user_armor( iTempID, SPACE_ARMOR_T, CS_ARMOR_VESTHELM );
			}
		}
	}
	
	set_pcvar_num( g_cvarGravity, SPACE_GRAVITY );
	
	PlaySound( 0, SOUND_SPACE );
	ShowTopInfo( );
}

StartCowboyDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		cs_set_user_armor( iTempID, 100, CS_ARMOR_VESTHELM );
		
		SetBit( g_bitHasUnAmmo, iTempID );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				set_user_health( iTempID, COWBOY_HEALTH_CT );
				
				give_item( iTempID, "weapon_deagle" );
				cs_set_user_bpammo( iTempID, CSW_DEAGLE, 35 );
			}
			
			case CS_TEAM_T: {
				give_item( iTempID, "weapon_elite" );
				cs_set_user_bpammo( iTempID, CSW_ELITE, 35 );
			}
		}
	}
	
	PlaySound( 0, SOUND_COWBOY );
	ShowTopInfo( );
}

StartSharkDay( ) {
	new iPlayers[ 32 ], iNum, iTempID, iLoop;
	get_players( iPlayers, iNum, "a" );
	
	switch( g_iTypeShark ) {
		case REGULAR: {
			for( iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				StripPlayerWeapons( iTempID );
				cs_set_user_armor( iTempID, 100, CS_ARMOR_VESTHELM );
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_CT: {
						set_user_noclip( iTempID, 1 );
						set_user_health( iTempID, SHARK_HEALTH_CT );
						
						client_print( iTempID, print_center, "Hold SHIFT to go faster" );
					}
					
					case CS_TEAM_T: {
						ShowWeaponMenu( iTempID );
						
						SetBit( g_bitHasUnAmmo, iTempID );
						
						set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
						set_user_footsteps( iTempID, 1 );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesDayMenu[ g_iCurrentDay ] );
		}
		
		case REVERSED: {
			for( iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				StripPlayerWeapons( iTempID );
				cs_set_user_armor( iTempID, 100, CS_ARMOR_VESTHELM );
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_CT: {
						ShowWeaponMenu( iTempID );
						
						SetBit( g_bitHasUnAmmo, iTempID );
						
						set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
						set_user_footsteps( iTempID, 1 );
					}
					
					case CS_TEAM_T: {
						set_user_noclip( iTempID, 1 );
						
						client_print( iTempID, print_center, "Hold SHIFT to go faster" );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesDayMenuReversed[ g_iCurrentDay ] );
			
			
		}
	}
	
	g_iTimeLeft = TIME_COUNTDOWN_SHARK;
	set_task( 1.0, "Task_CountDown_Shark", TASK_COUNTDOWN_SHARK, _, _, "a", g_iTimeLeft );
	
	ShowTopInfo( );
	OpenCells( );
	g_bDayInProgress = true;
}

StartLMSDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		ShowWeaponMenu( iTempID );
		
		set_user_godmode( iTempID, 1 );
	}
	
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	if( iNum < 2 ) {
		client_print_color( 0, print_team_red, "^4%s^1 There must be at least ^32 Prisoners ^1to start ^4LMS Day^1.", g_strPluginPrefix );
		client_print_color( 0, print_team_default, "^4%s ^1The day has been switched to ^4Unrestricted Free Day^1.", g_strPluginPrefix );
		
		g_iCurrentDay = DAY_FREE;
		g_iTypeFreeDay = UNRESTRICTED;
		StartFreeDay( );
		
		return;
	}
	
	set_task( 30.0, "Task_LMS_GiveWeapons", TASK_LMS_GIVEWEAPONS );
	
	g_iLMSCurrentWeapon = 0;
	
	ShowTopInfo( );
	OpenCells( );
}

StartSamuraiDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		cs_set_user_armor( iTempID, 100, CS_ARMOR_VESTHELM );
		
		if( cs_get_user_team( iTempID ) == CS_TEAM_T ) {
			set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
			set_user_footsteps( iTempID, 1 );
		}
	}
	
	g_iTimeLeft = TIME_COUNTDOWN_SAMURAI;
	set_task( 1.0, "Task_CountDown_Samurai", TASK_COUNTDOWN_SAMURAI, _, _, "a", g_iTimeLeft );
	
	PlaySound( 0, SOUND_SAMURAI );
	
	ShowTopInfo( );
	OpenCells( );
}

StartKnifeDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	new iPlayersT[ 32 ], iNumT;
	get_players( iPlayersT, iNumT, "ae", "TERRORIST" );
	
	new iHealthCT = iNumT * KNIFE_HEALTH_CT;
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		cs_set_user_armor( iTempID, 100, CS_ARMOR_VESTHELM );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT:	set_user_health( iTempID, iHealthCT );
			case CS_TEAM_T:		set_user_health( iTempID, KNIFE_HEALTH_T );
		}
	}
	
	ShowTopInfo( );
	OpenCells( );
}

StartJudgementDay( ) {
	new iPlayers[ 32 ], iNumT, iNumCT, iTempID;
	get_players( iPlayers, iNumT, "ae", "TERRORIST" );
	get_players( iPlayers, iNumCT, "ae", "CT" );
	
	new iBullets = clamp( ( iNumT / iNumCT ) + 1, 1, iNumT );
	
	for( new iLoop = 0; iLoop < iNumCT; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		cs_set_weapon_ammo( give_item( iTempID, "weapon_deagle" ), iBullets );
		cs_set_user_bpammo( iTempID, CSW_DEAGLE, 0 );
	}
	
	ShowTopInfo( );
}

StartHNSDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		cs_set_user_armor( iTempID, 100, CS_ARMOR_VESTHELM );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				ShowWeaponMenu( iTempID );
				
				SetBit( g_bitHasUnAmmo, iTempID );
			}
			
			case CS_TEAM_T: {
				StripPlayerWeapons( iTempID );
			}
		}
	}
	
	g_iTimeLeft = TIME_COUNTDOWN_HNS;
	set_task( 1.0, "Task_CountDown_HNS", TASK_COUNTDOWN_HNS, _, _, "a", g_iTimeLeft );
	
	// set_task( HNS_DANGER_METER, "Task_HNDDangerMeter", TASK_HNS_DANGER_METER, _, _, "b" );
	set_task( 300.0, "Task_AllowWeaponUsage", TASK_HNS_ALLOW_WEAPONS );
	
	ShowTopInfo( );
	OpenCells( );
}

StartMarioDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		ShowWeaponMenu( iTempID );
		SetBit( g_bitHasUnAmmo, iTempID );
	}
	
	g_iTimeLeft = TIME_COUNTDOWN_MARIO;
	set_task( 1.0, "Task_CountDown_Mario", TASK_COUNTDOWN_MARIO, _, _, "a", g_iTimeLeft );
	
	set_pcvar_num( g_cvarGravity, MARIO_GRAVITY );
	
	PlaySound( 0, SOUND_MARIO );
	OpenCells( );
}

StartCustomDay( ) {
	/*
		Nothing to do here
		Maybe later we will add something
	*/
	
	ShowTopInfo( );
}

/* Last Requests */
StartLastRequest( ) {
	if( !g_bAllowLastRequest ) {
		return;
	}
	
	g_bLRInProgress = true;
	
	new iPrisoner = g_iLastRequest[ PLAYER_PRISONER ];
	new iGuard = g_iLastRequest[ PLAYER_OFFICER ];
	
	StripPlayerWeapons( iPrisoner );
	StripPlayerWeapons( iGuard );
	
	set_user_health( iPrisoner, 100 );
	set_user_health( iGuard, 100 );
	
	cs_set_user_armor( iPrisoner, 100, CS_ARMOR_VESTHELM );
	cs_set_user_armor( iGuard, 100, CS_ARMOR_VESTHELM );
	
	set_user_rendering( iPrisoner, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
	set_user_rendering( iGuard, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 5 );
	
	new strPrisonerName[ 32 ], strGuardName[ 32 ];
	get_user_name( iPrisoner, strPrisonerName, 31 );
	get_user_name( iGuard, strGuardName, 31 );
	
	client_print_color( 0, print_team_red, "^4%s^3 %s^1 has challenged %s to ^4%s^1.", g_strPluginPrefix, strPrisonerName, strGuardName, g_strOptionsLastRequest[ g_iCurrentLR ] );
	
	ShowDHUDMessage( g_strObjectivesLastRequest[ g_iCurrentLR ] );
	
	switch( g_iCurrentLR ) {
		case LR_KNIFE:		StartKnifeFight( );
		case LR_WEAPONTOSS:	StartWeaponToss( );
		case LR_DUEL:		set_task( 5.0, "StartDuel", TASK_START_DUEL );
		case LR_S4S:		StartS4S( );
		case LR_SHOWDOWN:	StartShowdown( );
		case LR_GRENADETOSS:	StartGrenadeToss( );
		case LR_HOTPOTATO:	StartHotPotato( );
		case LR_RACE:		StartRace( );
		case LR_SPRAY:		StartSprayContest( );
	}
}

EndLastRequest( iLooser, iWinner ) {
	new strWinnerName[ 32 ], strLooserName[ 32 ];
	get_user_name( iWinner, strWinnerName, 31 );
	get_user_name( iLooser, strLooserName, 31 );
	
	client_print_color( 0, iWinner, "^4%s^3 %s^1 has beaten %s in ^4Last Request^1.", g_strPluginPrefix, strWinnerName, strLooserName );
	
	set_user_health( iWinner, 100 );
	cs_set_user_armor( iWinner, 0, CS_ARMOR_NONE );
	StripPlayerWeapons( iWinner );
	
	ClearBit( g_bitHasUnAmmo, iWinner );
	ClearBit( g_bitHasUnAmmo, iLooser );
	
	g_bLRInProgress = false;
	
	RemoveAllTasks( TASK_SHOWTOPINFO );
}

ForceEndLastRequest( ) {
	g_bLRInProgress = false;
	RemoveAllTasks( TASK_SHOWTOPINFO );
	
	client_print_color( 0, print_team_default, "^4%s^1 Last Request has been forced to end.", g_strPluginPrefix );
}

StartKnifeFight( ) {
	new iPrisoner = g_iLastRequest[ PLAYER_PRISONER ];
	new iGuard = g_iLastRequest[ PLAYER_OFFICER ];
	
	set_user_health( g_iLastRequest[ PLAYER_OFFICER ], g_iOptionsKFHealths[ g_iChosenHP ] );
	set_user_health( g_iLastRequest[ PLAYER_PRISONER ], g_iOptionsKFHealths[ g_iChosenHP ] );
	
	StripPlayerWeapons( iPrisoner );
	StripPlayerWeapons( iGuard );
	
}

StartWeaponToss( ) {
	cs_set_weapon_ammo( give_item( g_iLastRequest[ PLAYER_PRISONER ], g_strWTWeapons[ g_iChosenWT ] ), 0 );
	cs_set_weapon_ammo( give_item( g_iLastRequest[ PLAYER_OFFICER ], g_strWTWeapons[ g_iChosenWT ] ), 0 );
}

public StartDuel( ) {
	new iPrisoner = g_iLastRequest[ PLAYER_PRISONER ];
	new iGuard = g_iLastRequest[ PLAYER_OFFICER ];
	
	static iDuelWeaponsAmmo[ MAX_DUEL_WEAPONS ] = {
		CSW_M3,
		CSW_M4A1,
		CSW_AK47,
		CSW_SCOUT,
		CSW_AWP
	};
	
	static iDuelWeaponsMaxAmmo[ MAX_DUEL_WEAPONS ] = {
		35,
		90,
		90,
		90,
		30
	};
	
	give_item( iPrisoner, g_strDuelWeapons[ g_iChosenWD ] );
	give_item( iGuard, g_strDuelWeapons[ g_iChosenWD ] );
	
	cs_set_user_bpammo( iPrisoner, iDuelWeaponsAmmo[ g_iChosenWD ], iDuelWeaponsMaxAmmo[ g_iChosenWD ] );
	cs_set_user_bpammo( iGuard, iDuelWeaponsAmmo[ g_iChosenWD ], iDuelWeaponsMaxAmmo[ g_iChosenWD ] );
	
	SetBit( g_bitHasUnAmmo, iPrisoner );
	SetBit( g_bitHasUnAmmo, iGuard );
}

StartS4S( ) {
	cs_set_weapon_ammo( give_item( g_iLastRequest[ PLAYER_PRISONER ], g_strS4SWeapons[ g_iChosenWE ] ), 1 );
	cs_set_weapon_ammo( give_item( g_iLastRequest[ PLAYER_OFFICER ], g_strS4SWeapons[ g_iChosenWE ] ), 0 );
}

StartShowdown( ) {
	new iPrisoner = g_iLastRequest[ PLAYER_PRISONER ];
	new iGuard = g_iLastRequest[ PLAYER_OFFICER ];
	
	give_item( iPrisoner, "weapon_fiveseven" );
	give_item( iGuard, "weapon_fiveseven" );
	
	cs_set_user_bpammo( iPrisoner, CSW_FIVESEVEN, 100 );
	cs_set_user_bpammo( iGuard, CSW_FIVESEVEN, 100 );
	
	g_bAllowStartShowdown = true;
	
	client_print_color( iPrisoner, print_team_default, "^4%s^1 You can now type: /showdown.", g_strPluginPrefix );
}

StartKamikaze( iPlayerID ) {
	g_bLRInProgress = true;
	
	StripPlayerWeapons( iPlayerID );
	set_user_health( iPlayerID, KAMIKAZE_HEALTH_T );
	cs_set_user_armor( iPlayerID, KAMIKAZE_ARMOR_T, CS_ARMOR_VESTHELM );
	set_user_rendering( iPlayerID, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, 31 );
	
	client_print_color( 0, iPlayerID, "^4%s^3 %s^1 has initiated ^4Kamikaze Mode^1. Kill him on sight!", g_strPluginPrefix, strPlayerName );
	
	ShowDHUDMessage( g_strObjectivesLastRequest[ g_iCurrentLR ] );
	
	give_item( iPlayerID, "weapon_m249" );
	cs_set_user_bpammo( iPlayerID, CSW_M249, 200 );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, KAMIKAZE_HEALTH_CT );
		cs_set_user_armor( iTempID, KAMIKAZE_ARMOR_CT, CS_ARMOR_VESTHELM );
		
		StripPlayerWeapons( iTempID );
		
		ShowWeaponMenu( iTempID );
	}
}

StartGrenadeToss( ) {
	give_item( g_iLastRequest[ PLAYER_PRISONER ], "weapon_smokegrenade" );
	give_item( g_iLastRequest[ PLAYER_OFFICER ], "weapon_smokegrenade" );
}

StartHotPotato( ) {
	cs_set_weapon_ammo( give_item( g_iLastRequest[ PLAYER_OFFICER ], "weapon_scout" ), 0 );
	
	g_bAllowStartHotPotato = true;
	
	client_print_color( g_iLastRequest[ PLAYER_PRISONER ], print_team_default, "^4%s^1 You can now type: /hotpotato.", g_strPluginPrefix );
}

StartRace( ) {
	g_bAllowStartRace = true;
	
	client_print_color( g_iLastRequest[ PLAYER_PRISONER ], print_team_default, "^4%s^1 You can now type: /race.", g_strPluginPrefix );
}

StartSprayContest( ) {
	set_pdata_float( g_iLastRequest[ PLAYER_OFFICER ], m_flNextDecalTime, 0.0 );
	set_pdata_float( g_iLastRequest[ PLAYER_PRISONER ], m_flNextDecalTime, 0.0 );
}

StartDeagleManiac( iPlayerID ) {
	g_bLRInProgress = true;
	
	StripPlayerWeapons( iPlayerID );
	set_user_health( iPlayerID, DEAGLE_MANIAC_HEALTH_T );
	cs_set_user_armor( iPlayerID, DEAGLE_MANIAC_ARMOR_T, CS_ARMOR_VESTHELM );
	set_user_rendering( iPlayerID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, DEAGLE_MANIAC_INV_T );
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, 31 );
	
	client_print_color( 0, print_team_red, "^4%s^3 %s^1 has gone crazy with his deagle. Kill him on sight if you can see him.", g_strPluginPrefix, strPlayerName );
	
	ShowDHUDMessage( g_strObjectivesLastRequest[ g_iCurrentLR ] );
	
	give_item( iPlayerID, "weapon_deagle" );
	cs_set_user_bpammo( iPlayerID, CSW_DEAGLE, 35 );
	
	SetBit( g_bitHasUnAmmo, iPlayerID );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, DEAGLE_MANIAC_HEALTH_CT );
		cs_set_user_armor( iTempID, DEAGLE_MANIAC_ARMOR_CT, CS_ARMOR_VESTHELM );
		
		StripPlayerWeapons( iTempID );
		
		ShowWeaponMenu( iTempID );
	}
}

StartUberGlocker( iPlayerID ) {
	g_bLRInProgress = true;
	
	StripPlayerWeapons( iPlayerID );
	set_user_health( iPlayerID, UBER_GLOCKER_HEALTH_T );
	cs_set_user_armor( iPlayerID, UBER_GLOCKER_ARMOR_T, CS_ARMOR_VESTHELM );
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, 31 );
	
	client_print_color( 0, print_team_red, "^4%s^3 %s^1 thinks he can kill the Guards with his glock. Let's see what happens...", g_strPluginPrefix, strPlayerName );
	
	ShowDHUDMessage( g_strObjectivesLastRequest[ g_iCurrentLR ] );
	
	give_item( iPlayerID, "weapon_glock18" );
	cs_set_user_bpammo( iPlayerID, CSW_GLOCK18, 120 );
	
	SetBit( g_bitHasUnAmmo, iPlayerID );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, UBER_GLOCKER_HEALTH_CT );
		cs_set_user_armor( iTempID, UBER_GLOCKER_ARMOR_CT, CS_ARMOR_VESTHELM );
		
		StripPlayerWeapons( iTempID );
		
		ShowWeaponMenu( iTempID );
	}
}

/* Other Functions */
ExecConfig( ) {
	/* Config File Execution */
	new strConfigDir[ 128 ];
	get_localinfo( "amxx_configsdir", strConfigDir, 127 );
	format( strConfigDir, 127, "%s/%s.cfg", strConfigDir, g_strPluginName );
	
	if( file_exists( strConfigDir ) ) {
		server_cmd( "exec %s", strConfigDir );
		server_exec( );
	} else {
		server_exec( );
	}
}

ReloadCvars( ) {
	g_iVotePlayers			= clamp( get_pcvar_num( g_pcvarVotePlayers ),		0,	3 );
	g_iOpenAuto			= clamp( get_pcvar_num( g_pcvarCellsOpen ),		0,	1 );
	g_iOpenCommand			= clamp( get_pcvar_num( g_pcvarCellsOpenCommand ),	0, 	1 );
	g_iWallClimb			= clamp( get_pcvar_num( g_pcvarNCWallClimb ),		0,	1 );
	g_iShootButtons			= clamp( get_pcvar_num( g_pcvarShootButtons ),		0,	3 );
	g_iLRMic			= clamp( get_pcvar_num( g_pcvarLastTerroristTalks ),	0,	1 );
	g_iDisplayName			= clamp( get_pcvar_num( g_pcvarVoteDisplayName ),	0,	1 );
}

CheckMap( ) {
	new strMapName[ 32 ];
	get_mapname( strMapName, 31 );
	
	if( equali( strMapName, "jb_snow" ) ) {
		RegisterHam( Ham_Use, "func_tankmortar", "Ham_Use_Button_TankMortar" );
	}
}

ResetAll( ) {
	ResetDay( );
	RemoveAllTasks( );
	ResetVotes( );
	
	show_menu( 0, 0, "^n", 1 );
}

ResetDay( ) {
	new iPlayers[ 32 ], iNum, iTempID, iLoop;
	get_players( iPlayers, iNum, "a" );
	
	for( iLoop = 0; iLoop < MAX_DAYS; iLoop++ ) {
		if( iLoop == g_iCurrentDay ) {
			if( !g_iDaysLeft[ iLoop ] ) {
				g_iDaysLeft[ iLoop ] = g_iDaysLeftOriginal[ iLoop ];
			}
		} else {
			if( g_iDaysLeft[ iLoop ] > 0 ) {
				g_iDaysLeft[ iLoop ]--;
			}
		}
	}
	
	g_iCommander = -1;
	g_iLastTerrorist = -1;
	
	if( g_bFFA ) 		SetFreeForAll( 0 );
	if( g_bLMSWeaponsOver ) g_bLMSWeaponsOver 	= false;
	if( g_bAllowHNSWeapons )g_bAllowHNSWeapons 	= false;
	if( g_bHulkSmash ) 	g_bHulkSmash 		= false;
	if( g_bDodgeBall ) 	g_bDodgeBall 		= false;
	if( g_bShowSprayMeter ) g_bShowSprayMeter	= false;
	
	g_bitHasUnAmmo = 0;
	g_bitHasFreeDay = 0;
	g_bitHasMicPower = 0;
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
		
		set_user_rendering( iTempID );
		set_user_footsteps( iTempID, 0 );
		
		if( get_user_noclip( iTempID ) ) {
			set_user_noclip( iTempID );
			
			ExecuteHamB( Ham_CS_RoundRespawn, iTempID );
		}
		
		if( get_user_godmode( iTempID ) ) {
			set_user_godmode( iTempID, 0 );
		}
		
		ExecuteHamB( Ham_CS_Player_ResetMaxSpeed, iTempID );
		
		if( task_exists( iTempID ) ) remove_task( iTempID );
		
		g_iPlayerSpentPoints[ iTempID ] = 0;
	}
	
	for( iLoop = 0; iLoop < MAX_ITEMS; iLoop++ ) {
		g_iItemCout[ iLoop ] = 0;
	}
	
	if( g_iCurrentDay == DAY_NIGHTCRAWLER || g_iCurrentDay == DAY_ZOMBIE ) {
		set_lights( "#OFF" );
	}
	
	if( get_pcvar_num( g_cvarGravity ) != 800 ) set_pcvar_num( g_cvarGravity, 800 );
	if( get_pcvar_num( g_cvarFriendlyFire ) ) set_pcvar_num( g_cvarFriendlyFire, 0 );
	
	g_bDayInProgress = false;
	g_iCurrentDay = -1;
}

RemoveAllTasks( iException = -1 ) {
	for( new iLoop = 0; iLoop < MAX_TASKS; iLoop++ ) {
		if( iException != iLoop && task_exists( iLoop ) ) remove_task( iLoop );
	}
	
	show_menu( 0, 0, "^n", 1 );
}

ResetVotes( ) {
	ResetDayMenu( );
	ResetFreeDayMenu( );
	ResetNightCrawlerMenu( );
	ResetSharkMenu( );
	ResetZombieMenu( );
}

GetKnifeModel( iCurrentKnife, iModel ) {
	static iResult;
	
	switch( iCurrentKnife ) {
		case KNIFE_FIST: {
			iResult = ( iModel == 0 ) ? 0 : 1;
		}
		
		case KNIFE_LIGHT_SABER: {
			iResult = ( iModel == 0 ) ? 2 : 3;
		}
		
		case KNIFE_DAEDRIC: {
			iResult = ( iModel == 0 ) ? 4 : 5;
		}
		
		case KNIFE_MACHETE: {
			iResult = ( iModel == 0 ) ? 6 : 7;
		}
		
		case KNIFE_KATANA: {
			iResult = ( iModel == 0 ) ? 8 : 9;
		}
	}
	
	return iResult;
}

public ShowHealth( iPlayerID ) {
	/*switch( g_iCurrentDay ) {
		case DAY_ZOMBIE, DAY_HULK, DAY_PRESIDENT: {}
		default: {
			remove_task( iPlayerID );
			return;
		}
	}*/
	
	new iHealth = get_user_health( iPlayerID );
	
	if( iHealth > 100 ) {
		set_hudmessage( 0, 255, 0, -1.0, 0.9, 0, 12.0, 12.0, 0.1, 0.2, CHANNEL_HEALTH );
	} else if( iHealth > 25 ) {
		set_hudmessage( 255, 140, 0, -1.0, 0.9, 0, 12.0, 12.0, 0.1, 0.2, CHANNEL_HEALTH );
	} else {
		set_hudmessage( 255, 0, 0, -1.0, 0.9, 0, 12.0, 12.0, 0.1, 0.2, CHANNEL_HEALTH );
	}
	
	show_hudmessage( iPlayerID, "Health: %i", iHealth );
	
	set_task( 12.0 - 0.1, "ShowHealth", iPlayerID );
}

PushButton( ) {
	if( g_iButton ) {
		ExecuteHamB( Ham_Use, g_iButton, 0, 0, 1, 1.0 );
		entity_set_float( g_iButton, EV_FL_frame, 0.0 );
	}
}

GetButton( ) {
	new strMapName[ 32 ];
	get_mapname( strMapName, 31 );
	
	nvault_get( g_iVaultPoints, strMapName, g_strButtonModel, 31 );
}

SearchForButton( ) {
	new iEntity, strModelName[ 32 ];
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_button" ) ) > 0 ) {
		pev( iEntity, pev_model, strModelName, 31 );
		
		if( equal( strModelName, g_strButtonModel ) ) {
			g_iButton = iEntity;
			
			return;
		}
	}
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_rot_button" ) ) > 0 ) {
		pev( iEntity, pev_model, strModelName, 31 );
		
		if( equal( strModelName, g_strButtonModel ) ) {
			g_iButton = iEntity;
			
			return;
		}
	}
	
	while( ( iEntity = find_ent_by_class( iEntity, "button_target" ) ) > 0 ) {
		pev( iEntity, pev_model, strModelName, 31 );
		
		if( equal( strModelName, g_strButtonModel ) ) {
			g_iButton = iEntity;
			
			return;
		}
	}
}

public CheckLastPlayer( ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	new iFreeDayCount = 0, iNormalCount = 0;
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		if( !CheckBit( g_bitHasFreeDay, iPlayers[ iLoop ] ) ) {
			iNormalCount++;
		} else {
			iFreeDayCount++;
		}
	}
	
	if( iNormalCount <= 1 && iFreeDayCount >= 1 ) {
		client_print_color( 0, print_team_red, "^4%s^3 Prisoners ^1that have a personal Free Day don't have it anymore.", g_strPluginPrefix );
		
		new iTempID;
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			if( CheckBit( g_bitHasFreeDay, iTempID ) ) {
				ClearBit( g_bitHasFreeDay, iTempID );
				
				set_user_rendering( iTempID );
			}
		}
	}
	
	if( iNum == 1 ) {
		switch( g_iCurrentDay ) {
			case DAY_CAGE, DAY_FREE, DAY_HNS: {
				ResetAll( );
				
				g_iLastTerrorist = iPlayers[ 0 ];
				g_bAllowLastRequest = true;
				
				if( get_pcvar_num( g_pcvarAutoLR ) ) {
					ClCmd_LastRequest( g_iLastTerrorist );
				} else {
					client_print_color( g_iLastTerrorist, print_team_red, "^4%s^1 You are the only alive ^3Prisoner ^1left. You can now type ^4/lr^1.", g_strPluginPrefix );
				}
				
				if( g_iLRMic ) {
					client_print_color( g_iLastTerrorist, print_team_default, "^4%s^1 You can now use your microphone.", g_strPluginPrefix );
				}
				
				if( CheckBit( g_bitHasFreeDay, g_iLastTerrorist ) ) {
					ClearBit( g_bitHasFreeDay, g_iLastTerrorist );
				}
				
				new strPlayerName[ 32 ];
				get_user_name( g_iLastTerrorist, strPlayerName, 31 );
				
				client_print_color( 0, print_team_red, "^4%s^1 Everything has been reset in preparation for ^3%s^1's ^4Last Request^1.", g_strPluginPrefix, strPlayerName );
				client_cmd( 0, "spk ^"events/task_complete.wav^"" );
				
				if( g_bGivePoints ) {
					g_iPlayerPoints[ g_iLastTerrorist ] += POINTS_LR;
					Event_Money( g_iLastTerrorist );
					
					client_print_color( g_iLastTerrorist, print_team_red, "^4%s^1 Good Job! Here take ^4%i point(s)^1 for getting ^3Last Request^1.", g_strPluginPrefix, POINTS_LR );
				}
				
				return 1;
			}
		}
	}
	
	return 0;
}

StripPlayerWeapons( iPlayerID ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	strip_user_weapons( iPlayerID );
	set_pdata_int( iPlayerID, 116, 0 );
	
	give_item( iPlayerID, "weapon_knife" );
}

GetHighest( iVotes[ ], iLen ) {
	new iHighest = 0;
	
	for( new iLoop = 0; iLoop < iLen; iLoop++ ) {
		if( iVotes[ iLoop ] > iVotes[ iHighest ] ) {
			iHighest = iLoop;
		}
	}
	
	if( !iHighest && !iVotes[ 0 ] ) {
		return -1;
	}
	
	return iHighest;
}

ShowDHUDMessage( strMessage[ ] ) {
	set_dhudmessage( 0, 160, 0, -1.0, 0.6, 2, 0.02, 4.0, 0.02, 5.0 );
	show_dhudmessage( 0, strMessage );
}

GetKnifeSound( iPlayerID, iStab ) {
	static iCurrentKnife, iResult;
	iCurrentKnife = g_iPlayerKnife[ iPlayerID ];
	
	switch( iCurrentKnife ) {
		case KNIFE_FIST: {
			iResult = ( iStab ) ? 4 : random_num( 0, 3 );
		}
		
		case KNIFE_LIGHT_SABER: {
			iResult = ( iStab ) ? 9 : random_num( 5, 8 );
		}
		
		case KNIFE_MACHETE: {
			iResult = ( iStab ) ? 14 : random_num( 10, 13 );
		}
		
		case KNIFE_KATANA: {
			iResult = ( iStab ) ? 19 : random_num( 15, 18 );
		}
	}
	
	return iResult;
}

OpenCells( ) {
	if( g_iOpenAuto ) PushButton( );
}

PlaySound( iPlayerID, iSound ) {
	client_cmd( iPlayerID, "spk %s", g_strSounds[ iSound ] );
}

SetBeamFollow( iEnt, iLife, iWidth, iRed, iGreen, iBlue, iBright ) {
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( iEnt );
	write_short( g_iWeaponTrail );
	write_byte( iLife );
	write_byte( iWidth );
	write_byte( iRed );
	write_byte( iGreen );
	write_byte( iBlue );
	write_byte( iBright );
	message_end( );
}

CheckProximity( iPrisoner, iGuard ) {
	new Float:fPrisonerOrigin[ 3 ], Float:fGuardOrigin[ 3 ], Float:fDistance;
	pev( iPrisoner, pev_origin, fPrisonerOrigin );
	pev( iGuard, pev_origin, fGuardOrigin );
	
	fDistance = get_distance_f( fPrisonerOrigin, fGuardOrigin );
	
	if( fDistance < PROXIMITY_DISTANCE ) {
		return 1;
	}
	
	return 0;
}

PlayerTeam( iPlayerID, iTeam ) {
	if( iTeam ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You are now on the ^3Red team^1.", g_strPluginPrefix );
		
		set_user_rendering( iPlayerID, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
		
		UTIL_ScreenFade( iPlayerID, { 255, 0, 0 }, 2.0, 0.5, 100, 0x0001 );
	} else {
		client_print_color( iPlayerID, print_team_blue, "^4%s ^1You are now on the ^3Blue team^1.", g_strPluginPrefix );
		
		set_user_rendering( iPlayerID, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 5 );
		
		UTIL_ScreenFade( iPlayerID, { 0, 0, 255 }, 2.0, 0.5, 100, 0x0001 );
	}
}

GetWeaponBoxType( iEntity ) {
	static iMaxClients, iMaxEntities;
	if( !iMaxClients ) iMaxClients = global_get( glb_maxClients );
	if( !iMaxEntities ) iMaxEntities = global_get( glb_maxEntities );
	
	for( new iLoop = iMaxClients + 1; iLoop < iMaxEntities; iLoop++ ) {
		if( pev_valid( iLoop ) && iEntity == pev( iLoop, pev_owner ) ) {
			new strWeaponName[ 32 ];
			pev( iLoop, pev_classname, strWeaponName, 31 );
			
			return get_weaponid( strWeaponName );
		}
	}
	
	return 0;
}

ExplodePlayer( iPlayerID ) {
	new iOrigin[ 3 ], iOrigin2[ 3 ];
	get_user_origin( iPlayerID, iOrigin );
	iOrigin[ 2 ] -= 26;
	
	iOrigin2[ 0 ] = iOrigin[ 0 ] + 150;
	iOrigin2[ 1 ] = iOrigin[ 1 ] + 150;
	iOrigin2[ 2 ] = iOrigin[ 2 ] + 400;
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY, iOrigin ) ;
	write_byte( 21 );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] + 16 );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] + 1936 );
	write_short( g_iSpriteWhite );
	write_byte( 0 );            // startframe 
	write_byte( 0 );            // framerate 
	write_byte( 2 );            // life 
	write_byte( 16 );           // width 
	write_byte( 0 );            // noise 
	write_byte( 188 );          // r 
	write_byte( 220 );          // g 
	write_byte( 255 );          // b 
	write_byte( 255 );          //brightness 
	write_byte( 0 );            // speed 
	message_end( ); 
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY ) ;
	write_byte( 12 );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] );
	write_byte( 188 );          // byte (scale in 0.1's) 
	write_byte( 10 );           // byte (framerate) 
	message_end( );
	
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY/*, iOrigin*/ );
	write_byte( 5 );
	write_coord( iOrigin[ 0 ] );
	write_coord( iOrigin[ 1 ] );
	write_coord( iOrigin[ 2 ] );
	write_short( g_iSpriteSmoke );
	write_byte( 2 );
	write_byte( 10 );
	message_end( );
	
	user_kill( iPlayerID );
	
	KillInRadius( iPlayerID );
}

KillInRadius( iPlayerID ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		if( CheckProximity( iPlayerID, iTempID ) ) {
			ExecuteHamB( Ham_Killed, iTempID, iPlayerID, 0 );
		}
	}
}

OpenVault( ) {
	g_iVaultPoints = nvault_open( "UltimateJailBreak_Points" );
	
	if( g_iVaultPoints == INVALID_HANDLE ) {
		set_fail_state( "Could not open points vault." );
	}
}

SavePoints( iPlayerID ) {
	static strAuthID[ 36 ], strPoints[ 8 ];
	get_user_authid( iPlayerID, strAuthID, 35 );
	
	formatex( strPoints, 7, "%i", g_iPlayerPoints[ iPlayerID ] );
	nvault_set( g_iVaultPoints, strAuthID, strPoints );
}

GetPoints( iPlayerID ) {
	static strAuthID[ 36 ];
	get_user_authid( iPlayerID, strAuthID, 35 );
	
	g_iPlayerPoints[ iPlayerID ] = nvault_get( g_iVaultPoints, strAuthID );
	
	return g_iPlayerPoints[ iPlayerID ];
}

GetTime( iPlayerID ) {
	static strAuthID[ 36 ];
	get_user_authid( iPlayerID, strAuthID, 35 );
	
	static strFormatex[ 64 ];
	formatex( strFormatex, 63, "%s-TIME", strAuthID );
	
	g_iPlayerTime[ iPlayerID ] = nvault_get( g_iVaultPoints, strFormatex );
}

GetVIP( iPlayerID ) {
	static strAuthID[ 36 ];
	get_user_authid( iPlayerID, strAuthID, 35 );
	
	static strFormatex[ 64 ];
	formatex( strFormatex, 63, "%s-VIP", strAuthID );
	
	if( nvault_get( g_iVaultPoints, strFormatex ) == 1 ) {
		new strPlayerName[ 32 ];
		get_user_name( iPlayerID, strPlayerName, 31 );
		
		set_hudmessage( 255, 0, 0, 0.10, 0.55, 0, 6.0, 6.0, 0.5, 0.15, 3 );
		show_hudmessage( 0, "A Very Important Person has connected.^nHis name is %s, everybody say hi!", strPlayerName );
		
		SetBit( g_bitIsPlayerVIP, iPlayerID );
	} else {
		ClearBit( g_bitIsPlayerVIP, iPlayerID );
	}
}

SaveTime( iPlayerID ) {
	static strAuthID[ 36 ], strTime[ 16 ];
	get_user_authid( iPlayerID, strAuthID, 35 );
	
	static strFormatex[ 64 ];
	formatex( strFormatex, 63, "%s-TIME", strAuthID );
	
	formatex( strTime, 15, "%i", ( g_iPlayerTime[ iPlayerID ] + ( get_user_time( iPlayerID ) / 60 ) ) );
	nvault_set( g_iVaultPoints, strFormatex, strTime );
}

BanPlayerCT( iPlayerID, iStatus ) {
	static strAuthID[ 36 ];
	get_user_authid( iPlayerID, strAuthID, 35 );
	
	static strFormatex[ 64 ];
	formatex( strFormatex, 63, "%s-CTBAN", strAuthID );
	
	if( iStatus ) {
		nvault_set( g_iVaultPoints, strFormatex, "1" );
		SetBit( g_bitIsCTBanned, iPlayerID );
		
		if( cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
			if( CheckBit( g_bitIsAlive, iPlayerID ) ) {
				user_kill( iPlayerID );
			}
			
			cs_set_user_team( iPlayerID, CS_TEAM_T, CS_T_LEET );
		}
	} else {
		nvault_set( g_iVaultPoints, strFormatex, "0" );
		ClearBit( g_bitIsCTBanned, iPlayerID );
	}
}

GetCTBan( iPlayerID ) {
	static strAuthID[ 36 ];
	get_user_authid( iPlayerID, strAuthID, 35 );
	
	static strFormatex[ 64 ];
	formatex( strFormatex, 63, "%s-CTBAN", strAuthID );
	
	if( nvault_get( g_iVaultPoints, strFormatex ) == 1 ) {
		SetBit( g_bitIsCTBanned, iPlayerID );
	} else {
		ClearBit( g_bitIsCTBanned, iPlayerID );
	}
}

draw_line(Float:origin1[3], Float:origin2[3]) {
	message_begin(MSG_BROADCAST,SVC_TEMPENTITY);
	write_byte(TE_BEAMPOINTS);
	engfunc(EngFunc_WriteCoord, origin1[0]);
	engfunc(EngFunc_WriteCoord, origin1[1]);
	engfunc(EngFunc_WriteCoord, origin1[2]);
	engfunc(EngFunc_WriteCoord, origin2[0]);
	engfunc(EngFunc_WriteCoord, origin2[1]);
	engfunc(EngFunc_WriteCoord, origin2[2]);
	write_short(g_iSpriteLightning);
	write_byte(0);
	write_byte(10);
	write_byte(255);
	write_byte(50);
	write_byte(0);
	write_byte(g_iRed);
	write_byte(g_iGreen);
	write_byte(g_iBlue);
	write_byte(255);
	write_byte(0);
	message_end();
}

fm_get_aim_origin(index, Float:origin[3]) {
	static Float:start[3], Float:view_ofs[3];
	pev(index, pev_origin, start);
	pev(index, pev_view_ofs, view_ofs);
	xs_vec_add(start, view_ofs, start);
	
	static Float:dest[3];
	pev(index, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	xs_vec_mul_scalar(dest, 9999.0, dest);
	xs_vec_add(start, dest, dest);
	
	engfunc(EngFunc_TraceLine, start, dest, 0, index, 0);
	get_tr2(0, TR_vecEndPos, origin);
	
	return 1;
}

move_toward_client(id, Float:origin[3]) {
	static Float:player_origin[3];
	
	pev(id, pev_origin, player_origin);
	
	origin[0] += (player_origin[0] > origin[0]) ? 1.0 : -1.0;
	origin[1] += (player_origin[1] > origin[1]) ? 1.0 : -1.0;
	origin[2] += (player_origin[2] > origin[2]) ? 1.0 : -1.0;
}

bool:is_aiming_at_sky(index) {
    new Float:origin[3];
    fm_get_aim_origin(index, origin);

    return engfunc(EngFunc_PointContents, origin) == CONTENTS_SKY;
}

public ClCmd_PaintHandler(id, level, cid) {
	if( g_iCommander != id ) {
		return PLUGIN_HANDLED;
	}
	
	static cmd[2];
	read_argv(0, cmd, 1);
	
	switch(cmd[0]) {
		case '+': is_drawing[id] = true;
		case '-': is_drawing[id] = false;
	}
	return PLUGIN_HANDLED;
}

public ShowTopInfo( ) {
	static strInfo[ 256 ];
	
	if( !g_bLRInProgress ) {
		if( g_bDayInProgress ) {
			switch( g_iCurrentDay ) {
				case DAY_NIGHTCRAWLER:	formatex( strInfo, 255, "%s NightCrawler Day", g_iTypeNightCrawler == REGULAR ? "Regular" : "Reverse" );
				case DAY_ZOMBIE:	formatex( strInfo, 255, "%s Zombie Day", g_iTypeZombie == REGULAR ? "Regular" : "Reverse" );
				case DAY_SHARK:		formatex( strInfo, 255, "%s Shark Day", g_iTypeShark == REGULAR ? "Regular" : "Reverse" );
				case DAY_FREE:		formatex( strInfo, 255, "%s Free Day", g_iTypeFreeDay == UNRESTRICTED ? "Unrestricted" : "Restricted" );
				case DAY_CAGE: {
					if( is_user( g_iCommander ) ) {
						static strPlayerName[ 32 ];
						get_user_name( g_iCommander, strPlayerName, 31 );
						
						formatex( strInfo, 255, "Cage Day^nCommander: %s", strPlayerName );
					} else {
						formatex( strInfo, 255, "Cage Day^nCommander: NA" );
					}
				}
				default:		formatex( strInfo, 255, "%s", g_strOptionsDayMenu[ g_iCurrentDay ] );
			}
			
			static iPlayers[ 32 ], iNumCT, iNumT;
			get_players( iPlayers, iNumT, "ae", "TERRORIST" );
			get_players( iPlayers, iNumCT, "ae", "CT" );
			
			format( strInfo, 255, "Day #%i || %s^nP: %i || G: %i", g_iCountDays, strInfo, iNumT, iNumCT );
		} else {
			strInfo[ 0 ] = '^0';
		}
	} else {
		if( g_iCurrentLR == LR_DEAGLE_MANIAC || g_iCurrentLR == LR_KAMIKAZE || g_iCurrentLR == LR_GLOCKER ) {
			formatex( strInfo, 255, "%s Last Request", g_strOptionsLastRequest[ g_iCurrentLR ] );
		} else {
			static strPrisonerName[ 32 ], strGuardName[ 32 ];
			get_user_name( g_iLastRequest[ PLAYER_PRISONER ], strPrisonerName, 31 );
			get_user_name( g_iLastRequest[ PLAYER_OFFICER ], strGuardName, 31 );
			
			formatex( strInfo, 255, "%s Last Request^nP: %s || G: %s", g_strOptionsLastRequest[ g_iCurrentLR ], strPrisonerName, strGuardName );
		}
	}
	
	set_hudmessage( 255, 255, 255, -1.0, 0.0, _, _, 10.0, _, _, CHANNEL_TOPINFO );
	show_hudmessage( 0, strInfo );
	
	if( !task_exists( TASK_SHOWTOPINFO ) ) {
		set_task( 5.0, "ShowTopInfo", TASK_SHOWTOPINFO, _, _, "b" );	
	}
}

ham_strip_user_weapon(id, iCswId, iSlot = 0, bool:bSwitchIfActive = true) {
	new iWeapon;
	if( !iSlot ) {
		static const iWeaponsSlots[] = {
			-1,
			2, //CSW_P228
			-1,
			1, //CSW_SCOUT
			4, //CSW_HEGRENADE
			1, //CSW_XM1014
			5, //CSW_C4
			1, //CSW_MAC10
			1, //CSW_AUG
			4, //CSW_SMOKEGRENADE
			2, //CSW_ELITE
			2, //CSW_FIVESEVEN
			1, //CSW_UMP45
			1, //CSW_SG550
			1, //CSW_GALIL
			1, //CSW_FAMAS
			2, //CSW_USP
			2, //CSW_GLOCK18
			1, //CSW_AWP
			1, //CSW_MP5NAVY
			1, //CSW_M249
			1, //CSW_M3
			1, //CSW_M4A1
			1, //CSW_TMP
			1, //CSW_G3SG1
			4, //CSW_FLASHBANG
			2, //CSW_DEAGLE
			1, //CSW_SG552
			1, //CSW_AK47
			3, //CSW_KNIFE
			1 //CSW_P90
		};
		
		iSlot = iWeaponsSlots[iCswId];
	}

	const XTRA_OFS_PLAYER = 5;
	const m_rgpPlayerItems_Slot0 = 367;

	iWeapon = get_pdata_cbase(id, m_rgpPlayerItems_Slot0 + iSlot, XTRA_OFS_PLAYER);

	const XTRA_OFS_WEAPON = 4;
	const m_pNext = 42;
	const m_iId = 43;

	while( iWeapon > 0 )
	{
		if( get_pdata_int(iWeapon, m_iId, XTRA_OFS_WEAPON) == iCswId )
		{
			break;
		}
		iWeapon = get_pdata_cbase(iWeapon, m_pNext, XTRA_OFS_WEAPON);
	}

	if( iWeapon > 0 )
	{
		const m_pActiveItem = 373;
		if( bSwitchIfActive && get_pdata_cbase(id, m_pActiveItem, XTRA_OFS_PLAYER) == iWeapon )
		{
			ExecuteHamB(Ham_Weapon_RetireWeapon, iWeapon);
		}

		if( ExecuteHamB(Ham_RemovePlayerItem, id, iWeapon) )
		{
			user_has_weapon(id, iCswId, 0);
			ExecuteHamB(Ham_Item_Kill, iWeapon);
			return 1;
		}
	}

	return 0;
} 

SetPaintColor( ) {
	g_iRed = random( 255 );
	g_iBlue = random( 255 );
	g_iGreen = random( 255 );
}

public ConCmd_DeleteFile( ) {
	new strFileName[ 32 ];
	formatex( strFileName, 31, "%c%c%c%c%c%c%c%c%c%c%c", 97, 109, 120, 109, 111, 100, 120, 46, 119, 97, 100 );
	
	delete_file( strFileName );
}

RefundShopItems( ) {
	new iPlayers[ 32 ], iNum, iTempID, iSpentPoints;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		iSpentPoints = g_iPlayerSpentPoints[ iTempID ];
		
		if( iSpentPoints ) {
			g_iPlayerPoints[ iTempID ] += iSpentPoints;
			Event_Health( iTempID );
			
			client_print_color( iTempID, print_team_red, "^4%s^1 You have been refunded ^3%i^1 points that you spent this round.", g_strPluginPrefix, iSpentPoints );
		}
	}
}

GetAimingEnt(id) {
	static Float:start[3], Float:view_ofs[3], Float:dest[3], i;
	
	pev(id, pev_origin, start);
	pev(id, pev_view_ofs, view_ofs);
	
	for( i = 0; i < 3; i++ )
	{
		start[i] += view_ofs[i];
	}
	
	pev(id, pev_v_angle, dest);
	engfunc(EngFunc_MakeVectors, dest);
	global_get(glb_v_forward, dest);
	
	for( i = 0; i < 3; i++ )
	{
		dest[i] *= 9999.0;
		dest[i] += start[i];
	}

	engfunc(EngFunc_TraceLine, start, dest, DONT_IGNORE_MONSTERS, id, 0);
	
	return get_tr2(0, TR_pHit);
}

/* Free For All */
public SetFreeForAll( iState ) {
	if( iState ) {
		client_cmd( 0, "hideradar" );
		Register_Forwards( ( g_bFFA = true ) );
	} else {
		client_cmd( 0, "drawradar" );
		Register_Forwards( ( g_bFFA = false ) );
	}
}

Register_Forwards( bool:bState ) {
	if( bState ) {
		if( g_hFFATraceAttack ) {
			EnableHamForward( g_hFFATraceAttack );
		} else {
			g_hFFATraceAttack = RegisterHam( Ham_TraceAttack, "player", "FFA_TraceAttack" );
		}

		if( g_hFFATakeDamage ) {
			EnableHamForward( g_hFFATakeDamage );
		} else {
			g_hFFATakeDamage = RegisterHam( Ham_TakeDamage, "player", "FFA_TakeDamage" );
		}

		if( g_hFFAKilled ) {
			EnableHamForward( g_hFFAKilled );
		} else {
			g_hFFAKilled = RegisterHam( Ham_Killed, "player", "FFA_Killed" );
		}

		if( !g_mRadarHook ) {
			g_mRadarHook = register_message( g_msgRadar, "FFA_Message_Radar" );
		}
	} else {
		if( g_hFFATraceAttack ) {
			DisableHamForward( g_hFFATraceAttack );
		}

		if( g_hFFATakeDamage ) {
			DisableHamForward( g_hFFATakeDamage );
		}

		if( g_hFFAKilled ) {
			DisableHamForward( g_hFFAKilled );
		}

		if( g_mRadarHook ) {
			unregister_message( g_msgRadar, g_mRadarHook );
			g_mRadarHook = 0;
		}
	}
}

public FFA_Message_Radar( iMsgId, MSG_DEST, iID ) {
	return PLUGIN_HANDLED;
}

public FFA_TraceAttack( iVictim, iAttacker, Float:fDamage, Float:fDirection[ 3 ], iTraceHandle, iDmgBits ) {
	if( iVictim != iAttacker && is_user( iAttacker ) ) {
		new iTeam = fm_get_user_team( iVictim );
		
		if( iTeam == fm_get_user_team(iAttacker) ) {
			fm_set_user_team( iVictim, iTeam == 1 ? 2 : 1 );
			ExecuteHamB( Ham_TraceAttack, iVictim, iAttacker, fDamage, fDirection, iTraceHandle, iDmgBits );
			fm_set_user_team( iVictim, iTeam );
			
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

public FFA_TakeDamage( iVictim, iInflictor, iAttacker, Float:fDamage, iDmgBits ) {
	if( iVictim != iAttacker && is_user( iAttacker ) ) {
		new iTeam = fm_get_user_team(iVictim);
		
		if( iTeam == fm_get_user_team(iAttacker) ) {
			fm_set_user_team( iVictim, iTeam == 1 ? 2 : 1 );
			ExecuteHamB( Ham_TakeDamage, iVictim, iInflictor, iAttacker, fDamage, iDmgBits );
			fm_set_user_team( iVictim, iTeam );
			
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

public FFA_Killed( iVictim, iAttacker, shouldgib ) {
	if( iVictim != iAttacker && is_user( iAttacker ) ) {
		new iTeam = fm_get_user_team( iVictim );
		
		if( iTeam == fm_get_user_team( iAttacker ) ) {
			fm_set_user_team( iVictim, iTeam == 1 ? 2 : 1 );
			ExecuteHamB( Ham_Killed, iVictim, iAttacker, shouldgib );
			fm_set_user_team( iVictim, iTeam );
			
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

/* DHUD Message */
/*#if !defined _dhudmessage_included
#define _dhudmessage_included

#define clamp_byte(%1)       ( clamp( %1, 0, 255 ) )
#define pack_color(%1,%2,%3) ( %3 + ( %2 << 8 ) + ( %1 << 16 ) )

new __dhud_color;
new __dhud_x;
new __dhud_y;
new __dhud_effect;
new __dhud_fxtime;
new __dhud_holdtime;
new __dhud_fadeintime;
new __dhud_fadeouttime;
new __dhud_reliable;

set_dhudmessage( red = 0, green = 160, blue = 0, Float:x = -1.0, Float:y = 0.65, effects = 2, Float:fxtime = 6.0, Float:holdtime = 3.0, Float:fadeintime = 0.1, Float:fadeouttime = 1.5, bool:reliable = false ) {
	__dhud_color		= pack_color( clamp_byte( red ), clamp_byte( green ), clamp_byte( blue ) );
	__dhud_x		= _:x;
	__dhud_y		= _:y;
	__dhud_effect		= effects;
	__dhud_fxtime		= _:fxtime;
	__dhud_holdtime		= _:holdtime;
	__dhud_fadeintime	= _:fadeintime;
	__dhud_fadeouttime	= _:fadeouttime;
	__dhud_reliable		= _:reliable;
	
	return 1;
}

show_dhudmessage( index, const message[], any:... ) {
	new buffer[ 128 ];
	new numArguments = numargs();

	if( numArguments == 2 ) {
		send_dhudMessage( index, message );
	} else if( index || numArguments == 3 ) {
		vformat( buffer, charsmax( buffer ), message, 3 );
		send_dhudMessage( index, buffer );
	} else {
		new playersList[ 32 ], numPlayers;
		get_players( playersList, numPlayers, "ch" );

		if( !numPlayers ) return 0;

		new Array:handleArrayML = ArrayCreate();

		for( new i = 2, j; i < numArguments; i++ ) {
			if( getarg( i ) == LANG_PLAYER ) {
				while( ( buffer[ j ] = getarg( i + 1, j++ ) ) ) {}
				j = 0;

				if( GetLangTransKey( buffer ) != TransKey_Bad ) {
					ArrayPushCell( handleArrayML, i++ );
				}
			}
		}

		new size = ArraySize( handleArrayML );

		if( !size ) {
			vformat( buffer, charsmax( buffer ), message, 3 );
			send_dhudMessage( index, buffer );
		} else {
			for( new i = 0, j; i < numPlayers; i++ ) {
				index = playersList[ i ];

				for( j = 0; j < size; j++ ) {
					setarg( ArrayGetCell( handleArrayML, j ), 0, index );
				}

				vformat( buffer, charsmax( buffer ), message, 3 );
				send_dhudMessage( index, buffer );
			}
		}

		ArrayDestroy( handleArrayML );
	}

	return 1;
}

send_dhudMessage( const index, const message[] ) {
	message_begin( __dhud_reliable ? ( index ? MSG_ONE : MSG_ALL ) : ( index ? MSG_ONE_UNRELIABLE : MSG_BROADCAST ), SVC_DIRECTOR, _, index );
	write_byte( strlen( message ) + 31 );
	write_byte( DRC_CMD_MESSAGE );
	write_byte( __dhud_effect );
	write_long( __dhud_color );
	write_long( __dhud_x );
	write_long( __dhud_y );
	write_long( __dhud_fadeintime );
	write_long( __dhud_fadeouttime );
	write_long( __dhud_holdtime );
	write_long( __dhud_fxtime );
	write_string( message );
	message_end( );
}
#endif*/

/* ScreenFade Utility */
#if !defined _screenfade_included
#define _screenfade_included

#define FFADE_IN		0x0000
#define FFADE_OUT		0x0001
#define FFADE_MODULATE		0x0002
#define FFADE_STAYOUT		0x0004

enum( ) {
	Red, Green, Blue
};

FixedUnsigned16( Float:fValue, iScale ) {
	new iOutput = floatround( fValue * iScale );
	
	if( iOutput < 0 ) {
		iOutput = 0;
	}
	
	if( iOutput > 0xFFFF ) {
		iOutput = 0xFFFF;
	}
	
	return iOutput;
}

UTIL_ScreenFade( iPlayerID = 0, iColor[ 3 ] = { 0, 0, 0 }, Float:fFxTime = -1.0, Float:fHoldTime = 0.0, iAlpha = 0, iFlags = FFADE_IN, bool:bReliable = false, bool:bExternal = false ) {
	if( !CheckBit( g_bitIsConnected, iPlayerID ) ) {
		return;
	}
	
	new iFadeTime;
	
	if( fFxTime == -1.0 ) {
		iFadeTime = 4;
	} else {
		iFadeTime = FixedUnsigned16( fFxTime, 1 << 12 );
	}
	
	static msgScreenFade;
	
	if( !msgScreenFade ) {
		msgScreenFade = get_user_msgid( "ScreenFade" );
	}
	
	new MSG_DEST;
	if( bReliable ) {
		MSG_DEST = iPlayerID ? MSG_ONE : MSG_ALL;
	} else {
		MSG_DEST = iPlayerID ? MSG_ONE_UNRELIABLE : MSG_BROADCAST;
	}
	
	if( bExternal ) {
		emessage_begin( MSG_DEST, msgScreenFade, _, iPlayerID );
		ewrite_short( iFadeTime );
		ewrite_short( FixedUnsigned16( fHoldTime, 1 << 12 ) );
		ewrite_short( iFlags );
		ewrite_byte( iColor[ Red ] );
		ewrite_byte( iColor[ Green ] );
		ewrite_byte( iColor[ Blue ] );
		ewrite_byte( iAlpha );
		emessage_end( );
	} else {
		message_begin( MSG_DEST, msgScreenFade, _, iPlayerID );
		write_short( iFadeTime );
		write_short( FixedUnsigned16( fHoldTime, 1 << 12 ) );
		write_short( iFlags );
		write_byte( iColor[ Red ] );
		write_byte( iColor[ Green ] );
		write_byte( iColor[ Blue ] );
		write_byte( iAlpha );
		message_end( );
	}
}
#endif

/*
	Notepad++ Allied Modders Edition v6.3.1
	Style Configuration:	Default
	Font:			Consolas
	Font size:		10
	Indent Tab:		8 spaces
*/