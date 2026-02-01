
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

### atum2_db_account.dbo.ti_OverlapItem
>- Determines the tab in which the cash shop items appear as well as their final prices.
>- Consists of 4 columns:
>    - `ItemNum` -> The item. Refer to [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).
>    - `CashPrice` -> Cash price of the item. Overwrites the price specified in the [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).
>    - `Tab` -> Tab in which the item will appear. [1-6]
>    - `ItemAttribute` -> Likely allows overwriting the attribute of the item. Unless you know what you're doing, just copy the `ItemAttribute` column of the [ti_ItemInfo](#atum2_db_accountdboti_iteminfo).
>- Adding items to the [cash shop](#atum2_db_accountdboti_shop). also requires adding a corresponding entry here.

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
>       - `1` -> Normal influence (whatever that means)
>       - `2` -> BCU influence
>       - `4` -> ANI influence
>       - `255` -> All influence
>- The main mechanic to understand is this: when `DayOfWeek` is set to `7`, the row defines the date range during which the happy hour will be active for a given `InfluenceType`. The bonus values such as `EXPRate` or `SPIRate` for these rows are completely ignored. The active period is determined by `StartTime` and `EndTime`. If no such row exists for an `InfluenceType`, or if the current date falls outside this range, the happy hour will not be active.
>- After activating the happy hour with a row as explained above, the bonuses must be configured separately for each day of the week. When `DayOfWeek` is set to a value between `0–6` (representing `sunday–monday`), the date component of `StartTime` and `EndTime` is ignored and only the time component is used. This time window defines the active period for that specific day, and the bonus multiplier columns are applied to the corresponding `InfluenceType` during that period.

---
