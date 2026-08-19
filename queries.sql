--1st
--Output the number of movies in each category, sorted descending.
SELECT c.name, COUNT(c.name) as cnt
FROM category c
JOIN film_category fc
  ON c.category_id = fc.category_id
GROUP BY c.category_id
ORDER BY cnt DESC

--2nd
--Output the 10 actors whose movies rented the most, sorted in descending order.
SELECT a.actor_id, 
       CONCAT(a.first_name,' ', a.last_name) as name,
	   COUNT(r.rental_id) as movie_cnt
FROM actor a
LEFT JOIN film_actor fa
  ON fa.actor_id = a.actor_id
LEFT JOIN inventory i
  ON i.film_id = fa.film_id
LEFT JOIN rental r
  ON r.inventory_id = i.inventory_id
GROUP BY a.actor_id, a.first_name, a.last_name
ORDER BY movie_cnt DESC LIMIT 10

--3rd
--Output the category of movies on which the most money was spent.
SELECT c.category_id, c.name, COALESCE(SUM(p.amount),0) as amt_spent 
FROM category c
LEFT JOIN film_category fc
  ON c.category_id = fc.category_id
LEFT JOIN inventory i
  ON i.film_id = fc.film_id
LEFT JOIN rental r
  ON r.inventory_id = i.inventory_id
LEFT JOIN payment p
  ON p.rental_id = r.rental_id
GROUP BY c.category_id, c.name
ORDER BY amt_spent DESC LIMIT 1

--4th
--Print the names of movies that are not in the inventory. Write a query without using the IN operator.
SELECT f.film_id, f.title
FROM film f
WHERE NOT EXISTS (
	SELECT 1
	FROM inventory i
	WHERE i.film_id = f.film_id
)


--5th
--Output the top 3 actors who have appeared the most in movies in the “Children” category. 
--If several actors have the same number of movies, output all of them.
WITH actor_film_count AS (
	SELECT a.actor_id,
	       a.first_name,
		   a.last_name,
		   COUNT(fa.film_id) as cnt
	FROM actor a
	JOIN film_actor fa
	  ON fa.actor_id = a.actor_id
	JOIN film_category fc
	  ON fc.film_id = fa.film_id
	JOIN category c
	  ON c.category_id = fc.category_id
	WHERE c.name = 'Children'
	GROUP BY a.actor_id, a.first_name, a.last_name
), 
ranked_actor_film_count AS (
	SELECT 
		DENSE_RANK() OVER (
			ORDER BY cnt DESC
		) AS ranking,
		actor_id,
		cnt,
		CONCAT(first_name, ' ', last_name) as name
	FROM actor_film_count
)

SELECT *
FROM ranked_actor_film_count
WHERE ranking<=3

--6th
--Output cities with the number of active and inactive customers (active - customer.active = 1). 
--Sort by the number of inactive customers in descending order.
SELECT city.city_id,
	   city.city,
	   SUM(CASE WHEN c.active=1 THEN 1 ELSE 0 END) as active_cnt,
	   SUM(CASE WHEN c.active=0 THEN 1 ELSE 0 END) as inactive_cnt
FROM city
LEFT JOIN address a
  ON city.city_id = a.city_id
LEFT JOIN customer c
  ON a.address_id = c.address_id
GROUP BY city.city_id, city.city, c.active
ORDER BY inactive_cnt DESC


--7th
--Output the category of movies that have the highest number of total rental hours in the city (customer.address_id in this city) and that start with the letter “a”. 
--Do the same for cities that have a “-” in them. Write everything in one query.
WITH category_rank_per_city as (
	SELECT c.category_id,
	       c.name,
		   city.city_id,
		   city.city,
		   COALESCE(SUM(AGE(r.return_date, r.rental_date)), INTERVAL '0 days') as rent_time_per_category,
	       DENSE_RANK() OVER (PARTITION BY city.city_id ORDER BY COALESCE(SUM(AGE(r.return_date, r.rental_date)), INTERVAL '0 days') DESC) as ranking
	FROM category c
	JOIN film_category fc
	  ON fc.category_id = c.category_id
	JOIN inventory i
	  ON i.film_id = fc.film_id
	JOIN rental r
	  ON r.inventory_id = i.inventory_id
	JOIN customer
	  ON customer.customer_id = r.customer_id
	JOIN address a
	  ON a.address_id = customer.address_id
	JOIN city
	  ON city.city_id = a.city_id
	WHERE city.city ILIKE 'A%' OR city.city LIKE '%-%'
	GROUP BY city.city_id, city.city, c.category_id, c.name
)

SELECT *
FROM category_rank_per_city
WHERE ranking=1
