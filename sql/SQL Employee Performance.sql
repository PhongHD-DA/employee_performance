create database Employee_Performance;

select * from clean_business_outcomes;
select * from clean_employees;
select * from clean_monthly_performance;
select * from clean_role_kpis;
select * from clean_stores;

select
    Employee_id,
    Full_Name,
    Age,
    Age_Group,
    Education_Level,
    Department,
    Job_Role,
    Job_Level,
    Employment_Type,
    Base_Salary_Annual,
    Manager_Id,
    Store_Id,
    Hire_Date,
    Exit_Date,
    Is_Active,
    Tenure_Days
INTO dim_employees
from clean_employees;

select
    Store_Id,
    Store_Name,
    City,
    Store_Type,
    Opening_Date
INTO dim_stores
from clean_stores;

SELECT DISTINCT 
    Manager_Id,
    Manager_Name,
    Manager_Status
INTO dim_managers
FROM clean_employees;

SELECT 
    p.Employee_Id,
    p.Year_Month,
    p.Performance_Rating,
    p.Manager_Evaluation,
    p.Training_Hours,
    p.Training_Group,
    p.Overtime_Hours,
    p.Employee_Satisfaction,
    p.Engagement_Index,
    p.Monthly_Bonus,
    p.Benefits_Cost,
    p.Promotion_Flag,
    p.Salary_Increase_Flag,
    p.Absenteeism_Days,
    k.Productivity_Index,
    k.Kpi_1_Name,
    k.Kpi_1_Value,
    k.Kpi_2_Name,
    k.Kpi_2_Value,
    k.Kpi_3_Name,
    k.Kpi_3_Value
INTO fact_employee_monthly
FROM clean_monthly_performance p
LEFT JOIN clean_role_kpis k 
    ON p.Employee_Id = k.Employee_Id 
    AND p.Year_Month = k.Year_Month;

SELECT 
    Store_Id,
    Department,
    Year_Month,
    Sales_Target,
    Sales_Actual,
    -- Tính toán độ lệch Sales để biết hụt/vượt bao nhiêu tiền
    (Sales_Actual - Sales_Target) AS Sales_Variance, 
    Sales_Target_Achievement_Pct, 
    Customer_Satisfaction,
    Nps_Score,
    Waste_Percentage,
    On_Time_Delivery,
    -- Trạng thái dễ hiểu: % Đạt mục tiêu và % lãng phí
    CASE 
        WHEN Sales_Target_Achievement_Pct >= 100 AND Waste_Percentage < 5 THEN 'High Efficiency'
        WHEN Sales_Target_Achievement_Pct < 90 OR Waste_Percentage > 10 THEN 'Low Efficiency'
        ELSE 'Standard'
    END AS Operational_Efficiency_Status
INTO fact_business_outcomes
FROM clean_business_outcomes;

-- Kiểm tra xem tổng doanh thu ở bảng Fact có khớp với bảng thô không
SELECT SUM(Sales_Actual) FROM fact_business_outcomes;
SELECT SUM(Sales_Actual) FROM clean_business_outcomes;

-- Kiểm tra xem có nhân viên nào ở bảng Fact mà không có trong bảng Dim không
SELECT COUNT(*) 
FROM fact_employee_monthly 
WHERE Employee_Id NOT IN (SELECT Employee_Id FROM dim_employees);

SELECT 
    Department,
    COUNT(Employee_Id) AS Total_Staff,
    SUM(CASE WHEN Is_Active = 'False' THEN 1 ELSE 0 END) AS Resigned_Staff,
    ROUND(SUM(CASE WHEN Is_Active = 'False' THEN 1 ELSE 0 END) * 100.0 / COUNT(Employee_Id), 2) AS Turnover_Rate_Pct
FROM dim_employees
GROUP BY Department
ORDER BY Turnover_Rate_Pct DESC;

select
    e.Department,
    e.Job_Level,
    round(avg(e.Base_Salary_Annual/12 + em.Benefits_Cost + em.Monthly_Bonus),2) as Avg_Salary
from dim_employees e
join fact_employee_monthly em ON e.Employee_id = em.Employee_Id
group BY e.Department, e.Job_Level
order BY e.Department, Avg_Salary DESC

SELECT 
    Year_Month,
    ROUND(AVG(Performance_Rating), 2) AS Avg_Performance
FROM fact_employee_monthly
GROUP BY Year_Month
ORDER BY Year_Month;

select Top 10
    m.Manager_Name,
    round(avg(em.Performance_Rating),2) as Performance,
    count(distinct e.Employee_id) as Team_Size
from fact_employee_monthly em
join dim_employees e on e.Employee_id = em.Employee_Id
join dim_managers m on m.Manager_Id = e.Manager_Id
where m.Manager_Name != 'BOD'
group by m.Manager_Name
order by Performance desc, Team_Size desc

select
    Training_Group,
    round(avg(Performance_Rating), 2) as Performance,
    ROUND(AVG(Productivity_Index), 2) AS Productivity
from fact_employee_monthly
Group by Training_Group
order by Performance desc

select
    s.Store_Name,
    bo.Operational_Efficiency_Status,
    bo.Nps_score,
    round(avg(bo.Customer_Satisfaction),2) as Avg_Cus_Satisfaction ,
    round(sum(bo.Sales_Actual),2) as Total_Sales,
    round(avg(bo.Sales_Variance),2) as Sales_Variance,
    round(avg(bo.Sales_Target_Achievement_Pct),2) as Avg_Pct_Achieve_Target
from dim_stores s
join fact_business_outcomes bo on s.Store_Id = bo.Store_Id
group by s.Store_Name,bo.Operational_Efficiency_Status, bo.Nps_Score
order by Total_Sales desc, Sales_Variance desc, Avg_Pct_Achieve_Target desc

select
    e.Department,
    round(avg(em.Employee_Satisfaction),2) as Avg_Employee_Satisfaction
from fact_employee_monthly em
join dim_employees e on e.Employee_id = em.Employee_Id
group by e.Department
order by Avg_Employee_Satisfaction desc

select
    e.Job_Role,
    round(avg(Productivity_Index),2) as Productivity
from fact_employee_monthly em
join dim_employees e on e.Employee_id = em.Employee_Id
group by e.Job_Role
order by Productivity desc

select
    e.Full_Name,
    e.Job_Level,
    round(em.Productivity_Index,2),
    round(em.Performance_Rating,2),
    round(em.Employee_Satisfaction,2),
    round((em.Productivity_Index * 0.5 + em.Performance_Rating * 0.3 + em.Employee_Satisfaction * 0.2),5) as Talent_Score
from dim_employees e
join fact_employee_monthly em on em.Employee_Id = e.Employee_id
where e.Is_Active = 1 and em.Year_Month = (select Max(Year_Month) from fact_employee_monthly)
order by Talent_Score desc

SELECT
    e.Age_Group,
    round(avg(em.Productivity_Index),5) as Productivity,
    round(avg(em.Performance_Rating),5) as Performance
from dim_employees e
join fact_employee_monthly em on em.Employee_Id = e.Employee_id
group by e.Age_Group
order by Productivity desc

SELECT * FROM dim_employees
SELECT * FROM dim_managers
SELECT * FROM dim_stores
SELECT * FROM fact_business_outcomes
SELECT * FROM fact_employee_monthly