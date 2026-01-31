
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
