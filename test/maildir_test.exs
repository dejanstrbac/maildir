defmodule MaildirTest do
  use ExUnit.Case

  test "is maildir" do
    assert Maildir.path_is_maildir? "test/maildir"
    assert Maildir.path_is_maildir? "test/maildir/Sent"
    assert Maildir.path_is_maildir? "test/maildir/Trash"
    assert Maildir.path_is_maildir? "test/maildir/Drafts"
    assert Maildir.path_is_maildir? "test/maildir/Custom"
    assert !(Maildir.path_is_maildir? "test/maildir/cur")
    assert !(Maildir.path_is_maildir? "test/maildir/new")
  end


  test "custom folders" do
    assert (Maildir.custom_folders("test/maildir") === ["Custom"])
  end


  test "maildir listing" do
    assert Maildir.folder_listing("test/maildir", "", "*") === [
      "1434995344.M588504P13503.mail2.migadu.ch,S=7060,W=7060:2,",
      "1434995643.M140437P10423.mail1.migadu.ch,S=2651,W=2651:2,"
    ]

    assert Maildir.folder_listing("test/maildir", "Sent", "*") === []
    assert Maildir.folder_listing("test/maildir", "not_a_maildir", "*") === []
  end


  test "email" do
    mail = Maildir.fetch_email("test/maildir/cur/1434995344.M588504P13503.mail2.migadu.ch")
    assert mail.from.email ===  "dejan@advite.ch"
  end

  test "new email processing with no new messages" do
    Maildir.process_new_messages("test/maildir")
  end


  test "new email processing" do
    filename = to_string(:random.uniform)
    base_path = "test/maildir"
    File.touch(Path.join([base_path, "new", filename]))
    Maildir.process_new_messages(base_path)
    assert :ok == File.rm(Path.join([base_path, "cur", filename <> ":2,"]))
  end

end
