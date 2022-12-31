library ieee;
  use ieee.std_logic_1164.all;  -- thu vien logic chuan
  use ieee.std_logic_arith.all; -- thu vien toan hoc
  use ieee.std_logic_unsigned.all;  -- thu vien so khong dau

entity fifo_rx is
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
end entity;

architecture behavioral of fifo_rx is
  type reg_file_type is array (2**w-1 downto 0) of std_logic_vector(b-1 downto 0);
  -- tao mang hai chieu chua 2^w-1 phan tu, moi phan tu co do rong b-1 bit
  signal array_r  : reg_file_type;
  signal wr_prt_r : std_logic_vector(w-1 downto 0); --dia chi cua phan tu se ghi vao trong mang
  signal wr_prt_n : std_logic_vector(w-1 downto 0);
  signal wr_prt_s : std_logic_vector(w-1 downto 0);

  signal rd_prt_r : std_logic_vector(w-1 downto 0); --dia chi cua phan tu se duoc doc ra 
  signal rd_prt_n : std_logic_vector(w-1 downto 0);
  signal rd_prt_s : std_logic_vector(w-1 downto 0);

  signal full_r, full_n : std_logic;        -- n : net
  signal empty_r, empty_n : std_logic;      -- r : register

  signal wr_op : std_logic_vector(1 downto 0); -- bao hieu trang thai doc/ghi
  signal wr_en : std_logic; -- cho phep fifo ghi du lieu
begin
   reg_file: process(clkht, rst)    -- khoi xu ly qua trinh doc ghi du lieu
   begin
    if rst = '1' then array_r <= (others => (others => '0'));  -- xoa tat ca du lieu khi reset tich cuc
    elsif rising_edge(clkht) then
        if wr_en = '1' then
            array_r(conv_integer(unsigned(wr_prt_r)))<= wr_data; -- ghi du lieu vao dia chi wr_prt
        end if;  
    end if;
   end process reg_file;
   wr_en <= wr and not(full_r); -- tin hieu cho phep ghi khi co tin hieu yeu cau ghi va fi fo chua day
   rd_data <= array_r(conv_integer(unsigned(rd_prt_r))); -- doc du lieu o dia chi rd_prt (doi kieu du lieu)
  fifo : process(clkht, rst)
  begin
    if rst = '1' then   -- ban dau tat ca dia chi o o nho 0
        wr_prt_r <= (others => '0');
        rd_prt_r <= (others => '0');
        full_r <= '0';  -- fifo chua day
        empty_r <= '1'; -- fifo rong
    elsif rising_edge(clkht) then   -- cap nhat tin hieu n cho r tai canh xuong cua clkht
        wr_prt_r <= wr_prt_n;
        rd_prt_r <= rd_prt_n;
        full_r <= full_n;
        empty_r <= empty_n;
    end if;
    end process fifo;
    wr_prt_s <= wr_prt_r + 1;
    rd_prt_s <= rd_prt_r + 1;
    wr_op <= wr & rd;
    process(wr_prt_r, wr_prt_s, rd_prt_r, rd_prt_s, wr_op, empty_r, full_r) -- may trang thai
    begin
        wr_prt_n <= wr_prt_r; -- gan cac tin hieu bang thanh ghi nho cua no
        rd_prt_n <= rd_prt_r;
        full_n <= full_r;
        empty_n <= empty_r;
    case wr_op is
        when "00" => --fifo khong lam gi
        when "01" => -- fifo doc du lieu ra
            if empty_r = '0' then 
                rd_prt_n <= rd_prt_s; -- dia chi cua thanh ghi rd tang len 1
                full_n <= '0'; -- fifo co the rong hoac van con du lieu
                if rd_prt_s = wr_prt_r then -- neu khong ghi ma chi doc co the dan toi du lieu trong fifo bi doc het
                    empty_n <= '1';     -- neu con tro doc tiep theo tro toi vi tri cho tro ghi thi xac dinh da doc het du lieu trong fifo
                end if;
            end if;
        when "10" => -- fifo ghi du lieu vao
            if full_r = '0' then
                wr_prt_n <= wr_prt_s;    --tang dia chi cua thanh ghi wr len 1
                empty_n <= '0'; -- fifo co the day hoac chua day
                if wr_prt_s = rd_prt_r then -- neu khong doc ma chi ghi co the dan toi bo nho cua fifo co the bi day
                    full_n <= '1';  -- neu con tro ghi tiep theo ma tro toi vi tri cua thanh ghi chuan bi doc ra xac dinh fifo da day
                end if;
            end if;
        when others => -- ghi doc dong thoi
            wr_prt_n <= wr_prt_s;   -- 
            rd_prt_n <= rd_prt_s;
    end case;
    end process;
    empty <= empty_r;
    -- full <= full_r;
end behavioral;
-- tin hieu n la tin hieu duoc xu ly trong moi tien trinh va se cap nhat lai cho tin hieu r sau moi canh xuong cua cklht