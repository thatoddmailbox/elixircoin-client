defmodule Client.Address do
	def get_address_from_public_key(key) do
		key |> String.split("\n") |> Enum.slice(1, 7) |> Enum.join()
	end

	def get_public_key_from_address(address) do
		addressParts = address |> String.codepoints |> Enum.chunk(64, 64, []) |> Enum.map(&Enum.join(&1)) 
		Enum.concat([ "-----BEGIN PUBLIC KEY-----" ], addressParts) |> Enum.concat([ "-----END PUBLIC KEY-----", "" ]) |> Enum.join("\n")
	end

	def generate_address do
		{:ok, {private, public}} = RsaEx.generate_keypair
		{:ok, {get_address_from_public_key(public), public, private}}
	end

	def is_valid?(address) do
		String.length(address) == 392
	end

	def try_expand_identifier(identifier) do
		if Client.Storage.address_identifier_exists?(identifier) do
			{:ok, address} = Client.Storage.get_address(identifier)
			address
		else
			identifier
		end
	end
end