library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all; -- khai bao thu vien chuan

entity baud_rate_genator is
    generic(n:integer:=9; -- tham so dem
            m:integer:=136); --163    tham so xung tick
  port (ckht: in std_logic;
        rst : in std_logic;
        tick: out std_logic);
end baud_rate_genator;

architecture arch of baud_rate_genator is

    signal r_r: unsigned(n-1 downto 0); --9
    signal r_n: unsigned(n-1 downto 0); --9

begin
    
    identifier : process( ckht, rst )
    begin
        if rst = '0' then
            r_r <= (others => '0');  -- tin hieu reset 
        elsif falling_edge(ckht) then
            r_r <= r_n;
        end if ; 
    end process ; -- identifier
    r_n <= (others => '0') when r_r = (m-1) else  -- r_n bang o
        r_r + 1;
    tick <= '1' when r_r = (m-1) else
        '0';
    process (r_r)
    begin
        if r_r = (m - 1 ) then
            r_n <= (others => '0');
            tick <= '1';
        else
            tick <= '0';
            r_n <= r_r + 1;
        end if;
    end process;       
end arch;
