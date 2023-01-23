

  -- Cleaning Data in SQL Queries
  
  SELECT * FROM NashvilleHousing;

  -- Standardize Sale Date

  SELECT SaleDate, CONVERT(date, SaleDate)
  FROM NashvilleHousing;

  ALTER TABLE NashvilleHousing
  ADD SaleDateConverted Date;  
  
  UPDATE NashvilleHousing
  SET SaleDateConverted = CONVERT(date, SaleDate);

  SELECT SaleDateConverted
  FROM NashvilleHousing;

  ------------------------------------------------------------------------

  -- Populate Property Address Data

   SELECT * FROM NashvilleHousing -- WHERE PropertyAddress IS NULL;
   ORDER BY ParcelID;

   SELECT n1.ParcelID, n1.PropertyAddress, n2.ParcelID, n2.PropertyAddress, ISNULL(n1.PropertyAddress, n2.PropertyAddress)
   FROM NashvilleHousing AS n1
   JOIN NashvilleHousing AS n2
   ON n1.ParcelID = n2.ParcelID 
   AND n1.[UniqueID ] <> n2.[UniqueID ]
   WHERE n1.PropertyAddress IS NULL;

   UPDATE n1
   SET PropertyAddress = ISNULL(n1.PropertyAddress, n2.PropertyAddress)
   FROM NashvilleHousing AS n1
   JOIN NashvilleHousing AS n2
   ON n1.ParcelID = n2.ParcelID 
   AND n1.[UniqueID ] <> n2.[UniqueID ]
   WHERE n1.PropertyAddress IS NULL;

   --Update (29 rows affected)

  ------------------------------------------------------------------------

  --Breaking out Address into Individual Columns (Address, City, State)
  SELECT * FROM NashvilleHousing

  SELECT PropertyAddress FROM NashvilleHousing; 
  -- WHERE PropertyAddress IS NULL
  -- ORDER BY ParcelID;
  
   SELECT 
   SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1) AS Address,
   TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress))) AS City
   FROM NashvilleHousing;

   -- DDL - ADD PropertySpilt[Address/City] Column to Table 
   ALTER TABLE NashvilleHousing
   ADD PropertySpiltAddress nvarchar(255);

   ALTER TABLE NashvilleHousing
   ADD PropertySpiltCity nvarchar(255);

   -- DDL - ADD OwnerSpilt[Address/City/State] Column to Table 
   ALTER TABLE NashvilleHousing
   ADD OwnerSpiltAddress nvarchar(255);

    ALTER TABLE NashvilleHousing
   ADD OwnerSpiltCity nvarchar(255);

    ALTER TABLE NashvilleHousing
   ADD OwnerSpiltState nvarchar(2);




   -- DML - UPDATE PropertySpilt[Address/City] Column  Using SUBSTRING()
   UPDATE NashvilleHousing
   SET PropertySpiltAddress = TRIM(SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress)-1));
   
   UPDATE NashvilleHousing
   SET PropertySpiltCity = TRIM(SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress)+1, LEN(PropertyAddress)));



   -- DML - UPDATE OwnerSpilt[Address/City/State] Column  Using PARSENAME()
  SELECT 
    PARSENAME(REPLACE(OwnerAddress,',','.') , 3) AS Address,
    PARSENAME(REPLACE(OwnerAddress,',','.') , 2) AS City,
    PARSENAME(REPLACE(OwnerAddress,',','.') , 1) AS State 
   FROM NashvilleHousing
   WHERE OwnerAddress IS NOT NULL;

   UPDATE NashvilleHousing
   SET 
	OwnerSpiltAddress = PARSENAME(REPLACE(OwnerAddress,',','.') , 3),
	OwnerSpiltCity = PARSENAME(REPLACE(OwnerAddress,',','.') , 2),
	OwnerSpiltState = TRIM(PARSENAME(REPLACE(OwnerAddress,',','.') , 1));

	SELECT * FROM NashvilleHousing

  ----------------------------------------------------------------------

  -- Change Y to N to Yes and No "Sold as Vacant" field (Standarized Data) 

 SELECT DISTINCT SoldAsVacant
 FROM NashvilleHousing;

 SELECT SoldAsVacant, COUNT(*) AS #ofResponses
 FROM NashvilleHousing
 GROUP BY SoldAsVacant;

 WITH 
	cte (CorrectedSoldAsVacant, #ofResponses)
	AS(
	SELECT
	CASE 
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
	END AS CorrectedSoldAsVacant,
	COUNT(*) AS #ofResponses
	FROM NashvilleHousing
	WHERE SoldAsVacant <> 'Yes' AND SoldAsVacant <> 'No'
	GROUP BY SoldAsVacant
	)
 SELECT CorrectedSoldAsVacant, #ofResponses,
	SUM(#ofResponses) OVER(Order By #ofResponses DESC) AS RunningTotal
 FROM cte
 GROUP BY CorrectedSoldAsVacant, #ofResponses;

 SELECT
	CASE 
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
	END
 FROM NashvilleHousing
 WHERE SoldAsVacant <> 'Yes' AND SoldAsVacant <> 'No';

 UPDATE NashvilleHousing
 SET SoldAsVacant = 
	CASE 
		WHEN SoldAsVacant = 'N' THEN 'No'
		WHEN SoldAsVacant = 'Y' THEN 'Yes'
	END
 WHERE SoldAsVacant <> 'Yes' AND SoldAsVacant <> 'No';

 SELECT DISTINCT SoldAsVacant FROM NashvilleHousing;

  ----------------------------------------------------------------------

  -- Remove duplicates
WITH 
	RowNumCTE AS(
  SELECT *,
	ROW_NUMBER() OVER(PARTITION BY ParcelID,
							 PropertyAddress,
							 SaleDate,
							 SalePrice,
							 LegalReference
			   ORDER BY UniqueID
	)  AS row_num
  FROM NashvilleHousing
  )

  --DELETE
  SELECT *
  FROM RowNumCTE
  --WHERE row_num > 1;

  ----------------------------------------------------------------------


  -- Delete Unused Fields

  SELECT * 
  FROM  NashvilleHousing

   -- DROP Columns -> OwnerAddress, TaxDistrict, PropertyAddress, SaleDate
   -- Columns were droped because: 
	-- 1. Extracted Essential Data from Columns (OwnerAddress,PropertyAddress, SaleDate)
	-- 2. Information does not provide any value for analysis

   ALTER TABLE NashvilleHousing
   DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate;
	
