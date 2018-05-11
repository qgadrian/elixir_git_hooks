defmodule GitHooks.Printer do
  @moduledoc false

  @type message :: String.t()

  @spec info(any, message) :: any
  def info(return_this, message) do
    info(message)
    return_this
  end

  @spec info(message) :: :ok
  def info(message) do
    IO.puts([IO.ANSI.blue(), 0x2197, " ", message])
    IO.write(IO.ANSI.default_color())
  end

  @spec warn(message) :: :ok
  def warn(message) do
    IO.puts([IO.ANSI.yellow(), 0x26A0, " ", message])
    IO.write(IO.ANSI.default_color())
  end

  @spec success(message) :: :ok
  def success(message) do
    IO.puts([IO.ANSI.green(), 0x2714, " ", message])
    IO.write(IO.ANSI.default_color())
  end

  @spec error(message) :: :ok
  def error(message) do
    IO.puts([IO.ANSI.red(), 0xD7, " ", message])
    IO.write(IO.ANSI.default_color())
  end
end
