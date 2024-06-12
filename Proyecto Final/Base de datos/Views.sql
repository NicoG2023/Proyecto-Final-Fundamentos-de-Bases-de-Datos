--Consolidated view that shows the payroll summary for each employee, including base salary, total allowances, total deductions, and net salary

drop view if exists employee_payroll_summary;
create view employee_payroll_summary as
select e."UUID" as employee_id, e.name as employee_name, e.salary as base_salary, coalesce(sum(ea.amount),0) as total_allowances, coalesce(sum(ed.amount),0) as total_deductions,
(e.salary + coalesce(sum(ea.amount),0) - coalesce(sum(ed.amount),0)) as net_salary
from public.employee e 
left join public.employee_allowances ea on e."UUID" = ea.employee_fk
left join public.employee_deductions ed on e."UUID" = ed.employee_fk
group by e."UUID", e.name, e.salary;

select * from employee e ;
select * from employee_allowances ea ;
SELECT * FROM employee_payroll_summary;

--Number of employees and the average salary for each department
drop view if exists department_employee_summary;
create view department_employee_summary as
select d.id as department_id, d.name as department_name, count(e."UUID") as employee_count, avg(e.salary) as average_salary
from public.department d 
join public."Position" p on d.id = p.department_fk
join public.employee e on p.id = e.position_fk
group by d.id, d.name;

select * from department_employee_summary order by employee_count desc;

--view that logs user activities, including login times, actions performed, and the roles of users
drop view if exists user_activity_summary;
create view user_activity_summary as
select e."UUID" as user_id, e.name as user_name, r.name as role_name, a.action, a.action_timestamp
from public.employee e 
join public."Role" r on e.role_fk = r.id
join public.user_activity_log a on e."UUID" = a.employee_fk;

select * from user_activity_summary;

--view that shows the total salary budget for each department, including base salaries and allowances
drop view if exists department_salary_budget;
create or replace view department_salary_budget as
select d.id as department_id, d.name as department_name, sum(e.salary) as total_base_salaries, coalesce(sum(ea.amount),0) as total_budget
from public.department d 
join public."Position" p on d.id = p.department_fk
join public.employee e on p.id = e.position_fk
left join public.employee_allowances ea on e."UUID" = ea.employee_fk
group by d.id, d.name;

select * from department_salary_budget order by total_budget desc;

--View that shows the attendance summary for each employee
drop view if exists employee_attendance_summary;
create or replace view employee_attendance_summary as
select e.name as employee_name, sum(ps.present) as total_days_present, sum(ps.absent) as total_days_absent
from public.employee e 
join public.payslip ps on e."UUID" = ps.employee_fk
group by e."UUID", e.name;

select * from employee_attendance_summary order by total_days_present desc;