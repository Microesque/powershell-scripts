/*
================================================================================
atum2_db_account.dbo.ti_ItemInfo
[] -> Too many to list here, basically ALL properties of items.
...

    - Contains all item related info, including names, price, cashprice, wp
    price...
    - Shops add items by including the [ItemNum] value in this table.
*/
-- See all weapon effect cards
SELECT *
FROM atum2_db_account.dbo.ti_ItemInfo
WHERE ItemName LIKE '%Effect]%'

-- Get the current cash shop entries (and their names)
SELECT a.*, b.ItemName
FROM atum2_db_account.dbo.ti_Shop a
JOIN atum2_db_account.dbo.ti_ItemInfo b
ON a.ItemNum = b.ItemNum
WHERE a.UniqueNumber = 9999;

/*
================================================================================
atum2_db_account.dbo.ti_Shop
[ShopOrder]    -> Some int. Don't know what it does but keep it sequential.
[UniqueNumber] -> The shop the item will be added to.
[ItemNum]      -> Item to add. Check "ti_ItemInfo" table.

    - Contains which items are added to which shops including cash shop.
    - Uniqu numbers:
        9001: Weapon Shop BCU
        9101: Weapon Shop ANI
        9002: Card Shop BCU
        9102: Card Shop ANI
        9005: Part Shop BCU
        9105: Part Shop ANI
        9009: Skill Shop BCU
        9109: Skill Shop ANI
        9285: Shop WP BCU
        9286: Shop WP ANI
        9999: Credit Shop (updating this requires regenerating omi.tex)
    - NOTE FOR UPDATING CREDIT SHOP: Updating credit shop requires regenerating
    the "omi.tex" file and updating the server/client. Use admin monitor tool.
    Updating the credits shop MAY requrie updating the "ti_OverlapItem".
*/
-- Get the current cash shop entries including item names
SELECT a.*, b.ItemName
FROM atum2_db_account.dbo.ti_Shop a
JOIN atum2_db_account.dbo.ti_ItemInfo b
ON a.ItemNum = b.ItemNum
WHERE a.UniqueNumber = 9999;

-- Delete all current cash shop entries
DELETE atum2_db_account.dbo.ti_Shop
WHERE UniqueNumber = 9999;

-- Insert given table entries into the cash shop (preserve item order)
INSERT INTO atum2_db_account.dbo.ti_Shop(ShopOrder, UniqueNumber, ItemNum)
SELECT
	m.MaxShopOrder + ROW_NUMBER() OVER (ORDER BY (SELECT NULL)),
	9999,
	s.ItemNum
FROM (
	SELECT *
	FROM atum2_db_account.dbo.ti_ItemInfo
	WHERE ItemNum = 7028760
    OR ItemNum = 7028770
    OR ItemNum = 7035910
    OR ItemNum = 7035920
) s
CROSS JOIN (
	SELECT MAX(ShopOrder) AS MaxShopOrder
	FROM atum2_db_account.dbo.ti_Shop
) m;

/*
================================================================================
atum2_db_account.dbo.ti_OverlapItem
[ItemNum]       -> The item. Check "ti_ItemInfo" table.
[CashPrice]     -> Overwrites the CashPrice of the item that's originally in the "ti_ItemInfo".
[Tab]           -> Tab of the item. [1-5]
[ItemAttribute] -> Don't know why it's required but items have this in the "ti_ItemInfo". Assign it to that.

    - This governs which items in the cash shop entry from "ti_Shop" goes where.
    - Allows overwriting of the original cash price.
    - All items in the 9999 shop in "ti_Shop" should have an entry here or issues seem to happen.
*/
-- Get the current cash shop entry configurations including item names
SELECT a.*, b.ItemName
FROM atum2_db_account.dbo.ti_OverlapItem a
JOIN atum2_db_account.dbo.ti_ItemInfo b
ON a.ItemNum = b.ItemNum;
