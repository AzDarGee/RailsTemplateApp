require "application_system_test_case"

class Ai::MessagesTest < ApplicationSystemTestCase
  setup do
    @ai_message = ai_messages(:one)
  end

  test "visiting the index" do
    visit ai_messages_url
    assert_selector "h1", text: "Messages"
  end

  test "should create message" do
    visit ai_messages_url
    click_on "New message"

    fill_in "Content", with: @ai_message.content
    fill_in "Conversation", with: @ai_message.conversation_id
    fill_in "Role", with: @ai_message.role
    fill_in "Tool call", with: @ai_message.tool_call_id
    fill_in "Tool calls", with: @ai_message.tool_calls
    click_on "Create Message"

    assert_text "Message was successfully created"
    click_on "Back"
  end

  test "should update Message" do
    visit ai_message_url(@ai_message)
    click_on "Edit this message", match: :first

    fill_in "Content", with: @ai_message.content
    fill_in "Conversation", with: @ai_message.conversation_id
    fill_in "Role", with: @ai_message.role
    fill_in "Tool call", with: @ai_message.tool_call_id
    fill_in "Tool calls", with: @ai_message.tool_calls
    click_on "Update Message"

    assert_text "Message was successfully updated"
    click_on "Back"
  end

  test "should destroy Message" do
    visit ai_message_url(@ai_message)
    click_on "Destroy this message", match: :first

    assert_text "Message was successfully destroyed"
  end
end
