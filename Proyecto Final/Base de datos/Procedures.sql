--Achieve old payroll records
create or replace procedure archive_old_payrolls(cutoff_date Date)
LANGUAGE plpgsql
AS $$
BEGIN
    -- Insert old records into the archive table
    INSERT INTO public.archive_payroll (id, paroll_type_fk, reference_number, status, date_from, date_to, date_created)
    SELECT id, paroll_type_fk, reference_number, status, date_from, date_to, date_created
    FROM public.payroll
    WHERE date_to < cutoff_date;
    
    -- Delete old records from the main table
    DELETE FROM public.payroll
    WHERE date_to < cutoff_date;
END;
$$;



--Recalculate Salaries Based on Position changes
CREATE OR REPLACE PROCEDURE recalculate_salaries()
LANGUAGE plpgsql
AS $$
DECLARE
    emp RECORD;
    new_salary NUMERIC;
BEGIN
    FOR emp IN 
        SELECT e."UUID", e.salary, p.id as position_id, p.salary_increment
        FROM public.employee e
        JOIN public."Position" p ON e.position_fk = p.id
    LOOP
        new_salary := emp.salary + emp.salary * emp.salary_increment / 100;
        UPDATE public.employee
        SET salary = new_salary
        WHERE "UUID" = emp."UUID";
        
        INSERT INTO public.user_activity_log(user_fk, action, action_timestamp)
        VALUES (emp."UUID", 'salary recalculated', NOW());
    END LOOP;
END;
$$;
