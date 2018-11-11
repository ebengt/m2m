defmodule M2mTest do
  use ExUnit.Case
  doctest M2m

  test "ignore line without item" do
    assert false === M2m.useful_line?( "/* Record_N 1 */" )
  end

  test "map from line" do
    m = M2m.map_from_line( "{ servedMSISDN INTERNATIONAL_NUMBER ISDN/TELEPHONY_NUMBERING_PLAN 1090 } 80 01 55" )

    assert m == %{"servedMSISDN" => "INTERNATIONAL_NUMBER ISDN/TELEPHONY_NUMBERING_PLAN 1090", :bytes => [128,01,85]}
  end

  test "map with items from line" do
    m = M2m.map_from_line( "{ p-GWAddress                              ---------------- } A4 06" )
 
    assert m == %{:tag => "p-GWAddress", :contents => [], :bytes => [164,06]}
  end

  test "length" do
    m = %{"recordType" => "pGWRecord", :bytes => [80,01,55]}

    assert M2m.length( m ) == 3
  end

  test "assemble maps" do
    m0 = %{"recordType" => "pGWRecord", :bytes => [128,01,85]}
    m1 = %{"iPBinV4Address" => "193.254.163.148", :bytes => [80, 04, C1, FE, A3, 94]}
    ms = [m0, m1]

    ^ms = M2m.assemble( ms )
  end

  test "assemble maps into" do
    m0 = %{:tag => "p-GWAddress", :contents => [], :bytes => [164,12]}
    m1 = %{"iPBinV4Address" => "1.254.163.148", :bytes => [1, 04, C1, FE, A3, 94]}
    m2 = %{"iPBinV4Address" => "2.254.163.148", :bytes => [2, 04, C1, FE, A3, 94]}

    [into] = M2m.assemble( [m0, m1, m2] )

    assert into == %{:tag => "p-GWAddress", :contents => [m1, m2], :bytes => [164,12]}
  end

  test "assemble maps into and more" do
    m0 = %{:tag => "p-GWAddress", :contents => [], :bytes => [164,12]}
    m1 = %{"iPBinV4Address" => "1.254.163.148", :bytes => [1, 04, C1, FE, A3, 94]}
    m2 = %{"iPBinV4Address" => "2.254.163.148", :bytes => [2, 04, C1, FE, A3, 94]}
    m3 = %{"recordType" => "pGWRecord", :bytes => [80,01,55]}

    [into, m] = M2m.assemble( [m0, m1, m2, m3] )

    assert into == %{:tag => "p-GWAddress", :contents => [m1,m2], :bytes => [164,12]}
    assert m == m3
  end

  test "assemble maps into into" do
    m0 = %{:tag => "p-GWAddress", :contents => [], :bytes => [164,8]}
    m1 = %{:tag => "GWAddress", :contents => [], :bytes => [164,6]}
    m2 = %{"iPBinV4Address" => "2.254.163.148", :bytes => [2, 04, C1, FE, A3, 94]}
    m3 = %{"recordType" => "pGWRecord", :bytes => [80,01,55]}

    [into, m] = M2m.assemble( [m0, m1, m2, m3] )

    minto = Map.put( m1, :contents, [m2])
    assert into == %{:tag => "p-GWAddress", :contents => [minto], :bytes => [164,8]}
    assert m == m3
  end


@tag :thisone
  test "assemble maps into into and more" do
    m0 = %{:tag => "p-GWAddress", :contents => [], :bytes => [164,19]}
    m1 = %{:tag => "GWAddress", :contents => [], :bytes => [164,6]}
    m2 = %{"iPBinV4Address" => "2.254.163.148", :bytes => [2, 04, C1, FE, A3, 94]}
    m3 = %{:tag => "GW3", :contents => [], :bytes => [164,6]}
    m4 = %{"iPBinV4Address" => "3.254.163.148", :bytes => [2, 04, C1, FE, A3, 94]}
    m5 = %{"recordType" => "pGWRecord", :bytes => [80,01,55]}

    [total] = M2m.assemble( [m0, m1, m2, m3, m4, m5] )

    minto1 = Map.put( m1, :contents, [m2])
    minto2 = Map.put( m3, :contents, [m4])
    assert total == %{:tag => "p-GWAddress", :contents => [minto1, minto2, m5], :bytes => [164,19]}
  end

end
