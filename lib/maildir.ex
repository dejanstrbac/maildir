defmodule Maildir do
  use MailParse
  use Timex

  @part_separator ":"          # part separator
  @info_separator ","          # info separator
  @info "2" <> @info_separator # the default info


  # Maildir contains three sub-directories, new, cur and tmp.
  def is_maildir_structure?(path) do
    path |> File.dir? &&
    path |> Path.join("new") |> File.dir? &&
    path |> Path.join("cur") |> File.dir? &&
    path |> Path.join("tmp") |> File.dir?
  end


  # Folders start with a dot and have the maildir structure
  def folders(maildir_path) do
    maildir_path
      |> Path.expand
      |> Path.join(".**")
      |> Path.wildcard(match_dot: true)
      |> Enum.filter &is_maildir_structure?/1
  end


  def folder_messages(path, info_filter \\ "") do
    if is_maildir_structure?(path) do
      # Cleanup tmp files
      cleanup_folder!(path)

      # Move from new to cur all new mail
      process_folder!(path)

      prepared_filter = "*" <> @part_separator <> @info <> "*" <> info_filter <> "*"

      # Wildcard ignores filenames starting with a dot by default
      path
        |> Path.expand
        |> Path.join("cur")
        |> Path.join(prepared_filter)
        |> Path.wildcard
        |> Enum.sort(&(parse_message_path(&1) |> elem(0) <= parse_message_path(&2) |> elem(0)))
    else
      {:error, :invalid_maildir}
    end
  end


  def paged(msgs, items_per_page \\ 10, page \\ 0) do
    Enum.slice(msgs, page * items_per_page, items_per_page)
      |> Enum.map &message/1
  end


  defp parse_message_path(path) do
    file_name = Path.basename(path)
    if String.contains?(path, @part_separator) do
      file_name |> String.split(@part_separator) |> List.to_tuple
    else
      { file_name, nil }
    end
  end


  def cleanup_folder!(path) do
    path
      |> Path.expand
      |> Path.join("tmp")
      |> Path.join("**")
      |> Path.wildcard(match_dot: true)
      |> Enum.each &(cleanup_file!/1)
    :ok
  end


  defp cleanup_file!(path) do
    {:ok, %{atime: atime}} = File.stat(path)
    last_access_time = Date.from(atime)
    expiry_time = Date.now |> Date.subtract(Time.to_timestamp(36, :hours))
    (Date.compare(last_access_time, expiry_time) === -1) && (File.rm(path) === :ok)
  end


  # Process the "new" subdirectory
  def process_folder!(path) do
    path
      |> Path.expand
      |> Path.join("new")
      |> Path.join("**")
      |> Path.wildcard
      |> Enum.map(&process_message(&1))
    :ok
  end


  defp process_message(path) do
    {file_name, info} = parse_message_path(path)

    processed_path = path
      |> Path.dirname
      |> Path.dirname
      |> Path.join("cur")
      |> Path.join(file_name)

    :ok = :file.rename(path, processed_path <> @part_separator <> @info )
  end


  def message(path) do
    { :ok, parsed_mail } = MailReader.read(path)
    { :ok, received_at } = DateFormat.parse(parsed_mail.date, "{RFC1123z}")

    %{
      subject: Map.get(parsed_mail, :subject, "(No Subject)"),
      from:    parsed_mail.from,
      date:    DateFormat.format!(received_at, "{ISO}"),
      raw:     parsed_mail
     }
  end


  def update_message_flags(path, flag, action) do
    {file_name, info_part} = parse_message_path(path)
    file_name <> @part_separator <> update_flags(info_part, flag, action)
  end


  defp update_flags(info, flag, action) do
    flags = %{ passed: "P", replied: "R", seen: "S", trashed: "T", draft: "D", flagged: "F" }
    if Map.has_key?(flags, flag) do
      case action do
        :add    -> add_flag(info, flags[flag])
        :remove -> remove_flag(info, flags[flag])
        _       -> :error
      end
    else
      :error
    end
  end


  defp add_flag(info, flag) do
    [version, flags] = String.split(info || @info, @info_separator)
    if String.contains?(flags, flag) do
      info
    else
      version <> @info_separator <> order_flags(flags <> flag)
    end
  end


  # Remove a flag from the info part
  defp remove_flag(info, flag) do
    [version, flags] = String.split(info || @info, @info_separator)
    if String.contains?(flags, flag) do
      version <> @info_separator <> (String.split(flags, ~r{}) |> List.delete(flag) |> Enum.join)
    else
      info
    end
  end


  # Order flags of the info part
  defp order_flags(flags), do: String.split(flags, ~r{}) |> Enum.sort |> Enum.join


end
