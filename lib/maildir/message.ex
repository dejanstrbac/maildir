# defmodule Maildir.Message do
#   defstruct maildir: nil,
#             folder:
#             folder: :tmp,
#             uniq: nil,
#             info: nil


#   defp parse_file_name(file_name) when is_binary(file_name) do
#     if String.contains?(file_name, ":") do
#       String.split(file_name, ":") |> List.to_tuple
#     else
#       { file_name, nil }
#     end
#   end


#   def update_flags(info, flag, :add) do
#     case flag do
#       :passed  -> add_flag(info, "P")
#       :replied -> add_flag(info, "R")
#       :seen    -> add_flag(info, "S")
#       :trashed -> add_flag(info, "T")
#       :draft   -> add_flag(info, "D")
#       :flagged -> add_flag(info, "F")
#       _        -> :error
#     end
#   end

#   def update_flags(info, flag, :remove) do
#     case flag do
#       :passed  -> remove_flag(info, "P")
#       :replied -> remove_flag(info, "R")
#       :seen    -> remove_flag(info, "S")
#       :trashed -> remove_flag(info, "T")
#       :draft   -> remove_flag(info, "D")
#       :flagged -> remove_flag(info, "F")
#       _        -> :error
#     end
#   end


#   def update_flags(_, _, _) do
#     :error
#   end
# end