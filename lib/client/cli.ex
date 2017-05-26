defmodule Client.CLI do
	def main(args) do
		Client.Network.start
		Client.Storage.init_storage

		args |> parse_args |> process
	end

	def parse_args([]) do
		{ "help", [] }
	end

	def parse_args(args) do
		parse = OptionParser.parse(args, switches: [], aliases: [])
		case parse do
			{ _, options, _ }
				-> { Enum.at(options, 0), options |> Kernel.tl }

			_ -> { "help", [] }
		end
	end

	def is_valid_integer?(str) do
		case Integer.parse(str) do
			:error -> false
			{_, _} -> true
		end
	end

	def process({ "help", _ }) do
		IO.puts "Available subcommands"
		IO.puts "=============================="
		IO.puts "* addresses"
		IO.puts "* balance <address or identifier>"
		IO.puts "* confirm <address or identifier>"
		IO.puts "* generate-address"
		IO.puts "* history <address or identifier>"
		IO.puts "* send <from address> <to address> <amount>"
	end

	def process({ "addresses", _ }) do
		IO.puts "Available addresses:"
		Enum.map(Client.Storage.get_addresses, fn({ identifier, address }) ->
			IO.puts "* #{address} (#{identifier})"
			IO.puts ""
		end)
	end

	def process({ "generate-address", _ }) do
		{:ok, {address, public, private}} = Client.Address.generate_address
		Client.Storage.save_address(address, public, private)

		IO.puts "#{address} is your new address."
		IO.puts "Address generation successful."
	end

	def process({ "balance", [ addressOrIdentifier ] }) when addressOrIdentifier != "" do
		blocks = Client.Network.get_blocks
		address = Client.Address.try_expand_identifier(addressOrIdentifier)
		if Client.Address.is_valid?(address) do
			{confirmed, unconfirmed} = Client.Block.calculate_balance(address, blocks)

			IO.puts "Balance for #{address}"
			IO.puts "Confirmed: #{confirmed} elixircoin"
			IO.puts "Unconfirmed: #{unconfirmed} elixircoin"
		else
			IO.puts "Invalid address or identifier."
		end
	end

	def process({ "balance", _ }) do
		IO.puts "Usage: balance <address to check>"
	end

	def process({ "history", [ addressOrIdentifier ] }) do
		blocks = Client.Network.get_blocks
		address = Client.Address.try_expand_identifier(addressOrIdentifier)
		if Client.Address.is_valid?(address) do
			Client.Block.print_log(address, blocks)
		else
			IO.puts "Invalid address or identifier."
		end
	end

	def process({ "history", _ }) do
		IO.puts "Usage: history <address>"
	end

	def process({ "send", [ fromInput, toInput, amountInput ] }) when fromInput != "" and toInput != "" and amountInput != "" do
		if is_valid_integer?(amountInput) do
			from = Client.Address.try_expand_identifier(fromInput)
			to = Client.Address.try_expand_identifier(toInput)
			{amount, _} = Integer.parse(amountInput)

			if Client.Address.is_valid?(from) and Client.Address.is_valid?(to) do
				blocks = Client.Network.get_blocks
				{confirmed, unconfirmed} = Client.Block.calculate_balance(from, blocks)
				if confirmed + unconfirmed >= amount do
					lastBlock = List.last(blocks)

					if lastBlock.status == 1 do
						{:ok, private_key} = Client.Storage.find_private_key(from)
						block = %{
							from: from,
							to: to,
							value: amount,
							comment: "",
							prev_hash: lastBlock.hash
						}
						signedBlock = Map.put(block, :signature, Client.Block.sign_block(block, private_key))
						{:ok, signedBlockStr} = Poison.encode(signedBlock)
						finalBlock = Base.encode64(signedBlockStr)
						
						Client.Network.add_block(finalBlock)
						IO.puts "Transaction success."
					else
						IO.puts "The last block in the blockchain has not been confirmed yet. Try again later."
					end
				else
					IO.puts "You tried to send #{amount} elixircoin, but that address only has #{confirmed + unconfirmed} elixircoin."
				end
			else
				IO.puts "From or to address is invalid."
			end
		else
			IO.puts "Amount is not a valid integer."
		end
	end

	def process({ "send", _ }) do
		IO.puts "Usage: send <from address> <to address> <amount>"
	end

	def process({ "confirm", [ rewardToInput ] }) do
		rewardTo = Client.Address.try_expand_identifier(rewardToInput)
		blocks = Client.Network.get_blocks
		difficulty = Client.Network.get_difficulty
		blockToConfirm = List.last(blocks)
		if blockToConfirm.status == 0 do
			IO.puts "Found block, looking for solution..."
			{nonce, newBlock} = Client.Block.find_solution_to_block(blockToConfirm, difficulty)
			IO.puts "Found solution to block!"
			Client.Network.confirm_block(nonce, rewardTo)
		else
			IO.puts "There is no block to confirm. Try again later."
		end
	end

	def process({ _, _ }) do
		IO.puts "Unknown command"
	end
end