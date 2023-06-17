# Music Store Data Analysis in MySQL:

# Set I
# Q.1 Who is the senior most employee on job title?
select * from employee order by levels DESC limit 1;

# Q.2 Which country has the most invoices?
select count(*) as c, billing_country 
from invoice 
group by billing_country
order by c DESC limit 1;

# Q.3 What are top 3 values of total invoices?
select total from invoice order by total Desc limit 3;

# Q.4 Which city has the best customers? We would like to throw a promotional 
-- music festival in the city we made the most money. Write a query that 
-- returns one city that has the highest of invoice totals. Return both 
-- the city name and invoice totals.

select round(sum(total)) as invoice_total, billing_city 
from invoice
group by billing_city
order by invoice_total desc limit 1;

# Q.5 Who is the best customer? The customer who has spent 
-- the most money will be declared as the best customer.

select customer.customer_id, customer.first_name, customer.last_name, sum(invoice.total) as totalw
from customer
join invoice on customer.customer_id = invoice.customer_id
group by customer.customer_id
order by totalw desc limit 3;

# Set II
# Q.1 Write a query to return email, first name, last name, genre of all Rock music 
-- listeners return your list ordered alphabetically by emails starting with A.

select distinct email, first_name, last_name
from customer
join invoice on customer.customer_id = invoice.customer_id
Join invoice_line on invoice.invoice_id = invoice_line.invoice_id
where track_id in(
       select track_id from track 
       join genre on track.genre_id = genre.genre_id
       where genre.name like 'Rock'
)
order by email;

# Q.2 Let's invite the top ten artists who has written the most rock music.

select artist.artist_id, artist.name, count(artist.artist_id) as number_of_songs
from track
join  album  on album.album_id   = track.album_id
join  artist on artist.artist_id = album.artist_id
join  genre  on genre.genre_id   = track.genre_id
where genre.name like 'Rock'
group by artist.artist_id
order by number_of_songs desc
limit 10;

# Q.3 Return all the track names that have strong length longer than the average song length. 
-- Return the name and milliseconds for each track. Order by the song length so that the longest song come first.

select name, milliseconds from track
where milliseconds > (select avg(milliseconds) as AVG_Length from track)
order by milliseconds desc;

# Set III
# Q.1 Find how much amount spent by each customers on artists. 
-- Write a query to return customer name, artist name and total spent.

with best_selling_artist as (
select artist.artist_id as artist_id, artist.name as artist_name,
sum(invoice_line.unit_price*invoice_line.quantity) as total_sales
from invoice_line
join track on track.track_id = invoice_line.track_id
join album on album.album_id = track.album_id
join artist on artist.artist_id = album.artist_id
group by 1
order by 3 desc
limit 1
)
select c.customer_id, c.first_name, c.last_name, bsa.artist_name, 
sum(il.unit_price*il.quantity) as amount_spent from invoice i
join customer c on c.customer_id = i.customer_id
join invoice_line il on il.invoice_id = i.invoice_id
join track t on t.track_id = il.track_id
join album alb on alb.album_id = t.album_id
join best_selling_artist bsa on bsa.artist_id = alb.artist_id
group by 1,2,3,4
order by 5 desc;

# Q.2 We want to find out the most popular music Genre for each country. 
-- We determine the most popular genre as the genre with highest amount of purchases.
-- Write a query that returns each country along with the top genre.
-- For countries where maximum number of purchases is shared return all Genres.

WITH popular_genre AS 
(
    SELECT COUNT(invoice_line.quantity) AS purchases, customer.country, genre.name, genre.genre_id, 
	ROW_NUMBER() OVER(PARTITION BY customer.country ORDER BY COUNT(invoice_line.quantity) DESC) AS RowNo 
    FROM invoice_line 
	JOIN invoice ON invoice.invoice_id = invoice_line.invoice_id
	JOIN customer ON customer.customer_id = invoice.customer_id
	JOIN track ON track.track_id = invoice_line.track_id
	JOIN genre ON genre.genre_id = track.genre_id
	GROUP BY 2,3,4
	ORDER BY 2 ASC, 1 DESC
)
SELECT * FROM popular_genre WHERE RowNo <= 1

# Q.3 Write a query that determines the customer that has spent the most on music for each country. 
-- Write a query that returns the country along with the top customer and how much they spent. 
-- For countries where the top amount spent is shared, provide all customers who spent this amount.

WITH Customter_with_country AS (
		SELECT customer.customer_id, first_name, last_name, billing_country, SUM(total) AS total_spending,
	    ROW_NUMBER()
        OVER ( PARTITION BY billing_country ORDER BY SUM(total) DESC ) AS RowNo 
		FROM invoice
		JOIN customer ON customer.customer_id = invoice.customer_id
		GROUP BY 1,2,3,4
		ORDER BY 4 ASC, 5 DESC )
SELECT * FROM Customter_with_country WHERE RowNo <= 1