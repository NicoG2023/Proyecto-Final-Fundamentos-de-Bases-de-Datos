--Delete an employee who has left the company
delete from public.employee where "UUID" = '30b9e6f2-86e0-4b3e-bd34-625351d76104';

select * from employee;

--Delete an outdated allowance entry for an employee
delete from public.employee_allowances where id = 15;

--Remove a department that has been dissolved
delete from public.employee 
where position_fk in (select id from public."Position" where department_fk = 2);
delete from public."Position" 
where department_fk = 2;
delete from public.department where id = 2;

--Delete incorrect deduction entries for an employee
delete from public.employee_deductions where id = 21;

--Delete an extra hours record that was mistakenly added
delete from public.employee_extra_hours where id = 3;

--Remove old payroll records that are past the retention period
delete from public.payroll where date_created = 326002017;

--Delete payroll records for a specific date range that were entered incorrectly
delete from public.payroll where date_from >= '1970-04-21' and date_to <= '1995-09-24';