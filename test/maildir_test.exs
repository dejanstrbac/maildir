defmodule MaildirTest do
  use ExUnit.Case

  test "is maildir" do
    assert Maildir.is_maildir_structure? "test/maildir"
    assert Maildir.is_maildir_structure? "test/maildir/.Sent"
    assert Maildir.is_maildir_structure? "test/maildir/.Trash"
    assert Maildir.is_maildir_structure? "test/maildir/.Drafts"
    assert Maildir.is_maildir_structure? "test/maildir/.Custom"
    assert !(Maildir.is_maildir_structure? "test/maildir/cur")
    assert !(Maildir.is_maildir_structure? "test/maildir/new")
  end


  test "maildir listing" do
    assert length(Maildir.folder_messages("test/maildir")) === 2
    assert length(Maildir.folder_messages("test/maildir/.Sent")) === 0
    assert length(Maildir.folder_messages("test/maildir/.Trash")) === 0
  end


  test "email" do
    mail = Maildir.message("test/maildir/cur/1434995344.M588504P13503.mail2.migadu.ch,S=7060,W=7060:2,")
    assert mail.from.email ===  "dejan@advite.ch"
  end


  test "new email processing" do
    filename = to_string(:random.uniform)
    base_path = "test/maildir"
    File.touch(Path.join([base_path, "new", filename]))
    Maildir.folder_messages(base_path)
    assert :ok == File.rm(Path.join([base_path, "cur", filename <> ":2,"]))
  end

end
