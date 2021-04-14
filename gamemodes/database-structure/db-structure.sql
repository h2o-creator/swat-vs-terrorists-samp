-- Adminer 4.7.7 MySQL dump

SET NAMES utf8;
SET time_zone = '+00:00';
SET foreign_key_checks = 0;
SET GLOBAL sql_mode = 'NO_AUTO_VALUE_ON_ZERO';

SET NAMES utf8mb4;

DROP TABLE IF EXISTS `BansData`;
CREATE TABLE `BansData` (
  `BanId` int(11) NOT NULL AUTO_INCREMENT,
  `BannedName` TEXT(24) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `AdminName` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `BanReason` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ExpiryDate` int(11) DEFAULT NULL,
  `BanDate` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`BanId`),
  UNIQUE KEY `BannedName` (`BannedName`(24))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `BansHistoryData`;
CREATE TABLE `BansHistoryData` (
  `BanId` int(11) NOT NULL AUTO_INCREMENT,
  `BannedName` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `AdminName` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `BanReason` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ExpiryDate` int(11) DEFAULT NULL,
  `BanDate` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`BanId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `ClanLog`;
CREATE TABLE `ClanLog` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `cID` int(11) NOT NULL DEFAULT '-1',
  `Member` TEXT DEFAULT NULL,
  `Rank` int(11) DEFAULT NULL,
  `Action` TEXT DEFAULT NULL,
  `Date` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;


DROP TABLE IF EXISTS `ClansData`;
CREATE TABLE `ClansData` (
  `ClanId` int(11) NOT NULL AUTO_INCREMENT,
  `ClanName` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ClanTag` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ClanOwner` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ClanMotd` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ClanWeap` int(11) NOT NULL DEFAULT '0',
  `ClanWallet` int(11) NOT NULL DEFAULT '0',
  `ClanKills` int(11) NOT NULL DEFAULT '0',
  `ClanDeaths` int(11) NOT NULL DEFAULT '0',
  `ClanPoints` int(11) NOT NULL DEFAULT '0',
  `Rank1` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Rank2` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Rank3` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Rank4` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Rank5` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Rank6` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Rank7` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Rank8` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Rank9` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Rank10` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ClanLevel` int(11) NOT NULL DEFAULT '0',
  `ClanSkin` int(11) NOT NULL DEFAULT '0',
  `InviteClanLevel` int(11) NOT NULL DEFAULT '10',
  `ClanWarLevel` int(11) NOT NULL DEFAULT '10',
  `ClanPermsLevel` int(11) NOT NULL DEFAULT '10',
  PRIMARY KEY (`ClanId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `CWParties`;
CREATE TABLE `CWParties` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `pID` int(11) DEFAULT NULL,
  `cID` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `pID` (`pID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `Dogfights`;
CREATE TABLE `Dogfights` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `FirstOppID` int(11) DEFAULT NULL,
  `WinnerID` int(11) DEFAULT NULL,
  `SecondOppVHP` float DEFAULT NULL,
  `DogfightVID` int(11) DEFAULT NULL,
  `DogfightTL` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `ForbiddenList`;
CREATE TABLE `ForbiddenList` (
  `ForbidId` int(11) NOT NULL AUTO_INCREMENT,
  `Type` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Text` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`ForbidId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `IgnoreList`;
CREATE TABLE `IgnoreList` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `BlockerId` int(11) DEFAULT NULL,
  `BlockedId` int(11) DEFAULT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `Players`;
CREATE TABLE `Players` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Username` TEXT(24) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Password` TEXT COLLATE utf8mb4_unicode_ci NULL,
  `Salt` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `IP` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `GPCI` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Coins` int(11) NOT NULL DEFAULT '0',
  `RegDate` int(11) NOT NULL DEFAULT '0',
  `LastVisit` int(11) NOT NULL DEFAULT '0',
  `PlayTime` int(11) NOT NULL DEFAULT '0',
  `ClanId` int(11) NOT NULL DEFAULT '-1',
  `ClanRank` int(11) NOT NULL DEFAULT '0',
  `IsBanned` int(11) NOT NULL DEFAULT '0',
  `Warnings` int(11) NOT NULL DEFAULT '0',
  `AdminLevel` int(11) NOT NULL DEFAULT '0',
  `TimesLoggedIn` int(11) NOT NULL DEFAULT '0',
  `AntiCheatWarnings` int(11) NOT NULL DEFAULT '0',
  `PlayerReports` int(11) NOT NULL DEFAULT '0',
  `SpamAttempts` int(11) NOT NULL DEFAULT '0',
  `AdvAttempts` int(11) NOT NULL DEFAULT '0',
  `AntiSwearBlocks` int(11) NOT NULL DEFAULT '0',
  `TagPermitted` int(11) NOT NULL DEFAULT '0',
  `ReportAttempts` int(11) NOT NULL DEFAULT '0',
  `BannedTimes` int(11) NOT NULL DEFAULT '0',
  `DonorLevel` int(11) NOT NULL DEFAULT '0',
  `SupportKey` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ID`),
  UNIQUE KEY `Username` (`Username`(24))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `PlayersConf`;
CREATE TABLE `PlayersConf` (
  `pID` int(11) DEFAULT NULL,
  `DoNotDisturb` int(11) NOT NULL DEFAULT '0',
  `NoDuel` int(11) NOT NULL DEFAULT '0',
  `HitIndicator` int(11) NOT NULL DEFAULT '1',
  `GUIEnabled` int(11) NOT NULL DEFAULT '1',
  `WeaponBodyToys` int(11) NOT NULL DEFAULT '1',
  `SpawnKillTime` int(11) NOT NULL DEFAULT '7',
  `UseHelmet` int(11) NOT NULL DEFAULT '1',
  `UseGasMask` int(11) NOT NULL DEFAULT '1',
  `AllowWatch` int(11) NOT NULL DEFAULT '0',
  `NoDogfights` int(11) NOT NULL DEFAULT '0',
  `NoTutor` int(11) NOT NULL DEFAULT '0',
  UNIQUE KEY `pID` (`pID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `PlayersData`;
CREATE TABLE `PlayersData` (
  `pID` int(11) DEFAULT NULL,
  `Score` bigint(11) NOT NULL DEFAULT '0',
  `Cash` bigint(11) NOT NULL DEFAULT '0',
  `Kills` int(11) NOT NULL DEFAULT '0',
  `Deaths` int(11) NOT NULL DEFAULT '0',
  `GunFires` int(11) NOT NULL DEFAULT '0',
  `IsJailed` int(11) NOT NULL DEFAULT '0',
  `JailTime` int(11) NOT NULL DEFAULT '0',
  `Headshots` int(11) NOT NULL DEFAULT '0',
  `Nutshots` int(11) NOT NULL DEFAULT '0',
  `KnifeKills` int(11) NOT NULL DEFAULT '0',
  `RevengeTakes` int(11) NOT NULL DEFAULT '0',
  `JackpotsFound` int(11) NOT NULL DEFAULT '0',
  `DeathmatchKills` int(11) NOT NULL DEFAULT '0',
  `RustlerRockets` int(11) NOT NULL DEFAULT '0',
  `RustlerRocketsHit` int(11) NOT NULL DEFAULT '0',
  `DuelsWon` int(11) NOT NULL DEFAULT '0',
  `DuelsLost` int(11) NOT NULL DEFAULT '0',
  `MedkitsUsed` int(11) NOT NULL DEFAULT '0',
  `ArmourkitsUsed` int(11) NOT NULL DEFAULT '0',
  `SupportAttempts` int(11) NOT NULL DEFAULT '0',
  `EXP` int(11) NOT NULL DEFAULT '0',
  `KillAssists` int(11) NOT NULL DEFAULT '0',
  `CaptureAssists` int(11) NOT NULL DEFAULT '0',
  `HighestKillStreak` int(11) NOT NULL DEFAULT '0',
  `SawedKills` int(11) NOT NULL DEFAULT '0',
  `AirRocketsFired` int(11) NOT NULL DEFAULT '0',
  `AntiAirRocketsFired` int(11) NOT NULL DEFAULT '0',
  `CarePackagesDropped` int(11) NOT NULL DEFAULT '0',
  `DamageRate` float NOT NULL DEFAULT '0',
  `HealthLost` float NOT NULL DEFAULT '0',
  `SMGKills` int(11) NOT NULL DEFAULT '0',
  `ShotgunKills` int(11) NOT NULL DEFAULT '0',
  `HeavyKills` int(11) NOT NULL DEFAULT '0',
  `MeleeKills` int(11) NOT NULL DEFAULT '0',
  `PistolKills` int(11) NOT NULL DEFAULT '0',
  `FistKills` int(11) NOT NULL DEFAULT '0',
  `CloseKills` int(11) NOT NULL DEFAULT '0',
  `DriversStabbed` int(11) NOT NULL DEFAULT '0',
  `SpiesEliminated` int(11) NOT NULL DEFAULT '0',
  `KillsAsSpy` int(11) NOT NULL DEFAULT '0',
  `LongDistanceKills` int(11) NOT NULL DEFAULT '0',
  `WeaponsDropped` int(11) NOT NULL DEFAULT '0',
  `WeaponsPicked` int(11) NOT NULL DEFAULT '0',
  `EventsWon` int(11) NOT NULL DEFAULT '0',
  `RacesWon` int(11) NOT NULL DEFAULT '0',
  `ItemsUsed` int(11) NOT NULL DEFAULT '0',
  `FavSkin` int(11) NOT NULL DEFAULT '0',
  `FavTeam` int(11) NOT NULL DEFAULT '0',
  `SuicideAttempts` int(11) NOT NULL DEFAULT '0',
  `PlayersHealed` int(11) NOT NULL DEFAULT '0',
  `CommandsUsed` int(11) NOT NULL DEFAULT '0',
  `CommandsFailed` int(11) NOT NULL DEFAULT '0',
  `UnauthorizedActions` int(11) NOT NULL DEFAULT '0',
  `RCONLogins` int(11) NOT NULL DEFAULT '0',
  `RCONFailedAttempts` int(11) NOT NULL DEFAULT '0',
  `ClassAbilitiesUsed` int(11) NOT NULL DEFAULT '0',
  `DronesExploded` int(11) NOT NULL DEFAULT '0',
  `HealthGained` float NOT NULL DEFAULT '0',
  `ZonesCaptured` int(11) NOT NULL DEFAULT '0',
  `InteriorsEntered` int(11) NOT NULL DEFAULT '0',
  `InteriorsExitted` int(11) NOT NULL DEFAULT '0',
  `PickupsPicked` int(11) NOT NULL DEFAULT '0',
  `HousesPurchased` int(11) NOT NULL DEFAULT '0',
  `QuestionsAsked` int(11) NOT NULL DEFAULT '0',
  `QuestionsAnswered` int(11) NOT NULL DEFAULT '0',
  `CrashTimes` int(11) NOT NULL DEFAULT '0',
  `SAMPClient` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `BackupAttempts` int(11) NOT NULL DEFAULT '0',
  `BackupsResponded` int(11) NOT NULL DEFAULT '0',
  `BaseRapeAttempts` int(11) NOT NULL DEFAULT '0',
  `ChatMessagesSent` int(11) NOT NULL DEFAULT '0',
  `MoneySent` int(11) NOT NULL DEFAULT '0',
  `MoneyReceived` int(11) NOT NULL DEFAULT '0',
  `HighestBet` int(11) NOT NULL DEFAULT '0',
  `DuelRequests` int(11) NOT NULL DEFAULT '0',
  `DuelsAccepted` int(11) NOT NULL DEFAULT '0',
  `DuelsRefusedByPlayer` int(11) NOT NULL DEFAULT '0',
  `DuelsRefusedByOthers` int(11) NOT NULL DEFAULT '0',
  `BountyAmount` int(11) NOT NULL DEFAULT '0',
  `BountyCashSpent` int(11) NOT NULL DEFAULT '0',
  `CoinsSpent` int(11) NOT NULL DEFAULT '0',
  `PaymentsAccepted` int(11) NOT NULL DEFAULT '0',
  `ClanKills` int(11) NOT NULL DEFAULT '0',
  `ClanDeaths` int(11) NOT NULL DEFAULT '0',
  `AchsUnlocked` int(11) NOT NULL DEFAULT '0',
  `HighestCaptures` int(11) NOT NULL DEFAULT '0',
  `KicksByAdmin` int(11) NOT NULL DEFAULT '0',
  `LongestKillDistance` float NOT NULL DEFAULT '0',
  `NearestKillDistance` float NOT NULL DEFAULT '0',
  `HighestCaptureAssists` int(11) NOT NULL DEFAULT '0',
  `HighestKillAssists` int(11) NOT NULL DEFAULT '0',
  `BountyPlayersKilled` int(11) NOT NULL DEFAULT '0',
  `ChallengesWon` int(11) NOT NULL DEFAULT '0',
  `MissionsCompleted` int(11) NOT NULL DEFAULT '0',
  `PrototypesStolen` int(11) NOT NULL DEFAULT '0',
  `AntennasDestroyed` int(11) NOT NULL DEFAULT '0',
  `CratesOpened` int(11) NOT NULL DEFAULT '0',
  `LastPing` int(11) NOT NULL DEFAULT '0',
  `LastPacketLoss` float NOT NULL DEFAULT '0',
  `HighestPing` int(11) NOT NULL DEFAULT '0',
  `LowestPing` int(11) NOT NULL DEFAULT '0',
  `NukesLaunched` int(11) NOT NULL DEFAULT '0',
  `AirstrikesCalled` int(11) NOT NULL DEFAULT '0',
  `FlashBangedPlayers` int(11) NOT NULL DEFAULT '0',
  `AnthraxIntoxications` int(11) NOT NULL DEFAULT '0',
  `PUBGEventsWon` int(11) NOT NULL DEFAULT '0',
  `SafesRobbed` int(11) NOT NULL DEFAULT '0',
  `RopeRappels` int(11) NOT NULL DEFAULT '0',
  `AreasEntered` int(11) NOT NULL DEFAULT '0',
  `LastAreaId` int(11) NOT NULL DEFAULT '0',
  `LastPosX` float NOT NULL DEFAULT '0',
  `LastPosY` float NOT NULL DEFAULT '0',
  `LastPosZ` float NOT NULL DEFAULT '0',
  `LastHealth` float NOT NULL DEFAULT '0',
  `LastArmour` float NOT NULL DEFAULT '0',
  `TimeSpentOnFoot` int(11) NOT NULL DEFAULT '0',
  `TimeSpentInCar` int(11) NOT NULL DEFAULT '0',
  `TimeSpentAsPassenger` int(11) NOT NULL DEFAULT '0',
  `TimeSpentInSelection` int(11) NOT NULL DEFAULT '0',
  `TimeSpentAFK` int(11) NOT NULL DEFAULT '0',
  `DriveByKills` int(11) NOT NULL DEFAULT '0',
  `MathCalculations` int(11) NOT NULL DEFAULT '0',
  `CashAdded` bigint(11) NOT NULL DEFAULT '0',
  `CashReduced` bigint(11) NOT NULL DEFAULT '0',
  `LastInterior` int(11) NOT NULL DEFAULT '0',
  `LastVirtualWorld` int(11) NOT NULL DEFAULT '0',
  UNIQUE KEY `pID` (`pID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

DROP TABLE IF EXISTS `PlayersReports`;
CREATE TABLE `PlayersReports` (
  `Id` int(11) NOT NULL AUTO_INCREMENT,
  `Reporter` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ReportedPlayer` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Reason` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `DateIssued` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  PRIMARY KEY (`Id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `Punishments`;
CREATE TABLE `Punishments` (
  `ActionId` int(11) NOT NULL AUTO_INCREMENT,
  `PunishedPlayer` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Punisher` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `Action` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ActionReason` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `PunishmentTime` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `ActionDate` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`ActionId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `RacesCheckpoints`;
CREATE TABLE `RacesCheckpoints` (
  `RaceId` int(11) DEFAULT NULL,
  `RX` float DEFAULT NULL,
  `RY` float DEFAULT NULL,
  `RZ` float DEFAULT NULL,
  `RType` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `RacesData`;
CREATE TABLE `RacesData` (
  `RaceId` int(11) NOT NULL AUTO_INCREMENT,
  `RaceName` TEXT(30) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RaceMaker` TEXT COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `RaceVehicle` int(11) NOT NULL DEFAULT '-1',
  `RaceInt` int(11) NOT NULL DEFAULT '0',
  `RaceWorld` int(11) NOT NULL DEFAULT '0',
  `RaceDate` int(11) NOT NULL DEFAULT '0',
  PRIMARY KEY (`RaceId`),
  UNIQUE KEY `RaceName` (`RaceName`(30))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `RacesSpawnPoints`;
CREATE TABLE `RacesSpawnPoints` (
  `RaceId` int(11) DEFAULT NULL,
  `RX` float DEFAULT NULL,
  `RY` float DEFAULT NULL,
  `RZ` float DEFAULT NULL,
  `RRot` float NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;


DROP TABLE IF EXISTS `Achievements`;
CREATE TABLE `Achievements` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `AchName` TEXT(25) DEFAULT NULL,
  `AchDesc` TEXT DEFAULT NULL,
  `AchScore` int(11) NOT NULL DEFAULT 0,
  `AchCash` int(11) NOT NULL DEFAULT 0,
  `AchValue` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`),
  UNIQUE KEY `AchName` (`AchName`(25))
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `PlayersAchievements`;
CREATE TABLE `PlayersAchievements` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `PlayerId` int(11) DEFAULT NULL,
  `AchId` int(11) DEFAULT NULL,
  `AchValue` int(11) NOT NULL DEFAULT 0,
  PRIMARY KEY (`ID`),
  UNIQUE KEY (`PlayerId`),
  UNIQUE KEY (`AchId`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `Messages_Log`;
CREATE TABLE `Messages_Log` ( 
  `ID` int(11) NOT NULL AUTO_INCREMENT, 
  `Sender` int(11) DEFAULT NULL, 
  `Receiver` int(11) DEFAULT NULL, 
  `Message` TEXT DEFAULT NULL, 
  `Time` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE = InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `Commands_Log`;
CREATE TABLE `Commands_Log` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Sender` int(11) DEFAULT NULL,
  `Command` TEXT DEFAULT NULL,
  `Parameters` TEXT DEFAULT NULL,
  `Flags` int(11) DEFAULT NULL,
  `Time` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `Anticheat_Log`;
CREATE TABLE `Anticheat_Log` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Suspect` int(11) DEFAULT NULL,
  `Cheat` TEXT DEFAULT NULL,
  `Time` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `Connections_Log`;
CREATE TABLE `Connections_Log` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Player` int(11) DEFAULT NULL,
  `Reason` int(11) DEFAULT NULL,
  `Time` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `Activity_Log`;
CREATE TABLE `Activity_Log` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Player` int(11) DEFAULT NULL,
  `Action` TEXT DEFAULT NULL,
  `Time` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `PlayersWeapons`;
CREATE TABLE `PlayersWeapons` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Player` int(11) DEFAULT NULL,
  `Weapon` int(11) DEFAULT NULL,
  `Ammo` int(11) DEFAULT NULL,
  `Time` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `PlayersItems`;
CREATE TABLE `PlayersItems` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `Player` int(11) DEFAULT NULL,
  `Item` int(11) DEFAULT NULL,
  `Qty` int(11) DEFAULT NULL,
  `Time` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


DROP TABLE IF EXISTS `ZonesTransactions`;
CREATE TABLE `ZonesTransactions` (
  `ID` int(11) NOT NULL AUTO_INCREMENT,
  `TeamId` int(11) DEFAULT NULL,
  `ZoneId` int(11) DEFAULT NULL,
  `Investment` int(11) DEFAULT NULL,
  `Expiry` int(11) DEFAULT NULL,
  `Date` int(11) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4;


-- 2020-07-06 14:30:22