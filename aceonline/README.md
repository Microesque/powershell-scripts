# SCRIPT USAGE

>- The `modules` directory contains reusable functions required by the main scripts in this directory. Therefore, the scripts cannot function correctly if used without the `modules` directory.
>- All scripts are interactive by default. You can use the `-NonInteractive` parameter to suppress prompts and require explicit parameters. Without the `-NonInteractive` switch, any supplied parameters will be ignored. Ex:
```powershell
# Give 30000 cash points to the account `CoolAccount`
powershell.exe -NoProfile -ExecutionPolicy Bypass `
    -File "Update-AccountCashPoint.ps1" `
    -MssqlServerAddress "192.168.1.100" `
    -MssqlUsername "sa" `
    -MssqlPassword "123asd" `
    -AccountName "CoolAccount" `
    -Value "+30000" `
    -NonInteractive
```
>- All functions/scripts are fully documented. You can access the documentation with the PowerShell `-Help` parameter, or view them directly at the top of each function/script.

---

# TABLE INFO

**`atum2_db_1:`**
- [atum2_db_1.dbo.td_Character](#atum2_db_1dbotd_character)
- [atum2_db_1.dbo.td_CharacterQuest](#atum2_db_1dbotd_characterquest)
- [atum2_db_1.dbo.td_DeclarationOfWar](#atum2_db_1dbotd_declarationofwar)
- [atum2_db_1.dbo.td_InfinityImpute](#atum2_db_1dbotd_infinityimpute)
- [atum2_db_1.dbo.td_InfluenceWarData](#atum2_db_1dbotd_influencewardata)
- [atum2_db_1.dbo.td_OutPostInfo](#atum2_db_1dbotd_outpostinfo)
- [atum2_db_1.dbo.td_RenewalStrategyPointSummonTime](#atum2_db_1dbotd_renewalstrategypointsummontime)
- [atum2_db_1.dbo.td_Store](#atum2_db_1dbotd_store)

**`atum2_db_account:`**
- [atum2_db_account.dbo.td_Account](#atum2_db_accountdbotd_account)
- [atum2_db_account.dbo.td_PollDate](#atum2_db_accountdbotd_polldate)
- [atum2_db_account.dbo.ti_EnchantInfo](#atum2_db_accountdboti_enchantinfo)
- [atum2_db_account.dbo.ti_HappyHourEvent](#atum2_db_accountdboti_happyhourevent)
- [atum2_db_account.dbo.ti_InfinityShop](#atum2_db_accountdboti_infinityshop)
- [atum2_db_account.dbo.ti_ItemEvent](#atum2_db_accountdboti_itemevent)
- [atum2_db_account.dbo.ti_ItemInfo](#atum2_db_accountdboti_iteminfo)
- [atum2_db_account.dbo.ti_Monster](#atum2_db_accountdboti_monster)
- [atum2_db_account.dbo.ti_MonsterItem](#atum2_db_accountdboti_monsteritem)
- [atum2_db_account.dbo.ti_OverlapItem](#atum2_db_accountdboti_overlapitem)
- [atum2_db_account.dbo.ti_RareItemInfo](#atum2_db_accountdboti_rareiteminfo)
- [atum2_db_account.dbo.ti_Shop](#atum2_db_accountdboti_shop)

---

### atum2_db_1.dbo.td_Character

>- Contains the characters (the actual gears) inside of the accounts.
>- Also contains various stats bound to the character such as char name, unit kind, level stats, number stats, level, total experience, hp, create time etc... Column names are self explanatory.
>- War points and cash points are bound to the account, not characters. They are stored in the [td_Account](#atum2_db_accountdbotd_account).
>- `UniqueNumber` is `identity primary key`. Do not include when inserting into the table.
>- `UniqueNumber` can be used to join with other tables to add the character name and other character related info.
>- `AccountName` and `AccountUniqueNumber` are taken from the [td_Account](#atum2_db_accountdbotd_account).
>- `InfluenceType` -> Specifies which faction the character belongs to:
>   - `1` -> Normal influence (whatever that means, maybe pre lvl11)
>   - `2` -> BCU influence
>   - `4` -> ANI influence
>   - `255` -> All influence
>- `SPI` is a regular item with `ItemNum = 7000022`, so it is not stored in the account or the character. It is however, bound to the characters' inventory. Refer to [td_Store](#atum2_db_1dbotd_store).

---

### atum2_db_1.dbo.td_CharacterQuest

>- Contains the list of completed character missions as well as the currently active one.
>- `CharacterUniqueNumber` is the `foreign key` for `UniqueNumber` of [td_Character](#atum2_db_1dbotd_character).
>- `QuestIndex` refer to the specific mission.
>- `QuestState`: `1` means currently active, `2` means completed.
>- I do not know what `QuestParam1` is for, but it is set to `0` for everything. The other columns are self explanatory; they determine when and how long the quest was active.
>- You can insert entries into this table to auto complete missions for characters. Editing this table requires re-logging for the changes to update.

---

### atum2_db_1.dbo.td_DeclarationOfWar

>- Contains various information about the mothership wars.
>- `InfluenceType` -> Specifies the mothership faction:
>   - `2` -> BCU influence
>   - `4` -> ANI influence
>- **The information below is my UNTESTED conclusion of what the columns do according to default values, and from starting an MS war or two. Since I modified my server for solo play for myself, I don't have any reason to start or meddle with MS wars, so I didn't bother confirming anything.**
>- `MSWarStep` seems to be defined in sequential order (`1`->`2`->`3`...). This is likely for the server to determine the level of the mothership, as the level depends on the previous outcome of the battle.
>- `NCP` is known to stand for "nation contribution points". So, this column likely stores the current `NCP` of the nation at the start or maybe end of the war. You can set it to `0` when inserting into the table.
>- `MSNum` is the mob id of the ships. You can set it to `0` when inserting into the table; it'll be updated to the appropriate value on battle start according to the previous outcome of the battle. You can join with `UniqueNumber` of [ti_Monster](#atum2_db_accountdboti_monster) to see the names and stats of the motherships.
>- `MSAppearanceMap` is the map where the mothership was spawned. You can set it to `0` when inserting into the table; it'll be updated to the appropriate value on battle start.
>- `MSWarStepStartTime` together with `MSWarStepEndTime` from what I understand, seems to determine the date range in which the mothership war can be set to start. In the actual game, mothership battle dates are determined by the faction leader, not by admins via SQL editing. This range likely represents the leader's selectable range for the corresponding step, as the name implies. So, for most cases you'd set `MSWarStepStartTime` to be the start of the week, and `MSWarStepEndTime` to be the end of the week. As such, the next row's `MSWarStepStartTime` would be the same as the current row's `MSWarStepEndTime` (with some margin).
>- `MSWarStartTime` is the actual date for the mothership battle to start for that step.
>- `MSWarEndTime` is automatically updated by the server when the said battle ends. Set to `NULL` when inserting into the table.
>- `SelectCount` is an unknown for me. It is always set to `3` and doesn't seem to ever change. I don't know what it does.
>- `GiveUp` probably shows if the battle was forfeit I guess? Can you even do that? I don't know. Set to `0` when inserting into the table.
>- `MSWarEndState` is automatically updated by the server when the corresponding battle ends. Set to `0` when inserting into the table. I don't know what value corresponds to what result, but there are more than a couple states.

---

### atum2_db_1.dbo.td_InfinityImpute
>- Logs the daily infinity field tries for each character.
>- `AccountUID` can be joined with [td_Account](#atum2_db_accountdbotd_account) to get more info about the account, such as the account name.
>- `CharacterUID` can be joined with [td_Character](#atum2_db_1dbotd_character) to get more info about the character, such as the character name.
>- `InfinityModeUID` represents the infinity field map that was initiated:
>   - `1` -> Kreacian Holy Lands
>   - `2` -> The Hydrogen Driver
>   - `3` -> Survival Abyss
>- Other columns are self explanatory.
>- If you crash during the infinity field and want to re-enter or something, simply delete the corresponding entry for that character. Requires character re-login.
>- The server automatically handles deleting the entries that are a day old.

---

### atum2_db_1.dbo.td_InfluenceWarData
>- Stores various information about the factions themselves.
>- You aren't supposed to add or delete entries here. There should be one `InfluenceType = 2` and one `InfluenceType = 4` entries listed in the table.
>   - `2` -> BCU influence
>   - `4` -> ANI influence
>- If you want to set yourself as the faction leader, set the `InfLeaderCharacterUID` to your characters `UniqueNumber` found in [td_Character](#atum2_db_1dbotd_Character). However, this will not give you the items normally given to the leader at the end of an election. You are simply overwriting the information. You can still get these items by editing your [ti_Shop](#atum2_db_accountdboti_shop) entries.
>- The other column names are either self explanatory or not important enough to talk about.

---

### atum2_db_1.dbo.td_OutPostInfo
>- Contains various information about the outpost wars.
>- This is where you set the outpost war times.
>- `OutPostMapIndex` is the outpost map. I don't know which number corresponds to which map.
>- `OutPostCityMapIndex` likely refers to the outpost headquarters map, but I'm not sure.
>- `OutPostGetTime` is the last outpost wars' finish date.
>- `OutPostNextWarTime` is the next outpost wars' start date.
>- `OutPostNextWarTimeSet` likely shows if anyone managed to win the last outpost war, but I'm not sure. I think `0` means `finished` and `1` means `unfinished`.
>- `OutPostGetInfl` is the influence type the outpost currently belongs to:
>   - `2` -> BCU influence
>   - `4` -> ANI influence
>- `OutPostGuildUID` is the id of the guild that currently owns the outpost. You can get more info by joining with the table `atum2_db_1.dbo.td_Guild`.

---

### atum2_db_1.dbo.td_RenewalStrategyPointSummonTime
>- Configures the strategic point spawns.
>- `DayOfWeek` should be `0–6`, which correspond to the days `sunday–monday` respectively.
>- `StartTime` and `EndTime` determine the **time** range when SPs can spawn. The date values are ignored.
>- `CountBCU` and `CountANI` represent how many SPs should spawn within the specified time frame for that day of the week.
>- As you can derive from the previous lines, SPs are spawned automatically and periodically by the server. You only get to configure the automation settings. You do not set the date/time of SP spawns individually.
>- You can use the admin `/summon` command to summon SPs if you need them to be spawned on demand.

---

### atum2_db_1.dbo.td_Store
>- Contains the current items of the characters; this includes both inventory and warehouse.
>- `SPI` is an item with `ItemNum = 7000022`, so giving or editing the money of a character is done from this table.
>- `UniqueNumber` is an `identity primary key`. Do not include when inserting into the table.
>- `AccountUniqueNumber` is the `foreign key` for `AccountUniqueNumber` of [td_Account](#atum2_db_accountdbotd_account). It determines you which account's character has the item.
>- `Possess` is the `foreign key` for `UniqeuNumber` of [td_Character](#atum2_db_1dbotd_character). It determines which character has the item.
>- `ItemStorage` determines weather the item is in the character's inventory or warehouse:
>   - `0` -> Inventory
>   - `1` -> Warehouse
>- `Wear` determines if the item is equipped by the character:
>   - `0` -> Not wearing
>   - `1` -> Wearing
>- `CurrentCount` determines how many of that item the stack has.
>- `ItemWindowIndex` seems to be the slot the item is in. I believe, the inventory starts from `100` which represents the top left most slot. It seems that, it's fine for multiple items to be listed as the same slot, or set it to a slot that isn't continuous from the existing entries. The game seems to handle all of those cases well. When inserting into the table, I recommend setting this value to `MAX(ItemWindowIndex) + 1` or `100`, whichever one is bigger. This way, the item will always appear on the last empty slot in your inventory.
>- `ItemNum` is the item, and is the `foreign key` for `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).
>- The other columns are either self explanatory or not worth talking about.

---

### atum2_db_account.dbo.td_Account
>- Contains the accounts for the server.
>- Also contains various stats bound to the account, such as account name, account password, account type, register date, last login date, etc... Column names are self explanatory.
>- Creating an account is done by adding entries into this table. Most of the columns don't need to be filled and many of them have default values. Refer to the [Add-NewAccount.ps1](../Add-NewAccount.ps1) script to see my implementation.
>- `AccountUniqueNumber` is `identity primary key`. Do not include when inserting into the table.
>- `AccountUniqueNumber` can be used to join with other tables to add the account name and other account related info.
>- `AccountType` determines the account type:
>   - `0` -> Normal user
>   - `128` -> GM
>   - `256` -> Helper
>   - `...` -> There are apparently others, but not that important.
>- `CashPoint` and `WarPoint` store the war points and cash points respectively, they are stored on this table since these are account wide currencies.
>- `SPI` is a regular item with `ItemNum = 7000022`, so it is not stored in the account or the character. It is however, bound to the characters' inventory. Refer to [td_Store](#atum2_db_1dbotd_store).

---

### atum2_db_account.dbo.td_PollDate
>- Determines faction leaders' application, vote, and election dates.
>- All columns are of type `datetime` and self explanatory.
>- Note that, there are requirements to be able to apply, some of which can't be fullfilled in a solo server. For such case, editing the [td_InfluenceWarData](#atum2_db_1dbotd_influencewardata) to set yourself as a leader is the better choice.

---

### atum2_db_account.dbo.ti_EnchantInfo
>- Determines the success probabilities and costs of enchanting cards.
>- `EnchantItemNum` is the item you're enchanting with, not the item that is getting enchanted. As such, these items are mostly cards. Join with the `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo) to get the corresponding item name and related info.
>- To get the probability percentage of success, divide the prob column values by 100. Meaning, prob of `10,000` corresponds to 100% chance of success. Note that, you can add multipliers to these success rates via the happy hour from the [ti_HappyHourEvent](#atum2_db_accountdboti_happyhourevent).
>- By default, the max enchant level for weapons is +16, and the max enchant level for engines and shields is +5, due to the following `Prob17` and `Prob6` respectively being set to `0`.
>- Fix and reset cards are also listed here. Their default is set to 100% chance but you could change that here.
>- With modification, the cards could be applied all the way to +40 (last column).

---

### atum2_db_account.dbo.ti_HappyHourEvent
>- Determines the happy hour times and bonuses as well as which faction and level players they apply to.
>- Happy hour bonuses are written as direct multipliers, even though they are shown as percentile increases in game. For example, setting the `EXPRate` to `25` will increase the xp gain by `2500%` in game.
>- The first `UniqueNumber` column is an identity primary key. Do not include it when inserting into the table.
>- **The information below was derived through trial and error. I didn't inspect the game's source code, so take them with a grain of salt!**
>- Seems what should've been implemented in two different tables is implemented on this single table, so depending on the value of the `DayOfWeek` column, some values are ignored.
>- There are mainly 5 columns that determine if and when the happy hour will occur:
>    - `ServerGroupID` -> Server ID to appy happy hour to. Set to `0` for all servers.
>    - `DayOfWeek` -> Values between `0–6` correspond to the days `sunday–monday` to which the bonuses will apply. A value of `7` instead defines when the happy hour itself is active.
>    - `StartTime` -> Depending on `DayOfWeek` value, either represents the happy hour start time or the happy hour active start date.
>    - `EndTime` -> Depending on `DayOfWeek` value, either represents the happy hour end time or the happy hour active end date.
>    - `InfluenceType` -> Specifies which faction the entry applies to:
>       - `1` -> Normal influence (whatever that means, maybe pre lvl11)
>       - `2` -> BCU influence
>       - `4` -> ANI influence
>       - `255` -> All influence
>- The main mechanic to understand is this: when `DayOfWeek` is set to `7`, the row defines the date range during which the happy hour will be active for a given `InfluenceType`. The bonus values such as `EXPRate` or `SPIRate` for these rows are completely ignored. The active period is determined by `StartTime` and `EndTime`. If no such row exists for an `InfluenceType`, or if the current date falls outside this range, the happy hour will not be active.
>- After activating the happy hour with a row as explained above, the bonuses must be configured separately for each day of the week. When `DayOfWeek` is set to a value between `0–6` (representing `sunday–monday`), the date component of `StartTime` and `EndTime` is ignored and only the time component is used. This time window defines the active period for that specific day, and the bonus multiplier columns are applied to the corresponding `InfluenceType` during that period.

---

### atum2_db_account.dbo.ti_InfinityShop
>- Contains the items listed in the infinity field shop.
>- `InfinityShopUID` is the `primary key`.
>- `BuyItemNum` is the item to purchase. Join with the `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo) to see the item name and related info.
>- `BuyItemCount` is the number of `BuyItemNum` you get per single purchase.
>- `TradeItemNum` is the item used to purchase the item. Join with the `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo) to see the item name and related info.
>- `TradeItemCount1` is the number of `TradeItemNum` you need to do a single purchase.

---

### atum2_db_account.dbo.ti_ItemEvent
>- Contains the list of items given to characters via various events.
>- `ItemEventUID` is the `primary key`.
>- `ItemEventType` is the event the row corresponds to. `2` seems to correspond to membership daily login rewards. `4` seems to correspond to leveling up? Or maybe active all the time, since it's used to give rewards when you reach a certain level. I don't know beyond that.
>- `InfluenceType` -> Specifies which faction the entry applies to:
>   - `1` -> Normal influence (whatever that means, maybe pre lvl11)
>   - `2` -> BCU influence
>   - `4` -> ANI influence
>   - `255` -> All influence
>- `ItemNum` and `Count` determine the item and how many of it will be given. Join with the `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo) to get the corresponding item name and related info.
>- `StartTime` and `EndTime` define the active date period for events such as valentines day, or christmas.
>- Rest of the columns are either self explanatory or ones I do not know.

---

### atum2_db_account.dbo.ti_ItemInfo
>- Contains all properties of all items.
>- One of the most useful tables to join with, so you can refer to items with their names instead of their `ItemNum`.
>- Also contains basically all attributes bound to the item such as item names, min/max level, damages, required unit type, spi price, wp price etc...
>- Contains the all useful `ItemNum` column which is used to refer to an item in other tables, such as a monster dropping a given item. Although, the probability of dropping is dependent on the mob and not a property of the item itself, so it would be part of the moster table.
>- `SPI` is also an item with `ItemNum = 7000022`.
>- `WP` and `Cash` are bound to the account and not the character, so they are not items. `SellingPrice` column determines the selling price when dragged onto a shop, while the purchasing price is determined by the `Price` column of the [ti_Shop](#atum2_db_accountdboti_shop) table.
>- For weapons, `MultiTarget` column determines how many targets can be selected at a time. For normal weapons besides `Snipe` this is typically `1`. This can be set to `0` to make a weapon unable to hit anything.
>- `LinkItem` determines the required item to purchase. For example, for an elite skill, it would point to the itemnum of elite skill opening card
>- The weapon shot by `P.E.D` is also an item that can be edited with the `ItemNum = 7047795`.
>- Changing certain columns requires re-generating and updating of `omi.tex` file for both the server and the client. The changes will apply without the update, but won't reflect correctly on the UI of the game.
>- `ItemAttribute` also determines stuff like the requirements to buy it, or weather you can enchant a weapon or not. For example, you can change the `ItemAttribute` of a unique weapon to make it enchantable.

---

### atum2_db_account.dbo.ti_Monster
>- Determines the various stats of every mob in the game.
>- `Experience` column is the amount of experience the monster gives on kill.
>- `MonsterItemXX` columns list the attacks a monster is capable of doing. The nature of the attack such as the delay/frequency/damage are pre-defined.
>- I won't pretend like I know what each column does, but you can modify the level, hp, regen, etc, values of the monsters from here. Unless you know what you're doing, you'd mostly use this table for its `UniqueNumber` column to join and reference the name of the monsters in other tables.
>- Do know this: certain aspects of monsters, such as which map they spawn in and how many can spawn at a time, are stored in the game's map files, not in this table. These files require dedicated tools to view and modify.

---

### atum2_db_account.dbo.ti_MonsterItem
>- Determines the item drops from monsters and bosses including the infinity field ones.
>- `MonsterUniqueNumber` can be joined with the `UniqueNumber` of [ti_Monster](#atum2_db_accountdboti_monster) to get the corresponding monster name and related info.
>- `ItemNum` can be joined with the `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo) to get the corresponding item name and related info.
>- Each entry is rolled separately, so you could get every single listed item from a single mob, or you could get absolutely nothing.
>- Duplicate entries are not allowed. An item can only be dropped by a given mob a single time. This is also likely the reason why infinity field levels modify not only the drop chance but also the drop amount.
>- Probability doesn't seem to be out of 100. If you want something to drop 100% of the time, just set it to a high value like `100,000,000`. I think `1,000,000` or so represents 100%, but I didn't test this.
>- `MinCount` and `MaxCount` determine the range in which the number of items will drop.
>- I do not know what the `DropType` column is for; though, 99.99% of the items have it set to 0.
>- If you want to adjust the infinity field boss drops:

| Map                 | Boss Name DB       | MonsterUniqueNumber |
| ------------------- | ------------------ | ------------------- |
| Kreacian Holy Lands | \yUltima Kreacia\y | 2091200             |
| The Hydrogen Driver | \yCalzaghe\y       | 2089900             |
| Survival Abyss      | \mSHADE Engine\m   | 2104600             |

---

### atum2_db_account.dbo.ti_OverlapItem
>- Determines the tab in which the cash shop items appear as well as their final prices.
>- Consists of 4 columns:
>    - `ItemNum` -> The item. Refer to [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).
>    - `Tab` -> Tab in which the item will appear. [1-6]
>    - `ItemAttribute` -> Likely allows overwriting the attribute of the item. Unless you know what you're doing, just copy the `ItemAttribute` column of the [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).
>- Adding items to the cash shop via [ti_Shop](#atum2_db_accountdboti_shop) table also requires adding a corresponding entry here.

---

### atum2_db_account.dbo.ti_RareItemInfo
>- Defines the enchants, their probabilities, and the stats they give for various weapons and items.
>- `CodeNum` is the `private key` and must be unique. The value in this column is used to assign the enchant to items.
>- `ReqUseType` is an unknown to me.
>- `ReqMinLevel` always seems to be 1. Don't know how it affects the enchant.
>- `ReqMaxLevel` always seems to be 120. Don't know how it affects the enchant.
>- `ReqItemKind` seems to be the type of item enchant is applicable to:
>    - `44`  -> Standard weapons
>    - `48`  -> Advanced weapons
>    - `7`   -> Armors
>    - `...` -> There seems to be more but I don't know what they refer to.
>- `ReqAttackPart` always seems to be 0. Don't know how it affects the enchant.
>- `ReqDefensePart` always seems to be 0. Don't know how it affects the enchant.
>- `ReqDodgePart` always seems to be 0. Don't know how it affects the enchant.
>- `ReqFuelPart` always seems to be 0. Don't know how it affects the enchant.
>- `ReqShieldPart` always seems to be 0. Don't know how it affects the enchant.
>- `ReqShoulPart` always seems to be 0. Don't know how it affects the enchant.
>- `DestParameterX` is the stat the corresponding `ParameterValueX` will apply to.
>- `ParameterValueX` is the modifier the corresponding `DestParameterX` will receive.
>- `Probability` is the probability of getting the enchant. The chances of getting the enchant depends on the probabilities of the other enchants and their relation.
>- Below is a list of `DestParameterX` values and what they represent.
>    - `18`  -> Damage (std) (min)
>    - `19`  -> Damage (adv) (min)
>    - `20`  -> Probability (std)
>    - `21`  -> Probability (adv)
>    - `22`  -> Defence (std)
>    - `23`  -> Defence (adv)
>    - `24`  -> Evasion (std)
>    - `25`  -> Evasion (adv)
>    - `31`  -> ReAttack (std)
>    - `32`  -> ReAttack (adv)
>    - `71`  -> Damage (std) (max)
>    - `72`  -> Damage (adv) (max)
>    - `75`  -> Weight (std)
>    - `76`  -> Weight (adv)
>    - `129` -> Radar (std)
>    - `130` -> Radar (adv)
>    - `157` -> EXP
>    - `159` -> Drop Rate
>    - `161` -> Shield Recovery
>    - `162` -> Sp Recovery
>    - `176` -> Speed
>    - `184` -> Pierce (std)
>    - `185` -> Pierce (adv)
>- Note that, `ParameterValueX` will change depending on the type of stat it applies to. For example, `+15% probability` requires a value of `15`. While -15% ReAttack will requires a value of `-0.15`. Reference the other entries in the table.
>- Below is a list of the top tier enchants for myself to reference:

`Weapon Fixes:`
| Fix Name | Tier  | Min/Max | Prob | Pierce | ReAtk | Weight |
| -------- | ----- | ------- | ---- | ------ | ----- | ------ |
| Fear     | Hyper | 25      |      |        |       |        |
| Navas    | Hyper | 20      | 20   |        |       |        |
| Asmodi   | Hyper | 15      |      | 15     |       |        |
| Max      | Hyper | 15      |      |        | 15    |        |
| Sentinal | Hyper | 15      |      |        |       | 30     |
| Wrath    | Hyper |         | 15   | 15     |       |        |
| Legend   | Hyper |         | 15   |        | 15    |        |
| Watcher  | Hyper |         | 15   |        |       | 30     |
| Warrior  | Hyper |         |      | 15     | 15    |        |
| Warder   | Hyper |         |      | 15     |       | 30     |
| Sentry   | Hyper |         |      |        | 15    | 30     |

`Armor Fixes:`
| Focus      | Weapon  | Fix Name   | Tier  | Stats                                                                                   |
| ---------- | ------- | ---------- | ----- | --------------------------------------------------------------------------------------- |
| EXP        | STD     | Endlos     | Super | Exp +22% - Std Min/Max +7% - Std Prc 5.00% - Adv Prc +5.00%                             |
| EXP        | ADV     | Allocer    | Super | Exp +20% - Adv Min/Max +10% - Spd +6%                                                   |
| EXP + DMG  | STD     | Creed      | Super | Exp +15% - Std Min/Max +10% - Std Prob +7.00%                                           |
| EXP + DMG  | ADV     | Aeon       | Super | Exp +15% - Adv Min/Max +10% - Adv Rdr +12.00%                                           |
| DROP       | STD&ADV | Malevolent | Super | DropRate +24% - SP Recov +17% - Shd Recov +22%                                          |
| DROP + DMG | STD     | Limbo      | Super | DropRate +20% - Std Min +10% - Std Max +22%                                             |
| DROP + DMG | STD     | Forbidden  | Super | DropRate +20% - Std Prob +4.50% - Std Rdr +5.00% - SP Recov +10%                        |
| DROP + DMG | ADV     | Agares     | Super | DropRate +22% - Adv Min/Max +10% - Std Min +10% - SP Recov +15%                         |
| DROP + DMG | STD&ADV | Odyssey    | Hyper | DropRate +18% - Std Prob +9.80% - Adv Prob +9.80% - Sp Recov +15% - Shd Recov +15%      |
| EXP + DROP | STD&ADV | Orichalcum | Super | Exp +15% - DropRate +20% - SP Recov +12%                                                |
| EXP + DROP | ADV     | Oracle     | Super | Exp +15% - DropRate +20% - Adv Prob +4.00%                                              |
| DMG        | STD     | Limbo      | Super | Std Min +10% - Std Max +22% - DropRate +20%                                             |
| DMG        | STD     | Testament  | Hyper | Std Min/Max +10% - Adv Max +10% - 6.00% Std Prc - SP Recov +15%                         |
| DMG        | STD     | Tyranny    | Hyper | Std Min/Max +10% - Adv Max +10% - Std Prob +6.00% - SP Recov +15%                       |
| DMG        | STD     | Origin     | Hyper | Std Prob +9.80% - Adv Prob +9.80% - Shd Recov +15% - SP Recov +15% - Std Rdr Rng +9.00% |
| DMG        | ADV     | Conclave   | Super | Adv Min +21% - Adv Max +10% - Std Prc +5.00% - Adv Prc +5.00%                           |
| DMG        | ADV     | Macha      | Hyper | Std Prob +4.71% - Adv Prob +4.71% - Adv Prc 4.50% - Std Rdr +5.00% - Spd +5%            |
| DMG        | ADV     | Ose        | Hyper | Adv Min +9% - Std Prob +9.80% - Adv Prob +9.80% - SP Recov +15% - Shd Recov +15%        |
| Armor      | EVA     | Bathin     | Super | +10% Std Eva - +12% Adv Eva                                                             |
| Armor      | DEF     | Baldr      | Super | +10% Std Def - +12% Adv Def                                                             |

> NOTE:
>- Some of the fixes listed above have a chance to also come with additional stat bonuses (e.g., +5% prob, -weight, +overheat time etc.). This applies to all listed weapon fixes, along with only the `Bathin` and `Baldr` armor fixes. 
>- For armor fixes, `Focus: DMG` refers to all stats that contribute to damage, including probability and piercing.
>- `Sentinel` is a custom weapon enchant I added for my own server.
>- `Watcher` is a custom weapon enchant I added for my own server.
>- `Warder` is a custom weapon enchant I added for my own server.
>- `Sentry` is a custom weapon enchant I added for my own server.

---

### atum2_db_account.dbo.ti_Shop
>- Contains all items listed in various shops.
>- Consists of 3 columns:
>    - `ShopOrder` -> Unique index (not a key).
>    - `UniqueNumber` -> Shop ID.
>    - `ItemNum` -> The item. Refer to [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).
>    - `Price` -> Price of the item. The price listed here automatically turns into SPI price for regular shops, WP price for the WP shop, and cash price for the cash shop.
>- Corresponding shop names for the shop ID:
>    - `9001` -> Weapon Shop BCU
>    - `9101` -> Weapon Shop ANI
>    - `9002` -> Card Shop BCU
>    - `9102` -> Card Shop ANI
>    - `9005` -> Part Shop BCU
>    - `9105` -> Part Shop ANI
>    - `9006` -> Gear Shop BCU
>    - `9106` -> Gear Shop ANI
>    - `9009` -> Skill Shop BCU
>    - `9109` -> Skill Shop ANI
>    - `9285` -> Shop WP BCU
>    - `9286` -> Shop WP ANI
>    - `9999` -> Cash Shop
>    - `----` -> There are other shops such as crystal kit shop. I didn't bother figuring those out. `¯\_(ツ)_/¯`
>- Updating the shop ID `9999 (Cash Shop)` requires re-generating and updating of `omi.tex` file for both the server and the client. The changes will apply without the update, but won't reflect correctly on the UI of the game.
>- Adding items to the shop ID `9999 (Cash Shop)` also requires adding a corresponding entry to the [ti_OverlapItem](#atum2_db_accountdboti_overlapitem).
>- The prices for the shops as well as which gear's tab they appear in are all properties of the items. Refer to [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).

---
