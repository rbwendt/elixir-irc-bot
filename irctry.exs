defmodule IRCTry do
  use GenServer

  @initial_state %{socket: nil}
  def start_link do
    GenServer.start_link(__MODULE__, @initial_state)
  end

  def init(state, host, port, nick, channel, handler) do
    opts = [:list, active: false]
    {:ok, socket} = :gen_tcp.connect(host, port, opts)
    {:ok, %{state | socket: socket}}
    say(socket, 'NICK #{nick}')
    say(socket, 'USER ircbot 0 * #{nick}')
    say(socket, 'JOIN ##{channel}')
    say_to_chan(socket, channel, 'Hello')
    read(socket, channel, handler)
  end

  defp say(socket, msg) do
    :gen_tcp.send(socket, msg ++ [10])
    IO.puts msg
  end

  defp say_to_chan(socket, channel, msg) do
    say(socket, 'PRIVMSG ##{channel} :#{msg}')
  end

  defp read(socket, channel, f) do
    {:ok, msg} = :gen_tcp.recv(socket, 0)
    IO.puts msg

    if Enum.take(msg, 6) == 'PING :' do
      say(socket, Enum.concat('PONG :', Enum.slice(msg, 6, Enum.count(msg) - 6)))
    else
      reply = f.(msg)
      if Enum.count(reply) > 0 do
        say_to_chan(socket, channel, reply)
      end
    end
    read(socket, channel, f)
  end
end

handler = fn (msg) ->
  smsg = String.Chars.to_string(msg)
  if String.contains?(smsg, "hi bot") do
    'Hi back!'
  else
    ''
  end
end
IRCTry.init(%{socket: nil}, 'irc.freenode.net', 6667, 'IrcBot70101', 'fun_channel', handler)