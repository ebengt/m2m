defmodule M2m do
  @moduledoc """
  Documentation for M2m.
  """

  @doc """
  Hello world.

  ## Examples

      iex> M2m.hello
      :world

  """
  def hello do
    :world
  end

	def assemble( [] ), do: []
	def assemble( [%{:tag => _}=m | t] ) do
		{tothis, rest} = assemble_tothis( assemble_length(m), t, [] )
		[%{m | :contents => assemble(tothis)} | assemble( rest ) ]
	end
	def assemble( [m | t] ), do: [m | assemble( t )]

	def assemble_length( %{:tag => _, :bytes => [_tag, length]} ), do: length
	def assemble_length( %{:tag => _, :bytes => [_tag1, _tag, length]} ), do: length
	def assemble_length( %{:tag => _, :bytes => [_tag1, _tag2, _tag, length]} ), do: length
	def assemble_length( %{:tag => _, :bytes => [_tag1, _tag, length_counter, length1, length2]} ) when length_counter > 0x80 do
		length1 * 0x100 + length2
	end

	def length( %{:bytes => bs} ) do
		Kernel.length( bs )
	end

	def main( [file] ) do
		File.read!( file ) |> String.split("\n")  |> Enum.filter( &useful_line?/1 ) |> Enum.map(&map_from_line/1) |> assemble |> display
	end

	def map_from_line( line ) do
		map_from_line_ok( String.split(String.trim(line)) )
	end

	def useful_line?( "" ), do: false
	def useful_line?( line ), do: String.at( line, 0 ) === "{"


# Internal functions

	defp assemble_tothis( bytes, [m | t], acc ) when bytes > 0 do
		n = M2m.length(m)
		assemble_tothis( bytes - n, t, [m | acc] )
	end
	defp assemble_tothis( 0, ms, acc ) do
		{Enum.reverse(acc), ms}
	end


	defp display( ms ), do: for m <- ms, do: display( m, "" )

	defp display( %{:tag => t, :contents => cs}, pre ) do
		IO.puts([pre, t] )
		for c <- cs, do: display( c, pre <> "--->" )
	end
	defp display( m, pre ) do
		[k] = for k <- Map.keys(m), k != :bytes, do: k
		IO.puts([pre, k, " ", m[k] ])
	end


	defp map_from_line_ok( ["{", key | t] ) do
		{value, bytes} = value_bytes( t )
		integers = for x <- bytes, do: String.to_integer(x, 16)
		map_from_line( key, value, integers )
	end
	defp map_from_line_ok( _ ) do
		%{}
	end

	defp map_from_line( key, "----------------", bytes ) do
		%{:tag => key, :bytes => bytes, :contents => []}
	end
	defp map_from_line( key, value, bytes ) do
		%{key => value, :bytes => bytes}
	end


	defp value_bytes( items ) do
		{values, ["}" | bytes]} = Enum.split_while( items, &value_bytes_continue?/1 )
		{Enum.join(values, " "), bytes}
	end
	defp value_bytes_continue?( "}" ), do: false
	defp value_bytes_continue?( _ ), do: true

end
