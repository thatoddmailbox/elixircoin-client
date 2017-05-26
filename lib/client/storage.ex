defmodule Client.Storage do
	def get_base_path do
		Path.join(System.user_home!, ".elixircoin")
	end

	def create_folder_if_not_exist(path) do
		case File.mkdir(path) do
			:ok -> { :ok }
			{ :error, :eexist } -> { :ok }
			{ :error, reason } -> { :error, reason }
		end
	end

	def init_storage do
		get_base_path |> create_folder_if_not_exist

		Path.join(get_base_path, "addresses") |> create_folder_if_not_exist
	end

	def get_addresses do
		addressPath = Path.join(get_base_path, "addresses")
		{:ok, identifiers} = addressPath |> File.ls
		Enum.reject(identifiers, fn(identifier) ->
			!File.dir?(Path.join(get_base_path, "addresses") |> Path.join(identifier))
		end) |> Enum.map(fn(identifier) ->
			{:ok, address} = get_address(identifier)
			{identifier, address}
		end)
	end

	def get_address(identifier) do
		path = Path.join(get_base_path, "addresses") |> Path.join(identifier)
		File.read(path |> Path.join("address"))
	end

	def save_address(address, public, private) do
		pathIdentifier = :crypto.hash(:sha256, address) |> Base.encode16() |> String.slice(0, 10)
		path = Path.join(get_base_path, "addresses") |> Path.join(pathIdentifier)
		Client.Storage.create_folder_if_not_exist(path)

		File.write(Path.join(path, "address"), address)
		File.write(Path.join(path, "public"), public)
		File.write(Path.join(path, "private"), private)
	end

	def address_identifier_exists?(identifier) do
		path = Path.join(get_base_path, "addresses") |> Path.join(identifier)
		File.exists?(path)
	end

	defp find_private_key_helper(address, [{identifier, addressToCheck} | addresses]) when address == addressToCheck do
		path = Path.join(get_base_path, "addresses") |> Path.join(identifier) |> Path.join("private")
		File.read(path)
	end
	defp find_private_key_helper(address, [{_, addressToCheck} | addresses]) when address != addressToCheck do
		find_private_key_helper(address, addresses)
	end
	defp find_private_key_helper(address, []) do
		:does_not_exist
	end

	def find_private_key(address) do
		find_private_key_helper(address, get_addresses)
	end
end