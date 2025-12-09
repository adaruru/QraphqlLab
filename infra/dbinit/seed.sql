-- GraphQL Lab Test Data
-- Seed data for users, employment_status, and salaries tables

-- Insert test users
INSERT INTO users (username, email, full_name, department, position, hire_date) VALUES
('jsmith', 'john.smith@example.com', 'John Smith', 'Engineering', 'Senior Software Engineer', '2020-03-15'),
('mjohnson', 'mary.johnson@example.com', 'Mary Johnson', 'Engineering', 'Tech Lead', '2019-06-01'),
('rchen', 'robert.chen@example.com', 'Robert Chen', 'Engineering', 'Software Engineer', '2021-09-10'),
('swang', 'sarah.wang@example.com', 'Sarah Wang', 'Product', 'Product Manager', '2020-11-20'),
('dlee', 'david.lee@example.com', 'David Lee', 'Sales', 'Sales Manager', '2018-04-12'),
('akim', 'alice.kim@example.com', 'Alice Kim', 'Marketing', 'Marketing Specialist', '2022-01-15'),
('tgarcia', 'tom.garcia@example.com', 'Tom Garcia', 'Engineering', 'Junior Developer', '2023-03-01'),
('lbrown', 'lisa.brown@example.com', 'Lisa Brown', 'HR', 'HR Manager', '2019-08-05'),
('mwilson', 'mike.wilson@example.com', 'Mike Wilson', 'Finance', 'Financial Analyst', '2021-02-18'),
('ewu', 'emma.wu@example.com', 'Emma Wu', 'Product', 'Product Designer', '2022-07-10');

-- Insert employment status records
-- Active employees
INSERT INTO employment_status (user_id, status, start_date, end_date, notes) VALUES
(1, 'active', '2020-03-15', NULL, 'Current active employee'),
(2, 'active', '2019-06-01', NULL, 'Current active employee'),
(3, 'active', '2021-09-10', NULL, 'Current active employee'),
(4, 'active', '2020-11-20', NULL, 'Current active employee'),
(5, 'active', '2018-04-12', NULL, 'Current active employee'),
(6, 'on_leave', '2022-01-15', NULL, 'On parental leave'),
(8, 'active', '2019-08-05', NULL, 'Current active employee'),
(9, 'active', '2021-02-18', NULL, 'Current active employee'),
(10, 'active', '2022-07-10', NULL, 'Current active employee');

-- Employee on probation
INSERT INTO employment_status (user_id, status, start_date, end_date, notes) VALUES
(7, 'probation', '2023-03-01', '2023-06-01', 'Probation period - 3 months'),
(7, 'active', '2023-06-01', NULL, 'Probation completed successfully');

-- Insert salary records
-- Current salaries
INSERT INTO salaries (user_id, base_salary, bonus, currency, effective_date, end_date, payment_frequency) VALUES
-- John Smith - Senior Software Engineer
(1, 1800000.00, 200000.00, 'TWD', '2023-01-01', NULL, 'monthly'),
-- Mary Johnson - Tech Lead
(2, 2200000.00, 300000.00, 'TWD', '2023-01-01', NULL, 'monthly'),
-- Robert Chen - Software Engineer
(3, 1500000.00, 150000.00, 'TWD', '2023-01-01', NULL, 'monthly'),
-- Sarah Wang - Product Manager
(4, 1900000.00, 250000.00, 'TWD', '2023-01-01', NULL, 'monthly'),
-- David Lee - Sales Manager
(5, 2000000.00, 400000.00, 'TWD', '2023-01-01', NULL, 'monthly'),
-- Alice Kim - Marketing Specialist
(6, 1300000.00, 100000.00, 'TWD', '2023-01-01', NULL, 'monthly'),
-- Tom Garcia - Junior Developer
(7, 1000000.00, 50000.00, 'TWD', '2023-03-01', NULL, 'monthly'),
-- Lisa Brown - HR Manager
(8, 1700000.00, 200000.00, 'TWD', '2023-01-01', NULL, 'monthly'),
-- Mike Wilson - Financial Analyst
(9, 1600000.00, 180000.00, 'TWD', '2023-01-01', NULL, 'monthly'),
-- Emma Wu - Product Designer
(10, 1400000.00, 120000.00, 'TWD', '2023-01-01', NULL, 'monthly');

-- Historical salary records (for demonstration of salary changes)
INSERT INTO salaries (user_id, base_salary, bonus, currency, effective_date, end_date, payment_frequency) VALUES
-- John Smith - previous salary
(1, 1600000.00, 150000.00, 'TWD', '2020-03-15', '2022-12-31', 'monthly'),
(1, 1700000.00, 180000.00, 'TWD', '2022-01-01', '2022-12-31', 'monthly'),
-- Mary Johnson - previous salary
(2, 1800000.00, 200000.00, 'TWD', '2019-06-01', '2021-12-31', 'monthly'),
(2, 2000000.00, 250000.00, 'TWD', '2022-01-01', '2022-12-31', 'monthly'),
-- Robert Chen - previous salary
(3, 1200000.00, 100000.00, 'TWD', '2021-09-10', '2022-12-31', 'monthly');

-- Add some comments to demonstrate data relationships
-- These tables are designed to support GraphQL join operations:
-- 1. Query user and their current employment status
-- 2. Query user and their salary history
-- 3. Query employment status with associated user and salary information
-- 4. Complex queries joining all three tables
