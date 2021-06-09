SELECT tc.constraint_name, c.data_type 
FROM information_schema.table_constraints AS tc
	LEFT JOIN information_schema.key_column_usage AS kcu
	ON tc.constraint_name = kcu.constraint_name 
	LEFT JOIN information_schema.columns AS c
	ON kcu.table_name = c.table_name AND kcu.column_name = c.column_name
WHERE tc.constraint_type = 'PRIMARY KEY'