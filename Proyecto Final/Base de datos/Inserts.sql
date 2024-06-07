insert into public."Role" (name) values('admin');
insert into public."Role" (name) values('user');

insert into public.payroll_type (name) values('Monthly');
insert into public.payroll_type (name) values('Semi-Monthly');
insert into public.payroll_type (name) values('Once');

insert into public.status (name, "comments") values('New', 'It refers if the payroll is new');
insert into public.status (name, "comments") values('Computed', 'It refers if the payroll has been computed');
