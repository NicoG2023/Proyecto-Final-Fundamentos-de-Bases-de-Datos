--Update an employee's position
update public.employee set position_fk = 1 where "UUID" = 'd054962a-db0b-4894-8ae1-a0b6003e21ee';
select * from employee e where "UUID" = 'd054962a-db0b-4894-8ae1-a0b6003e21ee';

--Update an employee's salary
update public.employee set salary = 90000.85 where "UUID" = '0ff994a8-0b1a-4b82-94dd-a574a70ba701';
select * from employee e where "UUID" = '0ff994a8-0b1a-4b82-94dd-a574a70ba701';

--Change an employee's status
update public.employee set status_fk = 1 where "UUID" = 'de7d1f21-6b75-42c4-9092-90939d9a40c5';
select * from employee e where "UUID" = 'de7d1f21-6b75-42c4-9092-90939d9a40c5';

--Update an employee's email
update public.employee set email = '' where "UUID" = '2b42ad01-c9a4-471b-9f73-cfeaab5e1834';
select * from employee e where "UUID" = '2b42ad01-c9a4-471b-9f73-cfeaab5e1834';

--Update a employee's role
update public.employee set role_fk = 2 where "UUID" = '';
select * from public.employee e where "UUID" = '';
select * from employee e ;

--Update the number of extra hours worked by an employee
update public.employee_extra_hours set hours = 15, amount = 8000 where id = 20;

--Change an employee's phone number
update public.employee set phone = '123654821' where "UUID" = 'df9407a8-ae9d-4043-b36c-f7bc38a48e42';
select * from employee e where "UUID" = 'df9407a8-ae9d-4043-b36c-f7bc38a48e42';

--Correct a typo in the job title of a position
update public."Position" set name = 'Waiter/Waitress' where id = 5;