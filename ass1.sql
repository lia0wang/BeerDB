-- COMP3311 21T3 Assignment 1
--
-- Fill in the gaps ("...") below with your code
-- You can add any auxiliary views/function that you like
-- The code in this file MUST load into a database in one pass
-- It will be tested as follows:
-- createdb test; psql test -f ass1.dump; psql test -f ass1.sql
-- Make sure it can load without errorunder these conditions


-- Q1: oldest brewery
-- earliest founded

CREATE OR REPLACE VIEW Q1(brewery)
AS
SELECT name
FROM breweries
WHERE founded = (SELECT MIN(founded) FROM breweries)
;

-- Q2: collaboration beers
-- beers wich has > 1 brewery, defined by their id

CREATE OR REPLACE VIEW Q2(beer)
AS
SELECT name
FROM beers
JOIN brewed_by ON beers.id = brewed_by.beer
GROUP BY id
HAVING COUNT(brewery) > 1
;

-- Q3: worst beer
-- lowest rating

CREATE OR REPLACE VIEW Q3(worst)
AS
SELECT name
FROM beers
WHERE rating = (SELECT MIN(rating) FROM beers)
;

-- Q4: too strong beer
-- beers whose ABV is higher than the maximum ABV for their style

CREATE OR REPLACE VIEW Q4(beer,abv,style,max_abv)
AS
SELECT beers.name, beers.abv, styles.name, styles.max_abv
FROM beers
JOIN styles ON beers.style = styles.id
WHERE beers.abv > styles.max_abv
;

-- Q5: most common style
-- determined by the number of beers brewed to that style

CREATE OR REPLACE VIEW V1(name, number)
AS
SELECT styles.name, COUNT(*)
FROM styles
JOIN beers ON beers.style = styles.id
GROUP BY styles.name
;

CREATE OR REPLACE VIEW Q5(style)
AS
SELECT name
FROM V1
WHERE NUMBER = (SELECT MAX(number) FROM V1)
;

-- Q6: duplicated style names
-- differ only in the upper/lower case of their letters
-- the lexicographically smaller style name should be in style1.

CREATE OR REPLACE VIEW Q6(style1,style2)
AS
SELECT A.name AS style1, B.name AS style2
FROM styles A, styles B
WHERE A.name < B.name
AND LOWER(A.name) = LOWER(B.name)
;

-- Q7: breweries that make no beers

CREATE OR REPLACE VIEW Q7(brewery)
AS
SELECT name AS brewery
FROM breweries
WHERE id NOT IN (SELECT brewery FROM brewed_by)
;

-- Q8: city with the most breweries

CREATE OR REPLACE VIEW V2(id,number)
AS
SELECT locations.id, COUNT(locations.id)
FROM locations
JOIN breweries ON locations.id = breweries.located_in
WHERE locations.metro IS NOT NULL
GROUP BY locations.id;

CREATE OR REPLACE VIEW Q8(city,country)
AS
SELECT locations.metro AS city, locations.country
FROM locations
JOIN v2 ON locations.id = v2.id
WHERE v2.number = (SELECT max(v2.number) FROM v2)
;

-- Q9: breweries that make more than 5 styles

CREATE OR REPLACE VIEW Q9(brewery,nstyles)
AS
SELECT breweries.name AS brewery, COUNT(DISTINCT styles.id) AS nstyles
FROM brewed_by
JOIN breweries ON brewed_by.brewery = breweries.id
JOIN beers ON brewed_by.beer = beers.id
JOIN styles ON beers.style = styles.id
GROUP BY breweries.name
HAVING COUNT(DISTINCT styles.id) > 5
;

-- Q10: beers of a certain style
-- create type BeerInfo as 
-- (beer text, brewery text, style text, year YearValue, abv ABVvalue)

CREATE OR REPLACE VIEW BeerInfo(beer, brewery, style, year, abv)
AS
SELECT DISTINCT beers.name, a.l, styles.name, beers.brewed, beers.abv
FROM (
	SELECT Brewed_by.beer as id, string_agg(Breweries.name, ' + ') as l
	FROM Brewed_by
	JOIN Breweries ON Breweries.id = Brewed_by.brewery
	GROUP BY Brewed_by.beer
)a
JOIN Beers ON Beers.id = a.id
JOIN Styles ON Beers.style = Styles.id
;

create or replace function
    q10(_style text) returns setof BeerInfo
as $$
declare
    emp record;
begin
    for emp in 
        SELECT * FROM BeerInfo WHERE BeerInfo.style = _style
    loop
        return next emp;
    end loop;
end;
$$
language plpgsql;

-- Q11: beers with names matching a pattern

create or replace view IdCollab(id, collab)
as
SELECT Brewed_by.beer, string_agg(Breweries.name, ' + ')
FROM Brewed_by
JOIN Breweries ON Breweries.id = Brewed_by.brewery
GROUP BY Brewed_by.beer
;

create or replace view BeerInfo(beer, brewery, style, abv)
as
SELECT Beers.name, IdCollab.collab, Styles.name, Beers.ABV
FROM IdCollab
JOIN Beers ON Beers.id = IdCollab.id
JOIN Styles ON Beers.style = Styles.id
;

create or replace function
    Q11(partial_name text) returns setof text
as $$
declare
    emp record;
    pattern text;
begin
    pattern := '%' || partial_name || '%';
    for emp in 
        SELECT beer, brewery, style, abv FROM BeerInfo WHERE LOWER(beer) LIKE LOWER(pattern)
    loop
        return next '"' || emp.beer || '"' || ', ' || emp.brewery || ', ' || emp.style || ', ' || emp.abv || '% ABV';
    end loop;
end;
$$
language plpgsql;

-- Q12: breweries and the beers they make

create or replace function
    Q12(partial_name text) returns setof text
as $$
declare
    emp record;
    bemp record;
    about_brewery text;
    pattern text;
    town text;
    metro text;
    region text;
    country text;
    located text;
begin
    pattern := '%' || partial_name || '%';
    for emp in
        SELECT Breweries.id, Breweries.name, Breweries.founded, Breweries.located_in
        FROM Breweries
        WHERE LOWER(Breweries.name) LIKE LOWER(pattern)
        ORDER BY Breweries.name
    loop
        return next emp.name || ', founded ' || emp.founded;
        located := 'located in ';
        town := (SELECT Locations.town FROM Locations WHERE emp.located_in = Locations.id);
        metro := (SELECT Locations.metro FROM Locations WHERE emp.located_in = Locations.id);
        region := (SELECT Locations.region FROM Locations WHERE emp.located_in = Locations.id);
        country := (SELECT Locations.country FROM Locations WHERE emp.located_in = Locations.id);
        if (town IS NOT NULL AND METRO is not NULL) then
            located := located || town || ', ';
        elsif (town IS NOT NULL) then    
            located := located || town || ', ';
        elsif (metro IS NOT NULL) then
            located := located || metro || ', ';
        end if;
        
        if (region IS NOT NULL) then
            located := located || region || ', ';
        end if;
        located := located || country;
        return next located;

        for bemp in 
            SELECT Beers.name, Styles.name as style, Beers.brewed, Beers.ABV
            FROM Beers
            JOIN Styles ON Styles.id = Beers.style
            JOIN Brewed_by ON Brewed_by.beer = Beers.id AND Brewed_by.brewery = emp.id
            ORDER BY Beers.brewed ASC, Beers.name
        loop
            return next '  "' || bemp.name || '", ' || bemp.style || ', ' || bemp.brewed || ', ' || bemp.ABV || '% ABV';
        end loop;
            
        if (NOT FOUND) then
            return next '  No known beers';
        end if;
    end loop;
end;
$$
language plpgsql;