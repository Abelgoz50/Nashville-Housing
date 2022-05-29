SELECT * FROM PortfolioProject..NashvilleHousing

-- REMOVE TIME DATA FROM SALE DATE COLUMN

-- See SaleDate and converted data side by side
SELECT SaleDate, CONVERT(Date, SaleDate)
FROM PortfolioProject..NashvilleHousing

-- Add column to store converted dates
ALTER TABLE NashvilleHousing
ADD SaleDateConverted Date

-- Populate new column with coverted data from SaleDate column
UPDATE NashvilleHousing
SET SaleDateConverted = CONVERT(Date,SaleDate)

-- See SaleDate and SaleDateConverted side by side (remove SaleDate later?)
SELECT SaleDate, SaleDateConverted
FROM PortfolioProject..NashvilleHousing


-- POPULATE PROPERTY ADDRESS DATA

-- Check PropertyAddress column for NULL entries
SELECT PropertyAddress
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL

-- Since ParcelID and PropertyAddress are always linked and unique but can appear in multiple rows,
-- join table to itself on parcelID but when uniqueID is different = all NULLs and their matches (same parcelID but diff uniqueID)
SELECT a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Set NULLs as "ISNULL" from above (sets as correct address linked to that parcelID but under a diff uniqueID)
UPDATE a
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
FROM PortfolioProject..NashvilleHousing a
JOIN PortfolioProject..NashvilleHousing b
	ON a.ParcelID = b.ParcelID
	AND a.[UniqueID ] <> b.[UniqueID ]
WHERE a.PropertyAddress IS NULL

-- Double checking
SELECT *
FROM PortfolioProject..NashvilleHousing
WHERE PropertyAddress IS NULL


-- BREAKING OUT ADDRESS INTO INDIVIDUAL COLUMNS (STREET, CITY)

-- Isolating PropertyAddress from beginning to comma (street) & comma to the end (city)
SELECT PropertyAddress, SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1) AS Address,
SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress)) AS City
FROM PortfolioProject..NashvilleHousing

-- Adding Property Street and City columns to fill in above data
ALTER TABLE NashvilleHousing
ADD PropertyStreet NVARCHAR(255);

UPDATE NashvilleHousing
SET PropertyStreet = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress)-1)

ALTER TABLE NashvilleHousing
ADD PropertyCity NVARCHAR(255)

UPDATE NashvilleHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress)+2, LEN(PropertyAddress))

SELECT PropertyStreet, PropertyCity
FROM PortfolioProject..NashvilleHousing


-- BREAKING OUT OWNERADDRESS (STREET, CITY, STATE) INTO SEPARATE COLUMNS

-- Use ParseName to break into sections by period '.' delimiter
SELECT PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3), PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2), PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)
FROM PortfolioProject..NashvilleHousing

-- Adding Owner Street, City, and State columns and filling with data above
ALTER TABLE NashvilleHousing
ADD OwnerStreet NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerStreet = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)

ALTER TABLE NashvilleHousing
ADD OwnerCity NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)

ALTER TABLE NashvilleHousing
ADD OwnerState NVARCHAR(255)

UPDATE NashvilleHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1)

SELECT * FROM PortfolioProject..NashvilleHousing


-- CHANGE Y & N TO YES & NO IN "SoldAsVacant" COLUMN

-- Get a count of how many times Y, N, Yes, & No are used
SELECT DISTINCT(SoldAsVacant), COUNT(SoldAsVacant)
FROM PortfolioProject..NashvilleHousing
GROUP BY SoldAsVacant
ORDER BY 2 DESC

-- Testing CASE statement to do this replacement
SELECT SoldAsVacant,
CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END
FROM PortfolioProject..NashvilleHousing

-- Update the data in SoldAsVacant column by the CASE statement
UPDATE NashvilleHousing
SET SoldAsVacant = CASE WHEN SoldAsVacant = 'Y' THEN 'Yes'
	 WHEN SoldAsVacant = 'N' THEN 'No'
	 ELSE SoldAsVacant
	 END


-- REMOVE DUPLICATE ROW ENTRIES

-- Using CTE, partition by enough columns to ensure truly duplicate, duplicates identified by >1 value in new column
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
)
SELECT * FROM RowNumCTE
WHERE row_num > 1
ORDER BY PropertyAddress

-- Delete the duplicates
WITH RowNumCTE AS(
SELECT *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num
FROM PortfolioProject..NashvilleHousing
)
DELETE
FROM RowNumCTE
WHERE row_num > 1


-- REMOVE UNUSED COLUMNS

-- Use DROP COLUMN to remove unnecessary columns
ALTER TABLE PortfolioProject..NashvilleHousing
DROP COLUMN PropertyAddress, OwnerAddress, TaxDistrict

SELECT * FROM PortfolioProject..NashvilleHousing