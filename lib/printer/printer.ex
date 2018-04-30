defmodule GitHooks.Printer do
  @moduledoc false

  @spec info(String.t()) :: :ok
  def info(message) do
    IO.puts([IO.ANSI.blue(), 0x2197, " ", message])
    IO.write(IO.ANSI.default_color())
  end

  @spec warn(String.t()) :: :ok
  def warn(message) do
    IO.puts([IO.ANSI.yellow(), 0x26A0, " ", message])
    IO.write(IO.ANSI.default_color())
  end

  @spec success(String.t()) :: :ok
  def success(message) do
    IO.puts([IO.ANSI.green(), 0x2714, " ", message])
    IO.write(IO.ANSI.default_color())
  end

  @spec error(String.t()) :: :ok
  def error(message) do
    IO.puts([IO.ANSI.red(), 0xD7, " ", message])
    IO.write(IO.ANSI.default_color())
  end
end
