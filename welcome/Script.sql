select tc.constraint_name, c.data_type 
from information_schema.table_constraints as tc
	left join information_schema.key_column_usage as kcu
	on tc.constraint_name = kcu.constraint_name 
	left join information_schema.columns as c
	on kcu.table_name = c.table_name and kcu.column_name = c.column_name
where tc.constraint_type = 'PRIMARY KEY'