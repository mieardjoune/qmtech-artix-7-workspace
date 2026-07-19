-------------------------------------------------------------------------------
-- File        : ram.vhd
-- Project     : qmtech-workspace / ram_test
-- Standard    : IEEE 1076-2008 (VHDL), IEEE 1164 (std_logic)
-- Description : Synchronous single-port RAM, optionally initialized at
--               elaboration time from mem_content.txt (one decimal value
--               per line, most-significant word first).
-------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use std.textio.all;

entity ram is
    generic (
        g_width : integer := 8;
        g_depth : integer := 16
    );
    port (
        clk  : in  std_logic;
        we   : in  std_logic;
        addr : in  std_logic_vector(3 downto 0);
        din  : in  std_logic_vector(g_width-1 downto 0);
        dout : out std_logic_vector(g_width-1 downto 0)
    );
end entity;

architecture rtl of ram is
    type ram_type is array (0 to g_depth-1) of std_logic_vector(g_width-1 downto 0);

    impure function init_ram return ram_type is
        file f_file       : text;
        variable l_line   : line;
        variable val      : integer;
        variable temp_ram : ram_type := (others => (others => '0'));
        variable f_status : file_open_status;
    begin
        file_open(f_status, f_file, "mem_content.txt", read_mode);
        if f_status = open_ok then
            for i in 0 to g_depth-1 loop
                if not endfile(f_file) then
                    readline(f_file, l_line);
                    read(l_line, val);
                    temp_ram(i) := std_logic_vector(to_unsigned(val, g_width));
                end if;
            end loop;
            file_close(f_file);
        end if;
        return temp_ram;
    end function;

    signal r_ram : ram_type := init_ram;
begin
    process(clk)
    begin
        if rising_edge(clk) then
            if we = '1' then
                r_ram(to_integer(unsigned(addr))) <= din;
            end if;
            dout <= r_ram(to_integer(unsigned(addr)));
        end if;
    end process;
end architecture;
