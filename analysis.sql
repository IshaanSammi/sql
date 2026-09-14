
-- Create Database
CREATE DATABASE IF NOT EXISTS OnlineBookstore;

-- Switch to the database
USE OnlineBookstore;

-- Create Tables

DROP TABLE IF EXISTS Orders;
DROP TABLE IF EXISTS Reviews;
DROP TABLE IF EXISTS Books;
DROP TABLE IF EXISTS Customers;

CREATE TABLE Books (
Book_ID INT AUTO_INCREMENT PRIMARY KEY,
Title VARCHAR(100),
Author VARCHAR(100),
Genre VARCHAR(50),
Published_Year INT,
Price DECIMAL(10, 2),
Stock INT
);

CREATE TABLE Customers (
Customer_ID INT AUTO_INCREMENT PRIMARY KEY,
Name VARCHAR(100),
Email VARCHAR(100),
Phone VARCHAR(15),
City VARCHAR(50),
Country VARCHAR(150)
);

CREATE TABLE Orders (
Order_ID INT AUTO_INCREMENT PRIMARY KEY,
Customer_ID INT,
Book_ID INT,
Order_Date DATE,
Quantity INT,
Total_Amount DECIMAL(10, 2),
FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID),
FOREIGN KEY (Book_ID) REFERENCES Books(Book_ID)
);

-- New Table: Reviews (each row = one customer's rating of a book)
CREATE TABLE Reviews (
Review_ID INT AUTO_INCREMENT PRIMARY KEY,
Book_ID INT,
Customer_ID INT,
Rating INT CHECK (Rating BETWEEN 1 AND 5),
Review_Date DATE,
FOREIGN KEY (Book_ID) REFERENCES Books(Book_ID),
FOREIGN KEY (Customer_ID) REFERENCES Customers(Customer_ID)
);

SELECT * FROM Books;
SELECT * FROM Customers;
SELECT * FROM Orders;
SELECT * FROM Reviews;

-- Import Data into Books Table
-- (Enable local file loading first if needed: SET GLOBAL local_infile = 1;)
-- LOAD DATA LOCAL INFILE 'Books.csv'
-- INTO TABLE Books
-- FIELDS TERMINATED BY ','
-- OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (Book_ID, Title, Author, Genre, Published_Year, Price, Stock);

-- -- Import Data into Customers Table
-- LOAD DATA LOCAL INFILE 'Customers.csv'
-- INTO TABLE Customers
-- FIELDS TERMINATED BY ','
-- OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (Customer_ID, Name, Email, Phone, City, Country);

-- -- Import Data into Orders Table
-- LOAD DATA LOCAL INFILE 'Orders.csv'
-- INTO TABLE Orders
-- FIELDS TERMINATED BY ','
-- OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (Order_ID, Customer_ID, Book_ID, Order_Date, Quantity, Total_Amount);

-- -- Import Data into Reviews Table
-- LOAD DATA LOCAL INFILE 'Reviews.csv'
-- INTO TABLE Reviews
-- FIELDS TERMINATED BY ','
-- OPTIONALLY ENCLOSED BY '"'
-- LINES TERMINATED BY '\n'
-- IGNORE 1 ROWS
-- (Review_ID, Book_ID, Customer_ID, Rating, Review_Date);

-- 1) Retrieve all books in the "Fiction" genre:
SELECT * FROM Books
WHERE Genre='Fiction';

-- 2) Find books published after the year 1950:
SELECT * FROM Books
WHERE Published_year>1950;

-- 3) List all customers from the Canada:
SELECT * FROM Customers
WHERE country='Canada';

-- 4) Show orders placed in November 2023:
SELECT * FROM Orders
WHERE order_date BETWEEN '2023-11-01' AND '2023-11-30';

-- 5) Retrieve the total stock of books available:
SELECT SUM(stock) AS Total_Stock
FROM Books;

-- 6) Find the details of the most expensive book:
SELECT * FROM Books
ORDER BY Price DESC
LIMIT 1;

-- 7) Show all customers who ordered more than 1 quantity of a book:
SELECT * FROM Orders
WHERE quantity>1;

-- 8) Retrieve all orders where the total amount exceeds $20:
SELECT * FROM Orders
WHERE total_amount>20;

-- 9) List all genres available in the Books table:
SELECT DISTINCT genre FROM Books;

-- 10) Find the book with the lowest stock:
SELECT * FROM Books
ORDER BY stock
LIMIT 1;

-- 11) Calculate the total revenue generated from all orders:
SELECT SUM(total_amount) As Revenue
FROM Orders;

-- Advance Questions :

-- 1) Retrieve the total number of books sold for each genre:
SELECT * FROM Orders;

SELECT b.Genre, SUM(o.Quantity) AS Total_Books_sold
FROM Orders o
JOIN Books b ON o.book_id = b.book_id
GROUP BY b.Genre;

-- 2) Find the average price of books in the "Fantasy" genre:
SELECT AVG(price) AS Average_Price
FROM Books
WHERE Genre = 'Fantasy';

-- 3) List customers who have placed at least 2 orders:
SELECT o.customer_id, c.name, COUNT(o.Order_id) AS ORDER_COUNT
FROM orders o
JOIN customers c ON o.customer_id=c.customer_id
GROUP BY o.customer_id, c.name
HAVING COUNT(Order_id) >=2;

-- 4) Find the most frequently ordered book:
SELECT o.Book_id, b.title, COUNT(o.order_id) AS ORDER_COUNT
FROM orders o
JOIN books b ON o.book_id=b.book_id
GROUP BY o.book_id, b.title
ORDER BY ORDER_COUNT DESC LIMIT 1;

-- 5) Show the top 3 most expensive books of 'Fantasy' Genre :
SELECT * FROM books
WHERE genre ='Fantasy'
ORDER BY price DESC LIMIT 3;

-- 6) Retrieve the total quantity of books sold by each author:
SELECT b.author, SUM(o.quantity) AS Total_Books_Sold
FROM orders o
JOIN books b ON o.book_id=b.book_id
GROUP BY b.Author;

-- 7) List the cities where customers who spent over $30 are located:
SELECT DISTINCT c.city, o.total_amount
FROM orders o
JOIN customers c ON o.customer_id=c.customer_id
WHERE o.total_amount > 30;

-- 8) Find the customer who spent the most on orders:
SELECT c.customer_id, c.name, SUM(o.total_amount) AS Total_Spent
FROM orders o
JOIN customers c ON o.customer_id=c.customer_id
GROUP BY c.customer_id, c.name
ORDER BY Total_spent DESC LIMIT 1;

-- 9) Calculate the stock remaining after fulfilling all orders:
SELECT b.book_id, b.title, b.stock, COALESCE(SUM(o.quantity),0) AS Order_quantity,
b.stock - COALESCE(SUM(o.quantity),0) AS Remaining_Quantity
FROM books b
LEFT JOIN orders o ON b.book_id=o.book_id
GROUP BY b.book_id, b.title, b.stock ORDER BY b.book_id;


-- =====================================================================
-- PART 2: EXPANDED DATA + WINDOW FUNCTION / CTE / LAG-LEAD / RANK
-- =====================================================================
-- Everything above this line is the ORIGINAL project (converted to
-- MySQL syntax only - logic/questions untouched), plus the new
-- Reviews table which now sits with the other tables at the top of
-- the script and is loaded from the accompanying Reviews.csv.
-- Below is a "Reviews Table Questions" section (plain joins/aggregates
-- using Reviews) followed by the Window Function / CTE section
-- (ROW_NUMBER, RANK, DENSE_RANK, NTILE, LAG, LEAD, running totals,
-- moving averages, and CTEs, including a recursive CTE).
-- =====================================================================

-- Reviews Table Questions :

-- 1) Retrieve all reviews for a specific book (e.g. Book_ID = 10):
SELECT r.Review_ID, b.Title, r.Rating, r.Review_Date
FROM Reviews r
JOIN Books b ON r.Book_ID = b.Book_ID
WHERE r.Book_ID = 10;

-- 2) Find the average rating for each genre:
SELECT b.Genre, ROUND(AVG(r.Rating), 2) AS Avg_Genre_Rating, COUNT(*) AS Total_Reviews
FROM Reviews r
JOIN Books b ON r.Book_ID = b.Book_ID
GROUP BY b.Genre
ORDER BY Avg_Genre_Rating DESC;

-- 3) List books that have never been reviewed:
SELECT b.Book_ID, b.Title, b.Genre
FROM Books b
LEFT JOIN Reviews r ON b.Book_ID = r.Book_ID
WHERE r.Review_ID IS NULL;

-- 4) Find customers who have written more than 3 reviews:
SELECT c.Customer_ID, c.Name, COUNT(r.Review_ID) AS Review_Count
FROM Reviews r
JOIN Customers c ON r.Customer_ID = c.Customer_ID
GROUP BY c.Customer_ID, c.Name
HAVING COUNT(r.Review_ID) > 3
ORDER BY Review_Count DESC;

-- 5) Show the 10 most recent reviews overall, with book and customer names:
SELECT r.Review_ID, b.Title, c.Name AS Reviewer, r.Rating, r.Review_Date
FROM Reviews r
JOIN Books b ON r.Book_ID = b.Book_ID
JOIN Customers c ON r.Customer_ID = c.Customer_ID
ORDER BY r.Review_Date DESC
LIMIT 10;

-- 6) Count how many low (1-2 star) reviews each genre has received:
SELECT b.Genre, COUNT(*) AS Low_Rating_Count
FROM Reviews r
JOIN Books b ON r.Book_ID = b.Book_ID
WHERE r.Rating <= 2
GROUP BY b.Genre
ORDER BY Low_Rating_Count DESC;

-- 7) Find customers who reviewed a book they never actually ordered
--    (anti-join between Reviews and Orders):
SELECT DISTINCT c.Customer_ID, c.Name, b.Title
FROM Reviews r
JOIN Customers c ON r.Customer_ID = c.Customer_ID
JOIN Books b ON r.Book_ID = b.Book_ID
WHERE NOT EXISTS (
    SELECT 1 FROM Orders o
    WHERE o.Customer_ID = r.Customer_ID AND o.Book_ID = r.Book_ID
);

-- 8) Find the book with the highest number of 5-star reviews:
SELECT b.Book_ID, b.Title, COUNT(*) AS Five_Star_Count
FROM Reviews r
JOIN Books b ON r.Book_ID = b.Book_ID
WHERE r.Rating = 5
GROUP BY b.Book_ID, b.Title
ORDER BY Five_Star_Count DESC
LIMIT 1;

-- Window Function / CTE Questions :

-- 1) Rank books by price within each genre (highest price = rank 1):
SELECT Book_ID, Title, Genre, Price,
       RANK() OVER (PARTITION BY Genre ORDER BY Price DESC) AS Price_Rank_In_Genre
FROM Books;

-- 2) Assign a sequential order number to each customer's own orders,
--    ordered by order date (ROW_NUMBER + PARTITION BY):
SELECT Order_ID, Customer_ID, Order_Date, Total_Amount,
       ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY Order_Date) AS Customer_Order_Seq
FROM Orders;

-- 3) Running total (cumulative) revenue over time, ordered by order date:
SELECT Order_ID, Order_Date, Total_Amount,
       SUM(Total_Amount) OVER (ORDER BY Order_Date, Order_ID
                                ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Running_Revenue
FROM Orders;

-- 4) For each customer, compare each order's amount to their PREVIOUS
--    order's amount using LAG():
SELECT Order_ID, Customer_ID, Order_Date, Total_Amount,
       LAG(Total_Amount) OVER (PARTITION BY Customer_ID ORDER BY Order_Date) AS Prev_Order_Amount,
       Total_Amount - LAG(Total_Amount) OVER (PARTITION BY Customer_ID ORDER BY Order_Date) AS Change_From_Prev
FROM Orders;

-- 5) For each customer, find the date of their NEXT order using LEAD(),
--    and how many days until that next order:
SELECT Order_ID, Customer_ID, Order_Date,
       LEAD(Order_Date) OVER (PARTITION BY Customer_ID ORDER BY Order_Date) AS Next_Order_Date,
       DATEDIFF(LEAD(Order_Date) OVER (PARTITION BY Customer_ID ORDER BY Order_Date), Order_Date) AS Days_Until_Next_Order
FROM Orders;

-- 6) Using a CTE, find total spend per customer, then list only
--    customers spending above the overall average (CTE + aggregate):
WITH Customer_Spend AS (
    SELECT c.Customer_ID, c.Name, SUM(o.Total_Amount) AS Total_Spent
    FROM Orders o
    JOIN Customers c ON o.Customer_ID = c.Customer_ID
    GROUP BY c.Customer_ID, c.Name
)
SELECT *
FROM Customer_Spend
WHERE Total_Spent > (SELECT AVG(Total_Spent) FROM Customer_Spend)
ORDER BY Total_Spent DESC;

-- 7) Find each customer's first and last order date side by side
--    using FIRST_VALUE / LAST_VALUE window functions:
SELECT DISTINCT Customer_ID,
       FIRST_VALUE(Order_Date) OVER (PARTITION BY Customer_ID ORDER BY Order_Date
                                      ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS First_Order_Date,
       LAST_VALUE(Order_Date) OVER (PARTITION BY Customer_ID ORDER BY Order_Date
                                     ROWS BETWEEN UNBOUNDED PRECEDING AND UNBOUNDED FOLLOWING) AS Last_Order_Date
FROM Orders
ORDER BY Customer_ID;

-- 8) Split customers into 4 spending quartiles using NTILE(4), based
--    on total amount spent (CTE + NTILE):
WITH Customer_Spend AS (
    SELECT c.Customer_ID, c.Name, SUM(o.Total_Amount) AS Total_Spent
    FROM Orders o
    JOIN Customers c ON o.Customer_ID = c.Customer_ID
    GROUP BY c.Customer_ID, c.Name
)
SELECT Customer_ID, Name, Total_Spent,
       NTILE(4) OVER (ORDER BY Total_Spent DESC) AS Spending_Quartile
FROM Customer_Spend;

-- 9) 3-order moving average of Total_Amount per customer, ordered by
--    order date (window frame: current row + 2 preceding):
SELECT Order_ID, Customer_ID, Order_Date, Total_Amount,
       AVG(Total_Amount) OVER (PARTITION BY Customer_ID ORDER BY Order_Date
                                ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS Moving_Avg_3_Orders
FROM Orders;

-- 10) Rank customers by total spend, and within each country show only
--     the top 3 spenders using DENSE_RANK + PARTITION BY + CTE:
WITH Customer_Spend AS (
    SELECT c.Customer_ID, c.Name, c.Country, SUM(o.Total_Amount) AS Total_Spent
    FROM Orders o
    JOIN Customers c ON o.Customer_ID = c.Customer_ID
    GROUP BY c.Customer_ID, c.Name, c.Country
),
Ranked_Spend AS (
    SELECT *, DENSE_RANK() OVER (PARTITION BY Country ORDER BY Total_Spent DESC) AS Rank_In_Country
    FROM Customer_Spend
)
SELECT *
FROM Ranked_Spend
WHERE Rank_In_Country <= 3
ORDER BY Country, Rank_In_Country;

-- 11) Month-over-month revenue and its growth vs the previous month,
--     using a CTE to aggregate by month plus LAG() to compare:
WITH Monthly_Revenue AS (
    SELECT DATE_FORMAT(Order_Date, '%Y-%m-01') AS Order_Month,
           SUM(Total_Amount) AS Revenue
    FROM Orders
    GROUP BY DATE_FORMAT(Order_Date, '%Y-%m-01')
)
SELECT Order_Month, Revenue,
       LAG(Revenue) OVER (ORDER BY Order_Month) AS Prev_Month_Revenue,
       Revenue - LAG(Revenue) OVER (ORDER BY Order_Month) AS Revenue_Change,
       ROUND(
         (Revenue - LAG(Revenue) OVER (ORDER BY Order_Month))
         / NULLIF(LAG(Revenue) OVER (ORDER BY Order_Month), 0) * 100, 2
       ) AS Pct_Growth
FROM Monthly_Revenue
ORDER BY Order_Month;

-- 12) Each genre's share of total revenue, using a window function
--     with no PARTITION BY (grand total) inside a CTE:
WITH Genre_Revenue AS (
    SELECT b.Genre, SUM(o.Total_Amount) AS Genre_Revenue
    FROM Orders o
    JOIN Books b ON o.Book_ID = b.Book_ID
    GROUP BY b.Genre
)
SELECT Genre, Genre_Revenue,
       ROUND(Genre_Revenue / SUM(Genre_Revenue) OVER () * 100, 2) AS Pct_Of_Total_Revenue
FROM Genre_Revenue
ORDER BY Pct_Of_Total_Revenue DESC;

-- 13) Average rating per book from the new Reviews table, then rank
--     the top 5 highest rated books (min 2 reviews) using RANK():
WITH Book_Ratings AS (
    SELECT r.Book_ID, b.Title, b.Genre,
           ROUND(AVG(r.Rating), 2) AS Avg_Rating,
           COUNT(*) AS Review_Count
    FROM Reviews r
    JOIN Books b ON r.Book_ID = b.Book_ID
    GROUP BY r.Book_ID, b.Title, b.Genre
    HAVING COUNT(*) >= 2
)
SELECT *, RANK() OVER (ORDER BY Avg_Rating DESC) AS Rating_Rank
FROM Book_Ratings
ORDER BY Rating_Rank
LIMIT 5;

-- 14) For each book, compare each review's rating to that same book's
--     PREVIOUS review rating over time (LAG partitioned by book):
SELECT Review_ID, Book_ID, Review_Date, Rating,
       LAG(Rating) OVER (PARTITION BY Book_ID ORDER BY Review_Date) AS Prev_Rating_For_Book,
       Rating - LAG(Rating) OVER (PARTITION BY Book_ID ORDER BY Review_Date) AS Rating_Change
FROM Reviews
ORDER BY Book_ID, Review_Date;

-- 15) Recursive CTE: generate a full calendar of months between the
--     earliest and latest order date, then LEFT JOIN monthly revenue
--     onto it so months with zero orders still show up as 0:
WITH RECURSIVE Month_Series AS (
    SELECT DATE_FORMAT(MIN(Order_Date), '%Y-%m-01') AS Month_Start
    FROM Orders
    UNION ALL
    SELECT DATE_ADD(Month_Start, INTERVAL 1 MONTH)
    FROM Month_Series
    WHERE DATE_ADD(Month_Start, INTERVAL 1 MONTH) <= (SELECT DATE_FORMAT(MAX(Order_Date), '%Y-%m-01') FROM Orders)
),
Monthly_Revenue AS (
    SELECT DATE_FORMAT(Order_Date, '%Y-%m-01') AS Order_Month, SUM(Total_Amount) AS Revenue
    FROM Orders
    GROUP BY DATE_FORMAT(Order_Date, '%Y-%m-01')
)
SELECT ms.Month_Start AS Order_Month,
       COALESCE(mr.Revenue, 0) AS Revenue
FROM Month_Series ms
LEFT JOIN Monthly_Revenue mr ON ms.Month_Start = mr.Order_Month
ORDER BY ms.Month_Start;

-- 16) For each customer, number their reviews in the order they wrote
--     them (ROW_NUMBER partitioned by customer, ordered by review date):
SELECT Review_ID, Customer_ID, Book_ID, Review_Date, Rating,
       ROW_NUMBER() OVER (PARTITION BY Customer_ID ORDER BY Review_Date) AS Customer_Review_Seq
FROM Reviews;

-- 17) Running (cumulative) count of reviews received by each book over
--     time, so you can see how a book's review count builds up:
SELECT Review_ID, Book_ID, Review_Date, Rating,
       COUNT(*) OVER (PARTITION BY Book_ID ORDER BY Review_Date
                       ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS Running_Review_Count_For_Book
FROM Reviews
ORDER BY Book_ID, Review_Date;

-- 18) Bucket books into 4 quality tiers using NTILE(4) based on their
--     average rating (CTE to get avg rating, then NTILE over it):
WITH Book_Avg_Rating AS (
    SELECT r.Book_ID, b.Title, b.Genre, ROUND(AVG(r.Rating), 2) AS Avg_Rating
    FROM Reviews r
    JOIN Books b ON r.Book_ID = b.Book_ID
    GROUP BY r.Book_ID, b.Title, b.Genre
)
SELECT Book_ID, Title, Genre, Avg_Rating,
       NTILE(4) OVER (ORDER BY Avg_Rating DESC) AS Rating_Tier
FROM Book_Avg_Rating;
