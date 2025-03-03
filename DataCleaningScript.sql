select * from nashvillehousing;

-- Standardize Sale Date Format

select saledate  from nashvillehousing ;
select saledate,STR_TO_DATE(saledate,'%M %e, %Y') from nashvillehousing;

-- update nashvillehousing set saledate = saleDateConverted;

alter table nashvillehousing add saleDateConverted Date;

update nashvillehousing set saleDateConverted = STR_TO_DATE(saledate,'%M %e, %Y');

-- Populate Property Address Data

select PropertyAddress from nashvillehousing 
 where PropertyAddress= ''
order by ParcelID;

update nashvillehousing set PropertyAddress = NULL where PropertyAddress = '';

select a.ParcelID,a.PropertyAddress,b.ParcelID,b.PropertyAddress,
a.UniqueID,b.UniqueID,IFNULL(a.PropertyAddress,b.PropertyAddress)
from nashvillehousing a 
join nashvillehousing b on 
a.ParcelID=b.ParcelID and a.UniqueID <> b.UniqueID 
where a.PropertyAddress is null;

UPDATE nashvillehousing a
JOIN nashvillehousing b ON a.ParcelID = b.ParcelID AND a.UniqueID <> b.UniqueID
SET a.PropertyAddress = IFNULL(a.PropertyAddress, b.PropertyAddress)
WHERE a.PropertyAddress IS NULL;

-- Breaking out address into Individual Columns (Address, City, State)

select PropertyAddress from nashvillehousing ;
-- where PropertyAddress= ''
-- order by ParcelID;

SELECT 
    SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1) AS Address,
    SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 2) AS City
FROM nashvillehousing;

alter table nashvillehousing add PropertySplitAddress nvarchar(255);

update nashvillehousing set PropertySplitAddress = 
SUBSTRING(PropertyAddress, 1, LOCATE(',', PropertyAddress) - 1);

alter table nashvillehousing add PropertySplitCity nvarchar(255);

update nashvillehousing set PropertySplitCity = 
SUBSTRING(PropertyAddress, LOCATE(',', PropertyAddress) + 2);

select OwnerAddress from nashvillehousing;

SELECT SUBSTRING_INDEX(ownerAddress, ',', 1),
SUBSTRING_INDEX(SUBSTRING_INDEX(ownerAddress, ',', 2), ',',-1),
SUBSTRING_INDEX(SUBSTRING_INDEX(ownerAddress, ',', 3), ',',-1) FROM nashvillehousing;

alter table nashvillehousing add OwnerSplitAddress nvarchar(255);

update nashvillehousing set OwnerSplitAddress = 
SUBSTRING_INDEX(ownerAddress, ',', 1);

alter table nashvillehousing add OwnerSplitCity nvarchar(255);

update nashvillehousing set OwnerSplitCity = 
SUBSTRING_INDEX(SUBSTRING_INDEX(ownerAddress, ',', 2), ',',-1);

alter table nashvillehousing add OwnerSplitState nvarchar(255);

update nashvillehousing set OwnerSplitState = 
SUBSTRING_INDEX(SUBSTRING_INDEX(ownerAddress, ',', 3), ',',-1);

-- Change Y and N to Yes and No in "Sold as Vacant" field
select distinct(soldAsVacant),count(SoldAsVacant) from nashvillehousing 
group by SoldAsVacant order by 2;

select soldAsVacant,
case when soldAsVacant = 'Y' then 'Yes'
when soldAsVacant = 'N' then 'No'
else soldAsVacant
END
from nashvillehousing;

update nashvillehousing set soldAsVacant = case when soldAsVacant = 'Y' then 'Yes'
when soldAsVacant = 'N' then 'No'
else soldAsVacant
END;

-- Remove Duplicates
WITH RowNumCTE AS(
select *,row_number() over (partition by parcelId,PropertyAddress,SalePrice,
SaleDate,LegalReference 
-- Order by uniqueID
) row_num from nashvillehousing 
-- order by ParcelID
)
select * from RowNumCTE where row_num >1 order by propertyAddress;

WITH RowNumCTE AS(
select *,row_number() over (partition by parcelId,PropertyAddress,SalePrice,
SaleDate,LegalReference 
-- Order by uniqueID
) as row_num from nashvillehousing 
-- order by ParcelID
)
delete from RowNumCTE where row_num >1 ;

DELETE n
FROM nashvillehousing n
JOIN (
    SELECT uniqueID
    FROM (
        SELECT uniqueID, 
               ROW_NUMBER() OVER (PARTITION BY parcelId, PropertyAddress, SalePrice, SaleDate, 
               LegalReference ORDER BY uniqueID) AS row_num
        FROM nashvillehousing
    ) AS RowNumCTE
    WHERE row_num > 1
) AS ToDelete
ON n.uniqueID = ToDelete.uniqueID;
-- ORDER BY n.propertyAddress

-- Delete unused columns

alter table nashvillehousing drop column owneraddress,drop column taxdistrict,
drop column propertyaddress, drop column saledate;
