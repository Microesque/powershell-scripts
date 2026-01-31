
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
