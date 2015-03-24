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
#define PLUGIN_VERSION		"0.5.7b"

/* Includes */
#include < amxmodx >
#include < amxmisc >
#include < cstrike >
#include < fakemeta >
#include < hamsandwich >
#include < knifeapi >
#include < nvault >
#include < engine >
#include < fun >
#include < xs >

#pragma semicolon 1

/* Defines */
#define SetBit(%1,%2)      		(%1 |= (1<<(%2&31)))
#define ClearBit(%1,%2)    		(%1 &= ~(1 <<(%2&31)))
#define CheckBit(%1,%2)    		(%1 & (1<<(%2&31)))

#define is_user(%1)			(1 <= %1 <= MAX_PLAYERS)

#define PISTOL_WEAPONS_BIT		(1<<CSW_GLOCK18|1<<CSW_USP|1<<CSW_DEAGLE|1<<CSW_P228|1<<CSW_FIVESEVEN|1<<CSW_ELITE)
#define SHOTGUN_WEAPONS_BIT		(1<<CSW_M3|1<<CSW_XM1014)
#define SUBMACHINE_WEAPONS_BIT		(1<<CSW_TMP|1<<CSW_MAC10|1<<CSW_MP5NAVY|1<<CSW_UMP45|1<<CSW_P90)
#define RIFLE_WEAPONS_BIT		(1<<CSW_FAMAS|1<<CSW_GALIL|1<<CSW_AK47|1<<CSW_SCOUT|1<<CSW_M4A1|1<<CSW_SG550|1<<CSW_SG552|1<<CSW_AUG|1<<CSW_AWP|1<<CSW_G3SG1)
#define MACHINE_WEAPONS_BIT		(1<<CSW_M249)
#define PRIMARY_WEAPONS_BIT		(SHOTGUN_WEAPONS_BIT|SUBMACHINE_WEAPONS_BIT|RIFLE_WEAPONS_BIT|MACHINE_WEAPONS_BIT)
#define SECONDARY_WEAPONS_BIT		(PISTOL_WEAPONS_BIT)

#define IsPrimaryWeapon(%1)		((1<<%1) & PRIMARY_WEAPONS_BIT)
#define IsSecondaryWeapon(%1)		((1<<%1) & PISTOL_WEAPONS_BIT)

#define FFADE_IN			0x0000
#define FFADE_OUT			0x0001
#define FFADE_MODULATE			0x0002
#define FFADE_STAYOUT			0x0004

/*
	Uncomment the following line if you wish to debug the code. I
	included this options just to make my life easier for myself
	when I was writing and testing this plugin along the way.
	
	WARNING: enabling plugin debug may result in a massive ammount
	of log messages being written, you may experience problems opening
	the .txt document as it will be very large in some situations.
*/
// #define DEBUG

#define PAGE_OPTIONS			7
#define PAGE_MAX			3
#define PROXIMITY_DISTANCE		Float:300.0
#define GROUPS_MAX			5

#define TIME_COUNTDOWN_HOTPOTATO	11
#define TIME_COUNTDOWN_RACE		11
#define TIME_COUNTDOWN_COMMANDER	11
#define TIME_HOTPOTATO			Float:31.0
#define TIME_SHOP			Float:45.0

/*
	Below is the section where normal people can safely edit
	its values.
	Please if you don't know how to code, refrain from editing
	anything outside the safety zone.
	
	Experienced coders are free to edit what they want, but I
	will not reply to any private messages nor emails about hel-
	ping you with it, the comments should be plenty enough help.
	
	SAFETY ZONE STARTS HERE
*/
new const GLOW_THIKNESS			= 5;
new const Float:NOCLIP_SPEED		= Float:10.0;

new const BEAM_LIFE			= 40;
new const BEAM_WIDTH			= 10;
new const BEAM_BRIGHT			= 195;

new const ADMIN_START_DAY		= ADMIN_MAP;
new const ADMIN_OPEN			= ADMIN_KICK;
/*
	This is where you stop. Editing anything below this point
	might lead to some serious errors, and you will not get any
	support if you do.
	
	SAFETY ZONE ENDS HERE
*/

/* Enumerations */
/*
	These are all the days present in this plugin.
*/
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

/*
	These are all the last requests present in this plugin.
*/
enum _:MAX_LR( ) {
	LR_KNIFE		= 0,	LR_WEAPONTOSS,
	LR_DUEL,			LR_S4S,
	LR_SHOWDOWN,			LR_GRENADETOSS,
	LR_HOTPOTATO,			LR_RACE,
	LR_SPRAY,			LR_KAMIKAZE,
	LR_SUICIDE,			LR_MANIAC,
	LR_GLOCKER
};

/*
	These are all the ids of all the tasks in this plugin.
*/
enum _:MAX_TASKS( += 324 ) {
	TASK_VOTE_DAY		= 324,	TASK_VOTE_FREEDAY,
	TASK_VOTE_NIGHTCRAWLER,		TASK_VOTE_ZOMBIE,
	TASK_VOTE_SHARK,
	
	TASK_COUNTDOWN_NC,		TASK_COUNTDOWN_HOTPOTATO,
	TASK_COUNTDOWN_HNS,		TASK_COUNTDOWN_MARIO,
	TASK_COUNTDOWN_SAMURAI, 	TASK_COUNTDOWN_SHARK,
	TASK_COUNTDOWN_RACE,		TASK_COUNTDOWN_COMMANDER,
	TASK_COUNTDOWN_COMMANDERMATH,
	
	TASK_MENU_NC,			TASK_MENU_SHARK,
	TASK_MENU_ZOMBIE,
	
	TASK_PRESIDENT_GIVEWEAPONS,	TASK_START_DUEL,
	TASK_NADEWAR_START,		TASK_NADEWAR_GIVENADE,
	TASK_LMS_GIVEWEAPON,		TASK_LMS_GIVEORDEREDWEAPONS,
	TASK_HULK_SMASH,		TASK_END_ROUND,
	TASK_SHOWHEALTH,		TASK_START_SHOWDOWN,
	TASK_SLAYLOOSER,		TASK_UNGLOW_RANDOMPLAYER,
	TASK_TEAMJOIN,			TASK_DISABLESHOP
};

/*
	These are the types for some days since there are two versions
	of them. Regular and Reverse are for options where the days are
	reversed or not (CT becomes T and T becomes CT), where Restricted
	and Unrestricted are for a single day witch is the free day.
*/
enum _:MAX_TYPES( ) {
	TYPE_REGULAR		= 0,	TYPE_REVERSE,
	TYPE_UNRESTRICTED,		TYPE_RESTRICTED
};

/*
	These are all the sounds that are used in this plugin.
*/
enum _:MAX_SOUNDS( ) {
	SOUND_COWBOY		= 0,	SOUND_NADEWAR,
	SOUND_HULK,			SOUND_SPACE,
	SOUND_SAMURAI,			SOUND_SAMURAI2,
	SOUND_ZOMBIE,			SOUND_NIGHTCRAWLER,
	SOUND_HNS,			SOUND_MARIO,
	SOUND_MARIO_DOWN
};

/*
	These are all the weapons, primary and secondary. Makes life 
	much easier than hardcoding one by one.
*/
enum _:MAX_WEAPONS( ) {
	PRIMARY_M4A1		= 0,	PRIMARY_AK47,
	PRIMARY_AUG,			PRIMARY_SG552,
	PRIMARY_GALIL,			PRIMARY_FAMAS,
	PRIMARY_SCOUT,			PRIMARY_AWP,
	PRIMARY_M249,			PRIMARY_UMP45,
	PRIMARY_MP5NAVY,		PRIMARY_M3,
	PRIMARY_XM1014,			PRIMARY_TMP,
	PRIMARY_MAC10,			PRIMARY_P90,
	
	SECONDARY_USP,			SECONDARY_GLOCK18,
	SECONDARY_DEAGLE,		SECONDARY_P228,
	SECONDARY_ELITE,		SECONDARY_FIVESEVEN
}

/*
	These are all the values to be read from the UltimateJailBreak.ini
	file where server owners are able to tweak a lot of this 
	plugin's features and values.
	
	Note: do not switch the places of any two settings, cause its important
	that the order here and the order in the UltimateJailBreak.ini match.
*/
enum _:MAX_SETTINGS( ) {
	VOTE_PRIM_MIN		= 0,	VOTE_PRIM_MAX,
	VOTE_SEC_MIN,			VOTE_SEC_MAX,
	VOTE_OPPOSITE_MIN,		VOTE_OPPOSITE_MAX,
	
	CHANNEL_TOPINFO,		CHANNEL_OTHER,
	CHANNEL_COUNTDOWN,		CHANNEL_HEALTH,
	
	RESTRICTION_FREE,		RESTRICTION_CAGE,
	RESTRICTION_NC,			RESTRICTION_ZM,
	RESTRICTION_RIOT,		RESTRICTION_PRESIDENT,
	RESTRICTION_NINJA,		RESTRICTION_NADEWAR,
	RESTRICTION_HULK,		RESTRICTION_SPACE,
	RESTRICTION_COWBOY,		RESTRICTION_SHARK,
	RESTRICTION_LMS,		RESTRICTION_SAMURAI,
	RESTRICTION_KNIFE,		RESTRICTION_JUDGEMENT,
	RESTRICTION_HNS,		RESTRICTION_MARIO,
	RESTRICTION_CUSTOM,
	
	NC_REG_HEALTH_GUARD_REL,	NC_REG_ARMOR_GUARD,
	NC_REG_HEALTH_PRISONER,		NC_REG_ARMOR_PRISONER,
	NC_REV_HEALTH_GUARD_REL,	NC_REV_ARMOR_GUARD,
	NC_REV_HEALTH_PRISONER,		NC_REV_ARMOR_PRISONER,
	NC_COUNTDOWN_TIME,
	
	ZOMBIE_REG_HEALTH_GUARD,	ZOMBIE_REG_ARMOR_GUARD,
	ZOMBIE_REG_HEALTH_PRISONER_REL,	ZOMBIE_REG_ARMOR_PRISONER,
	ZOMBIE_REV_HEALTH_GUARD_REL,	ZOMBIE_REV_ARMOR_GUARD,
	ZOMBIE_REV_HEALTH_PRISONER,	ZOMBIE_REV_ARMOR_PRISONER,
	
	PRESIDENT_HEALTH_PRESIDENT_REL,	PRESIDENT_ARMOR_PRESIDENT,
	PRESIDENT_HEALTH_GUARD_REL,	PRESIDENT_ARMOR_GUARD,
	
	USP_NINJA_HEALTH_GUARD_REL,	USP_NINJA_ARMOR_GUARD,
	USP_NINJA_HEALTH_PRISONER,	USP_NINJA_ARMOR_PRISONER,
	USP_NINJA_BP_GUARD,		USP_NINJA_BP_PRISONER,
	USP_NINJA_GRAVITY,
	
	HULK_HEALTH_PRISONER_REL,	HULK_ARMOR_PRISONER,
	HULK_HEALTH_GUARD,		HULK_ARMOR_GUARD,
	HULK_PRIMARY_GUARD,		HULK_SECONDARY_GUARD,
	HULK_INTERVAL_SMASH,
	
	SPACE_HEALTH_GUARD,		SPACE_ARMOR_GUARD,
	SPACE_HEALTH_PRISONER,		SPACE_ARMOR_PRISONER,
	SPACE_PRIMARY_GUARD,		SPACE_SECONDARY_GUARD,
	SPACE_PRIMARY_PRISONER,		SPACE_SECONDARY_PRISONER,
	SPACE_GRAVITY,
	
	SHARK_REG_HEALTH_GUARD,		SHARK_REG_ARMOR_GUARD,
	SHARK_REG_HEALTH_PRISONER,	SHARK_REG_ARMOR_PRISONER,
	SHARK_REV_HEALTH_GUARD,		SHARK_REV_ARMOR_GUARD,
	SHARK_REV_HEALTH_PRISONER,	SHARK_REV_ARMOR_PRISONER,
	SHARK_COUNTDOWN_TIME,
	
	COWBOY_HEALTH_GUARD,		COWBOY_ARMOR_GUARD,
	COWBOY_PRIMARY_GUARD,		COWBOY_SECONDARY_GUARD,
	COWBOY_HEALTH_PRISONER,		COWBOY_ARMOR_PRISONER,
	COWBOY_PRIMARY_PRISONER,	COWBOY_SECONDARY_PRISONER,
	
	LMS_HEALTH_PRISONER,		LMS_ARMOR_PRISONER,
	LMS_TIME_INTERVAL,
	
	KNIFE_HEALTH_GUARD_REL,		KNIFE_ARMOR_GUARD,
	KNIFE_HEALTH_PRISONER,		KNIFE_ARMOR_PRISONER,
	
	SAMURAI_HEALTH_GUARD,		SAMURAI_ARMOR_GUARD,
	SAMURAI_HEALTH_PRISONER,	SAMURAI_ARMOR_PRISONER,
	SAMURAI_COUNTDOWN_TIME,
	
	MARIO_COUNTDOWN_TIME,		MARIO_GRAVITY,
	
	HNS_COUNTDOWN_TIME,
	
	KNIFE_HEALTH_1,			KNIFE_HEALTH_2,
	KNIFE_HEALTH_3,			KNIFE_HEALTH_4,
	
	TOSS_WEAPON_1_STR,		TOSS_WEAPON_2_STR,
	TOSS_WEAPON_3_STR,		
	
	DUEL_WEAPON_1_STR,		DUEL_WEAPON_2_STR,
	DUEL_WEAPON_3_STR,		DUEL_WEAPON_4_STR,
	DUEL_WEAPON_5_STR,
	
	S4S_WEAPON_1_STR,		S4S_WEAPON_2_STR,
	S4S_WEAPON_3_STR,		S4S_WEAPON_4_STR,
	S4S_WEAPON_5_STR,		S4S_WEAPON_6_STR,
	
	KAMIKAZE_PRISONER_HEALTH,	KAMIKAZE_PRISONER_ARMOR,
	KAMIKAZE_GUARD_HEALTH,		KAMIKAZE_GUARD_ARMOR,
	KAMIKAZE_GUARD_COUNT,
	
	MANIAC_PRISONER_HEALTH,		MANIAC_PRISONER_ARMOR,
	MANIAC_GUARD_HEALTH,		MANIAC_GUARD_ARMOR,
	MANIAC_GUARD_COUNT,		MANIAC_PRISONER_INVIS,
	
	GLOCKER_PRISONER_HEALTH,	GLOCKER_PRISONER_ARMOR,
	GLOCKER_GUARD_HEALTH,		GLOCKER_GUARD_ARMOR,
	GLOCKER_GUARD_COUNT,
	
	POINTS_KILL,			POINTS_KILL_HS,
	POINTS_LR,			POINTS_ROUND_START,
	POINTS_ROUND_END,		POINTS_MIN_PLAYERS,
	
	SHOP_GRENADE_HE,		SHOP_GRENADE_FLASH,
	SHOP_GRENADE_SMOKE,		SHOP_HEALTH,
	SHOP_HEALTH_ADV,		SHOP_ARMOR,
	SHOP_KNIFE,			SHOP_DEAGLE,
	SHOP_SCOUT,			SHOP_FOOTSTEPS,
	
	ITEMS_GRENADE_HE,		ITEMS_GRENADE_FLASH,
	ITEMS_GRENADE_SMOKE,		ITEMS_HEALTH,
	ITEMS_HEALTH_ADV,		ITEMS_ARMOR,
	ITEMS_KNIFE,			ITEMS_DEAGLE,
	ITEMS_SCOUT,			ITEMS_FOOTSTEPS
};

/*
	Type of player is last requests. Is he a Guard or a Prisoner?
*/
enum _:MAX_PLAYER_TYPE( ) {
	PLAYER_GUARD		=0,	PLAYER_PRISONER
}

/*
	All the commander available options of the menu.
*/
enum _:MAX_COMMANDER( ) {
	COMMANDER_OPEN		= 0, 	COMMANDER_SPLIT,
	COMMANDER_TIMER,		COMMANDER_GAMEBOOK,
	COMMANDER_RANDOM_PRISONER,	COMMANDER_EMPTY_DEAGLE,
	COMMANDER_MIC,			COMMANDER_HEAL,
	COMMANDER_GLOW,			COMMANDER_MATH,
	COMMANDER_FFA,			COMMANDER_SPRAY
};

/*
	All the main menu options.
*/
enum _:MAX_MAIM_MENU( ) {
	MAIN_MENU_TEAM		= 0,	MAIN_MENU_SHOP,
	MAIN_MENU_LR,			MAIN_MENU_FUN,
	MAIN_MENU_FREEDAY,		MAIN_MENU_COMMANDER,
	MAIN_MENU_COMMANDER_MENU,	MAIN_MENU_DAY,
	MAIN_MENU_VIP,			MAIN_MENU_GUNS,
	MAIN_MENU_RULES,		MAIN_MENU_CREDITS
};

/*
	All the knife skins present in this plugin.
*/
// enum _:MAX_KNIVES( ) {
	// KNIFE_BARE_HANDS	= 0,	KNIFE_TASER
// };

// enum _:MAX_SKINS( ) {
	// SKIN_T_DEFAULT		= 0,	SKIN_CT_DEFAULT
};

/* Constantes */
new const g_strPluginName[ ]		= "UltimateJailBreak";
new const g_strPluginVersion[ ]		= PLUGIN_VERSION;
new const g_strPluginAuthor[ ]		= "tonykaram1993";

/*
	Names of each and every day available in this plugin.
*/
new const g_strOptionsDayVote[ ][ ] = {
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
	Normal Objectives for each and every day available in this plugin.
	These objectives will be printed similarly to the TIPS in
	the center of you screen in green. You know, those annoying 
	messages? Well these won't be annoying, they will be helpful.
*/
new const g_strObjectivesDayVote[ ][ ] = {
	"Nothing is restricted except the Gunroom.^nGuards can only order Prisoners^nto drop their weapons.",
	"Prisoners have to follow the commands^ngiven by the Guards.^nAny disobedience might lead to death .",
	"Guards are invisible and have more HP.^nPrisoners automatically get weapons.^nGuards must chase the Prisoners with knives.",
	"Prisoners are Zombies.^nGuards automatically get weapons.^nPrisoners must try to infect the Guards.",
	"Treated as a Cage Day.^nOne random Prisoner will get an^nAK47 and a Deagle.^nGuards must try and find out who.",
	"One random Guard is picked as the President.^nPresident get more HP and a USP.^nGuards protect him at all costs.",
	"All players get a silenced USP.^nGuards get 112 extra bullets and Prisoners get 24.^nUSP must always be silenced.",
	"Guards lead the Prisoners to a specified area with godmode.^nA Guard types /nadewar and everyone gets^nunlimited grenades.",
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
	Same as above, except these are for the reverse type that some
	days have, that is why you see most of the following fields empty.
*/
new const g_strObjectivesReverseDayVote[ ][ ] = {
	"Guards can only restrict one area^nor one particular action.",
	"",
	"Prisoners are invisible and have more HP.^nGuards automatically get deagles.^nPrisoners must chase the Guards with knives.",
	"Guards get more HP.^nPrisoners automatically get weapons.^nGuards must chase the Prisoners with knives.",
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
	These are the names of all the available last request options.
*/
new const g_strOptionsLastRequest[ ][ ] = {
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
	Same as for the day objectives, these are the last request
	objectives, they will be printed the same way as HINT messages.
*/
new const g_strObjectivesLastRequest[ ][ ] = {
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
	The location of all the sounds used in this plugin. Used for
	precaching and for playing the sounds to the users.
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
	All primary and secondary weapon names.
*/
new const g_strWeapons[ ][ ] = {
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
	"weapon_p90",
	
	"weapon_usp",
	"weapon_glock18",
	"weapon_deagle",
	"weapon_p228",
	"weapon_elite",
	"weapon_fiveseven"
};

/*
	The V and P models of the knives, for precaching and showing to the player.
*/
// new const g_strKnifeModels[ ][ ][ ] = {
	// { "models/v_barehands.mdl",	"models/p_barehands.mdl" },
	// { "models/v_taser.mdl",		"models/p_taser.mdl" }
// };

// new const g_strSkinModels[ ][ ][ ] = {
	// // TODO: add skin models
// };

/*
	All the sounds of all the knives that are needed.
*/
// new const g_strKnifeSounds[ ][ ][ ] = {
	// /* Barehands (replacing default T knife) */
	// {
		// "weapons/barehands/knife_deploy1.wav",
		// "weapons/barehands/knife_hit1.wav",
		// "weapons/barehands/knife_stab.wav",
		// "weapons/barehands/knife_slash1.wav",
		// "weapons/barehands/knife_hit1.wav"
	// },
	
	// /* Taser (replacing default CT knife) */
	// {
		// "weapons/taser/knife_deploy1.wav",
		// "weapons/taser/knife_hit1.wav",
		// "weapons/taser/knife_stab",
		// "weapons/taser/knife_hit1.wav",
		// "weapons/taser/knife_hit1.wav"
	// }
// };

/* Integers */
new g_iPlayerPage[ MAX_PLAYERS + 1 ];
new g_iPlayerPrimaryWeapon[ MAX_PLAYERS + 1 ];
new g_iPluginSettings[ MAX_SETTINGS ];
new g_iPlayerTime[ MAX_PLAYERS + 1 ];
new g_iPlayerPoints[ MAX_PLAYERS + 1 ];
new g_iDayVoteRestrictionLeft[ MAX_DAYS ];
new g_iVotesDay[ MAX_DAYS ];
new g_iVotesPages[ PAGE_MAX ];
new g_iVotesFree[ MAX_TYPES ];
new g_iVotesNightCrawler[ TYPE_UNRESTRICTED ];
new g_iVotesZombie[ TYPE_UNRESTRICTED ];
new g_iVotesShark[ TYPE_UNRESTRICTED ];
new g_iLastRequestPlayers[ MAX_PLAYER_TYPE ];
new g_iKnives[ MAX_KNIVES ];
new g_iCommanderGlowColor[ 3 ];

new g_iDayCount;
new g_iDayCurrent;
new g_iDayForced;
new g_iDayVote;
new g_iDayVoteVoters;
new g_iDayVoteRestrictDays;
new g_iDayVoteShowVotes;
new g_iDayVoteWeightedVotes;
new g_iTypeFree;
new g_iTypeNightCrawler;
new g_iTypeZombie;
new g_iTypeShark;
new g_iVaultButtons;
new g_iVaultTime;
new g_iVaultPoints;
new g_iVaultCTBan;
new g_iWeaponMenuArmor;
new g_iWeaponMenuNades;
new g_iOpenCommand;
new g_iShootButtons;
new g_iPresident;
new g_iRestrictMicrophones;
new g_iTimeLeft;
new g_iCellsButton;
new g_iLMSCurrentWeapon;
new g_iSpriteWeaponTrail;
new g_iSpriteLaser;
new g_iSpriteSmoke;
new g_iSpriteWhite;
new g_iShowHealth;
new g_iLastRequest;
new g_iLRCurrent;
new g_iLRLastTerrorist;
new g_iLRChosenKnifeFight;
new g_iLRChosenWeaponToss;
new g_iLRChosenDuel;
new g_iLRChosenS4S;
new g_iLastPickup;
new g_iLastRequestMic;
new g_iCommander;
new g_iCommanderGuard;
new g_iCommanderMenuOption;
new g_iMathQuestionResult;
new g_iSprayChecker;
new g_iSprayCustom;
new g_iFlashLight;
new g_iMainMenu;
new g_iMainMenuRatio;
new g_iMainMenuTime;
new g_iPoints;

/* Strings */
new g_strPluginPrefix[ 32 ];
new g_strButtonModel[ 32 ];

/* Floats */
new Float:g_fWallOrigin[ MAX_PLAYERS + 1 ][ 3 ];

/* Booleans */
new bool:g_bOppositeVote;
new bool:g_bDayInProgress;
new bool:g_bLMSWeaponsOver;
new bool:g_bGivenWeapon;
new bool:g_bHulkSmash;
new bool:g_bFFA;
new bool:g_bLRInProgress;
new bool:g_bAllowNadeWar;
new bool:g_bAllowStartHotPotato;
new bool:g_bAllowStartRace;
new bool:g_bAllowStartShowdown;
new bool:g_bAllowSprayMeter;
new bool:g_bHotPotatoStarted;
new bool:g_bCatchAnswer;
new bool:g_bPluginCommand;
new bool:g_bGivePoints;
new bool:g_bAllowShop;

/* Bitsums */
new g_bitIsHeadShot[ MAX_PLAYERS + 1 ];
new g_bitHasBought[ GROUPS_MAX ];
new g_bitIsAlive;
new g_bitHasVoted;
new g_bitHasMenuHidden;
new g_bitHasUnAmmo;
new g_bitHasMicPower;
new g_bitHasFreeDay;
new g_bitHasHealthEnabled;
new g_bitIsFirstConnect;
new g_bitIsCTBanned;

/* PCVARs */
new g_pcvarResetButtons;
new g_pcvarDayVote;
new g_pcvarDayVoteVoters;
new g_pcvarDayVoteEndAtZero;
new g_pcvarPluginPrefix;
new g_pcvarDayVotePrimary;
new g_pcvarDayVoteSecondary;
new g_pcvarDayVoteMinPrisoners;
new g_pcvarDayVoteMinGuards;
new g_pcvarDayVoteOppositeChance;
new g_pcvarDayVoteRestrictDays;
new g_pcvarDayVoteFirstFreeday;
new g_pcvarDayVoteShowVotes;
new g_pcvarDayVoteWeightedVotes;
new g_pcvarWeaponMenuArmor;
new g_pcvarWeaponMenuNades;
new g_pcvarRestrictMicrophones;
new g_pcvarOpenCommand;
new g_pcvarShootButtons;
new g_pcvarShowHealth;
new g_pcvarLastRequest;
new g_pcvarLastRequestAutomatic;
new g_pcvarLastRequestMic;
new g_pcvarCommander;
new g_pcvarSprayChecker;
new g_pcvarSprayCustom;
new g_pcvarFlashLight;
new g_pcvarMainMenu;
new g_pcvarMainMenuRatio;
new g_pcvarMainMenuTime;
new g_pcvarPoints;

/* CVARs */
new g_cvarGravity;
new g_cvarRoundTime;

/* MessageIDs */
new g_msgScreenShake;
new g_msgRadar;

/* HamHooks */
new HamHook:g_hamTraceAttackButton;
new HamHook:g_hamUSPSecondaryAttack;
new HamHook:g_hamTouchWeaponbox;
new HamHook:g_hamTouchArmouryEntity;
new HamHook:g_hamTouchWorldSpawn;
new HamHook:g_hamTouchFuncWall;
new HamHook:g_hamTouchFuncBreakable;
new HamHook:g_hamTakeHealthPlayer;
new HamHook:g_hamTakeDamagePlayer;
new HamHook:g_hamThinkGrenade;
new HamHook:g_hamResetMaxSpeed;
new HamHook:g_hamPlayerPreThink;
new HamHook:g_hamAddPlayerItem;
new HamHook:g_hamPrimaryAttack;
new HamHook:g_hamTraceAttackPlayer;

/* Forwards */
new g_fwdSetClientListening;
new g_fwdAddToFullPack;
new g_fwdCmdStart;
new g_fwdTouch;
new g_fwdSpawn;
new g_fwdSetModel;

/* Plugin Natives */
public plugin_init( ) {
	/* Plugin Registration */
	register_plugin( g_strPluginName, g_strPluginVersion, g_strPluginAuthor );
	register_cvar( g_strPluginName, g_strPluginVersion, FCVAR_SERVER | FCVAR_EXTDLL | FCVAR_UNLOGGED | FCVAR_SPONLY );
	
	/* Events */
	register_event( "HLTV",		"Event_HLTV",			"a", "1=0", "2=0" );
	register_event( "TextMsg",	"Event_TextMsg_RestartRound",	"a", "2&#Game_C", "2&#Game_w", "2&#Round_D" );
	register_event( "CurWeapon",	"Event_CurWeapon",		"br", "1=1" );
	register_event( "Health",	"Event_Health",			"be", "1>0" );
	register_event( "23",		"Event_Spray",			"a", "1=112" );
	register_event( "Money",	"Event_Money",			"b" );
	
	/* LogEvents */
	register_logevent( "LogEvent_RoundStart",			2, "1=Round_Start" );
	register_logevent( "LogEvent_RoundEnd",				2, "1=Round_End" );
	
	/* ClCmd */
	register_clcmd( "say /day",					"ClCmd_ForceDay" );
	register_clcmd( "say /open",					"ClCmd_OpenCells" );
	register_clcmd( "say /credits",					"ClCmd_ShowCredits" );
	register_clcmd( "say /nadewar",					"ClCmd_StartNadeWar" );
	register_clcmd( "say /hotpotato",				"ClCmd_StartHotPotato" );
	register_clcmd( "say /race",					"ClCmd_StartRace" );
	register_clcmd( "say /showdown",				"ClCmd_StartShowdown" );
	register_clcmd( "say /health",					"ClCmd_ShowHealth" );
	register_clcmd( "say /guns",					"ClCmd_ShowGunsMenu" );
	register_clcmd( "say /ffa",					"ClCmd_FreeForAll" );
	register_clcmd( "say /voteday",					"ClCmd_ShowDayVote" );
	register_clcmd( "say /freeday",					"ClCmd_ShowFreeDayMenu" );
	register_clcmd( "say /lr",					"ClCmd_LastRequest" );
	register_clcmd( "say /commander",				"ClCmd_Commander" );
	register_clcmd( "say /commandermenu",				"ClCmd_CommanderMenu" );
	register_clcmd( "say /time",					"ClCmd_DisplayTime" );
	register_clcmd( "say /points",					"ClCmd_DisplayPoints" );
	
	register_clcmd( "say_team /day",				"ClCmd_ForceDay" );
	register_clcmd( "say_team /open",				"ClCmd_OpenCells" );
	register_clcmd( "say_team /credits",				"ClCmd_ShowCredits" );
	register_clcmd( "say_team /nadewar",				"ClCmd_StartNadeWar" );
	register_clcmd( "say_team /hotpotato",				"ClCmd_StartHotPotato" );
	register_clcmd( "say_team /race",				"ClCmd_StartRace" );
	register_clcmd( "say_team /showdown",				"ClCmd_StartShowdown" );
	register_clcmd( "say_team /health",				"ClCmd_ShowHealth" );
	register_clcmd( "say_team /guns",				"ClCmd_ShowGunsMenu" );
	register_clcmd( "say_team /ffa",				"ClCmd_FreeForAll" );
	register_clcmd( "say_team /voteday",				"ClCmd_ShowDayVote" );
	register_clcmd( "say_team /freeday",				"ClCmd_ShowFreeDayMenu" );
	register_clcmd( "say_team /lr",					"ClCmd_LastRequest" );
	register_clcmd( "say_team /commander",				"ClCmd_Commander" );
	register_clcmd( "say_team /commandermenu",			"ClCmd_CommanderMenu" );
	register_clcmd( "say_team /time",				"ClCmd_DisplayTime" );
	register_clcmd( "say_team /points",				"ClCmd_DisplayPoints" );
	
	register_clcmd( "drop",						"ClCmd_WeaponDrop" );
	register_clcmd( "drawradar",					"ClCmd_DrawRadar" );
	register_clcmd( "say",						"ClCmd_Say" );
	register_clcmd( "jointeam",					"ClCmd_ChooseTeam" );
	register_clcmd( "chooseteam",					"ClCmd_ChooseTeam" );
	
	/* ConCmd */
	register_concmd( "amx_set_button",				"ConCmd_SetButton",		ADMIN_RCON,	" - Set the button for the cell doors" );
	register_concmd( "amx_set_mic",					"ConCmd_SetMic",		ADMIN_KICK,	" <name | authid | userid> <1 | 0> - Set a player's talk power." );
	register_concmd( "amx_get_time",				"ConCmd_GetPlayerTime",		ADMIN_KICK,	" <name | authid | userid> - Get the ammount the player spent on the server." );
	register_concmd( "amx_set_time",				"ConCmd_SetPlayerTime",		ADMIN_KICK,	" <name | authid | userid> <#minutes> - Set the ammount the player spent on the server." );
	register_concmd( "amx_give_time",				"ConCmd_GivePlayerTime",	ADMIN_KICK,	" <name | authid | userid> <#minutes> - Give the ammount of time for the player." );
	register_concmd( "amx_get_points",				"ConCmd_GetPlayerPoints",	ADMIN_BAN,	" <name | authid | userid> - Get the ammount of points the player has." );
	register_concmd( "amx_set_points",				"ConCmd_SetPlayerPoints",	ADMIN_BAN,	" <name | authid | userid> <#points> - Set the ammount of points the player has." );
	register_concmd( "amx_give_points",				"ConCmd_GivePlayerPoints",	ADMIN_BAN,	" <name | authid | userid> <#points> - Give an ammount of points to a player." );
	register_concmd( "amx_banct",					"ConCmd_BanCT",			ADMIN_BAN,	" <name | authid | userid> - Set a ct ban for a player." );
	register_concmd( "amx_addbanct",				"ConCmd_AddBanCT",		ADMIN_BAN,	" <authid> - Set a ct ban for an offline player." );
	register_concmd( "amx_unbanct",					"ConCmd_UnBanCT",		ADMIN_BAN,	" <authid> - Removes a player's ban" );
	
	/* HamHooks */
	RegisterHam( Ham_Spawn,			"player",		"Ham_Spawn_Player_Post",		true );
	RegisterHam( Ham_Killed,		"player",		"Ham_Killed_Player_Pre",		false );
	RegisterHam( Ham_Use,			"func_healthcharger",	"Ham_Use_Recharger_Pre",		false );
	RegisterHam( Ham_Use,			"func_recharge",	"Ham_Use_Recharger_Pre",		false );
	
	/* Messages */
	register_message( get_user_msgid( "ShowMenu" ),			"Message_ShowMenu" );
	register_message( get_user_msgid( "VGUIMenu" ),			"Message_VGUIMenu" );
	
	/* Forwards */
	register_forward( FM_GetGameDescription,			"Forward_GetGameDescription_Pre",	0 );
	UnregisterSpawnForward( );
	
	/* Block Hint Messages */
	set_msg_block( get_user_msgid( "HudTextArgs" ), BLOCK_SET );
	
	/* Tasks */
	set_task( 1.0, "Task_ShowTopInfo", _, _, _, "b" );
	
	/* Impulses */
	register_impulse( 201, "Impulse_Spray" );
	register_impulse( 100, "Impulse_FlashLight" );
	
	/* Menus */
	new iKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_0;
	
	register_menu( "Day Vote",		1023,			"Handle_DayVote" );
	register_menu( "Free Vote",		iKeys,			"Handle_FreeVote" );
	register_menu( "NightCrawler Vote",	iKeys,			"Handle_NightCrawlerVote" );
	register_menu( "Zombie Vote",		iKeys,			"Handle_ZombieVote" );
	register_menu( "Shark Vote",		iKeys,			"Handle_SharkVote" );
	
	/* Register the knives */
	// RegisterKnives( );
	// CheckKnifePlugin( );
}

public plugin_cfg( ) {
	/*
		You know those things that you can change the values of
		in order to change how stuff work? These are it, they are
		called CVARs. We register them so amxmodx knows about this.
	*/
	RegisterPCVARs( );
	
	/*
		Read the config file and use those values.
	*/
	ExecConfig( );
	
	/*
		Since we registered the CVARs, and then executed our 
		config file, now its safe to save the values of certain
		CVARs. It is important to do this after executing the
		config file to get the true values and not the default ones.
	*/
	ReloadPCVARs( );
	
	/*
		Search for the cell doors button and save it.
	*/
	OpenButtonsVault( );		/* Opens the vault where we stored our buttons */
	GetButtonsVault( );		/* This will search in the vault for button to the specific map */
	SearchForButton( );		/* After getting the button, search for it on the map */
	CloseButtonsVault( );		/* We don't need the vault anymore, so close it */
	
	/*
		In here we will open the vaults that we are going to use in this plugin,
		we open them once at the beginning so we can use it anywhere. Better than opening
		and closing the vault everytime.
	*/
	OpenTimeVault( );
	OpenPointsVault( );
	OpenCTBanVault( );
}

public plugin_precache( ) {
	/*
		Precaching all the sounds that are going to be used.
	*/
	for( new iLoop = 0; iLoop < MAX_SOUNDS; iLoop++ ) {
		precache_sound( g_strSounds[ iLoop ] );
	}
	
	/*
		Precaching all the models and sounds of the knives.
	*/
	for( new iLoop = 0; iLoop < MAX_KNIVES; iLoop++ ) {
		precache_model( g_strKnifeModels[ iLoop ][ 0 ] );
		precache_model( g_strKnifeModels[ iLoop ][ 1 ] );
		
		precache_sound( g_strKnifeSounds[ iLoop ][ 0 ] );
		precache_sound( g_strKnifeSounds[ iLoop ][ 1 ] );
		precache_sound( g_strKnifeSounds[ iLoop ][ 2 ] );
		precache_sound( g_strKnifeSounds[ iLoop ][ 3 ] );
		precache_sound( g_strKnifeSounds[ iLoop ][ 4 ] );
	}
	
	/*
		Precaching several sprites to be used.
		Laser: for nightcrawler
		Weapon Trail: for when you throw weapon it gets a trail behind it
		Smoke: for the explosion of the suicide bomber
		White: same as smoke above
	*/
	g_iSpriteLaser		= precache_model( "sprites/zbeam4.spr" );
	g_iSpriteWeaponTrail 	= precache_model( "sprites/arrow1.spr" );
	g_iSpriteSmoke 		= precache_model( "sprites/steam1.spr" );
	g_iSpriteWhite 		= precache_model( "sprites/white.spr" );
	
	/*
		This will open up the UltimateJailBreak.ini and read all values. These values
		are going to be used obviously.
	*/
	LoadPluginSettings( );
	
	/*
		Do not allow players to buy anything on the map, this is used cause sometimes
		mappers do not think of this issue and they rely on a plugin to block it for them.
	*/
	RemoveBuyZones( );
}

public plugin_end( ) {
	/*
		Save the player's times and points since the pluging is being unloaded.
	*/
	SavePlayerTime( 0 );
	SavePlayerPoints( 0 );
	
	/*
		Close the vault cause obviously we are not going to use it anymore.
	*/
	CloseTimeVault( );
	CloseCTBanVault( );
	ClosePointsVault( );
}

/* Client Natives */
public client_putinserver( iPlayerID ) {
	/*
		Client has connected, we need to reset some bits as
		it's the players first time on the server. We don't
		want a new connecting player to get values of those
		bits from previously connected players now do we?
	*/
	ClearBit( g_bitIsAlive, 	iPlayerID );
	ClearBit( g_bitHasVoted, 	iPlayerID );
	ClearBit( g_bitHasMenuHidden, 	iPlayerID );
	ClearBit( g_bitHasMicPower,	iPlayerID );
	ClearBit( g_bitHasUnAmmo, 	iPlayerID );
	ClearBit( g_bitHasFreeDay,	iPlayerID );
	ClearBit( g_bitHasHealthEnabled,iPlayerID );
	
	SetBit( g_bitIsFirstConnect,	iPlayerID );
	
	g_iPlayerPage[ iPlayerID ] = 0;
	
	/*
		This will not allow the newly connected player to spawn,
		even if he reconnected or not. That is only if a day has
		already started or a last request has as well.
	*/
	if( g_bDayInProgress || g_bLRInProgress ) {
		BlockPlayerSpawn( iPlayerID );
	}
}

public client_authorized( iPlayerID ) {
	/*
		Client has received his Steam ID, then now it is safe to retrieve that
		Steam ID's points, time and whether it is CT banned or not. We get those
		from the vault of course.
	*/
	GetPlayerTime( iPlayerID );
	GetPlayerPoints( iPlayerID );
	GetPlayerCTBan( iPlayerID );
}

public client_disconnect( iPlayerID ) {
	/*
		Player disconnected, so obviously he is not alive anymore.
	*/
	ClearBit( g_bitIsAlive, iPlayerID );
	
	/*
		Check if the disconnected player is envolved in a last request, and
		let the other player win if so.
	*/
	if( g_bLRInProgress ) {
		if( iPlayerID == g_iLastRequestPlayers[ PLAYER_GUARD ] ) {
			EndLastRequest( iPlayerID, g_iLastRequestPlayers[ PLAYER_PRISONER ] );
		} else if( iPlayerID == g_iLastRequestPlayers[ PLAYER_PRISONER ] ) {
			EndLastRequest( iPlayerID, g_iLastRequestPlayers[ PLAYER_GUARD ] );
		}
	}
	
	/*
		Player has disconnected, so we save his time and points.
	*/
	SavePlayerTime( iPlayerID );
	SavePlayerPoints( iPlayerID );
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
		Do other stuff not related to couting alive prisoners.
		
		First reload the CVARs, and reset all buttons so they become clickable.
		We are reloading the CVARs every round because maybe an admin has 
		changed some CVAR values. Reloading the CVARs each round is way better
		than reloading the CVARs everytime a CVAR is going to be used.
	*/
	ReloadPCVARs( );
	ResetButtons( );
	
	/*
		We save all player's time and points every round, just to be on the safe side.
		And then we close both vaults and then open them again, that way (i think),
		if the server crashed, turned off, or whatever happens, the points are saved.
	*/
	SavePlayerTime( 0 );
	SavePlayerPoints( 0 );
	
	CloseTimeVault( );
	OpenTimeVault( );
	
	ClosePointsVault( );
	OpenPointsVault( );
	
	/*
		Check if blocking microphones CVAR has changed, and act accordingly.
	*/
	if( g_iRestrictMicrophones ) {
		g_fwdSetClientListening = register_forward( FM_Voice_SetClientListening, "Forward_SetClientListening_Pre", 0 );
	} else {
		if( g_fwdSetClientListening ) {
			unregister_forward( FM_Voice_SetClientListening, 0 );
		}
	}
	
	/*
		Check if the shooting buttons cvar has changed and act accordingly.
	*/
	if( g_iShootButtons ) {
		if( g_hamTraceAttackButton ) {
			EnableHamForward( g_hamTraceAttackButton );
		} else {
			g_hamTraceAttackButton = RegisterHam( Ham_TraceAttack, "func_button", "Ham_TraceAttack_Button_Pre", false );
		}
	} else {
		if( g_hamTraceAttackButton ) {
			DisableHamForward( g_hamTraceAttackButton );
		}
	}
}

public Event_DelayedHLTV( ) {
	/*
		HLTV is executed only once every round, so this way we know that a round
		has passed, hence a day has passed. That means we increment the value by one.
	*/
	g_iDayCount++;
	
	/*
		Set the very first round as an Unrestricted FreeDay.
	*/
	if( g_iDayCount == 1 && get_pcvar_num( g_pcvarDayVoteFirstFreeday ) ) {
		#if defined DEBUG
		log_amx( "First day forced as unrestricted free day" );
		#endif
		
		g_iTypeFree = TYPE_UNRESTRICTED;
		StartFreeDay( );
		
		client_print_color( 0, print_team_default, "^4%s^1 The first day is always an ^4Unrestricted Free Day^1. Have Fun!", g_strPluginPrefix );
		
		return;
	}
	
	/*
		Check whether to make the vote appear at round start or not.
		0: never make the vote, always cage day (admins must force days)
		1: always make the vote
		#: make the vote if there is less than # minutes remaining of the map.
	*/
	switch( g_iDayVote ) {
		case 0: {
			#if defined DEBUG
			log_amx( "g_iDayVote is 0, forcing cage day" );
			#endif
			
			g_iDayCurrent = DAY_CAGE;
			StartDay( );
			
			client_print_color( 0, print_team_default, "^4%s^1 Day has been set to ^4Cage Day^1.", g_strPluginPrefix );
		}
		
		case 1: {
			#if defined DEBUG
			log_amx( "g_iDayVote is 1, starting day vote" );
			#endif
			
			StartDayVote( );
		}
		
		default: {
			if( get_timeleft( ) <= ( 60 * g_iDayVote ) ) {
				#if defined DEBUG
				log_amx( "g_iDayVote is a #, map timeleft satisfied, showing day vote" );
				#endif
				
				StartDayVote( );
			} else {
				#if defined DEBUG
				log_amx( "g_iDayVote is a #, map timeleft not satisfied, forcing cage day" );
				#endif
				
				g_iDayCurrent = DAY_CAGE;
				StartDay( );
				
				client_print_color( 0, print_team_default, "^4%s^1 Day has been set to ^4Cage Day^1.", g_strPluginPrefix );
			}
		}
	}
}

public Event_TextMsg_RestartRound( ) {
	/*
		An admin has restarted the round or game is a draw, so end
		the day if it started or end last request if it started.
	*/
	if( g_bDayInProgress ) {
		EndDay( );
	}
	
	if( g_bLRInProgress ) {
		EndLastRequest( 0, 0 );
	}
}

public Event_CurWeapon( iPlayerID ) {
	/*
		This event is called whenever the player changed his weapon, or
		the ammount of bullets and backpack needs to be updated. So it is
		a safe bet to check for ammo here and refill it when the player has
		unlimited ammo.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return PLUGIN_CONTINUE;
	}
	
	static iWeaponID;
	iWeaponID = read_data( 2 );
	
	if( CheckBit( g_bitHasUnAmmo, iPlayerID ) ) {
		switch( iWeaponID ) {
			case CSW_C4, CSW_KNIFE, CSW_HEGRENADE, CSW_FLASHBANG, CSW_SMOKEGRENADE: {
				return PLUGIN_CONTINUE;
			}
		}
		
		static const iWeaponBPAmmo[ ] = {
			0, 52, 0, 90, 1, 32, 1, 100, 90, 1, 120, 100, 100, 90, 90, 90,
			100, 120, 30, 120, 200, 32, 90, 120, 90, 2, 35, 90, 90, 0, 100
		};
		
		if( cs_get_user_bpammo( iPlayerID, iWeaponID ) != iWeaponBPAmmo[ iWeaponID ] ) {
			cs_set_user_bpammo( iPlayerID, iWeaponID, iWeaponBPAmmo[ iWeaponID ] );
		}
	}
	
	return PLUGIN_CONTINUE;
}

public Event_Health( iPlayerID ) {
	/*
		Health of a user has changed, therefore we update our own health HUD display.
	*/
	Task_ShowHealth( iPlayerID );
}

public Event_Spray( ) {
	new iPlayerID = read_data( 2 );
	
	if( !g_iSprayChecker ) {
		return PLUGIN_CONTINUE;
	}
	
	if( g_bAllowSprayMeter || g_bLRInProgress && g_iLRCurrent == LR_SPRAY && ( iPlayerID == g_iLRLastTerrorist || iPlayerID == g_iLastRequestPlayers[ PLAYER_GUARD ] ) ) {
		new Float:fSprayOrigin[ 3 ];
		read_data( 3, fSprayOrigin[ 0 ] );
		read_data( 4, fSprayOrigin[ 1 ] );
		read_data( 5, fSprayOrigin[ 2 ] );
		
		new Float:fPlayerOrigin[ 3 ];
		pev( iPlayerID, pev_origin, fPlayerOrigin );
		
		new Float:fDirection[ 3 ];
		xs_vec_sub( fSprayOrigin, fPlayerOrigin, fDirection );
		xs_vec_mul_scalar( fDirection, 10.0 / vector_length( fDirection ), fDirection );

		new Float:fStop[ 3 ];
		xs_vec_add( fSprayOrigin, fDirection, fStop );
		xs_vec_mul_scalar( fDirection, -1.0, fDirection );
		
		new Float:fStart[ 3 ];
		xs_vec_add( fSprayOrigin, fDirection, fStart );
		engfunc( EngFunc_TraceLine, fStart, fStop, IGNORE_MONSTERS, -1, 0 );
		get_tr2( 0, TR_vecPlaneNormal, fDirection );
		fDirection[ 2 ] = 0.0;
		
		xs_vec_mul_scalar( fDirection, 5.0 / vector_length( fDirection ), fDirection );
		xs_vec_add( fSprayOrigin, fDirection, fStart );
		xs_vec_copy( fStart, fStop );
		fStop[ 2 ] -= 9999.0;
		
		engfunc( EngFunc_TraceLine, fStart, fStop, IGNORE_MONSTERS, -1, 0 );
		get_tr2( 0, TR_vecEndPos, fStop );

		new Float:fSprayDistance = fStart[ 2 ] - fStop[ 2 ];
		
		new strPlayerName[ 32 ];
		get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 Sprayed ^4%i unites^1 off the ground.", g_strPluginPrefix, strPlayerName, floatround( fSprayDistance ) );
	}
	
	return PLUGIN_CONTINUE;
}

public Event_Money( iPlayerID ) {
	if( is_user( iPlayerID ) ) {
		cs_set_user_money( iPlayerID, g_iPlayerPoints[ iPlayerID ], 0 );
	}
}

/* LogEvents */
public LogEvent_RoundStart( ) {
	/*
		Round has started (when freezetime has finished), so set a task to when the
		round timer is over to stop the round from taking too much time.
	*/
	if( get_pcvar_num( g_pcvarDayVoteEndAtZero ) ) {
		set_task( get_pcvar_float( g_cvarRoundTime ) * 60.0, "Task_EndRound", TASK_END_ROUND );
	}
	
	/*
		Check if at the beginning of the round there is only 1 prisoner, so
		grant him his last request.
	*/
	CheckIfLastPrisoner( );
	
	if( g_iPoints && GetTeamPlayersNumber( "A" ) >= g_iPluginSettings[ POINTS_MIN_PLAYERS ] ) {
		g_bGivePoints = true;
		
		if( g_hamTraceAttackPlayer ) {
			EnableHamForward( g_hamTraceAttackPlayer );
		} else {
			g_hamTraceAttackPlayer = RegisterHam( Ham_TraceAttack, "player", "Ham_TraceAttack_Player_Post", true );
		}
	} else {
		g_bGivePoints = false;
		
		if( g_hamTraceAttackPlayer ) {
			DisableHamForward( g_hamTraceAttackPlayer );
		}
	}
	
	if( g_bGivePoints ) {
		new iPlayers[ 32 ], iNum, iTempID;
		get_players( iPlayers, iNum, "ae", "TERRORIST" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			g_iPlayerPoints[ iTempID ] += g_iPluginSettings[ POINTS_ROUND_START ];
			
			client_print_color( iTempID, print_team_red, "^4%s^1 You have been given ^3%i point(s)^1 for playing another round.", g_strPluginPrefix, g_iPluginSettings[ POINTS_ROUND_START ] );
			Event_Money( iTempID );
		}
	}
	
	g_bAllowShop = true;
}

public LogEvent_RoundEnd( ) {
	if( g_bGivePoints ) {
		new iPlayers[ 32 ], iNum, iTempID;
		get_players( iPlayers, iNum, "ae", "TERRORIST" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			g_iPlayerPoints[ iTempID ] += g_iPluginSettings[ POINTS_ROUND_END ];
			Event_Money( iTempID );
			
			client_print_color( iTempID, print_team_default, "^4%s^1 Way to survive the round! Here take those ^4%i point(s)^1.", g_strPluginPrefix, g_iPluginSettings[ POINTS_ROUND_END ] );
		}
	}
	
	if( g_bDayInProgress ) {
		EndDay( );
	}
	
	if( g_bLRInProgress ) {
		EndLastRequest( 0, 0 );
	}
}

/* ClCmds */
public ClCmd_ForceDay( iPlayerID ) {
	/*
		Admin wants to force a day, so check if he has access and show him 
		the menu.
	*/
	if( access( iPlayerID, ADMIN_START_DAY ) ) {
		StartForceDayMenu( iPlayerID );
	} else {
		client_print_color( iPlayerID, print_team_red, "^4%s^3 Access Denied!^1 Only ^3Admins^1 are allowed to use this command.", g_strPluginPrefix );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_OpenCells( iPlayerID ) {
	/*
		User wants to open the cell doors, check the cvar value and act accordingly.
		0: no one is able to use this command
		1: only admins are able to use this command
		2: admin and guards are able to use this command
		
		If check has passed, get the name of the player and print the action to all
		players.
	*/
	switch( g_iOpenCommand ) {
		case 0: {
			client_print_color( iPlayerID, print_team_red, "^4%s^1 Command has been ^3disabled^1 on this server.", g_strPluginPrefix );
			
			return PLUGIN_HANDLED;
		}
		
		case 1: {
			if( !access( iPlayerID, ADMIN_OPEN ) ) {
				client_print_color( iPlayerID, print_team_red, "^4%s^3 Access denied!^1 Only ^4Admins^1 can use this command.", g_strPluginPrefix );
				
				return PLUGIN_HANDLED;
			}
		}
		
		case 2: {
			if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT && !is_user_admin( iPlayerID ) ) {
				client_print_color( iPlayerID, print_team_red, "^4%s^3 Access denied!^1 Only ^4Admins^1 and ^4Guards^1 can use this command.", g_strPluginPrefix );
				
				return PLUGIN_HANDLED;
			}
		}
	}
	
	OpenCells( );
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
	
	client_print_color( 0, iPlayerID, "^4%s^3 %s^1 has opened the cells remotely.", g_strPluginPrefix, strPlayerName );
	
	return PLUGIN_HANDLED;
}

public ClCmd_ShowCredits( iPlayerID ) {
	/*
		Display the name of the almighty scripter who made this plugin.
		He is the best, we all love him and worship him.
		
		T O N Y   K A R A M   1 9 9 3
	*/
	client_print_color( iPlayerID, print_team_default, "^4%s^1 This mod is scripted by ^4%s^1. Contact: ^4tonykaram1993@gmail.com^1.", g_strPluginPrefix, g_strPluginAuthor );
}

public ClCmd_StartNadeWar( iPlayerID ) {
	/*
		This command is going to be used when it is nade war day. Basically this allows
		the guards to group all the prisoners in a wide area, and start it. The guard
		must be alive and it should a nade war day obviously as well as allowed to use
		this command.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be a ^3Guard^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iDayCurrent != DAY_NADEWAR ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You can only use this command on a NadeWar Day.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bAllowNadeWar ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You are not allowed to use this command anymore.", g_strPluginPrefix );
	} else {
		g_bAllowNadeWar = false;
		
		/*
			Give a 5 second delay so prisoners are not surprised about it.
		*/
		set_task( 5.0, "Task_NadeWar_Start", TASK_NADEWAR_START );
		
		client_print_color( 0, print_team_default, "^4%s^1 Get ready! Nadewar will start in^4 5 seconds^1.", g_strPluginPrefix );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_StartHotPotato( iPlayerID ) {
	/*
		This is to be used when the prisoner and the guard are ready in last request.
		The prisoner must obviously be alive and it should be hot potato and not something
		else.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be a ^3Guard^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iLRCurrent != LR_HOTPOTATO ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You can only use this command on Hot Potato.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bAllowStartHotPotato ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You are not allowed to use this command anymore.", g_strPluginPrefix );
	} else {
		g_bAllowStartHotPotato = false;
		
		/*
			Start the countdown to let both players know that the game is about to start.
		*/
		g_iTimeLeft = TIME_COUNTDOWN_HOTPOTATO;
		set_task( 1.0, "Task_Countdown_HotPotato", TASK_COUNTDOWN_HOTPOTATO, _, _, "a", g_iTimeLeft );
		
		client_print_color( 0, print_team_default, "^4%s^1 Get ready! Hot Potato will start shortly.", g_strPluginPrefix );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_StartShowdown( iPlayerID ) {
	/*
		This is to be used when the prisoner and the guard are ready in last request.
		The prisoner must obviously be alive and it should be showdown and not something
		else.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be a ^3Guard^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iLRCurrent != LR_SHOWDOWN ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You can only use this command on a Showdown.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bAllowStartShowdown ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You are not allowed to use this command anymore.", g_strPluginPrefix );
	} else {
		g_bAllowStartShowdown = false;
		
		client_print( iPlayerID, print_center, "Get ready for a showdown. Only shoot when you read 'SHOOT'!" );
		client_print( g_iLastRequestPlayers[ PLAYER_GUARD ], print_center, "Get ready for a showdown. Only shoot when you read 'SHOOT'" );
		
		set_task( random_float( 3.0, 5.0 ), "Task_Start_Showdown", TASK_START_SHOWDOWN );
		
		client_print_color( 0, print_team_default, "^4%s^1 Get ready! Showdown will start shortly.", g_strPluginPrefix );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_StartRace( iPlayerID ) {
	/*
		This will start the race countdown. When timer ends, then the race officially 
		starts. Check stuff and do some other stuff below.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You have to be alive in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be a ^3Guard^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iLRCurrent != LR_RACE ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You can only use this command on a Race.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_bAllowStartRace ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You are not allowed to use this command anymore.", g_strPluginPrefix );
	} else {
		g_bAllowStartRace = false;
		
		g_iTimeLeft = TIME_COUNTDOWN_RACE;
		set_task( 1.0, "Task_Countdown_Race", TASK_COUNTDOWN_RACE, _, _, "a", g_iTimeLeft );
		
		client_print_color( 0, print_team_default, "^4%s^1 Get ready! Race will start shortly.", g_strPluginPrefix );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_ShowHealth( iPlayerID ) {
	/*
		This command allows the player to switch on or off his health HUD display. Because
		some players might find it annoying after all, so let's please them :D
	*/
	if( !g_iShowHealth ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 This command has been ^3disabled^1 on this server.", g_strPluginPrefix );
	} else {
		if( CheckBit( g_bitHasHealthEnabled, iPlayerID ) ) {
			client_print_color( iPlayerID, print_team_red, "^4%s^1 You have ^3disabled^1 your health HUD display.", g_strPluginPrefix );
		} else {
			Task_ShowHealth( TASK_SHOWHEALTH + iPlayerID );
			
			client_print_color( iPlayerID, print_team_default, "^4%s^1 You have ^4enabled^1 your health HUD display.", g_strPluginPrefix );
		}
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_ShowGunsMenu( iPlayerID ) {
	/*
		This command will bring up the weapons menu so you can change your weapons. Since 
		we do not want players to abuse this menu, we are checking and allowing it only on
		some days where it does not matter that much.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be ^3alive^1 in order to use this command.", g_strPluginPrefix );
	} else {
		switch( g_iDayCurrent ) {
			case DAY_FREE, DAY_CAGE, DAY_RIOT: {
				if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
					client_print_color( iPlayerID, print_team_blue, "^4%s^1 Only ^3Guards^1 are allowed to use this command.", g_strPluginPrefix );
				} else {
					ShowWeaponMenu( iPlayerID );
				}
			}
			
			default: {
				client_print_color( iPlayerID, print_team_red, "^4%s^1 The Gun Menu has been blocked on this day to prevent abuse.", g_strPluginPrefix );
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_FreeForAll( iPlayerID ) {
	/*
		This command will turn on free for all. Obviously we are gonna allow it on 
		all days, so we are letting the admins turn it on on some special days.
	*/
	if( !is_user_admin( iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 Only ^3Admins^1 are allowed to use this command.", g_strPluginPrefix );
	} else {
		switch( g_iDayCurrent ) {
			case DAY_CAGE, DAY_FREE, DAY_RIOT, DAY_CUSTOM, DAY_JUDGEMENT: {
				new strPlayerName[ 32 ];
				get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
				
				if( !g_bFFA ) {
					client_print_color( 0, iPlayerID, "^4%s^3 %s^1 turned on ^4Free For All^1.", g_strPluginPrefix );
					
					SetFreeForAll( 1 );
				} else {
					client_print_color( 0, iPlayerID, "^4%s^3 %s^1 turned off ^4Free For All^1.", g_strPluginPrefix );
					
					SetFreeForAll( 0 );
				}
			}
			
			default: {
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You ^3cannot^1 use this command on this day.", g_strPluginPrefix );
			}
		}
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_ShowDayVote( iPlayerID ) {
	/*
		When the day vote is not shown everyday, allow the admins to start it only when
		the day vote is not shown every day. And then tell everybody about it.
	*/
	if( !is_user_admin( iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be an ^3Admin^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iTimeLeft == 1 ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You are ^3not allowed^1 to start a vote when a vote is automatically started at the start of each round.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
	
	StartDayVote( );
	
	client_print_color( 0, iPlayerID, "^4%s^3 %s^1 has started a ^4Day Vote^1.", g_strPluginPrefix );
	
	return PLUGIN_HANDLED;
}

public ClCmd_ShowFreeDayMenu( iPlayerID ) {
	/*
		Allow guards and admins to open up a menu where they can give some prisoners
		personal free days, maybe because the got free killed the round before.
	*/
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT && !is_user_admin( iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be a ^4Guard^1 or an ^4Admin^1 in order to use this command.", g_strPluginPrefix );
	} else if( g_iDayCurrent != DAY_CAGE ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You can only give free days on a ^3Cage Day^1.", g_strPluginPrefix );
	} else {
		ShowFreeDayMenu( iPlayerID );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_LastRequest( iPlayerID ) {
	/*
		This will allow the last prisoner to start his last request. So we are checking
		if he is the last prisoner, and if it appears that he isn't, check again.
	*/
	if( g_iLRLastTerrorist != iPlayerID && !CheckIfLastPrisoner( ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You are not the last ^3Prisoner^1 alive in order to use this command.", g_strPluginPrefix );
	} else {
		new strPlayerName[ 32 ];
		get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 is now picking a ^4Last Request^1 option. Get Read!", g_strPluginPrefix, strPlayerName );
		
		ShowLastRequestMenu( iPlayerID );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_Commander( iPlayerID ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be ^3alive^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be a ^3Guard^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iDayCurrent != DAY_CAGE ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You can only be the ^3Commander^1 on a ^4Cage Day^1.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_iCommander ) {
		client_print_color( 0, print_team_red, "^4%s^1 This option has been ^3disabled^1 on this server.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( iPlayerID == g_iCommanderGuard ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You're already the ^3Commander^1.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( g_iCommanderGuard != -1 ) {
		new strPlayerName[ 32 ];
		get_user_name( g_iCommanderGuard, strPlayerName, charsmax( strPlayerName ) );
		
		client_print_color( iPlayerID, print_team_blue, "^4%s^3 %s^1 is already the ^4Commander^1.", g_strPluginPrefix, strPlayerName );
	} else {
		g_iCommanderGuard = iPlayerID;
		
		set_user_rendering( iPlayerID, kRenderFxGlowShell, 220, 220, 0, kRenderNormal, 5 );
		
		new strPlayerName[ 32 ];
		get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
		
		client_print_color( 0, print_team_blue, "^4%s^3 %s^1 is now the ^3Commander^1. He has control of the current ^4Cage Day^1.", g_strPluginPrefix, strPlayerName );
	}
	
	Task_ShowTopInfo( );
	
	return PLUGIN_HANDLED;
}

public ClCmd_CommanderMenu( iPlayerID ) {
	if( iPlayerID != g_iCommanderGuard ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have to be the ^3Commander^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !g_iCommander ) {
		client_print_color( 0, print_team_red, "^4%s^1 This options has been ^4disabled^1 on this server.", g_strPluginPrefix );
	} else {
		ShowCommanderMenu( iPlayerID );
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_DisplayTime( iPlayerID ) {
	client_print_color( iPlayerID, iPlayerID, "^4%s^1 Our records show that you have played here for ^3%d minutes(s)^1.", g_strPluginPrefix, g_iPlayerTime[ iPlayerID ] + get_user_time( iPlayerID ) / 60 );
	client_print_color( iPlayerID, iPlayerID, "^4%s^1 Current session time: ^3%d minute(s)^1.", g_strPluginPrefix, get_user_time( iPlayerID ) / 60 );
	
	return PLUGIN_HANDLED;
}

public ClCmd_DisplayPoints( iPlayerID ) {
	client_print_color( iPlayerID, print_team_red, "^4%s^1 You have ^3%i points^1 to use in the shop.", g_strPluginPrefix, g_iPlayerPoints[ iPlayerID ] );
	
	return PLUGIN_HANDLED;
}

public ClCmd_OpenShop( iPlayerID ) {
	if( cs_get_user_team( iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be a ^3Prisoner^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have to be ^3alive^1 in order to use this command.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	switch( g_iDayCurrent ) {
		case DAY_CAGE: {
			if( !g_bAllowShop ) {
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You are ^3not allowed^1 to open the ^4Shop Menu^1 at this time.", g_strPluginPrefix );
			} else {
				ShowShopMenu( iPlayerID );
			}
		}
		
		default: {
			client_print_color( iPlayerID, print_team_red, "^4%s^1 You ^3cannot^1 use this command on this day.", g_strPluginPrefix );
		}
	}
	
	return PLUGIN_HANDLED;
}

public ClCmd_FunMenu( iPlayerID ) {
	// TODO: make the fun menu
}

public ClCmd_ShowVIPMenu( iPlayerID ) {
	// TODO: make the vip menu
}

public ClCmd_ShowRules( iPlayerID ) {
	// TODO: put the rules url
}


public ClCmd_Say( iPlayerID ) {
	if( g_bCatchAnswer ) {
		new strString[ 8 ];
		read_argv( 1, strString, charsmax( strString ) );
		
		if( str_to_num( strString ) == g_iMathQuestionResult ) {
			new strPlayerName[ 32 ];
			get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
			
			set_user_rendering( iPlayerID, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
			set_task( 5.0, "Task_UnglowRandomPlayer", TASK_UNGLOW_RANDOMPLAYER + iPlayerID );
			
			set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
			show_hudmessage( 0, "%s answered first", strPlayerName );
		}
		
		g_bCatchAnswer = false;
	}
}

public ClCmd_WeaponDrop( iPlayerID ) {
	/*
		Block weapon drop ability to specific teams/players on specific days.
		Why am i blocking drop? Because on some days, its not possible to pick up
		or get weapons from the ground or anywhere for that matter, so if he dropped
		his weapon, he won't be able to pick it up anymore.
	*/
	if( g_bDayInProgress ) {
		switch( g_iDayCurrent ) {
			/*
				Block only for president, obviously on president day.
			*/
			case DAY_PRESIDENT: {
				if( iPlayerID == g_iPresident ) {
					return PLUGIN_HANDLED;
				}
			}
			
			/*
				Block if player is a guard.
			*/
			case DAY_HULK, DAY_JUDGEMENT: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
					return PLUGIN_HANDLED;
				}
			}
			
			/*
				Block if you are a prisoner and lms is not over yet.
			*/
			case DAY_LMS: {
				if( cs_get_user_team( iPlayerID ) == CS_TEAM_T && !g_bLMSWeaponsOver ) {
					return PLUGIN_HANDLED;
				}
			}
			
			/*
				Block for all players.
			*/
			case DAY_COWBOY, DAY_SPACE, DAY_USP_NINJA: {
				return PLUGIN_HANDLED;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public ClCmd_ChooseTeam( iPlayerID ) {
	if( !g_iMainMenu || g_bPluginCommand ) {
		return PLUGIN_CONTINUE;
	}
	
	ShowMainMenu( iPlayerID );
	
	return PLUGIN_HANDLED;
}

/* ConCmd */
public ConCmd_SetButton( iPlayerID, iLevel, iCid ) {
	/*
		Set the button that is used to open the cells so it can be used by /open and 
		others.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 1 ) ) {
		return PLUGIN_HANDLED;
	}
	
	/*
		Get entity the admin is aiming at. That is how the admin must use it, aim at 
		the button and then issue the command.
	*/
	new iEntity = GetAimingEnt( iPlayerID );
	
	if( !is_valid_ent( iEntity ) ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You are not aiming at a button.", g_strPluginPrefix );
		
		return PLUGIN_HANDLED;
	}
	
	g_iCellsButton = iEntity;
	
	/*
		Get the model name of the button and store it in the vault. Since we closed
		that vault on precache, we are reopining it and then closing it when we are
		done.
	*/
	new strModelName[ 32 ];
	pev( iEntity, pev_model, strModelName, charsmax( strModelName ) );
	
	new strMapName[ 32 ];
	get_mapname( strMapName, charsmax( strMapName ) );
	
	OpenButtonsVault( );
	SaveButtonsVault( strMapName, strModelName );
	CloseButtonsVault( );
	
	client_print_color( iPlayerID, print_team_default, "^4%s^1 The cells button has been saved. Thank you!", g_strPluginPrefix );
	
	return PLUGIN_HANDLED;
}

public ConCmd_SetMic( iPlayerID, iLevel, iCid ) {
	/*
		Allow admins to give players microphone ability. This will of course last only one
		round.
	*/
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTagetName[ 32 ];
	read_argv( 1, strTagetName, charsmax( strTagetName ) );
	
	new iTarget = cmd_target( iPlayerID, strTagetName, CMDTARGET_OBEY_IMMUNITY | CMDTARGET_ALLOW_SELF );
	
	if( !iTarget ) {
		return PLUGIN_HANDLED;
	}
	
	new strStatus[ 2 ];
	read_argv( 2, strStatus, 1 );
	
	new strAdminName[ 32 ];
	get_user_name( iPlayerID, strAdminName, charsmax( strAdminName ) );
	get_user_name( iTarget, strTagetName, charsmax( strTagetName ) );
	
	/*
		Tell the users and the admin of the action.
	*/
	if( str_to_num( strStatus ) ) {
		SetBit( g_bitHasMicPower, iTarget );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 set ^4%s^1's microphone status to ON.", g_strPluginPrefix, strAdminName, strTagetName );
		
		client_cmd( iTarget, "spk ^"vox/communication acquired^"" );
	} else {
		ClearBit( g_bitHasMicPower, iTarget );
		
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 set ^4%s^1's microphone status to OFF.", g_strPluginPrefix, strAdminName, strTagetName );
		
		client_cmd( iTarget, "spk ^"vox/communication deactivated^"" );
	}
	
	return PLUGIN_HANDLED;
}

public ConCmd_GetPlayerTime( iPlayerID, iLevel, iCid ) {
	if( !cmd_access( iPlayerID, iLevel, iCid, 1 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, charsmax( strTarget ) );
	
	if( strTarget[ 0 ] == '@' ) {
		new iPlayers[ 32 ], iNum, iTempID;
		new strTeam[ 32 ];
		
		switch( strTarget[ 1 ] ) {
			case 'A', 'a': {
				get_players( iPlayers, iNum );
				formatex( strTeam, charsmax( strTeam ), "All" );
			}
			
			case 'T', 't': {
				get_players( iPlayers, iNum, "e", "TERRORIST" );
				formatex( strTeam, charsmax( strTeam ), "Terrorist" );
			}
			
			case 'C', 'c': {
				get_players( iPlayers, iNum, "e", "CT" );
				formatex( strTeam, charsmax( strTeam ), "Counter-Terrorist" );
			}
			
			case 'S', 's': {
				get_players( iPlayers, iNum, "e", "SPECTATOR" );
				formatex( strTeam, charsmax( strTeam ), "Spectator" );
			}
			
			default: {
				console_print( iPlayerID, "It appears that you entered an invalid team." );
				
				return PLUGIN_HANDLED;
			}
		}
		
		console_print( iPlayerID, "--------------------------------------------" );
		console_print( iPlayerID, "Below you will find all the %s team players along with their time played^n", strTeam );
		
		console_print( iPlayerID, "PLAYER_NAME | CURRENT_SESSION | PLAYED_TIME^n" );
		
		new strPlayerName[ 32 ], iPlayerTime;
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			iPlayerTime = get_user_time( iTempID ) / 60;
			
			get_user_name( iTempID, strPlayerName, charsmax( strPlayerName ) );
			console_print( iPlayerID, "* %s | %d | %d", strPlayerName, iPlayerTime, g_iPlayerTime[ iTempID ] + iPlayerTime );
		}
		
		console_print( iPlayerID, "^nA total of %i players have been listed" );
		console_print( iPlayerID, "--------------------------------------------" );
	} else {
		new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );
		
		if( !iTarget ) {
			return PLUGIN_HANDLED;
		}
		
		new strPlayerName[ 32 ];
		get_user_name( iTarget, strPlayerName, charsmax( strPlayerName ) );
		
		new iPlayerTime = get_user_time( iTarget ) / 60;
		
		console_print( iPlayerID, "%s's current session time is %d minute(s)", iPlayerTime );
		console_print( iPlayerID, "%s's total played time is %d minute(s)", g_iPlayerTime[ iTarget ] + iPlayerTime );
	}
	
	return PLUGIN_HANDLED;
}

public ConCmd_SetPlayerTime( iPlayerID, iLevel, iCid ) {
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, charsmax( strTarget ) );
	
	new strTime[ 16 ];
	read_argv( 2, strTime, charsmax( strTime ) );
	
	new iTime = str_to_num( strTime );
	
	if( strTarget[ 0 ] == '@' ) {
		new iPlayers[ 32 ], iNum;
		new strTeam[ 32 ];
		
		switch( strTarget[ 1 ] ) {
			case 'A', 'a': {
				get_players( iPlayers, iNum );
				formatex( strTeam, charsmax( strTeam ), "All" );
			}
			
			case 'T', 't': {
				get_players( iPlayers, iNum, "e", "TERRORIST" );
				formatex( strTeam, charsmax( strTeam ), "Terrorist" );
			}
			
			case 'C', 'c': {
				get_players( iPlayers, iNum, "e", "CT" );
				formatex( strTeam, charsmax( strTeam ), "Counter-Terrorist" );
			}
			
			case 'S', 's': {
				get_players( iPlayers, iNum, "e", "SPECTATOR" );
				formatex( strTeam, charsmax( strTeam ), "Spectator" );
			}
			
			default: {
				console_print( iPlayerID, "It appears that you entered an invalid team." );
				
				return PLUGIN_HANDLED;
			}
		}
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			g_iPlayerTime[ iPlayers[ iLoop ] ] = iTime;
		}
		
		console_print( iPlayerID, "All %s team players's time has been set to %i.", strTeam, iTime );
	} else {
		new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );
		
		if( !iTarget ) {
			return PLUGIN_HANDLED;
		}
		
		new strPlayerName[ 32 ];
		get_user_name( iTarget, strPlayerName, charsmax( strPlayerName ) );
		
		g_iPlayerTime[ iTarget ] = iTime;
		
		console_print( iPlayerID, "%s's time has been set to %i.", strPlayerName, iTime );
	}
	
	CloseTimeVault( );
	OpenTimeVault( );
	
	return PLUGIN_HANDLED;
}

public ConCmd_GivePlayerTime( iPlayerID, iLevel, iCid ) {
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, charsmax( strTarget ) );
	
	new strTime[ 16 ];
	read_argv( 2, strTime, charsmax( strTime ) );
	
	new iTime = str_to_num( strTime );
	
	if( strTarget[ 0 ] == '@' ) {
		new iPlayers[ 32 ], iNum;
		new strTeam[ 32 ];
		
		switch( strTarget[ 1 ] ) {
			case 'A', 'a': {
				get_players( iPlayers, iNum );
				formatex( strTeam, charsmax( strTeam ), "All" );
			}
			
			case 'T', 't': {
				get_players( iPlayers, iNum, "e", "TERRORIST" );
				formatex( strTeam, charsmax( strTeam ), "Terrorist" );
			}
			
			case 'C', 'c': {
				get_players( iPlayers, iNum, "e", "CT" );
				formatex( strTeam, charsmax( strTeam ), "Counter-Terrorist" );
			}
			
			case 'S', 's': {
				get_players( iPlayers, iNum, "e", "SPECTATOR" );
				formatex( strTeam, charsmax( strTeam ), "Spectator" );
			}
			
			default: {
				console_print( iPlayerID, "It appears that you entered an invalid team." );
				
				return PLUGIN_HANDLED;
			}
		}
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			g_iPlayerTime[ iPlayers[ iLoop ] ] += iTime;
		}
		
		console_print( iPlayerID, "All %s team players's time has been given %i minute(s).", strTeam, iTime );
	} else {
		new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );
		
		if( !iTarget ) {
			return PLUGIN_HANDLED;
		}
		
		new strPlayerName[ 32 ];
		get_user_name( iTarget, strPlayerName, charsmax( strPlayerName ) );
		
		g_iPlayerTime[ iTarget ] += iTime;
		
		console_print( iPlayerID, "%s's time has been given %i minute(s).", strPlayerName, iTime );
	}
	
	CloseTimeVault( );
	OpenTimeVault( );
	
	return PLUGIN_HANDLED;
}

public ConCmd_GetPlayerPoints( iPlayerID, iLevel, iCid ) {
	if( !cmd_access( iPlayerID, iLevel, iCid, 1 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, charsmax( strTarget ) );
	
	if( strTarget[ 0 ] == '@' ) {
		new iPlayers[ 32 ], iNum, iTempID;
		new strTeam[ 32 ];
		
		switch( strTarget[ 1 ] ) {
			case 'A', 'a': {
				get_players( iPlayers, iNum );
				formatex( strTeam, charsmax( strTeam ), "All" );
			}
			
			case 'T', 't': {
				get_players( iPlayers, iNum, "e", "TERRORIST" );
				formatex( strTeam, charsmax( strTeam ), "Terrorist" );
			}
			
			case 'C', 'c': {
				get_players( iPlayers, iNum, "e", "CT" );
				formatex( strTeam, charsmax( strTeam ), "Counter-Terrorist" );
			}
			
			case 'S', 's': {
				get_players( iPlayers, iNum, "e", "SPECTATOR" );
				formatex( strTeam, charsmax( strTeam ), "Spectator" );
			}
			
			default: {
				console_print( iPlayerID, "It appears that you entered an invalid team." );
				
				return PLUGIN_HANDLED;
			}
		}
		
		console_print( iPlayerID, "--------------------------------------------" );
		console_print( iPlayerID, "Below you will find all the %s team players along with their points ammount^n", strTeam );
		
		console_print( iPlayerID, "PLAYER_NAME | POINTS^n" );
		
		new strPlayerName[ 32 ];
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			get_user_name( iTempID, strPlayerName, charsmax( strPlayerName ) );
			console_print( iPlayerID, "* %s | %i", strPlayerName, g_iPlayerPoints[ iTempID ] );
		}
		
		console_print( iPlayerID, "^nA total of %i players have been listed" );
		console_print( iPlayerID, "--------------------------------------------" );
		
		get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
		log_amx( "%s requested the list of every player's points.", strPlayerName );
	} else {
		new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );
		
		if( !iTarget ) {
			return PLUGIN_HANDLED;
		}
		
		new strPlayerName[ 32 ];
		get_user_name( iTarget, strPlayerName, charsmax( strPlayerName ) );
		
		console_print( iPlayerID, "%s has %i points.", strPlayerName, g_iPlayerPoints[ iTarget ] );
		
		new strAdminName[ 32 ];
		get_user_name( iPlayerID, strAdminName, charsmax( strAdminName ) );
		
		log_amx( "%s requested to see how much points %s has.", strAdminName, strPlayerName );
	}
	
	return PLUGIN_HANDLED;
}

public ConCmd_SetPlayerPoints( iPlayerID, iLevel, iCid ) {
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, charsmax( strTarget ) );
	
	new strPoints[ 16 ];
	read_argv( 2, strPoints, charsmax( strPoints ) );
	
	new iPoints = str_to_num( strPoints );
	
	new strAdminName[ 32 ];
	get_user_name( iPlayerID, strAdminName, charsmax( strAdminName ) );
	
	if( strTarget[ 0 ] == '@' ) {
		new iPlayers[ 32 ], iNum;
		new strTeam[ 32 ];
		
		switch( strTarget[ 1 ] ) {
			case 'A', 'a': {
				get_players( iPlayers, iNum );
				formatex( strTeam, charsmax( strTeam ), "All" );
			}
			
			case 'T', 't': {
				get_players( iPlayers, iNum, "e", "TERRORIST" );
				formatex( strTeam, charsmax( strTeam ), "Terrorist" );
			}
			
			case 'C', 'c': {
				get_players( iPlayers, iNum, "e", "CT" );
				formatex( strTeam, charsmax( strTeam ), "Counter-Terrorist" );
			}
			
			case 'S', 's': {
				get_players( iPlayers, iNum, "e", "SPECTATOR" );
				formatex( strTeam, charsmax( strTeam ), "Spectator" );
			}
			
			default: {
				console_print( iPlayerID, "It appears that you entered an invalid team." );
				
				return PLUGIN_HANDLED;
			}
		}
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			g_iPlayerPoints[ iPlayers[ iLoop ] ] = iPoints;
		}
		
		console_print( iPlayerID, "All %s team players's points has been set to %i.", strTeam, iPoints );
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 has set all ^4%s^1 team players' points to ^4%i^1.", g_strPluginPrefix, strAdminName, strTeam, iPoints );
		
		log_amx( "%s has set all %s team players' points to %i", strAdminName, strTeam, iPoints );
	} else {
		new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );
		
		if( !iTarget ) {
			return PLUGIN_HANDLED;
		}
		
		new strPlayerName[ 32 ];
		get_user_name( iTarget, strPlayerName, charsmax( strPlayerName ) );
		
		g_iPlayerPoints[ iTarget ] = iPoints;
		
		console_print( iPlayerID, "%s's points has been set to %i.", strPlayerName, iPoints );
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 has set ^4%s^1's points to ^4%i^1.", g_strPluginPrefix, strAdminName, strPlayerName, iPoints );
		
		log_amx( "%s has set %s's points to %i.", strAdminName, strPlayerName, iPoints );
	}
	
	ClosePointsVault( );
	OpenPointsVault( );
	
	return PLUGIN_HANDLED;
}

public ConCmd_GivePlayerPoints( iPlayerID, iLevel, iCid ) {
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, charsmax( strTarget ) );
	
	new strPoints[ 16 ];
	read_argv( 2, strPoints, charsmax( strPoints ) );
	
	new iPoints = str_to_num( strPoints );
	
	new strAdminName[ 32 ];
	get_user_name( iPlayerID, strAdminName, charsmax( strAdminName ) );
	
	if( strTarget[ 0 ] == '@' ) {
		new iPlayers[ 32 ], iNum;
		new strTeam[ 32 ];
		
		switch( strTarget[ 1 ] ) {
			case 'A', 'a': {
				get_players( iPlayers, iNum );
				formatex( strTeam, charsmax( strTeam ), "All" );
			}
			
			case 'T', 't': {
				get_players( iPlayers, iNum, "e", "TERRORIST" );
				formatex( strTeam, charsmax( strTeam ), "Terrorist" );
			}
			
			case 'C', 'c': {
				get_players( iPlayers, iNum, "e", "CT" );
				formatex( strTeam, charsmax( strTeam ), "Counter-Terrorist" );
			}
			
			case 'S', 's': {
				get_players( iPlayers, iNum, "e", "SPECTATOR" );
				formatex( strTeam, charsmax( strTeam ), "Spectator" );
			}
			
			default: {
				console_print( iPlayerID, "It appears that you entered an invalid team." );
				
				return PLUGIN_HANDLED;
			}
		}
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			g_iPlayerPoints[ iPlayers[ iLoop ] ] += iPoints;
		}
		
		console_print( iPlayerID, "All %s team players's points has been given %i point(s).", strTeam, iPoints );
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 gave ^4%s^1 team players ^4%i^1 point(s).", g_strPluginPrefix, strAdminName, strTeam, iPoints );
		
		log_amx( "%s gave %s team players %i points.", strAdminName, strTeam, iPoints );
	} else {
		new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );
		
		if( !iTarget ) {
			return PLUGIN_HANDLED;
		}
		
		new strPlayerName[ 32 ];
		get_user_name( iTarget, strPlayerName, charsmax( strPlayerName ) );
		
		g_iPlayerPoints[ iTarget ] += iPoints;
		
		console_print( iPlayerID, "%s's points has been given %i point(s).", strPlayerName, iPoints );
		client_print_color( 0, iPlayerID, "^4%s^3 %s^1 gave ^4%s %i^1 points.", g_strPluginPrefix, strAdminName, strPlayerName, iPoints );
		
		log_amx( "%s gave %s %i points.", strAdminName, strPlayerName, iPoints );
	}
	
	ClosePointsVault( );
	OpenPointsVault( );
	
	return PLUGIN_HANDLED;
}

public ConCmd_BanCT( iPlayerID, iLevel, iCid ) {
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, charsmax( strTarget ) );
	
	new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );
	
	if( !iTarget ) {
		return PLUGIN_HANDLED;
	}
	
	new strPlayerAuthID[ 36 ];
	get_user_authid( iPlayerID, strPlayerAuthID, charsmax( strPlayerAuthID ) );
	
	new strFormatex[ 64 ];
	formatex( strFormatex, charsmax( strFormatex ), "%s-CTBAN", strPlayerAuthID );
	
	nvault_set( g_iVaultCTBan, strFormatex, "1" );
	SetBit( g_bitIsCTBanned, iPlayerID );
	
	if( cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
		cs_set_user_team( iPlayerID, CS_TEAM_T );
		
		if( CheckBit( g_bitIsAlive, iPlayerID ) ) {
			user_kill( iPlayerID );
		}
	}
	
	new strAdminName[ 32 ], strPlayerName[ 32 ];
	get_user_name( iPlayerID, strAdminName, charsmax( strAdminName ) );
	get_user_name( iTarget, strPlayerName, charsmax( strPlayerName ) );
	
	client_print_color( 0, iPlayerID, "^4%s^3 %s^1 banned ^4%s^1 from joining the ^4Guard^1 team.", g_strPluginPrefix, strAdminName, strPlayerName );
	
	log_amx( "%s banned %s from the CT team.", strAdminName, strPlayerName );
	
	return PLUGIN_HANDLED;
}

public ConCmd_AddBanCT( iPlayerID, iLevel, iCid ) {
	if( !cmd_access( iPlayerID, iLevel, iCid, 2 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 36 ];
	read_argv( 1, strTarget, charsmax( strTarget ) );
	
	if( contain( strTarget, "STEAM" ) == -1 ) {
		console_print( iPlayerID, "It appears that you did not input a valid STEAM_ID. Please try again!" );
		
		return PLUGIN_HANDLED;
	}
	
	new strFormatex[ 64 ];
	formatex( strFormatex, charsmax( strFormatex ), "%s-CTBAN", strTarget );
	
	nvault_set( g_iVaultCTBan, strFormatex, "1" );
	
	new strAdminName[ 32 ];
	get_user_name( iPlayerID, strAdminName, charsmax( strAdminName ) );
	
	client_print_color( 0, iPlayerID, "^4%s^3 %s^1 banned ^4%s^1 from the ^4Guard^1 team.", g_strPluginPrefix, strAdminName, strTarget );
	
	log_amx( "%s banned %s from the CT team.", strAdminName, strTarget );
	
	return PLUGIN_HANDLED;
}

public ConCmd_UnBanCT( iPlayerID, iLevel, iCid ) {
	if( !cmd_access( iPlayerID, iLevel, iCid, 1 ) ) {
		return PLUGIN_HANDLED;
	}
	
	new strTarget[ 32 ];
	read_argv( 1, strTarget, charsmax( strTarget ) );
	
	new iTarget = cmd_target( iPlayerID, strTarget, CMDTARGET_ALLOW_SELF | CMDTARGET_OBEY_IMMUNITY );
	
	if( !iTarget ) {
		return PLUGIN_HANDLED;
	}
	
	new strPlayerAuthID[ 36 ];
	get_user_authid( iTarget, strPlayerAuthID, charsmax( strPlayerAuthID ) );
	
	new strFormatex[ 64 ];
	formatex( strFormatex, charsmax( strFormatex ), "%s-CTBAN", strPlayerAuthID );
	
	nvault_set( g_iVaultCTBan, strFormatex, "0" );
	ClearBit( g_bitIsCTBanned, iTarget );
	
	return PLUGIN_HANDLED;
}

/* HamHooks */
public Ham_Spawn_Player_Post( iPlayerID ) {
	if( !is_user_alive( iPlayerID ) ) {
		#if defined DEBUG
		log_amx( "Player spawned but check reveals dead, stopping here" );
		#endif
		
		return HAM_IGNORED;
	}
	
	SetBit( g_bitIsAlive, iPlayerID );
	
	/*
		We strip the weapons of all spawning players so they do not get any
		weapons, T or CT.
	*/
	StripPlayerWeapons( iPlayerID );
	
	/*
		He spawned, so show his health.
	*/
	if( g_iShowHealth ) {
		Task_ShowHealth( TASK_SHOWHEALTH + iPlayerID );
	}
	
	if( !Knife_PlayerGetCurrent( iPlayerID ) ) {
		switch( cs_get_user_team( iPlayerID ) ) {
			case CS_TEAM_CT:	GivePlayerKnife( iPlayerID, KNIFE_TASER );
			case CS_TEAM_T:		GivePlayerKnife( iPlayerID, KNIFE_BARE_HANDS );
			default:		GivePlayerKnife( iPlayerID, KNIFE_BARE_HANDS );
		}
	}
	
	return HAM_IGNORED;
}

public Ham_Killed_Player_Pre( iVictim, iKiller, iShouldGIB ) {
	/*
		If this is called, that means someone died.
	*/
	ClearBit( g_bitIsAlive, iVictim );
	
	if( g_bGivePoints && cs_get_user_team( iKiller ) == CS_TEAM_T && cs_get_user_team( iVictim ) == CS_TEAM_CT ) {
		if( CheckBit( g_bitIsHeadShot[ iKiller ], iVictim ) ) {
			g_iPlayerPoints[ iKiller ] += g_iPluginSettings[ POINTS_KILL_HS ];
			
			client_print_color( iKiller, print_team_blue, "^4%s^1 Damn, did that ^3Guard^1's head? Here take those ^4%i point(s)^1.", g_strPluginPrefix, g_iPluginSettings[ POINTS_KILL_HS ] );
		} else {
			g_iPlayerPoints[ iKiller ] += g_iPluginSettings[ POINTS_KILL ];
			
			client_print_color( iKiller, print_team_default, "^4%s^1 Nice kill there. Here take those ^4%i point(s)^1.", g_strPluginPrefix, g_iPluginSettings[ POINTS_KILL ] );
		}
	}
	
	if( g_bDayInProgress ) {
		switch( g_iDayCurrent ) {
			case DAY_PRESIDENT: {
				/*
					Check if president died on president day and kill all other 
					guards.
				*/
				if( iVictim == g_iPresident ) {
					new iPlayers[ 32 ], iNum, iTempID;
					get_players( iPlayers, iNum, "ae", "CT" );
					
					for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
						iTempID = iPlayers[ iLoop ];
						
						if( iTempID != g_iPresident ) {
							user_kill( iTempID, 1 );
						}
					}
					
					new strPlayerName[ 32 ];
					get_user_name( g_iPresident, strPlayerName, charsmax( strPlayerName ) );
					
					client_print_color( 0, print_team_blue, "^4%s^1 President ^3%s^1 is now dead. All ^3Officers^1 are now dead!", g_strPluginPrefix );
				}
			}
			
			case DAY_CAGE, DAY_FREE, DAY_JUDGEMENT, DAY_RIOT: {
				/*
					A Guard has died by the hands of a Prisoner. Therefore we change 
					the killer to "0" (self death?) so the Prisoner's name does not 
					appear on the deathmsg, that way the Guards do not know who killed
					the Guard unless they saw them doing it.
					
					Also update the Top Info as the number of Guards is now -1. He
					could also be the commander right?
				*/
				if( is_user( iKiller ) && cs_get_user_team( iVictim ) == CS_TEAM_CT && cs_get_user_team( iKiller ) == CS_TEAM_T ) {
					SetHamParamEntity( 2, 0 );
					set_user_frags( iKiller, get_user_frags( iKiller ) + 1 );
					
					Task_ShowTopInfo( );
					
					return HAM_HANDLED;
				}
			}
		}
		
		/*
			Check if has a freeday and remove it, so he doesn't have it the next round.
		*/
		if( CheckBit( g_bitHasFreeDay, iVictim ) ) {
			ClearBit( g_bitHasFreeDay, iVictim );
		}
		
		/*
			When a prisoner dies, check if there is only one more prisoner alive, and 
			grant him his last request.
		*/
		if( cs_get_user_team( iVictim ) == CS_TEAM_T ) {
			CheckIfLastPrisoner( );
			
			Task_ShowTopInfo( );
		}
	}
	
	/*
		If we are in a last request, that means someone has won. Check who and end it.
	*/
	if( g_bLRInProgress ) {
		if( iVictim == g_iLastRequestPlayers[ PLAYER_GUARD ] ) {
			EndLastRequest( iVictim, g_iLastRequestPlayers[ PLAYER_PRISONER ] );
		} else if( iVictim == g_iLastRequestPlayers[ PLAYER_PRISONER ] ) {
			EndLastRequest( iVictim, g_iLastRequestPlayers[ PLAYER_GUARD ] );
		}
	}
	
	return HAM_IGNORED;
}

public Ham_TraceAttack_Button_Pre( iButton, iPlayerID, Float:fDamage, Float:fDirection[ 3 ], iHandle, iDamageBits ) {
	/*
		Allows players to shoot buttons in order to activate them according to the cvar.
		0: no one can use it
		1: prisoners only can use it
		2: guards only can use it
		3: all players can use it
	*/
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

public Ham_TakeDamage_Player_Pre( iVictim, iInflictor, iAttacker, Float:fDamage, iDamageBits ) {
	/*
		Block damage given to a player under certain circumstances.
	*/
	if( g_bDayInProgress ) {
		switch( g_iDayCurrent ) {
			/*
				Block fall damage for nightcrawlers and if the countdown is still
				running.
			*/
			case DAY_NIGHTCRAWLER: {
				if( iDamageBits == DMG_FALL ) {
					if( g_iTypeNightCrawler == TYPE_REGULAR && cs_get_user_team( iVictim ) == CS_TEAM_CT ||
					g_iTypeNightCrawler == TYPE_REVERSE && cs_get_user_team( iVictim ) == CS_TEAM_T ) {
						SetHamReturnInteger( 0 );
						
						return HAM_SUPERCEDE;
					}
				}
				
				if( task_exists( TASK_COUNTDOWN_NC ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			/*
				Block damage if countdown is still running.
			*/
			case DAY_SHARK: {
				if( task_exists( TASK_COUNTDOWN_SHARK ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			/*
				Block guard damage if countdown is still running.
			*/
			case DAY_HNS: {
				if( task_exists( TASK_COUNTDOWN_HNS ) && cs_get_user_team( iVictim ) == CS_TEAM_CT ) {
					return HAM_SUPERCEDE;
				}
			}
			
			/*
				Block guard damage if countdown is still running.
				Also set the damage ammount of the samurais to the exact health 
				of the victim, therefore instant death.
			*/
			case DAY_SAMURAI: {
				if( task_exists( TASK_COUNTDOWN_SAMURAI ) && cs_get_user_team( iVictim ) == CS_TEAM_CT ) {
					return HAM_SUPERCEDE;
				}
				
				if( cs_get_user_team( iAttacker ) == CS_TEAM_CT ) {
					SetHamParamFloat( 4, float( get_user_health( iVictim ) ) );
					
					return HAM_HANDLED;
				}
			}
			
			/*
				Set the damage ammount of the samurais to the exact health 
				of the victim, therefore instant death. Only with the deagle that is.
			*/
			case DAY_JUDGEMENT: {
				new strWeaponName[ 32 ];
				get_weaponname( get_user_weapon( iAttacker ), strWeaponName, charsmax( strWeaponName ) );
				
				if( cs_get_user_team( iAttacker ) == CS_TEAM_CT && equal( strWeaponName, "weapon_deagle" ) ) {
					SetHamParamFloat( 4, float( get_user_health( iVictim ) ) );
					
					return HAM_HANDLED;
				}
			}
			
			/*
				Block fall damage, and allow only guards to deal damage with weapons or
				whatever.
			*/
			case DAY_MARIO: {
				if( iDamageBits == DMG_FALL || is_user( iAttacker ) && cs_get_user_team( iAttacker ) != CS_TEAM_CT ) {
					return HAM_SUPERCEDE;
				}
			}
		}
	}
	
	return HAM_IGNORED;
}

public Ham_SecondaryAttack_USP_Post( iEntity ) {
	/*
		Block unsilencing of USP on usp ninja day.
	*/
	if( !cs_get_weapon_silen( iEntity ) ) {
		cs_set_weapon_silen( iEntity, 1 );
	}
}

public Ham_Touch_Weapon_Pre( iEntity, iPlayerID ) {
	/*
		Blocks weapon pickup from the ground on some days.
	*/
	if( !is_user( iPlayerID ) || !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return HAM_IGNORED;
	}
	
	static CsTeams:iTeam;
	iTeam = cs_get_user_team( iPlayerID );
	
	if( g_bDayInProgress ) {
		switch( g_iDayCurrent ) {
			/*
				Block only for nightcrawlers.
			*/
			case DAY_NIGHTCRAWLER: {
				if( iTeam == CS_TEAM_CT && g_iTypeNightCrawler == TYPE_REGULAR ||
				iTeam == CS_TEAM_T && g_iTypeNightCrawler == TYPE_REVERSE ) {
					return HAM_SUPERCEDE;
				}
			}
			
			/*
				Block only for zombies.
			*/
			case DAY_ZOMBIE: {
				if( iTeam == CS_TEAM_CT && g_iTypeZombie == TYPE_REVERSE ||
				iTeam == CS_TEAM_T && g_iTypeZombie == TYPE_REGULAR ) {
					return HAM_SUPERCEDE;
				}
			}
			
			/*
				Block only for sharks.
			*/
			case DAY_SHARK: {
				if( iTeam == CS_TEAM_CT && g_iTypeShark == TYPE_REGULAR ||
				iTeam == CS_TEAM_T && g_iTypeShark == TYPE_REVERSE ) {
					return HAM_SUPERCEDE;
				}
			}
			
			/*
				Block only for president.
			*/
			case DAY_PRESIDENT: {
				if( iTeam == CS_TEAM_CT ) {
					return HAM_SUPERCEDE;
				}
			}
			
			/*
				Block only for guards on a judgement day.
			*/
			case DAY_JUDGEMENT: {
				if( iTeam == CS_TEAM_CT ) {
					return HAM_SUPERCEDE;
				}
			}
			
			/*
				Block only for prisoners on lms when it isn't over yet.
			*/
			case DAY_LMS: {
				if( iTeam == CS_TEAM_T && !g_bLMSWeaponsOver ) {
					return HAM_SUPERCEDE;
				}
			}
			
			/*
				Block only for prisoners when the day has started.
			*/
			case DAY_NADEWAR: {
				if( iTeam == CS_TEAM_T && task_exists( TASK_NADEWAR_GIVENADE ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			/*
				Block for all players.
			*/
			case DAY_SAMURAI, DAY_KNIFE, DAY_SPACE, DAY_USP_NINJA, DAY_COWBOY, DAY_HULK: {
				return HAM_SUPERCEDE;
			}
			
			/*
				Block only for prisoners on mario day.
			*/
			case DAY_MARIO: {
				if( iTeam == CS_TEAM_T ) {
					return HAM_SUPERCEDE;
				}
			}
		}
	}
	
	if( g_bLRInProgress ) {
		if( iPlayerID != g_iLastRequestPlayers[ PLAYER_GUARD ] && iPlayerID != g_iLastRequestPlayers[ PLAYER_PRISONER ] ) {
			return HAM_IGNORED;
		}
		
		static iWeaponID;
		iWeaponID = cs_get_armoury_type( iEntity );
		
		static strWeaponName[ 32 ];
		get_weaponname( iWeaponID, strWeaponName, charsmax( strWeaponName ) );
		
		switch( g_iLRCurrent ) {
			case LR_KNIFE, LR_RACE: {
				return HAM_SUPERCEDE;
			}
			
			case LR_WEAPONTOSS: {
				if( !equal( strWeaponName[ 7 ], g_strWeapons[ TOSS_WEAPON_1_STR + g_iLRChosenWeaponToss ][ 7 ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_S4S: {
				if( !equal( strWeaponName[ 7 ], g_strWeapons[ S4S_WEAPON_1_STR + g_iLRChosenS4S ][ 7 ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_HOTPOTATO: {
				if( !equal( strWeaponName[ 7 ], "scout" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_GRENADETOSS: {
				if( !equal( strWeaponName[ 7 ], "smokegrenade" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_DUEL: {
				if( !equal( strWeaponName[ 7 ], g_strWeapons[ DUEL_WEAPON_1_STR + g_iLRChosenDuel ][ 7 ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_GLOCKER: {
				if( iPlayerID == g_iLRLastTerrorist && !equal( strWeaponName[ 7 ], "glock18" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_MANIAC: {
				if( iPlayerID == g_iLRLastTerrorist && !equal( strWeaponName[ 7 ], "deagle" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_KAMIKAZE: {
				if( iPlayerID == g_iLRLastTerrorist && !equal( strWeaponName[ 7 ], "m249" ) ) {
					return HAM_SUPERCEDE;
				}
			}
		}
	}
	
	return HAM_IGNORED;
}

public Ham_Touch_Wall_Pre( iEntity, iPlayerID ) {
	/*
		This is used to save the location aka origin, for the wall climbing
		ability.
	*/
	if( is_user( iPlayerID ) && CheckBit( g_bitIsAlive, iPlayerID ) ) {
		pev( iPlayerID, pev_origin, g_fWallOrigin[ iPlayerID ] );
	}
}

public Ham_Use_Recharger_Pre( iEntity, iPlayerID ) {
	/*
		This will make the healers practically infinite as they do not run
		out of juice :P.
		Plus it blocks it on some days to prevent cheating.
	*/
	if( get_pdata_ent( iEntity, 75, 5 ) <= 1 ) {
		set_pdata_int( iEntity, 75, 500 );
	}
	
	if( g_bDayInProgress ) {
		switch( g_iDayCurrent ) {
			case DAY_NIGHTCRAWLER, DAY_ZOMBIE, DAY_USP_NINJA, DAY_NADEWAR,
			DAY_HULK, DAY_SPACE, DAY_COWBOY, DAY_SHARK, DAY_SAMURAI, DAY_KNIFE,
			DAY_HNS, DAY_MARIO, DAY_PRESIDENT, DAY_LMS: {
				return HAM_SUPERCEDE;
			}
		}
	}
	
	if( g_bLRInProgress ) {
		switch( g_iLRCurrent ) {
			case LR_KAMIKAZE, LR_MANIAC, LR_GLOCKER: {
				return HAM_SUPERCEDE;
			}
			
			default: {
				if( iPlayerID == g_iLRLastTerrorist || iPlayerID == g_iLastRequestPlayers[ PLAYER_GUARD ] ) {
					return HAM_SUPERCEDE;
				}
			}
		}
	}
	
	return HAM_IGNORED;
}

public Ham_AddPlayerItem_Player_Pre( iPlayerID, iEntity ) {
	/*
		Player has had a weapon added to his inventory, so block it or let 
		it pass according to some conditions.
		
		Basically this stop players getting weapons other than the ones they
		are supposed to get on each day, or none at all depending on the day
		being played.
	*/
	if( !is_user( iPlayerID ) ) {
		return HAM_IGNORED;
	}
	
	static strWeaponName[ 32 ];
	pev( iEntity, pev_classname, strWeaponName, charsmax( strWeaponName ) );
	
	/*
		Don't block the knife as its standard.
	*/
	if( equal( strWeaponName[ 7 ], "knife" ) ) {
		return HAM_IGNORED;
	}
	
	static CsTeams:iTeam;
	iTeam = cs_get_user_team( iPlayerID );
	
	if( g_bDayInProgress ) {
		switch( g_iDayCurrent ) {
			case DAY_COWBOY: {
				if( iTeam == CS_TEAM_CT && !equal( strWeaponName[ 7 ], "deagle" ) ||
				iTeam == CS_TEAM_T && !equal( strWeaponName[ 7 ], "elite" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_HULK: {
				if( iTeam == CS_TEAM_T ) {
					return HAM_SUPERCEDE;
				} else if( iTeam == CS_TEAM_CT && 
				!equal( strWeaponName[ 7 ], "fiveseven" ) && 
				!equal( strWeaponName[ 7 ], "p90" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_PRESIDENT: {
				if( iPlayerID == g_iPresident && 
				!equal( strWeaponName[ 7 ], "usp" ) &&
				!equal( strWeaponName[ 7 ], "hegrenade" ) &&
				!equal( strWeaponName[ 7 ], "flashbang" ) &&
				!equal( strWeaponName[ 7 ], "smokegrenade" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_SHARK: {
				if( !task_exists( TASK_MENU_SHARK ) &&
				( ( iTeam == CS_TEAM_CT && g_iTypeShark == TYPE_REGULAR ) ||
				( iTeam == CS_TEAM_T && g_iTypeShark == TYPE_REVERSE ) ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_ZOMBIE: {
				if( !task_exists( TASK_MENU_ZOMBIE ) &&
				( ( iTeam == CS_TEAM_CT && g_iTypeZombie == TYPE_REVERSE ) ||
				( iTeam == CS_TEAM_T && g_iTypeZombie == TYPE_REGULAR ) ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_NIGHTCRAWLER: {
				if( !task_exists( TASK_MENU_NC ) &&
				( ( iTeam == CS_TEAM_CT && g_iTypeNightCrawler == TYPE_REGULAR ) ||
				( iTeam == CS_TEAM_T && g_iTypeNightCrawler == TYPE_REVERSE ) ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_SPACE: {
				if( iTeam == CS_TEAM_CT && !equal( strWeaponName[ 7 ], "awp" ) ||
				iTeam == CS_TEAM_T && !equal( strWeaponName[ 7 ], "scout" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_USP_NINJA: {
				if( !equal( strWeaponName[ 7 ], "usp" ) ) {
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
				if( iTeam == CS_TEAM_T && !task_exists( TASK_NADEWAR_GIVENADE ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case DAY_LMS: {
				if( iTeam == CS_TEAM_T  && !g_bGivenWeapon ) {
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
		switch( g_iLRCurrent ) {
			case LR_KNIFE, LR_RACE: {
				return HAM_SUPERCEDE;
			}
			
			case LR_WEAPONTOSS: {
				if( !equal( strWeaponName[ 7 ], g_strWeapons[ TOSS_WEAPON_1_STR + g_iLRChosenWeaponToss ][ 7 ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_S4S: {
				if( !equal( strWeaponName[ 7 ], g_strWeapons[ S4S_WEAPON_1_STR + g_iLRChosenS4S ][ 7 ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_HOTPOTATO: {
				if( g_bHotPotatoStarted ) {
					if( !equal( strWeaponName[ 7 ], "scout" ) ) {
						return HAM_SUPERCEDE;
					} else {
						g_iLastPickup = iPlayerID;
					}
				}
			}
			
			case LR_GRENADETOSS: {
				if( !equal( strWeaponName[ 7 ], "smokegrenade" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_DUEL: {
				if( !equal( strWeaponName[ 7 ], g_strWeapons[ DUEL_WEAPON_1_STR + g_iLRChosenDuel ][ 7 ] ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_GLOCKER: {
				if( iPlayerID == g_iLRLastTerrorist && !equal( strWeaponName[ 7 ], "glock18" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_MANIAC: {
				if( iPlayerID == g_iLRLastTerrorist && !equal( strWeaponName[ 7 ], "deagle" ) ) {
					return HAM_SUPERCEDE;
				}
			}
			
			case LR_KAMIKAZE: {
				if( iPlayerID == g_iLRLastTerrorist && !equal( strWeaponName[ 7 ], "m249" ) ) {
					return HAM_SUPERCEDE;
				}
			}
		}
	}
	
	return HAM_IGNORED;
}

public Ham_ResetMaxSpeed_Player_Post( iPlayerID ) {
	/*
		This allows us to keep the player frozen on hulk day. Since when we freeze
		the player, if he switched his weapon, his speed will be reset, therefore
		stop it or rather set it back so he can't move.
	*/
	if( g_bHulkSmash && is_user( iPlayerID ) && CheckBit( g_bitIsAlive, iPlayerID ) && cs_get_user_team( iPlayerID ) == CS_TEAM_CT ) {
		set_pev( iPlayerID, pev_maxspeed, 1.0 );
	}
}

public Ham_Think_Grenade_Pre( iEntity ) {
	/*
		This is basically a way to put fancy stuff behind the grenade as it flies
		around the map sometimes.
	*/
	if( pev_valid( iEntity ) ) {
		static iPlayerID;
		iPlayerID = pev( iEntity, pev_owner );
		
		static strGrenadeModel[ 32 ];
		pev( iEntity, pev_model, strGrenadeModel, charsmax( strGrenadeModel ) );
		
		if( equal( strGrenadeModel, "models/w_hegrenade.mdl" ) ) {
			set_pev( iEntity, pev_renderfx, kRenderFxGlowShell );
			set_pev( iEntity, pev_rendermode, kRenderNormal );
			set_pev( iEntity, pev_renderamt, 16.0 );
			
			switch( cs_get_user_team( iPlayerID ) ) {
				case CS_TEAM_CT: {
					set_pev( iEntity, pev_rendercolor, { 0.0, 0.0, 255.0 } );
					
					SetBeamFollow( iEntity, BEAM_LIFE, BEAM_WIDTH, 0, 0, 255, BEAM_BRIGHT );
				}
				
				case CS_TEAM_T: {
					set_pev( iEntity, pev_rendercolor, { 255.0, 0.0, 0.0 } );
					
					SetBeamFollow( iEntity, BEAM_LIFE, BEAM_WIDTH, 255, 0, 0, BEAM_BRIGHT );
				}
			}
		}
		
		if( g_bDayInProgress ) {
			return HAM_IGNORED;
		} else if( g_bLRInProgress ) {
			return HAM_SUPERCEDE;
		}
	}
	
	return HAM_IGNORED;
}

public Ham_TakeHealth_Player_Pre( iPlayerID, Float:fHealth, iDamageBits ) {
	/*
		Block the ability to get health completly. Block it for last request players
		on lr and for all when a day is running.
	*/
	if( g_bLRInProgress ) {
		if( iPlayerID == g_iLRLastTerrorist || iPlayerID == g_iLastRequestPlayers[ PLAYER_GUARD ] ) {
			return HAM_SUPERCEDE;
		} else {
			return HAM_IGNORED;
		}
	}
	
	if( g_bDayInProgress ) {
		return HAM_SUPERCEDE;
	}
	
	return HAM_IGNORED;
}

public Ham_Player_Prethink_Pre( iPlayerID ) {
	/*
		Prethink is used to show the lasers on player's guns on nightcrawler,
		and allow them to climb up walls.
	*/
	#if defined DEBUG
	log_amx( "--------------------" );
	log_amx( "Entered Ham_Player_Prethink_Pre function" );
	#endif
	
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return FMRES_IGNORED;
	}
	
	static CsTeams:iTeam;
	iTeam = cs_get_user_team( iPlayerID );
	
	#if defined DEBUG
	log_amx( "Player team is %s", ( iTeam == CS_TEAM_CT ) ? "CT" : "T" );
	log_amx( "NC Type is %s", ( g_iTypeNightCrawler == TYPE_REGULAR ) ? "REGULAR" : "REVERSE" );
	#endif
	
	if( iTeam == CS_TEAM_CT && g_iTypeNightCrawler == TYPE_REGULAR ||
	iTeam == CS_TEAM_T && g_iTypeNightCrawler == TYPE_REVERSE ) {
		static iButton;
		iButton = get_user_button( iPlayerID );
		
		if( iButton & IN_USE ) {
			#if defined DEBUG
			log_amx( "Player is using USE button" );
			#endif
			
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
	
	if( iTeam == CS_TEAM_CT && g_iTypeNightCrawler == TYPE_REVERSE ||
	iTeam == CS_TEAM_T && g_iTypeNightCrawler == TYPE_REGULAR ) {
		static iTarget, iBody, iRed, iGreen, iBlue, iWeapon;
		get_user_aiming( iPlayerID, iTarget, iBody );
		iWeapon = get_user_weapon( iPlayerID );
		
		if( IsPrimaryWeapon( iWeapon ) || IsSecondaryWeapon( iWeapon ) ) {
			if( is_user( iTarget ) && CheckBit( g_bitIsAlive, iTarget ) && iTeam != cs_get_user_team( iTarget ) ) {
				iRed 	= 255;
				iGreen 	= 0;
				iBlue 	= 0;
			} else {
				iRed	= 0;
				iGreen	= 255;
				iBlue	= 0;
			}
			
			static iOrigin[ 3 ];
			get_user_origin( iPlayerID, iOrigin, 3 );
			
			message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
			write_byte( TE_BEAMENTPOINT );
			write_short( iPlayerID | 0x1000 );
			write_coord( iOrigin[ 0 ] );
			write_coord( iOrigin[ 1 ] );
			write_coord( iOrigin[ 2 ] );
			write_short( g_iSpriteLaser );
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
	
	return FMRES_IGNORED;
}

public Ham_Weapon_PrimaryAttack_Post( iEntity ) {
	new iOpponentEntity;
	new iPlayerID = pev( iEntity, pev_owner );
	
	if( cs_get_weapon_ammo( iEntity ) == 0 ) {
		if( iPlayerID == g_iLRLastTerrorist ) {
			iOpponentEntity = find_ent_by_owner( -1, g_strWeapons[ S4S_WEAPON_1_STR + g_iLRChosenS4S ], g_iLastRequestPlayers[ PLAYER_GUARD ] );
			
			if( pev_valid( iOpponentEntity ) ) {
				cs_set_weapon_ammo( iOpponentEntity, 1 );
			}
		} else if( iPlayerID == g_iLastRequestPlayers[ PLAYER_GUARD ] ) {
			iOpponentEntity = find_ent_by_owner( -1, g_strWeapons[ S4S_WEAPON_1_STR + g_iLRChosenS4S ], g_iLRLastTerrorist );
			
			if( pev_valid( iOpponentEntity ) ) {
				cs_set_weapon_ammo( iOpponentEntity, 1 );
			}
		}
	}
	
	return HAM_IGNORED;
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

/* Messages */
public Message_ShowMenu( iMessageID, iDestination, iPlayerID ) {
	if( !g_iMainMenu ) {
		return PLUGIN_CONTINUE;
	}
	
	static FIRST_JOIN_MSG[ ] 	= "#Team_Select";
	static FIRST_JOIN_MSG_SPEC[ ] 	= "#Team_Select_Spect";
	static INGAME_JOIN_MSG[ ] 	= "#IG_Team_Select";
	static INGAME_JOIN_MSG_SPEC[ ]	= "#IG_Team_Select_Spect";
	
	static strMenuCode[ 32 ];
	
	get_msg_arg_string( 4, strMenuCode, charsmax( strMenuCode ) );
	
	/* Allows multiple team changes */
	set_pdata_int( iPlayerID, 125, get_pdata_int( iPlayerID, 125, 5 ) & ~ ( 1<<8 ), 5 );
	
	if( equal( strMenuCode, FIRST_JOIN_MSG ) || equal( strMenuCode, FIRST_JOIN_MSG_SPEC ) ) {
		if( is_user_connected( iPlayerID ) && !task_exists( TASK_TEAMJOIN + iPlayerID ) ) {
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
	if( !g_iMainMenu ) {
		return PLUGIN_CONTINUE;
	}
	
	/* Allows multiple team changes */
	set_pdata_int( iPlayerID, 125, get_pdata_int( iPlayerID, 125, 5 ) & ~ ( 1<<8 ), 5 );
	
	if( get_msg_arg_int( 1 ) != 2 ) {
		return PLUGIN_CONTINUE;
	}
	
	if( is_user_connected( iPlayerID ) && !task_exists( TASK_TEAMJOIN + iPlayerID ) ) {
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

/* Forwards */
public Forward_GetGameDescription_Pre( ) {
	/*
		Change the description of the game on the find servers tab. That way
		we look cool 8).
	*/
	forward_return( FMV_STRING, g_strPluginName );
	
	return FMRES_SUPERCEDE;
}

public Forward_SetClientListening_Pre( iReceiverID, iSenderID, bool:bListen ) {
	/*
		Manage each player's ability to use his microphone.
	*/
	if( !is_user( iReceiverID ) || !is_user( iSenderID ) ) {
		return FMRES_IGNORED;
	}
	
	if( !is_user_connected( iReceiverID ) || !is_user_connected( iSenderID ) ) {
		return FMRES_IGNORED;
	}
	
	/*
		Check if player has been given mic access or he is an admin and allow it. Also
		allow if he is the last terrorist alive and cvar is set.
	*/
	if( CheckBit( g_bitHasMicPower, iSenderID ) || is_user_admin( iSenderID ) || g_iLastRequestMic && iSenderID == g_iLRLastTerrorist ) {
		return FMRES_IGNORED;
	}
	
	/*
		Block it if he is a guard that is alive.
	*/
	if( cs_get_user_team( iSenderID ) != CS_TEAM_CT || !CheckBit( g_bitIsAlive, iSenderID ) ) {
		engfunc( EngFunc_SetClientListening, iReceiverID, iSenderID, 0 );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public Forward_CmdStart_Pre( iPlayerID, UC_Handle ) {
	/*
		This allows players to move way faster when they are in noclip mode 
		when they press 'SHIFT' (walk key).
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

public Forward_AddToFullPack_Post( ES_Handle, iE, iEntity, iHost, iHostFlags, iID, pSet ) {
	/*
		This is useful to hid the players from their enemies but keep them visible
		to their teammates.
	*/
	if( iID ) {
		switch( g_iDayCurrent ) {
			case DAY_SAMURAI: {
				if( !task_exists( TASK_COUNTDOWN_SAMURAI ) ) {
					unregister_forward( FM_AddToFullPack, g_fwdAddToFullPack, 1 );
				}
			}
			
			case DAY_SHARK: {
				if( !task_exists( TASK_COUNTDOWN_SHARK ) ) {
					unregister_forward( FM_AddToFullPack, g_fwdAddToFullPack, 1 );
				}
			}
		}
		
		if( cs_get_user_team( iHost ) == cs_get_user_team( iEntity ) ) {
			set_es( ES_Handle, ES_RenderMode, kRenderTransTexture );
			set_es( ES_Handle, ES_RenderAmt, 125 );
		}
	}
}

public Forward_Touch( iToucher, iTouched ) {
	/*
		This is used to detect when a player has landed on his teammates' head.
		Mainly used in mario day. Honestly I just pulled this from some plugin
		that I forgot the name of, but credits to him or her.
	*/
	if( task_exists( TASK_COUNTDOWN_MARIO ) ) {
		return FMRES_IGNORED;
	}
	
	if( !is_user( iToucher ) || !is_user( iTouched ) ||
	!CheckBit( g_bitIsAlive, iToucher ) || !CheckBit( g_bitIsAlive, iTouched ) ||
	cs_get_user_team( iToucher ) != cs_get_user_team( iTouched ) ) {
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
	set_user_frags( iToucher, get_user_frags( iToucher ) + 1 );
	
	PlaySound( 0, SOUND_MARIO_DOWN );
	
	return FMRES_IGNORED;
}

public Forward_Spawn( iEntity ) {
	/*
		Here we are hooking all entities that spawn and check each one if its
		the buyzone, and removing it.
	*/
	new strClassName[ 32 ];
	entity_get_string( iEntity, EV_SZ_classname, strClassName, charsmax( strClassName ) );
	
	if( equal( strClassName, "info_map_parameters" ) ) {
		remove_entity( iEntity );
		
		return FMRES_SUPERCEDE;
	}
	
	return FMRES_IGNORED;
}

public Forward_SetModel( iEntity ) {
	if( !pev_valid( iEntity ) ) {
		return FMRES_IGNORED;
	}
	
	static iPlayerID;
	iPlayerID = pev( iEntity, pev_owner );
	
	if( !is_user( iPlayerID ) ) {
		return FMRES_IGNORED;
	}
	
	static iWeaponID;
	iWeaponID = cs_get_armoury_type( iEntity );
	
	if( !iWeaponID ) {
		return FMRES_IGNORED;
	}
	
	static strWeaponName[ 32 ];
	get_weaponname( iWeaponID, strWeaponName, charsmax( strWeaponName ) );
	
	if( equal( strWeaponName[ 7 ], g_strWeapons[ TOSS_WEAPON_1_STR + g_iLRChosenWeaponToss ][ 7 ] ) ) {
		if( iPlayerID == g_iLastRequestPlayers[ PLAYER_GUARD ] ) {
			set_pev( iEntity, pev_renderfx, kRenderFxGlowShell );
			set_pev( iEntity, pev_rendercolor, { 0.0, 0.0, 255.0 } );
			set_pev( iEntity, pev_rendermode, kRenderNormal );
			set_pev( iEntity, pev_renderamt, 16.0 );
			
			SetBeamFollow( iEntity, BEAM_LIFE, BEAM_WIDTH, 0, 0, 255, BEAM_BRIGHT );
		} else if( iPlayerID == g_iLRLastTerrorist ) {
			set_pev( iEntity, pev_renderfx, kRenderFxGlowShell );
			set_pev( iEntity, pev_rendercolor, { 255.0, 0.0, 0.0 } );
			set_pev( iEntity, pev_rendermode, kRenderNormal );
			set_pev( iEntity, pev_renderamt, 16.0 );
			
			SetBeamFollow( iEntity, BEAM_LIFE, BEAM_WIDTH, 255, 0, 0, BEAM_BRIGHT );
		}
	}
	
	return FMRES_IGNORED;
}

/* Tasks */
/*
	Vote tasks are basically a timer for the menu.
	Refresh every second and then stop the vote when
	timer is over.
*/
public Task_Vote_Day( ) {
	#if defined DEBUG
	log_amx( "--------------------" );
	log_amx( "Entered 'Task_Vote_Day' function" );
	#endif
	
	if( --g_iTimeLeft ) {
		ShowDayVote( );
		
		#if defined DEBUG
		log_amx( "g_iTimeLeft is positive, shown day vote." );
		#endif
	} else {
		EndDayVote( );
		
		#if defined DEBUG
		log_amx( "g_iTimeLeft is negative or zero, ended day vote." );
		#endif
	}
	
	#if defined DEBUG
	log_amx( "Exited 'Task_Vote_Day' function" );
	log_amx( "--------------------" );
	#endif
}

public Task_Vote_Free( ) {
	if( --g_iTimeLeft ) {
		ShowFreeVote( );
	} else {
		EndFreeVote( );
	}
}

public Task_Vote_NightCrawler( ) {
	if( --g_iTimeLeft ) {
		ShowNightCrawlerVote( );
	} else {
		EndNightCrawlerVote( );
	}
}

public Task_Vote_Zombie( ) {
	if( --g_iTimeLeft ) {
		ShowZombieVote( );
	} else {
		EndZombieVote( );
	}
}

public Task_Vote_Shark( ) {
	if( --g_iTimeLeft ) {
		ShowSharkVote( );
	} else {
		EndSharkVote( );
	}
}

public Task_ShowTopInfo( ) {
	/*
		This will show some information at the top of the screen for all players.
	*/
	static strInfo[ 256 ];
	
	/*
		Show current day name, number of guards, number of prisoners, number of free day
		players, and then show the commander name if there is any. Or simply show that a
		vote is in progress.
	*/
	if( g_bDayInProgress ) {
		switch( g_iDayCurrent ) {
			case DAY_NIGHTCRAWLER:	formatex( strInfo, charsmax( strInfo ), "%s NightCrawler Day", 	g_iTypeNightCrawler == TYPE_REGULAR 	? "Regular" : "Reverse" );
			case DAY_ZOMBIE:	formatex( strInfo, charsmax( strInfo ), "%s Zombie Day", 		g_iTypeZombie == TYPE_REGULAR 		? "Regular" : "Reverse" );
			case DAY_SHARK:		formatex( strInfo, charsmax( strInfo ), "%s Shark Day", 		g_iTypeShark == TYPE_REGULAR 		? "Regular" : "Reverse" );
			case DAY_FREE:		formatex( strInfo, charsmax( strInfo ), "%s Free Day",		g_iTypeFree == TYPE_UNRESTRICTED 	? "Unrestricted" : "Restricted" );
			case DAY_CAGE: {
				if( g_iCommanderGuard != -1 ) {
					static strCommanderName[ 32 ];
					get_user_name( g_iCommanderGuard, strCommanderName, charsmax( strCommanderName ) );
					
					formatex( strInfo, charsmax( strInfo ), "Cage Day^nCommander: %s", strCommanderName );
				} else {
					formatex( strInfo, charsmax( strInfo ), "Cage Day^nCommander: N/A" );
				}
			}
			default:		formatex( strInfo, charsmax( strInfo ), "%s", g_strOptionsDayVote[ g_iDayCurrent ] );
		}
		
		format( strInfo, charsmax( strInfo ), "Day #%i || %s^nP: %i (%i) || G: %i", g_iDayCount, strInfo, GetTeamPlayersNumber( "T" ), GetTeamPlayersNumber( "F" ), GetTeamPlayersNumber( "C" ) );
	} else if( task_exists( TASK_VOTE_DAY ) || task_exists( TASK_VOTE_FREEDAY ) || task_exists( TASK_VOTE_NIGHTCRAWLER ) || 
	task_exists( TASK_VOTE_SHARK ) || task_exists( TASK_VOTE_ZOMBIE ) ) {
		formatex( strInfo, charsmax( strInfo ), "Day #%i || Vote In Progress", g_iDayCount );
	}
	
	set_hudmessage( 255, 255, 255, -1.0, 0.0, _, _, 10.0, _, _, g_iPluginSettings[ CHANNEL_TOPINFO ] );
	show_hudmessage( 0, strInfo );
}

public Task_Countdown_NC( ) {
	/*
		Remove invisibility at the end of the timer.
	*/
	if( --g_iTimeLeft > 5 ) {
		set_hudmessage( 0, 255, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft ) {
		set_hudmessage( 255, 0, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time is over!^nEliminate the opposing team!" );
		
		new iPlayers[ 32 ], iNum, iTempID;
		get_players( iPlayers, iNum, "ae", g_iTypeNightCrawler == TYPE_REGULAR ? "TERRORIST" : "CT" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			set_user_rendering( iTempID );
			set_user_footsteps( iTempID, 0 );
		}
		
		client_print_color( 0, ( g_iTypeNightCrawler == TYPE_REGULAR ) ? print_team_red : print_team_blue, "^4%s^1 The ^3%s^1 are now visible. FIND THEM!", g_strPluginPrefix, ( g_iTypeNightCrawler == TYPE_REGULAR ) ? "Prisoners" : "Guards" );
		PlaySound( 0, SOUND_NIGHTCRAWLER );
		
		if( g_iTypeNightCrawler == TYPE_REVERSE ) {
			OpenCells( );
		}
	}
}

public Task_Countdown_Shark( ) {
	/*
		Remove invisibility at the end of the timer.
	*/
	if( --g_iTimeLeft > 5 ) {
		set_hudmessage( 0, 255, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft ) {
		set_hudmessage( 255, 0, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time is over!^nEliminate the opposing team!" );
		
		new iPlayers[ 32 ], iNum, iTempID;
		get_players( iPlayers, iNum, "ae", ( g_iTypeShark == TYPE_REGULAR ) ? "TERRORIST" : "CT" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			set_user_rendering( iTempID );
			set_user_footsteps( iTempID, 0 );
		}
		
		client_print_color( 0, ( g_iTypeShark == TYPE_REGULAR ) ? print_team_red : print_team_blue, "^4%s^1 The ^3%s^1 are now visible. FIND THEM!", g_strPluginPrefix, ( g_iTypeShark == TYPE_REGULAR ) ? "Prisoners" : "Guards" );
		PlaySound( 0, SOUND_NIGHTCRAWLER );
	}
}

public Task_Countdown_Samurai( ) {
	/*
		Remove invisibility at the end of the timer.
	*/
	if( --g_iTimeLeft > 10 ) {
		set_hudmessage( 0, 255, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft ) {
		set_hudmessage( 255, 0, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time is over!^nEliminate the opposing team!" );
		
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

public Task_Countdown_HNS( ) {
	/*
		Remove invisibility at the end of the timer.
	*/
	if( --g_iTimeLeft > 10 ) {
		set_hudmessage( 0, 255, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft ) {
		set_hudmessage( 255, 0, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time Remaining: %i seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Time is over!^nEliminate the opposing team!" );
		
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

public Task_Countdown_HotPotato( ) {
	/*
		Start hot potato at the end of the timer.
	*/
	if( --g_iTimeLeft > 3 ) {
		set_hudmessage( 0, 255, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Hot Potato will start in: %i seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft ) {
		set_hudmessage( 255, 0, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Hot Potato will start in: %i seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Hot Potato has now started!", g_iTimeLeft );
		
		g_bHotPotatoStarted = true;
		g_iLastPickup = g_iLastRequestPlayers[ PLAYER_GUARD ];
		
		set_task( TIME_HOTPOTATO, "Task_SlayLooser", TASK_SLAYLOOSER );
	}
}

public Task_Countdown_Race( ) {
	/*
		Start race at the end of the timer.
	*/
	if( --g_iTimeLeft > 3 ) {
		set_hudmessage( 0, 255, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Race will start in: %i seconds!", g_iTimeLeft );
	} else if( g_iTimeLeft > 0 ) {
		set_hudmessage( 255, 0, 0, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Race will start in: %i seconds!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = g_iPluginSettings[ CHANNEL_COUNTDOWN ] );
		show_hudmessage( 0, "Go Go Go!", g_iTimeLeft );
		
		client_cmd( 0, "spk ^"radio/com_go^"" );
	}
}

public Task_Countdown_Commander( ) {
	if( --g_iTimeLeft > 3 ) {
		set_hudmessage( 0, 255, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Commander countdown: %i seconds left!", g_iTimeLeft );
	} else if( g_iTimeLeft ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Commander countdown: %i seconds left!", g_iTimeLeft );
	} else {
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Go Go Go!" );
		
		client_cmd( 0, "spk ^"radio/com_go.wav^"" );
	}
}

public Task_Countdown_CommanderMath( strEquation[ ], iTaskID ) {
	if( --g_iTimeLeft > 3 ) {
		new strFunnyMathSituation[ ][ ] = {
			"I will ask you a math question",
			"I'm the king of math, hit me :)",
			"What is 1+1 equal to?",
			"Pffft, thats obviously 22",
			"Wrong! It's 2 you idiot...",
			"OMG fuck my keyboard",
			"Always blame the keyoard :D"
		};
		
		static iCount = 0;
		if( iCount == 7 ) {
			iCount = 0;
		}
		
		if( iCount % 2 == 0 ) {
			set_hudmessage( 170, 0, 150, .channel = CHANNEL_COUNTDOWN );
		} else {
			set_hudmessage( 75, 75, 255, .channel = CHANNEL_COUNTDOWN );
		}
		
		show_hudmessage( 0, strFunnyMathSituation[ iCount++ ] );
		
		set_hudmessage( 0, 255, 0, _, _, _, 1.0, 1.0, _, _, CHANNEL_OTHER );
		show_hudmessage( 0, "^nMath question in %i...", g_iTimeLeft );
	} else if( g_iTimeLeft ) {
		set_hudmessage( 255, 0, 0, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, "Math question in %i...", g_iTimeLeft );
	} else {
		g_bCatchAnswer = true;
		
		set_hudmessage( 255, 255, 255, .channel = CHANNEL_COUNTDOWN );
		show_hudmessage( 0, strEquation );
		
		console_print( 0, strEquation );
	}
}

public Task_NadeWar_Start( ) {
	/*
		Start giving prisoners nades but strip their weapons before that.
	*/
	SetFreeForAll( 1 );
	
	StripPlayerWeapons( 0, "A" );
	set_task( 0.1, "Task_NadeWar_GiveNade", TASK_NADEWAR_GIVENADE, _, _, "b" );
	
	PlaySound( 0, SOUND_NADEWAR );
}

public Task_NadeWar_GiveNade( ) {
	/*
		Does prisoner have a nade? Easy, then give him one.
	*/
	static iPlayers[ 32 ], iNum, iTempID, iLoop;
	get_players( iPlayers, iNum, "a" );
	
	for( iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		if( !user_has_weapon( iTempID, CSW_HEGRENADE ) ) {
			give_item( iTempID, "weapon_hegrenade" );
		}
	}
}

public Task_LMS_GiveWeapon( ) {
	/*
		Start giving the prisoners a weapon/
	*/
	SetFreeForAll( 1 );
	g_iLMSCurrentWeapon = 0;
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		set_user_health( iTempID, LMS_HEALTH_PRISONER );
		cs_set_user_armor( iTempID, LMS_ARMOR_PRISONER, CS_ARMOR_VESTHELM );
	}
	
	Task_LMS_GiveOrderedWeapons( );
	set_task( float( g_iPluginSettings[ LMS_TIME_INTERVAL ] ), "Task_LMS_GiveOrderedWeapons", TASK_LMS_GIVEORDEREDWEAPONS );
}

public Task_LMS_GiveOrderedWeapons( ) {
	static iLMSPrimaryOrderedWeapons[ ] = {
		-1,
		-1,
		-1,
		PRIMARY_M3,
		PRIMARY_XM1014,
		PRIMARY_SCOUT,
		PRIMARY_MP5NAVY,
		PRIMARY_FAMAS,
		PRIMARY_GALIL,
		PRIMARY_AWP,
		PRIMARY_AK47,
		PRIMARY_M4A1
	};
	
	static iLMSSecondaryOrderedWeapons[ ] = {
		SECONDARY_GLOCK18,
		SECONDARY_USP,
		SECONDARY_DEAGLE,
		-1,
		-1,
		-1,
		-1,
		-1,
		-1,
		-1,
		-1,
		-1
	};
	
	if( g_iLMSCurrentWeapon == sizeof( iLMSPrimaryOrderedWeapons ) + 1 ) {
		g_iLMSCurrentWeapon = 0;
		g_bLMSWeaponsOver = true;
		
		remove_task( TASK_LMS_GIVEORDEREDWEAPONS );
		
		client_print_color( 0, print_team_red, "^4%s^3 Prisoners^1 can now use any weapon they can find.", g_strPluginPrefix );
	} else {
		new iPlayers[ 32 ], iNum, iTempID;
		get_players( iPlayers, iNum, "ae", "TERRORIST" );
		
		g_bGivenWeapon = true;
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			StripPlayerWeapons( iTempID );
			
			if( g_iLMSCurrentWeapon != sizeof( iLMSPrimaryOrderedWeapons ) ) {
				GivePlayerWeapon( iTempID, ":P", iLMSPrimaryOrderedWeapons[ g_iLMSCurrentWeapon ], iLMSSecondaryOrderedWeapons[ g_iLMSCurrentWeapon ], false, true );
			}
		}
		
		g_bGivenWeapon = false;
		
		g_iLMSCurrentWeapon++;
	}
}

public Task_President_GiveWeapons( ) {
	/*
		Enough time has been given for the guards, open cells and give prisoners weapons.
	*/
	StripPlayerWeapons( 0, "T" );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		ShowWeaponMenu( iPlayers[ iLoop ] );
	}
	
	OpenCells( );
}

public Task_Hulk_Smash( ) {
	/*
		Shake the guards screen and make them freeze every 20 seconds.
	*/
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	g_bHulkSmash = true;
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		message_begin( MSG_ONE, g_msgScreenShake, { 0, 0, 0 }, iTempID );
		write_short( 255 << 14 );
		write_short( 10 << 14 );
		write_short( 255 << 14 );
		message_end( );
		
		set_pev( iTempID, pev_maxspeed, 1.0 );
	}
	
	PlaySound( 0, SOUND_HULK );
	
	set_task( 5.0, "Task_Hulk_RemoveSmash" );
}

public Task_Hulk_RemoveSmash( ) {
	/*
		They have been frozen for 5 seconds, so unfreeze them now.
	*/
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	g_bHulkSmash = false;
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		ExecuteHamB( Ham_CS_Player_ResetMaxSpeed, iPlayers[ iLoop ] );
	}
}

public Task_EndRound( ) {
	/*
		Round has ended, so kill all guards. Round is taking for ever :(
	*/
	if( g_bDayInProgress ) {
		EndDay( );
		
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum, "ae", "CT" );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			user_silentkill( iPlayers[ iLoop ] );
		}
		
		client_print_color( 0, print_team_blue, "^4%s^1 The ^3Guards^1 are changing shifts.", g_strPluginPrefix );
	}
}

public Task_ShowHealth( iTaskID ) {
	/*
		Show player's health? Easy enough I guess.
	*/
	static iHealth, iPlayerID;
	iPlayerID = iTaskID - TASK_SHOWHEALTH;
	
	if( !CheckBit( g_bitIsAlive, iPlayerID ) || !CheckBit( g_bitHasHealthEnabled, iPlayerID ) ) {
		return;
	}
	
	iHealth = get_user_health( iPlayerID );
	
	if( iHealth > 25 ) {
		set_hudmessage( 255, 140, 0, -1.0, 0.9, 0, 12.0, 12.0, 0.1, 0.2, g_iPluginSettings[ CHANNEL_HEALTH ] );
	} else {
		set_hudmessage( 255, 0, 0, -1.0, 0.9, 0, 12.0, 12.0, 0.1, 0.2, g_iPluginSettings[ CHANNEL_HEALTH ] );
	}
	
	show_hudmessage( iPlayerID, "HP: %i", iHealth );
	
	set_task( 12.0 - 0.1, "Task_ShowHealth", iTaskID );
}

public Task_SlayLooser( ) {
	/*
		30 seconds have passed, so kill the player who picked the scout the last.
	*/
	if( g_bLRInProgress && g_iLRCurrent == LR_HOTPOTATO ) {
		if( g_iLastPickup == g_iLastRequestPlayers[ PLAYER_GUARD ] ) {
			ExecuteHamB( Ham_Killed, g_iLastPickup, g_iLastRequestPlayers[ PLAYER_PRISONER ], 0 );
		} else {
			ExecuteHamB( Ham_Killed, g_iLastPickup, g_iLastRequestPlayers[ PLAYER_GUARD ], 0 );
		}
	}
}

public Task_Start_Showdown( ) {
	/*
		Print in center message the differenet stages of showdown.
	*/
	static iShowdownCount = 0;
	
	switch( ++iShowdownCount ) {
		case 1: {
			client_print( g_iLastRequestPlayers[ PLAYER_GUARD ], print_center, "Walk!" );
			client_print( g_iLastRequestPlayers[ PLAYER_PRISONER ], print_center, "Walk!" );
		}
		
		case 2: {
			client_print( g_iLastRequestPlayers[ PLAYER_GUARD ], print_center, "Draw!" );
			client_print( g_iLastRequestPlayers[ PLAYER_PRISONER ], print_center, "Draw!" );
		}
		
		case 3: {
			client_print( g_iLastRequestPlayers[ PLAYER_GUARD ], print_center, "Shoot!" );
			client_print( g_iLastRequestPlayers[ PLAYER_PRISONER ], print_center, "Shoot!" );
			
			iShowdownCount = 0;
			
			return;
		}
	}
	
	set_task( random_float( 3.0, 5.0 ), "Task_Start_Showdown", TASK_START_SHOWDOWN );
}

public Task_TeamJoin( iParameters[ ], iTaskID ) {
	new iPlayerID = iTaskID - TASK_TEAMJOIN;
	
	new iMessageID = iParameters[ 0 ];
	new iMessageBlock = get_msg_block( iMessageID );
	set_msg_block( iMessageID, BLOCK_SET );
	
	static strTeam[ 2 ];
	
	switch( cs_get_user_team( iPlayerID ) ) {
		case CS_TEAM_T:		strTeam = "2";
		case CS_TEAM_CT:	strTeam = "1";
		case CS_TEAM_SPECTATOR:	strTeam = "1";
		case CS_TEAM_UNASSIGNED:strTeam = "2";
	}
	
	g_bPluginCommand = true;
	
	engclient_cmd( iPlayerID, "jointeam", strTeam );
	engclient_cmd( iPlayerID, "joinclass", "2" );
	
	g_bPluginCommand = false;
	
	set_msg_block( iMessageID, iMessageBlock );
}

public Task_NotifyMenu( iParameters[ ] ) {
	client_print_color( iParameters[ 0 ], print_team_red, "^4%s^1 Press the ^3team menu^1 button ^4(default M)^1 to open the ^4Main Menu^1.", g_strPluginPrefix );
}

public Task_DisableShop( ) {
	if( g_bAllowShop ) {
		g_bAllowShop = false;
	}
}

/* Impulses */
public Impulse_Spray( iPlayerID ) {
	switch( g_iSprayCustom ) {
		case 0:		return PLUGIN_CONTINUE;
		case 1:		return PLUGIN_HANDLED;
		case 2:	{
			if( !is_user_admin( iPlayerID ) ) {
				return PLUGIN_HANDLED;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

public Impulse_FlashLight( iPlayerID ) {
	switch( g_iFlashLight ) {
		case 0:	{
			return PLUGIN_HANDLED;
		}
		
		case 1: {
			if( cs_get_user_team( iPlayerID ) != CS_TEAM_T ) {
				return PLUGIN_HANDLED;
			}
		}
		
		case 2: {
			if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
				return PLUGIN_HANDLED;
			}
		}
	}
	
	return PLUGIN_CONTINUE;
}

/* Menus */
StartDayVote( ) {
	#if defined DEBUG
	log_amx( "--------------------" );
	log_amx( "Entered 'StartDayVote' function" );
	#endif
	
	g_iTimeLeft = clamp( get_pcvar_num( g_pcvarDayVotePrimary ), g_iPluginSettings[ VOTE_PRIM_MIN ], g_iPluginSettings[ VOTE_PRIM_MAX ] );
	
	/*
		Check if minimum number of Prisoners and Guards is satisfied.
	*/
	if( CheckMinimumPlayers( ) ) {
		#if defined DEBUG
		log_amx( "Minimum players satisfied" );
		#endif
		
		/*
			Check if it's the opposite team's chance to vote.
			This is only applicable if a single team is allowed to vote,
			and not all players.
		*/
		if( g_iDayVote == 1 ) {
			new iDaysToVote = clamp( get_pcvar_num( g_pcvarDayVoteOppositeChance ), g_iPluginSettings[ VOTE_OPPOSITE_MIN ], g_iPluginSettings[ VOTE_OPPOSITE_MAX ] );
			
			#if defined DEBUG
			log_amx( "iDayVote is 1" );
			log_amx( "iDaysToVote is %i", iDaysToVote );
			#endif
			
			if( iDaysToVote && ( g_iDayCount % iDaysToVote ) == 0 ) {
				#if defined DEBUG
				log_amx( "It's opposite team's turn to vote" );
				#endif
				
				g_bOppositeVote = true;
				
				client_print_color( 0, ( g_iDayVoteVoters == 1 ) ? print_team_blue : print_team_red, "^4%s ^3%s ^1 are able to vote this round.", g_strPluginPrefix, ( g_iDayVoteVoters == 1 ) ? "Guards" : "Prisoners" );
			} else {
				#if defined DEBUG
				log_amx( "It is not opposite team's turn to vote" );
				#endif
				
				g_bOppositeVote = false;
			}
		}
		
		#if defined DEBUG
		log_amx( "Shown day vote" );
		#endif
		
		ShowDayVote( );
		set_task( 1.0, "Task_Vote_Day", TASK_VOTE_DAY, _, _, "a", g_iTimeLeft );
	} else {
		#if defined DEBUG
		log_amx( "Minimum players not satisfied" );
		log_amx( "Started cage day" );
		#endif
		
		g_iDayCurrent = DAY_CAGE;
		StartDay( );
		
		client_print_color( 0, print_team_default, "^4%s^1 Day has been set to ^4Cage Day^1.", g_strPluginPrefix );
	}
	
	#if defined DEBUG
	log_amx( "Exited 'StartDayVote' function" );
	log_amx( "--------------------" );
	#endif
}

ShowDayVote( ) {
	/*
		Check if the vote is over and show a blank menu. That
		way we are removing our menu IF it was still shown.
	*/
	if( g_iTimeLeft <= 0 ) {
		show_menu( 0, 0, "^n", 1 );
		
		return;
	}
	
	#if defined DEBUG
	log_amx( "--------------------" );
	log_amx( "Entered 'ShowDayVote' function" );
	#endif
	
	static strMenu[ 2048 ];
	new iLen, iPlayerPage;
	
	/*
		We need to loop throught all players, and display the menu 
		according to each player's prefs (Page, Hidden, ... etc).
	*/
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		/*
			Player has wished not to see the menu, so don't show it.
		*/
		if( CheckBit( g_bitHasMenuHidden, iTempID ) ) {
			continue;
		}
		
		iPlayerPage = g_iPlayerPage[ iTempID ];
		
		#if defined DEBUG
		log_amx( "g_iDayVote is %i", g_iDayVote );
		log_amx( "g_bOppositeVote is %i", g_bOppositeVote ? 1 : 0 );
		#endif
		
		/*
			Depending on the CVAR, check who is allowed to vote and display the 
			header accordingly.
		*/
		switch( g_iDayVoteVoters ) {
			case 1: iLen = formatex( strMenu, charsmax( strMenu ), "\y[%s] Choose A Day: [%i]^n", g_bOppositeVote ? "Guards" : "Prisoners", g_iTimeLeft );
			case 2:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[%s] Choose A Day: [%i]^n", g_bOppositeVote ? "Prisoners" : "Guards", g_iTimeLeft );
			case 3: iLen = formatex( strMenu, charsmax( strMenu ), "\y[ALL] Choose A Day: [%i]^n", g_iTimeLeft );
		}
		
		/*
			Here we are adding each and every day to the menu. The values and dynamic conditions
			is a bit overwhelming at first, but its understandable after a cigarette :P.
		*/
		for( new iInnerLoop = PAGE_OPTIONS * iPlayerPage; ( iInnerLoop < ( iPlayerPage + 1 ) * PAGE_OPTIONS ); iInnerLoop++ ) {
			#if defined DEBUG
			log_amx( "Adding element to day vote menu" );
			log_amx( "Element %i", iInnerLoop );
			#endif
			
			/*
				We have exceeded the available ammount of days. Stop here.
			*/
			if( iInnerLoop >= MAX_DAYS ) {
				#if defined DEBUG
				log_amx( "Element selection is equal to or exceeded MAX_DAYS value, element: %i, MAX_DAYS: %i", iInnerLoop, MAX_DAYS );
				#endif
				
				break;
			}
			
			/*
				Disable or enable element according to the restrictions if there are any.
			*/
			if( g_iDayVoteRestrictDays && g_iDayVoteRestrictionLeft[ iInnerLoop ] > 0 ) {
				#if defined DEBUG
				log_amx( "Element disabled cause restriction left is %i, number %i, votes %i", g_iDayVoteRestrictionLeft[ iInnerLoop ], iInnerLoop - ( iPlayerPage * PAGE_OPTIONS - 1 ), g_iVotesDay[ iInnerLoop ] );
				#endif
				
				iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n\d%i. \d%s \y[\rDays Left: %i\y]", iInnerLoop - ( iPlayerPage * PAGE_OPTIONS - 1 ), g_strOptionsDayVote[ iInnerLoop ], g_iDayVoteRestrictionLeft[ iInnerLoop ] );
			} else {
				#if defined DEBUG
				log_amx( "Element enabled, number %i, votes %i", iInnerLoop - ( iPlayerPage * PAGE_OPTIONS - 1 ), g_iVotesDay[ iInnerLoop ] );
				#endif
				
				iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iInnerLoop - ( iPlayerPage * PAGE_OPTIONS - 1 ), g_strOptionsDayVote[ iInnerLoop ], g_iVotesDay[ iInnerLoop ] );
			}
		}
		
		/*
			Print the navigation buttons.
			8 for Previous and 9 for Next according to the player's page number.
		*/
		if( iPlayerPage == 0 ) {
			if( CheckIfLastPage( iPlayerPage ) ) {
				#if defined DEBUG
				log_amx( "Player on first page AND last page, so disabled back and next buttons. Player page %i, last page %i", iPlayerPage, GetLastPage( ) );
				#endif
				
				iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n^n\d8. \dBack" );
				iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n\d9. \dNext" );
			} else {
				#if defined DEBUG
				log_amx( "Player on first page but NOT last page, so disabled back button. Player page %i, last page %i", iPlayerPage, GetLastPage( ) );
				#endif
				
				iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n^n\d8. \dBack" );
				iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n\y9. \wNext \y[\rVotes: %i\y]", SumOfNextPages( iPlayerPage ) );
			}
			
		} else {
			if( CheckIfLastPage( iPlayerPage ) ) {
				#if defined DEBUG
				log_amx( "Player on last page, so disabled next button. Player page %i, last page %i", iPlayerPage, GetLastPage( ) );
				#endif
				
				iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n^n\y8. \wBack \y[\rVotes: %i\y]", SumOfPreviousPages( iPlayerPage ) );
				iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n\d9. \dNext" );
			} else {
				#if defined DEBUG
				log_amx( "Player not on last page and not on first page, so enabled both buttons. Player page %i, last page %i", iPlayerPage, GetLastPage( ) );
				#endif
				
				iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n^n\y8. \wBack \y[\rVotes: %i\y]", SumOfPreviousPages( iPlayerPage ) );
				iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n\y9. \wNext \y[\rVotes: %i\y]", SumOfNextPages( iPlayerPage ) );
			}
		}
		
		/*
			Print the footer of the menu.
		*/
		iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n^n\y0. \wHide Day Vote" );
		iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n^n\rPage %i/%i", iPlayerPage + 1, GetLastPage( ) );
		
		show_menu( iTempID, 1023, strMenu, -1, "Day Vote" );
	}
	
	#if defined DEBUG
	log_amx( "Exited 'ShowDayVote' function" );
	log_amx( "--------------------" );
	#endif
}

public Handle_DayVote( iPlayerID, iKey ) {
	#if defined DEBUG
	log_amx( "--------------------" );
	log_amx( "Entered 'Handle_DayVote' function" );
	#endif
	
	/*
		Since dead players cannot vote, we stop here if player is dead.
	*/
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		#if defined DEBUG
		log_amx( "Player is not alive" );
		#endif
		
		return;
	}
	
	static iPlayerPage;
	iPlayerPage = g_iPlayerPage[ iPlayerID ];
	
	#if defined DEBUG
	log_amx( "Player's page is %i", iPlayerPage );
	log_amx( "Player's key is %i", iKey );
	log_amx( "iDayVote is %i", g_iDayVote );
	#endif
	
	/*
		In here, since the vote menu only appears at the end of the map, where
		cage and free day has been played so many times, we are blocking the ability
		to vote for those days.
	*/
	if( !iPlayerPage && ( iKey == 1 || iKey == 0 ) && g_iDayVote != 1 ) {
		#if defined DEBUG
		log_amx( "Player cannot vote for first two options because iDayVote is != 1", iPlayerPage );
		#endif
		
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You cannot vote for that day right now. Please choose another.", g_strPluginPrefix );
		
		ShowDayVote( );
		
		return;
	}
	
	new iDayNumber = ( iPlayerPage - 1 ) * PAGE_OPTIONS + ( iKey );
	
	#if defined DEBUG
	log_amx( "iDayNumber is %i", iDayNumber );
	#endif
	
	/*
		The player clicked an area of the menu that does not exist.
		Stop here and notify him.
	*/
	if( CheckIfLastPage( iPlayerPage ) && iDayNumber >= MAX_DAYS ) {
		#if defined DEBUG
		log_amx( "iDayNumber is equal or bigger than MAX_DAYS: %i > %i", iDayNumber, MAX_DAYS );
		#endif
		
		client_print_color( iPlayerID, print_team_default, "^4%s^1 You chose a day that does not exist. Please choose another.", g_strPluginPrefix );
		
		ShowDayVote( );
		
		return;
	}
	
	static CsTeams:iTeam;
	iTeam = cs_get_user_team( iPlayerID );
	
	#if defined DEBUG
	log_amx( "Player's team is %s", ( iTeam == CS_TEAM_CT ) ? "CT" : "T" );
	#endif
	
	switch( iKey ) {
		/*
			He wants to go back a page, check if allowed and act accordingly.
		*/
		case 7: {
			if( !iPlayerPage ){
				#if defined DEBUG
				log_amx( "Player's page is 0, no action on previous page" );
				#endif
			} else {
				#if defined DEBUG
				log_amx( "Decreased player's page by 1" );
				#endif
				
				g_iPlayerPage[ iPlayerID ]--;
			}
		}
		
		/*
			He wants to go forward a page, check if allowed and act accordingly.
		*/
		case 8:	{
			if( iPlayerPage == GetLastPage( ) - 1 ) {
				#if defined DEBUG
				log_amx( "Player's page is last page, no action on next page" );
				#endif
			} else {
				#if defined DEBUG
				log_amx( "Increased player's page by 1" );
				#endif
				
				g_iPlayerPage[ iPlayerID ]++;
			}
		}
		
		/*
			He wants to hide the menu.
		*/
		case 9:	{
			#if defined DEBUG
			log_amx( "No action taken on exit key" );
			#endif
			
			SetBit( g_bitHasMenuHidden, iPlayerID );
			
			client_print_color( iPlayerID, print_team_red, "^4%s^1 You have chosen to hide the vote for the current round.", g_strPluginPrefix );
		}
		
		/*
			If the code here is reached that means, he has voted for a day.
			Let's do the specific calculations.
		*/
		default: {
			/*
				Check if he already voted.
			*/
			if( CheckBit( g_bitHasVoted, iPlayerID ) ) {
				#if defined DEBUG
				log_amx( "Player has already voted, no action taken" );
				#endif
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You have ^3already voted^1.", g_strPluginPrefix );
			} else {
				/*
					Check if he is allowed to vote.
				*/
				if( CheckAllowedVote( iPlayerID, iTeam ) ) {
					new iDayNumber = iPlayerPage * PAGE_OPTIONS + iKey;
					
					#if defined DEBUG
					log_amx( "Player is allowed to vote" );
					log_amx( "iDayNumber is %i", iDayNumber );
					#endif
					
					/*
						Check if the day that he voted for has a restriction.
					*/
					if( g_iDayVoteRestrictDays && g_iDayVoteRestrictionLeft[ iDayNumber ] > 0 ) {
						#if defined DEBUG
						log_amx( "Voting for day stopped due to vote restriction bigger than 0" );
						#endif
						
						client_print_color( iPlayerID, print_team_red, "^4%s^1 You ^3cannot vote^1 for that day yet. Please choose another.", g_strPluginPrefix );
					} else {
						/*
							All checks passed, that means he is able to vote.
							Do some calucluations.
						*/
						SetBit( g_bitHasVoted, iPlayerID );
						
						g_iVotesDay[ iDayNumber ] 	+= CheckWeightedVote( iTeam );
						g_iVotesPages[ iPlayerPage ] 	+= CheckWeightedVote( iTeam );
						
						#if defined DEBUG
						log_amx( "Player's voting bit changed to one" );
						log_amx( "Increased player's choice of day %i and page %i", iDayNumber, iDayNumber % PAGE_OPTIONS );
						#endif
						
						/*
							Show to all players that he has voted for that day.
						*/
						if( g_iDayVoteShowVotes ) {
							#if defined DEBUG
							log_amx( "Displayed player's vote choice to everyone" );
							#endif
							
							new strPlayerName[ 32 ];
							get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
							
							client_print_color( 0, iPlayerID, "^4%s^3 %s^1 voted for ^4%s^1.", g_strPluginPrefix, strPlayerName, g_strOptionsDayVote[ iDayNumber ] );
						}
					}
				}
			}
		}
	}
	
	ShowDayVote( );
	
	#if defined DEBUG
	log_amx( "Exited 'Handle_DayVote' function" );
	log_amx( "--------------------" );
	#endif
}

EndDayVote( ) {
	/*
		Day Vote has ended. Calculate the resut and start the day.
	*/
	#if defined DEBUG
	log_amx( "--------------------" );
	log_amx( "Entered 'EndDayVote' function" );
	#endif
	
	show_menu( 0, 0, "^n", 1 );
	
	/*
		Get the highest voted result. Check if no one voted, then 
		start the default day.
	*/
	g_iDayCurrent = GetHighestVote( g_iVotesDay, MAX_DAYS );
	
	if( g_iDayCurrent == -1 ) {
		g_iDayCurrent = DAY_FREE;
		
		client_print_color( 0, print_team_red, "^4%s^3 Voting failed!^1 Default day loaded.", g_strPluginPrefix );
	} else {
		client_print_color( 0, print_team_default, "^4%s Voting passed!^1 %s loaded.", g_strPluginPrefix, g_strOptionsDayVote[ g_iDayCurrent ] );
	}
	
	/*
		Reset Day Vote variables so the vote is correct every round. And 
		then start the day.
	*/
	ResetDayVote( );
	StartDay( );
	
	#if defined DEBUG
	log_amx( "Exited 'EndDayVote' function" );
	log_amx( "--------------------" );
	#endif
}

ResetDayVote( ) {
	/*
		Reset Day Vote variables so the vote is correct every round.
	*/
	g_bitHasVoted = 0;
	g_bitHasMenuHidden = 0;
	
	arrayset( g_iVotesDay, 		0, sizeof( g_iVotesDay ) );
	arrayset( g_iVotesPages, 	0, sizeof( g_iVotesPages ) );
	arrayset( g_iPlayerPage, 	0, sizeof( g_iPlayerPage ) );
}

StartFreeVote( ) {
	g_iTimeLeft = clamp( get_pcvar_num( g_pcvarDayVoteSecondary ), g_iPluginSettings[ VOTE_SEC_MIN ], g_iPluginSettings[ VOTE_SEC_MAX ] );
	
	ShowFreeVote( );
	set_task( 1.0, "Task_Vote_Free", TASK_VOTE_FREEDAY, _, _, "a", g_iTimeLeft );
}

ShowFreeVote( ) {
	static strMenu[ 1024 ];
	static iKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_0;
	new iLen;
	
	static strOptionsFree[ ][ ] = {
		"Unrestricted Free Day",
		"Restricted Free Day"
	};
	
	switch( g_iDayVoteVoters ) {
		case 1:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[%s] Choose A Type: [%i]^n", g_bOppositeVote ? "Guards" : "Prisoners", g_iTimeLeft );
		case 2:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[%s] Choose A Type: [%i]^n", g_bOppositeVote ? "Prisoners" : "Guards", g_iTimeLeft );
		case 3:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[ALL] Choose A Type: [%i]^n", g_iTimeLeft );
	}
	
	for( new iLoop = 0; iLoop < sizeof( strOptionsFree ); iLoop++ ) {
		iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iLoop + 1, strOptionsFree[ iLoop ], g_iVotesFree[ iLoop ] );
	}
	
	iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n^n\y0. \wHide Day Vote" );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		/*
			Player has wished not to see the menu, so don't show it.
		 */
		if( CheckBit( g_bitHasMenuHidden, iTempID ) ) {
			continue;
		}
		
		show_menu( iTempID, iKeys, strMenu, -1, "Free Vote" );
	}
}

public Handle_FreeVote( iPlayerID, iKey ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	if( iKey == 9 ) {
		SetBit( g_bitHasMenuHidden, iPlayerID );
		
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have chosen to hide the vote for the current round.", g_strPluginPrefix );
	} else {
		if( CheckBit( g_bitHasVoted, iPlayerID ) ) {
			client_print_color( iPlayerID, print_team_red, "^4%s^1 You have ^3already voted^1.", g_strPluginPrefix );
		} else {
			new CsTeams:iTeam = cs_get_user_team( iPlayerID );
			
			if( CheckAllowedVote( iPlayerID, iTeam ) ) {
				SetBit( g_bitHasVoted, iPlayerID );
				
				g_iVotesFree[ iKey ] += CheckWeightedVote( iTeam );
				
				if( g_iDayVoteShowVotes ) {
					static strOptionsFree[ ][ ] = {
						"Unrestricted Free Day",
						"Restricted Free Day"
					};
					
					new strPlayerName[ 32 ];
					get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
					
					client_print_color( 0, iPlayerID, "^4%s^3 %s^1 voted for ^4%s^1.", g_strPluginPrefix, strPlayerName, strOptionsFree[ iKey ] );
				}
			}
		}
	}
}

EndFreeVote( ) {
	show_menu( 0, 0, "^n", 1 );
	
	g_iTypeFree = GetHighestVote( g_iVotesFree, sizeof( g_iVotesFree ) );
	
	if( g_iTypeFree == -1 ) {
		g_iTypeFree = TYPE_UNRESTRICTED;
		
		client_print_color( 0, print_team_red, "^4%s^3 Voting failed!^1 Default type loaded.", g_strPluginPrefix );
	}
	
	ResetFreeVote( );
	StartFreeDay( );
}

ResetFreeVote( ) {
	g_bitHasVoted = 0;
	g_bitHasMenuHidden = 0;
	
	arrayset( g_iVotesFree, 0, sizeof( g_iVotesFree ) );
}

StartNightCrawlerVote( ) {
	g_iTimeLeft = clamp( get_pcvar_num( g_pcvarDayVoteSecondary ), g_iPluginSettings[ VOTE_SEC_MIN ], g_iPluginSettings[ VOTE_SEC_MAX ] );
	
	ShowNightCrawlerVote( );
	set_task( 1.0, "Task_Vote_NightCrawler", TASK_VOTE_NIGHTCRAWLER, _, _, "a", g_iTimeLeft );
}

ShowNightCrawlerVote( ) {
	static strMenu[ 1024 ];
	static iKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_0;
	new iLen;
	
	static strOptionsNightCrawler[ ][ ] = {
		"Regular \y[\rNightCrawlers = Guards\y]",
		"Reverse \y[\rNightCrawlers = Prisoners\y]"
	};
	
	switch( g_iDayVoteVoters ) {
		case 1:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[%s] Choose A Type: [%i]^n", g_bOppositeVote ? "Guards" : "Prisoners", g_iTimeLeft );
		case 2:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[%s] Choose A Type: [%i]^n", g_bOppositeVote ? "Prisoners" : "Guards", g_iTimeLeft );
		case 3:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[ALL] Choose A Type: [%i]^n", g_iTimeLeft );
	}
	
	for( new iLoop = 0; iLoop < sizeof( strOptionsNightCrawler ); iLoop++ ) {
		iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iLoop + 1, strOptionsNightCrawler[ iLoop ], g_iVotesNightCrawler[ iLoop ] );
	}
	
	iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n^n\y0. \wHide Day Vote" );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		/*
			Player has wished not to see the menu, so don't show it.
		 */
		if( CheckBit( g_bitHasMenuHidden, iTempID ) ) {
			continue;
		}
		
		show_menu( iTempID, iKeys, strMenu, -1, "NightCrawler Vote" );
	}
}

public Handle_NightCrawlerVote( iPlayerID, iKey ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	if( iKey == 9 ) {
		SetBit( g_bitHasMenuHidden, iPlayerID );
		
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have chosen to hide the vote for the current round.", g_strPluginPrefix );
	} else {
		if( CheckBit( g_bitHasVoted, iPlayerID ) ) {
			client_print_color( iPlayerID, print_team_red, "^4%s^1 You have ^3already voted^1.", g_strPluginPrefix );
		} else {
			new CsTeams:iTeam = cs_get_user_team( iPlayerID );
			
			if( CheckAllowedVote( iPlayerID, iTeam ) ) {
				SetBit( g_bitHasVoted, iPlayerID );
				
				g_iVotesNightCrawler[ iKey ] += CheckWeightedVote( iTeam );
				
				if( g_iDayVoteShowVotes ) {
					static strOptionsNightCrawler[ ][ ] = {
						"Regular [NightCrawlers = Guards]",
						"Reverse [NightCrawlers = Prisoners]"
					};
					
					new strPlayerName[ 32 ];
					get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
					
					client_print_color( 0, iPlayerID, "^4%s^3 %s^1 voted for ^4%s^1.", g_strPluginPrefix, strPlayerName, strOptionsNightCrawler[ iKey ] );
				}
			}
		}
	}
}

EndNightCrawlerVote( ) {
	show_menu( 0, 0, "^n", 1 );
	
	g_iTypeNightCrawler = GetHighestVote( g_iVotesNightCrawler, sizeof( g_iVotesNightCrawler ) );
	
	if( g_iTypeNightCrawler == -1 ) {
		g_iTypeNightCrawler = TYPE_REGULAR;
		
		client_print_color( 0, print_team_red, "^4%s^3 Voting failed!^1 Default type loaded.", g_strPluginPrefix );
	}
	
	ResetNightCrawlerVote( );
	StartNightCrawlerDay( );
}

ResetNightCrawlerVote( ) {
	g_bitHasVoted = 0;
	g_bitHasMenuHidden = 0;
	
	arrayset( g_iVotesNightCrawler, 0, sizeof( g_iVotesNightCrawler ) );
}

StartZombieVote( ) {
	g_iTimeLeft = clamp( get_pcvar_num( g_pcvarDayVoteSecondary ), g_iPluginSettings[ VOTE_SEC_MIN ], g_iPluginSettings[ VOTE_SEC_MAX ] );
	
	ShowZombieVote( );
	set_task( 1.0, "Task_Vote_Zombie", TASK_VOTE_ZOMBIE, _, _, "a", g_iTimeLeft );
}

ShowZombieVote( ) {
	static strMenu[ 1024 ];
	static iKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_0;
	new iLen;
	
	static strOptionsZombie[ ][ ] = {
		"Regular \y[\rZombies = Prisoners\y]",
		"Reverse \y[\rZombies = Guards\y]"
	};
	
	switch( g_iDayVoteVoters ) {
		case 1:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[%s] Choose A Type: [%i]^n", g_bOppositeVote ? "Guards" : "Prisoners", g_iTimeLeft );
		case 2:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[%s] Choose A Type: [%i]^n", g_bOppositeVote ? "Prisoners" : "Guards", g_iTimeLeft );
		case 3:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[ALL] Choose A Type: [%i]^n", g_iTimeLeft );
	}
	
	for( new iLoop = 0; iLoop < sizeof( strOptionsZombie ); iLoop++ ) {
		iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iLoop + 1, strOptionsZombie[ iLoop ], g_iVotesZombie[ iLoop ] );
	}
	
	iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n^n\y0. \wHide Day Vote" );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		/*
			Player has wished not to see the menu, so don't show it.
		 */
		if( CheckBit( g_bitHasMenuHidden, iTempID ) ) {
			continue;
		}
		
		show_menu( iTempID, iKeys, strMenu, -1, "Zombie Vote" );
	}
}

public Handle_ZombieVote( iPlayerID, iKey ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	if( iKey == 9 ) {
		SetBit( g_bitHasMenuHidden, iPlayerID );
		
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have chosen to hide the vote for the current round.", g_strPluginPrefix );
	} else {
		if( CheckBit( g_bitHasVoted, iPlayerID ) ) {
			client_print_color( iPlayerID, print_team_red, "^4%s^1 You have ^3already voted^1.", g_strPluginPrefix );
		} else {
			new CsTeams:iTeam = cs_get_user_team( iPlayerID );
			
			if( CheckAllowedVote( iPlayerID, iTeam ) ) {
				SetBit( g_bitHasVoted, iPlayerID );
				
				g_iVotesZombie[ iKey ] += CheckWeightedVote( iTeam );
				
				if( g_iDayVoteShowVotes ) {
					static strOptionsZombie[ ][ ] = {
						"Regular [Zombies = Prisoners]",
						"Reverse [Zombies = Guards]"
					};
					
					new strPlayerName[ 32 ];
					get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
					
					client_print_color( 0, iPlayerID, "^4%s^3 %s^1 voted for ^4%s^1.", g_strPluginPrefix, strPlayerName, strOptionsZombie[ iKey ] );
				}
			}
		}
	}
}

EndZombieVote( ) {
	show_menu( 0, 0, "^n", 1 );
	
	g_iTypeZombie = GetHighestVote( g_iVotesZombie, sizeof( g_iVotesZombie ) );
	
	if( g_iTypeZombie == -1 ) {
		g_iTypeZombie = TYPE_REGULAR;
		
		client_print_color( 0, print_team_red, "^4%s^3 Voting failed!^1 Default type loaded.", g_strPluginPrefix );
	}
	
	ResetZombieVote( );
	StartZombieDay( );
}

ResetZombieVote( ) {
	g_bitHasVoted = 0;
	g_bitHasMenuHidden = 0;
	
	arrayset( g_iVotesZombie, 0, sizeof( g_iVotesZombie ) );
}

StartSharkVote( ) {
	g_iTimeLeft = clamp( get_pcvar_num( g_pcvarDayVoteSecondary ), g_iPluginSettings[ VOTE_SEC_MIN ], g_iPluginSettings[ VOTE_SEC_MAX ] );
	
	ShowSharkVote( );
	set_task( 1.0, "Task_Vote_Shark", TASK_VOTE_SHARK, _, _, "a", g_iTimeLeft );
}

ShowSharkVote( ) {
	static strMenu[ 1024 ];
	static iKeys = MENU_KEY_1 | MENU_KEY_2 | MENU_KEY_0;
	new iLen;
	
	static strOptionsShark[ ][ ] = {
		"Regular \y[\rSharks = Guards\y]",
		"Reverse \y[\rSharks = Prisoners\y]"
	};
	
	switch( g_iDayVoteVoters ) {
		case 1:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[%s] Choose A Type: [%i]^n", g_bOppositeVote ? "Guards" : "Prisoners", g_iTimeLeft );
		case 2:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[%s] Choose A Type: [%i]^n", g_bOppositeVote ? "Prisoners" : "Guards", g_iTimeLeft );
		case 3:	iLen = formatex( strMenu, charsmax( strMenu ), "\y[ALL] Choose A Type: [%i]^n", g_iTimeLeft );
	}
	
	for( new iLoop = 0; iLoop < sizeof( strOptionsShark ); iLoop++ ) {
		iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n\y%i. \w%s \y[\rVotes: %i\y]", iLoop + 1, strOptionsShark[ iLoop ], g_iVotesShark[ iLoop ] );
	}
	
	iLen += formatex( strMenu[ iLen ], charsmax( strMenu ) - iLen, "^n^n\y0. \wHide Day Vote" );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		/*
			Player has wished not to see the menu, so don't show it.
		 */
		if( CheckBit( g_bitHasMenuHidden, iTempID ) ) {
			continue;
		}
		
		show_menu( iTempID, iKeys, strMenu, -1, "Shark Vote" );
	}
}

public Handle_SharkVote( iPlayerID, iKey ) {
	if( !CheckBit( g_bitIsAlive, iPlayerID ) ) {
		return;
	}
	
	if( iKey == 9 ) {
		SetBit( g_bitHasMenuHidden, iPlayerID );
		
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You have chosen to hide the vote for the current round.", g_strPluginPrefix );
	} else {
		if( CheckBit( g_bitHasVoted, iPlayerID ) ) {
			client_print_color( iPlayerID, print_team_red, "^4%s^1 You have ^3already voted^1.", g_strPluginPrefix );
		} else {
			new CsTeams:iTeam = cs_get_user_team( iPlayerID );
			
			if( CheckAllowedVote( iPlayerID, iTeam ) ) {
				SetBit( g_bitHasVoted, iPlayerID );
				
				g_iVotesShark[ iKey ] += CheckWeightedVote( iTeam );
				
				if( g_iDayVoteShowVotes ) {
					static strOptionsShark[ ][ ] = {
						"Regular [Sharks = Guards]",
						"Reverse [Sharks = Prisoners]"
					};
					
					new strPlayerName[ 32 ];
					get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
					
					client_print_color( 0, iPlayerID, "^4%s^3 %s^1 voted for ^4%s^1.", g_strPluginPrefix, strPlayerName, strOptionsShark[ iKey ] );
				}
			}
		}
	}
}

EndSharkVote( ) {
	show_menu( 0, 0, "^n", 1 );
	
	g_iTypeShark = GetHighestVote( g_iVotesShark, sizeof( g_iVotesShark ) );
	
	if( g_iTypeShark == -1 ) {
		g_iTypeShark = TYPE_REGULAR;
		
		client_print_color( 0, print_team_red, "^4%s^3 Voting failed!^1 Default type loaded.", g_strPluginPrefix );
	}
	
	ResetSharkVote( );
	StartSharkDay( );
}

ResetSharkVote( ) {
	g_bitHasVoted = 0;
	g_bitHasMenuHidden = 0;
	
	arrayset( g_iVotesShark, 0, sizeof( g_iVotesShark ) );
}

StartForceDayMenu( iPlayerID ) {
	if( task_exists( TASK_VOTE_DAY ) || task_exists( TASK_VOTE_FREEDAY ) || task_exists( TASK_VOTE_NIGHTCRAWLER ) ||
	task_exists( TASK_VOTE_SHARK ) || task_exists( TASK_VOTE_ZOMBIE ) ) {
		client_print_color( iPlayerID, print_team_default, "^4%s^1 Please wait until the vote has ended.", g_strPluginPrefix );
	} else {
		ShowForceDayMenu( iPlayerID );
	}
	
	return PLUGIN_HANDLED;
}

ShowForceDayMenu( iPlayerID ) {
	static menuForceDay;
	
	if( !menuForceDay ) {
		new strMenuTitle[ ] = "\yChoose A Day:^n";
		
		menuForceDay = menu_create( strMenuTitle, "Handle_ForceDayMenu" );
		
		new strDayNumber[ 2 ];
		
		for( new iLoop = 0; iLoop < MAX_DAYS; iLoop++ ) {
			num_to_str( iLoop, strDayNumber, charsmax( strDayNumber ) );
			
			menu_additem( menuForceDay, g_strOptionsDayVote[ iLoop ], strDayNumber );
		}
		
		menu_setprop( menuForceDay, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuForceDay, 0 );
}

public Handle_ForceDayMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	new strDayNumber[ 2 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strDayNumber, charsmax( strDayNumber ), _, _, iCallBack );
	
	g_iDayForced = str_to_num( strDayNumber );
	
	switch( g_iDayForced ) {
		case DAY_FREE:		ShowFreeForceMenu( iPlayerID );
		case DAY_NIGHTCRAWLER:	ShowNightCrawlerForceMenu( iPlayerID );
		case DAY_ZOMBIE:	ShowZombieForceMenu( iPlayerID );
		case DAY_SHARK:		ShowSharkForceMenu( iPlayerID );
		default: {
			EndDay( );
			
			g_iDayCurrent = g_iDayForced;
			StartDay( );
			
			new strPlayerName[ 32 ];
			get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
			
			client_print_color( 0, iPlayerID, "^4%s^3 %s^1 forced a ^4%s^1.", g_strPluginPrefix, strPlayerName, g_strOptionsDayVote[ g_iDayCurrent ] );
		}
	}
}

ShowFreeForceMenu( iPlayerID ) {
	static menuForceFree;
	
	if( !menuForceFree ) {
		new strMenuTitle[ ] = "\yChoose A Type:^n";
		
		menuForceFree = menu_create( strMenuTitle, "Handle_ForceDayExtraMenu" );
		
		new strOptionsFree[ ][ ] = {
			"Unrestricted Free Day",
			"Restricted Free Day"
		};
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsFree ); iLoop++ ) {
			menu_additem( menuForceFree, strOptionsFree[ iLoop ] );
		}
		
		menu_setprop( menuForceFree, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuForceFree, 0 );
}

ShowNightCrawlerForceMenu( iPlayerID ) {
	static menuForceNightCrawler;
	
	if( !menuForceNightCrawler ) {
		new strMenuTitle[ ] = "\yChoose A Type:^n";
		
		menuForceNightCrawler = menu_create( strMenuTitle, "Handle_ForceDayExtraMenu" );
		
		new strOptionsNightCrawler[ ][ ] = {
			"Regular NightCrawler Day \y[\rOfficers = NightCrawlers\y]",
			"Reverse NightCrawler Day \y[\rPrisoners = NightCrawlers\y]"
		};
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsNightCrawler ); iLoop++ ) {
			menu_additem( menuForceNightCrawler, strOptionsNightCrawler[ iLoop ] );
		}
		
		menu_setprop( menuForceNightCrawler, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuForceNightCrawler, 0 );
}

ShowZombieForceMenu( iPlayerID ) {
	static menuForceZombie;
	
	if( !menuForceZombie ) {
		new strMenuTitle[ ] = "\yChoose A Type:^n";
		
		menuForceZombie = menu_create( strMenuTitle, "Handle_ForceDayExtraMenu" );
		
		new strOptionsZombie[ ][ ] = {
			"Regular Zombie Day \y[\rPrisoners = Zombies\y]",
			"Reverse Zombie Day \y[\rOfficers = Zombies\y]"
		};
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsZombie ); iLoop++ ) {
			menu_additem( menuForceZombie, strOptionsZombie[ iLoop ] );
		}
		
		menu_setprop( menuForceZombie, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuForceZombie, 0 );
}

ShowSharkForceMenu( iPlayerID ) {
	static menuForceShark;
	
	if( !menuForceShark ) {
		new strMenuTitle[ ] = "\yChoose A Type:^n";
		
		menuForceShark = menu_create( strMenuTitle, "Handle_ForceDayExtraMenu" );
		
		new strOptionsShark[ ][ ] = {
			"Regular Shark Day \y[\rOfficers = Sharks\y]",
			"Reverse Shark Day \y[\rPrisoners = Sharks\y]"
		};
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsShark ); iLoop++ ) {
			menu_additem( menuForceShark, strOptionsShark[ iLoop ] );
		}
		
		menu_setprop( menuForceShark, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuForceShark, 0 );
}

public Handle_ForceDayExtraMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	EndDay( );
	g_iDayCurrent = g_iDayForced;
	
	switch( g_iDayForced ) {
		case DAY_FREE: {
			g_iTypeFree = iKey + 2;
			StartFreeDay( );
		}
		
		case DAY_NIGHTCRAWLER: {
			g_iTypeNightCrawler = iKey;
			StartNightCrawlerDay( );
		}
		
		case DAY_ZOMBIE: {
			g_iTypeZombie = iKey;
			StartZombieDay( );
		}
		
		case DAY_SHARK: {
			g_iTypeShark = iKey;
			StartSharkDay( );
		}
	}
}

ShowWeaponMenu( iPlayerID, strTeam[ ] = "" ) {
	if( !iPlayerID ) {
		new iPlayers[ 32 ], iNum;
		
		switch( strTeam[ 0 ] ) {
			case 'C', 'c': {
				get_players( iPlayers, iNum, "ae", "CT" );
			}
			
			case 'T', 't': {
				get_players( iPlayers, iNum, "ae", "TERRORIST" );
			}
			
			case 'A', 'a': {
				get_players( iPlayers, iNum, "a" );
			}
		}
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			ShowPrimaryWeaponMenu( iPlayers[ iLoop ] );
		}
	} else {
		ShowPrimaryWeaponMenu( iPlayerID );
	}
}

ShowPrimaryWeaponMenu( iPlayerID ) {
	static menuPrimaryWeapon;
	
	if( !menuPrimaryWeapon ) {
		new strMenuTitle[ ] = "\yChoose A Primary Weapon:^n";
		
		menuPrimaryWeapon = menu_create( strMenuTitle, "Handle_PrimaryWeaponMenu" );
		
		new strNumber[ 2 ];
		
		new strPrimaryWeapons[ SECONDARY_USP ][ ] = {
			"M4A1",		"AK47",
			"AUG",		"SG552",
			"Galil",	"Famas",
			"Scout",	"AWP",
			"M249",		"UMP 45",
			"MP5 Navy",	"M3",
			"XM1014",	"TMP",
			"Mac 10",	"P90"
		};
		
		for( new iLoop = 0; iLoop < SECONDARY_USP; iLoop++ ) {
			num_to_str( iLoop, strNumber, charsmax( strNumber ) );
			
			menu_additem( menuPrimaryWeapon, strPrimaryWeapons[ iLoop ], strNumber );
		}
		
		menu_setprop( menuPrimaryWeapon, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuPrimaryWeapon, 0 );
}

public Handle_PrimaryWeaponMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	new strWeaponName[ 2 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strWeaponName, charsmax( strWeaponName ), _, _, iCallBack );
	
	new iWeaponID = str_to_num( strWeaponName );
	
	g_iPlayerPrimaryWeapon[ iPlayerID ] = iWeaponID;
	
	ShowSecondaryWeaponMenu( iPlayerID );
}

ShowSecondaryWeaponMenu( iPlayerID ) {
	static menuSecondaryWeapon;
	
	if( !menuSecondaryWeapon ) {
		new strMenuTitle[ ] = "\yChoose A Secondary Weapon:^n";
		
		menuSecondaryWeapon = menu_create( strMenuTitle, "Handle_SecondaryWeaponMenu" );
		
		new strNumber[ 2 ];
		
		new strSecondaryWeapons[ MAX_WEAPONS - SECONDARY_USP ][ ] = {
			"USP",
			"Glock",
			"Deagle",
			"P228",
			"Elite",
			"Five Seven"
		};
		
		for( new iLoop = 0; iLoop < ( MAX_WEAPONS - SECONDARY_USP ); iLoop++ ) {
			num_to_str( iLoop, strNumber, charsmax( strNumber ) );
			
			menu_additem( menuSecondaryWeapon, strSecondaryWeapons[ iLoop ], strNumber );
		}
		
		menu_setprop( menuSecondaryWeapon, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuSecondaryWeapon, 0 );
}

public Handle_SecondaryWeaponMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	switch( g_iDayCurrent ) {
		case DAY_CAGE, DAY_FREE, DAY_RIOT, DAY_JUDGEMENT, DAY_CUSTOM, DAY_HNS: {
			if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
				client_print_color( iPlayerID, print_team_blue, "^4%s^1 Only ^3Guards^1 are allowed to choose weapons on this day.", g_strPluginPrefix );
				
				return;
			}
		}
	}
	
	new strWeaponName[ 2 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strWeaponName, charsmax( strWeaponName ), _, _, iCallBack );
	
	new iSecondaryWeapon = str_to_num( strWeaponName );
	
	GivePlayerWeapon( iPlayerID, ":P", g_iPlayerPrimaryWeapon[ iPlayerID ], iSecondaryWeapon );
	
	if( g_iWeaponMenuArmor ) {
		cs_set_user_armor( iPlayerID, g_iWeaponMenuArmor, CS_ARMOR_VESTHELM );
	}
	
	switch( g_iWeaponMenuNades ) {
		case 1: {
			give_item( iPlayerID, "weapon_hegrenade" );
		}
		
		case 2: {
			give_item( iPlayerID, "weapon_flashbang" );
			give_item( iPlayerID, "weapon_flashbang" );
		}
		
		case 3: {
			give_item( iPlayerID, "weapon_hegrenade" );
			give_item( iPlayerID, "weapon_flashbang" );
			give_item( iPlayerID, "weapon_flashbang" );
		}
	}
}

ShowFreeDayMenu( iPlayerID ) {
	new strMenuTitle[ ] = "\yChoose A Player:^n";
	
	static menuFreeDayMenu[ MAX_PLAYERS + 1 ];
	menuFreeDayMenu[ iPlayerID ] = menu_create( strMenuTitle, "Handle_FreeDayMenu" );
	
	new strPlayerName[ 32 ], strPlayerID[ 8 ];
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	if( iNum <= 1 ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 There are not enough or no ^4Prisoners^1 to show the menu.", g_strPluginPrefix );
		
		return;
	}
	
	new strFormatex[ 64 ];
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		num_to_str( get_user_userid( iTempID ), strPlayerID, charsmax( strPlayerID ) );
		get_user_name( iTempID, strPlayerName, charsmax( strPlayerName ) );
		
		if( CheckBit( g_bitHasFreeDay, iTempID ) ) {
			formatex( strFormatex, charsmax( strFormatex ), "\rREMOVE: \w%s", strPlayerName );
		} else {
			formatex( strFormatex, charsmax( strFormatex ), "\rGIVE: \w%s", strPlayerName );
		}
		
		menu_additem( menuFreeDayMenu[ iPlayerID ], strFormatex, strPlayerID );
	}
	
	menu_setprop( menuFreeDayMenu[ iPlayerID ], MPROP_NUMBER_COLOR, "\y" );
	
	menu_display( iPlayerID, menuFreeDayMenu[ iPlayerID ], 0 );
}

public Handle_FreeDayMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		menu_destroy( iMenu );
		
		return;
	}
	
	new strPlayerID[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strPlayerID, charsmax( strPlayerID ), _, _, iCallBack );
	
	new iTarget = find_player( "k", str_to_num( strPlayerID ) );
	
	if( !is_user( iTarget ) ) {
		menu_destroy( iMenu );
		ShowFreeDayMenu( iPlayerID );
		
		return;
	}
	
	new strTargetName[ 32 ], strAdminName[ 32 ];
	get_user_name( iTarget, strTargetName, charsmax( strTargetName ) );
	get_user_name( iPlayerID, strAdminName, charsmax( strAdminName ) );
	
	if( !CheckBit( g_bitIsAlive, iTarget ) ) {
		client_print_color( iPlayerID, iTarget, "^4%s^3 %s^1 is no longer alove.", g_strPluginPrefix );
	} else {
		if( CheckBit( g_bitHasFreeDay, iTarget ) ) {
			set_user_rendering( iTarget );
			
			ClearBit( g_bitHasFreeDay, iTarget );
			
			client_print_color( 0, iPlayerID, "^4%s^3 %s^1 removed ^4%s^1's personal free day.", g_strPluginPrefix, strAdminName, strTargetName );
		} else {
			set_user_rendering( iTarget, kRenderFxGlowShell, 220, 220, 0, kRenderNormal, 5 );
			UTIL_ScreenFade( iTarget, { 220, 220, 0 }, 2.0, 0.5, 100, 0x0001 /* FFADE_OUT */ );
			
			SetBit( g_bitHasFreeDay, iTarget );
			
			client_print_color( 0, iPlayerID, "^4%s^3 %s^1 gave ^4%s^1 a personal free day.", g_strPluginPrefix, strAdminName, strTargetName );
		}
	}
	
	menu_destroy( iMenu );
	
	ShowFreeDayMenu( iPlayerID );
}

ShowLastRequestMenu( iPlayerID, iPage = 0 ) {
	if( g_iLRLastTerrorist != iPlayerID ) {
		return;
	}
	
	static menuLastRequest;
	
	if( !menuLastRequest ) {
		new strMenuTitle[ ] = "\yLast Request Menu:^n";
		
		menuLastRequest = menu_create( strMenuTitle, "Handle_LastRequestMenu" );
		
		new strOptionsLastRequestExtra[ ][ ] = {
			"\y[\rsharpen your knife and get ready \y]",
			"\y[\rthrow that heavy thing\y]",
			"\y[\rshoot that bastard\y]",
			"\y[\rcan you get that headshot?\y]",
			"\y[\rWILD WEST here I come\y]",
			"\y[\rno the nade does not explode\y]",
			"\y[\rthat scout is hot, get rid of it\y]",
			"\y[\rstrafe running is what I do\y]",
			"\y[\ryou a graffity artist?\y]",
			"\y[\rAHHH!\y]",
			"\y[\rKABOOOOM!\y]",
			"\y[\rsneaky beaky like\y]",
			"\y[\rburst fire his head off\y]"
		};
		
		new strNumber[ 8 ], strFormatex[ 128 ];
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsLastRequestExtra ); iLoop++ ) {
			num_to_str( iLoop , strNumber, charsmax( strNumber ) );
			
			switch( iLoop ) {
				case LR_KAMIKAZE, LR_SUICIDE, LR_MANIAC, LR_GLOCKER: {
					formatex( strFormatex, charsmax( strFormatex ), "\rREBELL: \w%s %s", g_strOptionsLastRequest[ iLoop ], strOptionsLastRequestExtra[ iLoop ] );
				}
				
				default: {
					formatex( strFormatex, charsmax( strFormatex ), "\w%s %s", g_strOptionsLastRequest[ iLoop ], strOptionsLastRequestExtra[ iLoop ] );
				}
			}
			
			menu_additem( menuLastRequest, strFormatex, strNumber );
		}
		
		menu_setprop( menuLastRequest, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuLastRequest, iPage );
}

public Handle_LastRequestMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT || g_bLRInProgress || g_iLRLastTerrorist != iPlayerID ) {
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, charsmax( strOption ), _, _, iCallBack );
	
	g_iLRCurrent = str_to_num( strOption );
	
	switch( g_iLRCurrent ) {
		case LR_KNIFE:		ShowKnifeFightHealthMenu( iPlayerID );
		case LR_WEAPONTOSS:	ShowWeaponTossWeaponMenu( iPlayerID );
		case LR_DUEL:		ShowDuelWeaponMenu( iPlayerID );
		case LR_S4S:		ShowS4SWeaponMenu( iPlayerID );
		
		case LR_SHOWDOWN, LR_GRENADETOSS, LR_HOTPOTATO, LR_RACE, LR_SPRAY: {
			ShowLRPlayerMenu( iPlayerID );
		}
		
		case LR_KAMIKAZE: {
			if( GetTeamPlayersNumber( "C" ) < g_iPluginSettings[ KAMIKAZE_GUARD_COUNT ] ) {
				client_print_color( iPlayerID, print_team_blue, "^4%s^1 There must be at least ^3%i Guards^1 to choose this option.", g_strPluginPrefix, g_iPluginSettings[ KAMIKAZE_GUARD_COUNT ] );
				
				ShowLastRequestMenu( iPlayerID, LR_KAMIKAZE % PAGE_OPTIONS );
			} else {
				StartKamikaze( iPlayerID );
			}
			
			Task_ShowTopInfo( );
		}
		
		case LR_SUICIDE: {
			SuicidePlayer( iPlayerID );
			
			new strPlayerName[ 32 ];
			get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
			
			client_print_color( 0, iPlayerID, "^4%s^1 Suicide bomber ^3%s^1 has killed all nearby Guards.", g_strPluginPrefix, strPlayerName );
			
			Task_ShowTopInfo( );
		}
		
		case LR_MANIAC: {
			if( GetTeamPlayersNumber( "C" ) < g_iPluginSettings[ MANIAC_GUARD_COUNT ] ) {
				client_print_color( iPlayerID, print_team_blue, "^4%s^1 There must be at least ^3%i Guards^1 to choose this option.", g_strPluginPrefix, g_iPluginSettings[ MANIAC_GUARD_COUNT ] );
				
				ShowLastRequestMenu( iPlayerID, LR_MANIAC % PAGE_OPTIONS );
			} else {
				StartDeagleManiac( iPlayerID );
			}
			
			Task_ShowTopInfo( );
		}
		
		case LR_GLOCKER: {
			if( GetTeamPlayersNumber( "C" ) < g_iPluginSettings[ GLOCKER_GUARD_COUNT ] ) {
				client_print_color( iPlayerID, print_team_blue, "^4%s^1 There must be at least ^3%i Guards^1 to choose this option.", g_strPluginPrefix, g_iPluginSettings[ GLOCKER_GUARD_COUNT ] );
				
				ShowLastRequestMenu( iPlayerID, LR_GLOCKER % PAGE_OPTIONS );
			} else {
				StartUberGlocker( iPlayerID );
			}
			
			Task_ShowTopInfo( );
		}
	}
}

ShowKnifeFightHealthMenu( iPlayerID ) {
	if( g_iLRLastTerrorist != iPlayerID ) {
		return;
	}
	
	static menuKnifeFightHealth;
	
	if( !menuKnifeFightHealth ) {
		new strMenuTitle[ ] = "\yKnife Fight Health Menu:^n";
		
		menuKnifeFightHealth = menu_create( strMenuTitle, "Handle_KnifeFightHealthMenu" );
		
		new strHealth[ 8 ];
		
		for( new iLoop = KNIFE_HEALTH_1; iLoop <= KNIFE_HEALTH_4; iLoop++ ) {
			num_to_str( g_iPluginSettings[ iLoop ], strHealth, charsmax( strHealth ) );
			
			menu_additem( menuKnifeFightHealth, strHealth );
		}
		
		menu_setprop( menuKnifeFightHealth, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuKnifeFightHealth );
}

public Handle_KnifeFightHealthMenu( iPlayerID, iMenu, iKey ) {
	if( g_bLRInProgress || g_iLRLastTerrorist != iPlayerID ) {
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		ShowLastRequestMenu( iPlayerID, LR_KNIFE % PAGE_OPTIONS );
		
		return;
	}
	
	g_iLRChosenKnifeFight = iKey;
	ShowLRPlayerMenu( iPlayerID );
}

ShowWeaponTossWeaponMenu( iPlayerID ) {
	if( g_iLRLastTerrorist != iPlayerID ) {
		return;
	}
	
	static menuWeaponTossWeaponMenu;
	
	if( !menuWeaponTossWeaponMenu ) {
		new strMenuTitle[ ] = "\yWeapon Toss Weapon Menu:^n";
		
		menuWeaponTossWeaponMenu = menu_create( strMenuTitle, "Handle_WeaponTossWeaponMenu" );
		
		new strCapitalizedFirstLetter[ 32 ];
		
		for( new iLoop = TOSS_WEAPON_1_STR; iLoop <= TOSS_WEAPON_3_STR; iLoop++ ) {
			formatex( strCapitalizedFirstLetter, charsmax( strCapitalizedFirstLetter ), g_strWeapons[ g_iPluginSettings[ iLoop ] ][ 7 ] );
			CapitalizeFirstLetter( strCapitalizedFirstLetter );
			
			menu_additem( menuWeaponTossWeaponMenu, strCapitalizedFirstLetter );
		}
		
		menu_setprop( menuWeaponTossWeaponMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuWeaponTossWeaponMenu );
}

public Handle_WeaponTossWeaponMenu( iPlayerID, iMenu, iKey ) {
	if( g_bLRInProgress || g_iLRLastTerrorist != iPlayerID ) {
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		ShowLastRequestMenu( iPlayerID, LR_WEAPONTOSS % PAGE_OPTIONS );
		
		return;
	}
	
	g_iLRChosenWeaponToss = iKey;
	ShowLRPlayerMenu( iPlayerID );
}

ShowDuelWeaponMenu( iPlayerID ) {
	if( g_iLRLastTerrorist != iPlayerID ) {
		return;
	}
	
	static menuDuelWeaponMenu;
	
	if( !menuDuelWeaponMenu ) {
		new strMenuTitle[ ] = "\yDuel Weapon Menu:^n";
		
		menuDuelWeaponMenu = menu_create( strMenuTitle, "Handle_DuelWeaponMenu" );
		
		new strCapitalizedFirstLetter[ 32 ];
		
		for( new iLoop = DUEL_WEAPON_1_STR; iLoop <= DUEL_WEAPON_5_STR; iLoop++ ) {
			formatex( strCapitalizedFirstLetter, charsmax( strCapitalizedFirstLetter ), g_strWeapons[ g_iPluginSettings[ iLoop ] ][ 7 ] );
			CapitalizeFirstLetter( strCapitalizedFirstLetter );
			
			menu_additem( menuDuelWeaponMenu, strCapitalizedFirstLetter );
		}
		
		menu_setprop( menuDuelWeaponMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuDuelWeaponMenu );
}

public Handle_DuelWeaponMenu( iPlayerID, iMenu, iKey ) {
	if( g_bLRInProgress || g_iLRLastTerrorist != iPlayerID ) {
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		ShowLastRequestMenu( iPlayerID, LR_DUEL % PAGE_OPTIONS );
		
		return;
	}
	
	g_iLRChosenDuel = iKey;
	ShowLRPlayerMenu( iPlayerID );
}

ShowS4SWeaponMenu( iPlayerID ) {
	if( g_iLRLastTerrorist != iPlayerID ) {
		return;
	}
	
	static menuS4SWeaponMenu;
	
	if( !menuS4SWeaponMenu ) {
		new strMenuTitle[ ] = "\yS4S Weapon Menu:^n";
		
		menuS4SWeaponMenu = menu_create( strMenuTitle, "Handle_S4SWeaponMenu" );
		
		new strCapitalizedFirstLetter[ 32 ];
		
		for( new iLoop = S4S_WEAPON_1_STR; iLoop <= S4S_WEAPON_6_STR; iLoop++ ) {
			formatex( strCapitalizedFirstLetter, charsmax( strCapitalizedFirstLetter ), g_strWeapons[ g_iPluginSettings[ iLoop ] ][ 7 ] );
			CapitalizeFirstLetter( strCapitalizedFirstLetter );
			
			menu_additem( menuS4SWeaponMenu, strCapitalizedFirstLetter );
		}
		
		menu_setprop( menuS4SWeaponMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuS4SWeaponMenu );
}

public Handle_S4SWeaponMenu( iPlayerID, iMenu, iKey ) {
	if( g_bLRInProgress || g_iLRLastTerrorist != iPlayerID ) {
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		ShowLastRequestMenu( iPlayerID, LR_S4S % PAGE_OPTIONS );
		
		return;
	}
	
	g_iLRChosenS4S = iKey;
	ShowLRPlayerMenu( iPlayerID );
}

ShowLRPlayerMenu( iPlayerID ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	if( !iNum ) {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 There are no alive ^4Guards^1 for you to choose from.", g_strPluginPrefix );
		
		return;
	}
	
	static strMenuTitle[ ] = "\yChoose A Player:^n";
	
	new menuLRPlayerMenu = menu_create( strMenuTitle, "Handle_LRPlayerMenu" );
	
	new strPlayerName[ 32 ], strPlayerID[ 8 ], iTempID;
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		get_user_name( iTempID, strPlayerName, charsmax( strPlayerName ) );
		num_to_str( get_user_userid( iTempID ), strPlayerID, charsmax( strPlayerID ) );
		
		menu_additem( menuLRPlayerMenu, strPlayerName, strPlayerID );
	}
	
	menu_setprop( menuLRPlayerMenu, MPROP_NUMBER_COLOR, "\y" );
	
	menu_display( iPlayerID, menuLRPlayerMenu );
}

public Handle_LRPlayerMenu( iPlayerID, iMenu, iKey ) {
	if( g_bLRInProgress || g_iLRLastTerrorist != iPlayerID ) {
		menu_destroy( iMenu );
		
		return;
	}
	
	if( iKey == MENU_EXIT ) {
		menu_destroy( iMenu );
		ShowLastRequestMenu( iPlayerID );
		
		return;
	}
	
	new strPlayerID[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strPlayerID, charsmax( strPlayerID ), _, _, iCallBack );
	
	new iTarget = find_player( "k", str_to_num( strPlayerID ) );
	
	if( !is_user( iTarget ) ) {
		menu_destroy( iMenu );
		ShowLastRequestMenu( iPlayerID );
		
		return;
	}
	
	if( !CheckBit( g_bitIsAlive, iTarget ) ) {
		client_print_color( iTarget, print_team_blue, "^4%s^1 The ^3Guard^1 you chose is no longer alive, please choose another.", g_strPluginPrefix );
		
		return;
	}
	
	if( ( g_iLRCurrent == LR_SHOWDOWN || g_iLRCurrent == LR_HOTPOTATO ) && !CheckProximity( iPlayerID, iTarget ) ) {
		client_print_color( iPlayerID, iTarget, "^4%s^3 Guard^1 is too far! Please get closer and try again.", g_strPluginPrefix );
		
		menu_destroy( iMenu );
		ShowLRPlayerMenu( iPlayerID );
		
		return;
	}
	
	g_iLastRequestPlayers[ PLAYER_GUARD ] = iTarget;
	g_iLastRequestPlayers[ PLAYER_PRISONER ] = iPlayerID;
	
	StartLastRequest( );
	
	menu_destroy( iMenu );
}

ShowCommanderMenu( iPlayerID, iPage = 0 ) {
	static menuCommanderMenu;
	
	if( !menuCommanderMenu ) {
		new strMenuTitle[ ] = "\yChoose An Option:^n";
		
		menuCommanderMenu = menu_create( strMenuTitle, "Handle_CommanderMenu" );
		
		new strCommanderMenuOptions[ ][ ] = {
			"Open Cells",
			"Split Prisoners in two teams \y[\r# Prisoners pair\y]",
			"Start a 10 second timer \y[\rtick tock\y]",
			"Open the G Book \y[\rNOOB CT? not anymore\y]",
			"Pick a random Prisoner \y[\rwe'll pick for you\y]",
			"Give a Prisoner an empty Deagle",
			"Give/Remove a Prisoner's mic access \y[\rone round\y]",
			"Heal all Prisoners \y[\r100 HP\y]",
			"Glow a Prisoner \y[\rtons of colors\y]",
			"Ask a random math question \y[\rwe already have the answers\y]",
			"Enable/Disable Free For All \y[\rlet them kill each others\y]",
			"Enable/Disable Spray Meter \y[\rhow high can you spray?\y]"
		};
		
		new strNumber[ 8 ];
		
		for( new iLoop = 0; iLoop < sizeof( strCommanderMenuOptions ); iLoop++ ) {
			num_to_str( iLoop, strNumber, charsmax( strNumber ) );
			
			menu_additem( menuCommanderMenu, strCommanderMenuOptions[ iLoop ], strNumber );
		}
		
		menu_setprop( menuCommanderMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuCommanderMenu, iPage );
}

public Handle_CommanderMenu( iPlayerID, iMenu, iKey ) {
	if( g_iCommanderGuard != iPlayerID || iKey == MENU_EXIT ) {
		return;
	}
	
	if( cs_get_user_team( iPlayerID ) != CS_TEAM_CT ) {
		g_iCommanderGuard = -1;
		
		return;
	}
	
	new strOption[ 32 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iAccess, iKey, strOption, charsmax( strOption ), _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	new strCommanderName[ 32 ];
	get_user_name( iPlayerID, strCommanderName, charsmax( strCommanderName ) );
	
	switch( iOption ) {
		case COMMANDER_OPEN: {
			PushButton( );
			
			client_print_color( 0, print_team_blue, "^4%s^3 %s^1 has remotely opened the cells.", g_strPluginPrefix, strCommanderName );
			
			ShowCommanderMenu( iPlayerID, COMMANDER_OPEN % PAGE_OPTIONS );
		}
		
		case COMMANDER_SPLIT: {
			new iAvailablePrisoners = GetTeamPlayersNumber( "T" ) - GetTeamPlayersNumber( "F" );
			
			if( iAvailablePrisoners % 2 ) {
				client_print_color( iPlayerID, print_team_red, "^4%s^1 There must be an even number of ^3Prisoners^1 to use this command.", g_strPluginPrefix );
				
				ShowCommanderMenu( iPlayerID, COMMANDER_SPLIT % PAGE_OPTIONS );
			} else {
				new iPlayers[ 32 ], iNum, iTempID;
				get_players( iPlayers, iNum, "ae", "TERRORIST" );
				
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
				
				client_print_color( 0, print_team_blue, "^4%s^3 %s^1 has split the ^4Prisoners^1 into two teams.", g_strPluginPrefix, strCommanderName );
			}
			
			ShowCommanderMenu( iPlayerID, COMMANDER_SPLIT % PAGE_OPTIONS );
		}
		
		case COMMANDER_TIMER: {
			if( task_exists( TASK_COUNTDOWN_COMMANDER ) ) {
				client_print_color( iPlayerID, print_team_red, "^4%s^1 There is already a ^3countdown^1 in progress.", g_strPluginPrefix );
			} else {
				g_iTimeLeft = 11;
				
				Task_Countdown_Commander( );
				set_task( 1.0, "Task_Countdown_Commander", TASK_COUNTDOWN_COMMANDER, _, _, "a", g_iTimeLeft );
			}
			
			ShowCommanderMenu( iPlayerID, COMMANDER_TIMER % PAGE_OPTIONS );
		}
		
		case COMMANDER_RANDOM_PRISONER: {
			new iPlayers[ 32 ], iNum;
			get_players( iPlayers, iNum, "ae", "TERRORIST" );
			
			new iRandomPlayer;
			
			do {
				iRandomPlayer = random( iNum );
			} while( CheckBit( g_bitHasFreeDay, iPlayers[ iRandomPlayer ] ) );
			
			iRandomPlayer = iPlayers[ iRandomPlayer ];
			
			new strPlayerName[ 32 ];
			get_user_name( iRandomPlayer, strPlayerName, charsmax( strPlayerName ) );
			
			set_user_rendering( iRandomPlayer, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
			set_task( 5.0, "Task_UnglowRandomPlayer", TASK_UNGLOW_RANDOMPLAYER + iRandomPlayer );
			
			client_print_color( 0, print_team_blue, "^4%s^3 %s^1 requested a random ^3Prisoners^1 and got ^4%s^1.", g_strPluginPrefix, strCommanderName, strPlayerName );
			
			ShowCommanderMenu( iPlayerID, COMMANDER_RANDOM_PRISONER % PAGE_OPTIONS );
		}
		
		case COMMANDER_MIC, COMMANDER_EMPTY_DEAGLE: {
			g_iCommanderMenuOption = iKey;
			
			ShowCommanderPlayerMenu( iPlayerID );
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
			
			client_print_color( 0, print_team_blue, "^4%s^3 %s^1 healed all ^4Prisoners^1 to full health.", g_strPluginPrefix, strCommanderName );
			
			ShowCommanderMenu( iPlayerID, COMMANDER_HEAL % PAGE_OPTIONS );
		}
		
		case COMMANDER_GLOW: {
			ShowCommanderGlowMenu( iPlayerID );
		}
		
		case COMMANDER_MATH: {
			new iNumbers[ 3 ];
			iNumbers[ 0 ] = random( 10 );
			iNumbers[ 1 ] = random( 10 );
			iNumbers[ 2 ] = random( 10 );
			
			new iOperations[ 2 ];
			iOperations[ 0 ] = random_num( 0, 1 );
			iOperations[ 1 ] = random_num( 0, 1 );
			
			if( iOperations[ 0 ] ) {
				if( iOperations[ 1 ] ) {
					g_iMathQuestionResult = iNumbers[ 0 ] + iNumbers[ 1 ] + iNumbers[ 2 ];
				} else {
					g_iMathQuestionResult = iNumbers[ 0 ] + iNumbers[ 1 ] - iNumbers[ 2 ];
				}
			} else {
				if( iOperations[ 1 ] ) {
					g_iMathQuestionResult = iNumbers[ 0 ] - iNumbers[ 1 ] + iNumbers[ 2 ];
				} else {
					g_iMathQuestionResult = iNumbers[ 0 ] - iNumbers[ 1 ] - iNumbers[ 2 ];
				}
			}
			
			new strEquation[ 32 ];
			formatex( strEquation, charsmax( strEquation ), "Equation: %i %s %i %s %i = ?", iNumbers[ 0 ], iOperations[ 0 ] ? "+" : "-", iNumbers[ 1 ], iOperations[ 1 ] ? "+" : "-", iNumbers[ 2 ] );
			client_print_color( iPlayerID, print_team_default, "^4%s^1 The result to the equation is ^4%i^1.", g_strPluginPrefix, g_iMathQuestionResult );
			
			g_iTimeLeft = TIME_COUNTDOWN_COMMANDER;
			
			Task_Countdown_CommanderMath( strEquation, TASK_COUNTDOWN_COMMANDERMATH );
			set_task( 1.0, "Task_Countdown_Commander", TASK_COUNTDOWN_COMMANDERMATH, strEquation, charsmax( strEquation ), "a", g_iTimeLeft );
			
			ShowCommanderMenu( iPlayerID, COMMANDER_MATH % PAGE_OPTIONS );
		}
		
		case COMMANDER_FFA: {
			if( g_bFFA ) {
				SetFreeForAll( 0 );
			} else {
				SetFreeForAll( 1 );
			}
			
			client_print_color( 0, print_team_blue, "^4%s^3 %s^1 has %s ^4Free For All^1.", g_strPluginPrefix, strCommanderName, g_bFFA ? "disabled" : "enabled" );
			
			ShowCommanderMenu( iPlayerID, COMMANDER_FFA % PAGE_OPTIONS );
		}
		
		case COMMANDER_SPRAY: {
			if( !g_iSprayChecker ) {
				client_print_color( iPlayerID, print_team_red, "^4%s^1 This option is ^3disabled^1 on this server.", g_strPluginPrefix );
			} else {
				if( g_bAllowSprayMeter ) {
					g_bAllowSprayMeter = false;
				} else {
					g_bAllowSprayMeter = true;
				}
				
				client_print_color( 0, print_team_blue, "^4%s^3 %s^1 has %s ^4Spray Meter^1.", g_strPluginPrefix, strCommanderName, g_bAllowSprayMeter ? "disabled" : "enabled" );
			}
			
			ShowCommanderMenu( iPlayerID, COMMANDER_SPRAY % PAGE_OPTIONS );
		}
	}
}

ShowCommanderGlowMenu( iPlayerID ) {
	static menuCommanderGlowMenu;
	
	if( !menuCommanderGlowMenu ) {
		new strMenuTitle[ ] = "\yCommander Glow Menu:^n";
		
		menuCommanderGlowMenu = menu_create( strMenuTitle, "Handle_CommanderGlowMenu" );
		
		new strGlowColors[ ][ ] = {
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
		
		new strNumber[ 8 ];
		
		for( new iLoop = 0; iLoop < sizeof( strGlowColors ); iLoop++ ) {
			num_to_str( iLoop, strNumber, charsmax( strNumber ) );
			
			menu_additem( menuCommanderGlowMenu, strGlowColors[ iLoop ], strNumber );
		}
		
		menu_setprop( menuCommanderGlowMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuCommanderGlowMenu );
}

public Handle_CommanderGlowMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		ShowCommanderMenu( iPlayerID, COMMANDER_GLOW % PAGE_OPTIONS );
		
		return;
	}
	
	if( g_iCommander != iPlayerID ) {
		return;
	}
	
	new strOption[ 32 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, charsmax( strOption ), _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	static iColorArray[ ][ ] = {
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
	
	g_iCommanderGlowColor[ 0 ] = iColorArray[ iOption ][ 0 ];
	g_iCommanderGlowColor[ 1 ] = iColorArray[ iOption ][ 1 ];
	g_iCommanderGlowColor[ 2 ] = iColorArray[ iOption ][ 2 ];
	
	g_iCommanderMenuOption = COMMANDER_GLOW;
	ShowCommanderPlayerMenu( iPlayerID );
}

ShowCommanderPlayerMenu( iPlayerID ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	if( !iNum ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 There are no alive ^3Prisoners^1 to select from.", g_strPluginPrefix );
		ShowCommanderMenu( iPlayerID, g_iCommanderMenuOption % PAGE_OPTIONS );
		
		return;
	}
	
	static strMenuTitle[ ] = "\yChoose A Player:^n";
	
	new menuCommanderPlayerMenu = menu_create( strMenuTitle, "Handle_CommanderPlayerMenu" );
	
	menu_additem( menuCommanderPlayerMenu, "\rAll Players", 	"-2" );
	menu_additem( menuCommanderPlayerMenu, "\rPick Player by AIM", 	"-1" );
	
	new strFormat[ 64 ], strPlayerUserID[ 8 ];
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		if( CheckBit( g_bitHasFreeDay, iTempID ) ) {
			continue;
		}
		
		num_to_str( get_user_userid( iTempID ), strPlayerUserID, charsmax( strPlayerUserID ) );
		get_user_name( iTempID, strFormat, charsmax( strFormat ) );
		
		if( g_iCommanderMenuOption == COMMANDER_MIC ) {
			if( CheckBit( g_bitHasMicPower, iTempID ) ) {
				format( strFormat, charsmax( strFormat ), "\rREMOVE: \w%s", strFormat );
			} else {
				format( strFormat, charsmax( strFormat ), "\rGIVE: \w%s", strFormat );
			}
		}
		
		menu_additem( menuCommanderPlayerMenu, strFormat, strPlayerUserID );
	}
	
	menu_setprop( menuCommanderPlayerMenu, MPROP_NUMBER_COLOR, "\y" );
	
	menu_display( iPlayerID, menuCommanderPlayerMenu );
}

public Handle_CommanderPlayerMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		ShowCommanderMenu( iPlayerID, g_iCommanderMenuOption % PAGE_OPTIONS );
		menu_destroy( iMenu );
		
		return;
	}
	
	if( g_iCommander != iPlayerID ) {
		menu_destroy( iMenu );
		
		return;
	}
	
	new strPlayerUserID[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strPlayerUserID, charsmax( strPlayerUserID ), _, _, iCallBack );
	
	new iPlayerUserID = str_to_num( strPlayerUserID );
	
	new iTarget;
	
	switch( iPlayerUserID ) {
		case -2: {
			// do nothing :D
		}
		
		case -1: {
			new iBody;
			get_user_aiming( iPlayerID, iTarget, iBody );
			
			if( !is_user( iTarget ) || !CheckBit( g_bitIsAlive, iTarget ) || CheckBit( g_bitHasFreeDay, iTarget ) ) {
				menu_destroy( iMenu );
				ShowCommanderPlayerMenu( iPlayerID );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 You are not aiming at a ^4Prisoner^1.", g_strPluginPrefix );
				
				return;
			}
		}
		
		default: {
			iTarget = find_player( "k", iPlayerUserID );
			
			if( !is_user( iTarget ) || !CheckBit( g_bitIsAlive, iTarget ) || CheckBit( g_bitHasFreeDay, iTarget ) ) {
				menu_destroy( iMenu );
				ShowCommanderPlayerMenu( iPlayerID );
				
				client_print_color( iPlayerID, print_team_red, "^4%s^1 It seems that ^4Prisoner^1 is not available anymore.", g_strPluginPrefix );
				
				return;
			}
		}
	}
	
	new strCommanderName[ 32 ];
	get_user_name( iPlayerID, strCommanderName, charsmax( strCommanderName ) );
	
	switch( g_iCommanderMenuOption ) {
		case COMMANDER_MIC: {
			if( iPlayerUserID == -2 ) {
				new iPlayers[ 32 ], iNum, iTempID;
				get_players( iPlayers, iNum, "ae", "TERRORIST" );
				
				for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
					iTempID = iPlayers[ iLoop ];
					
					if( CheckBit( g_bitHasMicPower, iTempID ) ) {
						ClearBit( g_bitHasMicPower, iTempID );
					}
				}
				
				client_print_color( 0, print_team_blue, "^4%s^3 %s^1 removed everybody's microphone access.", g_strPluginPrefix, strCommanderName );
			} else {
				new strPlayerName[ 32 ];
				get_user_name( iTarget, strPlayerName, charsmax( strPlayerName ) );
				
				if( CheckBit( g_bitHasMicPower, iTarget ) ) {
					ClearBit( g_bitHasMicPower, iTarget );
					
					client_print_color( 0, print_team_blue, "^4%s^3 %s^1 removed ^4%s^1's microphone access.", g_strPluginPrefix, strCommanderName, strPlayerName );
				} else {
					SetBit( g_bitHasMicPower, iTarget );
					
					client_print_color( 0, print_team_blue, "^4%s^3 %s^1 gave ^4%s^1 microphone access.", g_strPluginPrefix, strCommanderName, strPlayerName );
				}
			}
		}
		
		case COMMANDER_EMPTY_DEAGLE: {
			if( iPlayerUserID == -2 ) {
				new iPlayers[ 32 ], iNum, iTempID;
				get_players( iPlayers, iNum, "ae", "TERRORIST" );
				
				for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
					iTempID = iPlayers[ iLoop ];
					
					if( !CheckBit( g_bitHasFreeDay, iTempID ) ) {
						HamStripUserWeapon( iTempID, CSW_DEAGLE, 0, true );
						
						cs_set_weapon_ammo( give_item( iTempID, "weapon_deagle" ), 0 );
						cs_set_user_bpammo( iTempID, CSW_DEAGLE,  0 );
					}
				}
			} else {
				HamStripUserWeapon( iTarget, CSW_DEAGLE, 0, true );
				
				cs_set_weapon_ammo( give_item( iTarget, "weapon_deagle" ), 0 );
				cs_set_user_bpammo( iTarget, CSW_DEAGLE, 0 );
				
				new strPlayerName[ 32 ];
				get_user_name( iTarget, strPlayerName, charsmax( strPlayerName ) );
				
				client_print_color( 0, print_team_red, "^4%s^4 %s^1 gave ^4%s^1 an empty deagle.", g_strPluginPrefix, strCommanderName, strPlayerName );
			}
		}
		
		case COMMANDER_GLOW: {
			if( iPlayerUserID == -2 ) {
				new iPlayers[ 32 ], iNum, iTempID;
				get_players( iPlayers, iNum, "ae", "TERRORIST" );
				
				for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
					iTempID = iPlayers[ iLoop ];
					
					if( !CheckBit( g_bitHasFreeDay, iTempID ) ) {
						set_user_rendering( iTempID, kRenderFxGlowShell, g_iCommanderGlowColor[ 0 ], g_iCommanderGlowColor[ 1 ], g_iCommanderGlowColor[ 2 ], kRenderNormal, 5 );
					}
				}
				
				client_print_color( 0, print_team_blue, "^4%s^3 %s^1 just glowed all ^4Prisoners^1.", g_strPluginPrefix, strCommanderName );
			} else {
				set_user_rendering( iTarget, kRenderFxGlowShell, g_iCommanderGlowColor[ 0 ], g_iCommanderGlowColor[ 1 ], g_iCommanderGlowColor[ 2 ], kRenderNormal, 5 );
				
				new strPlayerName[ 32 ];
				get_user_name( iTarget, strPlayerName, charsmax( strPlayerName ) );
				
				client_print_color( 0, print_team_blue, "^4%s^3 %s^1 glowed ^4%s^1.", g_strPluginPrefix, strCommanderName, strPlayerName );
			}
		}
	}
	
	menu_destroy( iMenu );
	ShowCommanderPlayerMenu( iPlayerID );
}

public ShowMainMenu( iPlayerID ) {
	static menuMainMenu;
	
	if( !menuMainMenu ) {
		new strMenuTitle[ ] = "\yJailBreak Main Menu:^n";
		
		menuMainMenu = menu_create( strMenuTitle, "Handle_MainMenu" );
		
		new strOptionsMainMenu[ ] = {
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
		
		new strNumber[ 8 ];
		
		for( new iLoop = 0; iLoop < sizeof( strOptionsMainMenu ); iLoop++ ) {
			num_to_str( iLoop, strNumber, charsmax( strNumber ) );
			
			menu_additem( menuMainMenu, strOptionsMainMenu[ iLoop ], strNumber );
		}
		
		menu_setprop( menuMainMenu, MPROP_NUMBER_COLOR, "\y" );
	}
	
	menu_display( iPlayerID, menuMainMenu );
}

public Handle_MainMenu( iPlayerID, iMenu, iKey ) {
	if( iKey == MENU_EXIT ) {
		return;
	}
	
	new strOption[ 8 ], iAccess, iCallBack;
	menu_item_getinfo( iMenu, iKey, iAccess, strOption, charsmax( strOption ), _, _, iCallBack );
	
	new iOption = str_to_num( strOption );
	
	switch( iOption ) {
		case MAIN_MENU_TEAM: {
			new iPlayers[ 32 ], iNumCT, iNumT;
			get_players( iPlayers, iNumCT, "e", "CT" );
			get_players( iPlayers, iNumT, "e", "TERRORIST" );
			
			switch( cs_get_user_team( iPlayerID ) ) {
				case CS_TEAM_T: {
					if( iNumCT && --iNumT / ++iNumCT < g_iMainMenuRatio ) {
						client_print_color( iPlayerID, print_team_red, "^4%s^1 You ^4cannot^1 be a ^4Guard^1 because that will break the players ratio.", g_strPluginPrefix );
					} else {
						if( g_iMainMenuTime && !is_user_admin( iPlayerID ) && g_iPlayerTime[ iPlayerID ] < g_iMainMenuTime ) {
							client_print_color( iPlayerID, print_team_blue, "^4%s^1 You need ^4%d^1 more ^4minute(s)^1 to be able to join the ^3Guards^1.", g_strPluginPrefix, g_iMainMenuTime - g_iPlayerTime[ iPlayerID ] );
						} else {
							if( CheckBit( g_bitIsCTBanned, iPlayerID ) ) {
								client_print_color( iPlayerID, print_team_blue, "^4%s^1 You have been banned from the ^3Guard^1 team.", g_strPluginPrefix );
							} else {
								client_print_color( iPlayerID, print_team_blue, "^4%s^1 By playing as a ^3Guard^1, you automatically agree to all the terms and conditions.", g_strPluginPrefix );
								
								cs_set_user_team( iPlayerID, CS_TEAM_CT );
								
								if( CheckBit( g_bitIsAlive, iPlayerID ) ) {
									user_kill( iPlayerID );
								}
							}
						}
					}
				}
				
				case CS_TEAM_CT, CS_TEAM_SPECTATOR, CS_TEAM_UNASSIGNED: {
					cs_set_user_team( iPlayerID, CS_TEAM_T );
					
					if( CheckBit( g_bitIsAlive, iPlayerID ) ) {
						user_kill( iPlayerID );
					}
				}
			}
		}
		
		case MAIN_MENU_SHOP:			ClCmd_OpenShop( iPlayerID );
		case MAIN_MENU_LR:			ClCmd_LastRequest( iPlayerID );
		case MAIN_MENU_FUN:			ClCmd_FunMenu( iPlayerID );
		case MAIN_MENU_FREEDAY:			ClCmd_ShowFreeDayMenu( iPlayerID );
		case MAIN_MENU_COMMANDER:		ClCmd_Commander( iPlayerID );
		case MAIN_MENU_COMMANDER_MENU:		ClCmd_CommanderMenu( iPlayerID );
		case MAIN_MENU_DAY:			ClCmd_ForceDay( iPlayerID );
		case MAIN_MENU_VIP:			ClCmd_ShowVIPMenu( iPlayerID );
		case MAIN_MENU_GUNS:			ClCmd_ShowGunsMenu( iPlayerID );
		case MAIN_MENU_RULES:			ClCmd_ShowRules( iPlayerID );
		case MAIN_MENU_CREDITS:			ClCmd_ShowCredits( iPlayerID );
	}
}

ShowShopMenu( iPlayerID, iPage = 0 ) {
	client_print_color( iPlayerID, print_team_red, "^4%s^1 The shop is currently ^3under construction^1.", g_strPluginPrefix );

	// static menuShopMenu;
	
	// if( !menuShopMenu ) {
		// new strMenuTitle[ ] = "\yJailBreak Shop Menu:^n";
		
		// menuShopMenu = menu_create( strMenuTitle, "Handle_ShopMenu" );
		
		// new strOptionsShopMenu[ ][ ] = {
			// "\wHE Grenade \y[\rexplosive\y]",
			// "\wFLASH Grenade \y[\rblinding shit\y]",
			// "\wSMOKE Grenade \y[\rfoggy atmosphere\y]",
			// "\wHealth Kit \y[\rhere take 50 HP\y]",
			// "\wAdvanced Health Kit \y[\rhere take 100 HP\y]",
			// "\wArmor Jacket \y[\rhere take 100 AP\y]",
			// "\wPrison Knife \y[\rprison made knife\y]",
			// "\wOne Bullet Deagle \y[\rget that headshot\y]",
			// "\wOne Bullet Scout \y[\rget that headshot\y]",
			// "\wAssassin Steps \y[\rsound reducing choose\y]"
		// };
		
		// new strNumber[ 8 ], strFormatex[ 256 ];
		
		// for( new iLoop = 0; iLoop < sizeof( strOptionsShopMenu ); iLoop++ ) {
			// num_to_str( iLoop, strNumber, charsmax( strNumber ) );
			
			// formatex( strFormatex, charsmax( strFormatex ), "\y%i points: %s", g_iPluginSettings[ SHOP_GRENADE_HE + iLoop ], strOptionsShopMenu[ iLoop ] );
			// menu_additem( menuShopMenu, strFormatex, strNumber );
		// }
		
		// menu_setprop( menuShopMenu, MPROP_NUMBER_COLOR, "\y" );
	// }
	
	// menu_display( iPlayerID, menuShopMenu, iPage );
}

// public Handle_ShopMenu( iPlayerID, iMenu, iKey ) {
	// if( iKey == MENU_EXIT || !CheckBit( g_bitIsAlive, iPlayerID ) || cs_get_user_team( iPlayerID ) != CS_TEAM_T || !g_bAllowShop ) {
		// return;
	// }
	
	// new strOption[ 8 ], iAccess, iCallBack;
	// menu_item_getinfo( iMenu, iKey, iAccess, strOption, charsmax( strOption ), _, _, iCallBack );
	
	// new iOption = str_to_num( strOption );
	// new iPoints = g_iPluginSettings[ SHOP_GRENADE_HE + iOption ];
	
	// if( g_iPlayerPoints[ iPlayerID ] < iPoints ) {
		// client_print_color( iPlayerID, print_team_red, "^4%s^1 You do ^3not^1 have ^3enough points^1 to purchase this item.", g_strPluginPrefix );
	// } else if( g_iShopItemCount[ iOption ] >= g_iPluginSettings[ ITEMS_GRENADE_HE + iOption ] ) {
		// client_print_color( iPlayerID, print_team_red, "^4%s^1 The item you are requesting is ^3out of stock^1.", g_strPluginPrefix );
	// } else {
		// g_iPlayerPoints[ iPlayerID ] -= g_iPluginSettings[ SHOP_GRENADE_HE + iOption ];
	// }
// }

/* Days */
StartDay( ) {
	switch( g_iDayCurrent ) {
		case DAY_FREE: {
			StartFreeVote( );
			return;
		}
		case DAY_CAGE:		StartCageDay( );
		case DAY_NIGHTCRAWLER: {
			StartNightCrawlerVote( );
			return;
		}
		case DAY_ZOMBIE: {
			StartZombieVote( );
			return;
		}
		case DAY_RIOT:		StartRiotDay( );
		case DAY_PRESIDENT:	StartPresidentDay( );
		case DAY_USP_NINJA:	StartUSPNinjaDay( );
		case DAY_NADEWAR:	StartNadeWar( );
		case DAY_HULK:		StartHulkDay( );
		case DAY_SPACE:		StartSpaceDay( );
		case DAY_COWBOY:	StartCowboyDay( );
		case DAY_SHARK: {
			StartSharkVote( );
			return;
		}
		case DAY_LMS:		StartLastManStandingDay( );
		case DAY_SAMURAI:	StartSamuraiDay( );
		case DAY_KNIFE:		StartKnifeDay( );
		case DAY_JUDGEMENT:	StartJudgementDay( );
		case DAY_HNS:		StartHideNSeekDay( );
		case DAY_MARIO:		StartMarioDay( );
		case DAY_CUSTOM:	StartCustomDay( );
	}
	
	ShowDHUDMessage( g_strObjectivesDayVote[ g_iDayCurrent ] );
	
	SetDayHamHooks( g_iDayCurrent, true );
	
	g_bDayInProgress = true;
}

EndDay( ) {
	ComputeDayRestrictions( );
	
	switch( g_iDayCurrent ) {
		case DAY_FREE:		EndFreeDay( );
		case DAY_CAGE:		EndCageDay( );
		case DAY_NIGHTCRAWLER:	EndNightCrawlerDay( );
		case DAY_ZOMBIE:	EndZombieDay( );
		case DAY_RIOT:		EndRiotDay( );
		case DAY_PRESIDENT:	EndPresidentDay( );
		case DAY_USP_NINJA:	EndUSPNinjaDay( );
		case DAY_NADEWAR:	EndNadeWarDay( );
		case DAY_HULK:		EndHulkDay( );
		case DAY_SPACE:		EndSpaceDay( );
		case DAY_COWBOY:	EndCowboyDay( );
		case DAY_SHARK:		EndSharkDay( );
		case DAY_LMS:		EndLastManStandingDay( );
		case DAY_SAMURAI:	EndSamuraiDay( );
		case DAY_KNIFE:		EndKnifeDay( );
		case DAY_JUDGEMENT:	EndJudgementDay( );
		case DAY_HNS:		EndHideNSeekDay( );
		case DAY_MARIO:		EndMarioDay( );
		case DAY_CUSTOM:	EndCustomDay( );
	}
	
	RemoveAllTasks( );
	ResetVotes( );
	
	show_menu( 0, 0, "^n", 1 );
	
	g_bDayInProgress = false;
	
	SetDayHamHooks( g_iDayCurrent, false );
}

StartFreeDay( ) {
	ShowWeaponMenu( 0, "C" );
	
	if( g_iTypeFree == TYPE_UNRESTRICTED ) {
		ShowDHUDMessage( g_strObjectivesDayVote[ DAY_FREE ] );
	} else {
		ShowDHUDMessage( g_strObjectivesReverseDayVote[ DAY_FREE ] );
	}
	
	g_bDayInProgress = true;
}

EndFreeDay( ) {
	g_bitHasUnAmmo = 0;
}

StartCageDay( ) {
	ShowWeaponMenu( 0, "C" );
	
	set_task( TIME_SHOP, "Task_DisableShop", TASK_DISABLESHOP );
}

EndCageDay( ) {
	g_bitHasUnAmmo = 0;
}

StartNightCrawlerDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	switch( g_iTypeNightCrawler ) {
		case TYPE_REGULAR: {
			new iHealthCT = GetTeamPlayersNumber( "T" ) * g_iPluginSettings[ NC_REG_HEALTH_GUARD_REL ];
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				StripPlayerWeapons( iTempID );
				
				set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
				set_user_footsteps( iTempID, 1 );
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_CT: {
						set_user_health( iTempID, iHealthCT );
						cs_set_user_armor( iTempID, g_iPluginSettings[ NC_REG_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
					}
					
					case CS_TEAM_T: {
						set_user_health( iTempID, g_iPluginSettings[ NC_REG_HEALTH_PRISONER ] );
						cs_set_user_armor( iTempID, g_iPluginSettings[ NC_REG_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
						
						ShowWeaponMenu( iTempID );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesDayVote[ DAY_NIGHTCRAWLER ] );
			OpenCells( );
		}
		
		case TYPE_REVERSE: {
			new iHealthCT = GetTeamPlayersNumber( "T" ) * g_iPluginSettings[ NC_REV_HEALTH_GUARD_REL ];
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				StripPlayerWeapons( iTempID );
				
				set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
				set_user_footsteps( iTempID, 1 );
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_CT: {
						set_user_health( iTempID, iHealthCT );
						cs_set_user_armor( iTempID, g_iPluginSettings[ NC_REV_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
						
						ShowWeaponMenu( iTempID );
					}
					
					case CS_TEAM_T: {
						set_user_health( iTempID, g_iPluginSettings[ NC_REV_HEALTH_PRISONER ] );
						cs_set_user_armor( iTempID, g_iPluginSettings[ NC_REV_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesReverseDayVote[ DAY_NIGHTCRAWLER ] );
		}
	}
	
	g_bDayInProgress = true;
	SetDayHamHooks( DAY_NIGHTCRAWLER, true );
	set_lights( "b" );
	
	g_iTimeLeft = g_iPluginSettings[ NC_COUNTDOWN_TIME ];
	set_task( 1.0, "Task_Countdown_NC", TASK_COUNTDOWN_NC, _, _, "a", g_iTimeLeft );
}

EndNightCrawlerDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		set_user_rendering( iTempID );
		set_user_footsteps( iTempID, 0 );
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
	}
	
	g_bitHasUnAmmo = 0;
	set_lights( "#OFF" );
}

StartZombieDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	switch( g_iTypeZombie ) {
		case TYPE_REGULAR: {
			new iHealthT = GetTeamPlayersNumber( "C" ) * g_iPluginSettings[ ZOMBIE_REG_HEALTH_PRISONER_REL ];
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				StripPlayerWeapons( iTempID );
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_CT: {
						set_user_health( iTempID, g_iPluginSettings[ ZOMBIE_REG_HEALTH_GUARD ] );
						cs_set_user_armor( iTempID, g_iPluginSettings[ ZOMBIE_REG_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
						
						ShowWeaponMenu( iTempID );
					}
					
					case CS_TEAM_T: {
						set_user_health( iTempID, iHealthT );
						cs_set_user_armor( iTempID, g_iPluginSettings[ ZOMBIE_REG_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
						
						set_user_rendering( iTempID, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, GLOW_THIKNESS );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesDayVote[ DAY_ZOMBIE ] );
		}
		
		case TYPE_REVERSE: {
			new iHealthCT = GetTeamPlayersNumber( "T" ) * g_iPluginSettings[ ZOMBIE_REV_HEALTH_GUARD_REL ];
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				StripPlayerWeapons( iTempID );
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_CT: {
						set_user_health( iTempID, iHealthCT );
						cs_set_user_armor( iTempID, g_iPluginSettings[ ZOMBIE_REV_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
						
						set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, GLOW_THIKNESS );
					}
					
					case CS_TEAM_T: {
						set_user_health( iTempID, g_iPluginSettings[ ZOMBIE_REV_HEALTH_PRISONER ] );
						cs_set_user_armor( iTempID, g_iPluginSettings[ ZOMBIE_REV_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
						
						ShowWeaponMenu( iTempID );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesReverseDayVote[ DAY_ZOMBIE ] );
			OpenCells( );
		}
	}
	
	g_bDayInProgress = true;
	SetDayHamHooks( DAY_ZOMBIE, true );
	set_lights( "b" );
	
	PlaySound( 0, SOUND_ZOMBIE );
}

EndZombieDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		set_user_rendering( iTempID );
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
	}
	
	g_bitHasUnAmmo = 0;
	set_lights( "#OFF" );
}

StartRiotDay( ) {
	ShowWeaponMenu( 0, "C" );
	
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	new iRandomPlayer = iPlayers[ random( iNum ) ];
	
	GivePlayerWeapon( iRandomPlayer, ":P", PRIMARY_AK47, SECONDARY_DEAGLE, true, false );
	
	client_print_color( iRandomPlayer, print_team_blue, "^4%s^1 You have been chosen to be the silent killer. Kill the ^3Guards^1 if you can.", g_strPluginPrefix );
}

EndRiotDay( ) {
	g_bitHasUnAmmo = 0;
}

StartPresidentDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	g_iPresident = iPlayers[ random( iNum ) ];
	GivePlayerWeapon( g_iPresident, ":P", -1, SECONDARY_USP, true, true );
	
	new iHealthPresident = GetTeamPlayersNumber( "T" ) * g_iPluginSettings[ PRESIDENT_HEALTH_PRESIDENT_REL ];
	set_user_health( g_iPresident, iHealthPresident );
	cs_set_user_armor( g_iPresident, g_iPluginSettings[ PRESIDENT_ARMOR_PRESIDENT ], CS_ARMOR_VESTHELM );
	
	set_user_rendering( g_iPresident, kRenderFxGlowShell, 255, 255, 255, kRenderNormal, GLOW_THIKNESS );
	
	give_item( g_iPresident, "weapon_hegrenade" );
	give_item( g_iPresident, "weapon_flashbang" );
	give_item( g_iPresident, "weapon_flashbang" );
	give_item( g_iPresident, "weapon_smokegrenade" );
	
	new iHealthCT = ( GetTeamPlayersNumber( "T" ) * g_iPluginSettings[ PRESIDENT_HEALTH_GUARD_REL ] ) / GetTeamPlayersNumber( "C" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		if( iTempID != g_iPresident ) {
			ShowWeaponMenu( iTempID );
			
			set_user_health( iTempID, iHealthCT );
			cs_set_user_armor( iTempID, g_iPluginSettings[ PRESIDENT_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
		}
	}
	
	set_task( 30.0, "Task_President_GiveWeapons", TASK_PRESIDENT_GIVEWEAPONS );
}

EndPresidentDay( ) {
	StripPlayerWeapons( 0, "C" );
	g_bitHasUnAmmo = 0;
	
	set_user_rendering( g_iPresident );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
	}
}

StartUSPNinjaDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	new iHealthCT = GetTeamPlayersNumber( "T" ) * g_iPluginSettings[ USP_NINJA_HEALTH_GUARD_REL ];
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		cs_set_weapon_silen( give_item( iTempID, "weapon_usp" ), 1 );
		set_user_footsteps( iTempID, 1 );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				set_user_health( iTempID, iHealthCT );
				cs_set_user_armor( iTempID, g_iPluginSettings[ USP_NINJA_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
				
				cs_set_user_bpammo( iTempID, CSW_USP, g_iPluginSettings[ USP_NINJA_BP_GUARD ] );
			}
			
			case CS_TEAM_T: {
				set_user_health( iTempID, g_iPluginSettings[ USP_NINJA_HEALTH_PRISONER ] );
				cs_set_user_armor( iTempID, g_iPluginSettings[ USP_NINJA_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
				
				cs_set_user_bpammo( iTempID, CSW_USP, g_iPluginSettings[ USP_NINJA_BP_PRISONER ] );
			}
		}
	}
	
	set_pcvar_num( g_cvarGravity, g_iPluginSettings[ USP_NINJA_GRAVITY ] );
}

EndUSPNinjaDay( ) {
	StripPlayerWeapons( 0, "C" );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_footsteps( iTempID, 0 );
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
	}
	
	set_pcvar_num( g_cvarGravity, 800 );
}

StartNadeWar( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		ShowWeaponMenu( iTempID );
		set_user_godmode( iTempID, 1 );
	}
	
	g_bAllowNadeWar = true;
}

EndNadeWarDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		set_user_godmode( iTempID );
	}
	
	if( g_bAllowNadeWar ) {
		g_bAllowNadeWar = false;
	}
}

StartHulkDay( ) {
	new iHealthT = GetTeamPlayersNumber( "C" ) * g_iPluginSettings[ HULK_HEALTH_PRISONER_REL ];
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				GivePlayerWeapon( iTempID, ":P", g_iPluginSettings[ HULK_PRIMARY_GUARD ], g_iPluginSettings[ HULK_SECONDARY_GUARD ], true, false );
				
				set_user_health( iTempID, g_iPluginSettings[ HULK_HEALTH_GUARD ] );
				cs_set_user_armor( iTempID, g_iPluginSettings[ HULK_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
			}
			
			case CS_TEAM_T: {
				set_user_health( iTempID, iHealthT );
				cs_set_user_armor( iTempID, g_iPluginSettings[ HULK_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
			}
		}
	}
	
	set_task( float( g_iPluginSettings[ HULK_INTERVAL_SMASH ] ), "Task_Hulk_Smash", TASK_HULK_SMASH, _, _, "b" );
	PlaySound( 0, SOUND_HULK );
	OpenCells( );
}

EndHulkDay( ) {
	if( task_exists( TASK_HULK_SMASH ) ) {
		remove_task( TASK_HULK_SMASH );
	}
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
	}
}

StartSpaceDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				GivePlayerWeapon( iTempID, ":P", g_iPluginSettings[ SPACE_PRIMARY_GUARD ], g_iPluginSettings[ SPACE_SECONDARY_GUARD ], true, true );
				
				set_user_health( iTempID, g_iPluginSettings[ SPACE_HEALTH_GUARD ] );
				cs_set_user_armor( iTempID, g_iPluginSettings[ SPACE_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
			}
			
			case CS_TEAM_T: {
				GivePlayerWeapon( iTempID, ":P", g_iPluginSettings[ SPACE_PRIMARY_PRISONER ], g_iPluginSettings[ SPACE_SECONDARY_PRISONER ], true, true );
				
				set_user_health( iTempID, g_iPluginSettings[ SPACE_HEALTH_PRISONER ] );
				cs_set_user_armor( iTempID, g_iPluginSettings[ SPACE_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
			}
		}
	}
	
	set_pcvar_num( g_cvarGravity, g_iPluginSettings[ SPACE_GRAVITY ] );
	
	PlaySound( 0, SOUND_SPACE );
}

EndSpaceDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
	}
	
	g_bitHasUnAmmo = 0;
	
	set_pcvar_num( g_cvarGravity, 800 );
}

StartCowboyDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				set_user_health( iTempID, g_iPluginSettings[ COWBOY_HEALTH_GUARD ] );
				cs_set_user_armor( iTempID, g_iPluginSettings[ COWBOY_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
				
				GivePlayerWeapon( iTempID, ":P", g_iPluginSettings[ COWBOY_PRIMARY_GUARD ], g_iPluginSettings[ COWBOY_SECONDARY_GUARD ], true, true );
			}
			
			case CS_TEAM_T: {
				set_user_health( iTempID, g_iPluginSettings[ COWBOY_HEALTH_PRISONER ] );
				cs_set_user_armor( iTempID, g_iPluginSettings[ COWBOY_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
				
				GivePlayerWeapon( iTempID, ":P", g_iPluginSettings[ COWBOY_PRIMARY_PRISONER ], g_iPluginSettings[ COWBOY_SECONDARY_PRISONER ], true, true );
			}
		}
	}
	
	PlaySound( 0, SOUND_COWBOY );
}

EndCowboyDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_VESTHELM );
	}
	
	g_bitHasUnAmmo = 0;
}

StartSharkDay( ) {
	new iPlayers[ 32 ], iNum, iTempID, iLoop;
	get_players( iPlayers, iNum, "a" );
	
	switch( g_iTypeShark ) {
		case TYPE_REGULAR: {
			for( iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				StripPlayerWeapons( iTempID );
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_CT: {
						set_user_noclip( iTempID, 1 );
						
						set_user_health( iTempID, g_iPluginSettings[ SHARK_REG_HEALTH_GUARD ] );
						cs_set_user_armor( iTempID, g_iPluginSettings[ SHARK_REG_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
						
						client_print( iTempID, print_center, "Hold SHIFT to go faster" );
					}
					
					case CS_TEAM_T: {
						ShowWeaponMenu( iTempID );
						
						set_user_health( iTempID, g_iPluginSettings[ SHARK_REG_HEALTH_PRISONER ] );
						cs_set_user_armor( iTempID, g_iPluginSettings[ SHARK_REG_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
						
						set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
						set_user_footsteps( iTempID, 1 );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesDayVote[ DAY_SHARK ] );
		}
		
		case TYPE_REVERSE: {
			for( iLoop = 0; iLoop < iNum; iLoop++ ) {
				iTempID = iPlayers[ iLoop ];
				
				StripPlayerWeapons( iTempID );
				
				switch( cs_get_user_team( iTempID ) ) {
					case CS_TEAM_CT: {
						ShowWeaponMenu( iTempID );
						
						set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
						set_user_footsteps( iTempID, 1 );
						
						set_user_health( iTempID, g_iPluginSettings[ SHARK_REV_HEALTH_GUARD ] );
						cs_set_user_armor( iTempID, g_iPluginSettings[ SHARK_REV_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
					}
					
					case CS_TEAM_T: {
						set_user_noclip( iTempID, 1 );
						
						set_user_health( iTempID, g_iPluginSettings[ SHARK_REV_HEALTH_PRISONER ] );
						cs_set_user_armor( iTempID, g_iPluginSettings[ SHARK_REV_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
						
						client_print( iTempID, print_center, "Hold SHIFT to go faster" );
					}
				}
			}
			
			ShowDHUDMessage( g_strObjectivesReverseDayVote[ DAY_SHARK ] );
		}
	}
	
	g_iTimeLeft = g_iPluginSettings[ SHARK_COUNTDOWN_TIME ];
	set_task( 1.0, "Task_Countdown_Shark", TASK_COUNTDOWN_SHARK, _, _, "a", g_iTimeLeft );
	
	OpenCells( );
	g_bDayInProgress = true;
	SetDayHamHooks( DAY_SHARK, true );
}

EndSharkDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
		
		if( get_user_noclip( iTempID ) ) {
			set_user_noclip( iTempID );
			
			ExecuteHamB( Ham_CS_RoundRespawn, iTempID );
		}
		
		set_user_rendering( iTempID );
		set_user_footsteps( iTempID, 0 );
	}
	
	g_bitHasUnAmmo = 0;
}

StartLastManStandingDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		ShowWeaponMenu( iTempID );
		
		set_user_godmode( iTempID, 1 );
	}
	
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	if( iNum < 2 ) {
		client_print_color( 0, print_team_red, "^4%s^1 There must be at least^3 2 Prisoners^1 to start ^4Last Man Standing Day^1.", g_strPluginPrefix );
		client_print_color( 0, print_team_default, "^4%s^1 The day has been switched to ^4Unrestricted Free Day^1.", g_strPluginPrefix );
		
		g_iDayCurrent = DAY_FREE;
		StartFreeVote( );
	} else {
		set_task( float( g_iPluginSettings[ LMS_TIME_INTERVAL ] ), "Task_LMS_GiveWeapon", TASK_LMS_GIVEWEAPON );
		
		OpenCells( );
	}
}

EndLastManStandingDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
		
		if( get_user_godmode( iTempID ) ) {
			set_user_godmode( iTempID, 0 );
		}
	}
	
	g_bitHasUnAmmo = 0;
	
	if( g_bFFA ) {
		SetFreeForAll( 0 );
	}
}

StartSamuraiDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				set_user_health( iTempID, g_iPluginSettings[ SAMURAI_HEALTH_GUARD ] );
				cs_set_user_armor( iTempID, g_iPluginSettings[ SAMURAI_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
			}
			
			case CS_TEAM_T: {
				set_user_health( iTempID, g_iPluginSettings[ SAMURAI_HEALTH_PRISONER ] );
				cs_set_user_armor( iTempID, g_iPluginSettings[ SAMURAI_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
				
				set_user_rendering( iTempID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, 0 );
				set_user_footsteps( iTempID, 1 );
			}
		}
	}
	
	g_iTimeLeft = g_iPluginSettings[ SAMURAI_COUNTDOWN_TIME ];
	set_task( 1.0, "Task_Countdown_Samurai", TASK_COUNTDOWN_SAMURAI, _, _, "a", g_iTimeLeft );
	
	PlaySound( 0, SOUND_SAMURAI );
	OpenCells( );
}

EndSamuraiDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
	}
}

StartKnifeDay( ) {
	new iHealthCT = GetTeamPlayersNumber( "T" ) * g_iPluginSettings[ KNIFE_HEALTH_GUARD_REL ];
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		switch( cs_get_user_team( iTempID ) ) {
			case CS_TEAM_CT: {
				set_user_health( iTempID, iHealthCT );
				cs_set_user_armor( iTempID, g_iPluginSettings[ KNIFE_ARMOR_GUARD ], CS_ARMOR_VESTHELM );
			}
			
			case CS_TEAM_T: {
				set_user_health( iTempID, g_iPluginSettings[ KNIFE_HEALTH_PRISONER ] );
				cs_set_user_armor( iTempID, g_iPluginSettings[ KNIFE_ARMOR_PRISONER ], CS_ARMOR_VESTHELM );
			}
		}
	}
	
	OpenCells( );
}

EndKnifeDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "a" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, 100 );
		cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
	}
}

StartJudgementDay( ) {
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	new iBullets = clamp( ( GetTeamPlayersNumber( "T" ) / iNum ) + 1, 1, iNum );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		StripPlayerWeapons( iTempID );
		
		cs_set_weapon_ammo( give_item( iTempID, "weapon_deagle" ), iBullets );
		cs_set_user_bpammo( iTempID, CSW_DEAGLE, 0 );
	}
}

EndJudgementDay( ) {
	StripPlayerWeapons( 0, "C" );
}

StartHideNSeekDay( ) {
	ShowWeaponMenu( 0, "C" );
	StripPlayerWeapons( 0, "C" );
	
	g_iTimeLeft = g_iPluginSettings[ HNS_COUNTDOWN_TIME ];
	set_task( 1.0, "Task_Countdown_HNS", TASK_COUNTDOWN_HNS, _, _, "a", g_iTimeLeft );
	
	OpenCells( );
}

EndHideNSeekDay( ) {
	g_bitHasUnAmmo = 0;
}

StartMarioDay( ) {
	ShowWeaponMenu( 0, "C" );
	
	g_iTimeLeft = g_iPluginSettings[ MARIO_COUNTDOWN_TIME ];
	set_task( 1.0, "Task_Countdown_Mario", TASK_COUNTDOWN_MARIO, _, _, "a", g_iTimeLeft );
	
	set_pcvar_num( g_cvarGravity, g_iPluginSettings[ MARIO_GRAVITY ] );
	
	PlaySound( 0, SOUND_MARIO );
	OpenCells( );
}

EndMarioDay( ) {
	StripPlayerWeapons( 0, "C" );
	
	set_pcvar_num( g_cvarGravity, 800 );
	
	g_bitHasUnAmmo = 0;
}

StartCustomDay( ) {
	/*
		Empty because there is nothing to put in here :(
	*/
}

EndCustomDay( ) {
	/*
		Empty because there is nothing to put in here :(
	*/
}

/* Last Requests */
StartLastRequest( ) {
	g_bLRInProgress = true;
	
	new iPrisoner = g_iLastRequestPlayers[ PLAYER_PRISONER ];
	new iGuard = g_iLastRequestPlayers[ PLAYER_GUARD ];
	
	StripPlayerWeapons( iPrisoner );
	StripPlayerWeapons( iGuard );
	
	set_user_health( iPrisoner, 100 );
	set_user_health( iGuard, 100 );
	
	cs_set_user_armor( iPrisoner, 100, CS_ARMOR_VESTHELM );
	cs_set_user_armor( iGuard, 100, CS_ARMOR_VESTHELM );
	
	set_user_rendering( iPrisoner, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
	set_user_rendering( iGuard, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 5 );
	
	new strPrisonerName[ 32 ], strGuardName[ 32 ];
	get_user_name( iPrisoner, strPrisonerName, charsmax( strPrisonerName ) );
	get_user_name( iGuard, strGuardName, charsmax( strGuardName ) );
	
	client_print_color( 0, print_team_red, "^4%s^3 %s^1 has challenged %s to ^4%s^1.", g_strPluginPrefix, strPrisonerName, strGuardName, g_strOptionsLastRequest[ g_iLRCurrent ] );
	
	ShowDHUDMessage( g_strObjectivesLastRequest[ g_iLRCurrent ] );
	
	switch( g_iLRCurrent ) {
		case LR_KNIFE:		StartKnifeFight( );
		case LR_WEAPONTOSS:	StartWeaponToss( );
		case LR_DUEL: {
			client_print_color( 0, print_team_default, "^4%s^1 Weapon Duel is about to start in 5 seconds. Get ready!", g_strPluginPrefix );
			
			set_task( 5.0, "StartDuel", TASK_START_DUEL );
		}
		case LR_S4S:		StartS4S( );
		case LR_SHOWDOWN:	StartShowdown( );
		case LR_GRENADETOSS:	StartGrenadeToss( );
		case LR_HOTPOTATO:	StartHotPotato( );
		case LR_RACE:		StartRace( );
		case LR_SPRAY:		StartSprayContest( );
	}
	
	SetLRHamHooks( g_iLRCurrent, true );
}

EndLastRequest( iLooser, iWinner ) {
	switch( g_iLRCurrent ) {
		case LR_KNIFE:		EndKnifeFight( );
		case LR_WEAPONTOSS:	EndWeaponToss( );
		case LR_DUEL:		EndDuel( );
		case LR_S4S:		EndS4S( );
		case LR_SHOWDOWN:	EndShowdown( );
		case LR_KAMIKAZE:	EndKamikaze( );
		case LR_GRENADETOSS:	EndGrenadeToss( );
		case LR_HOTPOTATO:	EndHotPotato( );
		case LR_RACE:		EndRace( );
		case LR_SPRAY:		EndSprayContest( );
		case LR_MANIAC:	EndDeagleManiac( );
		case LR_GLOCKER:	EndUberGlocker( );
	}
	
	if( !iLooser || !iWinner ) {
		client_print_color( 0, print_team_default, "^4%s^1 Last Request has ended.", g_strPluginPrefix );
	} else {
		new strWinnerName[ 32 ], strLooserName[ 32 ];
		get_user_name( iWinner, strWinnerName, charsmax( strWinnerName ) );
		get_user_name( iLooser, strLooserName, charsmax( strLooserName ) );
		
		set_user_health( iWinner, 100 );
		cs_set_user_armor( iWinner, 0, CS_ARMOR_NONE );
		StripPlayerWeapons( iWinner );
		
		set_user_rendering( iWinner );
		set_user_rendering( iLooser );
		
		client_print_color( 0, iWinner, "^4%s^3 %s^1 has beaten %s in ^4Last Request^1.", g_strPluginPrefix, strWinnerName, strLooserName );
	}
	
	RemoveAllTasks( );
	
	g_bLRInProgress = false;
	
	SetLRHamHooks( g_iLRCurrent, false );
}

StartKnifeFight( ) {
	set_user_health( g_iLastRequestPlayers[ PLAYER_GUARD ], g_iPluginSettings[ KNIFE_HEALTH_1 + g_iLRChosenKnifeFight ] );
	set_user_health( g_iLastRequestPlayers[ PLAYER_PRISONER ], g_iPluginSettings[ KNIFE_HEALTH_1 + g_iLRChosenKnifeFight ] );
}

EndKnifeFight( ) {
	/*
		Empty because there is nothing to put in here :(
	*/
}

StartWeaponToss( ) {
	cs_set_weapon_ammo( give_item( g_iLastRequestPlayers[ PLAYER_GUARD ], g_strWeapons[ g_iPluginSettings[ TOSS_WEAPON_1_STR + g_iLRChosenWeaponToss ] ] ), 0 );
	cs_set_weapon_ammo( give_item( g_iLastRequestPlayers[ PLAYER_PRISONER ], g_strWeapons[ g_iPluginSettings[ TOSS_WEAPON_1_STR + g_iLRChosenWeaponToss ] ] ), 0 );
}

EndWeaponToss( ) {
	/*
		Empty because there is nothing to put in here :(
	*/
}

public StartDuel( ) {
	new iWeapon = g_iPluginSettings[ DUEL_WEAPON_1_STR + g_iLRChosenDuel ];
	
	if( iWeapon <= PRIMARY_P90 ) {
		GivePlayerWeapon( g_iLastRequestPlayers[ PLAYER_GUARD ], ":P", iWeapon, -1, false, true );
		GivePlayerWeapon( g_iLastRequestPlayers[ PLAYER_PRISONER ], ":P", iWeapon, -1, false, true );
	} else {
		GivePlayerWeapon( g_iLastRequestPlayers[ PLAYER_GUARD ], ":P", -1, iWeapon, false, true );
		GivePlayerWeapon( g_iLastRequestPlayers[ PLAYER_PRISONER ], ":P", -1, iWeapon, false, true );
	}
}

EndDuel( ) {
	g_bitHasUnAmmo = 0;
}

StartS4S( ) {
	cs_set_weapon_ammo( give_item( g_iLastRequestPlayers[ PLAYER_GUARD ], g_strWeapons[ g_iPluginSettings[ S4S_WEAPON_1_STR + g_iLRChosenS4S ] ] ), 1 );
	cs_set_weapon_ammo( give_item( g_iLastRequestPlayers[ PLAYER_PRISONER ], g_strWeapons[ g_iPluginSettings[ S4S_WEAPON_1_STR + g_iLRChosenS4S ] ] ), 0 );
}

EndS4S( ) {
	/*
		Empty because there is nothing to put in here :(
	*/
}

StartShowdown( ) {
	GivePlayerWeapon( g_iLastRequestPlayers[ PLAYER_GUARD ], ":P", -1, SECONDARY_FIVESEVEN, false, true );
	GivePlayerWeapon( g_iLastRequestPlayers[ PLAYER_PRISONER ], ":P", -1, SECONDARY_FIVESEVEN, false, true );
	
	g_bAllowStartShowdown = true;
	
	client_print_color( 0, print_team_red, "^4%s^1 Showdown will start when the ^3Prisoner^1 types: ^4/showdown^1.", g_strPluginPrefix );
}

EndShowdown( ) {
	g_bitHasUnAmmo = 0;
	
	g_bAllowStartShowdown = false;
}

StartKamikaze( iPlayerID ) {
	g_bLRInProgress = true;
	
	set_user_health( iPlayerID, g_iPluginSettings[ KAMIKAZE_PRISONER_HEALTH ] );
	
	if( g_iPluginSettings[ KAMIKAZE_PRISONER_ARMOR ] ) {
		cs_set_user_armor( iPlayerID, g_iPluginSettings[ KAMIKAZE_PRISONER_ARMOR ], CS_ARMOR_VESTHELM );
	} else {
		cs_set_user_armor( iPlayerID, 0, CS_ARMOR_NONE );
	}
	
	set_user_rendering( iPlayerID, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
	
	GivePlayerWeapon( iPlayerID, ":P", PRIMARY_M249, SECONDARY_DEAGLE, true, true );
	
	StripPlayerWeapons( 0, "C" );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	new iGuardHealth = g_iPluginSettings[ KAMIKAZE_GUARD_HEALTH ];
	new iGuardArmor = g_iPluginSettings[ KAMIKAZE_GUARD_ARMOR ];
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, iGuardHealth );
		
		if( iGuardArmor ) {
			cs_set_user_armor( iTempID, iGuardArmor, CS_ARMOR_VESTHELM );
		} else {
			cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
		}
		
		ShowWeaponMenu( iTempID );
	}
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
	
	client_print_color( 0, print_team_red, "^4%s^3 %s^1 has initiated ^4Kamikaze mode^1. Kill him on sight!", g_strPluginPrefix, strPlayerName );
	
	ShowDHUDMessage( g_strObjectivesLastRequest[ LR_KAMIKAZE ] );
	
	SetLRHamHooks( LR_KAMIKAZE, true );
}

EndKamikaze( ) {
	g_bitHasUnAmmo = 0;
}

StartGrenadeToss( ) {
	give_item( g_iLastRequestPlayers[ PLAYER_GUARD ], "weapon_smokegrenade" );
	give_item( g_iLastRequestPlayers[ PLAYER_PRISONER ], "weapon_smokegrenade" );
}

EndGrenadeToss( ) {
	/*
		Empty because there is nothing to put in here :(
	*/
}

StartHotPotato( ) {
	cs_set_weapon_ammo( give_item( g_iLastRequestPlayers[ PLAYER_GUARD ], "weapon_scout" ), 0 );
	
	g_bAllowStartHotPotato = true;
	
	client_print_color( 0, print_team_red, "^4%s^1 Hot Potato will start when the ^3Prisoner^1 types: ^4/hotpotato^1.", g_strPluginPrefix );
}

EndHotPotato( ) {
	g_bAllowStartHotPotato = false;
}

StartRace( ) {
	g_bAllowStartRace = true;
	
	client_print_color( 0, print_team_red, "^4%s^1 Race will start when the ^3Prisoner^1 types: ^4/race^1.", g_strPluginPrefix );
}

EndRace( ) {
	g_bAllowStartRace = false;
}

StartSprayContest( ) {
	static m_flNextDecalTime = 486;
	
	set_pdata_float( g_iLastRequestPlayers[ PLAYER_GUARD ], m_flNextDecalTime, 0.0 );
	set_pdata_float( g_iLastRequestPlayers[ PLAYER_PRISONER ], m_flNextDecalTime, 0.0 );
}

EndSprayContest( ) {
	/*
		Empty because there is nothing to put in here :(
	*/
}

StartDeagleManiac( iPlayerID ) {
	g_bLRInProgress = true;
	
	set_user_health( iPlayerID, g_iPluginSettings[ MANIAC_PRISONER_HEALTH ] );
	
	if( g_iPluginSettings[ MANIAC_PRISONER_ARMOR ] ) {
		cs_set_user_armor( iPlayerID, g_iPluginSettings[ MANIAC_PRISONER_ARMOR ], CS_ARMOR_VESTHELM );
	} else {
		cs_set_user_armor( iPlayerID, 0, CS_ARMOR_NONE );
	}
	
	set_user_rendering( iPlayerID, kRenderFxGlowShell, 0, 0, 0, kRenderTransAlpha, g_iPluginSettings[ MANIAC_PRISONER_INVIS ] );
	
	GivePlayerWeapon( iPlayerID, ":P", -1, SECONDARY_DEAGLE, true, true );
	
	new iGuardHealth = g_iPluginSettings[ MANIAC_GUARD_HEALTH ];
	new iGuardArmor = g_iPluginSettings[ MANIAC_GUARD_ARMOR ];
	
	StripPlayerWeapons( 0, "C" );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, iGuardHealth );
		
		if( iGuardArmor ) {
			cs_set_user_armor( iTempID, iGuardArmor, CS_ARMOR_VESTHELM );
		} else {
			cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
		}
		
		ShowWeaponMenu( iTempID );
	}
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
	
	client_print_color( 0, print_team_red, "^4%s^3 %s^1 has gone crazy with his Deagle. Kill him on sight if you can see him!", g_strPluginPrefix, strPlayerName );
	
	ShowDHUDMessage( g_strObjectivesLastRequest[ LR_MANIAC ] );
	
	SetLRHamHooks( LR_MANIAC, true );
}

EndDeagleManiac( ) {
	g_bitHasUnAmmo = 0;
}

StartUberGlocker( iPlayerID ) {
	g_bLRInProgress = true;
	
	set_user_health( iPlayerID, g_iPluginSettings[ GLOCKER_PRISONER_HEALTH ] );
	
	if( g_iPluginSettings[ GLOCKER_PRISONER_ARMOR ] ) {
		cs_set_user_armor( iPlayerID, g_iPluginSettings[ GLOCKER_PRISONER_ARMOR ], CS_ARMOR_VESTHELM );
	} else {
		cs_set_user_armor( iPlayerID, 0, CS_ARMOR_NONE );
	}
	
	set_user_rendering( iPlayerID, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
	
	GivePlayerWeapon( iPlayerID, ":P", -1, SECONDARY_GLOCK18, true, true );
	
	new iGuardHealth = g_iPluginSettings[ GLOCKER_GUARD_HEALTH ];
	new iGuardArmor = g_iPluginSettings[ GLOCKER_GUARD_HEALTH ];
	
	StripPlayerWeapons( 0, "C" );
	
	new iPlayers[ 32 ], iNum, iTempID;
	get_players( iPlayers, iNum, "ae", "CT" );
	
	for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
		iTempID = iPlayers[ iLoop ];
		
		set_user_health( iTempID, iGuardHealth );
		
		if( iGuardArmor ) {
			cs_set_user_armor( iTempID, iGuardArmor, CS_ARMOR_VESTHELM );
		} else {
			cs_set_user_armor( iTempID, 0, CS_ARMOR_NONE );
		}
		
		ShowWeaponMenu( iTempID );
	}
	
	new strPlayerName[ 32 ];
	get_user_name( iPlayerID, strPlayerName, charsmax( strPlayerName ) );
	
	client_print_color( 0, print_team_red, "^4%s^3 %s^1 thinks he is the master of the ^4Glock^1. Let's see what happens...", g_strPluginPrefix, strPlayerName );
	
	ShowDHUDMessage( g_strObjectivesLastRequest[ LR_GLOCKER ] );
	
	SetLRHamHooks( LR_GLOCKER, true );
}

EndUberGlocker( ) {
	g_bitHasUnAmmo = 0;
}

/* Other Functions */
RegisterPCVARs( ) {
	g_pcvarPluginPrefix			= register_cvar( "uj_plugin_prefix",		"[UJ]" );
	g_pcvarResetButtons			= register_cvar( "uj_reset_buttons",		"1" );
	g_pcvarShootButtons			= register_cvar( "uj_shoot_buttons",		"2" );
	g_pcvarDayVote				= register_cvar( "uj_day_vote",			"1" );
	g_pcvarDayVoteVoters			= register_cvar( "uj_day_vote_voters",		"2" );
	g_pcvarDayVoteEndAtZero			= register_cvar( "uj_day_vote_end_at_zero",	"1" );
	g_pcvarDayVotePrimary			= register_cvar( "uj_day_vote_primary",		"15" );
	g_pcvarDayVoteSecondary			= register_cvar( "uj_day_vote_secondary",	"7" );
	g_pcvarDayVoteMinPrisoners		= register_cvar( "uj_day_vote_min_prisoners",	"2" );
	g_pcvarDayVoteMinGuards			= register_cvar( "uj_day_vote_min_guards",	"1" );
	g_pcvarDayVoteOppositeChance		= register_cvar( "uj_day_vote_opposite_chance",	"7" );
	g_pcvarDayVoteRestrictDays		= register_cvar( "uj_day_vote_restrict_days",	"1" );
	g_pcvarDayVoteFirstFreeday		= register_cvar( "uj_day_vote_first_freeday",	"1" );
	g_pcvarDayVoteShowVotes			= register_cvar( "uj_day_vote_show_votes",	"1" );
	g_pcvarDayVoteWeightedVotes		= register_cvar( "uj_day_vote_weighted_votes",	"2" );
	g_pcvarWeaponMenuArmor			= register_cvar( "uj_weapon_menu_armor",	"100" );
	g_pcvarWeaponMenuNades			= register_cvar( "uj_weapon_menu_nades",	"3" );
	g_pcvarOpenCommand			= register_cvar( "uj_open_command",		"1" );
	g_pcvarRestrictMicrophones		= register_cvar( "uj_restrict_mics",		"1" );
	g_pcvarShowHealth			= register_cvar( "uj_show_health",		"1" );
	g_pcvarLastRequest			= register_cvar( "uj_last_request",		"1" );
	g_pcvarLastRequestAutomatic		= register_cvar( "uj_last_request_auto",	"1" );
	g_pcvarLastRequestMic			= register_cvar( "uj_last_request_mic",		"1" );
	g_pcvarSprayChecker			= register_cvar( "uj_spray_checker",		"1" );
	g_pcvarSprayCustom			= register_cvar( "uj_dpray_custom",		"1" );
	g_pcvarFlashLight			= register_cvar( "uj_flashlight",		"2" );
	g_pcvarCommander			= register_cvar( "uj_commander",		"1" );
	g_pcvarMainMenu				= register_cvar( "uj_main_menu",		"1" );
	g_pcvarMainMenuRatio			= register_cvar( "uj_main_menu_ratio",		"3" );
	g_pcvarMainMenuTime			= register_cvar( "uj_main_menu_time",		"600" );
	g_pcvarPoints				= register_cvar( "uj_points",			"1" );
	
	g_cvarGravity				= get_cvar_pointer( "sv_gravity" );
	g_cvarRoundTime				= get_cvar_pointer( "mp_roundtime" );
}

ReloadPCVARs( ) {
	g_iDayVote				= get_pcvar_num( g_pcvarDayVote );
	g_iDayVoteVoters			= get_pcvar_num( g_pcvarDayVoteVoters );
	g_iDayVoteRestrictDays			= get_pcvar_num( g_pcvarDayVoteRestrictDays );
	g_iDayVoteShowVotes			= get_pcvar_num( g_pcvarDayVoteShowVotes );
	g_iDayVoteWeightedVotes			= get_pcvar_num( g_pcvarDayVoteWeightedVotes );
	g_iWeaponMenuArmor			= get_pcvar_num( g_pcvarWeaponMenuArmor );
	g_iWeaponMenuNades			= get_pcvar_num( g_pcvarWeaponMenuNades );
	g_iOpenCommand				= get_pcvar_num( g_pcvarOpenCommand );
	g_iShootButtons				= get_pcvar_num( g_pcvarShootButtons );
	g_iRestrictMicrophones			= get_pcvar_num( g_pcvarRestrictMicrophones );
	g_iShowHealth				= get_pcvar_num( g_pcvarShowHealth );
	g_iLastRequest				= get_pcvar_num( g_pcvarLastRequest );
	g_iLastRequestMic			= get_pcvar_num( g_pcvarLastRequestMic );
	g_iCommander				= get_pcvar_num( g_pcvarCommander );
	g_iSprayChecker				= get_pcvar_num( g_pcvarSprayChecker );
	g_iSprayCustom				= get_pcvar_num( g_pcvarSprayCustom );
	g_iFlashLight				= get_pcvar_num( g_pcvarFlashLight );
	g_iMainMenu				= get_pcvar_num( g_pcvarMainMenu );
	g_iMainMenuRatio			= get_pcvar_num( g_pcvarMainMenuRatio );
	g_iMainMenuTime				= get_pcvar_num( g_pcvarMainMenuTime );
	g_iPoints				= get_pcvar_num( g_pcvarPoints );
	
	g_msgScreenShake			= get_user_msgid( "ScreenShake" );
	g_msgRadar				= get_user_msgid( "Radar" );
	
	get_pcvar_string( g_pcvarPluginPrefix, g_strPluginPrefix, charsmax( g_strPluginPrefix ) );
}

ExecConfig( ) {
	new strConfigDir[ 128 ];
	get_localinfo( "amxx_configsdir", strConfigDir, 127 );
	format( strConfigDir, 127, "%s/%s.cfg", strConfigDir, g_strPluginName );
	
	if( file_exists( strConfigDir ) ) {
		server_cmd( "exec %s", strConfigDir );
		server_exec( );
	}
}

LoadPluginSettings( ) {
	new strConfigDir[ 128 ];
	get_localinfo( "amxx_configsdir", strConfigDir, charsmax( strConfigDir ) );
	format( strConfigDir, charsmax( strConfigDir ), "%s/UltimateJailBreak.ini", strConfigDir );
	
	if( file_exists( strConfigDir ) ) {
		new strData[ 256 ];
		new iFile = fopen( strConfigDir, "r" );
		
		new strLeft[ 32 ], strRight[ 32 ];
		new iCounter = 0;
		
		while( !feof( iFile ) ) {
			fgets( iFile, strData, charsmax( strData ) );
			
			if( isalpha( strData[ 0 ] ) ) {
				strtok( strData, strLeft, charsmax( strLeft ), strRight, charsmax( strRight ), ' ', 1 );
					
				g_iPluginSettings[ iCounter++ ] = str_to_num( strRight );
			}
		}
		
		fclose( iFile );
	} else {
		set_fail_state( "%s.ini file not found, plugin cannot continue!", g_strPluginName );
	}
}

ResetButtons( ) {
	/*
		Resetting all buttons on round start. This helps in many situations
		where the map maker did not think of this situation. Very common on 
		jailbreak maps.
	*/
	if( get_pcvar_num( g_pcvarResetButtons ) ) {
		new iEntity;
		
		while( ( iEntity = find_ent_by_class( iEntity, "func_button" ) ) > 0 ) {
			call_think( iEntity );
		}
	}
}

RemoveAllTasks( ) {
	for( new iLoop = 0; iLoop < MAX_TASKS; iLoop++ ) {
		if( task_exists( iLoop ) ) {
			remove_task( iLoop );
		}
	}
}

ResetVotes( ) {
	ResetDayVote( );
}

CheckMinimumPlayers( ) {
	new iPlayers[ 32 ], iNum;
	
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	new iMinimumPrisoners = get_pcvar_num( g_pcvarDayVoteMinPrisoners );
	
	if( iNum < iMinimumPrisoners ) {
		client_print_color( 0, print_team_red, "^4%s^1 There must be at least ^3%i Prisoners^1 to start the vote.", g_strPluginPrefix, iMinimumPrisoners );
		
		return false;
	}
	
	new iMinimumGuards = get_pcvar_num( g_pcvarDayVoteMinGuards );
	
	if( iNum < iMinimumGuards ) {
		client_print_color( 0, print_team_blue, "^4%s^1 There must be at least ^3%i Guards^1 to start the vote.", g_strPluginPrefix, iMinimumGuards );
		
		return false;
	}
	
	return true;
}

CheckIfLastPage( iPlayerPage ) {
	if( iPlayerPage == ( GetLastPage( ) - 1 ) ) {
		return true;
	}
	
	return false;
}

GetLastPage( ) {
	#if defined DEBUG
	log_amx( "--------------------" );
	log_amx( "Entered 'GetLastPage' function" );
	#endif
	
	static iLastPage = 0;
	
	if( !iLastPage ) {
		new iFullPages = MAX_DAYS / PAGE_OPTIONS;
		new iRemainder = MAX_DAYS % PAGE_OPTIONS;
		
		#if defined DEBUG
		log_amx( "iFullPages is %i", iFullPages );
		log_amx( "iRemainder is %i", iRemainder );
		#endif
		
		if( iRemainder ) {
			iLastPage = iFullPages + 1;
		} else {
			iLastPage = iFullPages - 1;
		}
		
		#if defined DEBUG
		log_amx( "iLastPage is %i", iLastPage );
		#endif
	}
	
	#if defined DEBUG
	log_amx( "Exited 'GetLastPage' function" );
	log_amx( "--------------------" );
	#endif
	
	return iLastPage;
}

SumOfNextPages( iPlayerPage ) {
	new iSum = 0;
	
	for( new iLoop = iPlayerPage; iLoop <= GetLastPage( ) - 1; iLoop++ ) {
		if( iPlayerPage != iLoop ) {
			iSum += g_iVotesPages[ iLoop ];
		}
	}
	
	return iSum;
}

SumOfPreviousPages( iPlayerPage ) {
	new iSum = 0;
	
	for( new iLoop = iPlayerPage; iLoop >= 0; iLoop-- ) {
		if( iPlayerPage != iLoop ) {
			iSum += g_iVotesPages[ iLoop ];
		}
	}
	
	return iSum;
}

StripPlayerWeapons( iPlayerID, strTeam[ ] = "" ) {
	/*
		This is thanks to ConnorMcLeod.
	*/
	if( !iPlayerID ) {
		new iPlayers[ 32 ], iNum, iTempID;
		
		switch( strTeam[ 0 ] ) {
			case 'C', 'c': {
				get_players( iPlayers, iNum, "ae", "CT" );
			}
			
			case 'T', 't': {
				get_players( iPlayers, iNum, "ae", "TERRORIST" );
			}
			
			case 'A', 'a': {
				get_players( iPlayers, iNum, "a" );
			}
		}
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			strip_user_weapons( iTempID );
			set_pdata_int( iTempID, 116, 0 );
			
			give_item( iTempID, "weapon_knife" );
		}
	} else {
		strip_user_weapons( iPlayerID );
		set_pdata_int( iPlayerID, 116, 0 );
		
		give_item( iPlayerID, "weapon_knife" );
	}
}

CheckAllowedVote( iPlayerID, CsTeams:iTeam ) {
	/*
		Check if the player is allowed to vote.
		1: Terrorists can vote.
		2: Counter Terrorists can vote.
	*/
	#if defined DEBUG
	log_amx( "--------------------" );
	log_amx( "Entered 'CheckAllowedVote' function" );
	log_amx( "Player's team is %s", ( iTeam == CS_TEAM_CT ) ? "CT" : "T" );
	#endif
	
	switch( g_iDayVoteVoters ) {
		case 1: {
			#if defined DEBUG
			log_amx( "g_iDayVoteVoters is 1" );
			#endif
			
			if( g_bOppositeVote && iTeam == CS_TEAM_T || g_bOppositeVote && iTeam == CS_TEAM_CT ) {
				#if defined DEBUG
				log_amx( "Player not allowed to vote, team: %s, g_bOppositeVote: %i, voters: %i", ( iTeam == CS_TEAM_CT ) ? "CT" : "T", g_bOppositeVote ? 1 : 0, g_iDayVoteVoters );
				#endif
				
				client_print_color( iPlayerID, ( iTeam == CS_TEAM_CT ) ? print_team_red : print_team_blue, "^4%s^1 Today is an opposite vote day. Only ^3%s^1 are allowed to vote.", g_strPluginPrefix, ( iTeam == CS_TEAM_CT ) ? "Prisoners" : "Guards" );
				
				return false;
			}
		}
		
		case 2: {
			#if defined DEBUG
			log_amx( "g_iDayVoteVoters is 2" );
			#endif
			
			if( g_bOppositeVote && iTeam == CS_TEAM_CT || !g_bOppositeVote && iTeam == CS_TEAM_T ) {
				#if defined DEBUG
				log_amx( "Player not allowed to vote, team: %s, g_bOppositeVote: %i, voters: %i", ( iTeam == CS_TEAM_CT ) ? "CT" : "T", g_bOppositeVote ? 1 : 0, g_iDayVoteVoters );
				#endif
				
				client_print_color( iPlayerID, ( iTeam == CS_TEAM_T ) ? print_team_blue : print_team_red, "^4%s^1 Today is an opposite vote day. Only ^3%s^1 are allowed to vote.", g_strPluginPrefix, ( iTeam == CS_TEAM_T ) ? "Guards" : "Prisoners" );
				
				return false;
			}
		}
	}
	
	#if defined DEBUG
	log_amx( "Exited 'ChekcAllowedVote' function" );
	log_amx( "--------------------" );
	#endif
	
	return true;
}

CheckWeightedVote( CsTeams:iTeam ) {
	/*
		According to the CVAR, a team gets double the ammount of votes
		per member. That is useful if you have a server with ratio of 1:2
		let's say, so CTs need to have more votes for their favour.
	*/
	switch( g_iDayVoteWeightedVotes ) {
		case 1: {
			if( iTeam == CS_TEAM_T ) {
				return 2;
			}
		}
		
		case 2: {
			if( iTeam == CS_TEAM_CT ) {
				return 2;
			}
		}
	}
	
	return 1;
}

GetHighestVote( iVotes[ ], iSize ) {
	new iHighest = 0;
	
	for( new iLoop = 0; iLoop < iSize; iLoop++ ) {
		if( iVotes[ iLoop ] > iVotes[ iHighest ] ) {
			iHighest = iLoop;
		}
	}
	
	if( !iHighest && !iVotes[ iHighest ] ) {
		return -1;
	}
	
	return iHighest;
}

GetTeamPlayersNumber( strTeam[ ] = "" ) {
	static iPlayers[ 32 ], iNum;
	
	switch( strTeam[ 0 ] ) {
		case 'C', 'c': {
			get_players( iPlayers, iNum, "ae", "CT" );
			
			return iNum;
		}
		
		case 'T', 't': {
			get_players( iPlayers, iNum, "ae", "TERRORIST" );
			
			return iNum;
		}
		
		case 'A', 'a': {
			get_players( iPlayers, iNum, "a" );
			
			return iNum;
		}
		
		case 'F', 'f': {
			get_players( iPlayers, iNum, "ae", "TERRORIST" );
			
			new iCounter = 0;
			
			for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
				if( CheckBit( g_bitHasFreeDay, iPlayers[ iLoop ] ) ) {
					iCounter++;
				}
			}
			
			return iCounter;
		}
	}
	
	return -1;
}

ShowDHUDMessage( strMessage[ ] = "" ) {
	set_dhudmessage( 0, 160, 0, -1.0, 0.6, 2, 0.02, 4.0, 0.02, 5.0 );
	show_dhudmessage( 0, strMessage );
}

GivePlayerWeapon( iPlayerID, strTeam[ ] = "", iPrimary = -1, iSecondary = -1, bStrip = true, bUnlimitedAmmo = true ) {
	static iWeaponsAmmo[ MAX_WEAPONS ] = {
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
		CSW_P90,
		
		CSW_USP,
		CSW_GLOCK18,
		CSW_DEAGLE,
		CSW_P228,
		CSW_ELITE,
		CSW_FIVESEVEN
	};
	
	static iWeaponsMaxAmmo[ MAX_WEAPONS ] = {
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
		100,		// CSW_P90
		
		100,		// CSW_USP
		120,		// CSW_GLOCK18
		35,		// CSW_DEAGLE
		52,		// CSW_P228
		120,		// CSW_ELITE
		100		// CSW_FIVESEVEN
	};
	
	if( !iPlayerID ) {
		new iPlayers[ 32 ], iNum, iTempID;
		
		switch( strTeam[ 0 ] ) {
			case 'C', 'c': {
				get_players( iPlayers, iNum, "ae", "CT" );
			}
			
			case 'T', 't': {
				get_players( iPlayers, iNum, "ae", "TERRORIST" );
			}
			
			case 'A', 'a': {
				get_players( iPlayers, iNum, "a" );
			}
		}
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			if( bStrip ) {
				StripPlayerWeapons( iTempID );
			}
			
			if( iPrimary != -1 ) {
				give_item( iTempID, g_strWeapons[ iPrimary ] );
				cs_set_user_bpammo( iTempID, iWeaponsAmmo[ iPrimary ], iWeaponsMaxAmmo[ iPrimary ] );
			}
			
			if( iSecondary != -1 ) {
				give_item( iTempID, g_strWeapons[ iSecondary ] );
				cs_set_user_bpammo( iTempID, iWeaponsAmmo[ iSecondary ], iWeaponsMaxAmmo[ iSecondary ] );
			}
			
			if( bUnlimitedAmmo ) {
				SetBit( g_bitHasUnAmmo, iTempID );
			}
		}
	} else {
		if( bStrip ) {
			StripPlayerWeapons( iPlayerID );
		}
		
		if( iPrimary != -1 ) {
			give_item( iPlayerID, g_strWeapons[ iPrimary ] );
			cs_set_user_bpammo( iPlayerID, iWeaponsAmmo[ iPrimary ], iWeaponsMaxAmmo[ iPrimary ] );
		}
		
		if( iSecondary != -1 ) {
			give_item( iPlayerID, g_strWeapons[ iSecondary ] );
			cs_set_user_bpammo( iPlayerID, iWeaponsAmmo[ iSecondary ], iWeaponsMaxAmmo[ iSecondary ] );
		}
		
		if( bUnlimitedAmmo ) {
			SetBit( g_bitHasUnAmmo, iPlayerID );
		}
	}
}

GetAimingEnt( iPlayerID ) {
	new Float:fStart[ 3 ], Float:fViewOfs[ 3 ], Float:fDest[ 3 ];
	
	pev( iPlayerID, pev_origin, fStart );
	pev( iPlayerID, pev_view_ofs, fViewOfs );
	
	for( new iLoop = 0; iLoop < 3; iLoop++ ) {
		fStart[ iLoop ] += fViewOfs[ iLoop ];
	}
	
	pev( iPlayerID, pev_v_angle, fDest );
	engfunc( EngFunc_MakeVectors, fDest );
	global_get( glb_v_forward, fDest );
	
	for( new iLoop = 0; iLoop < 3; iLoop++ ) {
		fDest[ iLoop ] *= 9999.0;
		fDest[ iLoop ] += fStart[ iLoop ];
	}
	
	engfunc( EngFunc_TraceLine, fStart, fDest, DONT_IGNORE_MONSTERS, iPlayerID, 0 );
	
	return get_tr2( 0, TR_pHit );
}

PlaySound( iPlayerID, iSound ) {
	client_cmd( iPlayerID, "spk ^"%s^"", g_strSounds[ iSound ] );
}

SetBeamFollow( iEntity, iLife, iWidth, iRed, iGreen, iBlue, iBright ) {
	message_begin( MSG_BROADCAST, SVC_TEMPENTITY );
	write_byte( TE_BEAMFOLLOW );
	write_short( iEntity );
	write_short( g_iSpriteWeaponTrail );
	write_byte( iLife );
	write_byte( iWidth );
	write_byte( iRed );
	write_byte( iGreen );
	write_byte( iBlue );
	write_byte( iBright );
	message_end( );
}

RemoveBuyZones( ) {
	new iEntity = create_entity( "info_map_parameters" );
	DispatchKeyValue( iEntity, "buying", "3" );
	DispatchSpawn( iEntity );
	
	g_fwdSpawn = register_forward( FM_Spawn, "Forward_Spawn", 0 );
}

UnregisterSpawnForward( ) {
	if( g_fwdSpawn ) {
		unregister_forward( FM_Spawn, g_fwdSpawn, 0 );
	}
}

CapitalizeFirstLetter( strString[ ] ) {
	if( !is_char_upper( strString[ 0 ] ) ) {
		strString[ 0 ] = char_to_upper( strString[ 0 ] );
	}
}

ComputeDayRestrictions( ) {
	if( g_iDayVoteRestrictDays ) {
		for( new iLoop = 0; iLoop < MAX_DAYS; iLoop++ ) {
			if( iLoop == g_iDayCurrent && !g_iDayVoteRestrictionLeft[ iLoop ] ) {
				g_iDayVoteRestrictionLeft[ iLoop ] = g_iPluginSettings[ RESTRICTION_CAGE + iLoop ];
			} else {
				if( g_iDayVoteRestrictionLeft[ iLoop ] ) {
					g_iDayVoteRestrictionLeft[ iLoop ]--;
				}
			}
		}
	}
}

SetDayHamHooks( iDay, bool:bState ) {
	switch( iDay ) {
		case DAY_USP_NINJA: {
			if( bState ) {
				if( g_hamUSPSecondaryAttack ) {
					EnableHamForward( g_hamUSPSecondaryAttack );
				} else {
					g_hamUSPSecondaryAttack = RegisterHam( Ham_Weapon_SecondaryAttack, "weapon_usp", "Ham_SecondaryAttack_USP_Post", true );
				}
				
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
			} else {
				if( g_hamUSPSecondaryAttack ) {
					DisableHamForward( g_hamUSPSecondaryAttack );
				}
				
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
			}
		}
		
		case DAY_NIGHTCRAWLER: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchWorldSpawn ) {
					EnableHamForward( g_hamTouchWorldSpawn );
				} else {
					g_hamTouchWorldSpawn = RegisterHam( Ham_Touch, "worldspawn", "Ham_Touch_Wall_Pre", false );
				}
				
				if( g_hamTouchFuncWall ) {
					EnableHamForward( g_hamTouchFuncWall );
				} else {
					g_hamTouchFuncWall = RegisterHam( Ham_Touch, "func_wall", "Ham_Touch_Wall_Pre", false );
				}
				
				if( g_hamTouchFuncBreakable ) {
					EnableHamForward( g_hamTouchFuncBreakable );
				} else {
					g_hamTouchFuncBreakable = RegisterHam( Ham_Touch, "func_breakable", "Ham_Touch_Wall_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamPlayerPreThink ) {
					EnableHamForward( g_hamPlayerPreThink );
				} else {
					g_hamPlayerPreThink = RegisterHam( Ham_Player_PreThink, "player", "Ham_Player_Prethink_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeDamagePlayer ) {
					EnableHamForward( g_hamTakeDamagePlayer );
				} else {
					g_hamTakeDamagePlayer = RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Player_Pre", false );
				}
				
				g_fwdAddToFullPack = register_forward( FM_AddToFullPack, "Forward_AddToFullPack_Post", 1 );
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTouchWorldSpawn ) {
					DisableHamForward( g_hamTouchWorldSpawn );
				}
				
				if( g_hamTouchFuncWall ) {
					DisableHamForward( g_hamTouchFuncWall );
				}
				
				if( g_hamTouchFuncBreakable ) {
					DisableHamForward( g_hamTouchFuncBreakable );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamPlayerPreThink ) {
					DisableHamForward( g_hamPlayerPreThink );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeDamagePlayer ) {
					DisableHamForward( g_hamTakeDamagePlayer );
				}
				
				unregister_forward( FM_AddToFullPack, 	g_fwdAddToFullPack, 1 );
			}
		}
		
		case DAY_ZOMBIE: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
			}
		}
		
		case DAY_SHARK: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeDamagePlayer ) {
					EnableHamForward( g_hamTakeDamagePlayer );
				} else {
					g_hamTakeDamagePlayer = RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Player_Pre", false );
				}
				
				g_fwdAddToFullPack = register_forward( FM_AddToFullPack, "Forward_AddToFullPack_Post", 1 );
				g_fwdCmdStart = register_forward( FM_CmdStart, "Forward_CmdStart_Pre", 0 );
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeDamagePlayer ) {
					DisableHamForward( g_hamTakeDamagePlayer );
				}
				
				unregister_forward( FM_AddToFullPack, g_fwdAddToFullPack, 1 );
				unregister_forward( FM_CmdStart, g_fwdCmdStart, 0 );
			}
		}
		
		case DAY_PRESIDENT: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
			}
		}
		
		case DAY_JUDGEMENT: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeDamagePlayer ) {
					EnableHamForward( g_hamTakeDamagePlayer );
				} else {
					g_hamTakeDamagePlayer = RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeDamagePlayer ) {
					DisableHamForward( g_hamTakeDamagePlayer );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
			}
		}
		
		case DAY_HNS: {
			if( bState ) {
				if( g_hamTakeDamagePlayer ) {
					EnableHamForward( g_hamTakeDamagePlayer );
				} else {
					g_hamTakeDamagePlayer = RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
			} else {
				if( g_hamTakeDamagePlayer ) {
					DisableHamForward( g_hamTakeDamagePlayer );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
			}
		}
		
		case DAY_LMS: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
			}
		}
		
		case DAY_NADEWAR: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamThinkGrenade ) {
					EnableHamForward( g_hamThinkGrenade );
				} else {
					g_hamThinkGrenade - RegisterHam( Ham_Think, "grenade", "Ham_Think_Grenade_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamThinkGrenade ) {
					DisableHamForward( g_hamThinkGrenade );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
			}
		}
		
		case DAY_SAMURAI: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeDamagePlayer ) {
					EnableHamForward( g_hamTakeDamagePlayer );
				} else {
					g_hamTakeDamagePlayer = RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Player_Pre", false );
				}
				
				g_fwdAddToFullPack = register_forward( FM_AddToFullPack, "Forward_AddToFullPack_Post", 1 );
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeDamagePlayer ) {
					DisableHamForward( g_hamTakeDamagePlayer );
				}
				
				unregister_forward( FM_AddToFullPack, g_fwdAddToFullPack, 1 );
			}
		}
		
		case DAY_KNIFE: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
			}
		}
		
		case DAY_SPACE: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
			}
		}
		
		case DAY_COWBOY: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
			}
		}
		
		case DAY_HULK: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamResetMaxSpeed ) {
					EnableHamForward( g_hamResetMaxSpeed );
				} else {
					g_hamResetMaxSpeed = RegisterHam( Ham_CS_Player_ResetMaxSpeed, "player", "Ham_ResetMaxSpeed_Player_Post", true );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamResetMaxSpeed ) {
					DisableHamForward( g_hamResetMaxSpeed );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
			}
		}
		
		case DAY_MARIO: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeDamagePlayer ) {
					EnableHamForward( g_hamTakeDamagePlayer );
				} else {
					g_hamTakeDamagePlayer = RegisterHam( Ham_TakeDamage, "player", "Ham_TakeDamage_Player_Pre", false );
				}
				
				g_fwdTouch = register_forward( FM_Touch, "Forward_Touch", 0 );
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeDamagePlayer ) {
					DisableHamForward( g_hamTakeDamagePlayer );
				}
				
				unregister_forward( FM_Touch, g_fwdTouch, 0 );
			}
		}
	}
}

SetLRHamHooks( iLR, bool:bState ) {
	switch( iLR ) {
		case LR_KNIFE: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
			}
		}
		
		case LR_WEAPONTOSS: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				g_fwdSetModel = register_forward( FM_SetModel, "Forward_SetModel", 0 );
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				unregister_forward( FM_SetModel, g_fwdSetModel, 0 );
			}
		}
		
		case LR_S4S: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
				
				/*
					Why are we not simply re enabling the forward like the others? Simply
					because in this case, each last request may be a different weapon. So
					we are registering it from the start. I think this is better than
					checking what was the previously hooked to weapon, and changing it when
					we have to.
				*/
				g_hamPrimaryAttack = RegisterHam( Ham_Weapon_PrimaryAttack, g_strWeapons[ S4S_WEAPON_1_STR + g_iLRChosenS4S ], "Ham_Weapon_PrimaryAttack_Post", true );
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
				
				if( g_hamPrimaryAttack ) {
					DisableHamForward( g_hamPrimaryAttack );
				}
			}
		}
		
		case LR_DUEL: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
			}
		}
		
		case LR_RACE: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
			}
		}
		
		case LR_HOTPOTATO: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
			}
		}
		
		case LR_GRENADETOSS: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamThinkGrenade ) {
					EnableHamForward( g_hamThinkGrenade );
				} else {
					g_hamThinkGrenade - RegisterHam( Ham_Think, "grenade", "Ham_Think_Grenade_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamThinkGrenade ) {
					DisableHamForward( g_hamThinkGrenade );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
			}
		}
		
		case LR_GLOCKER: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
			}
		}
		
		case LR_MANIAC: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
			}
		}
		
		case LR_KAMIKAZE: {
			if( bState ) {
				if( g_hamTouchWeaponbox ) {
					EnableHamForward( g_hamTouchWeaponbox );
				} else {
					g_hamTouchWeaponbox = RegisterHam( Ham_Touch, "weaponbox", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamTouchArmouryEntity ) {
					EnableHamForward( g_hamTouchArmouryEntity );
				} else {
					g_hamTouchArmouryEntity = RegisterHam( Ham_Touch, "armoury_entity", "Ham_Touch_Weapon_Pre", false );
				}
				
				if( g_hamAddPlayerItem ) {
					EnableHamForward( g_hamAddPlayerItem );
				} else {
					g_hamAddPlayerItem = RegisterHam( Ham_AddPlayerItem, "player", "Ham_AddPlayerItem_Player_Pre", false );
				}
				
				if( g_hamTakeHealthPlayer ) {
					EnableHamForward( g_hamTakeHealthPlayer );
				} else {
					g_hamTakeHealthPlayer = RegisterHam( Ham_TakeHealth, "player", "Ham_TakeHealth_Player_Pre", false );
				}
			} else {
				if( g_hamTouchWeaponbox ) {
					DisableHamForward( g_hamTouchWeaponbox );
				}
				
				if( g_hamTouchArmouryEntity ) {
					DisableHamForward( g_hamTouchArmouryEntity );
				}
				
				if( g_hamAddPlayerItem ) {
					DisableHamForward( g_hamAddPlayerItem );
				}
				
				if( g_hamTakeHealthPlayer ) {
					DisableHamForward( g_hamTakeHealthPlayer );
				}
			}
		}
	}
}

CheckIfLastPrisoner( ) {
	new iPlayers[ 32 ], iNum;
	get_players( iPlayers, iNum, "ae", "TERRORIST" );
	
	new iFreeDayCount = GetTeamPlayersNumber( "F" );
	
	new iNormalCounter = iNum - iFreeDayCount;
	
	if( iFreeDayCount && iNormalCounter <= 1 ) {
		new iTempID;
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			iTempID = iPlayers[ iLoop ];
			
			if( CheckBit( g_bitHasFreeDay, iTempID ) ) {
				ClearBit( g_bitHasFreeDay, iTempID );
				
				set_user_rendering( iTempID );
			}
		}
		
		client_print_color( 0, print_team_red, "^4%s^3 Prisoners^1 that have a personal Free Day do not have it anymore.", g_strPluginPrefix );
	}
	
	if( iNum == 1 ) {
		switch( g_iLastRequest ) {
			case 0: return 0;
			case 2: {
				switch( g_iDayCurrent ) {
					case DAY_CAGE, DAY_FREE, DAY_HNS: { }
					default: {
						return 0;
					}
				}
			}
		}
		
		EndDay( );
		
		g_iLRLastTerrorist = iPlayers[ 0 ];
		
		if( get_pcvar_num( g_pcvarLastRequestAutomatic ) ) {
			ClCmd_LastRequest( g_iLRLastTerrorist );
		} else {
			client_print_color( g_iLRLastTerrorist, print_team_red, "^4%s^1 You are the last ^3Prisoner^1 alive. You can now type ^4/lr^1 for your ^4Last Request^1.", g_strPluginPrefix );
		}
		
		if( get_pcvar_num( g_pcvarLastRequestMic ) ) {
			SetBit( g_bitHasMicPower, g_iLRLastTerrorist );
		}
		
		new strPlayerName[ 32 ];
		get_user_name( g_iLRLastTerrorist, strPlayerName, charsmax( strPlayerName ) );
		
		client_print_color( 0, print_team_red, "^4%s^1 Everything has been reset in preperation for ^3%s^1's ^4Last Request^1.", g_strPluginPrefix, strPlayerName );
		
		if( g_bGivePoints ) {
			g_iPlayerPoints[ g_iLRLastTerrorist ] += g_iPluginSettings[ POINTS_LR ];
			Event_Money( g_iLRLastTerrorist );
			
			client_print_color( g_iLRLastTerrorist, print_team_red, "^4%s^1 You have been awarded ^3%i point(s)^1 for getting ^4Last Request^1.", g_strPluginPrefix, g_iPluginSettings[ POINTS_LR ] );
		}
		
		return 1;
	}
	
	return 0;
}

SuicidePlayer( iPlayerID ) {
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

BlockPlayerSpawn( iPlayerID ) {
	static m_iNumRespawns = 365;
	set_pdata_int( iPlayerID, m_iNumRespawns, 1 );
}

PlayerTeam( iPlayerID, iTeam ) {
	if( iTeam ) {
		client_print_color( iPlayerID, print_team_red, "^4%s^1 You are now on the ^3Red^1 team.", g_strPluginPrefix );
		
		set_user_rendering( iPlayerID, kRenderFxGlowShell, 255, 0, 0, kRenderNormal, 5 );
		
		UTIL_ScreenFade( iPlayerID, { 255, 0, 0}, 2.0, 0.5, 100, FFADE_IN | FFADE_OUT );
	} else {
		client_print_color( iPlayerID, print_team_blue, "^4%s^1 You are not on the ^3Blue^1 team.", g_strPluginPrefix );
		
		set_user_rendering( iPlayerID, kRenderFxGlowShell, 0, 0, 255, kRenderNormal, 5 );
		
		UTIL_ScreenFade( iPlayerID, { 0, 0, 255 }, 2.0, 0.5, 100, FFADE_IN | FFADE_OUT );
	}
}

HamStripUserWeapon( iPlayerID, iWeaponID, iSlot = 0, bool:bSwitchIfActive = true ) {
	new iWeapon;
	
	if( !iSlot ) {
		static iWeaponsSlots[ ] = {
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
			1  //CSW_P90
		};
		
		iSlot = iWeaponsSlots[ iWeaponID ];
	}

	new XTRA_OFS_PLAYER = 5;
	new m_rgpPlayerItems_Slot0 = 367;

	iWeapon = get_pdata_cbase( iPlayerID, m_rgpPlayerItems_Slot0 + iSlot, XTRA_OFS_PLAYER );

	new XTRA_OFS_WEAPON = 4;
	new m_pNext = 42;
	new m_iId = 43;

	while( iWeapon > 0 ) {
		if( get_pdata_int( iWeapon, m_iId, XTRA_OFS_WEAPON ) == iWeaponID ) {
			break;
		}
		
		iWeapon = get_pdata_cbase( iWeapon, m_pNext, XTRA_OFS_WEAPON );
	}

	if( iWeapon > 0 ) {
		new m_pActiveItem = 373;
		
		if( bSwitchIfActive && get_pdata_cbase( iPlayerID, m_pActiveItem, XTRA_OFS_PLAYER ) == iWeapon ) {
			ExecuteHamB( Ham_Weapon_RetireWeapon, iWeapon );
		}

		if( ExecuteHamB( Ham_RemovePlayerItem, iPlayerID, iWeapon ) ) {
			user_has_weapon( iPlayerID, iWeaponID, 0 );
			ExecuteHamB( Ham_Item_Kill, iWeapon );
			
			return 1;
		}
	}

	return 0;
}

/* Knife Registration functions */
// RegisterKnives( ) {
	// RegisterBareHands( );
	// RegisterTaser( );
// }

// RegisterBareHands( ) {
	// g_iKnives[ KNIFE_BARE_HANDS ] = Knife_Register(
		// .WeaponName	= "Bare Hands",
		
		// .VModel		= g_strKnifeModels[ KNIFE_BARE_HANDS ][ 0 ],
		// .PModel		= g_strKnifeModels[ KNIFE_BARE_HANDS ][ 1 ],
		
		// .DeploySound	= g_strKnifeSounds[ KNIFE_BARE_HANDS ][ 0 ],
		// .SlashSound	= g_strKnifeSounds[ KNIFE_BARE_HANDS ][ 1 ],
		// .StabSound	= g_strKnifeSounds[ KNIFE_BARE_HANDS ][ 2 ],
		// .WhiffSound	= g_strKnifeSounds[ KNIFE_BARE_HANDS ][ 3 ],
		// .WallSound	= g_strKnifeSounds[ KNIFE_BARE_HANDS ][ 4 ]
	// );
	
	// Knife_SetProperty( g_iKnives[ KNIFE_BARE_HANDS ], KN_CLL_Droppable, false );
// }

// RegisterTaser( ) {
	// g_iKnives[ KNIFE_TASER ] = Knife_Register(
		// .WeaponName	= "Taser",
		
		// .VModel		= g_strKnifeModels[ KNIFE_TASER ][ 0 ],
		// .PModel		= g_strKnifeModels[ KNIFE_TASER ][ 1 ],
		
		// .DeploySound	= g_strKnifeSounds[ KNIFE_TASER ][ 0 ],
		// .SlashSound	= g_strKnifeSounds[ KNIFE_TASER ][ 1 ],
		// .StabSound	= g_strKnifeSounds[ KNIFE_TASER ][ 2 ],
		// .WhiffSound	= g_strKnifeSounds[ KNIFE_TASER ][ 3 ],
		// .WallSound	= g_strKnifeSounds[ KNIFE_TASER ][ 4 ]
	// );
// }

// GivePlayerKnife( iPlayerID, iKnife ) {
	// Knife_PlayerGive( iPlayerID, g_iKnives[ iKnife ] );
	
	// Knife_PlayerSetLock( iPlayerID, true );
// }

// CheckKnifePlugin( ) {
	// if( !is_plugin_loaded( "Knife API" ) ) {
		// set_fail_state( "This plugin cannot run without the Knife API plugin. Please check the main thread for more information." );
	// }
// }

/* Cell Doors button related functions */
OpenButtonsVault( ) {
	g_iVaultButtons = nvault_open( "UltimateJailBreak_Buttons" );
	
	if( g_iVaultButtons == INVALID_HANDLE ) {
		set_fail_state( "Could not open buttons vault." );
	}
}

SaveButtonsVault( strMapName[ ], strModelName[ ] ) {
	nvault_set( g_iVaultButtons, strMapName, strModelName );
}

GetButtonsVault( ) {
	new strMapName[ 32 ];
	get_mapname( strMapName, charsmax( strMapName ) );
	
	nvault_get( g_iVaultButtons , strMapName, g_strButtonModel, charsmax( g_strButtonModel ) );
}

CloseButtonsVault( ) {
	nvault_close( g_iVaultButtons );
}

SearchForButton( ) {
	new iEntity, strModelName[ 32 ];
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_button" ) ) > 0 ) {
		pev( iEntity, pev_model, strModelName, charsmax( strModelName ) );
		
		if( equal( strModelName, g_strButtonModel ) ) {
			g_iCellsButton = iEntity;
			
			return;
		}
	}
	
	while( ( iEntity = find_ent_by_class( iEntity, "func_rot_button" ) ) > 0 ) {
		pev( iEntity, pev_model, strModelName, charsmax( strModelName ) );
		
		if( equal( strModelName, g_strButtonModel ) ) {
			g_iCellsButton = iEntity;
			
			return;
		}
	}
	
	while( ( iEntity = find_ent_by_class( iEntity, "button_target" ) ) > 0 ) {
		pev( iEntity, pev_model, strModelName, charsmax( strModelName ) );
		
		if( equal( strModelName, g_strButtonModel ) ) {
			g_iCellsButton = iEntity;
			
			return;
		}
	}
}

OpenCells( ) {
	if( g_iOpenCommand ) {
		PushButton( );
	}
}

PushButton( ) {
	if( g_iCellsButton ) {
		ExecuteHamB( Ham_Use, g_iCellsButton, 0, 0, 1, 1.0 );
		entity_set_float( g_iCellsButton, EV_FL_frame, 0.0 );
	}
}

/* Player Time related functions */
OpenTimeVault( ) {
	g_iVaultTime = nvault_open( "UltimateJailBreak_Time" );
	
	if( g_iVaultTime == INVALID_HANDLE ) {
		set_fail_state( "Could not open time vault." );
	}
}

GetPlayerTime( iPlayerID ) {
	new strPlayerAuthID[ 36 ];
	get_user_authid( iPlayerID, strPlayerAuthID, charsmax( strPlayerAuthID ) );
	
	new strFormatex[ 64 ];
	formatex( strFormatex, charsmax( strFormatex ), "%s-TIME", strPlayerAuthID );
	
	g_iPlayerTime[ iPlayerID ] = nvault_get( g_iVaultTime, strFormatex );
}

SavePlayerTime( iPlayerID ) {
	if( !iPlayerID ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			SavePlayerTime( iPlayers[ iLoop ] );
		}
	} else {
		new strPlayerAuthID[ 36 ];
		get_user_authid( iPlayerID, strPlayerAuthID, charsmax( strPlayerAuthID ) );
		
		new strFormatex[ 64 ];
		formatex( strFormatex, charsmax( strFormatex ), "%s-TIME", strPlayerAuthID );
		
		new strTime[ 16 ];
		formatex( strTime, charsmax( strTime ), "%i", g_iPlayerTime[ iPlayerID ] + get_user_time( iPlayerID ) / 60 );
		
		nvault_set( g_iVaultTime, strFormatex, strTime );
	}
}

CloseTimeVault( ) {
	nvault_close( g_iVaultTime );
}

/* Player Points related functions */
OpenPointsVault( ) {
	g_iVaultPoints = nvault_open( "UltimateJailBreak_Points" );
	
	if( g_iVaultPoints == INVALID_HANDLE ) {
		set_fail_state( "Could not open points vault." );
	}
}

GetPlayerPoints( iPlayerID ) {
	new strPlayerAuthID[ 36 ];
	get_user_authid( iPlayerID, strPlayerAuthID, charsmax( strPlayerAuthID ) );
	
	new strFormatex[ 64 ];
	formatex( strFormatex, charsmax( strFormatex ), "%s-POINTS", strPlayerAuthID );
	
	g_iPlayerPoints[ iPlayerID ] = nvault_get( g_iVaultPoints, strFormatex );
}

SavePlayerPoints( iPlayerID ) {
	if( !iPlayerID ) {
		new iPlayers[ 32 ], iNum;
		get_players( iPlayers, iNum );
		
		for( new iLoop = 0; iLoop < iNum; iLoop++ ) {
			SavePlayerPoints( iPlayers[ iLoop ] );
		}
	} else {
		new strPlayerAuthID[ 36 ];
		get_user_authid( iPlayerID, strPlayerAuthID, charsmax( strPlayerAuthID ) );
		
		new strFormatex[ 64 ];
		formatex( strFormatex, charsmax( strFormatex ), "%s-POINTS", strPlayerAuthID );
		
		new strPoints[ 16 ];
		formatex( strFormatex, charsmax( strFormatex ), "%i", g_iPlayerPoints[ iPlayerID ] );
		
		nvault_set( g_iVaultPoints, strFormatex, strPoints );
	}
}

ClosePointsVault( ) {
	nvault_close( g_iVaultPoints );
}

/* CT Ban related functions */
OpenCTBanVault( ) {
	g_iVaultCTBan = nvault_open( "UltimateJailBreak_CTBan" );
	
	if( g_iVaultCTBan == INVALID_HANDLE ) {
		set_fail_state( "Could not open ct ban vault." );
	}
}

GetPlayerCTBan( iPlayerID ) {
	new strPlayerAuthID[ 36 ];
	get_user_authid( iPlayerID, strPlayerAuthID, charsmax( strPlayerAuthID ) );
	
	new strFormatex[ 64 ];
	formatex( strFormatex, charsmax( strFormatex ), "%s-CTBAN", strPlayerAuthID );
	
	if( nvault_get( g_iVaultCTBan, strFormatex ) == 1 ) {
		SetBit( g_bitIsCTBanned, iPlayerID );
	} else {
		ClearBit( g_bitIsCTBanned, iPlayerID );
	}
}

CloseCTBanVault( ) {
	nvault_close( g_iVaultCTBan );
}

/* Free For All */
#if !defined _free_for_all
#define _free_for_all

#define fm_get_user_team(%1)		get_pdata_int(%1,114)
#define fm_set_user_team(%1,%2)		set_pdata_int(%1,114,%2)

new HamHook:g_hFFATraceAttack;
new HamHook:g_hFFATakeDamage;
new HamHook:g_hFFAKilled;
new g_mRadarHook;

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

public ClCmd_DrawRadar( iPlayerID ) {
	return _:g_bFFA;
}
#endif

/* ScreenFade Utility */
#if !defined _screenfade_included
#define _screenfade_included

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
	if( !is_user_connected( iPlayerID ) ) {
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