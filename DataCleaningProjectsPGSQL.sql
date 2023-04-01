create table housingdata (
	UniqueID int,
	ParcelID text,
	LandUse text,
	PropertyAddress varchar,
	SaleDate date,
	SalePrice text,	
	LegalReference varchar,
	SoldAsVacant text,
	OwnerName text,
	OwnerAddress varchar,
	Acreage numeric,
	TaxDistrict	text,
	LandValue int,
	BuildingValue int,
	TotalValue int,
	YearBuilt text,
	Bedrooms text,
	FullBath text,	
	HalfBath text
)


select *
from housingdata
order by parcelid
limit 100

--standarize date format
select saledate, cast(saledate as date)
from housingdata

-- populate property address data

select *
from housingdata
where propertyaddress is null
order by parcelid

select a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress,
coalesce(a.propertyaddress, b.propertyaddress) as realaddress
from housingdata a
join housingdata b
	on a.parcelid = b.parcelid
	and a.uniqueid <> b.uniqueid
where a.propertyaddress is null

UPDATE housingdata
SET propertyaddress = propertyaddress
WHERE propertyaddress is null
AND uniqueid <> uniqueid
and parcelid = parcelid ;

update housingdata
set propertyaddress = coalesce(a.propertyaddress, b.propertyaddress)
from housingdata a
inner join housingdata b 
	on a.parcelid = b.parcelid
	and a.uniqueid <> b.uniqueid
where housingdata.propertyaddress is null
and a.propertyaddress is not null
-- Kondisi a.propertyaddress IS NOT NULL 
-- memastikan bahwa nilai COALESCE hanya akan diambil dari 
-- kolom a.propertyaddress jika nilainya tidak NULL.
-- jika tanpa a.propertyaddress is not null maka propertyaddress akan berisi value yg sama semua

-- breaking out address into individual column (address, city, state)
select propertyaddress
from housingdata
--where propertyaddress is null

select substring(propertyaddress, 1, strpos(propertyaddress, ',') -1) as address,
substring(propertyaddress, strpos(propertyaddress, ',') +1, length(propertyaddress)) as address
from housingdata

-- strpos adalah fungsi dalam PostgreSQL yang mengembalikan
-- posisi kemunculan pertama suatu substring dalam string tertentu
alter table housingdata
add PropertySplitAddress varchar

update housingdata
set PropertySplitAddress = substring(propertyaddress, 1, strpos(propertyaddress, ',') -1)

alter table housingdata
add PropertySplitCity varchar

update housingdata
set PropertySplitCity = substring(propertyaddress, strpos(propertyaddress, ',') +1, length(propertyaddress))

select *
from housingdata
limit 100

select owneraddress
from housingdata

select
	split_part(owneraddress, ',',1),
	split_part(owneraddress, ',',2),
	split_part(owneraddress, ',',3)
from housingdata
--split_part membagi string menjadi bagian-bagian berdasarkan
--pemisah dan mengembalikan elemen yang ditentukan oleh posisi

alter table housingdata
add OwnerSplitAddress varchar

update housingdata
set OwnerSplitAddress = split_part(owneraddress, ',',1)

alter table housingdata
add OwnerSplitCity varchar

update housingdata
set OwnerSplitCity = split_part(owneraddress, ',',2)

alter table housingdata
add OwnerSplitState varchar

update housingdata
set OwnerSplitState = split_part(owneraddress, ',',3)

select *
from housingdata

-- change Y and N to Yes and No in "Sold As Vacant"
select distinct(soldasvacant), count(soldasvacant)
from housingdata
group by soldasvacant
order by 2

select soldasvacant, 
	case when soldasvacant = 'Y' then 'Yes'
	when soldasvacant = 'N' then 'No'
	else soldasvacant
	end
from housingdata

update housingdata
set soldasvacant = case when soldasvacant = 'Y' then 'Yes'
	when soldasvacant = 'N' then 'No'
	else soldasvacant
	end

-- looking for duplicate data
with rownumcte as (
select *,
	row_number() over (
	partition by parcelid,
	propertyaddress,
	saleprice,
	saledate,
	legalreference
	order by uniqueid
	) row_num
from housingdata )
select * 
from rownumcte
where row_num > 1

-- remove duplication
with rownumcte as (
select *,
	row_number() over (
	partition by parcelid,
	propertyaddress,
	saleprice,
	saledate,
	legalreference
	order by uniqueid
	) row_num
from housingdata )
delete from housingdata
where uniqueid IN (
  SELECT uniqueid
  FROM rownumcte
  WHERE row_num > 1
	)

-- delet unused columns
select *
from housingdata

alter table housingdata
drop column owneraddress, 
drop column propertyaddress,
drop column taxdistrict