library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

entity uart_controller_tx is
  generic ( d_bit   : integer := 8; -- do rong bit du lieu
            sb_tick : integer := 16 -- so lan lay mau
            );
  port (    clkht   : in std_logic;     -- xung he thong
            rst     : in std_logic;     -- tin hieu reset
            s_tick  : in std_logic;     -- tin hieu lay mau
            tx_data : in std_logic_vector(7 downto 0);  -- dau vao song song
            tx_fifo_empty : in std_logic;   -- bao fifo trong
            tx_done_tick    : out std_logic;    -- tin hieu bao da truyen xong mot khung du lieu
            tx      : out std_logic -- dau ra noi tiep
  );
end uart_controller_tx;

architecture behavioral of uart_controller_tx is
    type state_type is (idle, start, data, stop);
    signal state_r, state_n : state_type;
    signal s_r, s_n : unsigned(3 downto 0); -- dem so lan lay mau
    signal n_r, n_n : unsigned(2 downto 0); -- dem so bit da nhan duoc

    signal b_r, b_n : std_logic_vector(7 downto 0); -- thanh ghi (8 bit) du lieu dau vao
    signal tx_r, tx_n : std_logic;
begin
   process(clkht, rst)
   begin
    if rst = '1' then -- dua he thong ve trang thai reset (ch)
        state_r <= idle;
        s_r <= (others => '0');
        n_r <= (others => '0');
        b_r <= (others => '0');
        tx_r <= '1';   
    elsif falling_edge (clkht) then -- trang thai se duoc cap nhat sau moi lan
        state_r <= state_n;         -- co canh xuong cua xung he thong
        s_r <= s_n;                 -- duoc luu o trang thai register
        n_r <= n_n;
        b_r <= b_n;
        tx_r <= tx_n;
    end if;
   end process ;
  process(state_r, s_r, n_r, b_r, s_tick, tx_r, tx_fifo_empty, tx_data )
  begin
    state_n <= state_r;
    s_n <= s_r;
    b_n <= b_r;
    n_n <= n_r;
    tx_n <= tx_r;
    tx_done_tick <= '0';

    case state_r is
        when idle =>
            tx_n <= '1';
            if tx_fifo_empty = '0' then
                state_n <= start;
                s_n <= (others => '0');
                b_n <= tx_data;
            end if;
        when start =>
            tx_n <= '0';
            if s_tick = '1' then
                if s_r = 15 then
                    state_n <= data;
                    s_n <= (others => '0');
                    n_n <= (others => '0');
                else s_n <= s_r + 1;
                end if;
            end if;
        when  data =>
            tx_n <= b_r (0);
            if s_tick = '1' then
                if s_r = 15 then
                    s_n <= (others => '0');
                    b_n <= '0' & b_r(7 downto 1);
                    if n_r = (d_bit - 1) then
                        state_n <= stop;
                    else n_n <= n_r + 1;
                    end if;
                else s_n <= s_n + 1;
                end if;
            end if;
        when stop =>
            tx_n <= '1';
            if  s_tick = '1' then
                if  s_r = sb_tick - 1 then
                    state_n <= idle;
                    tx_done_tick <= '1';
                else s_n <= s_n + 1;
                end if;
            end if;
    end case;
  end process ;
  tx <= tx_r;
end behavioral;
