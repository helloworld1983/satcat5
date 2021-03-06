--------------------------------------------------------------------------
-- Copyright 2019 The Aerospace Corporation
--
-- This file is part of SatCat5.
--
-- SatCat5 is free software: you can redistribute it and/or modify it under
-- the terms of the GNU Lesser General Public License as published by the
-- Free Software Foundation, either version 3 of the License, or (at your
-- option) any later version.
--
-- SatCat5 is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE.  See the GNU Lesser General Public
-- License for more details.
--
-- You should have received a copy of the GNU Lesser General Public License
-- along with SatCat5.  If not, see <https://www.gnu.org/licenses/>.
--------------------------------------------------------------------------
--
-- Testbench for the file-read functions in config_file2rom
--
-- This testbench reads data from various test files in the sim/data folder.
--
-- There is some subtlety to the relative path compatibility:
--  * ModelSim 10.0a: Path is relative to ModelSim project.
--  * Vivado 2015.4: Path is relative to the file being simulated.
-- In both cases the "../../sim/data" folder is the right place.  We may
-- need a better solution as we add support for other simulator tools.
--
-- The full test is instantaneous; runtime of one microsecond is adequate to
-- ensure that the simulator tool evaluates all relevant processes.
--

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;
use     work.config_file2rom.all;

entity config_file2rom_tb is
    -- Unit testbench top level, no I/O ports
end config_file2rom_tb;

architecture tb of config_file2rom_tb is

-- Reference data is hard-coded:
constant TEST_REF : std_logic_vector(2047 downto 0) :=
    x"000102030405060708090A0B0C0D0E0F101112131415161718191A1B1C1D1E1F" &
    x"202122232425262728292A2B2C2D2E2F303132333435363738393A3B3C3D3E3F" &
    x"404142434445464748494A4B4C4D4E4F505152535455565758595A5B5C5D5E5F" &
    x"606162636465666768696A6B6C6D6E6F707172737475767778797A7B7C7D7E7F" &
    x"808182838485868788898A8B8C8D8E8F909192939495969798999A9B9C9D9E9F" &
    x"A0A1A2A3A4A5A6A7A8A9AAABACADAEAFB0B1B2B3B4B5B6B7B8B9BABBBCBDBEBF" &
    x"C0C1C2C3C4C5C6C7C8C9CACBCCCDCECFD0D1D2D3D4D5D6D7D8D9DADBDCDDDEDF" &
    x"E0E1E2E3E4E5E6E7E8E9EAEBECEDEEEFF0F1F2F3F4F5F6F7F8F9FAFBFCFDFEFF";

-- Read each test file.
constant TEST_BIN : std_logic_vector := read_bin_file("../../sim/data/test_bin.dat");
constant TEST_HEX : std_logic_vector := read_hex_file("../../sim/data/test_hex.txt");

begin

p_test : process
begin
    assert (TEST_BIN = TEST_REF)
        report "Binary file mismatch" severity error;
    assert (TEST_HEX = TEST_REF)
        report "Plaintext file mismatch" severity error;
    report "All tests completed.";
    wait;
end process;

end tb;
