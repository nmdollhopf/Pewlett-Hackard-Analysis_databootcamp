-- Retrieve the emp_no, first_name, and last_name columns from the Employees table.
-- Retrieve the title, from_date, and to_date columns from the Titles table.
-- Create a new table using the INTO clause.
-- Join both tables on the primary key.
-- Filter the data on the birth_date column to retrieve the employees who were born between 1952 and 1955.
-- Then, order by the employee number.
-- Export the Retirement Titles table from the previous step as retirement_titles.csv 
-- and save it to your Data folder in the Pewlett-Hackard-Analysis folder.
SELECT emps.emp_no,
    emps.first_name,
    emps.last_name,
    titles.title,
    titles.from_date,
    titles.to_date
-- INTO retirement_titles
FROM employees as emps
LEFT JOIN titles
    ON (emps.emp_no = titles.emp_no)
WHERE (birth_date BETWEEN '1952-01-01' AND '1955-12-31')
ORDER BY emps.emp_no ASC;
-- created 133776 rows in retirement_titles


-- Copy the query from the Employee_Challenge_starter_code.sql and add it to your Employee_Database_challenge.sql file.
-- Retrieve the employee number, first and last name, and title columns from the Retirement Titles table.
-- These columns will be in the new table that will hold the most recent title of each employee.
-- Use the DISTINCT ON statement to retrieve the first occurrence of the employee number for each
--    set of rows defined by the ON () clause
-- Use Dictinct with Orderby to remove duplicate rows
-- Exclude those employees that have already left the company by 
--     filtering on to_date to keep only those dates that are equal to '9999-01-01'.
-- Create a Unique Titles table using the INTO clause.
-- Sort the Unique Titles table in ascending order by the 
--      employee number and descending order by the last date (i.e., to_date) of the most recent title
SELECT DISTINCT ON (rt.emp_no) rt.emp_no,
    rt.first_name,
    rt.last_name,
    rt.title
INTO unique_titles
FROM retirement_titles as rt
WHERE (rt.to_date='9999-01-01')
ORDER BY rt.emp_no ASC, rt.to_date DESC;
--created 72458 rows in unique_titles


--Write another query in the Employee_Database_challenge.sql file to
--    retrieve the number of employees by their most recent job title who are about to retire.
-- First, retrieve the number of titles from the Unique Titles table.
-- Then, create a Retiring Titles table to hold the required information.
-- Group the table by title, then sort the count column in descending order
SELECT COUNT(title) AS "Count of [title]",
    title
INTO retiring_titles
FROM unique_titles
GROUP BY title
ORDER BY "Count of [title]" DESC;
-- created 7 rows in retiring_titles


-- deliverable 2:

-- Retrieve the emp_no, first_name, last_name, and birth_date columns from the Employees table.
-- Retrieve the from_date and to_date columns from the Department Employee table.
-- Retrieve the title column from the Titles table.
-- Use a DISTINCT ON statement to retrieve the first occurrence of the
--    employee number for each set of rows defined by the ON () clause.
-- Create a new table using the INTO clause.
-- Join the Employees and the Department Employee tables on the primary key.
-- Join the Employees and the Titles tables on the primary key.
-- Filter the data on the to_date column to all the current employees,
-- then filter the data on the birth_date columns to get all the employees whose birth dates
--     are between January 1, 1965 and December 31, 1965.
-- Order the table by the employee number.
--SELECT DISTINCT ON (emps.emp_no) emps.emp_no, emps.first_name,
--    emps.last_name, emps.birth_date, de.from_date,
--    de.to_date, titles.title
---- INTO 
--FROM employees as emps
--LEFT JOIN dept_emp AS de  ON (emps.emp_no = de.emp_no)
--INNER JOIN titles ON (emps.emp_no = titles.emp_no)
--WHERE (de.to_date='9999-01-01')
--    AND (birth_date BETWEEN '1965-01-01' AND '1965-12-31')
--ORDER BY emps.emp_no ASC;

-- depending on how quickly it runs, some information is *wrong*
-- challenge instructions have emp_no=10291 with the title "staff"
-- but (running the codes below), they were promoted in 1994 to "senior staff"
-- to fix:
--   idea 1: try doing `WHERE (titles.to_date='9999-01-01')` because dept_emp.to_date is 9999-01-01 for both titles
--      but only the right title has title.to_date=9999-01-01
--   idea 2: add a where condition of `AND (titles.to_date = de.to_date)` to, again, filter the correct titles.
-- initially, had thought it was maybe a difference on LEFT JOIN vs INNER JOIN, but doesn't seem to be the case

-- for troubleshooting:
SELECT * FROM titles
JOIN employees ON (employees.emp_no = titles.emp_no)
WHERE (employees.birth_date BETWEEN '1965-01-01' AND '1965-12-31')
AND (titles.emp_no=10291);

SELECT * FROM titles
JOIN dept_emp ON dept_emp.emp_no = titles.emp_no
WHERE (dept_emp.to_date=titles.to_date);


-- proper code for deliverable 2
-- using idea 1 from above
SELECT DISTINCT ON (emps.emp_no) emps.emp_no,
    emps.first_name,
    emps.last_name,
    emps.birth_date,
    de.from_date,
    de.to_date,
    titles.title
INTO mentorship_eligibility
FROM employees as emps
INNER JOIN dept_emp AS de
    ON (emps.emp_no = de.emp_no)
INNER JOIN titles
    ON (emps.emp_no = titles.emp_no)
WHERE (titles.to_date='9999-01-01')
    AND (birth_date BETWEEN '1965-01-01' AND '1965-12-31')
ORDER BY emps.emp_no ASC;
-- created 1549 rows in mentorship_eligibility

-- mentors by title
SELECT COUNT(title) AS "Count of mentors",
    title as "mentor title"
FROM mentorship_eligibility
GROUP BY title
ORDER BY "Count of mentors" DESC;

-- mentors by department
SELECT COUNT(dept.dept_name) AS "Count of mentors",
    dept.dept_name AS "Department name"
FROM mentorship_eligibility as ments
JOIN dept_emp as de
    ON de.emp_no = ments.emp_no
JOIN departments as dept
    ON dept.dept_no = de.dept_no
GROUP BY "Department name"
ORDER BY "Count of mentors" DESC;



-- one of the questions is if there are enough mentors to train the new hires
-- define "new hire" as hired <1 year ago or <6mo
-- to get most recent hire (and treat it as "now"):
SELECT MAX(from_date)
from dept_emp;
-- most recent hire is 2002-08-01

-- compare mentor count to new hire count
-- nest 2 diff aggregate count queries into 1 join query
SELECT "Title", "Count of mentors", "Count of new hires"  
FROM
    (SELECT COUNT(me.title) AS "Count of mentors",
        me.title as "Title" --"mentor title"
    FROM mentorship_eligibility as me
    GROUP BY me.title) AS mentors
LEFT JOIN
    (SELECT COUNT(title) as "Count of new hires", title as "New hire title" 
    FROM titles
    WHERE (from_date BETWEEN '2002-02-01' AND '2002-08-01')
        AND (to_date='9999-01-01')
    GROUP BY title) as new_hires
ON "Title" = "New hire title"
ORDER BY "Count of mentors" DESC;

--created two new tables to hold the above so they can
--    be retrieved into the same table
--6month new hires put into table 'newhires_sixmonths'
--1year new hires put into table 'newhires_oneyear'

--then, display them into one table for display
SELECT sm."Title" as "Title",
	sm."Count_of_mentors" as "Count of Mentors",
	sm."Count_of_new_hires" as "Count of New Hires (<6mo)",
	oy."Count_of_new_hires" as "Count of New Hires (<1yr)"
FROM newhires_sixmonths as sm
JOIN newhires_oneyear as oy
	ON sm."Title" = oy."Title"
ORDER BY "Count of Mentors" DESC;



-- what percentages of the departments are retiring?
-- we discovered during the module that some employees are counted twice in
--    the dept_info table. this is mitigated now by where titles.to_date = 9999-01-01
SELECT "Department", "Total Count", "Retiring Count",
	CAST((CAST("Retiring Count" AS DECIMAL)/"Total Count"*100) AS DECIMAL(4,2)) AS "Percent"
FROM
	(SELECT COUNT(departments.dept_name) as "Retiring Count", departments.dept_name
	FROM retirement_info AS ri
	LEFT JOIN titles ON ri.emp_no = titles.emp_no
	LEFT JOIN dept_emp AS de ON ri.emp_no = de.emp_no
	LEFT JOIN departments ON de.dept_no = departments.dept_no
	WHERE titles.to_date = ('9999-01-01')
	GROUP BY departments.dept_name) as retires
JOIN
	(SELECT COUNT(departments.dept_name) as "Total Count", departments.dept_name as "Department"
	FROM employees AS emps
	LEFT JOIN titles ON emps.emp_no = titles.emp_no
	LEFT JOIN dept_emp AS de ON emps.emp_no = de.emp_no
	LEFT JOIN departments ON de.dept_no = departments.dept_no
	WHERE titles.to_date = ('9999-01-01')
	GROUP BY departments.dept_name) AS totals
ON retires.dept_name = "Department"
ORDER BY "Percent" DESC;


-- what percentages of titles are retiring?
SELECT "Retiring title", "Total Count", "Retiring Count",
	CAST((CAST("Retiring Count" AS DECIMAL)/"Total Count"*100) AS DECIMAL(4,2)) AS "Percent"
FROM
    (SELECT COUNT(title) as "Total Count", title FROM titles
    WHERE (to_date='9999-01-01')
    GROUP BY title
    ORDER BY COUNT(title) DESC) as totals
LEFT JOIN
    (SELECT count as "Retiring Count", title as "Retiring title" FROM retiring_titles) AS retires
ON totals.title = "Retiring title";


-- average and total retiring salary sums by title
SELECT ut.emp_no, ut.title, sal.salary
FROM unique_titles as ut
LEFT JOIN salaries as sal
	ON sal.emp_no = ut.emp_no;

SELECT ut.title, AVG(sal.salary) as "Average Salary", sum(sal.salary) as "Total Salary"
FROM unique_titles as ut
LEFT JOIN salaries as sal
	ON sal.emp_no = ut.emp_no
GROUP BY ut.title
ORDER BY "Total Salary" DESC;


-- average and total retiring salary sums by department
SELECT depts.dept_name, AVG(sal.salary) AS "Average Salary", SUM(sal.salary) as "Total Salary"
FROM unique_titles as ut
LEFT JOIN dept_emp as de
    ON de.emp_no = ut.emp_no
LEFT JOIN departments as depts
	ON depts.dept_no = de.dept_no
LEFT JOIN salaries as sal
	ON sal.emp_no = ut.emp_no
WHERE de.to_date='9999-01-01'
GROUP BY depts.dept_name
ORDER BY "Total Salary" DESC;

-- total (total) salary sums by dept
SELECT depts.dept_name, sum(sal.salary) as "Total Salary"
FROM dept_emp as de
LEFT JOIN departments as depts
	ON depts.dept_no = de.dept_no
LEFT JOIN salaries as sal
	ON sal.emp_no = de.emp_no
WHERE de.to_date='9999-01-01'
GROUP BY depts.dept_name
ORDER BY "Total Salary" DESC;