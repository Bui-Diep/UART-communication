 chỉnh sửa
library ieee;
use IEEE.std_logic_1164.all;
use IEEE.std_logic_unsigned.all;
use IEEE.std_logic_arith.all;

entity Top_uart is
  generic (
    dvsr_bit   : integer  :=  9;      -- bit dem xung tick
    dvsr       : integer  :=  163;    -- dem tan so ckht
    d_bit      : integer  :=  8;      -- so bit data
    sb_tick    : integer  :=  16;     -- so xung tick trong 1 bit data
    fifo_w     : integer  :=  2       -- 2^(fifo_w) thanh ghi
  );
  port (
    ckht  : in std_logic; -- 50Mhz
    rst   : in std_logic;

    uart_rx : in std_logic;      -- baudspeed 19200 bps
    uart_tx : out std_logic;

    fifo_rx_ena_rd  : in std_logic; -- yeu cau doc du lieu tu fifo
    fifo_rx_data_out: out std_logic_vector(7 downto 0); -- du lieu ra song song
    fifo_rx_empty   : out std_logic;  -- fifo bao trang thai trong

    fifo_tx_ena_wr  : in std_logic; -- yeu cau ghi du lieu vao fifo
    fifo_tx_data_in : in std_logic_vector(7 downto 0);  -- du lieu vao song song
    fifo_tx_full    : out std_logic -- fifo bao trang thai day
  );
end entity;

architecture rtl of Top_uart is
------------------------------------------------------------------------
    component baud_rate_genator is
        generic(
                n:integer:=9;   --9
                m:integer:=136  --163    khai bao cac tham so
                ); 
      port (ckht: in std_logic;
            rst : in std_logic;
            tick: out std_logic);
    end component;
------------------------------------------------------------------------
    component uart_controller_rx is
        generic (
          d_bit : integer := 8;
          sb_tick : integer := 16
        );
        port (
              ckht : in std_logic;
              rst : in std_logic;
              rx : in std_logic;
              s_tick : in std_logic;
      
              rx_done_tick : out std_logic;
              rx_data : out std_logic_vector(7 downto 0)
             );
    end component;
------------------------------------------------------------------------
    component fifo_rx is
      generic ( b: natural := 8;    -- xac dinh do rong byte du lieu
                w: natural := 5);   -- xac dinh so phan tu trong mang  -- 32 thanh ghi
      port (
        clkht    : in std_logic;
        rst     : in std_logic;
        rd      : in std_logic;  -- yeu cau doc
        wr      : in std_logic;  -- yeu cau ghi
        wr_data : in std_logic_vector(7 downto 0); -- byte du lieu ghi vao
        empty   : out std_logic; -- bao trong
        -- full: out std_logic;    -- bao day
        rd_data : out std_logic_vector(7 downto 0) -- byte du lieu xuat ra
          );
    end component;
------------------------------------------------------------------------
    component uart_controller_tx is
      generic ( d_bit   : integer := 8; -- do rong bit du lieu
                sb_tick : integer := 16 -- so lan lay mau
              );
      port (  clkht   : in std_logic;     -- xung he thong
              rst     : in std_logic;     -- tin hieu reset
              s_tick  : in std_logic;     -- tin hieu lay mau
              tx_data : in std_logic_vector(7 downto 0);  -- dau vao song song
              tx_fifo_empty : in std_logic;   -- bao fifo trong
              tx_done_tick    : out std_logic;    -- tin hieu bao da truyen xong mot khung du lieu
              tx      : out std_logic -- dau ra noi tiep
          );
    end component;
------------------------------------------------------------------------
    component fifo_tx is
      generic ( b : natural := 8; -- do rong bus du lieu la b bit
                w : natural := 2 -- co 2^w thanh ghi  
                );
      port (
        clkht   : in std_logic;
        rst     : in std_logic;
        rd      : in std_logic;
        wr      : in std_logic;
        wr_data : in std_logic_vector(b-1 downto 0);
        empty   : out std_logic;
        full    : out std_logic;
        rd_data : out std_logic_vector(b-1 downto 0)
          );
    end component;
------------------------------------------------------------------------
-- khai bao tin hieu trung gian
signal s_tick           : std_logic;
signal fifo_rx_data_in  : std_logic_vector(7 downto 0);
signal fifo_rx_wr       : std_logic;

signal fifo_tx_data_out : std_logic_vector(7 downto 0);
signal fifo_tx_rd       : std_logic;
signal fifo_tx_empty    : std_logic;

begin
------------------------------------------------------------------------
baud_rate_genator_inst: baud_rate_genator
  generic map (
    n => dvsr,
    m => dvsr_bit
  )
  port map (
    ckht => ckht,
    rst  => rst,
    tick => s_tick
  );
------------------------------------------------------------------------
uart_controler_rx_inst: uart_controller_rx
  generic map (
    d_bit   => d_bit,
    sb_tick => sb_tick
  )
  port map (
    ckht         => ckht,
    rst          => rst,
    rx           => uart_rx,
    s_tick       => s_tick,
    rx_done_tick => fifo_rx_wr,
    rx_data      => fifo_rx_data_in
  );
------------------------------------------------------------------------
fifo_rx_inst: fifo_rx
  generic map (
    b => d_bit,
    w => fifo_w
  )
  port map (
    clkht   => ckht,
    rst     => rst,
    rd      => fifo_rx_ena_rd,
    wr      => fifo_rx_wr,
    wr_data => fifo_rx_data_in,
    empty   => fifo_rx_empty,
    rd_data => fifo_rx_data_out
  );
------------------------------------------------------------------------
uart_controller_tx_inst: uart_controller_tx
  generic map (
    d_bit   => d_bit,
    sb_tick => sb_tick
  )
  port map (
    clkht         => ckht,
    rst           => rst,
    s_tick        => s_tick,
    tx_data       => fifo_tx_data_out,
    tx_fifo_empty => fifo_tx_empty,
    tx_done_tick  => fifo_tx_rd,
    tx            => uart_tx
  );
------------------------------------------------------------------------
fifo_tx_inst: fifo_tx
  generic map (
    b => d_bit,
    w => fifo_w
  )
  port map (
    clkht   => ckht,
    rst     => rst,
    rd      => fifo_tx_rd,
    wr      => fifo_tx_ena_wr,
    wr_data => fifo_tx_data_in,
    empty   => fifo_tx_empty,
    full    => fifo_tx_full,
    rd_data => fifo_tx_data_out
  );
  
end architecture;
--finish
