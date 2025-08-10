local loaders = {}

-- Priest
loaders.PRIEST = function(engine)
  -- Common / utility
  require('spell_db/priest/21562_Power_Word_Fortitude')(engine)
  require('spell_db/priest/17_Power_Word_Shield')(engine)

  -- Holy / Disc healing toolkit
  require('spell_db/priest/33076_Prayer_of_Mending')(engine)
  require('spell_db/priest/2050_Holy_Word_Serenity')(engine)
  require('spell_db/priest/88684_Holy_Word_Sanctify')(engine)
  require('spell_db/priest/2060_Heal')(engine)
  require('spell_db/priest/2061_Flash_Heal')(engine)
  require('spell_db/priest/139_Renew')(engine)
  require('spell_db/priest/527_Purify')(engine)
  require('spell_db/priest/32375_Mass_Dispel')(engine)
  require('spell_db/priest/73325_Leap_of_Faith')(engine)

  -- Damage (all/holy/disc baseline)
  require('spell_db/priest/88625_Holy_Word_Chastise')(engine)
  require('spell_db/priest/14914_Holy_Fire')(engine)
  require('spell_db/priest/589_Shadow_Word_Pain')(engine)
  require('spell_db/priest/585_Smite')(engine)
  require('spell_db/priest/528_Dispel_Magic')(engine)

  -- Discipline signature
  require('spell_db/priest/47540_Penance')(engine)
  require('spell_db/priest/194509_Power_Word_Radiance')(engine)
  require('spell_db/priest/33206_Pain_Suppression')(engine)
  require('spell_db/priest/62618_Power_Word_Barrier')(engine)
  require('spell_db/priest/47536_Rapture')(engine)

  -- Shadow kit
  require('spell_db/priest/34914_Vampiric_Touch')(engine)
  require('spell_db/priest/8092_Mind_Blast')(engine)
  require('spell_db/priest/15407_Mind_Flay')(engine)
  require('spell_db/priest/34433_Shadowfiend')(engine)
  require('spell_db/priest/32379_Shadow_Word_Death')(engine)
  require('spell_db/priest/48045_Mind_Sear')(engine)
  require('spell_db/priest/335467_Devouring_Plague')(engine)
  require('spell_db/priest/228260_Void_Eruption')(engine)
  require('spell_db/priest/15286_Vampiric_Embrace')(engine)
  require('spell_db/priest/47585_Dispersion')(engine)
  require('spell_db/priest/15487_Silence')(engine)
  require('spell_db/priest/15473_Shadowform')(engine)

  -- Utility / defensives
  require('spell_db/priest/586_Fade')(engine)
  require('spell_db/priest/19236_Desperate_Prayer')(engine)
  require('spell_db/priest/10060_Power_Infusion')(engine)
  require('spell_db/priest/596_Prayer_of_Healing')(engine)
  require('spell_db/priest/64843_Divine_Hymn')(engine)
  require('spell_db/priest/47788_Guardian_Spirit')(engine)
  require('spell_db/priest/132157_Holy_Nova')(engine)
  require('spell_db/priest/2006_Resurrection')(engine)
end

-- Warrior
loaders.WARRIOR = function(engine)
  -- Buffs / engage
  require('spell_db/warrior/6673_Battle_Shout')(engine)
  require('spell_db/warrior/100_Charge')(engine)

  -- Arms / Fury DPS
  require('spell_db/warrior/772_Rend')(engine)
  require('spell_db/warrior/12294_Mortal_Strike')(engine)
  require('spell_db/warrior/7384_Overpower')(engine)
  require('spell_db/warrior/1464_Slam')(engine)
  require('spell_db/warrior/1680_Whirlwind')(engine)
  require('spell_db/warrior/5308_Execute')(engine)
  require('spell_db/warrior/34428_Victory_Rush')(engine)
  require('spell_db/warrior/6552_Pummel')(engine)
  require('spell_db/warrior/184367_Rampage')(engine)
  require('spell_db/warrior/1680_Warbreaker')(engine)
  require('spell_db/warrior/1719_Recklessness')(engine)
  require('spell_db/warrior/107574_Avatar')(engine)

  -- Protection
  require('spell_db/warrior/2565_Shield_Block')(engine)
  require('spell_db/warrior/23922_Shield_Slam')(engine)
  require('spell_db/warrior/6572_Revenge')(engine)
  require('spell_db/warrior/6343_Thunder_Clap')(engine)
  require('spell_db/warrior/355_Taunt')(engine)
  require('spell_db/warrior/1160_Demoralizing_Shout')(engine)
  require('spell_db/warrior/871_Shield_Wall')(engine)
  require('spell_db/warrior/12975_Last_Stand')(engine)
  require('spell_db/warrior/97462_Rallying_Cry')(engine)
  require('spell_db/warrior/190456_Ignore_Pain')(engine)
  require('spell_db/warrior/23920_Spell_Reflection')(engine)
end

-- Mage
loaders.MAGE = function(engine)
  require('spell_db/mage/1459_Arcane_Intellect')(engine)
  require('spell_db/mage/118_Polymorph')(engine)
  require('spell_db/mage/116_Slow_Fall')(engine)
  require('spell_db/mage/30451_Arcane_Blast')(engine)
  require('spell_db/mage/2139_Counterspell')(engine)
  require('spell_db/mage/133_Fireball')(engine)
  require('spell_db/mage/116_Frostbolt')(engine)
  require('spell_db/mage/30455_Ice_Lance')(engine)
  require('spell_db/mage/84714_Frozen_Orb')(engine)
  require('spell_db/mage/45438_Ice_Block')(engine)
  require('spell_db/mage/190319_Combustion')(engine)
  require('spell_db/mage/257541_Phoenix_Flames')(engine)
  require('spell_db/mage/11426_Ice_Barrier')(engine)
  require('spell_db/mage/1953_Blink')(engine)
  require('spell_db/mage/31661_Dragons_Breath')(engine)
  require('spell_db/mage/12472_Icy_Veins')(engine)
  require('spell_db/mage/108853_Fire_Blast')(engine)
  require('spell_db/mage/55342_Mirror_Image')(engine)
  require('spell_db/mage/321507_Touch_of_the_Magi')(engine)
end

-- Paladin
loaders.PALADIN = function(engine)
  require('spell_db/paladin/96231_Rebuke')(engine)
  require('spell_db/paladin/633_Lay_on_Hands')(engine)
  require('spell_db/paladin/1022_Blessing_of_Protection')(engine)
  require('spell_db/paladin/853_Hammer_of_Justice')(engine)
  require('spell_db/paladin/20271_Judgment')(engine)
  require('spell_db/paladin/26573_Consecration')(engine)
  require('spell_db/paladin/35395_Crusader_Strike')(engine)
  require('spell_db/paladin/31884_Avenging_Wrath')(engine)
  require('spell_db/paladin/20066_Repentance')(engine)
  require('spell_db/paladin/642_Divine_Shield')(engine)
  require('spell_db/paladin/31935_Avengers_Shield')(engine)
  require('spell_db/paladin/53600_Shield_of_the_Righteous')(engine)
  require('spell_db/paladin/85673_Word_of_Glory')(engine)
  require('spell_db/paladin/86659_Guardian_of_Ancient_Kings')(engine)
  require('spell_db/paladin/6940_Blessing_of_Sacrifice')(engine)
  require('spell_db/paladin/20473_Holy_Shock')(engine)
  require('spell_db/paladin/85222_Light_of_Dawn')(engine)
  require('spell_db/paladin/19750_Flash_of_Light')(engine)
  require('spell_db/paladin/184575_Blade_of_Justice')(engine)
  require('spell_db/paladin/85256_Templars_Verdict')(engine)
  require('spell_db/paladin/255937_Wake_of_Ashes')(engine)
  require('spell_db/paladin/184662_Shield_of_Vengeance')(engine)
  require('spell_db/paladin/31850_Ardent_Defender')(engine)
  require('spell_db/paladin/31821_Aura_Mastery')(engine)
  require('spell_db/paladin/1044_Blessing_of_Freedom')(engine)
  require('spell_db/paladin/190784_Divine_Steed')(engine)
  require('spell_db/paladin/62124_Hand_of_Reckoning')(engine)
  require('spell_db/paladin/24275_Hammer_of_Wrath')(engine)
  require('spell_db/paladin/82326_Holy_Light')(engine)
  require('spell_db/paladin/183998_Light_of_the_Martyr')(engine)
end

-- Hunter
loaders.HUNTER = function(engine)
  require('spell_db/hunter/147362_Counter_Shot')(engine)
  require('spell_db/hunter/5384_Feign_Death')(engine)
  require('spell_db/hunter/186257_Aspect_of_the_Cheetah')(engine)
  require('spell_db/hunter/34477_Misdirection')(engine)
  require('spell_db/hunter/186270_Raptor_Strike')(engine)
  require('spell_db/hunter/34026_Kill_Command')(engine)
  require('spell_db/hunter/193455_Cobra_Shot')(engine)
  require('spell_db/hunter/257044_Rapid_Fire')(engine)
  require('spell_db/hunter/19434_Aimed_Shot')(engine)
  require('spell_db/hunter/185358_Arcane_Shot')(engine)
  require('spell_db/hunter/257620_Multi_Shot')(engine)
  require('spell_db/hunter/186265_Aspect_of_the_Turtle')(engine)
  require('spell_db/hunter/109304_Exhilaration')(engine)
  require('spell_db/hunter/19574_Bestial_Wrath')(engine)
  require('spell_db/hunter/193530_Aspect_of_the_Wild')(engine)
  require('spell_db/hunter/53351_Kill_Shot')(engine)
end

-- Rogue
loaders.ROGUE = function(engine)
  require('spell_db/rogue/1766_Kick')(engine)
  require('spell_db/rogue/1784_Stealth')(engine)
  require('spell_db/rogue/185763_Pistol_Shot')(engine)
  require('spell_db/rogue/2098_Eviscerate')(engine)
  require('spell_db/rogue/53_Backstab')(engine)
  require('spell_db/rogue/31224_Cloak_of_Shadows')(engine)
  require('spell_db/rogue/1966_Feint')(engine)
  require('spell_db/rogue/185311_Crimson_Vial')(engine)
  require('spell_db/rogue/36554_Shadowstep')(engine)
  require('spell_db/rogue/1856_Vanish')(engine)
  require('spell_db/rogue/2983_Sprint')(engine)
  require('spell_db/rogue/408_Kidney_Shot')(engine)
  require('spell_db/rogue/1833_Cheap_Shot')(engine)
  require('spell_db/rogue/315496_Slice_and_Dice')(engine)
  require('spell_db/rogue/1943_Rupture')(engine)
  require('spell_db/rogue/13750_Adrenaline_Rush')(engine)
  require('spell_db/rogue/315508_Roll_the_Bones')(engine)
  require('spell_db/rogue/200806_Enveloping_Shadows')(engine)
end

-- Shaman
loaders.SHAMAN = function(engine)
  require('spell_db/shaman/57994_Wind_Shear')(engine)
  require('spell_db/shaman/2645_Ghost_Wolf')(engine)
  -- Elemental
  require('spell_db/shaman/188389_Flame_Shock')(engine)
  require('spell_db/shaman/51505_Lava_Burst')(engine)
  require('spell_db/shaman/8042_Earth_Shock')(engine)
  -- Enhancement
  require('spell_db/shaman/17364_Stormstrike')(engine)
  require('spell_db/shaman/60103_Lava_Lash')(engine)
  require('spell_db/shaman/187874_Crash_Lightning')(engine)
  -- Resto / utility
  require('spell_db/shaman/61295_Riptide')(engine)
  require('spell_db/shaman/1064_Chain_Heal')(engine)
  require('spell_db/shaman/8004_Healing_Surge')(engine)
  require('spell_db/shaman/192058_Capacitor_Totem')(engine)
  require('spell_db/shaman/108280_Healing_Tide_Totem')(engine)
  require('spell_db/shaman/98008_Spirit_Link_Totem')(engine)
  require('spell_db/shaman/370_Purge')(engine)
  require('spell_db/shaman/51514_Hex')(engine)
end

-- Druid
loaders.DRUID = function(engine)
  require('spell_db/druid/106839_Skull_Bash')(engine)
  require('spell_db/druid/22812_Barkskin')(engine)
  require('spell_db/druid/20484_Rebirth')(engine)
  require('spell_db/druid/774_Rejuvenation')(engine)
  require('spell_db/druid/8936_Regrowth')(engine)
  require('spell_db/druid/8921_Moonfire')(engine)
  require('spell_db/druid/33917_Mangle')(engine)
  require('spell_db/druid/1822_Rake')(engine)
  require('spell_db/druid/22568_Ferocious_Bite')(engine)
  require('spell_db/druid/5176_Wrath')(engine)
  require('spell_db/druid/29166_Innervate')(engine)
  require('spell_db/druid/18562_Swiftmend')(engine)
  require('spell_db/druid/33763_Lifebloom')(engine)
  require('spell_db/druid/48438_Wild_Growth')(engine)
  require('spell_db/druid/22842_Frenzied_Regeneration')(engine)
  require('spell_db/druid/192081_Ironfur')(engine)
  require('spell_db/druid/93402_Sunfire')(engine)
  require('spell_db/druid/78674_Starsurge')(engine)
end

-- Death Knight
loaders.DEATHKNIGHT = function(engine)
  require('spell_db/deathknight/47528_Mind_Freeze')(engine)
  require('spell_db/deathknight/49998_Death_Strike')(engine)
  require('spell_db/deathknight/43265_Death_and_Decay')(engine)
  require('spell_db/deathknight/49028_Dancing_Rune_Weapon')(engine)
  require('spell_db/deathknight/49020_Obliterate')(engine)
  require('spell_db/deathknight/195292_Death_Coil')(engine)
  require('spell_db/deathknight/48707_Anti_Magic_Shell')(engine)
  require('spell_db/deathknight/195182_Marrowrend')(engine)
  require('spell_db/deathknight/48792_Icebound_Fortitude')(engine)
  require('spell_db/deathknight/206930_Heart_Strike')(engine)
  require('spell_db/deathknight/50842_Blood_Boil')(engine)
  require('spell_db/deathknight/55233_Vampiric_Blood')(engine)
  require('spell_db/deathknight/49576_Death_Grip')(engine)
  require('spell_db/deathknight/49184_Howling_Blast')(engine)
  require('spell_db/deathknight/85948_Festering_Strike')(engine)
  require('spell_db/deathknight/85948_Scourge_Strike')(engine)
  require('spell_db/deathknight/51271_Pillar_of_Frost')(engine)
end

-- Monk
loaders.MONK = function(engine)
  require('spell_db/monk/116705_Spear_Hand_Strike')(engine)
  require('spell_db/monk/115203_Fortifying_Brew')(engine)
  require('spell_db/monk/100780_Tiger_Palm')(engine)
  require('spell_db/monk/107428_Rising_Sun_Kick')(engine)
  require('spell_db/monk/100784_Blackout_Kick')(engine)
  require('spell_db/monk/101546_Spinning_Crane_Kick')(engine)
  require('spell_db/monk/322109_Touch_of_Death')(engine)
  require('spell_db/monk/121253_Keg_Smash')(engine)
  require('spell_db/monk/119582_Purifying_Brew')(engine)
  require('spell_db/monk/116849_Life_Cocoon')(engine)
  require('spell_db/monk/115151_Renewing_Mist')(engine)
  require('spell_db/monk/322101_Expel_Harm')(engine)
end

-- Demon Hunter
loaders.DEMONHUNTER = function(engine)
  require('spell_db/demonhunter/183752_Disrupt')(engine)
  require('spell_db/demonhunter/198589_Blur')(engine)
  require('spell_db/demonhunter/258920_Immolation_Aura')(engine)
  require('spell_db/demonhunter/188499_Blade_Dance')(engine)
  require('spell_db/demonhunter/162794_Chaos_Strike')(engine)
  require('spell_db/demonhunter/198013_Eye_Beam')(engine)
  require('spell_db/demonhunter/191427_Metamorphosis')(engine)
end

-- Evoker
loaders.EVOKER = function(engine)
  require('spell_db/evoker/351338_Quell')(engine)
  require('spell_db/evoker/355936_Emerald_Blossom')(engine)
  require('spell_db/evoker/382266_Fire_Breath')(engine)
  require('spell_db/evoker/369459_Living_Flame')(engine)
  require('spell_db/evoker/360995_Verdant_Embrace')(engine)
  require('spell_db/evoker/367226_Spiritbloom')(engine)
  require('spell_db/evoker/359073_Eternity_Surge')(engine)
end

-- Warlock
loaders.WARLOCK = function(engine)
  require('spell_db/warlock/5782_Fear')(engine)
  require('spell_db/warlock/980_Agony')(engine)
  require('spell_db/warlock/172_Corruption')(engine)
  require('spell_db/warlock/30108_Unstable_Affliction')(engine)
  require('spell_db/warlock/80240_Havoc')(engine)
  require('spell_db/warlock/234153_Drain_Life')(engine)
  require('spell_db/warlock/116858_Chaos_Bolt')(engine)
  require('spell_db/warlock/6353_Soul_Fire')(engine)
  require('spell_db/warlock/196277_Implosion')(engine)
  require('spell_db/warlock/6201_Create_Healthstone')(engine)
end

return loaders


