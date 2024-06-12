--status of payroll records automatically change from new to computed after a certain period
create or replace function update_payroll_status() returns trigger as $$
begin 
	if new.status = 'new' and (new.date_created + interval '30 days') <= now() then new.status := 'computed';
	end if;
	return new;
end;
$$ language plpgsql;

create trigger payroll_status_update
before update on public.payroll 
for each row 
execute function update_payroll_status();

--log all changes made to the employee table
create or replace function log_employee_changes() returns trigger as $$
begin 
	IF TG_OP = 'INSERT' THEN
        IF EXISTS (SELECT 1 FROM public."User" WHERE "UUID" = NEW."UUID") THEN
            INSERT INTO public.user_activity_log (employee_fk, action, action_timestamp) 
            VALUES (NEW."UUID", 'insert', NOW());
        END IF;
    ELSIF TG_OP = 'UPDATE' THEN
        IF EXISTS (SELECT 1 FROM public."User" WHERE "UUID" = NEW."UUID") THEN
            INSERT INTO public.user_activity_log (employee_fk, action, action_timestamp) 
            VALUES (NEW."UUID", 'update', NOW());
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF EXISTS (SELECT 1 FROM public."User" WHERE "UUID" = OLD."UUID") THEN
            INSERT INTO public.user_activity_log (employee_fk, action, action_timestamp) 
            VALUES (OLD."UUID", 'delete', NOW());
        END IF;
    END IF;
	return new;
end
$$ language plpgsql;

create trigger employee_changes_log
after insert or update or delete on public.employee 
for each row
execute function log_employee_changes();

delete from employee where "UUID" = '550e8400-e29b-41d4-a716-446655440000';

--prevent anyupdates or inserts that would set an employee's salary to a negative value
create or replace function prevent_negative_salary() returns trigger as $$
begin 
	if new.salary < 0 then raise exception 'Salary cannot be negative';
	end if;
	return new;
end;
$$ language plpgsql;

create trigger check_negative_salary
before insert or update on public.employee 
for each row 
execute function prevent_negative_salary();

--delete related records of deleted employee
create or replace function cascade_delete_employee() returns trigger as $$
begin 
	delete from public.employee_allowances where employee_fk = old."UUID";
	delete from public.employee_deductions where employee_fk = old."UUID";
	delete from public.employee_extra_hours where employee_fk = old."UUID";
	return old;
end;
$$ language plpgsql;

create trigger cascade_delete_employee_records
before delete on public.employee 
for each row 
execute function cascade_delete_employee();

drop trigger if exists payroll_status_update on public.payroll ;
drop function if exists update_payroll_status();

drop trigger if exists employee_changes_log on public.employee ;
drop function if exists log_employee_changes() ;

-- Eliminar el trigger
DROP TRIGGER IF EXISTS cascade_delete_employee_records ON public.employee;

-- Eliminar la función
DROP FUNCTION IF EXISTS cascade_delete_employee();


select * from "Position" p ;
select * from department d ;
select * from employee_allowances ea ;