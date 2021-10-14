-- COMP3311 21T3 ASsignment 1
--
-- Fill in the gaps ("...") below with your code
-- You can add any auxiliary views/FUNCTION that you like
-- The code in this file MUST load into a databASe in one pASs
-- It will be tested AS follows:
-- createdb test; psql test -f ASs1.dump; psql test -f ASs1.sql
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
-- beers wich hAS > 1 brewery, defined by their id

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
-- differ only in the upper/lower cASe of their letters
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
-- create type BeerInfo AS 
-- (beer text, brewery text, style text, year YearValue, abv ABVvalue)

CREATE OR REPLACE VIEW BeerInfo(beer, brewery, style, year, abv)
AS
SELECT DISTINCT beers.name, co.combined_brewery,
                styles.name, beers.brewed, beers.abv
FROM beers
JOIN styles ON beers.style = styles.id
Join (
	SELECT brewed_by.beer AS id,
           string_agg(breweries.name, ' + ') AS combined_brewery
	FROM brewed_by
	JOIN breweries ON brewed_by.brewery = breweries.id
	GROUP BY brewed_by.beer
)co ON beers.id = co.id
;

CREATE OR REPLACE FUNCTION
    q10(_style text) RETURNS setof BeerInfo
AS $$
DECLARE
    info record;
BEGIN
    FOR info IN 
        SELECT *
        FROM BeerInfo
        WHERE BeerInfo.style = _style
    LOOP
        RETURN NEXT info;
    END LOOP;
END;
$$
LANGUAGE plpgsql;

-- Q11: beers with names matching a pattern
CREATE OR REPLACE FUNCTION
    Q11(partial_name text) RETURNS setof text
AS $$
DECLARE
    info record;
BEGIN
    FOR info IN 
        SELECT beer, brewery, style, abv
        FROM BeerInfo
        WHERE LOWER(beer) LIKE LOWER('%' || partial_name || '%')
    LOOP
        RETURN NEXT '"' || info.beer    || '", ' 
                        || info.brewery || ', ' 
                        || info.style   || ', ' 
                        || info.abv     || '% ABV';
    END LOOP;
END;
$$
LANGUAGE plpgsql;

-- Q12: breweries and the beers they make

CREATE OR REPLACE FUNCTION
    Q12(partial_name text) RETURNS setof text
AS $$
DECLARE
    brewery_info    record;
    beer_info       record;
    loc             text;
    t               text;
    m               text;
    r               text;
    c               text;
BEGIN
    FOR brewery_info IN
        SELECT name, founded, located_in, id
        FROM breweries
        WHERE LOWER(name) LIKE LOWER('%' || partial_name || '%')
        ORDER BY name
    LOOP
        --  Mountain Goat Beer, founded 1997s
        RETURN NEXT brewery_info.name || ', ' || 'founded ' || brewery_info.founded;

        --  located in Richmond, Victoria, Australia
        loc := 'located in ';
        
        t := (SELECT town FROM locations WHERE brewery_info.located_in = locations.id);
        m := (SELECT metro FROM locations WHERE brewery_info.located_in = locations.id);
        -- if both town and metro are known, include just the town
        IF t IS NOT NULL AND m IS NOT NULL then
            loc := loc || t || ', ';
        -- if only the metro is known, include that
        ELSIF m IS NOT NULL THEN
            loc := loc || m || ', ';
        -- if only the town is known, include that
        ELSIF t IS NOT NULL THEN    
            loc := loc || t || ', ';
        END IF;
        
        -- if a region is known, include that in the location string
        r := (SELECT region FROM locations WHERE brewery_info.located_in = locations.id);
        IF r IS NOT NULL THEN
            loc := loc || r || ', ';
        END IF;

        -- the country is always the last element in the string
        c := (SELECT country FROM locations WHERE brewery_info.located_in = locations.id);
        iF c IS NOT NULL THEN
            loc := loc || c;
        END IF;
        RETURN NEXT loc;

        -- "Name of beer", Beer style, Year brewed, abv_value% ABV
        FOR beer_info IN 
            SELECT beers.name, styles.name AS style, beers.brewed AS year, beers.abv
            FROM beers
            JOIN styles ON beers.style = styles.id
            JOIN brewed_by ON beers.id = brewed_by.beer AND brewery_info.id = brewed_by.brewery
            ORDER BY beers.brewed ASC, beers.name --  arranged in ascending order of year, beer name
        LOOP
            RETURN NEXT '  "' || beer_info.name     || '", '
                              || beer_info.style    || ', '
                              || beer_info.year     || ', '
                              || beer_info.abv      || '% ABV';
        END LOOP;

        -- if the brewery makes (so far) no beers,
        IF NOT FOUND THEN
            RETURN NEXT '  No known beers';
        END IF;
    END LOOP;
END;
$$
LANGUAGE plpgsql;