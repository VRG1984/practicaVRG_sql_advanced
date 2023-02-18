CREATE OR REPLACE FUNCTION keepcoding.clean_integer (p_integer INTEGER) RETURNS INTEGER 
AS ((SELECT IF(p_integer IS NULL, -999999, p_integer)))