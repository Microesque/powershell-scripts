
---

**`atum2_db_1:`**
- [atum2_db_1.dbo.td_Character](#atum2_db_1.dbotd_character)
- [atum2_db_1.dbo.td_CharacterQuest](#atum2_db_1.dbotd_characterquest)
- [atum2_db_1.dbo.td_DeclarationOfWar](#atum2_db_1.dbotd_declarationofwar)
- [atum2_db_1.dbo.td_InfinityImpute](#atum2_db_1.dbotd_infinityimpute)
- [atum2_db_1.dbo.td_InfluenceWarData](#atum2_db_1.dbotd_influencewardata)
- [atum2_db_1.dbo.td_OutPostInfo](#atum2_db_1.dbotd_outpostinfo)
- [atum2_db_1.dbo.td_Store](#atum2_db_1.dbotd_store)

**`atum2_db_account:`**
- [atum2_db_account.dbo.td_PollDate](#atum2_db_accountdbotd_polldate)
- [atum2_db_account.dbo.ti_EnchantInfo](#atum2_db_accountdboti_enchantinfo)
- [atum2_db_account.dbo.ti_HappyHourEvent](#atum2_db_accountdboti_happyhourevent)
- [atum2_db_account.dbo.ti_InfinityShop](#atum2_db_accountdboti_infinityshop)
- [atum2_db_account.dbo.ti_ItemEvent](#atum2_db_accountdboti_itemevent)
- [atum2_db_account.dbo.ti_ItemInfo](#atum2_db_accountdboti_iteminfo)
- [atum2_db_account.dbo.ti_Monster](#atum2_db_accountdboti_monster)
- [atum2_db_account.dbo.ti_MonsterItem](#atum2_db_accountdboti_monsteritem)
- [atum2_db_account.dbo.ti_OverlapItem](#atum2_db_accountdboti_overlapitem)
- [atum2_db_account.dbo.ti_Shop](#atum2_db_accountdboti_shop)

---

### atum2_db_1.dbo.td_Character

>- Contains the characters (the actual gears) inside of the accounts.
>- Also contains various stats bound to the character such as char name, unit kind, level stats, number stats, level, total experience, hp, create time etc... Column names are self explanatory.
>- War points and cash points are bound to the account, not characters. They are stored in the [td_Account](#atum2_db_accountdbotd_account).
>- `UniqueNumber` is `identity primary key`. Do not include when inserting into the table.
>- `UniqueNumber` can used to join with other tables to add the character name and other various info.
>- `AccountName` and `AccountUniqueNumber` are taken from the [td_Account](#atum2_db_accountdbotd_account).
>- `InfluenceType` -> Specifies which faction the character belongs to:
>   - `1` -> Normal influence (whatever that means, maybe pre lvl11)
>   - `2` -> BCU influence
>   - `4` -> ANI influence
>   - `255` -> All influence

---

### atum2_db_account.dbo.td_PollDate

>- Determines faction leaders' application, vote, and election dates.
>- All columns are of type `datetime` and self explanatory.
>- Note that, there are requirements to be able to apply which you can't fullfill in a solo server. For such case, editing the [td_InfluenceWarData](#atum2_db_1.dbotd_influencewardata) to set yourself as a leader is the better choice.

---

### atum2_db_account.dbo.ti_EnchantInfo

>- Determines the success probabilities and costs of enchanting cards.
>- `EnchantItemNum` is the item you're enchanting with, not the item that is getting enchanted. As such, these items are mostly cards. Join with the `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo) to get the corresponding item name and info.
>- To get the probability divide the prob column values by 100. Meaning, prob of `10,000` corresponds to 100% chance of success. Note that, you can add multipliers to these success rates via the happy hour from the [ti_HappyHourEvent](#atum2_db_accountdboti_happyhourevent).
>- By default, the max enchant level for weapons is +16, and the max enchant level for engines and shields is +5, since the following `Prob17` and `Prob6` respectively are set to `0`.
>- Fix and reset cards are also listed here. The default is 100% chance but you could change that here.
>- With modification, the cards could be applied all the way to +40.

---

### atum2_db_account.dbo.ti_HappyHourEvent
>- Determines the happy hour times and bonuses as well as which faction and level players they apply to.
>- Happy hour bonuses are written as direct multipliers even though they are shown as percentile increases in game. For example, setting the `EXPRate` to `25` will increase the xp gain by `2500%` in game.
>- The first `UniqueNumber` column is an identity primary key. Do not include it when inserting into the table.
>- **The information below was derived through trial and error. I didn't inspect the game's source code itself, so take them with a grain of salt!**
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
>- `BuyItemNum` is the item to purchase. Join with the `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo) to see the item name and info.
>- `BuyItemCount` is the number of `BuyItemNum` you get per single purchase.
>- `TradeItemNum` is the item used to purchase the item. Join with the `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo) to see the item name and info.
>- `TradeItemCount1` is the number of `TradeItemNum` you need to do a single purchase.

---

### atum2_db_account.dbo.ti_ItemEvent
>- Contains the list of items given to characters via various events.
>- `ItemEventUID` is the `primary key`.
>- `ItemEventType` is the event the row corresponds to. `2` seems to correspond to membership dailly login rewards. `4` seems to correspond to leveling up? Or maybe active all the time, since it;s used to give rewards when you reach a certain level. I don't know beyond that.
>- `InfluenceType` -> Specifies which faction the entry applies to:
>   - `1` -> Normal influence (whatever that means, maybe pre lvl11)
>   - `2` -> BCU influence
>   - `4` -> ANI influence
>   - `255` -> All influence
>- `ItemNum` and `Count` determine the item and how many of it will be given. Join with the `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo) to get the corresponding item name and info.
>- `StartTime` and `EndTime` define the active date period for events such as valentines day, or christmas.
>- Rest of the columns are either self explanatory or ones I simply do not know.

---

### atum2_db_account.dbo.ti_ItemInfo
>- Contains all properties of all items.
>- One of the most useful tables to join with, so you can refer to items with their names instead of their `ItemNum`.
>- This includes item names, min/max level, damages, required unit type, spi price, wp price etc...
>- Contains the `ItemNum` column which is used to refer to an item in other tables, such as a monster dropping a given item; although, the probability of dropping is not a property of the item itself, so it would be part of the moster table.
>- `SPI` is also an item with `ItemNum` of `7000022`.
>- `WP` and `Cash` are bound to the account and not the character, so they are not items. `Price` column determines the shop price for both `SPI` and `WP`, while a dedicated `CashPrice` column determines the cash shop price for the given item.
>- For weapons, `MultiTarget` column determines how many targets can be selected at a time. For normal weapons besides `Snipe` this is typically `1`. This can be set to `0` to make a weapon unable to hit anything.
>- The weapon shot by `P.E.D` is also an item that can be edited with the `ItemNum` of `7047795`.
>- Changing certain columns requires the updateing of `omi.tex` file for both the server and the cliend. The changes will apply without the update, but won't be shown correctly on the ui of the game. Columns such as `CashPrice` and `ReqMinLevel` require the update.
>- `ItemAttribute` also determines stuff like the requirements to buy it, or weather you can enchant a weapon or not. For example, you can change the `ItemAttribute` of a unique weapon to make it enchantable.

---

### atum2_db_account.dbo.ti_Monster
>- Determines the various stats of each mob in the game.
>- I won't pretend like I know what each column does, but you can modify the level, hp, regen, etc, values of the monsters from here. Unless you know what you're doing, you'd mostly use this table with its `UniqueNumber` column to join and reference the name of the monsters in other tables.
>- Do know this: certain aspects of monsters, such as which map they spawn in and how many can spawn at a time, are stored in the game's map files. These require dedicated tools to view and modify.

---

### atum2_db_account.dbo.ti_MonsterItem
>- Determines the item drops from monsters and bosses including infinity field ones.
>- `MonsterUniqueNumber` can be joined with the `UniqueNumber` of [ti_Monster](#atum2_db_accountdboti_monster) to get the corresponding monster name and info.
>- `ItemNum` can be joined with the `ItemNum` of [ti_ItemInfo](#atum2_db_accountdboti_iteminfo) to get the corresponding item name and info.
>- Each entry is rolled separately, so you could get every single listed item from a single mob, or you may get absolutely nothing.
>- Duplicate entries are not allowed. Certain item can only be dropped by a certain mob one time.
>- Probability doesn't seem to be out of 100. If you want something to drop 100% of the time, just set it to a high number like `100,000,000`. I think `1,000,000` or so represents 100% but I didn't test really.
>- `MinCount` and `MaxCount` determine the range in which the number of items will drop.
>- I do not know what the `DropType` column is for. Though, 99.99% of the items have it set to 0.
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
>    - `CashPrice` -> Cash price of the item. Overwrites the price specified in the [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).
>    - `Tab` -> Tab in which the item will appear. [1-6]
>    - `ItemAttribute` -> Likely allows overwriting the attribute of the item. Unless you know what you're doing, just copy the `ItemAttribute` column of the [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).
>- Adding items to the [cash shop](#atum2_db_accountdboti_shop). also requires adding a corresponding entry here.

---

### atum2_db_account.dbo.ti_Shop
>- Contains all items listed in various shops.
>- Consists of 3 columns:
>    - `ShopOrder` -> Unique index (not a key).
>    - `UniqueNumber` -> Shop ID.
>    - `ItemNum` -> The item. Refer to [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).
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
>- Updating the `9999 (Cash Shop)` requires regenerating the `omi.tex` file. Other shops seem to update with just a server restart.
>- Adding items to the `9999 (Cash Shop)` also requires adding a corresponding entry to the [ti_OverlapItem](#atum2_db_accountdboti_overlapitem).
>- The prices for the shops as well as which gear's tab they appear in are all properties of the items. Refer to [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).

---
