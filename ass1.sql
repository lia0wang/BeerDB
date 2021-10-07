-- COMP3311 21T3 Assignment 1
--
-- Fill in the gaps ("...") below with your code
-- You can add any auxiliary views/function that you like
-- The code in this file MUST load into a database in one pass
-- It will be tested as follows:
-- createdb test; psql test -f ass1.dump; psql test -f ass1.sql
-- Make sure it can load without errorunder these conditions


-- Q1: oldest brewery

create or replace view Q1(brewery)
as
...
;

-- Q2: collaboration beers

create or replace view Q2(beer)
as
...
;

-- Q3: worst beer

create or replace view Q3(worst)
as
...
;

-- Q4: too strong beer

create or replace view Q4(beer,abv,style,max_abv))
as
...
;

-- Q5: most common style

create or replace view Q5(style)
as
...
;

-- Q6: duplicated style names

create or replace view Q6(style1,style2)
as
...
;

-- Q7: breweries that make no beers

create or replace view Q7(brewery)
as
...
;

-- Q8: city with the most breweries

create or replace view Q8(city,country)
as
...
;

-- Q9: breweries that make more than 5 styles

create or replace view Q9(brewery,nstyles)
as
...
;

-- Q10: beers of a certain style

create or replace function
	q10(_style text) returns setof BeerInfo
as $$
...
$$
language plpgsql;

-- Q11: beers with names matching a pattern

create or replace function
	Q11(partial_name text) returns setof text
as $$
...
$$
language plpgsql;

-- Q12: breweries and the beers they make

create or replace function
	Q12(partial_name text) returns setof text
as $$
...
$$
language plpgsql;
