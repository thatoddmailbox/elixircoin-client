defmodule Client.Block do
	def calculate_hash(block) do
		{_, blockToHash} = Map.pop(block, :hash)
		{:ok, encoded} = Poison.encode(blockToHash)
		:crypto.hash(:sha256, encoded) |> Base.encode16()
	end

    def print_log(address, [%{
        from: from,
        reward_to: reward_to,
        value: value
    } | blocks]) when from == address do
        IO.write "send #{value} elixircoin to #{from}"
        if reward_to == address do
            IO.write " (got 50 elixircoin reward)"
        end
        IO.puts ""
        print_log(address, blocks)
    end
    def print_log(address, [%{
        from: from,
        to: to,
        reward_to: reward_to,
        value: value
    } | blocks]) when to == address do
        IO.write "recv #{value} elixircoin from #{from}"
        if reward_to == address do
            IO.write " (got 50 elixircoin reward)"
        end
        IO.puts ""
        print_log(address, blocks)
    end
    def print_log(address, [%{
        reward_to: reward_to
    } | blocks]) when reward_to == address do
        IO.puts "recv 50 elixircoin as reward"
        print_log(address, blocks)
    end
    def print_log(address, [_ | blocks]) do
        print_log(address, blocks)
    end
    def print_log(_, []) do
        
    end

	def find_solution_to_block(block, difficulty, nonce \\ 0) do
		prefix = String.duplicate("0", difficulty)
		noncedBlock = Map.put(block, :nonce, nonce)
		hash = Client.Block.calculate_hash(noncedBlock)
		if String.starts_with?(hash, prefix) do
			{nonce, Map.put(noncedBlock, :hash, hash)}
		else
			find_solution_to_block(block, difficulty, nonce + 1)
		end
	end

    defp calculate_balance_offset_from(address, block) do
        if block.from == address do
            -1 * block.value
        else 
            0
        end
    end
    defp calculate_balance_offset_to(address, block) do
        if block.to == address do
            block.value
        else 
            0
        end
    end
    defp calculate_balance_offset_reward(address, block) do
        if block.reward_to == address do
            50
        else 
            0
        end
    end

    def calculate_balance(address, blocks, confirmed \\ 0, unconfirmed \\ 0)
    def calculate_balance(address, [block | blocks], confirmed, unconfirmed) do
        balanceAdd = calculate_balance_offset_from(address, block) + calculate_balance_offset_to(address, block) + calculate_balance_offset_reward(address, block)
        if block.status == 0 do
            calculate_balance(address, blocks, confirmed, unconfirmed + balanceAdd)
        else
            calculate_balance(address, blocks, confirmed + balanceAdd, unconfirmed)
        end
    end
    def calculate_balance(_, [], confirmed, unconfirmed) do
        {confirmed, unconfirmed}
    end

    def sign_block(block, private_key) do
        {:ok, blockStr} = Poison.encode(block)
        IO.puts blockStr
        {:ok, signature} = RsaEx.sign(blockStr, private_key)
        signature |> Base.encode16()
    end
end