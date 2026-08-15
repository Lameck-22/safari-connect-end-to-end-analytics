# safari-connect-end-to-end-analytics
## Project Overview
I was hypothetically hired as a Junior Data Analyst at Safari Connect - a fast-growing Nairobi-based bus and matatu booking platform. Think of it as the Bolt of long-distance travel - passengers book seats online, choose their route, and pay via M-Pesa or card.

The company has been running since 2024 and storing all booking records in a shared Excel file. It is a complete mess. The Operations Director has handed you a CSV export and sent you this message:

_"We are growing fast - hundreds of bookings a month and counting. But I have no idea which routes
are making money, which drivers are performing well, or why our cancellation rate feels high.
I need you to clean this data, load it into our database, analyse it, and present your findings to the board.
I want to know: which routes are most profitable, which drivers I should promote, how revenue is
trending month by month, where our passengers come from, how much revenue cancellations are costing us,
and what our busiest travel times are.
Make it look professional. Present on Friday. The CEO will be in the room."_

### Key Tech stack used
1. PostgreSQL
2. PowerBi

### Step 1 : Loading and Cleaning the data
- I loaded bookings table loaded in PostgreSQL. All 23 problems that were identified fixed in the staging table.
- After cleaning the data, I created views that could answer businees problems raised by the CEO to help in making informed decisions for the company.
- Core analytical questions answered using SQL were as below and the views created there after:
    1.	Route Analysis - Which routes earn the most? Which are most popular?	GROUP BY, SUM, COUNT, ORDER BY
    2.	Driver Performance - Who are the best drivers? Who should be promoted?	GROUP BY, AVG, RANK window function
    3.	Revenue Trends - How is revenue changing month by month?	CTE + LAG, DATE_TRUNC, running total
    4. Passenger Insights - Who travels with us? Which cities, genders, seat classes?	GROUP BY, COUNT, CASE WHEN
    5.	Cancellations - What is our cancellation rate and how much revenue did we lose?	bookings table, CASE WHEN, SUM
    6.	Operational Patterns - What are our busiest days and times?	EXTRACT, TO_CHAR, GROUP BY, NTILE


### Step 2 : Loadind views in PowerBi and creating visualizations
__How to Connect Power BI to PostgreSQL__
1.	Open Power BI Desktop → click Get Data
2.	Search for PostgreSQL → select it → Connect
3.	Server: localhost   |   Database: postgres   |   Schema: safari_connect
4.	Enter your PostgreSQL username and password
5.	Select your views from the table list - use your v_ views, not raw tables
6.	Click Load → your data is ready to visualise

- After connecting the views, I created visualizations together with interractive dashboards to help answer the key questions asked by the CEO.

## Business insights and recommendations
