library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use work.LED_matrix_type_package.all;


entity LEDMatrixDriver is
    Port ( clk : in  STD_LOGIC;
			  pwm_mode : in  STD_LOGIC;
           sclk : out  STD_LOGIC;
           r0 : out  STD_LOGIC;
           g0 : out  STD_LOGIC;
           b0 : out  STD_LOGIC;
           r1 : out  STD_LOGIC;
           g1 : out  STD_LOGIC;
           b1 : out  STD_LOGIC;
           oe : out  STD_LOGIC;
           latch : out  STD_LOGIC;
           addr_out : out  STD_LOGIC_VECTOR (3 downto 0);
           data : RGB_LED_array;
			  rst : in  STD_LOGIC
			  );
end LEDMatrixDriver;

architecture Behavioral of LEDMatrixDriver is

	type StateType is (STEP_s, READ_s, SHIFT_s, LATCH_s, SHOW_s);

	signal state: StateType;
	signal next_state: StateType;
	
	signal step_line: std_logic;
	signal step_pixel: std_logic;
	signal load_line: std_logic;
	signal show_line: std_logic;
	
	signal addr_out_i : std_logic_vector(3 downto 0);
	signal addr_out_plus : std_logic_vector(4 downto 0);
	signal shift_counter : unsigned(4 downto 0);
	signal show_counter : unsigned(13 downto 0);
	signal pwm_count: unsigned(7 downto 0);
	
	signal data_r0 : LED_line;
	signal data_g0 : LED_line;
	signal data_b0 : LED_line;
	
	signal data_r1 : LED_line;
	signal data_g1 : LED_line;
	signal data_b1 : LED_line;
	
begin

	addr_out_plus(4) <= '1';
	addr_out_plus(3 downto 0) <= addr_out_i;
	
	addr_out <= addr_out_i;

	--step to next line
	step_line <= '1' when state = STEP_s else '0';

	--Load next line
	load_line <= '1' when state = READ_s else '0';

	--step to next pixel
	step_pixel <= '1' when state = SHIFT_s else '0';

	--Latch the data in
	latch <= '1' when state = LATCH_s else '0';
	
	--show this line
	show_line <= '1' when state = SHOW_s else '0';
	--oe <= '0' when state = SHOW_s else '1';
	oe <= step_line;
	
	
	--clock when clock is needed (for shifting and latching)
	sclk <= clk when ((state = SHIFT_s) or (state = LATCH_s)) else '0';
	--sclk <= clk when (state = SHIFT_s) else '0';
	
	r0 <= '1' when (data_r0(to_integer(shift_counter))) > pwm_count else '0';
	g0 <= '1' when (data_g0(to_integer(shift_counter))) > pwm_count else '0';
	b0 <= '1' when (data_b0(to_integer(shift_counter))) > pwm_count else '0';
	r1 <= '1' when (data_r1(to_integer(shift_counter))) > pwm_count else '0';
	g1 <= '1' when (data_g1(to_integer(shift_counter))) > pwm_count else '0';
	b1 <= '1' when (data_b1(to_integer(shift_counter))) > pwm_count else '0';
	
	process (clk) begin
		if rising_edge(clk) then
			if rst='1' then
				--reset conditions
				addr_out_i <= (others => '0');
				state <= STEP_s;
				shift_counter <= (others => '0');
				show_counter <= (others => '0');
				pwm_count <= (others => '0');
			else
				--advance state
				state <= next_state;
				
				--Load data in
				if load_line = '1' then
					data_r0 <= data(0)(to_integer(unsigned(addr_out_i)));
					data_g0 <= data(1)(to_integer(unsigned(addr_out_i)));
					data_b0 <= data(2)(to_integer(unsigned(addr_out_i)));
					data_r1 <= data(0)(to_integer(unsigned(addr_out_plus)));
					data_g1 <= data(1)(to_integer(unsigned(addr_out_plus)));
					data_b1 <= data(2)(to_integer(unsigned(addr_out_plus)));
					
					if pwm_mode = '1' then
						pwm_count <= pwm_count + 1;
					else
						pwm_count <= "00000000";
					end if;
				end if;
				
				--if we need to step a line
				if step_line = '1' then
					--add one to output address
					addr_out_i <= std_logic_vector(unsigned(addr_out_i)+1);
				end if;
				
				--if we need to step a pixel
				if step_pixel = '1' then
					--add one to pixel counter
					shift_counter <= shift_counter+1;
				end if;
				
				--count up to 16384, this is the delay for ligting one row
				if step_line = '0' then
					show_counter <= show_counter+1;
				else
					show_counter <= (others => '0');
				end if;
				
			end if;
		end if;
	end process;
	
	process (state, shift_counter, show_counter, pwm_mode) begin
		case state is
			when STEP_s =>
				next_state <= READ_s;
			when READ_s =>
				next_state <= SHIFT_s;
			when SHIFT_s =>
				if shift_counter = "11110" then
					next_state <= LATCH_s;
				else
					next_state <= SHIFT_s;
				end if;
			when LATCH_s =>
				next_state <= SHOW_s;
			when SHOW_s =>
				if pwm_mode = '0' then
					if show_counter = "111111111111" then
						next_state <= STEP_s;
					else
						next_state <= SHOW_s;
					end if;
				else
					if show_counter(5 downto 0) = "111111" then
						if show_counter(13 downto 6) = "11111111" then
							next_state <= STEP_s;
						else
							next_state <= READ_s;
						end if;
					else
						next_state <= SHOW_s;
					end if;
				end if;
		end case;
	end process;

end Behavioral;

