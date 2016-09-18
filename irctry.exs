defmodule IRCTry do

  @initial_state %{socket: nil}

  def init(state, host, port, nick, channel, handler) do
    {:ok, socket} = :gen_tcp.connect(host, port, [:binary, active: false])
    {:ok, %{state | socket: socket}}
    say(socket, "NICK #{nick}")
    say(socket, "USER ircbot 0 * #{nick}")
    say(socket, "JOIN ##{channel}")
    say_to_chan(socket, channel, "Hello")
    read(socket, channel, handler)
  end

  defp say(socket, msg) do
    :gen_tcp.send(socket, msg <> "\n")
    IO.puts msg
  end

  defp say_to_chan(socket, channel, msg) do
    say(socket, "PRIVMSG ##{channel} :#{msg}")
  end

  defp read(socket, channel, f) do
    {:ok, msg} = :gen_tcp.recv(socket, 0)
    IO.puts msg
    case msg do
      "PING :" <> host ->
        say(socket, "PONG :" <> host)
      _ ->
        reply = f.(msg)
        case reply do
          {:ok, msg} ->
            say_to_chan(socket, channel, msg)
          _ ->
            nil
        end
    end
    read(socket, channel, f)
  end
end

handler = fn (msg) ->
  smsg = String.Chars.to_string(msg)
  if String.contains?(smsg, "hi bot") do
    {:ok, "Hi back!"}
  end
end
IRCTry.init(%{socket: nil}, 'irc.freenode.net', 6667, 'IrcBot70101', 'fun_channel', handler)
