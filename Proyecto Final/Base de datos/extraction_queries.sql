--Nicolas Guevara Herran
--All the employees with their respective position and department
select e."name" as employee_name, e.lastname, e.email, e.phone, p.name as position_name, d.name as department_name
from public.employee e 
join public."Position" p on e.position_fk = p.id 
join public.department d on p.department_fk = d.id;

--Allowances of an specific employee
select e.name as employee_name, a.name as allowance_name, ea.amount, ea.effective_date 
from public.employee_allowances ea 
join public.employee e on ea.employee_fk = e."UUID" 
join public.allowance a on ea.allowance_fk = a.id 
where ea.employee_fk = '3719cb50-18c4-401b-9df0-a81ef13ca5f4';

--Deductions of an specific employee
select e.name as employee_name, d.name as deduction_name, ed.amount, ed.effective_date
from public.employee_deductions ed 
join public.employee e on ed.employee_fk = e."UUID" 
join public.deduction d on ed.deduction_fk = d.id 
where ed.employee_fk = 'df9407a8-ae9d-4043-b36c-f7bc38a48e42';

--Payrolls created on a date range
select p.id as payroll_id, pt.name as payroll_type, p.reference_number, p.status, p.date_from, p.date_to, p.date_created
from public.payroll p 
join public.payroll_type pt on p.paroll_type_fk = pt.id 
where p.date_from >= '2000-01-01' and p.date_to <= '2024-01-01' ;
select * from payroll p ;

--Summary of an employee's payroll, including wages, compensation, and deductions
select e.name as employee_name, ps.present, ps.absent, ps.salary, ps.allowance_amount, ps.net, ps.date_created
from public.payslip ps 
join public.employee e on ps.employee_fk = e."UUID" 
where ps.employee_fk = '49b0ae5c-b4d1-4d0e-b27b-302900f0d340';
select * from employee e ;

--Departments report with the number of employees and their respective salary
select d.id as department_id, d.name as department_name, count(e."UUID") as number_of_employees, avg(e.salary) as average_salary
from public.department d 
join public."Position" p on d.id = p.department_fk 
join public.employee e on p.id = e.position_fk 
group by d.id, d."name" 
order by number_of_employees desc;

--List of employees with extra hours and the total mount of paid extra hours on a specific date range
select e.name as employee_name, sum(eh.hours) as total_hours, sum(eh.amount) as total_amount, min(eh.effective_date) as period_start, max(eh.effective_date) as period_end
from public.employee_extra_hours eh 
join public.employee e on eh.employee_fk = e."UUID" 
where eh.effective_date >= '1990-01-01' and eh.effective_date <= '2024-01-01'
group by e."UUID", e."name" 
order by total_amount desc;

--Compensations and deductions report by payroll type for all the employees /*_*\
select pt.name as payroll_type, e.name as employee_name, sum(case when ea.amount is null then 0 else ea.amount end) as total_allowances, 
	sum(case when ed.amount is null then 0 else ed.amount end) as total_deductions
from public.payroll p 
join public.payslip ps on p.id = ps.payroll_fk 
join public.employee e on ps.employee_fk = e."UUID" 
left join public.employee_allowances ea on e."UUID" = ea.employee_fk and ea.payroll_type_fk = p.paroll_type_fk 
left join public.employee_deductions ed on e."UUID" = ed.employee_fk and ed.payroll_type_fk = p.paroll_type_fk 
join public.payroll_type pt on p.paroll_type_fk = pt.id 
group by pt."name", e."UUID", e."name"
order by pt."name", e."name";

--Payment history from an specific employee
select e.name as employee_name, ps.present, ps.absent, ps.salary, ps.allowance_amount, ps.deduction_amount, ps.net, p.date_from, p.date_to, ps.date_created
from public.payslip ps 
join public.employee e on ps.employee_fk = e."UUID" 
join public.payroll p on ps.payroll_fk = p.id 
where ps.employee_fk = 'd89c9845-6c9e-4144-9d78-9e76002e574c'
order by p.date_from desc;

select * from employee e ;

--List of all users with their respective role
select u.name as user_name, u.username, r.name as role_name
from public."User" u 
join public."Role" r on u.role_fk = r.id 
order by u."name" ;

--Quantity of users per role
select r.name as role_name, count(u."UUID") as user_count
from public."User" u 
join public."Role" r on u.role_fk = r.id 
group by r."name" 
order by user_count desc;

--Quantity of employees per status
select s.name as payroll_status, count(e."UUID") as employee_count
from public.employee e 
join public.status s on e.status_fk = s.id 
group by s."name" 
order by employee_count desc;