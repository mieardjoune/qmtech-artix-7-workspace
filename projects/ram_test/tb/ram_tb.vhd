-------------------------------------------------------------------------------
-- File        : ram_tb.vhd
-- Project     : qmtech-workspace / ram_test
-- Standard    : IEEE 1076-2008 (VHDL)
-- Description : Self-checking testbench for ram. Writes are pre-loaded via
--               mem_content.txt (see ram.vhd); this testbench only verifies
--               read-back of the first two initialized locations.
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ram_tb is
end entity;

architecture sim of ram_tb is
    signal clk      : std_logic := '0';
    signal we       : std_logic := '0';
    signal addr     : std_logic_vector(3 downto 0) := (others => '0');
    signal din      : std_logic_vector(7 downto 0) := (others => '0');
    signal dout     : std_logic_vector(7 downto 0);
    signal sim_done : boolean := false;
begin
    uut: entity work.ram
        port map ( clk => clk, we => we, addr => addr, din => din, dout => dout );

    clk <= not clk after 5 ns when sim_done = false else '0';

    process
    begin
        wait for 20 ns;
        addr <= "0000"; wait for 10 ns;
        assert (dout = std_logic_vector(to_unsigned(10, 8))) report "Index 0 fail" severity failure;

        addr <= "0001"; wait for 10 ns;
        assert (dout = std_logic_vector(to_unsigned(20, 8))) report "Index 1 fail" severity failure;

        report "PASS: ram_tb - all read-back values matched mem_content.txt." severity note;
        sim_done <= true;
        wait;
    end process;
end architecture;
