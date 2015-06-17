library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

package LED_matrix_type_package is

	subtype LED is unsigned(7 downto 0);

	type LED_line is array (0 to 31) of LED;

	type LED_array is array (0 to 31) of LED_line;
	
	type RGB_LED_array is array (0 to 2) of LED_array;

end LED_matrix_type_package;

package body LED_matrix_type_package is

end LED_matrix_type_package;
