require "application_system_test_case"

class Ai::ConversationsTest < ApplicationSystemTestCase
  setup do
    @ai_conversation = ai_conversations(:one)
  end

  test "visiting the index" do
    visit ai_conversations_url
    assert_selector "h1", text: "Conversations"
  end

  test "should create conversation" do
    visit ai_conversations_url
    click_on "New conversation"

    fill_in "Category", with: @ai_conversation.category
    fill_in "Title", with: @ai_conversation.title
    fill_in "User", with: @ai_conversation.user_id
    click_on "Create Conversation"

    assert_text "Conversation was successfully created"
    click_on "Back"
  end

  test "should update Conversation" do
    visit ai_conversation_url(@ai_conversation)
    click_on "Edit this conversation", match: :first

    fill_in "Category", with: @ai_conversation.category
    fill_in "Title", with: @ai_conversation.title
    fill_in "User", with: @ai_conversation.user_id
    click_on "Update Conversation"

    assert_text "Conversation was successfully updated"
    click_on "Back"
  end

  test "should destroy Conversation" do
    visit ai_conversation_url(@ai_conversation)
    click_on "Destroy this conversation", match: :first

    assert_text "Conversation was successfully destroyed"
  end
end
