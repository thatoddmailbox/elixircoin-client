defmodule Client.Network do
	def get_base_url do
		urlPath = Client.Storage.get_base_path |> Path.join("url")
		if File.exists?(urlPath) do
			{:ok, url} = File.read(urlPath)
			String.trim(url)
		else
			"http://localhost:4000/api/"
		end
	end

	def start do
		HTTPoison.start
	end

	def get_blocks do
		%{body: body} = HTTPoison.get!(get_base_url <> "get_blocks")
		{:ok, %{blocks: blocks}} = Poison.decode(body, keys: :atoms)
		blocks
	end

	def get_difficulty do
		%{body: body} = HTTPoison.get!(get_base_url <> "get_difficulty")
		{:ok, %{difficulty: difficulty}} = Poison.decode(body, keys: :atoms)
		difficulty
	end

	def add_block(block) do
		%{body: body} = HTTPoison.get!(get_base_url <> "add_block", [], [
			params: %{
				block: block
			}
		])
	end

	def confirm_block(nonce, reward_to) do
		%{body: body} = HTTPoison.get!(get_base_url <> "confirm_block", [], [
			params: %{
				nonce: nonce,
				reward_to: Base.encode64(reward_to)
			}
		])
	end
end