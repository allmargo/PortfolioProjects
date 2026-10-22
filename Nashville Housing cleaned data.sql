SELECT *
FROM nashville_housing
--WHERE "SoldAsVacant" = 'Y'
--WHERE "PropertyAddress" IS NULL;




-- стандартизируем формат даты

ALTER TABLE nashville_housing
ALTER COLUMN "SaleDate" TYPE DATE
USING TO_DATE("SaleDate", 'Month DD, YYYY');




-- сопоставление адресов по "ParcelID"

SELECT a."ParcelID", a."PropertyAddress", b."ParcelID", b."PropertyAddress", COALESCE(a."PropertyAddress", b."PropertyAddress")
FROM nashville_housing a
JOIN nashville_housing b
     ON a."ParcelID" = b."ParcelID"
     AND a."UniqueID " <> b."UniqueID "
WHERE a."PropertyAddress" IS NULL;


UPDATE nashville_housing a
SET "PropertyAddress" = b."PropertyAddress"
FROM nashville_housing b
WHERE a."ParcelID" = b."ParcelID"
  AND a."UniqueID " <> b."UniqueID "
  AND a."PropertyAddress" IS NULL
  AND b."PropertyAddress" IS NOT NULL;




-- разделяем адрес на отдельные колонки: Address, City, State

SELECT "PropertyAddress"
FROM nashville_housing
	
SELECT 
       SUBSTRING("PropertyAddress" FROM 1 FOR POSITION(',' IN "PropertyAddress") - 1) as "Address",
       SUBSTRING("PropertyAddress" FROM POSITION(',' IN "PropertyAddress") + 1) as "City"
FROM nashville_housing


ALTER TABLE nashville_housing 
ADD "PropertySplitAddress" VARCHAR(50);

UPDATE nashville_housing 
SET "PropertySplitAddress" = SUBSTRING("PropertyAddress" FROM 1 FOR POSITION(',' IN "PropertyAddress") - 1);


ALTER TABLE nashville_housing 
ADD "PropertySplitCity" VARCHAR(50);

UPDATE nashville_housing 
SET "PropertySplitCity" = SUBSTRING("PropertyAddress" FROM POSITION(',' IN "PropertyAddress") + 1);




-- делим колонку "OwnerSplitAddress" на три составляющие
	
SELECT SPLIT_PART("OwnerAddress", ',', -3),
       SPLIT_PART("OwnerAddress", ',', -2),
       SPLIT_PART("OwnerAddress", ',', -1)
FROM nashville_housing


ALTER TABLE nashville_housing 
ADD "OwnerSplitAddress" VARCHAR(50);

UPDATE nashville_housing 
SET "OwnerSplitAddress" = SPLIT_PART("OwnerAddress", ',', -3);


ALTER TABLE nashville_housing 
ADD "OwnerSplitCity" VARCHAR(50);

UPDATE nashville_housing 
SET "OwnerSplitCity" = SPLIT_PART("OwnerAddress", ',', -2);


ALTER TABLE nashville_housing 
ADD "OwnerSplitState" VARCHAR(50);

UPDATE nashville_housing 
SET "OwnerSplitState" = SPLIT_PART("OwnerAddress", ',', -1);




-- заменим Y и N на Yes и No в поле "SoldAsVacant"

SELECT DISTINCT("SoldAsVacant"), COUNT("SoldAsVacant") as count
FROM nashville_housing 
GROUP BY "SoldAsVacant"
ORDER BY count


SELECT "SoldAsVacant"
, CASE
	WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
	WHEN "SoldAsVacant" = 'N' THEN 'No'
	ELSE "SoldAsVacant"
END
FROM nashville_housing;


UPDATE nashville_housing
SET "SoldAsVacant" = CASE
	WHEN "SoldAsVacant" = 'Y' THEN 'Yes'
	WHEN "SoldAsVacant" = 'N' THEN 'No'
	ELSE "SoldAsVacant"
END




-- удалим дубликаты

WITH row_num_cte AS (
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY "ParcelID", "PropertyAddress", "SalePrice", "SaleDate", "LegalReference"
		ORDER BY "UniqueID "
		) AS row_num
FROM nashville_housing
)
SELECT *
FROM row_num_cte
WHERE row_num > 1;


WITH row_num_cte AS (
SELECT *,
	ROW_NUMBER() OVER (
		PARTITION BY "ParcelID", "PropertyAddress", "SalePrice", "SaleDate", "LegalReference"
		ORDER BY "UniqueID "
		) AS row_num
FROM nashville_housing
)
DELETE FROM nashville_housing
WHERE "UniqueID " IN (
	SELECT "UniqueID " FROM row_num_cte WHERE row_num > 1
);




-- удалим неиспользуемые колонки

ALTER TABLE nashville_housing
DROP COLUMN "OwnerAddress",
DROP COLUMN "TaxDistrict",
DROP COLUMN "PropertyAddress",
DROP COLUMN "SaleDate";
