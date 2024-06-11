/* 
Cleaning Data in SQL Queries

Using a dataset based on housing in NASHVILLE

*/



select * 
from PortfolioProject.dbo.NashvilleHousing

-----------------------------------------------------
--===================================================
-----------------------------------------------------

-- Standardising date format

select SaleDate, CONVERT(Date,SaleDate)
from NashvilleHousing

UPDATE NashvilleHousing
set SaleDate = CONVERT(Date,SaleDate)

ALTER TABLE NashvilleHousing
add SaleDateConverted Date;

UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

select SaleDate, saledateconverted from NashvilleHousing

-----------------------------------------------------
--===================================================
-----------------------------------------------------

-- Populate Property Address Data

select PropertyAddress from NashvilleHousing
where [PropertyAddress] is not null

select * from NashvilleHousing
--where PropertyAddress is null
order by ParcelID

/*             -UNDERSTANDING THE PROBLEM

Currently the data has a set of Property Adress' being filled as null, however the are some rows of data
Which have the same PARCELID but have the correct property address.

Parcel ID and Property address are directly linked, so in order to fill in the data we will look to carry over/FILL IN the correct property address based on parcel id

-----------------------------------------------------
--===================================================
-----------------------------------------------------

Self joining to fill in Property Address 
Using unique id is != you are able to get rid of duplicates so you only see the parcel ids where b.propertyaddress is not null

*/
select a.parcelID, a.PropertyAddress, b.parcelID, b.PropertyAddress , ISNULL(a.propertyaddress,b.PropertyAddress)
from NashvilleHousing as a
join NashvilleHousing as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ] -- <> is not equal to != 
where a.PropertyAddress is null

-- If a.propertyAddress is null then fill it in with B.propertyAddress
-- Based on a self join where the parcel IDs are matching, and the unique ids arent the same
-- In all instances where A.propertyAddress is null ANYWAYS
UPDATE a
Set propertyaddress = ISNULL(a.propertyaddress,b.PropertyAddress)
from NashvilleHousing as a
join NashvilleHousing as b
	on a.ParcelID = b.ParcelID
	and a.[UniqueID ] <> b.[UniqueID ] -- <> is not equal to != 
where a.PropertyAddress is null

select * from NashvilleHousing
where PropertyAddress is null

-----------------------------------------------------
--===================================================
-----------------------------------------------------
--Breaking out address into individual columns (Address, City, State)
--- Here i have created 2 additional columns:  PropertySplitAddress and PropertySplitCity.
--- Allowing for easier way to differentiate the original Property Address


select PropertyAddress from NashvilleHousing
--where PropertyAddress is null
--order by ParcelID

----- Naming an Address column --- Slicing COMMA BEFORE
-- CHARINDEX serves as a Counter. A counter which counts from the beginning of a column untill it reaches a certain character
-- So in the below code, Substring is starting its slice from the first character. Untill Charindex detected a ,
-- This gives us the first part of the string up till the comma. We then name this column/set of results as Address

----- Naming the City Column --- Slicing COMMA ONWARDS
-- Again using substring but the starting point is value at which the comma was detected (+2 for convention)
-- Up untill the end of the string (represented by a LEN function returning the full string character count) 
-- Giving us a slice of a string from the comma ONWARDS


SELECT 
SUBSTRING(propertyaddress,1,CHARINDEX(',',PropertyAddress)-1) as Address,
SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+2, len(propertyAddress)) as City,
PropertyAddress
from portfolioproject.dbo.NashvilleHousing

ALTER TABLE NashvilleHousing
add PropertySplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitAddress = SUBSTRING(propertyaddress,1,CHARINDEX(',',PropertyAddress)-1)

select * from NashvilleHousing

ALTER TABLE NashvilleHousing
add PropertySplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET PropertySplitCity = SUBSTRING(PropertyAddress,CHARINDEX(',',PropertyAddress)+2, len(propertyAddress))

select * from NashvilleHousing


-----------------------------------------------------
--===================================================
-----------------------------------------------------
--Adding in the new columns, then populating them with the above query

select OwnerAddress from NashvilleHousing
where OwnerAddress is not null

--- Separating out the Owner Addres

-- PARSENAME only works with FULLSTOPS!
-- So first step is to use the replace function to change the COMMAS to FULLSTOPS
-- PARSENAME then returns the segment of string untill it meets that fullstop , based on the index number given
-- The original text of owner address has 3 COMMAS. But now its being split in to 3 different sets of strings which we can call as seen below

select 
PARSENAME(REPLACE(owneraddress,',','.'),3),
PARSENAME(REPLACE(owneraddress,',','.'),2),
PARSENAME(REPLACE(owneraddress,',','.'),1)
from NashvilleHousing
where owneraddress is not null

-- Then just assign each set to a new column! (FIRST CREATE AN EMPTY COLUMN TO POPULATE)

ALTER TABLE NashvilleHousing
add OwnerSplitAddress Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitAddress = PARSENAME(REPLACE(owneraddress,',','.'),3)

ALTER TABLE NashvilleHousing
add OwnerSplitCity Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitCity = PARSENAME(REPLACE(owneraddress,',','.'),2)

ALTER TABLE NashvilleHousing
add OwnerSplitState Nvarchar(255);

UPDATE NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(owneraddress,',','.'),1)

select * from NashvilleHousing
where owneraddress is not null

-----------------------------------------------------
--===================================================
-----------------------------------------------------

--Change Y and N to Yes and No in "Sold as Vacant" field

select distinct(SoldAsVacant),count(soldasvacant)
from NashvilleHousing
group by soldasvacant
Order by 2

select SoldAsVacant,
CASE when SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'NO'
	 ELSE SoldAsVacant
	 END
from PortfolioProject.dbo.NashvilleHousing

update NashvilleHousing
SET SoldAsVacant = CASE when SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'NO'
	 ELSE SoldAsVacant
	 END

-----------------------------------------------------
--===================================================
-----------------------------------------------------

--------------- Remove Duplicates
-- Using a CTE almost like a temp table
-- CTE also allows us to see the database with a temporary lense before commiting final changes which we dont in this case

WITH RowNumCTE AS (
select * ,
	ROW_NUMBER() OVER (
	PARTITION BY parcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER	by
					Uniqueid
					) row_num

from PortfolioProject.dbo.NashvilleHousing
--order by ParcelID
)
Select * from RowNumCTE
where row_num >1
/*
DELETE from RowNumCTE
Where row_num > 1 
*/

-----------------------------------------------------
--===================================================
-----------------------------------------------------

--Delete Unused Column

select * from PortfolioProject.dbo.NashvilleHousing

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict,PropertyAddress

ALTER TABLE PortfolioProject.dbo.NashvilleHousing
DROP COLUMN SaleDate

-----------------------------------------------------
--===================================================
-----------------------------------------------------

--Rename a column name

EXEC sp_rename 'dbo.NashvilleHousing.SaleDateConverted', 'Sale_Date', 'COLUMN';
select * from PortfolioProject.dbo.NashvilleHousing


