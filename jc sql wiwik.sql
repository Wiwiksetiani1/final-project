create schema jc
AUTHORIZATION postgres;
create table jc.user_tab (
    userid INT PRIMARY KEY,
    register_time DATE,
    country VARCHAR(10)
);
select *
from jc.user_tab;

create table jc.order_tab(
orderid SERIAL PRIMARY KEY,
    userid INT,
    itemid INT,
    gmv DECIMAL,
    order_time DATE
);
select *
from jc.order_tab;

--- 1. Hitung banyaknya user per negara

SELECT 
	country, 
	COUNT(DISTINCT userid) AS user_count
FROM jc.user_tab
GROUP BY country;

--- 2. Hitung banyaknya order per negara

SELECT 
	country, 
	COUNT(orderid) AS order_count
FROM jc.user_tab AS u
LEFT JOIN jc.order_tab AS o
	ON u.userid = o.userid	
GROUP BY country;

--- 3. Tampilkan tanggal order pertama untuk setiap user

SELECT 
	userid, 
	MIN(order_time) AS first_ordertime
FROM jc.order_tab 
GROUP BY userid;

--- 4. Hitung nilai belanja dari first order untuk setiap user, 
--- urutkan berdasarkan order id (ascending)

WITH first_orders AS (
    SELECT 
        o.userid,
        o.orderid,
        o.order_time,
        o.gmv,
        ROW_NUMBER() OVER (PARTITION BY o.userid ORDER BY o.order_time ASC) AS row_num
    FROM jc.order_tab AS o
)

SELECT 
    f.userid,
    f.orderid,
    f.order_time,
    f.gmv AS first_order_value
FROM 
    first_orders f
WHERE 
    f.row_num = 1
ORDER BY 
    f.orderid ASC;

--- 5. Identifikasi anomali pada data (order_time tercatat pada tanggal sebelum register_time)

SELECT 
    o.orderid,
    o.userid,
    o.order_time,
    o.gmv,
    u.register_time
FROM jc.order_tab AS o
LEFT JOIN jc.user_tab AS u
	ON o.userid = u.userid
WHERE 
    o.gmv <= 0 OR  -- Mendeteksi GMV yang tidak valid
    o.order_time < u.register_time OR  -- Mendeteksi waktu order yang tidak sesuai
    u.userid IS NULL;  -- Mendeteksi user yang tidak ada dalam data pengguna


